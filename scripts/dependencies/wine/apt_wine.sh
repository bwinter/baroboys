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
  wine-stable \
  winetricks

# Show version of wine64
echo "ℹ️ wine version info:"
/opt/wine-stable/bin/wine64 --version || echo "⚠️ wine64 not working"

# Initialize Wine prefix (once!)
sudo -u bwinter_sc81 -- "/home/bwinter_sc81/baroboys/scripts/dependencies/wine/src/setup_wine.sh"

echo "✅ Fonts install attempt complete."
