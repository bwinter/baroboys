#!/usr/bin/env bash
set -euxo pipefail

# Record active game — read by admin panel (multi-game awareness) and smoke test (self-identification).
mkdir -p /etc/baroboys
echo "$GAME_NAME" > /etc/baroboys/active-game

LOG_PATH="/var/log/baroboys"
LOG_FILE="${LOG_PATH}/${GAME_NAME}.log"

# Give Admin Server access to logs.
mkdir -p "$LOG_PATH"
chown bwinter_sc81:bwinter_sc81  "$LOG_PATH"
chmod 700  "$LOG_PATH"

touch "$LOG_FILE"
printf "\n==== %s ====\n" "$(date +%Y/%m/%d-%H:%M:%S)" >> "$LOG_FILE"
chown bwinter_sc81:bwinter_sc81  "$LOG_FILE"
chmod 644  "$LOG_FILE"

# Warm SteamCMD before the real install call.
# Without this, SteamCMD intermittently fails to start the installer correctly — likely a
# first-run initialization issue (depot cache, config, or update manifest setup). Running a
# bare login+quit first does a clean pave of whatever internal state SteamCMD needs, and
# the subsequent app_update call reliably succeeds. Root cause is unclear; workaround was
# found via community reports of similar intermittent SteamCMD failures.
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
cd "$BAROBOYS"
git checkout -- "$CHECKOUT_LIST"

# --- DECOMPRESS SAVE

# File exists and name not empty.
# TODO: Fix `if` statement
if [[ -[file exist] $SAVE_FILE_PATH && -[not empty] $SAVE_FILE_NAME ]] then
  # Ensure save is uncompressed
  cd "$SAVE_FILE_PATH"

  # Find the latest uncompressed save (if any)
  latest_save=$(find . -name "$SAVE_FILE_NAME*.save" | sed -E "s/.*$SAVE_FILE_NAME([0-9]+)\.save/\1 \0/" | sort -n | tail -n1)
  save_num=$(cut -d' ' -f1 <<< "$latest_save") # How do these work?
  save_file=$(cut -d' ' -f2 <<< "$latest_save") # How do these work?

  # Find the latest compressed save
  latest_gz=$(find . -name "$SAVE_FILE_NAME*.save.gz" | sed -E "s/.*$SAVE_FILE_NAME([0-9]+)\.save\.gz/\1 \0/" | sort -n | tail -n1)
  gz_num=$(cut -d' ' -f1 <<< "$latest_gz") # How do these work?
  gz_file=$(cut -d' ' -f2 <<< "$latest_gz") # How do these work?

  # Decide if we need to decompress
  if [[ -z "$gz_file" ]]; then
    echo "⚠️ No compressed autosaves found." >> "$LOG_FILE"

    # TODO: Explain `if` statement
  elif [[ -z "$save_file" || "$gz_num" -gt "$save_num" ]]; then
    echo "🗜 Decompressing newer autosave: $gz_file" >> "$LOG_FILE"
    gunzip -kf "$gz_file"
  else
    echo "✅ Latest .save is up-to-date or newer than .gz" >> "$LOG_FILE"
  fi
fi

SERVICE_SETUP_TEMPLATE="$BAROBOYS/scripts/services/templates/game-setup.service"
SERVICE_STARTUP_TEMPLATE="$BAROBOYS/scripts/services/templates/game-startup.service"
SERVICE_SHUTDOWN_TEMPLATE="$BAROBOYS/scripts/services/templates/game-shutdown.service"

SERVICE_SETUP_TMP="/tmp/scripts/services/templates/game-setup.service"
SERVICE_STARTUP_TMP="/tmp/scripts/services/templates/game-startup.service"
SERVICE_SHUTDOWN_TMP="/tmp/scripts/services/templates/game-shutdown.service"

# Requires $BAROBOYS & $GAME_NAME
envsubst < "$SERVICE_SETUP_TEMPLATE" > "$SERVICE_SETUP_TMP"
envsubst < "$SERVICE_STARTUP_TEMPLATE" > "$SERVICE_STARTUP_TMP"
envsubst < "$SERVICE_SHUTDOWN_TEMPLATE" > "$SERVICE_SHUTDOWN_TMP"

# Install Services
sudo install -m 644 "/tmp/game-setup.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/tmp/game-startup.service" \
  "/etc/systemd/system/"
sudo install -m 644 "/tmp/game-shutdown.service" \
  "/etc/systemd/system/"

# Enable Services
sudo systemctl daemon-reload
sudo systemctl enable game-setup.service
sudo systemctl enable game-startup.service
sudo systemctl enable game-shutdown.service