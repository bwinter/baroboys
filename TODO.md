# Backlog

---

## Active

### Immediate

- **Verify refactor on live VM** — the shared script architecture (setup.sh, startup.sh,
  shutdown.sh, install-game-units.sh) has not been tested on a live VM. Build and smoke test
  both existing games before adding new ones:
  1. `make build-game-VRising` + `make smoke-test-VRising`
  2. `make build-game-Barotrauma` + `make smoke-test-Barotrauma`

- **Create RCON password secret** — `make update-rcon-password` (VRising needs this before boot).

### Near-term

- **Add Project Zomboid (game 3)** — Java-based dedicated server. Steam App ID 380870.
  `LAUNCH_CMD="java -jar PZServer.jar"`. Config: `~/Zomboid/Server/servertest.ini` (plain ini,
  password set directly). Saves: `~/Zomboid/Saves/Multiplayer/<server-name>/`. Ports: UDP/TCP
  16261, UDP 16262. Shutdown: SIGTERM. New dep: `scripts/dependencies/java/apt_java.sh` (openjdk).
  Follow `docs/adding-a-game.md` — just env-vars.sh + post-checkout.sh + Packer template.

- **Add Valheim (game 4)** — Linux-native, simplest possible addition.
  Follow `docs/adding-a-game.md`.

  **env-vars.sh sketch:**
  ```bash
  export STEAM_APP_ID=896660
  export STEAM_PLATFORM="linux"
  export PROCESS_NAME="valheim_server.x86_64"
  export GAME_ENGINE_LOG="$LOG_FILE"
  export LAUNCH_CMD="./valheim_server.x86_64 -name BaroboysServer -world BaroboysWorld -password \$GAME_PASSWORD -port 2456"
  export SAVE_NAME="BaroboysWorld"
  export SAVE_FILE_PREFIX="BaroboysWorld"
  export SAVE_FILE_PATH="$HOME/.config/unity3d/IronGate/Valheim/worlds_local"
  ```
  Ports: UDP 2456–2458. No Wine, no Xvfb, no RCON. Minimal post-checkout.sh (just password fetch).

- **Template-based game onboarding** — turn adding-a-game.md into a fillable template.
  Start by creating filled-in markdown versions for VRising and Barotrauma (we know all the
  details). Derive the blank template from those. Then fill it out for Zomboid as the test.
  Markdown works well: prose around code blocks lets you annotate "research the save path here"
  alongside the actual config. The filled template becomes the source for generating env-vars.sh
  and post-checkout.sh.

- **Smoke test both games** — `make smoke-test-VRising` is exercised; `make smoke-test-Barotrauma`
  hasn't been run end-to-end. Verify it passes clean.

- **Smoke test: verify game is joinable** — extend `vm_checks.sh` to check that the game port
  is accepting connections, not just that the process is running. `nc -z -w5 <host> <port>`.

- **Manual QA: connect and play both games** — provision, launch game client, verify real
  connection. Port checks confirm listening; only a human client confirms playable.

- **CI — Tier 1: syntax/validate** — `packer validate` and `terraform validate` on every push.
  GitHub Actions on `push`/`pull_request`. No GCP credentials needed.

- **CI — Tier 2: design/contract tests** — enforce design decisions:
  - `shellcheck` on all scripts in `scripts/`
  - Verify systemd unit template pairing (setup/startup/shutdown)
  - Verify `Requires=` always accompanied by `After=` in unit templates
  - Verify all `.template` files contain only known `${VAR}` placeholders
  - Verify `SAVE_NAME` is exported in VRising/post-checkout.sh before `envsubst`
  - Verify `shared/shutdown.sh` contains the stash-pull-push-pop sequence
  - Verify every game dir has an `env-vars.sh` with all `SETUP: REQUIRED` vars set
  - Verify `.envrc` and `shared.tfvars` agree on project/zone/region/machine_name

- **CI — Tier 3: E2E smoke test on push** — full smoke test on every push to `main`.
  GitHub Actions with GCP SA credentials. Upload logs as job artifacts.

- **Start VM via bookmarkable URL** — Cloud Run + IAP serving a start button + status page.
  See git history for full design sketch (removed from TODO for brevity — the design is stable,
  just needs implementation).

- **Admin panel: multi-game awareness** — log dropdown shows all games regardless of which is
  running. Filter to active game:
  1. ✅ `active-game` written at Packer build time (in each game's .pkr.hcl)
  2. In `idle_check.sh`: read `active-game`, add `"game": "<name>"` to status.json
  3. Admin panel JS: read `status.json.game`, hide non-matching log entries

### Medium-term

- **Game manifest (bridges bash → Python)** — a JSON manifest at `/etc/baroboys/manifest.json`
  written by shared/setup.sh, consumed by admin_server.py. Replaces hardcoded log paths in Python
  with config derived from env-vars.sh. Unlocks multi-game awareness without a separate mechanism.

- **Save files to GCS** — reduce repo bloat. `gsutil cp` instead of git commit. Trade-off:
  loses "Git as backup" simplicity.

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`.
  GAME_DIR change cascades automatically (all paths derive from it). Low risk.

---

## Future / Big Ideas

These are interesting but not current priority.

- **devbox dev environment** — pins terraform, packer, gcloud, python3 via Nix-backed devbox.
  Learning/demo item — not a current pain point.
- Nix for environment management (replace/augment direnv)
- Claude API integration — AI-assisted ops from admin console
- Productize game management — web UI for picking/loading games; metadata-driven setup pipeline
- React frontend for admin panel
- Go for backend services
- Additional games beyond Zomboid/Valheim

---

## Done

Completed work lives in `git log`, `docs/architecture.md`, and inline comments.
Near-term items are removed from this list once their rationale is captured in docs.
