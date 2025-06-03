#!/bin/bash
set -eux

echo "📦 [install-ops-agent] Starting installation of Google Cloud CLI and Ops Agent..."

# Install the Google Cloud SDK APT key
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
  | gpg --dearmor -o "/usr/share/keyrings/cloud.google.gpg"

# Add the Cloud SDK repository (Bookworm)
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee /etc/apt/sources.list.d/google-cloud-sdk.list

# Install the CLI (optional but safe to include)
apt-get update
apt-get install -yq google-cloud-cli

echo "📦 [install-ops-agent] Installing Ops Agent repo + agent..."

# Download and run Google’s official install script
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

echo "🛠️ [install-ops-agent] Writing minimal config.yaml to enable collector..."

# Ensure collector runs by explicitly configuring it
sudo tee /etc/google-cloud-ops-agent/config.yaml > /dev/null <<EOF
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
EOF

echo "🚀 [install-ops-agent] Restarting agent to pick up new config..."
sudo systemctl restart google-cloud-ops-agent

echo "✅ [install-ops-agent] Google Ops Agent installation complete."
