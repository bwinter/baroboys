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

- **Wine/xvfb stack** — wine64→wine (Wine 11), 24-bit Xvfb, WINEDEBUG=-all, winetricks via
  curl (not apt), wineboot headless fix, Xvfb ExecStartPost= readiness poll. See known-issues
  #15, #16, #18 for the significant items.
- **`shutdown.sh` stash strategy** — documented that stash → pull --rebase → push → pop is
  intentional; clears local working-tree taint before rebase so push doesn't fail on dirty state.