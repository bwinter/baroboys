#!/bin/bash
set -euxo pipefail

echo "🔧 [nginx] Installing nginx and apache2-utils..."
apt update
apt install -y nginx apache2-utils

echo "🔐 [nginx] Fetching .htpasswd from GCP secrets..."
gcloud secrets versions access latest --secret="nginx-htpasswd" --quiet > "/etc/nginx/.htpasswd"
chmod 644 "/etc/nginx/.htpasswd"
chown root:root "/etc/nginx/.htpasswd"

# === Full nginx.conf replacement mode ===
CUSTOM_CONF="/root/baroboys/scripts/setup/install/assets/nginx.conf"
TARGET_CONF="/etc/nginx/nginx.conf"

echo "📄 [nginx] Looking for custom nginx.conf at: $CUSTOM_CONF"
if [[ ! -f "$CUSTOM_CONF" ]]; then
    echo "❌ ERROR: Custom nginx.conf not found at $CUSTOM_CONF"
    exit 1
fi

echo "📥 [nginx] Replacing default nginx.conf with custom version..."
cp "$CUSTOM_CONF" "$TARGET_CONF"
chown root:root "$TARGET_CONF"
chmod 644 "$TARGET_CONF"

echo "🔍 [nginx] Showing config diff:"
diff -u "$TARGET_CONF" "$CUSTOM_CONF" || true  # Always show diff output even if identical

echo "🧪 [nginx] Validating nginx config..."
nginx -t

echo "🚀 [nginx] Restarting nginx..."
systemctl restart nginx

echo "🧾 [nginx] Final check – should be listening on port 8080:"
ss -tuln | grep 8080 || {
    echo "⚠️ WARNING: Nginx is not listening on port 8080. Check config or logs."
}

head -n 20 "$TARGET_CONF"
echo "✅ [nginx] Setup complete. Current running config:"