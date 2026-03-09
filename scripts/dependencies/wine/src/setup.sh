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

# wineboot MUST run with no DISPLAY set (headless). Setting DISPLAY=:0 before wineboot
# causes Wine 11 to fail with "start_rpcss Failed" → "boot event wait timed out" →
# "could not load kernel32.dll". The prefix initialises fine in headless mode.
# unset is used here (not just omitting the export) so that this holds even if DISPLAY
# is set earlier in the environment — making the order of any future export irrelevant.
unset DISPLAY

# Launch wineboot (Wine 11+ uses 'wine' unified binary; wine64 was removed)
/opt/wine-stable/bin/wine wineboot || {
  echo "⚠️ wineboot failed" >&2
  exit 1
}

echo "✅ Wine prefix initialized."

# DISPLAY is required from this point on — winetricks needs X to install fonts.
export DISPLAY=:0

echo "🔧 Installing corefonts and tahoma via winetricks..."
winetricks --unattended corefonts tahoma || {
  echo "⚠️ winetricks failed" >&2
  exit 1
}
