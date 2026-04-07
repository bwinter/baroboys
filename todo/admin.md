- **Start VM via bookmarkable URL** — Cloud Run + IAP serving a start button + status page.
  See git history for full design sketch (removed from TODO for brevity — the design is stable,
  just needs implementation).

- **Admin panel: multi-game awareness** — log dropdown shows all games regardless of which is
  running. Filter to active game:
  1. ✅ `active-game` written at Packer build time (in each game's .pkr.hcl)
  2. In `idle_check.sh`: read `active-game`, add `"game": "<name>"` to status.json
  3. Admin panel JS: read `status.json.game`, hide non-matching log entries

- **Game manifest (bridges bash → Python)** — a JSON manifest at `/etc/baroboys/manifest.json`
  written by shared/setup.sh, consumed by admin_server.py. Replaces hardcoded log paths in Python
  with config derived from env-vars.sh. Unlocks multi-game awareness without a separate mechanism.
