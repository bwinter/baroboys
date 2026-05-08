#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
# shellcheck disable=SC1091
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# Single canonical clone — refresh-repo-startup.service runs as bwinter_sc81,
# and the source script targets /home/bwinter_sc81/baroboys regardless of who
# invokes it. No more cp-to-/tmp + sudo dance: just source and run.
# shellcheck source=scripts/services/refresh_repo/src/refresh_repo.sh
# shellcheck disable=SC1091
source "$BAROBOYS/scripts/services/refresh_repo/src/refresh_repo.sh"
