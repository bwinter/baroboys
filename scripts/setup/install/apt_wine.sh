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
sudo -u bwinter_sc81 --
  env WINETRICKS_GUI=none \
  xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' \
  winetricks --unattended corefonts tahoma \
  || echo echo "⚠️ Winetricks fonts failed, continuing anyway"
echo "✅ Fonts install attempt complete."