# Baroboys — Claude Project Instructions

## What This Repo Is

GCP game server hosting platform for **VRising** and **Barotrauma**. Packer builds layered GCE
images; Terraform provisions the VM; systemd + bash scripts manage the game lifecycle; saves are
committed to Git on every shutdown.

**Design philosophy:** [`docs/design.md`](docs/design.md)
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

Secrets, ports, log paths, file locations: see `docs/architecture.md`.

---

## Repo Layout

```
bootstrap/          Bootstrap scripts (TF bucket, SA) — run once
packer/             Packer templates; build.sh accepts "base/<name>" or "game/<name>"
terraform/          Infrastructure; build.sh accepts <game> <env>
scripts/
  dependencies/     apt installers (steam, wine, nginx, gcloud, etc.)
  services/         Per-component: setup.sh + startup.sh + shutdown.sh + systemd units
    admin_server/   Flask admin app
    barotrauma/     Game lifecycle
    vrising/        Game lifecycle
    idle_check/     CPU-based auto-shutdown
    refresh_repo/   Git pull on boot
    xvfb/           Virtual display (VRising/Wine)
  tools/            Local dev utilities (not deployed to VM)
docs/               Documentation
Barotrauma/         Game state: saves, mods, config template
VRising/            Game state: saves, admin/ban lists, config
```

---

## Common Commands

```bash
# Images — always build in this order
make build-base-core
make build-base-admin
make build-game-Barotrauma   # or build-game-VRising
make build                   # all images

# Deploy / tear down
make terraform-apply-VRising   # or terraform-apply-Barotrauma
make destroy

# VM access + game control
make ssh                       # or make ssh-iap
make restart-game
make save-and-shutdown

# Test
make smoke-test-VRising        # full E2E: terraform + checks + destroy

# Local dev
make admin-local               # Flask + Nginx locally, fetches real secrets
make clean                     # delete old GCP images/disks/IPs
```

---

## Working Style

- **Red-green TDD** for new features and bug fixes
- **Fix in place** — don't restructure directories as a prerequisite to small fixes
- **Bite-sized commits** — logical groupings, not one-liners and not monoliths
- **TODO.md** = long-term aspirations, not current sprint work
- **Fix protocol** — task-specific steps (code → docs → stage) then calls wrap (`memory/fix-protocol.md`)
- **Wrap protocol** — universal ending after any completed task: full memory sweep → commit → push.
  Always the full version — no shortcuts (`memory/wrap-protocol.md`)

---

## Packer Image Layer Order

Always build in this order (each bakes in the previous):

```
debian-12 → core → admin → barotrauma
                        └→ vrising
```

`packer/build.sh` copies `terraform/shared.tfvars` + `terraform/variables.tf` into `packer/tmp/`
as Packer var files — Packer and Terraform share the same variable definitions.

---

## Game Config Convention — `SETUP:` markers

Game-specific scripts use `# SETUP: REQUIRED` and `# SETUP: OPTIONAL` comments to mark
lines that need attention when adding a new game. `grep SETUP scripts/services/` shows
every decision point. `REQUIRED` = must be set for the game to work. `OPTIONAL` = only
needed if the game uses that feature (e.g. save decompression, RCON, template interpolation).

---

## systemd Unit Conventions

All units follow a two-phase pattern per component: `*-setup.service` (oneshot, root, installs/configures) → `*-startup.service` (long-running or oneshot, bwinter_sc81, runs the thing). Always pair `Requires=X` with `After=X` — `Requires` alone does not enforce order. For shutdown services use `Wants=` not `Requires=` for network dependency (network may stop during poweroff sequence). Unit changes require image rebuild to take effect.

`idle-check.service` has `WantedBy=multi-user.target` intentionally — runs once at boot to seed `status.json` before the timer's first 5-minute fire.

---

## Shutdown / Save Flow

```
idle_check.sh OR admin panel OR any VM stop (poweroff/halt/reboot)
  → game-shutdown.service (hooks into poweroff.target via [Install])
  → shutdown.sh (as bwinter_sc81)
      → kill game process, wait for clean exit
      → compress/stage save file
      → git commit + pull --rebase + push origin main
      → sudo systemctl poweroff
```

---

## Known Issues

See [`docs/known-issues.md`](docs/known-issues.md) — Won't Fix platform constraints and any
currently open issues. When you find a new bug, add it there.

---

## Files to Be Aware Of

- `.envrc` — direnv: sets PROJECT, ZONE, REGION, GCP_USER, activates `.venv`
- `.gitconfig` — VM git identity (`Game Server`, `bwinter.sc81+gameserver@gmail.com`)
- `terraform/.terraform.lock.hcl` — committed; keeps provider versions pinned
- `packer/tmp/` — gitignored build scratch dir, safe to delete
- `.claude/settings.local.json` — repo-level auto-approval list. Commands not in this list
  require manual confirmation — run them as standalone Bash calls, never chained with others.