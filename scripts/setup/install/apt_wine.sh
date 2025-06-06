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
  winetricks \
  xvfb

echo "🌀 Installing fonts..."

# Initialize Wine prefix (once!)
/usr/bin/sudo -u bwinter_sc81 -- bash -c '
  echo "🧪 UID is: $(id -u)"
  echo "🧪 TMPDIR: $TMPDIR"
  echo "🧪 XDG_RUNTIME_DIR: $XDG_RUNTIME_DIR"
  echo "🧪 Expected wineserver dir: /tmp/.wine-$(id -u)/"

  echo "🔧 Initializing wine prefix..."
  export WINEARCH=win64
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  export WINEDEBUG=+server,+wineserver,+file,+pid,+timestamp
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
  winetricks || true

dpkg --list | grep ':i386'

echo "✅ Fonts install attempt complete."
