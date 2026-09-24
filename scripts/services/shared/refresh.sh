#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"

# Mark refresh start in log (dir already created by admin_server/refresh.sh as root)
touch "$LOG_FILE"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$LOG_FILE"

# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

# Preconditions — fail fast before any side effects
: "${STEAM_APP_ID:?STEAM_APP_ID not set — check game env-vars.sh}"
: "${STEAM_APP_PLATFORM:?STEAM_APP_PLATFORM not set — check game env-vars.sh}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"

# --- Write game manifest for cross-language consumers ---
# The manifest only depends on the active game configuration and Terraform
# metadata. Write it before SteamCMD validation so admin_server.py can expose
# /api/manifest while a slow game refresh is still in progress.
GAME_TFVARS="$BAROBOYS/terraform/game/${GAME_NAME}.tfvars.json"

manifest_log_files=(game.log admin_server.log refresh_repo.log idle_check.log infrastructure.log)
# Whether to add xvfb.log: read uses_wine from the per-game JSON.
if [[ "$(jq -r '.uses_wine // false' "$GAME_TFVARS")" == "true" ]]; then
  manifest_log_files+=(xvfb.log)
fi
manifest_log_files_json="$(printf '"%s",' "${manifest_log_files[@]}" | sed 's/,$//')"

# Splice runtime-derived fields into the source JSON to produce the manifest.
# Cross-language game metadata comes from tfvars; paths come from the active
# game's env-vars so shared services do not rebuild per-game paths themselves.
python3 <<PY > /tmp/baroboys-manifest.json
import json
import os
src = json.load(open("$GAME_TFVARS"))
manifest = {
    "game_dir":      os.environ.get("GAME_DIR"),
    "game_name":     src["game_name"],
    "process_name":  src["process_name"],
    "save_name":     os.environ.get("SAVE_NAME"),
    "save_path":     os.environ.get("SAVE_FILE_PATH"),
    "uses_wine":     src["uses_wine"],
    "log_files":     [${manifest_log_files_json}],
    "ports": {
        "udp": src.get("game_ports_udp", []),
        "tcp": src.get("game_ports_tcp", []),
    },
    "accent_color":  src.get("accent_color", "#0d6efd"),
    # Treat a missing or explicit null RAM floor as the same default.
    "process_ram_mb_min": src.get("process_ram_mb_min") or 200,
    "templates":     src.get("templates", []),
}
print(json.dumps(manifest, indent=2))
PY
sudo install -m 644 /tmp/baroboys-manifest.json /etc/baroboys/manifest.json
rm -f /tmp/baroboys-manifest.json

# Warm login before the real app_update. This works around intermittent SteamCMD failures
# that occur when the depot cache or config hasn't been initialised yet. Root cause is
# unknown; removing this call makes builds flaky. Do not simplify.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType "$STEAM_APP_PLATFORM" \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$STEAM_APP_ID" validate \
  +quit

# Restore canonical server configs
cd "$GAME_DIR"
# CHECKOUT_LIST is optional: some games have no repository-owned files to restore.
if [[ -n "${CHECKOUT_LIST:-}" ]]; then
  # Intentional word splitting — CHECKOUT_LIST is space-separated paths.
  # shellcheck disable=SC2086
  git checkout -- $CHECKOUT_LIST
fi

# Run shared post-checkout: secret fetch + envsubst all manifest.templates.
# shellcheck source=scripts/services/shared/post-checkout.sh
source "$(dirname "${BASH_SOURCE[0]}")/post-checkout.sh"

# === Decompress saves ===
# Decompress all .gz saves matching the pattern. Without -f, gunzip skips files
# that already exist — protecting uncommitted saves from being overwritten.
if [[ -d "${SAVE_FILE_PATH:-}" && -n "${SAVE_FILE_PATTERN:-}" ]]; then
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PATTERN}.gz" -exec gunzip -k {} \; 2>/dev/null || true
fi

# Systemd unit installation is handled separately by install-game-units.sh
# (runs as root at Packer build time only — units are baked into the image).
