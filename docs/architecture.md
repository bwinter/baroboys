# System Architecture

This document describes how baroboys works end-to-end: image building, VM lifecycle, service
dependencies, networking, secrets, and state persistence.

---

## Architecture Decisions

### VM lifecycle is owned by systemd, not Terraform

Terraform provisions the VM once. After that, the VM is self-managing: it pulls the latest repo
from Git on every boot, runs via systemd-managed services, and handles its own shutdown gracefully.

This means:
- **Script changes deploy via Git**, not Terraform. Commit, push, restart the VM — `refresh-repo`
  pulls on boot and the new scripts run.
- **Terraform metadata scripts are not used.** `startup-script` was redundant because
  `game-startup.service` auto-starts via `WantedBy=multi-user.target`. `shutdown-script` is
  replaced by `game-shutdown.service` hooking into `poweroff.target` via `[Install]`.
- **Git acts as a stability gate.** The VM only runs what is in `origin/main`. Changes go through
  normal review before they reach production, even without a formal CI pipeline.

Tying runtime script execution to Terraform metadata would be an implicit external dependency
orthogonal to these goals — it would push scripts from a local dev environment directly to the
VM, bypassing the Git-based stability guarantees the rest of the system relies on.

---

## Overview

```
[Local Machine]                    [GCP: europan-world]
 Makefile
   ├── packer build.sh  ──────────► GCE Images (Packer)
   └── terraform build.sh ────────► VM: <game> (Terraform)
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
  └── core             packer/base/core.pkr.hcl
        └── admin            packer/base/admin.pkr.hcl
              ├── barotrauma       packer/game/Barotrauma.pkr.hcl
              └── vrising          packer/game/VRising.pkr.hcl
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
- One GCE VM per game (`vrising` or `barotrauma`, `n2-custom-2-6144`, `us-west1-c`, 20GB pd-ssd)
- Firewall rules for Barotrauma (TCP+UDP 27015, 27016), VRising (TCP+UDP 9876, 9877), and admin panel (TCP 8080)

No metadata startup/shutdown scripts — game lifecycle is entirely owned by systemd `[Install]`
targets. `game-startup.service` auto-starts via `WantedBy=multi-user.target`; `game-shutdown.service`
hooks into `poweroff/halt/reboot` targets.

The `game_image` variable selects which Packer image the VM boots from.
`terraform apply` is game-specific: `make terraform-apply-VRising` or `make terraform-apply-Barotrauma`.

State is stored remotely in `gs://tf-state-baroboys/terraform/prod`.

---

## VM Boot Sequence

When the VM starts, systemd brings up services in dependency order. `game-startup.service`
auto-starts via `WantedBy=multi-user.target` — no metadata scripts involved:

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
              │           Xvfb :0 -screen 0 1024x768x24
              │           ExecStartPost= polls /tmp/.X11-unix/X0 — blocks until display is live
              │
              └── game-setup.service           (oneshot, root)
                    Runs as root, calls scripts/services/<game>/setup.sh:
                    - Updates game files via SteamCMD
                    - Fetches GAME_PASSWORD from Secret Manager
                    - Runs envsubst on server config template
                    - (VRising) decompresses latest AutoSave_*.save.gz
                    - Writes /etc/baroboys/active-game (game name for admin panel + smoke test)
                    └── game-startup.service   (simple, bwinter_sc81)
                          Barotrauma: ./DedicatedServer
                          VRising:    wine VRisingServer.exe (DISPLAY=:0, Wine 11+)
```

---

## Shutdown Sequence

Triggered by any of:
- Admin panel "Trigger Shutdown" button → POST `/api/trigger-shutdown` → `systemctl restart game-shutdown.service`
- `idle_check.sh` after 30 min CPU below 5% → `systemctl restart game-shutdown.service`
- VM stop event (poweroff/halt/reboot) → `game-shutdown.service` via `[Install] WantedBy=poweroff.target`

`game-shutdown.service` runs `scripts/services/<game>/shutdown.sh` as `bwinter_sc81`.
`TimeoutStartSec=600` — VRising takes up to ~390s to save and exit cleanly; 300s was too short.

**VRising:**
1. Fetch server password from Secret Manager
2. `mcrcon` sends shutdown notice to players (RCON port 25575)
3. Wait for `VRisingServer.exe` process to exit (up to 300s)
4. `gzip -kf` the latest uncompressed autosave
5. `git rm --cached` older `.save.gz` files, `git add` new one
6. `git commit -m "Auto-save before shutdown <timestamp>"`
7. `git stash push` → `git pull --rebase` → `git push origin main` → `git stash pop`
   (stash is intentional — clears working-tree taint so rebase succeeds; do not simplify)
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

**Security model:** Flask runs as `bwinter_sc81` (not root). A sudoers drop-in
(`/etc/sudoers.d/admin-server`, mode 440) grants the single permission needed:
`systemctl restart game-shutdown.service`. `bwinter_sc81` is in the `adm` group for
nginx log read access. No other elevated permissions.

---

## Idle Check / Auto-Shutdown

`idle_check.sh` runs every 5 minutes via systemd timer:

1. Measures CPU with `mpstat 1 1` (1-second sample)
2. If CPU > 5%: clears idle flag, continues
3. If CPU ≤ 5%: creates `/tmp/server_idle_since.flag` if not present; tracks elapsed minutes
4. Writes `/opt/baroboys/static/status.json` (served directly by Nginx, read by admin panel)
5. If idle ≥ 30 minutes: triggers `game-shutdown.service`

Status JSON fields: `timestamp_utc`, `cpu_percent`, `mem_percent`, `idle_flag_set`, `idle_since`, `idle_duration_minutes`

`/etc/baroboys/active-game` contains the running game name (written by `setup.sh` at boot).
Consumed by the admin panel (log dropdown filtering) and `smoke_test/vm_checks.sh` (self-identification).

---

## Secrets

Three secrets live in GCP Secret Manager. All fetched at runtime by the `vm-runtime` SA.

| Secret | Used by | Purpose |
|--------|---------|---------|
| `github-deploy-key` | `refresh_repo.sh` at every boot | ECDSA SSH key to clone/pull private repo |
| `server-password` | `<game>/refresh.sh` (setup) and `vrising/shutdown.sh` | Game join password + RCON password (injected via `envsubst`) |
| `nginx-htpasswd` | `nginx/refresh.sh` (setup) | Basic auth credentials for admin panel |

The `.json.in` / `.xml.in` template pattern exists because the game writes to `StreamingAssets/Settings/`
at runtime, so that directory is gitignored — files there can't be committed directly. Templates
in the repo root let config be version-controlled without committing live credentials; `envsubst`
regenerates the live files at each boot.

Password injection:
- **Barotrauma**: `Barotrauma/serversettings.xml.in` → `envsubst` → `serversettings.xml` (placeholder: `${GAME_PASSWORD}`)
- **VRising**: `VRising/ServerHostSettings.json.in` → `envsubst` → `StreamingAssets/Settings/ServerHostSettings.json` (gitignored, regenerated each boot)

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
| VRising | `VRising/Data/Saves/v4/$SAVE_NAME/AutoSave_*.save.gz` (`SAVE_NAME="TestWorld-1"`) | Compressed .gz tracked; old .gz removed with `git rm --cached` |
| Barotrauma | `Barotrauma/Multiplayer/Arkham Aquatics*.gz` | Compressed .gz tracked via `SAVE_FILE_PREFIX` |

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
| Game install/update logic | `scripts/services/shared/setup.sh` |
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
| On-VM game logs (VRising) | `/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log` (symlinked from `/var/log/baroboys/VRisingServer.log`) |
| Active game file | `/etc/baroboys/active-game` |
| E2E smoke test | `scripts/tools/smoke_test/` — `make smoke-test-VRising` |

---

## Wine / Xvfb: Build-Time Initialisation (VRising only)

VRising is a Windows binary. It runs under WineHQ stable (`/opt/wine-stable/bin/wine`), installed
from the WineHQ apt repo during the VRising Packer image build.

**The Wine prefix is initialised at build time, not runtime.** During the Packer build:
1. Xvfb is started (display `:0`, 1024×768×24)
2. `wineboot` initialises the prefix at `~/.wine64` (`WINEARCH=win64`, `WINEPREFIX=~/.wine64`)
3. `winetricks corefonts tahoma` installs required fonts
4. The completed prefix is baked into the image

At VM boot, Wine simply uses the pre-built prefix — no initialisation needed at runtime.

**Wine 11 (Jan 2026):** The `wine64` binary was removed; the unified `wine` binary handles both
32-bit and 64-bit PE binaries based on the PE header. `WINEARCH=win64` still works as expected.

---

## Known Build Noise

These warnings appear in every Packer build and are **expected — not failures**:

| Warning | Source | Why |
|---------|--------|-----|
| `nodrv_CreateWindow` / `XDG_RUNTIME_DIR not set` | wineboot | Running Wine in a non-login Packer environment without a full session |
| `fixme:actctx:parse_depend_manifests Could not find dependent assembly Microsoft.Windows.Common-Controls` | wineboot | Missing Windows common controls manifest — harmless for a headless server |
| `err:vulkan:vulkan_init_once Failed to load libvulkan.so.1` | wineboot | No GPU on the build VM — expected |
| `ILocalize::AddFile() failed to load file` | SteamCMD | Localisation file missing — always present, never a failure |
| `setlocale` warnings | SteamCMD | Locale not fully configured in Packer environment |
| `fatal: Cannot rebase onto multiple branches` | refresh_repo.sh | Git tracking state ambiguous after fresh clone; fallback to `--no-rebase` handles it |

Anything **not** in this table during a build is worth investigating.
