#!/usr/bin/env bash
# scripts/setup/install/flask_server/run_admin_server_local.sh

set -euo pipefail

cd "$(dirname "$0")"  # this moves into scripts/setup/install/flask_server

export FLASK_ENV=development

python3 admin_server.py
