#!/usr/bin/env bash
set -euxo pipefail

# Persistent infrastructure configuration. Override these when bootstrapping
# the repository in another GCP project.
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-west1}"
ADDRESS_NAME="${STATIC_IP_NAME:-baroboys-ip}"
NETWORK_TIER="${NETWORK_TIER:-PREMIUM}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

command -v gcloud >/dev/null || { echo "gcloud not installed"; exit 1; }

if address_info=$(gcloud compute addresses describe "$ADDRESS_NAME" \
  --project="$PROJECT" \
  --region="$REGION" \
  --format='value(region.basename(),networkTier)' 2>/dev/null); then
  read -r existing_region existing_tier <<< "$address_info"

  if [[ "$existing_region" != "$REGION" ]]; then
    echo "ERROR: $ADDRESS_NAME exists in $existing_region, expected $REGION."
    exit 1
  fi

  if [[ "$existing_tier" != "$NETWORK_TIER" ]]; then
    echo "ERROR: $ADDRESS_NAME uses $existing_tier tier, expected $NETWORK_TIER."
    exit 1
  fi

  address=$(gcloud compute addresses describe "$ADDRESS_NAME" \
    --project="$PROJECT" \
    --region="$REGION" \
    --format='value(address)')
  echo "✔ Static IP already exists: $ADDRESS_NAME ($address) ($REGION, $NETWORK_TIER)"
else
  echo "➕ Reserving static IP: $ADDRESS_NAME ($REGION, $NETWORK_TIER)"
  gcloud compute addresses create "$ADDRESS_NAME" \
    --project="$PROJECT" \
    --region="$REGION" \
    --network-tier="$NETWORK_TIER"
  address=$(gcloud compute addresses describe "$ADDRESS_NAME" \
    --project="$PROJECT" \
    --region="$REGION" \
    --format='value(address)')
fi

echo "✅ Static IP bootstrap complete: $ADDRESS_NAME ($address)"
