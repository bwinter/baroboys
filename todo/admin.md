# Admin & UX

The admin panel, friend-facing UX, and the plumbing that connects bash config to Python.

## Friend access

- **Start VM via bookmarkable URL** — Cloud Run + IAP serving a start button + status page.
  See git history for full design sketch (removed from TODO for brevity — the design is stable,
  just needs implementation).

## Admin panel

- **Assess VM target autodetection** — evaluate whether Make targets and helper tools should discover
  the active/deployed VM instead of requiring `<GAME>`. Review all current game-targeted commands,
  ambiguous multi-VM states, stopped VMs, and the cleanest shared implementation before changing
  any individual command.

- **Multi-game awareness** — ✅ implemented through the active-game manifest path
  (`aee5b03`, `ad3b786`, `431ad8a`). Packer records the active game, the shared
  refresh writes `/etc/baroboys/manifest.json`, idle-check publishes game-aware
  health fields, and the admin panel consumes the manifest instead of hardcoded
  per-game configuration.

- **Game manifest (bridges bash → Python)** — ✅ implemented in `aee5b03`. The
  shared refresh writes `/etc/baroboys/manifest.json`, and `admin_server.py`
  consumes it for game metadata, ports, logs, and templates.
