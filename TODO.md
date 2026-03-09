# Backlog

---

## Active

### Near-term

- **CI — Tier 1: syntax/validate** — `packer validate` and `terraform validate` on every push.
  GitHub Actions workflow on `push`/`pull_request`. For Packer: replicate `packer/build.sh`'s
  var-file setup (copy `shared.tfvars` + `variables.tf` to `packer/tmp/`), then
  `packer init && packer validate` for each template. For Terraform: `terraform init -backend=false`
  + `terraform validate`. No GCP credentials needed.

- **CI — Tier 2: design/contract tests** — enforce design decisions invisible until a real build
  or boot fails. Implement as a bash test script or GitHub Actions steps (no GCP access needed):
  - `shellcheck` on all scripts in `scripts/` — catches unquoted vars, bad substitutions, etc.
  - Verify systemd unit pairing: every `*-setup.service` has a matching `*-startup.service`.
    **Exception:** `idle-check-setup.service` pairs with `idle-check.timer` + `idle-check.service`
    (no `-startup` unit — timer pattern). Test must whitelist this.
  - Verify `Requires=` is always accompanied by `After=` (grep unit files for violations)
  - Verify all `.json.in` templates contain only known `${VAR}` placeholders (no typos)
  - Verify `WORLD_NAME` is exported in `vrising/src/refresh.sh` before `envsubst`
  - Verify `shutdown.sh` files contain the stash-pull-push-pop sequence in order
  - Verify every game dir has a `config.sh` exporting `GAME_NAME`
  - Verify `.envrc` and `shared.tfvars` agree on project/zone/region/machine_name

- **Admin panel: start server button** — the circular dependency is intentional and
  cost-driven (see `docs/design.md` Cost Philosophy): the panel lives on the game VM, so it
  can't start a stopped VM. `make start` satisfies the need with no new infrastructure.
  A bookmarkable URL would require a Cloud Function + always-on SA — not warranted under the
  current cost constraints. Revisit if the single-VM cost model ever changes.


- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.
  Approach (simplified by config.sh groundwork):
  1. In each `<game>/setup.sh`: create `/etc/baroboys/` dir and write the game name:
     `mkdir -p /etc/baroboys && echo "vrising" > /etc/baroboys/active-game`
     (Note: setup.sh runs as root; config.sh uses `$HOME`-based paths which would resolve to
     `/root/...` in root context — simpler to write the literal game name than source config.sh.)
  2. In `idle_check.sh`: read `/etc/baroboys/active-game` and add `"game": "<name>"` to status.json
  3. Admin panel JS: read `status.json.game` on load, hide log entries whose name prefix doesn't match

- **Adding a new game — checklist** — the pattern is established; formalize when a 3rd game
  is added. Adding a game requires:
  - `scripts/services/<game>/config.sh` — GAME_NAME, GAME_DIR, STEAM_APP_ID, STEAM_PLATFORM,
    SAVE_DIR, LOG_FILE, plus game-specific tunables (WORLD_NAME, RCON_PORT, WINEPREFIX if Wine)
  - `scripts/services/<game>/setup.sh` — runs refresh.sh as bwinter_sc81, creates log files,
    installs + enables 3 systemd units; writes `$GAME_NAME` to `/etc/baroboys/active-game`.
    If the game manifest (see medium-term DRY item) exists by this point, also write it here.
    Note: existing setup.sh files use hardcoded game-specific strings (log names, script paths)
    rather than sourcing config.sh — this is acceptable since setup.sh runs as root and config.sh's
    `$HOME`-based paths would be wrong in that context (use `HOME=/home/bwinter_sc81 source config.sh`).
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

- **DRY shared game script logic + game manifest** — after config centralization, the game scripts
  are strikingly similar in structure. Patterns duplicated verbatim across both games:
  - `shutdown.sh`: git stash→pull→push→pop sequence (identical)
  - `setup.sh`: log dir creation + unit installation (identical structure, different hardcoded names)
  - `src/refresh.sh`: SteamCMD warm call + app_update + git checkout canonical files (structurally identical)
  Blocked by the 3-game rule. When a 3rd game is added, extract shared logic into
  `scripts/services/lib/` (e.g. `git_sync.sh`, `steamcmd_update.sh`). Scripts would source lib
  functions and supply game-specific args from config.sh. Current duplication is acceptable.

  **Game manifest (bridges bash → Python):** the same 3rd-game trigger should produce a
  machine-readable manifest written by `setup.sh` and consumed by `admin_server.py`. Today
  `admin_server.py` hardcodes every log path — the bash-side canonical definitions live in
  systemd `StandardOutput=` lines and `config.sh:LOG_FILE`, but Python can't source them.
  A JSON manifest at `/etc/baroboys/manifest.json` closes the gap:
  ```json
  {
    "game_name": "vrising",
    "log_dir": "/var/log/baroboys",
    "game_log": "/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log"
  }
  ```
  `setup.sh` writes it (running as root, can `HOME=/home/bwinter_sc81 source config.sh`);
  `admin_server.py` reads it on startup and derives `{game}_startup.log`, `{game}_shutdown.log`,
  `{game}.log` from `game_name` + `log_dir`, using `game_log` for the special game-engine log.
  This also unlocks multi-game awareness (see near-term item) without a separate mechanism —
  admin_server.py already has everything it needs from the manifest.

- **Save files to GCS** — saves currently live in Git (growing binary history). Moving to a GCS
  bucket would reduce repo bloat, allow multiple save slots, and simplify shutdown (gsutil cp
  instead of git commit). `vm-runtime` SA already has cloud-platform scope. Trade-off: loses the
  "Git as backup" simplicity.

- **Consolidate VRisingServer.log into `/var/log/baroboys/`** — VRising writes its game log to
  `$GAME_DIR/logs/VRisingServer.log` (set via `-logFile ./logs/VRisingServer.log` in startup.sh,
  relative to WorkingDirectory). All other game logs land in `/var/log/baroboys/`. Options:
  add a symlink from `/var/log/baroboys/VRisingServer.log` in `vrising/setup.sh`, or change the
  `-logFile` arg and update `refresh.sh` accordingly. Current workaround: admin_server.py
  hardcodes the full path directly.

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`. Mostly
  straightforward: GAME_DIR in config.sh is the only per-game change for startup/shutdown/refresh
  scripts (all paths derive from it). Also requires:
  - Packer templates: update `game_image` family name references in `terraform/game/*.tfvars`
  - `setup.sh` files: hardcoded script path references (e.g. the path passed to `sudo -u bwinter_sc81`)
    would need updating — these don't derive from GAME_DIR since they're script paths, not game data paths
  Low overall risk; the data dir move is the bulk of it.

---

## Future / Big Ideas

These are interesting but not current priority. Logged so they aren't forgotten.

- `/wrap` slash command skill — formalize the session wrap protocol as a Claude Code skill
  so memory updates run automatically on demand
- **devbox dev environment** — pins terraform, packer, gcloud, python3, bash 4, nginx, java via
  Nix-backed devbox. `devbox init`, `devbox add terraform packer google-cloud-sdk python3 bash
  nginx jdk`, wire into `.envrc`. Bootstrap (macOS): `xcode-select --install` → Nix → devbox.
  Caveat: nixpkgs gcloud disables component manager (read-only /nix/store/). Python/venv needs
  rebuilding inside devbox shell. Do not use on VM (apt + Packer stays). Learning/demo item —
  not a current pain point.
- Nix for environment management (replace/augment direnv)
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