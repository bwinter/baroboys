#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"
# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
# shellcheck disable=SC1091  # $GAME_NAME is runtime-resolved; shellcheck can't follow
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

echo "🚀 $GAME_NAME launcher started at $(date)"

# Keep the service lifecycle marker above in game_startup.log, while routing
# launcher/runtime output for every game to the shared game log. Games with
# native file logging (such as VRising's -logFile) continue to use that path;
# this also captures stdout/stderr from the launcher and Wine.
exec >> "$LOG_FILE" 2>&1

: "${LAUNCH_CMD:?LAUNCH_CMD not set — check game env-vars.sh}"

$LAUNCH_CMD
