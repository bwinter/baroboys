# System Architecture

This document describes how baroboys works end-to-end: image building, VM lifecycle, service
dependencies, networking, secrets, and state persistence.

---

## Overview

```
[Local Machine]                    [GCP: europan-world]
 Makefile
   ├── packer build.sh  ──────────► GCE Images (Packer)
   └── terraform build.sh ────────► VM: europa (Terraform)
                                         │
                                    systemd units
                                    ├── refresh-repo
                                    ├── game-setup
                                    ├── game-startup  ──► VRising.exe (Wine) / DedicatedServer
                                    ├── game-shutdown ──► save → git commit → git push → poweroff
                                    ├── admin-server  ──► Flask :5000 ← Nginx :8080
                                    └── idle-check    ──► auto-shutdown after 30min CPU idle
```

---

## Packer Image Layers

Images are built in a strict hierarchy; each layer bakes in the one above it:

```
debian-12 (upstream)
  └── baroboys-core        packer/base/core.pkr.hcl
        └── baroboys-admin       packer/base/admin.pkr.hcl
              ├── baroboys-barotrauma  packer/game/barotrauma.pkr.hcl
              └── baroboys-vrising     packer/game/vrising.pkr.hcl
```

| Layer | Adds |
|-------|------|
| **core** | Debian Bookworm apt sources, i386 arch, git/curl/htop/screen/sysstat/gzip, gcloud CLI, Ops Agent (metrics + journald), clones repo, sets up refresh-repo service |
| **admin** | Nginx, SteamCMD, Flask admin server, idle-check service |
| **barotrauma** | Barotrauma dedicated server binaries (Steam app 1026340), game systemd services |
| **vrising** | Xvfb, WineHQ stable, winetricks fonts, VRising server binaries (Steam app 1829350, Windows platform), game systemd services |

**How `packer/build.sh` works:** it copies `terraform/shared.tfvars` and `terraform/variables.tf`
into `packer/tmp/` and passes them as Packer variable files. This means Packer and Terraform share
one source of truth for project, zone, machine type, and image names.

---

## Terraform

`terraform/main.tf` provisions:
- One GCE VM (`europa`, `n2-custom-2-6144`, `us-west1-c`, 20GB pd-ssd)
- Firewall rules for Barotrauma (TCP+UDP 27015, 27016), VRising (TCP+UDP 9876, 9877), and admin panel (TCP 8080)
- Startup metadata: `systemctl start game-startup.service`
- Shutdown metadata: `systemctl start game-shutdown.service`

The `game_image` variable selects which Packer image the VM boots from.
`terraform apply` is game-specific: `make terraform-apply-vrising` or `make terraform-apply-barotrauma`.

State is stored remotely in `gs://tf-state-baroboys/terraform/prod`.

---

## VM Boot Sequence

When the VM starts, GCE runs the startup-script metadata which triggers systemd.
Services run in dependency order:

```
network-online.target
  └── refresh-repo-setup.service   (oneshot, root)
        └── refresh-repo-startup.service  (oneshot, root)
             Clones/pulls latest Git for both /root and /home/bwinter_sc81
              ├── admin-server-setup.service   (oneshot, root)
              │     Installs nginx config, fetches .htpasswd from Secret Manager
              │     └── admin-server-startup.service  (simple, auto-restart)
              │           Flask app at /opt/baroboys/admin_server.py on :5000
              │
              ├── idle-check-setup.service     (oneshot, root)
              │     └── idle-check.timer  →  idle-check.service  (every 5 min)
              │
              ├── xvfb-setup.service           (VRising only, oneshot, root)
              │     └── xvfb-startup.service   (simple, always restart)
              │           Xvfb :0 -screen 0 1024x768x16
              │
              └── game-setup.service           (oneshot, root)
                    Runs as root, calls scripts/services/<game>/setup.sh:
                    - Updates game files via SteamCMD
                    - Fetches SERVER_PASSWORD from Secret Manager
                    - Runs envsubst on server config template
                    - (VRising) decompresses latest AutoSave_*.save.gz
                    └── game-startup.service   (simple, bwinter_sc81)
                          Barotrauma: ./DedicatedServer
                          VRising:    wine64 VRisingServer.exe (DISPLAY=:0)
```

---

## Shutdown Sequence

Triggered by any of:
- Admin panel "Trigger Shutdown" button → POST `/api/trigger-shutdown` → `systemctl restart game-shutdown.service`
- `idle_check.sh` after 30 min CPU below 5% → `systemctl restart game-shutdown.service`
- VM stop event → GCE shutdown-script metadata

`game-shutdown.service` runs `scripts/services/<game>/shutdown.sh` as `bwinter_sc81`:

**VRising:**
1. Fetch server password from Secret Manager
2. `mcrcon` sends shutdown notice to players (RCON port 25575)
3. Wait for `VRisingServer.exe` process to exit (up to 300s)
4. `gzip -kf` the latest uncompressed autosave
5. `git rm --cached` older `.save.gz` files, `git add` new one
6. `git commit -m "Auto-save before shutdown <timestamp>"`
7. `git stash push` → `git pull --rebase` → `git push origin main` → `git stash pop`
8. `sudo systemctl poweroff`

**Barotrauma:**
1. `pkill DedicatedServer`, wait for clean exit
2. `git add` all `*.save` and `*_CharacterData.xml` in `Barotrauma/Multiplayer/`
3. `git commit` + rebase pull + push
4. `sudo systemctl poweroff`

---

## Admin Panel Architecture

```
External browser
      │
      ▼
  :8080  Nginx  (basic auth via /etc/nginx/.htpasswd from Secret Manager)
      │
      ├── /              →  /opt/baroboys/static/admin.html     (static)
      ├── /status.json   →  /opt/baroboys/static/status.json    (static, written by idle_check.sh)
      ├── /api/*         →  http://127.0.0.1:5000/              (Flask proxy, /api/ prefix stripped)
      └── 404            →  /opt/baroboys/static/404.html
```

Flask (`admin_server.py`) routes:
- `GET /` → admin.html
- `GET /ping` → health check
- `POST /trigger-shutdown` → `systemctl restart game-shutdown.service`
- `GET /logs/<name>` → last 500 lines of a whitelisted log file
- `GET /directory` → Jinja template listing all routes

The admin panel auto-refreshes status every 5 seconds and streams the selected log.
UI theme: Bootstrap 5 + Bootswatch Cyborg (dark). See `docs/admin/style_guide.md`.

---

## Idle Check / Auto-Shutdown

`idle_check.sh` runs every 5 minutes via systemd timer:

1. Measures CPU with `mpstat 1 1` (1-second sample)
2. If CPU > 5%: clears idle flag, continues
3. If CPU ≤ 5%: creates `/tmp/server_idle_since.flag` if not present; tracks elapsed minutes
4. Writes `/opt/baroboys/static/status.json` (served directly by Nginx, read by admin panel)
5. If idle ≥ 30 minutes: triggers `game-shutdown.service`

Status JSON fields: `timestamp_utc`, `cpu_percent`, `mem_percent`, `idle_flag_set`, `idle_since`, `idle_duration_minutes`

---

## Secrets

Three secrets live in GCP Secret Manager. All fetched at runtime by the `vm-runtime` SA.

| Secret | Used by | Purpose |
|--------|---------|---------|
| `github-deploy-key` | `refresh_repo.sh` at every boot | ECDSA SSH key to clone/pull private repo |
| `server-password` | `<game>/refresh.sh` (setup) and `vrising/shutdown.sh` | Game join password + RCON password (injected via `envsubst`) |
| `nginx-htpasswd` | `nginx/refresh.sh` (setup) | Basic auth credentials for admin panel |

Password injection:
- **Barotrauma**: `serversettings.xml.in` → `envsubst` → `serversettings.xml` (placeholder: `${SERVER_PASSWORD}`)
- **VRising**: `ServerHostSettings.json` contains literal `"${SERVER_PASSWORD}"` strings → `envsubst` overwrites the file

---

## IAM

One service account: `vm-runtime@europan-world.iam.gserviceaccount.com`

| Role | Purpose |
|------|---------|
| `roles/logging.logWriter` | Ops Agent log forwarding |
| `roles/monitoring.metricWriter` | Ops Agent metrics |
| `roles/secretmanager.secretAccessor` | All three secrets above |

To grant someone the ability to start/stop the VM via GCP Console: `make iam-add-admin`
(grants `roles/compute.instanceAdmin.v1` to the provided email).

---

## Repository as State Store

The repo serves as a game-state database. Saves are committed and pushed on every clean shutdown.

| Game | Tracked paths | Format |
|------|--------------|--------|
| VRising | `VRising/Data/Saves/v4/TestWorld-1/AutoSave_*.save.gz` | Only latest kept in Git (older removed with `git rm --cached`) |
| Barotrauma | `Barotrauma/Multiplayer/*.save`, `*_CharacterData.xml` | All saves tracked |

The VM's `.gitconfig` identifies commits as `Game Server <bwinter.sc81+gameserver@gmail.com>`.

---

## File Paths Quick Reference

| What | Where |
|------|-------|
| Packer templates | `packer/base/`, `packer/game/` |
| Terraform config | `terraform/` |
| Bootstrap scripts | `bootstrap/` |
| Systemd unit files | `scripts/services/<component>/` |
| Game startup/shutdown logic | `scripts/services/<game>/startup.sh`, `shutdown.sh` |
| Game install/update logic | `scripts/services/<game>/src/refresh.sh` |
| Dependency installers | `scripts/dependencies/` |
| Admin Flask app | `scripts/services/admin_server/src/admin_server.py` |
| Admin static files | `scripts/services/admin_server/src/static/` |
| Nginx config | `scripts/dependencies/nginx/assets/nginx.conf` |
| Developer tools | `scripts/tools/` |
| VRising game config | `VRising/VRisingServer_Data/StreamingAssets/Settings/` |
| Barotrauma server config template | `Barotrauma/serversettings.xml.in` |
| Barotrauma local mod submarines | `Barotrauma/LocalMods/` |
| On-VM Flask install | `/opt/baroboys/admin_server.py` |
| On-VM static files | `/opt/baroboys/static/` |
| On-VM logs | `/var/log/baroboys/` |
| On-VM game logs (VRising) | `/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log` |