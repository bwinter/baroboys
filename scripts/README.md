# `scripts/` Directory Overview

This directory contains all setup, control, and shutdown logic for the Baroboys game server infrastructure.

---

## 🗃️ Conventions

- All branching behavior uses the `.envrc` value of `ACTIVE_GAME`
- Scripts are designed to be idempotent and safe to re-run
- Game-specific logic lives under clearly isolated paths
- Root scripts are only run directly or from Terraform startup hooks
- User scripts are invoked with `/usr/bin/sudo -u bwinter_sc81` for correct context

---

## 🛠️ `setup/`

Top-level bootstrapping logic, invoked by Terraform during VM provisioning.

- `setup.sh`: Core entrypoint called by the VM’s startup script

### 🔧 `setup/install/`

Per-tool installation scripts for global dependencies:

- `apt_core.sh`, `apt_gcloud.sh`, `apt_wine.sh`, `apt_xvfb.sh`, `apt_steam.sh`

### 🧑‍💻 `setup/user/`

User-context setup scripts (run via `/usr/bin/sudo -u bwinter_sc81`):

- `util/refresh_repo.sh`: Git clone logic
- `install_*.sh`: Game-specific userland setup
- `patch_steam.sh`: Optional Steam configuration tweaks

### 🔐 `setup/root/`

Root-context setup scripts (called directly during provisioning):

- `util/refresh_repo.sh`: Git clone logic for root
- `patch_steam.sh`, `start_xvfb.sh`: Supporting utilities
- `setup_game.sh`: Dispatches game-specific setup based on `$ACTIVE_GAME`
- `setup_*.sh`: Game-specific service setup (systemd, files, symlinks)

---

## 📦 `services/`

Systemd unit files used to launch games and headless dependencies:

- `vrising.service`, `xvfb.service`

---

## 🧭 `manual/`

Utilities for manual operation, debugging, local overrides, or service account bootstrapping.

### Game Management

* `switch_game.sh` — Toggles the current game mode (`ACTIVE_GAME`) by updating `.envrc`
* `start_barotrauma_server.sh` — Manually starts the Barotrauma server (if needed outside systemd)
* `save-decompressor/` — Tools for working with compressed save-game data

### GCP Service Account Bootstrapping

* `gcp/bootstrap_terraform_sa.sh` — Creates the `terraform@` service account and grants it provisioning roles (e.g., Compute, IAM)
* `gcp/bootstrap_vm_sa.sh` — Creates the `vm-runtime@` service account and grants it runtime roles (e.g., Secret Manager, Logging)

---

## ⛔ `teardown/`

Scripts triggered at VM shutdown or manual teardown time.

### 🧑‍💻 `teardown/user/`

Game-aware save logic:

- `save_game.sh`: Dispatcher that calls game-specific save scripts (`ACTIVE_GAME`)
- `save_vrising.sh`, `save_barotrauma.sh`: Commit-save logic per game

### 🔐 `teardown/root/`

- `shutdown.sh`: Root-level shutdown hook used by Terraform to trigger user-side save