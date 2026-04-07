# Adding a New Game

Step-by-step guide for onboarding a new game server. Use `<Game>` as a placeholder
for the title-case game name (e.g. `VRising`, `Barotrauma`, `Zomboid`).

---

## Overview: What Changes

| Layer | What to create/modify |
|-------|----------------------|
| `scripts/services/<Game>/env-vars.sh` | Game-specific variables (Steam, saves, process name, launch command) |
| `scripts/services/<Game>/post-checkout.sh` | Post-checkout hook: secret fetch + envsubst templates (if needed) |
| `scripts/dependencies/` | New apt installers if the game needs them (Java, Wine, etc.) |
| `<Game>/` (repo root) | Game state: saves, config templates, admin/ban lists |
| `packer/game/<Game>.pkr.hcl` | Packer image template |
| `terraform/game/<Game>.tfvars` | One-line file pointing Terraform at the right image family |
| `terraform/main.tf` | Firewall rules for game ports |
| `Makefile` | Add to `GAMES` list — auto-generates 3 targets |
| `admin_server.py` | Log map entries for the admin panel |

**You do NOT need to create:** startup.sh, shutdown.sh, setup.sh, or systemd units.
These are all shared scripts driven by env-vars.sh.

Build order: always `base/core → base/admin → game/<Game>`.

---

## Checklist

### 1. Game config — `scripts/services/<Game>/env-vars.sh`

The game manifest. Copy the nearest existing game and set the `SETUP:` marked variables.
Use `grep SETUP scripts/services/` to see every decision point across existing games.

```bash
# SETUP: REQUIRED
export STEAM_APP_ID=<id>
export STEAM_PLATFORM="linux"     # "linux" for native; "windows" for Wine
export PROCESS_NAME="<binary>"    # process name for pgrep/pkill
export GAME_ENGINE_LOG="$LOG_FILE" # where the game writes real output (or a separate path)
export LAUNCH_CMD="./<binary>"    # the command that starts the game server

# SETUP: OPTIONAL — saves
export SAVE_NAME="<world>"        # save/world identity (if game uses one)
export SAVE_FILE_PREFIX="<prefix>" # filename prefix for save compression
export SAVE_FILE_PATH="<dir>"     # directory containing saves

# SETUP: OPTIONAL — RCON (if game supports it)
export RCON_PASSWORD="$(gcloud secrets versions access latest --secret=<secret>)"
export RCON_PORT=<port>
export SHUTDOWN_DELAY_MINUTES=1

# SETUP: OPTIONAL — files to restore from git after SteamCMD update
export CHECKOUT_LIST="<path1> <path2>"
```

### 2. Post-checkout hook — `scripts/services/<Game>/post-checkout.sh`

Runs after SteamCMD install and `git checkout` of canonical configs. Use this for:
- Fetching secrets: `GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"`
- Exporting vars that envsubst needs: `export GAME_PASSWORD SAVE_NAME RCON_PASSWORD`
- Running envsubst on config templates

If the game uses command-line args only (no config templates), this file can be minimal —
just the password fetch and exports.

---

### 3. Dependencies — `scripts/dependencies/`

If the game needs a system package not already installed in `base/core` or `base/admin`,
add an installer script:

```
scripts/dependencies/<dep>/apt_<dep>.sh
```

Call it from the Packer template (step 5) before `shared/setup.sh`.

Examples: VRising needed Wine + Xvfb. Project Zomboid needs openjdk.
Barotrauma and Valheim (Linux native) need nothing extra.

---

### 4. Game data directory — `<Game>/` (repo root)

Create the directory and commit files that should live in version control:
- Config templates (`.template` files for envsubst, or plain ini/xml files)
- Admin/ban lists (if the game has them)
- Any seed files needed for a fresh install

Gitignore generated config and save files. Save `.gz` files are committed by
shutdown.sh and decompressed by setup.sh on each boot.

---

### 5. Packer template — `packer/game/<Game>.pkr.hcl`

Copy `packer/game/Barotrauma.pkr.hcl`. Make these substitutions:

| Placeholder | Replace with |
|-------------|-------------|
| `baroboys-barotrauma` (source block, labels, build name) | `baroboys-<game>` |
| `Barotrauma` in `active-game` echo | `<Game>` |

The provisioner steps are:
1. Clone repo + refresh_repo
2. (Optional) Install dependencies — add steps here for Wine, Java, etc.
3. Write active-game: `echo <Game> > /etc/baroboys/active-game`
4. Run `shared/setup.sh` as bwinter_sc81 (SteamCMD + config)
5. Run `shared/install-game-units.sh` as root (systemd units)
6. Autoremove

See `VRising.pkr.hcl` for the full pattern with extra dependencies.

---

### 6. Terraform — `terraform/game/<Game>.tfvars`

One line:

```hcl
game_image = "baroboys-<game>"
```

---

### 7. Terraform — firewall rules in `terraform/main.tf`

Add a `google_compute_firewall` resource for the game's ports:

```hcl
resource "google_compute_firewall" "<game>_ports" {
  name    = "<game>-ports"
  network = "default"
  allow {
    protocol = "tcp"   # or "udp", or both
    ports    = ["<port>"]
  }
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["game-server"]
}
```

---

### 8. Makefile — `GAMES` list

Add `<Game>` (title case) to the `GAMES` variable:

```makefile
GAMES := Barotrauma VRising <Game>
```

Auto-generates: `make build-game-<Game>`, `make terraform-apply-<Game>`, `make smoke-test-<Game>`.

---

### 9. Admin server — `admin_server.py`

Two places in `tail_log()`:

**`log_map` dict:** add entries for `<game>_startup.log`, `<game>_shutdown.log`, `<game>.log`.
Add a game-engine log entry if the game writes a separate log (like VRising's VRisingServer.log).

**`links` list:** add corresponding entries for the admin panel directory page.

---

## Verification

1. `make build-game-<Game>` — Packer build completes
2. `make terraform-apply-<Game>` — VM provisions and boots
3. SSH in, check `systemctl status game-startup.service` — game process running
4. Check `/etc/baroboys/active-game` — contains `<Game>`
5. Admin panel — new game logs appear in dropdown
6. `make smoke-test-<Game>` — full E2E: provision, checks, destroy

---

## Game-specific notes

### Valheim
- Linux native; no Wine, no Xvfb — use Barotrauma as the Packer template
- `LAUNCH_CMD="./valheim_server.x86_64 -name ... -world ... -password ..."`
- Config is command-line args; minimal post-checkout.sh
- Shutdown: SIGTERM — no RCON
- Saves: `~/.config/unity3d/IronGate/Valheim/worlds_local/`
- Ports: UDP 2456–2458

### Project Zomboid
- Java-based; add `scripts/dependencies/java/apt_java.sh` (openjdk)
- `LAUNCH_CMD="java -jar PZServer.jar"`
- Config: `~/Zomboid/Server/servertest.ini` — password set directly in ini
- Shutdown: SIGTERM — no RCON
- Saves: `~/Zomboid/Saves/Multiplayer/<server-name>/`
- Ports: UDP/TCP 16261, UDP 16262
- Steam App ID: 380870
