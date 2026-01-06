#!/usr/bin/env bash
set -euxo pipefail

echo "# 🧱 Print contents of some repo files."
echo "This file is designed to be edited to change the files printed."
echo "The goal is to make a large blob that can be shared with ChatGPT."
echo "Generated: $(date -u)"

add_section() {
  local path="$1"
  if [[ -f "$path" ]]; then
    echo -e "\n\n# === ($path) ==="
    echo '```bash'
    cat "$path"
    echo '```'
  else
    echo -e "\n\n# === ($path) ==="
    echo "**Missing file**"
  fi
}

add_section \
  "VRising/VRisingServer_Data/StreamingAssets/Settings/ServerHostSettings.json"

add_section \
  "VRising/VRisingServer_Data/StreamingAssets/Settings/ServerGameSettings.json"
