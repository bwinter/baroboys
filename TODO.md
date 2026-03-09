# Backlog

---

## Active

### Near-term

- **Config centralization** — PROJECT, ZONE, REGION, GCP_USER are scattered across `.envrc`,
  `Makefile`, and individual scripts with no single source of truth. Bootstrap process is also
  manual and not fully self-contained. Goal: everything reads from env; `.envrc` is the one
  place to change.

- **Barotrauma `refresh.sh` debug noise** — same `id`/`ls -la`/`find` lines that were cleaned
  from `vrising/src/refresh.sh` are still present in `barotrauma/src/refresh.sh:11-16,30-33`.
  Also copy the detailed warm-SteamCMD comment from the VRising version to the Barotrauma one
  (see known-issues.md for details). Two-minute fix.

- **Pin mcrcon to a release tag** — `mcrcon/refresh.sh` clones HEAD; add `git checkout <tag>`
  after clone. Check https://github.com/Tiiffi/mcrcon/releases for current latest.

- **CI: validate-only pipeline** — `packer validate` and `terraform validate` are free (no GCP
  calls). Running them on push would catch syntax errors early with zero infrastructure cost.

- **Admin panel: start server button** — panel runs on the VM, so it can only help when the VM
  is already up. "Start" would require a GCP Compute API call (`compute.instances.start`).
  The `vm-runtime` SA would need `compute.instanceAdmin.v1`. Could be a simple Makefile target
  or admin panel endpoint.

- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.

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