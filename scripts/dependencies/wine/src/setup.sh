#!/usr/bin/env bash
set -euxo pipefail

echo "🌀 Installing fonts..."

# UID info and TMPDIR
echo "🧪 UID: $(id -u)"
echo "🧪 HOME: $HOME"

# Set wine env
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
export WINE=/opt/wine-stable/bin/wine
export WINESERVER=/opt/wine-stable/bin/wineserver
export WINETRICKS_GUI=none
export DISPLAY=:0  # Xvfb is already running at :0 (started by apt_wine.sh)

# Launch wineboot (Wine 11+ uses 'wine' unified binary; wine64 was removed)
/opt/wine-stable/bin/wine wineboot || {
  echo "⚠️ wineboot failed" >&2
  exit 1
}

echo "✅ Wine prefix initialized."

echo "🔧 Installing corefonts and tahoma via winetricks..."
winetricks --unattended corefonts tahoma || {
  echo "⚠️ winetricks failed" >&2
  exit 1
}
