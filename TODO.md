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

- **CI — Tier 3: E2E smoke test on push** — run the full smoke test in serial on every push to
  `main`. GitHub Actions with GCP service account credentials; calls `scripts/tools/smoke_test/run.sh`
  directly (not `make` — interactive). Upload logs as job artifacts so they're reviewable in the
  Actions UI without SSH. Long-term: diff game server logs across runs to surface things worth
  implementing (unexpected warnings, latency patterns, missing features visible in output).

- **Smoke test both games** — `make smoke-test-vrising` is exercised; `make smoke-test-barotrauma`
  exists via the Makefile pattern but hasn't been run end-to-end. Verify it passes clean. Likely
  surfaces small config or path differences — that's the point.

- **Smoke test: verify game is joinable** — extend `vm_checks.sh` to check that the game port
  is actually accepting connections, not just that the process is running. A live process with a
  closed port is a false positive. Implementation: `nc -z -w5 <host> <port>` (TCP) or a UDP probe.
  Ports from `config.sh`: Barotrauma 27015, VRising 9876. This is the closest approximation to
  "did the game actually start?" without a real game client.

- **Manual QA: connect and play both games** — provision each game server, actually launch the
  game client, and verify a real connection works end-to-end. Port checks confirm the server is
  listening; only a human client confirms the game is actually playable. Do this after the
  smoke test items above pass cleanly.

- **Start VM via bookmarkable URL** — `make start` works from a terminal but friends need GCP
  console access today. Goal: a URL anyone with a Google account (that you've approved) can click
  to start the VM — with boot progress feedback — no GCP console, no CLI.

  **Design:** Cloud Run + Identity-Aware Proxy (IAP) serving a small HTML page
  - Cloud Run: Python/Flask service (same tech as `admin_server.py`). Serves its own HTML
    page with start button + status display + boot log. Serverless, free tier covers all usage.
  - IAP wraps the URL with Google auth. Friends click → Google login → page loads. No GCP
    console access, no service account keys.
  - Permissions: Cloud Run SA gets `compute.instances.start` + `compute.instances.get` +
    `compute.instances.getSerialPortOutput` scoped to the one VM. Friends get
    `roles/iap.httpsResourceAccessor` — one `gcloud` command to grant or revoke per person.
  - Terraform provisions Cloud Run + IAP config + SA + IAM bindings. New `make iam-add-friend`
    target (parallel to existing `make iam-add-admin`).

  **Page features:**
  1. **Start button** — POST `/api/start` → Compute API `instances.start`, returns immediately
  2. **Status badge** — polls `/api/status` (Compute API `instances.get`) every 3s, shows
     `TERMINATED` / `STAGING` / `RUNNING`. Auto-stops polling on `RUNNING`.
  3. **Boot log** — polls `/api/serial` (Compute API `instances.getSerialPortOutput`) every 3s.
     This is the VM's serial console — shows systemd boot sequence, game setup output, errors —
     the same view as GCP console "Serial port" tab. Answers "is it stuck?" without SSH.
     Stop tailing when status reaches `RUNNING`.

  Polling at 3s is simpler than SSE (server-sent events) with equivalent UX for a ~5 min boot.
  SSE is a future refinement if the polling feel is too janky.

  **Note:** Cloud Run costs $0 at idle — the one justified exception to the no-always-on-infra
  rule. The alternative (GCP console access for friends) has worse security and worse UX.


- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.
  Approach (simplified by config.sh groundwork):
  1. ✅ In each `<game>/setup.sh`: write `/etc/baroboys/active-game` — done (889a2ed).
     Also consumed by `smoke_test/vm_checks.sh` for self-identification.
  2. In `idle_check.sh`: read `/etc/baroboys/active-game` and add `"game": "<name>"` to status.json
  3. Admin panel JS: read `status.json.game` on load, hide log entries whose name prefix doesn't match

- **Add Valheim (game 3)** — Linux-native dedicated server, simplest possible addition.
  Follows the established pattern; adding it triggers the 3-game DRY rule and unlocks the
  `scripts/services/lib/` extraction + game manifest work.

  **config.sh sketch:**
  ```bash
  GAME_NAME="valheim"
  GAME_DIR="$HOME/baroboys/Valheim"
  STEAM_APP_ID=896660
  STEAM_PLATFORM=""          # native Linux
  WORLD_NAME="BaroboysWorld" # or whatever
  SAVE_DIR="$HOME/.config/unity3d/IronGate/Valheim/worlds_local"
  LOG_FILE="/var/log/baroboys/valheim.log"
  ```
  **Differences from Barotrauma/VRising:**
  - Config is command-line args to the server binary, not a template file. Password and world
    name passed as `-password` and `-world` flags in `startup.sh`. No `.in` template needed.
  - Shutdown: `SIGTERM` to `valheim_server.x86_64` — no RCON, no mcrcon dependency.
  - Saves: live in `$HOME/.config/unity3d/IronGate/Valheim/worlds_local/` — need to stage these
    in `shutdown.sh` the same way Barotrauma stages `.save` files.
  - Ports: UDP 2456-2458 — add to Terraform firewall rules.
  - No Wine, no Xvfb — simpler Packer layer than VRising.
  Also add `valheim` to `Makefile` `GAMES` list and create `packer/game/valheim.pkr.hcl`.

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
- `/cold-boot` slash command skill — formalize `~/.claude/cold-boot-protocol.md` as an
  invocable skill usable in any repo; assesses CLAUDE.md, memory files, settings, and hooks
  for warm boot quality; asks about goals, proposes and applies changes with approval
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