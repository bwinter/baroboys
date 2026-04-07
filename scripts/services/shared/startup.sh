#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/env-vars.sh"
# shellcheck source=scripts/services/$GAME_NAME/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../$GAME_NAME/env-vars.sh"

echo "🚀 $GAME_NAME launcher started at $(date)"

: "${LAUNCH_CMD:?LAUNCH_CMD not set — check game env-vars.sh}"

$LAUNCH_CMD
