#!/usr/bin/env bash
set -euxo pipefail

echo "🔧 [nginx] Installing nginx and apache2-utils..."
apt update
apt install -y nginx apache2-utils