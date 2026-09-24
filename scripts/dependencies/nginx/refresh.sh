#!/usr/bin/env bash
set -euxo pipefail

# shellcheck source=scripts/services/shared/env-vars.sh
source "$(dirname "${BASH_SOURCE[0]}")/../../services/shared/env-vars.sh"

# The game env is the source of truth for the admin username. Base images do
# not have an active game yet, so retain a harmless fallback for that phase.
if [[ -z "${ADMIN_USERNAME:-}" && -n "${GAME_NAME:-}" ]]; then
    GAME_ENV="$BAROBOYS/scripts/services/$GAME_NAME/env-vars.sh"
    if [[ -f "$GAME_ENV" ]]; then
        # shellcheck disable=SC1090
        source "$GAME_ENV"
    fi
fi
ADMIN_USERNAME="${ADMIN_USERNAME:-${SAVE_NAME:-${GAME_NAME:-admin}}}"

echo "🔐 [nginx] Generating .htpasswd from server-password..."
PASSWORD="$(gcloud secrets versions access latest --secret=server-password --quiet)"
htpasswd -cbB "/etc/nginx/.htpasswd" "$ADMIN_USERNAME" "$PASSWORD"
# Keep a stable machine-facing username so local tooling does not need to know
# which world/save is currently active.
if [[ "$ADMIN_USERNAME" != "admin" ]]; then
    htpasswd -bB "/etc/nginx/.htpasswd" "admin" "$PASSWORD"
fi
chown root:www-data "/etc/nginx/.htpasswd"
chmod 640 "/etc/nginx/.htpasswd"

# === Full nginx.conf replacement mode ===
CUSTOM_CONF="$BAROBOYS/scripts/dependencies/nginx/assets/nginx.conf"
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
