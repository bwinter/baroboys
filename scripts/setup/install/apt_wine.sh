#!/bin/bash
set -eux

# Add WineHQ key
curl -fsSL "https://dl.winehq.org/wine-builds/winehq.key" \
  | gpg --dearmor -o "/usr/share/keyrings/winehq.gpg"

# Add the repo for Bookworm
echo "deb [signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian bookworm main" \
  > "/etc/apt/sources.list.d/winehq.list"

sudo dpkg --add-architecture amd64
sudo apt-get -yq update

sudo apt -yq install \
  wine-stable-amd64 \
  wine64 \
  winetricks \
  xvfb

echo "🌀 Installing fonts..."

# Initialize Wine prefix (once!)
/usr/bin/sudo -u bwinter_sc81 -- bash -c '
  echo "🔧 Initializing wine prefix..."
  export WINEARCH=win64
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  /opt/wine-stable/bin/wine64 wineboot
'

# Run winetricks under xvfb
sudo -u bwinter_sc81 -- bash -c '
  echo "🔧 Installing corefonts and tahoma via winetricks..."
  export WINE=/opt/wine-stable/bin/wine64
  export WINEARCH=win64
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  export WINETRICKS_GUI=none
  xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
    winetricks --unattended corefonts tahoma || echo "⚠️ winetricks failed"
'

# --- Selective Cleanup ---

# Purge only the 32-bit and helper stuff
sudo apt -yq purge --auto-remove \
  wine32 \
  wine-stable-i386 \
  winetricks || true

# Reinstall 64-bit only (minimal deps)
sudo apt -yq --no-install-recommends install \
  wine64 \
  wine-stable-amd64

echo "✅ Fonts install attempt complete."
