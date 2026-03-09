# Known Issues

Bugs and gaps. Open items organized by effort — easy wins first.

---

## Open — Easy Fix

### `mcrcon` install not version-pinned

**File:** `scripts/dependencies/mcrcon/refresh.sh:15`

`git clone https://github.com/Tiiffi/mcrcon.git` always clones HEAD. If upstream breaks the
build or changes the CLI, VRising shutdown (which relies on mcrcon for RCON) will silently
break on the next image build that has a cache miss. The idempotency check (`mcrcon -v`) only
guards against re-installing, not against a bad upstream version.

**Effort:** Easy — after the `git clone` line, add:
```bash
git -C "/tmp/mcrcon" checkout v0.7.2   # or latest tag from /releases
```
Check https://github.com/Tiiffi/mcrcon/releases for the current latest release tag before
committing. The version string is printed by `mcrcon -v`, so the existing idempotency check
will still work correctly after pinning.

---

### Barotrauma `refresh.sh` warm-SteamCMD comment is weaker than VRising's

**File:** `scripts/services/barotrauma/src/refresh.sh:18`

VRising has a detailed comment explaining *why* the warm login workaround exists (intermittent
SteamCMD failure, likely depot cache init, root cause unknown, removing it makes builds flaky).
Barotrauma has only `# Warm steam to hopefully avoid intermittent failures.` — a future reader
might remove it not knowing the reasoning.

**Effort:** Trivial — replace the current one-liner with the explanation from `vrising/src/refresh.sh`.
The comment should convey: this is a deliberate workaround for intermittent SteamCMD failures
(likely depot cache initialisation); root cause is unknown; removing it makes builds flaky;
do not simplify.

---

### VRising world name "TestWorld-1" hardcoded in multiple places

**Files:**
- `scripts/services/vrising/shutdown.sh:7` — `SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"`
- `scripts/services/vrising/src/refresh.sh:8` — `SAVE_DIR="$VRISING_DIR/Data/Saves/v4/TestWorld-1"`
- `VRising/ServerHostSettings.json.in` — `"SaveName": "TestWorld-1"` (envsubst'd at boot)

**Effort:** Easy if only changing variable references; risky if actually renaming the world.

**Implementation:** In each shell script, replace the hardcoded string with a variable defined
at the top: `WORLD_NAME="TestWorld-1"`. Then reference `$WORLD_NAME` in the path. Each script
sets its own local copy — there is no shared sourced config file. The three changes are:

1. `shutdown.sh:7` → `WORLD_NAME="TestWorld-1"; SAVE_DIR="VRising/Data/Saves/v4/$WORLD_NAME"`
2. `refresh.sh:8` → `WORLD_NAME="TestWorld-1"; SAVE_DIR="$VRISING_DIR/Data/Saves/v4/$WORLD_NAME"`
3. `ServerHostSettings.json.in` → replace literal `"TestWorld-1"` with `"${WORLD_NAME}"` and
   ensure `refresh.sh` exports `WORLD_NAME` before calling `envsubst`

**Warning:** Actually renaming the world (not just the variable) requires the on-disk save
directory to be renamed too. The game will create a fresh world if the directory is missing.
Do a coordinated rename: rename dir, update variable, push, then boot. Low priority unless a
rename is actively planned.

---

## Accepted / Won't Fix

These are known but intentionally not being addressed.

| Issue | File | Reason |
|-------|------|--------|
| `vrising_diagnostic.sh` uses `wine` not `wine64` | `scripts/tools/vrising/vrising_diagnostic.sh` | Works as intended per extensive testing |
| `run_admin_server_local.sh` uses BSD `date -v` | `scripts/tools/admin/run_admin_server_local.sh:49` | macOS-only local dev tool; GNU date not used here |
| `idle_check.sh` uses GNU `date -d` (fails on macOS) | `scripts/services/idle_check/src/idle_check.sh:44` | Production is Linux; local dev never runs idle_check |
| `bfg_cleanup.sh` requires bash 4+ and uses BSD `stat` | `scripts/tools/clean_git/bfg_cleanup.sh:52,81` | macOS-only local tool; works fine there |
| `tmp.sh` orphaned in both game service dirs | `scripts/services/*/src/tmp.sh` | Saved intentionally as a reference; was removed due to complexity |

---

## Fixed

All of the following have been resolved and committed:

| # | Issue |
|---|-------|
| 1 | `make admin-local` broken — wrong `ADMIN_DIR` and nginx config paths |
| 2 | Admin panel log dropdown "vristing" typos (always returned 404) |
| 3 | `mcrcon_cmd()` / `get_server_password()` dead code removed |
| 4 | `/directory` page nginx log links used slashes instead of underscores |
| 5 | `refresh_users.log` key mapped to nonexistent file |
| 6 | `get_admin_server_logs.sh` referenced nonexistent `admin-server.service` |
| 7 | `game-shutdown.service` `TimeoutStartSec=300` too short for VRising (~390s worst case) → bumped to 600 |
| 8 | `docs/ai_primer.md` referenced wrong script name and nginx layout |
| 9 | `bfg_cleanup.sh` hardcoded `$HOME/Desktop/Baroboys` → derived from script location |
| 10 | `packer/build.sh` no cleanup trap on failure → added `trap 'rm -rf "$BUILD_DIR"' ERR EXIT` |
| 11 | `terraform/main.tf` `ignore_changes` on startup/shutdown metadata + metadata block removed — VM lifecycle now owned by systemd `[Install]` |
| 12 | `ServeGameSettings.jsonc` filename typo + unclear purpose → renamed to `ServerGameSettings.jsonc` and moved to `VRising/` root (annotated reference doc for `ServerGameSettings.json`) |
| 13 | `ServerHostSettings.json` + `ServerGameSettings.json` force-committed into gitignored `StreamingAssets/Settings/` → moved to `VRising/*.json.in` templates; `refresh.sh` now `envsubst`s both into Settings/ at boot |
| 14 | Flask admin server ran as root → now runs as `bwinter_sc81`; sudoers drop-in grants single `systemctl restart game-shutdown.service` permission; `adm` group added for nginx log access |
| 15 | Wine 11.0 (Jan 2026) removed `wine64` binary (unified into `wine`) → updated all 4 hardcoded `/opt/wine-stable/bin/wine64` references in `apt_wine.sh`, `src/setup.sh`, `vrising/startup.sh` |
| 16 | Xvfb race condition: `systemctl start xvfb-startup.service` (Type=simple) returned before display socket was ready; wineboot raced and failed with `start_rpcss Failed` → `boot event wait timed out` → `wine: could not load kernel32.dll, status c0000135` → build failure. Fixed via `ExecStartPost=` readiness poll in `xvfb-startup.service` |
| 17 | `review_and_cleanup.sh`: hung Packer instances (RUNNING, name~packer-) not caught — TERMINATED filter missed them. Fixed by adding dedicated section. Also fixed `gsutil ls "${bucket}**"` (invalid glob) → `gsutil ls "${bucket}"` |
| 19 | `barotrauma/src/refresh.sh`: boot-time debug noise (`id`, `ls -la`, `find`, `=== BEFORE/AFTER steamcmd ===`) removed; weak warm-SteamCMD comment replaced with explanation matching VRising version |
| 18 | `wine/src/setup.sh`: `DISPLAY=:0` was set before `wineboot` (introduced in commit `82d841c` as an apparent cleanup). Wine 11 requires wineboot to run headless — setting `DISPLAY` before it causes `start_rpcss Failed` → `boot event wait timed out` → `could not load kernel32.dll`. Fixed by `unset DISPLAY` before wineboot and `export DISPLAY=:0` only immediately before winetricks. `unset` (not just omitting the export) makes the constraint hold regardless of caller environment. |