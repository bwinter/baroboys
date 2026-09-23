#!/usr/bin/env bash
set -euo pipefail

ACTION="${1:-status}"
INSTANCE="${2:-}"
PROJECT="${PROJECT:-$(gcloud config get-value project 2>/dev/null)}"
REGION="${REGION:-us-west1}"
SERVICE_NAME="${VM_CONTROL_SERVICE:-vm-control}"

if [[ -z "$PROJECT" ]]; then
  echo "ERROR: GCP project not set. Run 'gcloud config set project ...' or export PROJECT."
  exit 1
fi

URL="$(gcloud run services describe "$SERVICE_NAME" --project="$PROJECT" --region="$REGION" \
  --format='value(status.url)')"
# User-account identity tokens do not support --audiences. Cloud Run accepts
# these tokens for development when the user has roles/run.invoker; audience-
# restricted tokens can be used later with service-account impersonation.
TOKEN="$(gcloud auth print-identity-token)"

case "$ACTION" in
  status)
    [[ -z "$INSTANCE" ]] || { echo "Usage: $0 status" >&2; exit 1; }
    curl --fail --silent --show-error -H "Authorization: Bearer $TOKEN" "$URL/v1/instances"
    ;;
  start)
    [[ -n "$INSTANCE" ]] || { echo "Usage: $0 start <instance>" >&2; exit 1; }
    curl --fail --silent --show-error -X POST -H "Authorization: Bearer $TOKEN" \
      "$URL/v1/instances/$INSTANCE/start"
    ;;
  *)
    echo "Usage: $0 {status|start <instance>}" >&2
    exit 1
    ;;
esac
echo
