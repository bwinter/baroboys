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

runuser -l bwinter_sc81 -c '
  set -x
  echo $HOME
  echo $USER
  export WINETRICKS_GUI=none
  env | sort
  which winetricks
  which wine
  winetricks corefonts tahoma
' 2>&1 | tee /tmp/winetricks_debug.log

sudo -u bwinter_sc81 -- bash -c '
  set -x
  export HOME=/home/bwinter_sc81
  timeout 180s \
    env WINETRICKS_GUI=none \
    xvfb-run -a -e /tmp/xvfb.err.log \
      --server-args="-screen 0 1024x768x24" \
      winetricks --unattended corefonts tahoma \
    || echo "⚠️ winetricks timeout or failure"
  cat /tmp/xvfb.err.log || echo "⚠️ no xvfb log found"
'

echo "✅ Fonts install attempt complete."