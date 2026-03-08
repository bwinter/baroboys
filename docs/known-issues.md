# Known Issues

Bugs and gaps. Open items organized by effort — easy wins first.

---

## Open — Easy Fix

### VRising world name "TestWorld-1" hardcoded in multiple places

**Files:**
- `scripts/services/vrising/shutdown.sh:7` — `SAVE_DIR="VRising/Data/Saves/v4/TestWorld-1"`
- `scripts/services/vrising/src/refresh.sh:8` — `SAVE_DIR="$VRISING_DIR/Data/Saves/v4/TestWorld-1"`
- `VRising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json` — `"SaveName": "TestWorld-1"`

**Effort:** Easy (extract to a shared variable or env var)

Renaming the world requires coordinated changes in 3+ places. Low value to fix unless a rename
is planned.

---

## Open — Needs Attention

### `ServeGameSettings.jsonc` — purpose unclear, filename typo

**File:** `VRising/VRisingServer_Data/StreamingAssets/Settings/ServeGameSettings.jsonc`
**Effort:** Investigation needed

Filename is "Serve" not "Server" — likely a typo. File appears unused but may be a VRising
configuration file that should be active.

> **Brendan's note:** "need to explore this. I thought this would be used."

---

## Open — Architectural

### Flask admin server runs as root

**File:** `scripts/services/admin_server/admin-server-startup.service`
**Effort:** Medium (sudoers + service file changes + testing)

`User=root` — Flask process has full root access. A compromise of the web process (path traversal
in `/logs/<name>`, etc.) equals full root on the VM.

**Fix:** Run Flask as `bwinter_sc81`. Grant that user a single specific sudoers entry:
```
bwinter_sc81 ALL=(ALL) NOPASSWD: /bin/systemctl restart game-shutdown.service
```

---

## Accepted / Won't Fix

These are known but intentionally not being addressed.

| Issue | File | Reason |
|-------|------|--------|
| `vrising_diagnostic.sh` uses `wine` not `wine64` | `scripts/tools/vrising/vrising_diagnostic.sh` | Works as intended per extensive testing |
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