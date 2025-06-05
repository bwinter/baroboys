#!/bin/bash
set -euo pipefail

echo "# 🧱 Baroboys Admin UI + Status Logic"
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
