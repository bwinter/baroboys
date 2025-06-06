#!/bin/bash
set -eux

echo "🌀 Installing fonts..."

# Set wine env
export WINEARCH=win64
export WINEPREFIX=/home/bwinter_sc81/.wine64
export WINETRICKS_GUI=none

# UID info and TMPDIR
echo "🧪 UID: $(id -u)"
echo "🧪 TMPDIR: ${TMPDIR:-/tmp}"
echo "🧪 XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-"(unset)"}"
echo "🧪 HOME: $HOME"

# Launch wineboot
/opt/wine-stable/bin/wine64 wineboot || echo "⚠️ wineboot failed"

echo "✅ Debug trace complete."

sudo apt -yq install \
  winetricks

export WINE=/opt/wine-stable/bin/wine64

echo "🔧 Installing corefonts and tahoma via winetricks..."
xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
  winetricks --unattended corefonts tahoma || echo "⚠️ winetricks failed"

# --- Selective Cleanup ---
sudo apt -yq purge --auto-remove \
  winetricks || true