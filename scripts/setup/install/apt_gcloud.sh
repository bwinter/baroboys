#!/bin/bash
set -eux

echo "📦 [install-ops-agent] Installing Google Cloud CLI and Ops Agent..."

# Add Google Cloud SDK repo and key
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee /etc/apt/sources.list.d/google-cloud-sdk.list

apt-get update
apt-get install -yq google-cloud-cli

echo "📦 [install-ops-agent] Installing Ops Agent..."

# Install the agent via official script
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

echo "🛠️ [install-ops-agent] Writing trimmed config.yaml (system metrics + journald)..."

CONFIG_PATH="/etc/google-cloud-ops-agent/config.yaml"

# Write config with full tee output and verify
cat <<EOF | tee "$CONFIG_PATH"
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
      scrapers:
        cpu:
        memory:
        disk:
        network:
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]

logging:
  receivers:
    journald:
      type: systemd_journald
  service:
    pipelines:
      default_pipeline:
        receivers: [journald]
EOF

echo "📄 [install-ops-agent] Final contents of $CONFIG_PATH:"
cat "$CONFIG_PATH"

echo "🧪 [install-ops-agent] Validating config with config-validator..."
if ! /opt/google-cloud-ops-agent/bin/config-validator -config_file="$CONFIG_PATH" 2>&1 | tee /tmp/ops_agent_validate.log; then
    echo "❌ [install-ops-agent] Config validation failed. Output was:"
    cat /tmp/ops_agent_validate.log
    exit 1
fi

echo "🚀 [install-ops-agent] Attempting to restart Ops Agent..."
systemctl restart google-cloud-ops-agent 2>&1 | tee /tmp/ops_agent_restart.log
STATUS=${PIPESTATUS[0]}

if [[ "$STATUS" -ne 0 ]]; then
    echo "📋 systemctl status:"
    systemctl status google-cloud-ops-agent --no-pager || true

    echo "📋 journalctl (truncated output):"
    journalctl -xeu google-cloud-ops-agent --no-pager -n 50 || echo "⚠️ Failed to get journal output"

    echo "📂 Dumping log output captured during restart:"
    cat /tmp/ops_agent_restart.log

    echo "🛑 [install-ops-agent] Aborting script due to Ops Agent failure"
    exit 1
else
    echo "✅ [install-ops-agent] Ops Agent restarted successfully."
fi
