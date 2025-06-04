#!/usr/bin/env bash
# scripts/setup/install/flask_server/run_admin_server_local.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../../.." && pwd)"

# === Shared paths (mirroring prod) ===
STATIC_SOURCE="$SCRIPT_DIR/static"
TEMPLATE_SOURCE="$SCRIPT_DIR/templates"
STATIC_DEST="/opt/baroboys/static"
TEMPLATE_DEST="/opt/baroboys/templates"
NGINX_CONF_MAIN="/usr/local/etc/nginx/nginx.conf"
HTPASSWD_DEST="/etc/nginx/.htpasswd"
STATUS_JSON="$STATIC_DEST/status.json"
NGINX_LOG_DIR="/var/log/nginx"
NGINX_RUN_DIR="/var/run"
NGINX_CONFIG_SOURCE="$REPO_ROOT/scripts/setup/install/assets/nginx.conf"

# === Kill Flask if running ===
if lsof -i :5000 >/dev/null 2>&1; then
  echo "🛑 Port 5000 in use — killing existing Flask process..."
  kill "$(lsof -ti tcp:5000)" || true
  sleep 1
fi

# === Kill nginx if running ===
if lsof -i :8080 >/dev/null 2>&1; then
  echo "🛑 Port 8080 in use — killing existing nginx process..."
  sudo nginx -s stop || sudo pkill -f nginx || true
  sleep 1
fi

# === Sync static/template files ===
echo "📦 Syncing static + template files to /opt/baroboys..."
sudo mkdir -p "$STATIC_DEST" "$TEMPLATE_DEST"
sudo cp "$STATIC_SOURCE/"* "$STATIC_DEST/"
sudo cp "$TEMPLATE_SOURCE/"* "$TEMPLATE_DEST/"

# === Dummy status.json ===
echo "📄 Creating dummy status.json at $STATUS_JSON..."
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
IDLE_SINCE="$(date -u -d '-45 minutes' +"%Y-%m-%dT%H:%M:%SZ")"
sudo tee "$STATUS_JSON" >/dev/null <<EOF
{
  "timestamp_utc": "$NOW_ISO",
  "source": "local_test",
  "uptime_duration_minutes": 123,
  "cpu_percent": 9.1,
  "load_average_1min": 0.42,
  "memory_free_mb": 3892,
  "idle_duration_minutes": 45,
  "idle_since": "$IDLE_SINCE",
  "vrising_pids": [12345],
  "players": {
    "count": 1,
    "list": ["TestPlayer"]
  },
  "shutdown": {
    "scheduled": false
  },
  "settings": {
    "game_settings": {
      "GameModeType": "PvE"
    }
  },
  "time": "Day 12 - 04:30"
}
EOF


sudo chown -R "$(whoami)" "$STATIC_DEST" "$TEMPLATE_DEST"
sudo find "$STATIC_DEST" "$TEMPLATE_DEST" -type f -exec chmod 644 {} +
sudo find "$STATIC_DEST" "$TEMPLATE_DEST" -type d -exec chmod 755 {} +

# === Install nginx.conf ===
echo "📝 Installing nginx.conf to $NGINX_CONF_MAIN..."
sudo cp "$NGINX_CONFIG_SOURCE" "$NGINX_CONF_MAIN"

# === Install .htpasswd ===
echo "🔐 Installing .htpasswd from gcloud..."
sudo mkdir -p "$(dirname "$HTPASSWD_DEST")"
gcloud secrets versions access latest --secret="nginx-htpasswd" --quiet | sudo tee "$HTPASSWD_DEST" >/dev/null
sudo chmod 644 "$HTPASSWD_DEST"
sudo chown "$(whoami)" "$HTPASSWD_DEST"

# === Ensure /var/log/nginx and /var/run exist ===
echo "🛠️  Fixing log + run dirs..."
sudo mkdir -p "$NGINX_LOG_DIR" "$NGINX_RUN_DIR"
sudo chown -R "$(whoami)" "$NGINX_LOG_DIR" "$NGINX_RUN_DIR"
sudo chmod 755 "$NGINX_LOG_DIR" "$NGINX_RUN_DIR"
sudo rm -f "$NGINX_RUN_DIR/nginx.pid"
sudo truncate -s 0 "$NGINX_LOG_DIR/access.log" || true
sudo truncate -s 0 "$NGINX_LOG_DIR/error.log" || true

# === Start Flask ===
echo "🚀 Starting Flask admin server..."
FLASK_ENV=development python3 "$SCRIPT_DIR/admin_server.py" &
FLASK_PID=$!

# === Start nginx (manual) ===
echo "🌐 Starting nginx manually..."
sudo nginx

# === Status ===
echo -e "\n✅ Admin panel running at:"
echo "   Flask:  http://localhost:5000"
echo "   Nginx:  http://localhost:8080"
echo "   Ctrl+C to stop..."

# === Wait ===
wait "$FLASK_PID"
