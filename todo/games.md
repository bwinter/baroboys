# Games

Adding new game servers. Each game needs two config files: the cross-language JSON
(`terraform/game/<Game>.tfvars.json`, including the `templates` list) and `env-vars.sh`.
Plus a Packer template. Firewall rules are generic, driven by `game_ports_udp/tcp` in
the JSON. Template envsubst is handled by `shared/post-checkout.sh`. See
`docs/adding-a-game.md`.

## Next up

- **Add Project Zomboid (game 3)** — Java-based dedicated server. Steam App ID 380870.
  `LAUNCH_CMD="java -jar PZServer.jar"`. Config: `~/Zomboid/Server/servertest.ini` (plain ini,
  password set directly). Saves: `~/Zomboid/Saves/Multiplayer/<server-name>/`. Ports: UDP/TCP
  16261, UDP 16262. Shutdown: SIGTERM. New dep: `scripts/dependencies/java/apt_java.sh` (openjdk).

- **Add Valheim (game 4)** — Linux-native, simplest possible addition.

  **terraform/game/Valheim.tfvars.json sketch:**
  ```json
  {
    "game_image": "valheim",
    "machine_name": "valheim",
    "game_tags": ["valheim"],
    "game_ports_udp": [2456, 2457, 2458],
    "game_ports_tcp": [],
    "game_name": "Valheim",
    "process_name": "valheim_server.x86_64",
    "uses_wine": false,
    "accent_color": "#3b82f6",
    "process_ram_mb_min": 200
  }
  ```

  **env-vars.sh sketch:**
  ```bash
  export STEAM_APP_ID=896660
  export STEAM_PLATFORM="linux"
  export LAUNCH_CMD="./valheim_server.x86_64 -name BaroboysServer -world BaroboysWorld -password \$GAME_PASSWORD -port 2456"
  export SAVE_NAME="BaroboysWorld"
  export SAVE_FILE_PREFIX="BaroboysWorld"
  export SAVE_FILE_PATH="$HOME/.config/unity3d/IronGate/Valheim/worlds_local"
  ```
  No Wine, no Xvfb, no RCON. `templates: []` in the JSON since Valheim uses CLI args
  instead of config files.

## Process

- **Template-based game onboarding** — turn adding-a-game.md into a fillable template.
  Start by creating filled-in markdown versions for VRising and Barotrauma (we know all the
  details). Derive the blank template from those. Then fill it out for Zomboid as the test.
  Markdown works well: prose around code blocks lets you annotate "research the save path here"
  alongside the actual config. The filled template becomes the source for generating
  `tfvars.json` and `env-vars.sh`.
