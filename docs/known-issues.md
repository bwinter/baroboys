# Known Issues

Known platform constraints intentionally not being addressed. Design decisions and non-obvious
gotchas live in `docs/architecture.md` and inline comments in the relevant files.

---

## Open

Active bugs — fix approach documented, not yet resolved.

| Issue | File | Fix |
|-------|------|-----|
| `VRisingServer.log` served from wrong path | `admin_server.py:71` | Change log_map path to `/home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log`, or symlink into `/var/log/baroboys/` from `vrising/setup.sh` |
| `barotrauma.log` directory label wrong | `admin_server.py:123` | Change `"V Rising Service Logs"` to `"Barotrauma Service Logs"` |
| `refresh_repo.log`, `xvfb.log` missing from admin panel dropdown | `admin.html` | Add both options to the `<select>` — they're in Flask's log_map but not exposed in the UI |

---

## Accepted / Won't Fix

These are known but intentionally not being addressed.

| Issue | File | Reason |
|-------|------|--------|
| `run_admin_server_local.sh` uses BSD `date -v` | `scripts/tools/admin/run_admin_server_local.sh:49` | macOS-only local dev tool; BSD date is correct here |
| `idle_check.sh` uses GNU `date -d` (fails on macOS) | `scripts/services/idle_check/src/idle_check.sh:44` | Production is Linux; local dev never runs idle_check |
| `bfg_cleanup.sh` requires bash 4+ and uses BSD `stat` | `scripts/tools/clean_git/bfg_cleanup.sh:52,81` | macOS-only local tool; bash 4 installed via brew |
