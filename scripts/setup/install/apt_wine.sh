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

which wine64
which wineserver
dpkg -L wine-stable-amd64 | grep wineserver

echo "🌀 Installing fonts..."

# Initialize Wine prefix (once!)
sudo -u bwinter_sc81 -- bash -eux <<'EOF' | tee /tmp/wine_debug_log.txt
  echo "🔧 Manual wineserver experiment (Packer-compatible)"

  # UID info and TMPDIR
  echo "🧪 UID: $(id -u)"
  echo "🧪 TMPDIR: ${TMPDIR:-/tmp}"
  echo "🧪 XDG_RUNTIME_DIR: ${XDG_RUNTIME_DIR:-"(unset)"}"
  echo "🧪 HOME: $HOME"

  # Show version of wine64
  echo "ℹ️ wine64 version info:"
  /usr/bin/wine64 --version || echo "⚠️ wine64 not working"

  # Show environment
  echo "🔧 Environment snapshot:"
  env | grep -E "WINE|XDG|TMP|HOME" || true

  ls -la /tmp

  # Clean up any previous temp dirs
  rm -rf /tmp/.wine-$(id -u)

  # Track TMP activity
  TMP_SNAPSHOT="/tmp/wine_tmp_before_$(date +%s)"
  cp -r /tmp "$TMP_SNAPSHOT" || true
  echo "🧪 Snapshot of /tmp saved to: $TMP_SNAPSHOT"

  # Set wine env
  export WINEARCH=win64
  export WINEPREFIX=/home/bwinter_sc81/.wine64
  export WINEDEBUG=+server,+wineserver,+file,+pid,+timestamp

  # Prep log files
  mkdir -p /tmp/wine-debug
  WS_LOG=/tmp/wine-debug/wineserver.log
  WB_LOG=/tmp/wine-debug/wineboot.log

  # Kill any old wineserver
  /usr/bin/wineserver -k || true
  rm -rf /tmp/.wine-$(id -u)

  # Start wineserver in background
  echo "🚀 Starting wineserver..."
  /usr/bin/wineserver -f -d 2>&1 | tee "$WS_LOG" &
  WS_PID=$!
  echo "🧪 wineserver PID: $WS_PID"

  # Wait a bit to ensure wineserver starts up
  sleep 2

  # Launch wineboot
  /usr/bin/wine64 wineboot 2>&1 | tee "$WB_LOG" || echo "⚠️ wineboot failed"

  # Shutdown wineserver
  echo "🛑 Killing wineserver..."
  kill "$WS_PID" || true
  wait "$WS_PID" || true

  echo "📄 Logs saved to:"
  echo "  - $WS_LOG"
  echo "  - $WB_LOG"

  # Snapshot /tmp again
  echo "📂 /tmp contents post-wineboot:"
  ls -la /tmp/.wine-$(id -u) || echo "❌ No wineserver dir found"
  ls -la /tmp

  echo "✅ Debug trace complete."
EOF

# Run winetricks under xvfb
sudo -u bwinter_sc81 -- bash -c '
  echo "🔧 Installing corefonts and tahoma via winetricks..."
  export WINE=/usr/bin/wine64
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
