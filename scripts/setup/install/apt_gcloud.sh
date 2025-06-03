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

cat <<EOF > /etc/google-cloud-ops-agent/config.yaml
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
      scrapers:
        cpu:
        memory:
        disk:
        network

  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]

logging:
  receivers:
    journald:
      type: journald

  service:
    pipelines:
      default_pipeline:
        receivers: [journald]
EOF

echo "🚀 [install-ops-agent] Restarting Ops Agent..."
systemctl restart google-cloud-ops-agent

systemctl status google-cloud-ops-agent.service
journalctl -xeu google-cloud-ops-agent.service

echo "✅ [install-ops-agent] Agent installed and configured."
