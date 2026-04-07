#!/usr/bin/env bash
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

# -d: save directory exists; -n: SAVE_FILE_NAME is non-empty.
if [[ -d "$SAVE_FILE_PATH" && -n "$SAVE_FILE_NAME" ]]; then
  # Ensure save is uncompressed

  pushd "$SAVE_FILE_PATH" || exit 1
    # Find the latest uncompressed save (if any).
    # sed -E: extended regex; captures numeric suffix, prepends it so sort can rank by number.
    # sort -n: numeric sort; tail -n1: keep only the last (highest-numbered) result.
    latest_save=$(find . -name "$SAVE_FILE_NAME*.save" | sed -E "s/.*$SAVE_FILE_NAME([0-9]+)\.save/\1 \0/" | sort -n | tail -n1)
    save_num=$(cut -d' ' -f1 <<< "$latest_save") # -d' ': split on space; -f1: first field (the number); <<<: here-string
    save_file=$(cut -d' ' -f2 <<< "$latest_save") # -f2: second field (the filename)

    # Find the latest compressed save.
    latest_gz=$(find . -name "$SAVE_FILE_NAME*.save.gz" | sed -E "s/.*$SAVE_FILE_NAME([0-9]+)\.save\.gz/\1 \0/" | sort -n | tail -n1)
    gz_num=$(cut -d' ' -f1 <<< "$latest_gz") # first field: the number
    gz_file=$(cut -d' ' -f2 <<< "$latest_gz") # second field: the filename

    # Decide if we need to decompress
    if [[ -z "$gz_file" ]]; then # -z: string is empty (no .gz found)
      echo "⚠️ No compressed autosaves found." >> "$LOG_FILE"

    # -z: no .save exists yet; -gt: gz has a higher (newer) autosave number than the .save.
    elif [[ -z "$save_file" || "$gz_num" -gt "$save_num" ]]; then
      echo "🗜 Decompressing newer autosave: $gz_file" >> "$LOG_FILE"
      gunzip -kf "$gz_file" # -k: keep the .gz original; -f: overwrite existing .save if present
    else
      echo "✅ Latest .save is up-to-date or newer than .gz" >> "$LOG_FILE"
    fi
  popd || exit 1
fi
