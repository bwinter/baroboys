#!/usr/bin/env bash
# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../shared/env-vars.sh"

# Valheim game-specific configuration.

# Steam
export STEAM_APP_ID=896660 # SETUP: REQUIRED
export STEAM_APP_PLATFORM="linux" # SETUP: OPTIONAL

export SAVE_NAME="Donaldsheim" # SETUP: OPTIONAL — save/world identity; feeds config template and path
export SAVE_FILE_PATTERN="*" # SETUP: OPTIONAL — filename glob for save compression
export SAVE_FILE_PATH="$GAME_DIR/worlds_local/$SAVE_NAME" # SETUP: OPTIONAL — directory containing saves
# Valheim saves are a coordinated directory of generation-specific files.
# Keep the raw Git save authoritative until the legacy per-file compression path
# has been redesigned and validated for this format.
export SAVE_COMPRESSION_ENABLED=0
export SAVE_BUCKET_BACKUP_ENABLED=0

GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"

# Checkout
# SETUP: REQUIRED — git checkout uses this; empty value would checkout everything
ADMIN_LIST="adminlist.txt"
BAN_LIST="bannedlist.txt"
PERMISSION_LIST="permittedlist.txt"

ADMIN_LIST="$GAME_DIR/$ADMIN_LIST"
BAN_LIST="$GAME_DIR/$BAN_LIST"
PERMISSION_LIST="$GAME_DIR/$PERMISSION_LIST"

export CHECKOUT_LIST="$ADMIN_LIST $BAN_LIST $PERMISSION_LIST"

# SETUP: REQUIRED — the command that launches the game server
# Keep Valheim's bounded automatic-backup policy explicit instead of relying on
# version-dependent defaults: one 2-hour backup and three 12-hour backups.
export LAUNCH_CMD="./valheim_server.x86_64 -name SnowCrashServer -world $SAVE_NAME -password $GAME_PASSWORD -port 2456 -crossplay -savedir $GAME_DIR -backups 4 -backupshort 7200 -backuplong 43200"
