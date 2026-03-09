# Known Issues

Known platform constraints intentionally not being addressed. Design decisions and non-obvious
gotchas live in `docs/architecture.md` and inline comments in the relevant files.

---

## Accepted / Won't Fix

These are known but intentionally not being addressed.

| Issue | File | Reason |
|-------|------|--------|
| `run_admin_server_local.sh` uses BSD `date -v` | `scripts/tools/admin/run_admin_server_local.sh:49` | macOS-only local dev tool; BSD date is correct here |
| `idle_check.sh` uses GNU `date -d` (fails on macOS) | `scripts/services/idle_check/src/idle_check.sh:44` | Production is Linux; local dev never runs idle_check |
| `bfg_cleanup.sh` requires bash 4+ and uses BSD `stat` | `scripts/tools/clean_git/bfg_cleanup.sh:52,81` | macOS-only local tool; bash 4 installed via brew |
