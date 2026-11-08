#!/usr/bin/env bash
set -euxo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "ERROR: This script uses macOS-specific tools (BSD date). Run on macOS only."
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
ADMIN_DIR="$REPO_ROOT/scripts/services/admin_server/src"

# === Shared paths (mirroring prod) ===
STATIC_SOURCE="$ADMIN_DIR/static"
TEMPLATE_SOURCE="$ADMIN_DIR/templates"
STATIC_DEST="/opt/baroboys/static"
TEMPLATE_DEST="/opt/baroboys/templates"
NGINX_CONF_MAIN="/usr/local/etc/nginx/nginx.conf"
HTPASSWD_DEST="/etc/nginx/.htpasswd"
STATUS_JSON="$STATIC_DEST/status.json"
NGINX_LOG_DIR="/var/log/nginx"
NGINX_RUN_DIR="/var/run"
NGINX_CONFIG_SOURCE="$REPO_ROOT/scripts/dependencies/nginx/assets/nginx.conf"
LOCAL_NGINX_USER="$(whoami)"
LOCAL_NGINX_GROUP="$(id -gn)"

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

# === Fixture status.json ===
echo "📄 Installing dev status fixture at $STATUS_JSON..."
NOW_ISO="$(date -u +"%Y-%m-%dT%H:%M:%SZ")"
sudo cp "$ADMIN_DIR/dev/status.json" "$STATUS_JSON"
sudo python3 - "$STATUS_JSON" "$NOW_ISO" <<'PY'
import json
import sys

path, timestamp = sys.argv[1:]
with open(path, encoding="utf-8") as f:
    status = json.load(f)
status["timestamp_utc"] = timestamp
with open(path, "w", encoding="utf-8") as f:
    json.dump(status, f, indent=2)
    f.write("\n")
PY


sudo chown -R "$(whoami)" "$STATIC_DEST" "$TEMPLATE_DEST"
sudo find "$STATIC_DEST" "$TEMPLATE_DEST" -type f -exec chmod 644 {} +
sudo find "$STATIC_DEST" "$TEMPLATE_DEST" -type d -exec chmod 755 {} +

# === Install nginx.conf ===
echo "📝 Installing nginx.conf to $NGINX_CONF_MAIN..."
# Production uses Debian's www-data account. Homebrew Nginx on macOS runs
# under the local account instead, so derive a local-only config copy.
sed "s/^user www-data;$/user $LOCAL_NGINX_USER $LOCAL_NGINX_GROUP;/" "$NGINX_CONFIG_SOURCE" \
  | sudo tee "$NGINX_CONF_MAIN" >/dev/null

# === Install .htpasswd ===
echo "🔐 Generating .htpasswd from server-password..."
sudo mkdir -p "$(dirname "$HTPASSWD_DEST")"
PASSWORD="$(gcloud secrets versions access latest --secret=server-password --quiet)"
ADMIN_USERNAME="${ADMIN_USERNAME:-${SAVE_NAME:-admin}}"
sudo htpasswd -cbB "$HTPASSWD_DEST" "$ADMIN_USERNAME" "$PASSWORD"
if [[ "$ADMIN_USERNAME" != "admin" ]]; then
    sudo htpasswd -bB "$HTPASSWD_DEST" "admin" "$PASSWORD"
fi
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

# Keep Flask in the foreground so make admin-local has one obvious process to
# interrupt and restart. The SIGINT trap above still cleans up Nginx and any
# process left on the service ports.
FLASK_ENV=dev python3 "$ADMIN_DIR/admin_server.py"

echo -e "\n✅ Done"
