
echo "🎮 Ensuring V Rising server is running via systemd..."

if systemctl is-active --quiet game-startup.service; then
  echo "✅ game-startup.service is already running, skipping restart."
else
  echo "🔁 game-startup.service not active — restarting..."

  echo "🧪 Checking if VRisingServer.exe is still running before restart:"
  pgrep -a -f VRisingServer.exe || echo "🔍 No existing VRisingServer.exe found."

  echo "🔁 Restarting game-startup.service..."
  if ! systemctl restart game-startup.service; then
    echo "❌ Failed to restart game-startup.service" >&2

    echo "📋 Recent journal output:"
    journalctl -xeu game-startup.service --no-pager -n 20 || true

    echo "📋 Current service status:"
    systemctl status --no-pager --full game-startup.service || true

    exit 1
  fi

  # Confirm it actually became active
  if ! systemctl is-active --quiet game-startup.service; then
    echo "❌ game-startup.service is not active after restart" >&2
    systemctl status --no-pager --full game-startup.service || true
    exit 3
  fi
fi

# Last-ditch check
if systemctl is-failed --quiet game-startup.service; then
  echo "❌ game-startup.service is in a failed state" >&2
  systemctl status --no-pager --full game-startup.service || true
  exit 2
fi

echo "✅ game-startup.service is now active."
