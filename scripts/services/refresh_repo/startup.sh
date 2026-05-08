#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

SCRIPT_DIR="$BAROBOYS/scripts/services/refresh_repo"

# Refresh root
# shellcheck source=scripts/services/refresh_repo/src/refresh_repo.sh
# shellcheck disable=SC1091
source "$SCRIPT_DIR/src/refresh_repo.sh"

cp "$SCRIPT_DIR/src/refresh_repo.sh" "/tmp/refresh_repo.sh"
chown bwinter_sc81:bwinter_sc81 "/tmp/refresh_repo.sh"
chmod 755  "/tmp/refresh_repo.sh"

# Now run it as the target user
sudo -u bwinter_sc81 -H -- "/tmp/refresh_repo.sh"

rm -f "/tmp/refresh_repo.sh"
