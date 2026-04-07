# Adding a New Game

Step-by-step guide for onboarding a new game server. Written during Valheim (game 3);
refined during Project Zomboid (game 4). Use `<game>` as a placeholder for the lowercase
game name (e.g. `valheim`, `zomboid`).

---

## Overview: What Changes

| Layer | What changes |
|-------|-------------|
| `scripts/services/<game>/` | Game lifecycle scripts + systemd units |
| `scripts/dependencies/` | New apt installers if the game needs them (Java, Wine, etc.) |
| `<GameName>/` (repo root) | Game state: saves, config templates, admin/ban lists |
| `packer/game/<game>.pkr.hcl` | Packer image template for this game layer |
| `terraform/game/<game>.tfvars` | One-line file pointing Terraform at the right image family |
| `terraform/main.tf` | Firewall rules for game ports |
| `Makefile` | Add to `GAMES` list — auto-generates 3 targets for free |
| `admin_server.py` | Log map entries so the admin panel can tail game logs |

Build order after adding a game: always `base/core → base/admin → game/<game>`.
The `game/<game>` layer bakes in the `base/admin` image, which bakes in `base/core`.

---

## Checklist

### 1. Scripts — `scripts/services/<game>/`

Create the following files. Copy the nearest existing game as a starting point.
Use `grep SETUP scripts/services/` to see every decision point marked with
`# SETUP: REQUIRED` or `# SETUP: OPTIONAL` across existing games.

#### `post-checkout.sh` — the game manifest

Sourced by all other game scripts. Minimum required vars:

```bash
GAME_NAME="<game>"
GAME_DIR="$HOME/baroboys/<GameName>"
STEAM_APP_ID=<id>          # dedicated server app ID (may differ from client)
STEAM_PLATFORM="linux"     # "linux" for native; "windows" for Wine
SAVE_FILE_PATH="<path>"          # where save files live
LOG_FILE="/var/log/baroboys/<game>.log"
```

Add game-specific vars as needed (e.g. `WORLD_NAME`, `RCON_PORT`).

> **Note:** `setup.sh` runs as root; `$HOME`-based paths in `post-checkout.sh` will resolve to
> `/root`. When sourcing from setup.sh, use `HOME=/home/bwinter_sc81 source post-checkout.sh`.

#### `setup.sh` — runs once at Packer build time (and again on each boot via game-setup.service)

Responsibilities (adapt from existing, but all should be present):

1. Run `refresh.sh` as `bwinter_sc81` to install/update the game via SteamCMD
2. Create `/var/log/baroboys/` and the log files the game produces, with correct ownership
3. Write `$GAME_NAME` to `/etc/baroboys/active-game` (used by admin panel + smoke test)
4. Install and enable the three systemd units

```bash
# Write active-game marker
mkdir -p /etc/baroboys
echo "<game>" > /etc/baroboys/active-game

# Install units
install -m 644 "/root/baroboys/scripts/services/<game>/game-setup.service"    /etc/systemd/system/
install -m 644 "/root/baroboys/scripts/services/<game>/game-startup.service"  /etc/systemd/system/
install -m 644 "/root/baroboys/scripts/services/<game>/game-shutdown.service" /etc/systemd/system/
systemctl daemon-reload
systemctl enable game-setup.service game-startup.service game-shutdown.service
```

#### `src/refresh.sh` — SteamCMD update + config templating

Runs as `bwinter_sc81`. Responsibilities:

1. Warm SteamCMD call (prevents intermittent failures — see comment in existing refresh.sh)
2. `app_update` with `$STEAM_APP_ID`, `$GAME_DIR`, `$STEAM_PLATFORM`
3. `git checkout` any canonical config files that should not drift (admin lists, base configs)
4. Export secrets and run `envsubst` on any `.in` templates into their live destinations

If the game config is command-line args only (e.g. Valheim), skip the envsubst step.

#### `startup.sh`

Sources `post-checkout.sh`. Launches the game process. For Wine games, set up `WINEPREFIX` and
`DISPLAY` first (see VRising startup.sh for ordering requirements).

#### `shutdown.sh`

Sources `post-checkout.sh`. Must follow the stash→pull→push→pop pattern — do not simplify:

```bash
git stash push
git pull --rebase
git stash pop
git push
```

After git sync: kill the game process (SIGTERM or RCON depending on the game), wait for
clean exit, then `sudo systemctl poweroff`.

#### Systemd units — `game-setup.service`, `game-startup.service`, `game-shutdown.service`

Copy from an existing game, then update `ExecStart=` paths and `Description=` fields.
Key rules (see CLAUDE.md "systemd Unit Conventions" for full details):

- Always pair `Requires=X` with `After=X`
- `game-shutdown.service`: needs `DefaultDependencies=no`, `Before=poweroff.target`,
  `[Install] WantedBy=poweroff.target halt.target reboot.target`, and
  `Wants=network-online.target` (not `Requires=` — network may stop during poweroff)

---

### 2. Dependencies — `scripts/dependencies/`

If the game needs a system package not already installed in `base/core` or `base/admin`,
add an installer script here:

```
scripts/dependencies/<dep>/apt_<dep>.sh
```

Call it from the Packer template (step 4) before `<game>/setup.sh`.

Examples: VRising needed `scripts/dependencies/wine/apt_wine.sh` and
`scripts/dependencies/xvfb/apt_xvfb.sh`. Valheim (Linux native) needs nothing extra.
Project Zomboid needs `openjdk` — add `scripts/dependencies/java/apt_java.sh`.

---

### 3. Game data directory — `<GameName>/` (repo root)

Create the directory and commit the files that should live in version control:
- Config templates (`.in` files for envsubst, or plain ini/xml files)
- Admin/ban lists (if the game has them)
- Any seed files needed for a fresh install

Gitignore generated config and save files that are large or binary — but save files
committed here are restored on each boot via `git checkout` in `refresh.sh`.

---

### 4. Packer template — `packer/game/<game>.pkr.hcl`

Copy `packer/game/Barotrauma.pkr.hcl`. Make these substitutions (5 occurrences):

| Placeholder | Replace with |
|-------------|-------------|
| `baroboys-barotrauma` (source block name) | `baroboys-<game>` |
| `baroboys-barotrauma-image` (build name) | `baroboys-<game>-image` |
| `"baroboys-barotrauma"` (sources list) | `"baroboys-<game>"` |
| `role = "baroboys-barotrauma"` | `role = "baroboys-<game>"` |
| `/scripts/services/barotrauma/setup.sh` | `/scripts/services/<game>/setup.sh` |

If the game needs extra dependencies (step 2), add provisioner steps before the
`<game>/setup.sh` call — see `VRising.pkr.hcl` for the Xvfb + Wine example.

---

### 5. Terraform — `terraform/game/<game>.tfvars`

Create `terraform/game/<game>.tfvars` with one line:

```hcl
game_image = "baroboys-<game>"
```

---

### 6. Terraform — firewall rules in `terraform/main.tf`

Add a `google_compute_firewall` resource (or two, if the game needs both TCP and UDP)
for the game's ports. Follow the existing Barotrauma/VRising pattern:

```hcl
resource "google_compute_firewall" "<game>_ports" {
  name    = "<game>-ports"
  network = "default"

  allow {
    protocol = "tcp"   # or "udp"
    ports    = ["<port>"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["game-server"]
}
```

---

### 7. Makefile — `GAMES` list

Add `<game>` to the `GAMES` variable on line 15:

```makefile
GAMES := barotrauma vrising <game>
```

That single addition auto-generates three targets:
- `make build-game-<game>` — builds the Packer image
- `make terraform-apply-<game>` — provisions the VM
- `make smoke-test-<game>` — runs the full E2E smoke test

---

### 8. Admin server — `scripts/services/admin_server/src/admin_server.py`

Two places in `tail_log()`:

**`log_map` dict** (~line 58):
```python
"<game>_startup.log":  os.path.join(LOG_DIR, "<game>_startup.log"),
"<game>_shutdown.log": os.path.join(LOG_DIR, "<game>_shutdown.log"),
"<game>.log":          os.path.join(LOG_DIR, "<game>.log"),
# Add a game-engine log entry here if the game writes a separate engine log
# (like VRising's VRisingServer.log). Skip if the game logs to <game>.log only.
```

**`links` list** (~line 117):
```python
("/api/logs/<game>_startup.log",  "<GameName> Startup Logs",  "GET"),
("/api/logs/<game>_shutdown.log", "<GameName> Shutdown Logs", "GET"),
("/api/logs/<game>.log",          "<GameName> Service Logs",  "GET"),
```

---

## Verification

After implementing all steps:

1. `make build-game-<game>` — Packer build should complete without errors
2. `make terraform-apply-<game>` — VM should provision and boot
3. SSH in, check `systemctl status game-startup.service` — game process running
4. Check `/etc/baroboys/active-game` — contains `<game>`
5. Admin panel log dropdown — new game logs should appear
6. `make smoke-test-<game>` — full E2E: provision, checks, destroy

---

## Game-specific notes

### Valheim
- Linux native; no Wine, no Xvfb — use Barotrauma as the template, not VRising
- Config is command-line args to `valheim_server.x86_64`; no `.in` template needed
- Shutdown: `SIGTERM` to `valheim_server.x86_64` — no RCON
- Saves: `~/.config/unity3d/IronGate/Valheim/worlds_local/`
- Ports: UDP 2456–2458

### Project Zomboid
- Java-based; add `scripts/dependencies/java/apt_java.sh` (openjdk)
- Config: `~/Zomboid/Server/servertest.ini` — password set directly in ini (no `.in` template)
- Shutdown: SIGTERM (no RCON required)
- Saves: `~/Zomboid/Saves/Multiplayer/<server-name>/`
- Ports: UDP/TCP 16261, UDP 16262
- Steam dedicated server App ID: 380870