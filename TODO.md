# Backlog

---

## Active

### Near-term

- **CI pipeline** — two tiers:

  **Tier 1 — syntax/validate (free, no GCP):** `packer validate` and `terraform validate` on
  every push. GitHub Actions workflow on `push`/`pull_request`. For Packer: replicate the
  `packer/build.sh` var-file setup (copy `shared.tfvars` + `variables.tf` to `packer/tmp/`),
  then `packer init && packer validate` for each template. For Terraform: `terraform init -backend=false`
  + `terraform validate`. No GCP credentials needed.

  **Tier 2 — design/contract tests (shellcheck + shell tests):** enforce design decisions that
  are otherwise invisible until a real build or boot fails. Candidates:
  - `shellcheck` on all scripts in `scripts/` — catches unquoted vars, bad substitutions, etc.
  - Verify systemd unit pairing: every `*-setup.service` has a matching `*-startup.service`
  - Verify `Requires=` is always accompanied by `After=` (grep unit files for violations)
  - Verify all `.json.in` templates contain only known `${VAR}` placeholders (no typos)
  - Verify `WORLD_NAME` is exported in `vrising/src/refresh.sh` before `envsubst`
  - Verify `shutdown.sh` files contain the stash-pull-push-pop sequence in order
  - Verify every game dir has a `config.sh` exporting `GAME_NAME`
  - Verify `.envrc` and `shared.tfvars` agree on project/zone/region/machine_name
  These can be implemented as a bash test script or simple GitHub Actions steps — no mocking
  or GCP access needed.

- **Admin panel: start server button** — panel runs on the VM, so it can only help when the VM
  is already up. "Start" requires a GCP Compute API call from *outside* the VM. Options:
  (a) **Makefile target only** (simplest) — `make start` calls `gcloud compute instances start europa --zone=us-west1-c`. Already achievable today with no new infrastructure.
  (b) **GCP Cloud Function** — lightweight HTTP trigger that calls Compute API; can be invoked from a bookmark or simple page. `vm-runtime` SA doesn't help (it's on the stopped VM); need a separate SA with `compute.instanceAdmin.v1`.
  (c) **Admin panel endpoint** — only reachable when VM is already up, so only useful as a "restart" not a "start". Already partially covered by `make restart-game`.

- **devbox dev environment** — new machine setup currently requires manually hunting down
  terraform, packer, gcloud, python3, bash 4, nginx, java. Devbox (Nix-backed, no Nix knowledge
  required) pins these with a `devbox.json` + `devbox.lock`. Non-pure shell: host tools (git,
  make, curl, ssh) still work; devbox only owns the version-sensitive/platform-painful ones.
  Same `devbox.json` works on macOS and Linux — Nix selects the right platform binary automatically.
  Integrates with existing `.envrc` via a generated snippet — auto-activates on `cd`.
  Approach: `devbox init`, `devbox add terraform packer google-cloud-sdk python3 bash nginx jdk`,
  wire into `.envrc`. Commit `devbox.json` + `devbox.lock`. New dev runs `devbox shell` (or
  just `cd` with direnv) and has everything pinned.

  **Bootstrap (macOS):** `xcode-select --install` → Nix installer → `devbox shell`. Xcode CLT
  is Apple's unavoidable first step (provides git, make, clang). After that Nix is self-contained.
  Linux only needs curl for the Nix installer — simpler.

  **gcloud caveat:** nixpkgs disables gcloud's built-in component manager because `/nix/store/`
  is read-only — `gcloud components update` and `gcloud components install` won't work. Core
  gcloud commands are fine. If additional components (alpha, emulators) are ever needed, may
  need to manage gcloud outside devbox and leave it to the host.

  **Do not use on the VM:** Packer bakes deps at build time, not runtime. Wine and SteamCMD
  have known-working apt installs that are risky to swap. Nix would add store overhead to the
  image. Keep apt + Packer for VM; devbox is local dev only.

- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.
  Approach (simplified by config.sh groundwork):
  1. In each `<game>/setup.sh`: `source config.sh && echo "$GAME_NAME" > /etc/baroboys/active-game`
  2. In `idle_check.sh`: read `/etc/baroboys/active-game` and add `"game": "<name>"` to status.json
  3. Admin panel JS: read `status.json.game` on load, hide log entries whose name prefix doesn't match

- **Adding a new game — checklist** — the pattern is established; formalize when a 3rd game
  is added. Adding a game requires:
  - `scripts/services/<game>/config.sh` — GAME_NAME, GAME_DIR, STEAM_APP_ID, STEAM_PLATFORM,
    SAVE_DIR, LOG_FILE, plus game-specific tunables (WORLD_NAME, RCON_PORT, WINEPREFIX if Wine)
  - `scripts/services/<game>/setup.sh` — sources config.sh, runs refresh.sh, creates log files,
    installs + enables 3 systemd units; writes `$GAME_NAME` to `/etc/baroboys/active-game`
  - `scripts/services/<game>/src/refresh.sh` — sources config.sh, SteamCMD warm + app_update
    (using `$STEAM_APP_ID`, `$GAME_DIR`, `$STEAM_PLATFORM`), git checkout canonical configs,
    envsubst password into config templates
  - `scripts/services/<game>/startup.sh`, `shutdown.sh` — source config.sh; shutdown follows
    stash→pull→push→pop pattern
  - Systemd unit triplet: `game-setup.service`, `game-startup.service`, `game-shutdown.service`
  - Add game to `Makefile` `GAMES` list and `packer/` template
  - Terraform firewall rules for game ports
  - Admin server log map entries in `admin_server.py`
  Worth formalizing as `docs/adding-a-game.md` when a 3rd game is actually added.

### Medium-term

- **DRY shared game script logic** — after config centralization, the game scripts are strikingly
  similar in structure. Patterns duplicated verbatim across both games:
  - `shutdown.sh`: git stash→pull→push→pop sequence (identical)
  - `setup.sh`: log dir creation + unit installation (identical)
  - `src/refresh.sh`: SteamCMD warm call + app_update + git checkout canonical files (structurally identical)
  Blocked by the 3-game rule. When a 3rd game is added, extract shared logic into
  `scripts/services/lib/` (e.g. `git_sync.sh`, `steamcmd_update.sh`). Scripts would source lib
  functions and supply game-specific args from config.sh. Current duplication is acceptable.

- **Save files to GCS** — saves currently live in Git (growing binary history). Moving to a GCS
  bucket would reduce repo bloat, allow multiple save slots, and simplify shutdown (gsutil cp
  instead of git commit). `vm-runtime` SA already has cloud-platform scope. Trade-off: loses the
  "Git as backup" simplicity.

- **Admin server location** — `scripts/services/admin_server/` is awkward. It's a long-running
  web service, not a transient script. A top-level `admin/` directory was considered.
  - Also considered renaming the "admin" packer layer to "shared".

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`. Now
  straightforward: GAME_DIR in config.sh is the only per-game change; all scripts derive paths
  from it. Also update Packer templates and terraform game_image references. Low risk.

---

## Future / Big Ideas

These are interesting but not current priority. Logged so they aren't forgotten.

- `/wrap` slash command skill — formalize the session wrap protocol as a Claude Code skill
  so memory updates run automatically on demand
- Nix for environment management (replace/augment direnv) — see near-term item
- Claude API integration — AI-assisted ops from the admin console
- Productize game management — web UI for picking/loading games, adding new titles; would
  require a formal game manifest (config.sh is the seed of this), dependency declaration per
  game (apt packages, SteamCMD app ID, Wine yes/no), and likely a metadata-driven setup pipeline
  rather than per-game bash scripts. Nix per-game derivations are a natural fit here.
- React frontend for admin panel
- Go for backend services
- Kubernetes for service orchestration
- Additional games: Valheim, Rails app, others
- GraphQL API

---

## Done

Completed work lives in `git log`, `docs/architecture.md`, and inline comments.
Near-term items are removed from this list once their rationale is captured in docs.