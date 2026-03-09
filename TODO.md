# Backlog

---

## Active

### Near-term

- **Config centralization — Layer 1 remaining** — `.envrc` exports `PROJECT`, `ZONE`, `REGION`,
  `GCP_USER`, `REMOTE`, `MACHINE_NAME`. Local dev tools now read these with hardcoded fallbacks
  (`get_admin_server_logs.sh`, `remote_refresh.sh`). Remaining gap: `Makefile` duplicates
  `PROJECT`, `ZONE`, `INSTANCE`, `USER` as Make variables — those are intentional (Make doesn't
  source `.envrc`) and unlikely to diverge, so low priority. `terraform/shared.tfvars` also
  duplicates some values — those feed Packer/Terraform and can't be replaced by shell vars.

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
  Approach: during `game-setup.service`, write the active game name to a known file, e.g.
  `echo "vrising" > /etc/baroboys/active-game` (created by `vrising/setup.sh`,
  `barotrauma/setup.sh` writes its own — source `config.sh` to get `$GAME_NAME`). `idle_check.sh`
  already writes `status.json` — add a `"game": "vrising"` field there. Admin panel JS reads
  `status.json` on load and hides log entries whose name doesn't match the active game.

- **Adding a new game — checklist** — the pattern is now established but not written down.
  Adding a third game should follow:
  - `scripts/services/<game>/config.sh` — `GAME_NAME` + game-specific tunables (world name,
    RCON port, etc.)
  - `scripts/services/<game>/setup.sh` — sources config.sh, runs refresh.sh as bwinter_sc81,
    creates log files, installs + enables 3 systemd units
  - `scripts/services/<game>/src/refresh.sh` — sources config.sh, SteamCMD warm + app_update,
    git checkout canonical configs, envsubst password into config templates
  - `scripts/services/<game>/startup.sh`, `shutdown.sh` — source config.sh; shutdown follows
    stash→pull→push→pop pattern
  - Systemd unit triplet: `game-setup.service`, `game-startup.service`, `game-shutdown.service`
  - Add game to `Makefile` `GAMES` list and `packer/` template
  - Terraform firewall rules for game ports
  - Admin server log map entries in `admin_server.py`
  - CI contract test: verify config.sh exports GAME_NAME, verify unit pairing
  Worth formalizing as a `docs/adding-a-game.md` guide once a 3rd game is added.

### Medium-term

- **DRY shared game script logic** — both games' scripts repeat the same patterns verbatim:
  git stash→pull→push→pop in shutdown.sh; log dir creation + unit installation in setup.sh.
  Blocked by the 3-game rule (two examples is coincidence, three is a pattern worth abstracting).
  When a 3rd game is added, extract these into a shared library (e.g. `scripts/services/lib/`).
  Current duplication is acceptable; do not abstract prematurely.

- **Save files to GCS** — saves currently live in Git (growing binary history). Moving to a GCS
  bucket would reduce repo bloat, allow multiple save slots, and simplify shutdown (gsutil cp
  instead of git commit). `vm-runtime` SA already has cloud-platform scope. Trade-off: loses the
  "Git as backup" simplicity.

- **Admin server location** — `scripts/services/admin_server/` is awkward. It's a long-running
  web service, not a transient script. A top-level `admin/` directory was considered.
  - Also considered renaming the "admin" packer layer to "shared".

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`. Config
  inconsistency (the original blocker) is now resolved — both games have `config.sh`. Remaining
  work: update hardcoded paths in game scripts (`$HOME/baroboys/VRising/`, etc.) and Packer
  templates. Straightforward but touches many files.

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