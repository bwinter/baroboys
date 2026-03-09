# Backlog

---

## Active

### Easy Wins (from wine/build audit)

- **`startup.sh`: Fix `set -euox pipefail` → `set -euxo pipefail`** — wrong flag order means
  pipefail is never enabled (the `x` is consumed as the `-o` argument, `pipefail` becomes `$1`).
  One-character reorder. `scripts/services/vrising/startup.sh:2`

- **`apt_xvfb.sh` + `apt_wine.sh`: Remove `dpkg --add-architecture amd64`** — no-op on amd64
  hosts. Likely a copy-paste from i386 Wine instructions. Wine 11 WoW64 mode doesn't need i386
  system libs. Investigate whether either call is needed; probably remove both.
  `scripts/dependencies/xvfb/apt_xvfb.sh:4`, `scripts/dependencies/wine/apt_wine.sh:12`

- **`setup.sh`: Add `export DISPLAY=:0` before wineboot** — Xvfb is running at `:0` when
  wineboot runs, but DISPLAY isn't exported. Wine relies on `$DISPLAY`; currently succeeds by
  luck or silent fallback. `scripts/dependencies/wine/src/setup.sh:14`

- **`setup.sh`: Fix stale "Debug trace complete" label** — wineboot section ends with
  `"✅ Debug trace complete."`. Should say "Wine prefix initialized" or similar.
  `scripts/dependencies/wine/src/setup.sh:20`

- **`startup.sh`: Add `WINEDEBUG=-all`** — Wine outputs extensive debug noise to stderr by
  default; all of it lands in `vrising_startup.log`. Setting `WINEDEBUG=-all` suppresses it
  and keeps logs meaningful. `scripts/services/vrising/startup.sh`

- **`startup.sh`: Add explicit `WINESERVER` env** — `setup.sh` sets
  `WINESERVER=/opt/wine-stable/bin/wineserver` explicitly; `startup.sh` doesn't. Wine auto-finds
  it, but explicit is consistent. `scripts/services/vrising/startup.sh`

- **`setup.sh`: Use `DISPLAY=:0` directly instead of `xvfb-run`** — `xvfb-run --auto-servernum`
  starts a second Xvfb alongside the one already running at `:0`. Could simplify by setting
  `DISPLAY=:0` and calling winetricks directly.
  `scripts/dependencies/wine/src/setup.sh:27`

- **`xvfb-startup.service`: Screen depth 16-bit vs 24-bit** — service uses `1024x768x16`;
  `xvfb-run` in setup.sh uses `1024x768x24`. Inconsistent; pick one (24-bit is more standard).
  `scripts/services/xvfb/xvfb-startup.service:13`

### Near-term

- **Config centralization** — PROJECT, ZONE, REGION, GCP_USER are scattered across `.envrc`,
  `Makefile`, and individual scripts with no single source of truth. Bootstrap process is also
  manual and not fully self-contained. Goal: everything reads from env; `.envrc` is the one
  place to change.

- **CI: validate-only pipeline** — `packer validate` and `terraform validate` are free (no GCP
  calls). Running them on push would catch syntax errors early with zero infrastructure cost.

- **Admin panel: start server button** — panel runs on the VM, so it can only help when the VM
  is already up. "Start" would require a GCP Compute API call (`compute.instances.start`).
  The `vm-runtime` SA would need `compute.instanceAdmin.v1`. Could be a simple Makefile target
  or admin panel endpoint.

- **Admin panel: multi-game awareness** — log dropdown always shows both Barotrauma and VRising
  entries regardless of which game is running. Should filter to the active game.

### Medium-term (from wine/build audit)

- **`refresh.sh`: Remove boot-time debug noise** — `id`, `ls -la ~`, `ls -la ~/.steam`,
  `find ~/.steam`, and `echo "=== BEFORE/AFTER steamcmd ==="` are leftover troubleshooting
  that run on every VM boot and pollute logs. Remove or gate behind a `DEBUG=1` flag.
  `scripts/services/vrising/src/refresh.sh:39-43, 58-61`

- **`refresh.sh`: Investigate warm SteamCMD call** — First `steamcmd +login anonymous +quit`
  before the real update call was a workaround for intermittent SteamCMD failures. Test if still
  needed; removing it would speed up every boot. `scripts/services/vrising/src/refresh.sh:46-48`

- **`shutdown.sh`: Simplify git stash strategy** — `stash push → pull --rebase → stash pop`
  is fragile: a failed pop leaves stashed state behind. After committing the save file, a simple
  `git fetch && git rebase origin/main` achieves the same goal more cleanly.
  `scripts/services/vrising/shutdown.sh:53-56`

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