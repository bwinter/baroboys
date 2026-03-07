# Baroboys — Claude Project Instructions

## What This Repo Is

GCP game server hosting platform for **VRising** and **Barotrauma**. Packer builds layered GCE
images; Terraform provisions the VM; systemd + bash scripts manage the game lifecycle; saves are
committed to Git on every shutdown.

**Full system reference:** [`docs/architecture.md`](docs/architecture.md)
**Known bugs/gaps:** [`docs/known-issues.md`](docs/known-issues.md)

---

## Key Facts (Memorise These)

| Item | Value |
|------|-------|
| GCP project | `europan-world` |
| VM | `europa`, `us-west1-c`, `n2-custom-2-6144` |
| VM user | `bwinter_sc81` |
| Service account | `vm-runtime@europan-world.iam.gserviceaccount.com` |
| TF state | `gs://tf-state-baroboys/terraform/prod` |
| Admin panel | `http://<VM-IP>:8080/` — user `Hex`, pw = server-password secret |

---

## Repo Layout

```
bootstrap/          Bootstrap scripts (TF bucket, SA) — run once
packer/             Packer templates (base/core, base/admin, game/vrising, game/barotrauma)
  build.sh          Entry point — accepts "base/<name>" or "game/<name>"
terraform/          Infrastructure (VM, firewall, outputs)
  build.sh          Entry point — accepts <game> <env>
scripts/
  dependencies/     apt installers (steam, wine, nginx, gcloud, etc.)
  services/         Per-component: setup.sh + startup.sh + shutdown.sh + systemd units
    admin_server/   Flask app (src/admin_server.py), static files, templates
    barotrauma/     Game lifecycle scripts
    vrising/        Game lifecycle scripts
    idle_check/     CPU-based auto-shutdown (every 5 min timer)
    refresh_repo/   Git pull on boot (runs for both root and bwinter_sc81)
    xvfb/           Virtual display for VRising/Wine
  tools/            Local developer utilities (not deployed to VM)
    admin/          run_admin_server_local.sh, get_admin_server_logs.sh
    gcp/            add_admin.sh, review_and_cleanup.sh
    clean_git/      BFG history cleanup pipeline
docs/               Documentation
Barotrauma/         Game state: saves, mods, server config template
VRising/            Game state: saves, admin/ban lists, server config
```

---

## Common Commands

```bash
# Infrastructure
make bootstrap                   # First-time setup (TF bucket + SA)
make terraform-apply-barotrauma  # Deploy Barotrauma server
make terraform-apply-vrising     # Deploy VRising server
make destroy                     # Tear down VM

# Images (build in order: core → admin → game)
make build-base-core
make build-base-admin
make build-game-barotrauma       # or build-game-vrising
make build                       # All images

# VM access
make ssh                         # Direct SSH
make ssh-iap                     # SSH via IAP tunnel

# Game control
make restart-game                # Restart game-startup.service on VM
make save-and-shutdown           # Trigger game-shutdown.service on VM

# Admin panel (local dev)
make admin-local                 # Run Flask + Nginx locally

# Maintenance
make update-password             # Update server-password secret
make iam-add-admin               # Grant VM start/stop to an email
make clean                       # Delete old GCP images/disks/IPs
```

---

## Working Style

- **Red-green TDD** for new features and bug fixes
- **Fix in place** — don't restructure directories as a prerequisite to small fixes
- **Bite-sized commits** — logical groupings, not one-liners and not monoliths
- **TODO.md** = long-term aspirations, not current sprint work

---

## Packer Image Layer Order

Always build in this order (each bakes in the previous):

```
debian-12 → baroboys-core → baroboys-admin → baroboys-barotrauma
                                           └→ baroboys-vrising
```

`packer/build.sh` copies `terraform/shared.tfvars` + `terraform/variables.tf` into `packer/tmp/`
as Packer var files — Packer and Terraform share the same variable definitions.

---

## Secrets (GCP Secret Manager)

Three secrets, all accessed via the `vm-runtime` service account at runtime:

| Secret | Used by | What |
|--------|---------|------|
| `github-deploy-key` | `refresh_repo.sh` (every boot) | ECDSA SSH key to clone/pull repo |
| `server-password` | `<game>/src/refresh.sh`, `vrising/shutdown.sh` | Game join + RCON password |
| `nginx-htpasswd` | `nginx/refresh.sh` | Basic auth for admin panel |

Password is injected via `envsubst`:
- Barotrauma: `serversettings.xml.in` → `serversettings.xml`
- VRising: `ServerHostSettings.json` (contains `"${SERVER_PASSWORD}"` literals)

---

## Admin Panel

Flask on `:5000` (internal) + Nginx on `:8080` (public, basic auth).

```
:8080 Nginx
  /             → /opt/baroboys/static/admin.html
  /status.json  → /opt/baroboys/static/status.json  (written by idle_check.sh)
  /api/*        → http://127.0.0.1:5000/             (Flask, /api/ stripped)
```

**Source:** `scripts/services/admin_server/src/admin_server.py`
**On-VM install:** `/opt/baroboys/`

Local dev: `make admin-local` (runs both processes, mirrors prod layout, fetches real secrets).

---

## Shutdown / Save Flow

```
idle_check.sh OR admin panel OR VM stop
  → systemctl restart game-shutdown.service
  → shutdown.sh (as bwinter_sc81)
      → kill game process, wait for clean exit
      → compress/stage save file
      → git commit + pull --rebase + push origin main
      → sudo systemctl poweroff
```

---

## Game-Specific Notes

**Barotrauma** (Steam app 1026340)
- Native Linux binary: `./DedicatedServer`
- Ports: TCP+UDP 27015/27016
- Config template: `Barotrauma/serversettings.xml.in`
- Saves: `Barotrauma/Multiplayer/*.save` + `*_CharacterData.xml`

**VRising** (Steam app 1829350)
- Windows binary via Wine64: `wine64 VRisingServer.exe`
- Requires Xvfb on DISPLAY=:0, WINEPREFIX=`/home/bwinter_sc81/.wine64`
- Ports: TCP+UDP 9876/9877 (firewall), 27015/27016 (configured in ServerHostSettings.json)
- RCON: port 25575 (used by shutdown.sh)
- Config: `VRising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json`
- Saves: `VRising/Data/Saves/v4/TestWorld-1/AutoSave_*.save.gz` (only latest in Git)
- Game settings: 5x stack size, no castle decay, no raids, faster crafting/research

---

## On-VM Log Locations

| Log | Path |
|-----|------|
| All baroboys logs | `/var/log/baroboys/` |
| VRising game log | `/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log` |
| Nginx | `/var/log/nginx/access.log`, `error.log` |

Logs are accessible via admin panel dropdown or `make admin-logs`.

---

## Known Open Issues

See [`docs/known-issues.md`](docs/known-issues.md) for full detail.

1. Flask admin server runs as root (security concern)
2. `bfg_cleanup.sh` hardcodes `$HOME/Desktop/Baroboys` — broken on any other setup

---

## Files to Be Aware Of

- `.envrc` — direnv: sets PROJECT, ZONE, REGION, GCP_USER, activates `.venv`
- `.gitconfig` — VM git identity (`Game Server`, `bwinter.sc81+gameserver@gmail.com`)
- `terraform/.terraform.lock.hcl` — committed; keeps provider versions pinned
- `packer/tmp/` — gitignored build scratch dir, safe to delete
- `scripts/services/*/src/tmp.sh` — orphaned helper scripts, not wired up to anything