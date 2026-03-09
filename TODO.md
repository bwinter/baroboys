# Backlog

---

## Active

### Near-term

- **Config centralization** — PROJECT, ZONE, REGION, GCP_USER are scattered across `.envrc`,
  `Makefile`, `terraform/shared.tfvars`, and individual scripts. Goal: `.envrc` is the one
  place to change. Approach: Makefile already sources `.envrc` via direnv; Terraform already
  reads `shared.tfvars`; the gap is scripts that hardcode values (e.g. `get_admin_server_logs.sh`
  hardcodes `bwinter_sc81@europa`). Audit scripts for hardcoded project/zone/user strings and
  replace with `$PROJECT`, `$ZONE`, `$GCP_USER` (already exported by `.envrc`).

- **Barotrauma `refresh.sh` debug noise** — same `id`/`ls -la`/`find` lines that were cleaned
  from `vrising/src/refresh.sh` are still present in `barotrauma/src/refresh.sh:11-16,30-33`.
  Also copy the detailed warm-SteamCMD comment from the VRising version to the Barotrauma one.
  See known-issues.md for exact lines to delete. Two-minute fix.

- **Pin mcrcon to a release tag** — `mcrcon/refresh.sh:15` clones HEAD; add
  `git -C "/tmp/mcrcon" checkout <tag>` after clone. Check releases page for current tag.
  See known-issues.md for exact implementation.

- **CI: validate-only pipeline** — `packer validate` and `terraform validate` are free (no GCP
  calls). Running them on push would catch syntax errors early with zero infrastructure cost.
  Approach: GitHub Actions workflow on `push`/`pull_request`. For Packer: replicate the
  `packer/build.sh` var-file setup (copy `shared.tfvars` + `variables.tf` to `packer/tmp/`),
  then `packer init && packer validate` for each template. For Terraform: `terraform init -backend=false`
  (skips remote state) + `terraform validate`. No GCP credentials needed for either.

- **Admin panel: start server button** — panel runs on the VM, so it can only help when the VM
  is already up. "Start" requires a GCP Compute API call from *outside* the VM. Options:
  (a) **Makefile target only** (simplest) — `make start` calls `gcloud compute instances start europa --zone=us-west1-c`. Already achievable today with no new infrastructure.
  (b) **GCP Cloud Function** — lightweight HTTP trigger that calls Compute API; can be invoked from a bookmark or simple page. `vm-runtime` SA doesn't help (it's on the stopped VM); need a separate SA with `compute.instanceAdmin.v1`.
  (c) **Admin panel endpoint** — only reachable when VM is already up, so only useful as a "restart" not a "start". Already partially covered by `make restart-game`.

- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.
  Approach: during `game-setup.service`, write the active game name to a known file, e.g.
  `echo "vrising" > /etc/baroboys/active-game` (created by `vrising/setup.sh`,
  `barotrauma/setup.sh` writes its own). `idle_check.sh` already writes `status.json` —
  add a `"game": "vrising"` field there. Admin panel JS reads `status.json` on load and
  hides log entries whose name doesn't match the active game.

### Medium-term

- **Save files to GCS** — saves currently live in Git (growing binary history). Moving to a GCS
  bucket would reduce repo bloat, allow multiple save slots, and simplify shutdown (gsutil cp
  instead of git commit). `vm-runtime` SA already has cloud-platform scope. Trade-off: loses the
  "Git as backup" simplicity.

- **Admin server location** — `scripts/services/admin_server/` is awkward. It's a long-running
  web service, not a transient script. A top-level `admin/` directory was considered.
  - Also considered renaming the "admin" packer layer to "shared".

- **Refactor games into subdir** — move `Barotrauma/` and `VRising/` under `games/`. Blocked on
  config inconsistency (env vars not standardized across scripts). Would require touching many
  hardcoded paths.

---

## Future / Big Ideas

These are interesting but not current priority. Logged so they aren't forgotten.

- `/wrap` slash command skill — formalize the session wrap protocol as a Claude Code skill
  so memory updates run automatically on demand
- Nix for environment management (replace/augment direnv)
- Claude API integration — AI-assisted ops from the admin console
- React frontend for admin panel
- Go for backend services
- Kubernetes for service orchestration
- Additional games: Valheim, Rails app, others
- GraphQL API

---

## Done

- **Game selection UX** — was clunky (edit tfvars directly). Now: `make terraform-apply-<game>`
  uses per-game tfvars files and a `GAME` env var.
- **Email secrets** — moved emails into GCP Secret Manager.
- **IAM cleanup** — simplified to a single design; removed unnecessary service account permissions.
- **Terraform SA secret access** — verified and removed; Packer uses local credentials.
- **Wine/xvfb easy wins** — 8 items: fixed `set -euxo`, removed no-op `dpkg --add-architecture amd64`,
  added `DISPLAY=:0` before wineboot, dropped redundant `xvfb-run`, added `WINEDEBUG=-all` and
  `WINESERVER` to startup.sh, fixed stale label, unified Xvfb to 24-bit color depth.
- **`refresh.sh`: Remove boot-time debug noise** — removed `id`, `ls -la ~`, `ls -la ~/.steam`,
  `find ~/.steam`, and `=== BEFORE/AFTER steamcmd ===` banners from `vrising/src/refresh.sh`.
- **`shutdown.sh`: Document stash strategy** — added comment explaining the stash → pull --rebase
  → push → pop pattern is intentional (clears local taint before rebase).