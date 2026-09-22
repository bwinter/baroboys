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
- Generic UDP/TCP firewall rules driven by `var.game_ports_udp` / `var.game_ports_tcp` (count
  guards skip the resource when the list is empty). Workspace-scoped admin firewall on TCP 8080
  targets the `admin` tag both VMs carry.

No metadata startup/shutdown scripts — game lifecycle is entirely owned by systemd `[Install]`
targets. `game-startup.service` auto-starts via `WantedBy=multi-user.target`; `game-shutdown.service`
hooks into `poweroff/halt/reboot` targets.

Per-game config is the single JSON file `terraform/game/<Game>.tfvars.json` — the cross-language
source of truth. Terraform reads it natively (`-var-file=...tfvars.json`); bash reads it once
via python3 in `shared/refresh.sh` to project the runtime manifest at `/etc/baroboys/manifest.json`.
All other consumers (`shared/post-checkout.sh`, `shared/shutdown.sh`, `idle_check.sh`,
`smoke_test/vm_checks.sh`) read the manifest via jq. The local `smoke_test/run.sh` reads the
JSON directly because it runs on the laptop, where the manifest doesn't exist. Schema:
`machine_name`, `game_image`, `game_tags`, `game_ports_udp/tcp`, `game_name`, `process_name`,
`uses_wine`, `accent_color`, `process_ram_mb_min`, `templates` (list of `[input, output]`
pairs envsubst'd by `shared/post-checkout.sh`).
Each game gets its own Terraform workspace (lowercase game name), so `terraform apply` for one
game doesn't affect another. `make terraform-apply-VRising` or `make terraform-destroy-Barotrauma`.

State is stored remotely in `gs://tf-state-baroboys/terraform/prod`, with per-game workspace isolation.

---

## VM Boot Sequence

When the VM starts, systemd brings up services in dependency order. `game-startup.service`
auto-starts via `WantedBy=multi-user.target` — no metadata scripts involved:

```
network-online.target
  ├── refresh-repo-refresh.service   (oneshot, root)
  │     └── refresh-repo-startup.service  (oneshot, root)
  │           Clones/pulls latest Git for both /root and /home/bwinter_sc81
  │           Installs sudoers from repo (self-heal)
  │
  └── infrastructure-refresh.service (oneshot, root, parallel with refresh-repo)
        Ensures /var/log/baroboys/ and /opt/baroboys ownership
              ↓ (both refresh-repo-startup and infrastructure-refresh must complete)
              ├── admin-server-refresh.service   (oneshot, root)
              │     Installs nginx config, derives .htpasswd from server-password
              │     └── admin-server-startup.service  (simple, auto-restart)
              │           Flask app at /opt/baroboys/admin_server.py on :5000
              │
              ├── idle-check-refresh.service     (oneshot, bwinter_sc81)
              │     └── idle-check.timer  →  idle-check.service  (every 5 min)
              │
              ├── xvfb-refresh.service           (VRising only, oneshot, bwinter_sc81)
              │     └── xvfb-startup.service   (simple, always restart)
              │           Xvfb :0 -screen 0 1024x768x24
              │           ExecStartPost= polls /tmp/.X11-unix/X0 — blocks until display is live
              │
              └── game-refresh.service           (oneshot, bwinter_sc81)
                    Calls scripts/services/shared/refresh.sh:
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

`game-shutdown.service` runs `scripts/services/shared/shutdown.sh` as `bwinter_sc81`.
`TimeoutStartSec=600` — VRising takes up to ~390s to save and exit cleanly; 300s was too short.

**Unified shutdown flow (all games):**
1. If RCON configured: `mcrcon` sends shutdown notice, waits for graceful exit
2. Otherwise: `pkill` the manifest's `process_name`, wait for clean exit (up to 300s)
3. Compress saves: `find $SAVE_FILE_PATH -name "$SAVE_FILE_PREFIX*" | gzip -kf`
4. `git rm --cached` older `.gz` files, `git add` current ones
5. `git commit -m "Auto-save before shutdown <timestamp>"`
6. `git stash push` → `git pull --rebase` → `git push origin main` → `git stash pop`
   (stash is intentional — clears working-tree taint so rebase succeeds; do not simplify)
7. `sudo systemctl poweroff`

---

## Admin Panel Architecture

```
External browser
      │
      ▼
  :8080  Nginx  (basic auth via /etc/nginx/.htpasswd, derived from server-password at boot)
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
(`/etc/sudoers.d/bwinter`, mode 440) grants the single permission needed:
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

`/etc/baroboys/active-game` contains the running game name (written by `refresh.sh` at boot).
Consumed by the admin panel (log dropdown filtering) and `smoke_test/vm_checks.sh` (self-identification).

---

## Secrets

Two secrets live in GCP Secret Manager. All fetched at runtime by the `vm-runtime` SA.

| Secret | Used by | Purpose |
|--------|---------|---------|
| `github-deploy-key` | `refresh_repo.sh` at every boot | ECDSA SSH key to clone/pull private repo |
| `server-password` | `shared/post-checkout.sh` (game config), `env-vars.sh` (RCON), `nginx/refresh.sh` (htpasswd) | Single password for game join, admin panel, and RCON |

Admin panel auth: `nginx/refresh.sh` derives htpasswd format from `server-password` at boot
using `htpasswd -cbB` — no separate `nginx-htpasswd` secret needed.

The `.template` pattern exists because the game writes to `StreamingAssets/Settings/`
at runtime, so that directory is gitignored — files there can't be committed directly. Templates
in the repo root let config be version-controlled without committing live credentials; `envsubst`
regenerates the live files at each boot.

Password injection:
- **Barotrauma**: `Barotrauma/serversettings.xml.template` → `envsubst` → `serversettings.xml` (placeholder: `${GAME_PASSWORD}`)
- **VRising**: `VRising/ServerHostSettings.json.template` → `envsubst` → `StreamingAssets/Settings/ServerHostSettings.json` (gitignored, regenerated each boot)

VRising also ships a `VRising/ServerGameSettings.jsonc` file alongside its `.template` —
that's an annotated reference doc (every field with type/range/notes, JSON-with-Comments
convention from VS Code), **not loaded by the game**. The actual game settings template is
`ServerGameSettings.json.template`. Tuned settings as of 2026-05: 5x stack size, 40% cheaper
builds, no castle decay, no raids.

---

## IAM

One service account: `vm-runtime@europan-world.iam.gserviceaccount.com`

| Role | Purpose |
|------|---------|
| `roles/logging.logWriter` | Ops Agent log forwarding |
| `roles/monitoring.metricWriter` | Ops Agent metrics |
| `roles/secretmanager.secretAccessor` | Both secrets above |

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
| Infrastructure (OS dirs, perms) | `scripts/services/infrastructure/` |
| Shared game lifecycle | `scripts/services/shared/` (refresh.sh, startup.sh, shutdown.sh, env-vars.sh) |
| Per-game config | `scripts/services/<Game>/` (env-vars.sh) + `terraform/game/<Game>.tfvars.json` |
| Dependency installers | `scripts/dependencies/` |
| Admin Flask app | `scripts/services/admin_server/src/admin_server.py` |
| Admin static files | `scripts/services/admin_server/src/static/` |
| Nginx config | `scripts/dependencies/nginx/assets/nginx.conf` |
| Developer tools | `scripts/tools/` |
| VRising game config | `VRising/VRisingServer_Data/StreamingAssets/Settings/` |
| Barotrauma server config template | `Barotrauma/serversettings.xml.template` |
| Barotrauma local mod submarines | `Barotrauma/LocalMods/` |
| On-VM Flask install | `/opt/baroboys/admin_server.py` |
| On-VM static files | `/opt/baroboys/static/` |
| On-VM logs | `/var/log/baroboys/` |
| On-VM game logs | `/var/log/baroboys/game.log` (all games, including engine output via `-logFile`) |
| Active game file | `/etc/baroboys/active-game` |
| E2E smoke test | `scripts/tools/smoke_test/` — `make smoke-test-VRising` |

---

## Wine / Xvfb: Build-Time Initialisation (VRising only)

VRising is a Windows binary. It runs under WineHQ stable (`/opt/wine-stable/bin/wine`), installed
from the WineHQ apt repo during the VRising Packer image build.

**The Wine prefix is initialised at build time, not runtime.** During the Packer build:
1. Xvfb is started (display `:0`, 1024×768×24)
2. `wineboot` initialises the prefix at `~/.wine` (`WINEARCH=win64`; Wine 11 defaults to `~/.wine`)
3. `winetricks corefonts tahoma` installs required fonts
4. The completed prefix is baked into the image

At VM boot, Wine simply uses the pre-built prefix — no initialisation needed at runtime.

**Wine 11 (Jan 2026):** The `wine64` binary was removed; the unified `wine` binary handles both
32-bit and 64-bit PE binaries based on the PE header. `WINEARCH=win64` still works as expected.

**Non-obvious traps (worth flagging because they don't surface as obvious errors):**
- **Init order is load-bearing.** `unset DISPLAY` → `wineboot` → `export DISPLAY=:0` → `winetricks`.
  If `DISPLAY` is set before `wineboot`, you get `start_rpcss Failed` followed by a `kernel32.dll`
  error that's hard to trace back to the cause.
- **`WINEARCH=win64` isn't decorative.** Without it, Wine builds a wow64 prefix whose 32-bit layer
  fragments the address space enough to fail VRising's ~6GB allocation. `WINEPREFIX` was removed
  (Wine 11 defaults to `~/.wine`), but `WINEARCH` must stay.
- **`winetricks` from GitHub source, not apt.** Debian's `winetricks` package depends on Debian's
  `wine` (8.x), which would shadow WineHQ's `wine` at `/opt/wine-stable/bin/`. The `apt_wine.sh`
  script `curl`s `winetricks` directly to `/usr/local/bin/`.

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
