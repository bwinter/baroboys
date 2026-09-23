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

## Completed

- **Add Valheim (game 4)** — Linux-native server deployed and validated through a full
  lifecycle test. Save handling and the shared static-IP/DuckDNS endpoint were also tested.

## Process

- **Template-based game onboarding** — turn adding-a-game.md into a fillable template.
  Start by creating filled-in markdown versions for VRising and Barotrauma (we know all the
  details). Derive the blank template from those. Then fill it out for Zomboid as the test.
  Markdown works well: prose around code blocks lets you annotate "research the save path here"
  alongside the actual config. The filled template becomes the source for generating
  `tfvars.json` and `env-vars.sh`.
