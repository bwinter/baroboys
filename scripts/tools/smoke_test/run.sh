#!/usr/bin/env bash
# run.sh — E2E smoke test: provision VRising VM, probe it, tear down.
# External checks run from local machine; internal checks run on the VM via SSH.
# Converted from RUNBOOK.md (b601cef).
#
# Usage: ./scripts/tools/smoke_test/run.sh [--game VRising|Barotrauma] [--skip-destroy]
#   --skip-destroy  leave VM running after tests (useful for manual inspection)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
TF_DIR="$REPO_ROOT/terraform"

GAME="VRising"
SKIP_DESTROY=false

for arg in "$@"; do
    case "$arg" in
        --game=*) GAME="${arg#*=}" ;;
        --skip-destroy) SKIP_DESTROY=true ;;
    esac
done

PROJECT="${PROJECT:-europan-world}"
ZONE="${ZONE:-us-west1-c}"
MACHINE_NAME="${MACHINE_NAME:-europa}"
GCP_USER="${GCP_USER:-bwinter_sc81}"

exit_code=0
IP=""

fail() { echo "❌ $*" >&2; exit_code=1; }
pass() { echo "✅ $*"; }
header() { echo ""; echo "=== $* ==="; }

# --- Teardown trap ---
# Always destroy on exit unless --skip-destroy. Prevents runaway VMs if script errors.
teardown() {
    if [[ "$SKIP_DESTROY" == "true" ]]; then
        echo ""
        echo "⚠️  --skip-destroy set: VM left running at $IP"
        return
    fi
    header "Stage 6 — Teardown"
    cd "$TF_DIR"
    # Destroy all provisioned infrastructure
    terraform destroy -auto-approve \
        -var-file="shared.tfvars" \
        -var-file="game/${GAME}.tfvars"
    pass "7 resources destroyed"
}
trap teardown EXIT

# ============================================================
# Stage 1 — Environment check
# ============================================================
header "Stage 1 — Environment Check"

# Verify environment vars and gcloud auth
echo "PROJECT=$PROJECT ZONE=$ZONE MACHINE_NAME=$MACHINE_NAME GCP_USER=$GCP_USER"
gcloud config get-value project
gcloud auth list --filter=status:ACTIVE --format="value(account)"
pass "Environment OK"

# ============================================================
# Stage 2 — Terraform apply
# ============================================================
header "Stage 2 — Terraform Apply"

cd "$TF_DIR"
# Provision VM + firewall rules. build.sh is interactive — call terraform directly.
terraform init -backend-config="backend/prod.hcl" -input=false
terraform apply -auto-approve \
    -var-file="shared.tfvars" \
    -var-file="game/${GAME}.tfvars"
pass "Terraform apply complete"

# ============================================================
# Stage 3 — Boot watch
# ============================================================
header "Stage 3 — Boot Watch"

# Poll until RUNNING, capture external IP
echo "Waiting for VM to reach RUNNING..."
for i in $(seq 1 20); do
    read -r status ip < <(gcloud compute instances describe "$MACHINE_NAME" \
        --zone="$ZONE" --project="$PROJECT" \
        --format="value(status,networkInterfaces[0].accessConfigs[0].natIP)" 2>/dev/null \
        || echo "UNKNOWN ")
    if [[ "$status" == "RUNNING" && -n "$ip" ]]; then
        IP="$ip"
        pass "VM RUNNING at $IP (after ${i}x polls)"
        break
    fi
    echo "  status=$status, retrying in 10s..."
    sleep 10
done
[[ -n "$IP" ]] || { fail "VM never reached RUNNING"; exit 1; }

# Wait for boot to complete — poll serial output for game-startup
echo "Waiting for game-startup.service..."
for i in $(seq 1 30); do
    serial=$(gcloud compute instances get-serial-port-output "$MACHINE_NAME" \
        --zone="$ZONE" --project="$PROJECT" 2>/dev/null || echo "")
    if echo "$serial" | grep -q "Started game-startup.service"; then
        pass "Boot sequence complete (after ${i}x polls)"
        break
    fi
    # Check for failures
    if echo "$serial" | grep -q "dependency failed\|Failed to start"; then
        fail "Systemd failure detected in serial output"
        echo "$serial" | grep -E "dependency failed|Failed to start" | tail -5
        exit 1
    fi
    echo "  game-startup not yet seen, retrying in 15s..."
    sleep 15
done

# ============================================================
# Stage 4 — Internal checks (run vm_checks.sh on the VM)
# ============================================================
header "Stage 4 — Internal Checks (via SSH)"

# SSH and execute vm_checks.sh — self-identifies game from /etc/baroboys/active-game
gcloud compute ssh "${GCP_USER}@${MACHINE_NAME}" \
    --zone="$ZONE" --project="$PROJECT" \
    --command="bash ~/baroboys/scripts/tools/smoke_test/vm_checks.sh" \
    || { fail "vm_checks.sh reported failures"; exit_code=1; }

# Cross-check: verify reported game matches what we provisioned
reported_game=$(gcloud compute ssh "${GCP_USER}@${MACHINE_NAME}" \
    --zone="$ZONE" --project="$PROJECT" \
    --command="cat /etc/baroboys/active-game" 2>/dev/null || echo "")
if [[ "$reported_game" == "$GAME" ]]; then
    pass "active-game cross-check: server reports '$reported_game' (expected '$GAME')"
else
    fail "active-game cross-check: server reports '$reported_game', expected '$GAME'"
fi

# ============================================================
# Stage 5 — External checks (admin panel)
# ============================================================
header "Stage 5 — External Checks (Admin Panel)"

GAME_PASSWORD=$(gcloud secrets versions access latest \
    --secret=server-password --project="$PROJECT")
ADMIN_URL="http://${IP}:8080"

# Full external stack: nginx auth + proxy + Flask
ping_response=$(curl -sf --max-time 10 \
    -u "Hex:${GAME_PASSWORD}" \
    "${ADMIN_URL}/api/ping" 2>/dev/null || echo "")
if [[ "$ping_response" == "pong" ]]; then
    pass "Admin panel /api/ping → pong (nginx + auth + Flask)"
else
    fail "Admin panel /api/ping failed (response: $ping_response)"
fi

# VRisingServer.log via admin panel — exercises symlink + log_map + nginx end-to-end
log_lines=$(curl -sf --max-time 10 \
    -u "Hex:${GAME_PASSWORD}" \
    "${ADMIN_URL}/api/logs/VRisingServer.log" 2>/dev/null | wc -l || echo 0)
if (( log_lines >= 5 )); then
    pass "VRisingServer.log endpoint returned ${log_lines} lines (symlink + log_map verified)"
else
    fail "VRisingServer.log endpoint returned ${log_lines} lines — expected ≥5"
fi

# ============================================================
# Summary
# ============================================================
echo ""
echo "============================================================"
if (( exit_code == 0 )); then
    echo "✅ All smoke tests passed."
else
    echo "❌ One or more smoke tests failed — check output above."
fi
echo "============================================================"
exit "$exit_code"