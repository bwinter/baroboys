#!/bin/bash
set -eux

echo "🌀 Installing fonts..."

# Set wine env
export WINE=/usr/bin/wine
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
export WINETRICKS_GUI=none

# UID info and TMPDIR
echo "🧪 UID: $(id -u)"
echo "🧪 TMPDIR: ${TMPDIR:-/tmp}"
echo "🧪 XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-"(unset)"}"
echo "🧪 HOME: $HOME"

# Launch wineboot
/usr/bin/wine wineboot || echo "⚠️ wineboot failed"

echo "✅ Debug trace complete."

echo "🔧 Installing corefonts and tahoma via winetricks..."
xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
  winetricks --unattended corefonts tahoma || echo "⚠️ winetricks failed"