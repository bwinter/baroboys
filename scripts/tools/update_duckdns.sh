#!/usr/bin/env bash
set -euo pipefail

# Update DuckDNS after Terraform has assigned the VM's external address.
# The token is read locally from Secret Manager and is never passed to
# Terraform or written to Terraform state.

if [[ $# -ne 2 ]]; then
  echo "Usage: $0 <external-ip> <gcp-project>" >&2
  exit 1
fi

EXTERNAL_IP="$1"
PROJECT="$2"
DUCKDNS_DOMAIN="${DUCKDNS_DOMAIN:-baroboys}"
SECRET_NAME="${DUCKDNS_SECRET_NAME:-duckdns-token}"

if [[ ! "$EXTERNAL_IP" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
  echo "ERROR: Invalid external IPv4 address: $EXTERNAL_IP" >&2
  exit 1
fi

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project is required." >&2
  exit 1
fi

if [[ -z "$DUCKDNS_DOMAIN" ]]; then
  echo "ERROR: DUCKDNS_DOMAIN cannot be empty." >&2
  exit 1
fi

TOKEN="$(gcloud secrets versions access latest \
  --secret="$SECRET_NAME" \
  --project="$PROJECT")"

if [[ -z "$TOKEN" ]]; then
  echo "ERROR: Secret '$SECRET_NAME' is empty." >&2
  exit 1
fi

RESPONSE="$(curl --fail --silent --show-error --get 'https://www.duckdns.org/update' \
  --data-urlencode "domains=$DUCKDNS_DOMAIN" \
  --data-urlencode "token=$TOKEN" \
  --data-urlencode "ip=$EXTERNAL_IP")"

case "$RESPONSE" in
  OK|NOCHG)
    echo "✅ DuckDNS updated: ${DUCKDNS_DOMAIN}.duckdns.org → $EXTERNAL_IP ($RESPONSE)"
    ;;
  *)
    echo "ERROR: DuckDNS returned an unexpected response: $RESPONSE" >&2
    exit 1
    ;;
esac
