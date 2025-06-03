#!/bin/bash
set -euo pipefail

echo "# 🧱 Baroboys Admin UI + Status Logic"
echo "Generated: $(date -u)"

add_section() {
  local label="$1"
  local path="$2"
  if [[ -f "$path" ]]; then
    echo -e "\n\n# === $label ($path) ==="
    echo '```bash'
    cat "$path"
    echo '```'
  else
    echo -e "\n\n# === $label ($path) ==="
    echo "**Missing file**"
  fi
}

add_section "Admin.html" \
  "scripts/setup/install/flask_server/static/admin.html"

add_section "Admin server" \
  "scripts/setup/install/flask_server/admin_server.py"

add_section "Debian nginx installer" \
  "scripts/setup/install/apt_nginx.sh"

add_section "nginx.config" \
  "scripts/setup/install/assets/nginx.config"

add_section "Admin server local installer (includes nginx install)" \
  "scripts/setup/install/flask_server/run_admin_server_local.sh"
