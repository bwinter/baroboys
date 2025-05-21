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

sudo -u bwinter_sc81 -- xvfb-run --auto-servernum --server-args='-screen 0 1024x768x24' env \
                          WINETRICKS_GUI=none \
                          WINEDEBUG=-all \
                          winetricks allfonts || echo echo "⚠️ Winetricks fonts failed, continuing anyway"
