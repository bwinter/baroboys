# Adding a New Game

Step-by-step guide for onboarding a new game server. Use `<Game>` as a placeholder
for the title-case game name (e.g. `VRising`, `Barotrauma`, `Zomboid`).

---

## Overview: What Changes

| Layer | What to create/modify |
|-------|----------------------|
| `terraform/game/<Game>.tfvars.json` | Cross-language source of truth: machine name, image, tags, ports, accent, process name, RAM floor, uses_wine, template list. Read by Terraform AND by bash (manifest, smoke test, post-checkout). |
| `scripts/services/<Game>/env-vars.sh` | Bash-only game-specific variables (Steam app id, save paths, RCON, CHECKOUT_LIST, LAUNCH_CMD) |
| `scripts/dependencies/` | New apt installers if the game needs them (Java, Wine, etc.) |
| `<Game>/` (repo root) | Game state: saves, config templates, admin/ban lists |
| `packer/game/<Game>.pkr.hcl` | Packer image template |
| `Makefile` | Add to `GAMES` list — auto-generates 3 targets |

**You do NOT need to create:** post-checkout.sh, startup.sh, shutdown.sh, refresh.sh, systemd
units, firewall rules, or admin-server log entries. Firewall rules generate from
`game_ports_udp/tcp` in the JSON; admin-panel log dropdown reads the runtime manifest
projected from the same JSON; `shared/post-checkout.sh` envsubst's every `(input, output)`
pair declared in `templates`. Lifecycle scripts are shared and driven by env-vars.sh + manifest.

Build order: always `base/core → base/admin → game/<Game>`.

---

## Checklist

### 1. Cross-language config — `terraform/game/<Game>.tfvars.json`

The single source of truth for everything Terraform AND bash both need to know about the game.
Read natively by Terraform; read by `shared/refresh.sh` to project the runtime manifest at
`/etc/baroboys/manifest.json`; downstream consumers (`shared/post-checkout.sh`,
`shared/shutdown.sh`, `idle_check.sh`, smoke test) read from the manifest via `jq`.

Copy `terraform/game/Barotrauma.tfvars.json` and edit:

```json
{
  "game_image": "<game>",
  "machine_name": "<game>",
  "game_tags": ["<game>"],

  "game_ports_udp": [<port>, <port>],
  "game_ports_tcp": [],

  "game_name": "<Game>",
  "process_name": "<binary>",
  "uses_wine": false,
  "accent_color": "#<hex>",
  "process_ram_mb_min": 200,

  "templates": [
    ["<input>.template", "<output-path-in-game-dir>"]
  ]
}
```

Notes:
- `game_image`/`machine_name`/`game_tags` are GCP/Terraform identifiers — keep them lowercase.
- `game_name` is the title-case display name; matches the directory and Makefile entry.
- `process_name` is what `pgrep` / `pkill` matches in `shared/shutdown.sh` and `idle_check.sh`.
- `uses_wine: true` makes `shared/refresh.sh` add `xvfb.log` to the manifest's log list.
- `process_ram_mb_min` is the floor below which the smoke test marks the game "still booting".
- `templates` is the list of `(input, output)` pairs `shared/post-checkout.sh` envsubst's on
  every boot. Both paths are relative to `GAME_DIR`. Available substitutions: `${GAME_PORT}`,
  `${GAME_QUERY_PORT}` (from `game_ports_udp[0..1]`), `${GAME_PASSWORD}` (server-password
  secret), `${SAVE_NAME}`, `${RCON_PORT}`, `${RCON_PASSWORD}` (from env-vars.sh).

### 2. Game config — `scripts/services/<Game>/env-vars.sh`

Bash-only game state. Copy the nearest existing game and set the `SETUP:` marked variables.
Use `grep SETUP scripts/services/` to see every decision point across existing games.

```bash
# SETUP: REQUIRED
export STEAM_APP_ID=<id>
export STEAM_PLATFORM="linux"     # "linux" for native; "windows" for Wine
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

`process_name`, ports, accent color, uses_wine, and the template list all live in the JSON
tfvars (step 1) — do not duplicate them here.

There is no per-game `post-checkout.sh`. `shared/post-checkout.sh` reads the manifest's
`templates` list and envsubst's every pair. If a new game needs game-specific bash beyond
template rendering, that logic belongs in `env-vars.sh` (which is sourced before
`post-checkout.sh` runs) — see Barotrauma's symlink dance for the reference pattern.

---

### 3. Dependencies — `scripts/dependencies/`

If the game needs a system package not already installed in `base/core` or `base/admin`,
add an installer script:

```
scripts/dependencies/<dep>/apt_<dep>.sh
```

Call it from the Packer template (step 5) before `shared/refresh.sh`.

Examples: VRising needed Wine + Xvfb. Project Zomboid needs openjdk.
Barotrauma and Valheim (Linux native) need nothing extra.

---

### 4. Game data directory — `<Game>/` (repo root)

Create the directory and commit files that should live in version control:
- Config templates (`.template` files for envsubst, or plain ini/xml files)
- Admin/ban lists (if the game has them)
- Any seed files needed for a fresh install

Gitignore generated config and save files. Save `.gz` files are committed by
shutdown.sh and decompressed by refresh.sh on each boot.

---

### 5. Packer template — `packer/game/<Game>.pkr.hcl`

Copy `packer/game/Barotrauma.pkr.hcl`. Make these substitutions:

| Placeholder | Replace with |
|-------------|-------------|
| `barotrauma` (source block, labels, build name) | `<game>` (lowercase) |
| `Barotrauma` in `active-game` echo | `<Game>` |

The provisioner steps are:
1. Clone repo + refresh_repo
2. (Optional) Install dependencies — add steps here for Wine, Java, etc.
3. Write active-game: `echo <Game> > /etc/baroboys/active-game`
4. Run `shared/refresh.sh` as bwinter_sc81 (SteamCMD + config)
5. Run `shared/install-game-units.sh` as root (systemd units)
6. Autoremove

See `VRising.pkr.hcl` for the full pattern with extra dependencies.

---

### 6. Makefile — `GAMES` list

Add `<Game>` (title case) to the `GAMES` variable:

```makefile
GAMES := Barotrauma VRising <Game>
```

Auto-generates: `make build-game-<Game>`, `make terraform-apply-<Game>`, `make smoke-test-<Game>`.

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
