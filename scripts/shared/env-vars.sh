export BAROBOYS="$HOME/baroboys"

# TODO: Prevent Masking
export GAME_NAME="$(cat /etc/baroboys/active-game)"
export GAME_DIR="$BAROBOYS/$GAME_NAME"
GAME_PASSWORD="$(gcloud secrets versions access latest --secret=server-password)"

export LOG_PATH="/var/log/baroboys"
export LOG_FILE="${LOG_PATH}/game.log"

# TODO: Would be curious to know if this can be deleted.
#  We made some updates to wine a while back.
WINEPREFIX="$HOME/.wine64"
# Only necessary for some games, would be nice to delete.
