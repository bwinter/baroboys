#!/usr/bin/env bash
set -euxo pipefail

echo "📦 [install-ops-agent] Installing Google Cloud CLI and Ops Agent..."

# Add Google Cloud SDK repo and key
curl -fsSL https://packages.cloud.google.com/apt/doc/apt-key.gpg \
  | gpg --dearmor -o /usr/share/keyrings/cloud.google.gpg

echo "deb [arch=amd64 signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
  | tee /etc/apt/sources.list.d/google-cloud-sdk.list

apt-get update -yq
apt-get install -yq google-cloud-cli

# Bake the GCP project into installation-level gcloud config. Without this,
# every gcloud call has to resolve project via the metadata server — which
# can race transiently at first boot of a fresh VM, leaving resource-parsing
# commands (`gcloud secrets versions access`, etc.) without project context
# even though `gcloud config list` works. Installation-level config is
# system-wide and inherited by all users, removing the per-call dependency
# on metadata-server availability and timing at runtime. Read from metadata
# at build time (reliably available during Packer) and persist to the image.
GCP_PROJECT="$(curl -sf -H 'Metadata-Flavor: Google' http://metadata.google.internal/computeMetadata/v1/project/project-id)"
gcloud config set --installation core/project "$GCP_PROJECT"

echo "📦 [install-ops-agent] Installing Ops Agent..."

# Install the agent via official script
curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

echo "🛠️ [install-ops-agent] Writing trimmed config.yaml (system metrics + journald)..."

CONFIG_PATH="/etc/google-cloud-ops-agent/config.yaml"

cat <<EOF | tee "$CONFIG_PATH"
metrics:
  receivers:
    hostmetrics:
      type: hostmetrics
      collection_interval: 60s
  processors:
    metrics_filter:
      type: exclude_metrics
      metrics_pattern: []
  service:
    pipelines:
      default_pipeline:
        receivers: [hostmetrics]
        processors: [metrics_filter]
        exporters: [google_cloud_monitoring]

logging:
  receivers:
    journald:
      type: systemd_journald
  service:
    pipelines:
      default_pipeline:
        receivers: [journald]
        exporters: [google_cloud_logging]
EOF

echo "📄 [install-ops-agent] Final contents of $CONFIG_PATH:"
cat "$CONFIG_PATH"

echo "🚀 [install-ops-agent] Attempting to restart Ops Agent..."
systemctl restart google-cloud-ops-agent 2>&1 | tee /tmp/ops_agent_restart.log
RESTART_STATUS=${PIPESTATUS[0]}

if [[ "$RESTART_STATUS" -ne 0 ]]; then
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
