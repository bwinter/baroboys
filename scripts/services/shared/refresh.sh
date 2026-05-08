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
: "${STEAM_PLATFORM:?STEAM_PLATFORM not set — check game env-vars.sh}"
: "${GAME_DIR:?GAME_DIR not set — check shared env-vars.sh}"
: "${CHECKOUT_LIST:?CHECKOUT_LIST not set — check game env-vars.sh}"

# Warm login before the real app_update. This works around intermittent SteamCMD failures
# that occur when the depot cache or config hasn't been initialised yet. Root cause is
# unknown; removing this call makes builds flaky. Do not simplify.
/usr/games/steamcmd \
  +login anonymous \
  +quit

/usr/games/steamcmd \
  +@sSteamCmdForcePlatformType "$STEAM_PLATFORM" \
  +force_install_dir "$GAME_DIR" \
  +login anonymous \
  +app_update "$STEAM_APP_ID" validate \
  +quit

# Restore canonical server configs
cd "$GAME_DIR"
# Intentional word splitting — CHECKOUT_LIST is space-separated paths.
# shellcheck disable=SC2086
git checkout -- $CHECKOUT_LIST

# shellcheck source=scripts/services/$GAME_NAME/post-checkout.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/post-checkout.sh"

# === Decompress saves ===
# Decompress all .gz saves matching the prefix. Without -f, gunzip skips files
# that already exist — protecting uncommitted saves from being overwritten.
if [[ -d "${SAVE_FILE_PATH:-}" && -n "${SAVE_FILE_PREFIX:-}" ]]; then
  find "$SAVE_FILE_PATH" -maxdepth 1 -name "${SAVE_FILE_PREFIX}*.gz" -exec gunzip -k {} \; 2>/dev/null || true
fi

# Systemd unit installation is handled separately by install-game-units.sh
# (runs as root at Packer build time only — units are baked into the image).

# --- Write game manifest for cross-language consumers ---
# Cross-language source of truth lives in terraform/game/<Game>.tfvars.json
# (Terraform reads it natively for firewall + VM config; we read it here to
# build the runtime manifest). Manifest at /etc/baroboys/manifest.json is
# what admin_server.py reads — narrower projection (adds log_files derived
# from runtime context like Wine/Xvfb).
GAME_TFVARS="$BAROBOYS/terraform/game/${GAME_NAME}.tfvars.json"

manifest_log_files=(game.log admin_server.log refresh_repo.log idle_check.log infrastructure.log)
# Whether to add xvfb.log: read uses_wine from the per-game JSON. The
# python3 dependency is already used by idle_check.sh; no new install.
if python3 -c "import json,sys; sys.exit(0 if json.load(open('$GAME_TFVARS')).get('uses_wine', False) else 1)"; then
  manifest_log_files+=(xvfb.log)
fi
manifest_log_files_json="$(printf '"%s",' "${manifest_log_files[@]}" | sed 's/,$//')"

# Splice log_files into the source JSON to produce the manifest. Everything
# else (game_name, process_name, uses_wine, ports, accent_color) is copied
# straight from the per-game tfvars.json. This keeps the manifest a strict
# function of the source-of-truth file plus runtime-derived log_files.
python3 <<PY > /tmp/baroboys-manifest.json
import json
src = json.load(open("$GAME_TFVARS"))
manifest = {
    "game_name":     src["game_name"],
    "process_name":  src["process_name"],
    "uses_wine":     src["uses_wine"],
    "log_files":     [${manifest_log_files_json}],
    "ports": {
        "udp": src.get("game_ports_udp", []),
        "tcp": src.get("game_ports_tcp", []),
    },
    "accent_color":  src.get("accent_color", "#0d6efd"),
    "process_ram_mb_min": src.get("process_ram_mb_min", 200),
}
print(json.dumps(manifest, indent=2))
PY
sudo install -m 644 /tmp/baroboys-manifest.json /etc/baroboys/manifest.json
rm -f /tmp/baroboys-manifest.json