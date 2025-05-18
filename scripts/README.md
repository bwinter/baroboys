## `scripts/setup/`
Top-level orchestrator scripts.

- `setup.sh`: full bootstrap entrypoint (called by Terraform)
- `install/`: per-tool install scripts
- `user/`: user-context setup (run via `sudo -u`)
- `root/`: root-context setup (systemd, cloning, service control)
