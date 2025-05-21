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
#!/bin/bash
set -euo pipefail
set -x

USER_HOME="/home/bwinter_sc81"

########################################
echo "\n[🧪 BASELINE] Whoami + env"
runuser -l bwinter_sc81 -c '
  whoami
  echo $HOME
  env | grep -E "^USER=|^HOME=|DISPLAY|WINE"
'
sudo -u bwinter_sc81 -- bash -c '
  whoami
  echo $HOME
  env | grep -E "^USER=|^HOME=|DISPLAY|WINE"
'

########################################
echo "\n[🧪 TOOL CHECK] wine + winetricks availability"
runuser -l bwinter_sc81 -c '
  command -v wine
  command -v winetricks
  wine --version || true
  winetricks --version || true
'
sudo -u bwinter_sc81 -- bash -c '
  command -v wine
  command -v winetricks
  wine --version || true
  winetricks --version || true
'

########################################
echo "\n[🧪 PREFIX INIT] wineboot"
runuser -l bwinter_sc81 -c '
  export HOME=/home/bwinter_sc81
  wineboot -i || echo "⚠️ wineboot failed"
'
sudo -u bwinter_sc81 -- bash -c '
  export HOME=/home/bwinter_sc81
  wineboot -i || echo "⚠️ wineboot failed"
'

########################################
echo "\n[🧪 BASIC] winetricks list-installed"
runuser -l bwinter_sc81 -c '
  export WINETRICKS_GUI=none
  winetricks list-installed || echo "⚠️ list-installed failed"
'
sudo -u bwinter_sc81 -- bash -c '
  export WINETRICKS_GUI=none
  winetricks list-installed || echo "⚠️ list-installed failed"
'

########################################
echo "\n[🧪 MINIMAL] winetricks corefonts only (no xvfb)"
runuser -l bwinter_sc81 -c '
  export WINETRICKS_GUI=none
  winetricks --unattended corefonts || echo "⚠️ corefonts failed"
'
sudo -u bwinter_sc81 -- bash -c '
  export WINETRICKS_GUI=none
  winetricks --unattended corefonts || echo "⚠️ corefonts failed"
'

########################################
echo "\n[🧪 HEADLESS] winetricks corefonts + tahoma with xvfb-run"
runuser -l bwinter_sc81 -c '
  export WINETRICKS_GUI=none
  xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
    winetricks --unattended corefonts tahoma || echo "⚠️ xvfb winetricks failed"
'
sudo -u bwinter_sc81 -- bash -c '
  export WINETRICKS_GUI=none
  xvfb-run --auto-servernum --server-args="-screen 0 1024x768x24" \
    winetricks --unattended corefonts tahoma || echo "⚠️ xvfb winetricks failed"
'

########################################
echo "\n[🧪 TIMEBOX] xvfb-run wrapped in timeout (180s)"
sudo -u bwinter_sc81 -- bash -c '
  export HOME=/home/bwinter_sc81
  timeout 180s \
    env WINETRICKS_GUI=none \
    xvfb-run -a -e /tmp/xvfb.err.log \
      --server-args="-screen 0 1024x768x24" \
      winetricks --unattended corefonts tahoma \
    || echo "⚠️ timeout or winetricks failure"
  echo "[🧪 LOG] Dumping xvfb log if available"
  cat /tmp/xvfb.err.log || echo "⚠️ no xvfb log"
'

########################################
echo "\n✅ All test stages completed. Review output above for hangs or crashes."

echo "✅ Fonts install attempt complete."