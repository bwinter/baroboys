# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# VRising game-specific configuration.

# Steam
STEAM_APP_ID=1829350 # SETUP: REQUIRED
STEAM_PLATFORM="windows" # SETUP: OPTIONAL

SAVE_FILE_NAME="AutoSave_*" # SETUP: OPTIONAL
SAVE_FILE_PATH="$GAME_DIR/Data/Saves/v4/$SAVE_FILE_NAME" # SETUP: OPTIONAL

RCON_PASSWORD="$(gcloud secrets versions access latest --secret=rcon-password)" # SETUP: run `make update-rcon-password` to create this secret
RCON_PORT=25575
RCON_SHUTDOWN_DELAY_MINUTES=1

# Checkout
# SETUP: OPTIONAL
ADMIN_LIST="Data/Settings/adminlist.txt"
BAN_LIST="Data/Settings/banlist.txt"

ADMIN_LIST="$GAME_DIR/$ADMIN_LIST"
BAN_LIST="$GAME_DIR/$BAN_LIST"

CHECKOUT_LIST= \
  "$ADMIN_LIST" \
  "$BAN_LIST"
