#!/usr/bin/env bash
# scripts/server/admin/run_admin_server_local.sh

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

# Function to clean up on SIGINT
cleanup() {
  # === Kill Flask if running ===
  if lsof -i :5000 >/dev/null 2>&1; then
    echo "🛑 Port 5000 in use — killing existing Flask process..."
    kill "$(lsof -ti tcp:5000)" || true
  fi

  # === Kill nginx if running ===
  if lsof -i :8080 >/dev/null 2>&1; then
    echo "🛑 Port 8080 in use — killing existing nginx process..."
    sudo nginx -s stop || sudo pkill -f nginx || true
  fi

  echo "Cleanup Success."
}

# Call cleanup to ensure clean state
cleanup

# === Sync static/template files ===
echo "📦 Syncing static + template files to /opt/baroboys..."
sudo mkdir -p "$STATIC_DEST" "$TEMPLATE_DEST"
sudo cp "$STATIC_SOURCE/"* "$STATIC_DEST/"
sudo cp "$TEMPLATE_SOURCE/"* "$TEMPLATE_DEST/"

# === Dummy status.json ===
echo "📄 Creating dummy status.json at $STATUS_JSON..."
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
IDLE_SINCE_ISO="$(date -u -v -45M +"%Y-%m-%dT%H:%M:%SZ")"
sudo tee "$STATUS_JSON" >/dev/null <<EOF
{
  "timestamp_utc": "$NOW_ISO",
  "cpu_percent": 30,
  "idle_flag_set": true,
  "idle_duration_minutes": 45,
  "idle_since": "$IDLE_SINCE_ISO",
  "vrising_pids": [55555],
  "players": {
    "count": null,
    "list": []
  }
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

# Set up trap
trap cleanup SIGINT

# === Status ===
echo -e "\n✅ Admin panel running at:"
echo "   Flask:  http://localhost:5000"
echo "   Nginx:  http://localhost:8080"
echo "   Ctrl+C to stop..."

# === Wait ===
wait "$FLASK_PID"

echo -e "\n✅ Done"