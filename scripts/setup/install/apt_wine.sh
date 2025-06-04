#!/bin/bash
set -eux

# Add WineHQ key
curl -fsSL "https://dl.winehq.org/wine-builds/winehq.key" \
  | gpg --dearmor -o "/usr/share/keyrings/winehq.gpg"

# Add the repo for Bookworm
echo "deb [signed-by=/usr/share/keyrings/winehq.gpg] https://dl.winehq.org/wine-builds/debian bookworm main" \
  > "/etc/apt/sources.list.d/winehq.list"

apt-get -yq update
apt-get install -yq winehq-stable winetricks xvfb

echo "🌀 Installing fonts..."

# Initialize Wine prefix (once!)
/usr/bin/sudo -u bwinter_sc81 -- bash -c '
  echo "🔧 Initializing wine prefix..."
  export WINEARCH=win64
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  wineboot -i
'

# Run winetricks under xvfb
sudo -u bwinter_sc81 -- bash -c '
  echo "🔧 Installing corefonts and tahoma via winetricks..."
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  export WINETRICKS_GUI=none
  xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
    winetricks --unattended corefonts tahoma || echo "⚠️ winetricks failed"
'

echo "✅ Fonts install attempt complete."
