# Known Issues

Bugs and gaps discovered during a deep code audit. Most are small and fixable; a few are
architectural. Items marked ✅ have been fixed.

---

## Active Bugs

### 1. ✅ `make admin-local` is broken

**File:** `scripts/tools/admin/run_admin_server_local.sh`

The script references `$REPO_ROOT/admin` (a directory that does not exist) and
`$REPO_ROOT/scripts/services/nginx/assets/nginx.conf` (wrong path).

The actual admin server lives at `scripts/services/admin_server/src/`.
The nginx config lives at `scripts/dependencies/nginx/assets/nginx.conf`.

**Fixed:** corrected both paths in the script.

---

### 2. ✅ Admin panel log dropdown has "vristing" typos

**File:** `scripts/services/admin_server/src/static/admin.html`

Two log options had the value `vristing_startup.log` / `vristing_shutdown.log` (typo).
These never matched the Flask log map, so selecting them always returned 404.

**Fixed:** corrected to `vrising_startup.log` / `vrising_shutdown.log`.

---

### 3. ✅ mcrcon dead code removed

**File:** `scripts/services/admin_server/src/admin_server.py`

`mcrcon_cmd()` and `get_server_password()` were stubs kept speculatively. VRising does not
implement the RCON commands needed for player-count detection, so the RCON approach was abandoned.
The CPU-based idle check works well — even a relatively idle client generates enough load to
distinguish connected vs. empty server state.

**Fixed:** both functions removed. If RCON is ever needed again, `get_server_password()` can be
restored from git history.

---

### 4. ✅ `/directory` page has wrong nginx log URL paths

**File:** `scripts/services/admin_server/src/admin_server.py`, `/directory` route

The directory template linked to `/api/logs/nginx/access` and `/api/logs/nginx/error`, but the
Flask log route uses `nginx_access` and `nginx_error` (underscores, no nested slash).

**Fixed:** paths corrected to `/api/logs/nginx_access` and `/api/logs/nginx_error`.

---

### 5. ✅ `refresh_users.log` maps to wrong file path

**File:** `scripts/services/admin_server/src/admin_server.py`, `tail_log()` log map

The key `refresh_users.log` pointed to `refresh_users_startup.log`, but the actual file created
by `refresh_repo/setup.sh` is `refresh_repo_startup.log`. Requesting this log always threw a
`FileNotFoundError`.

**Fixed:** key renamed to `refresh_repo.log`, path corrected.

---

### 6. ✅ `get_admin_server_logs.sh` fetches nonexistent service

**File:** `scripts/tools/admin/get_admin_server_logs.sh`

`SERVICE="admin-server.service"` — this service does not exist. The actual services installed are
`admin-server-setup.service` and `admin-server-startup.service`.

**Fixed:** changed to `admin-server-startup.service` (the Flask process logs).

---

### 7. Flask admin server runs as root

**File:** `scripts/services/admin_server/admin-server-startup.service`

`User=root` — the Flask process runs as root. Given the `/logs/<name>` endpoint opens files from
a whitelist and the `/trigger-shutdown` endpoint calls `systemctl`, this is functional but means
a Flask compromise equals full root access.

**Suggestion:** run Flask as `bwinter_sc81` and grant that user specific sudo rights for
`systemctl restart game-shutdown.service` only (sudoers `NOPASSWD` entry).

---

### 8. ✅ `game-shutdown.service` timeout too short for VRising

**File:** `scripts/services/vrising/game-shutdown.service`

`TimeoutStartSec=300` (5 minutes). The shutdown script sleeps 90 seconds for VRising to save,
then waits up to 300 seconds for the process to exit — a potential 390 seconds total. systemd
would kill the script at 300 seconds, before the git commit/push completes.

**Fixed:** increased `TimeoutStartSec` to `600`.

---

### 9. `docs/ai_primer.md` contains inaccurate references

The primer referenced a nonexistent `apt_refresh.sh` (should be `refresh.sh`) and described
nginx as using `sites-available/` (it actually replaces the entire `nginx.conf`).

**Fixed:** corrected in the file.

---

## Minor Observations

- `scripts/services/vrising/src/tmp.sh` and `scripts/services/barotrauma/src/tmp.sh` are orphaned
  helper scripts (no shebang, not called by anything). They contain useful "ensure game is running"
  logic and could be promoted to real tools.
  - Brendan's_notes:this_was_implemented_at_some_point_but_ultimately_added_complexity_that_let_to_issues.Hence_I_removed_but_saved_in_case_i_wanted_to_brin_it_back.

- `VRising/VRisingServer_Data/StreamingAssets/Settings/ServeGameSettings.jsonc` — filename typo
  ("Serve" not "Server"). This file appears to be unused.
  - Brendan's_notes:need_to_explore_this.I_thought_this_would_Be_used.

- `scripts/tools/clean_git/bfg_cleanup.sh` uses macOS BSD `stat -f` syntax. It also hardcodes
  `REPO_PATH="$HOME/Desktop/Baroboys"` — will fail on any other local setup.
  - Brendan's_notes:this_needs_to_be_fixed.I_have_moved_the_folder.

- `scripts/tools/vrising/vrising_diagnostic.sh` uses `wine` instead of `wine64`. Since VRising
  runs under `wine64`, the diagnostic may inspect the wrong binary on systems where `wine` ≠ `wine64`.
  - Brendan's_notes:pretty_sure_this_works_as_intended.I_spent_tons_of_hours_getting_this_to_work.