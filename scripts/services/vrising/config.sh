# Interpolate into Configs
# SETUP: OPTIONAL
export GAME_PASSWORD
export SAVE_FILE_NAME
export RCON_PASSWORD
export RCON_PORT

HOST_JSON_IN="ServerHostSettings.json.template"
GAME_JSON_IN="ServerGameSettings.json.template"

HOST_JSON_OUT="VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"
GAME_JSON_OUT="VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"

HOST_JSON_IN="$GAME_DIR/$HOST_JSON_IN"
GAME_JSON_IN="$GAME_DIR/$GAME_JSON_IN"

HOST_JSON_OUT="$GAME_DIR/$HOST_JSON_OUT"
GAME_JSON_OUT="$GAME_DIR/$GAME_JSON_OUT"

envsubst < "$HOST_JSON_IN" > "$HOST_JSON_OUT"
envsubst < "$GAME_JSON_IN" > "$GAME_JSON_OUT"

# SETUP: OPTIONAL --- DECOMPRESS SAVE

# File exists and name not empty.
# TODO: Fix `if` statement
if [[ -[file exist] $SAVE_FILE_PATH ]] then
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
