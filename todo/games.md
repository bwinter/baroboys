# Games

Adding new game servers. Each game needs just two files (`env-vars.sh` + `post-checkout.sh`)
plus a Packer template and Terraform tfvars/firewall. See `docs/adding-a-game.md`.

## Next up

- **Add Project Zomboid (game 3)** — Java-based dedicated server. Steam App ID 380870.
  `LAUNCH_CMD="java -jar PZServer.jar"`. Config: `~/Zomboid/Server/servertest.ini` (plain ini,
  password set directly). Saves: `~/Zomboid/Saves/Multiplayer/<server-name>/`. Ports: UDP/TCP
  16261, UDP 16262. Shutdown: SIGTERM. New dep: `scripts/dependencies/java/apt_java.sh` (openjdk).

- **Add Valheim (game 4)** — Linux-native, simplest possible addition.

  **env-vars.sh sketch:**
  ```bash
  export STEAM_APP_ID=896660
  export STEAM_PLATFORM="linux"
  export PROCESS_NAME="valheim_server.x86_64"
  export LAUNCH_CMD="./valheim_server.x86_64 -name BaroboysServer -world BaroboysWorld -password \$GAME_PASSWORD -port 2456"
  export SAVE_NAME="BaroboysWorld"
  export SAVE_FILE_PREFIX="BaroboysWorld"
  export SAVE_FILE_PATH="$HOME/.config/unity3d/IronGate/Valheim/worlds_local"
  ```
  Ports: UDP 2456-2458. No Wine, no Xvfb, no RCON. Minimal post-checkout.sh (just password fetch).

## Process

- **Template-based game onboarding** — turn adding-a-game.md into a fillable template.
  Start by creating filled-in markdown versions for VRising and Barotrauma (we know all the
  details). Derive the blank template from those. Then fill it out for Zomboid as the test.
  Markdown works well: prose around code blocks lets you annotate "research the save path here"
  alongside the actual config. The filled template becomes the source for generating env-vars.sh
  and post-checkout.sh.
