# Known Issues

Bugs and gaps. Open items organized by effort — easy wins first.

---

## Accepted / Won't Fix

These are known but intentionally not being addressed.

| Issue | File | Reason |
|-------|------|--------|
| `run_admin_server_local.sh` uses BSD `date -v` | `scripts/tools/admin/run_admin_server_local.sh:49` | macOS-only local dev tool; BSD date is correct here |
| `idle_check.sh` uses GNU `date -d` (fails on macOS) | `scripts/services/idle_check/src/idle_check.sh:44` | Production is Linux; local dev never runs idle_check |
| `bfg_cleanup.sh` requires bash 4+ and uses BSD `stat` | `scripts/tools/clean_git/bfg_cleanup.sh:52,81` | macOS-only local tool; bash 4 installed via brew |

---

## Fixed

Entries worth preserving as design context or non-obvious gotchas. Routine fixes
(typos, dead code, minor tool bugs) are in git log but not listed here.

| # | Issue |
|---|-------|
| 7 | `game-shutdown.service` `TimeoutStartSec=300` too short for VRising (~390s worst case) → bumped to 600 |
| 11 | `terraform/main.tf` metadata startup/shutdown scripts + `ignore_changes` removed — VM lifecycle is owned entirely by systemd `[Install]`, not Terraform metadata |
| 13 | `ServerHostSettings.json` + `ServerGameSettings.json` were force-committed into gitignored `StreamingAssets/Settings/` → moved to `VRising/*.json.in` templates; `refresh.sh` `envsubst`s them into Settings/ at boot |
| 14 | Flask admin server ran as root → now runs as `bwinter_sc81`; sudoers drop-in grants single `systemctl restart game-shutdown.service`; `adm` group added for nginx log access |
| 15 | Wine 11.0 (Jan 2026) removed `wine64` binary (unified into `wine`) → updated all hardcoded `wine64` references |
| 16 | Xvfb race: `Type=simple` returns on fork, not readiness; wineboot raced a half-started Xvfb and failed with `start_rpcss Failed` → `kernel32.dll` error. Fixed via `ExecStartPost=` socket poll in `xvfb-startup.service` |
| 18 | `wine/src/setup.sh`: `DISPLAY=:0` set before `wineboot` caused Wine 11 `start_rpcss Failed` → `kernel32.dll` error. Fixed: `unset DISPLAY` before wineboot, `export DISPLAY=:0` only before winetricks. `unset` (not just omitting) enforces headless regardless of caller environment. |
| 19 | `barotrauma/src/refresh.sh` had boot-time debug blocks (`id`, `ls -la`, `find`, `=== BEFORE/AFTER steamcmd ===`) running every boot. Also had a weak warm-SteamCMD comment. Removed debug blocks; replaced one-liner with full rationale matching VRising version. |
| 20 | `mcrcon/refresh.sh` cloned HEAD with no tag pin — upstream breakage would silently break VRising shutdown. Added `git -C "/tmp/mcrcon" checkout v0.7.2` after clone. |
| 21 | `TestWorld-1` hardcoded in `vrising/shutdown.sh`, `vrising/src/refresh.sh`, and `ServerHostSettings.json.in`. Replaced with `WORLD_NAME="TestWorld-1"` variable; `refresh.sh` exports it before `envsubst`. Rename still requires coordinated on-disk dir rename. |