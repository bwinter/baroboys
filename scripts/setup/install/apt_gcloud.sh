#!/bin/bash
set -eux

echo "🛰️  [OPS AGENT] Starting Google Cloud Ops Agent setup..."

# ---------------------------------------------------------------------
# 🔑 Step 1: Trust GCP APT Keyring
echo "🔑 [OPS AGENT] Installing GCP APT key..."
curl -fsSL "https://packages.cloud.google.com/apt/doc/apt-key.gpg" \
  | gpg --dearmor -o "/usr/share/keyrings/cloud.google.gpg"

# ---------------------------------------------------------------------
# 📦 Step 2: Add cloud-sdk APT repo (for gcloud CLI)
echo "📦 [OPS AGENT] Adding cloud-sdk APT repo..."
echo "deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee "/etc/apt/sources.list.d/google-cloud-sdk.list"

# ---------------------------------------------------------------------
# 📥 Step 3: Install gcloud CLI early (for potential later diagnostics)
echo "📥 [OPS AGENT] Installing google-cloud-cli..."
apt-get update -yq
apt-get install -yq google-cloud-cli

# ---------------------------------------------------------------------
# 📜 Step 4: Write config BEFORE agent install
echo "🛠️  [OPS AGENT] Writing /etc/google-cloud-ops-agent/config.yaml..."
tee /etc/google-cloud-ops-agent/config.yaml > /dev/null <<EOF
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

# ---------------------------------------------------------------------
# 📥 Step 5: Add repo + install the Ops Agent (canonical install path)
echo "🚀 [OPS AGENT] Downloading and running Google’s installer..."
curl -sSO "https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh"
bash add-google-cloud-ops-agent-repo.sh --also-install

# ---------------------------------------------------------------------
# ✅ Final: Confirm status for fast debugging
echo "🔍 [OPS AGENT] Verifying agent services..."
systemctl is-active --quiet google-cloud-ops-agent.service && echo "✅ Agent meta-service active"
systemctl is-active --quiet google-cloud-ops-agent-opentelemetry-collector.service && echo "✅ Collector active"
systemctl is-active --quiet google-cloud-ops-agent-fluent-bit.service && echo "✅ Logging agent active (if enabled)"

echo "🎉 [OPS AGENT] Installation and config complete."
