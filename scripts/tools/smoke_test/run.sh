#!/usr/bin/env bash
# run.sh — E2E smoke test: provision game VM, probe it, tear down.
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
MACHINE_NAME="${MACHINE_NAME:-$(echo "$GAME" | tr '[:upper:]' '[:lower:]')}"
GCP_USER="${GCP_USER:-bwinter_sc81}"

exit_code=0
IP=""

fail() { echo "❌ $*" >&2; exit_code=1; }
pass() { echo "✅ $*"; }
header() { echo ""; echo "=== $* ==="; }

# --- Teardown trap ---
# Always destroy on exit unless --skip-destroy. Prevents runaway VMs if script errors.
# shellcheck disable=SC2329  # invoked via `trap teardown EXIT` below
teardown() {
    if [[ "$SKIP_DESTROY" == "true" ]]; then
        echo ""
        echo "⚠️  --skip-destroy set: VM left running at $IP"
        return
    fi
    header "Stage 6 — Teardown"
    cd "$TF_DIR"
    terraform workspace select "$WORKSPACE" 2>/dev/null || true
    terraform destroy -auto-approve \
        -var-file="shared.tfvars" \
        -var-file="game/${GAME}.tfvars.json"
    pass "Terraform destroy complete"
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
WORKSPACE="$(echo "$GAME" | tr '[:upper:]' '[:lower:]')"
# Provision VM + firewall rules. build.sh is interactive — call terraform directly.
terraform init -backend-config="backend/prod.hcl" -input=false
terraform workspace select "$WORKSPACE" || terraform workspace new "$WORKSPACE"
terraform apply -auto-approve \
    -var-file="shared.tfvars" \
    -var-file="game/${GAME}.tfvars.json"
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
    if [[ "$i" -eq 30 ]]; then
        fail "game-startup.service never appeared in serial output after 30 polls"
    fi
done

# ============================================================
# Stage 3b — Game readiness (wait for game to bind its listen port)
# ============================================================
# `Started game-startup.service` only means systemd kicked off the unit, not
# that the game is ready. Wine games (VRising) take 2-5 minutes to bootstrap
# Unity + EOS before binding their port. Probe the actual game port until
# it's reachable; that's the real readiness signal.
header "Stage 3b — Game Readiness (port bind)"

# Pull readiness port from the per-game JSON (single source of truth).
# Drift between firewall, game listen, and this check would now surface
# as a readiness-timeout — not as a hardcoded mismatch.
GAME_TFVARS="$REPO_ROOT/terraform/game/${GAME}.tfvars.json"
read -r ready_port ready_proto < <(python3 -c "
import json
d = json.load(open('$GAME_TFVARS'))
udp = d.get('game_ports_udp', [])
tcp = d.get('game_ports_tcp', [])
if udp:
    print(udp[0], 'udp')
elif tcp:
    print(tcp[0], 'tcp')
else:
    print('', '')
")

if [[ -n "$ready_port" ]]; then
    nc_flag="-zvw 5"; [[ "$ready_proto" == "udp" ]] && nc_flag="-zuvw 5"
    echo "Waiting for $GAME to bind $ready_proto:$ready_port..."
    for i in $(seq 1 36); do
        # shellcheck disable=SC2086
        if nc $nc_flag "$IP" "$ready_port" >/dev/null 2>&1; then
            pass "$GAME ready on $ready_proto:$ready_port (after ${i}x polls / ~$((i*10))s)"
            break
        fi
        echo "  not yet ready, retrying in 10s..."
        sleep 10
        if [[ "$i" -eq 36 ]]; then
            fail "$GAME never bound $ready_proto:$ready_port after 6 minutes"
        fi
    done

    # Port-bind is the earliest "ready" signal — game has opened its socket
    # but Unity's full bootstrap (map loading, EOS handshake, settings parse)
    # continues for tens of seconds after. vm_checks's RAM/log-content
    # thresholds can fire false negatives if probed at this exact edge. Brief
    # grace period before internal checks lets the game settle.
    echo "Grace period: 60s for game to finish bootstrap..."
    sleep 60
fi

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
# Stage 5 — External checks (admin panel + game ports)
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

# game.log via admin panel — exercises log_map + nginx end-to-end
log_lines=$(curl -sf --max-time 10 \
    -u "Hex:${GAME_PASSWORD}" \
    "${ADMIN_URL}/api/logs/game.log" 2>/dev/null | wc -l || echo 0)
if (( log_lines >= 5 )); then
    pass "game.log endpoint returned ${log_lines} lines (log_map verified)"
else
    fail "game.log endpoint returned ${log_lines} lines — expected ≥5"
fi

# --- Game port reachability ---
# Catches drift between the game's actual listen config (rendered from the
# .template at runtime) and the terraform firewall config. The recent
# c909a08-vs-2be922b mismatch (template said 27015, firewall opened 9876)
# would have been caught here.
header "Stage 5b — Game Port Reachability"

# Port spec from the per-game JSON (single source of truth — same file
# Terraform reads for firewall rules and shared/refresh.sh reads to write
# the manifest).
read -r -a ports_udp < <(python3 -c "
import json
print(' '.join(str(p) for p in json.load(open('$GAME_TFVARS')).get('game_ports_udp', [])))
")
read -r -a ports_tcp < <(python3 -c "
import json
print(' '.join(str(p) for p in json.load(open('$GAME_TFVARS')).get('game_ports_tcp', [])))
")

for p in "${ports_udp[@]}"; do
    if nc -zuvw 5 "$IP" "$p" >/dev/null 2>&1; then
        pass "UDP $p reachable from internet"
    else
        fail "UDP $p NOT reachable from internet (firewall vs game-listen drift?)"
    fi
done
for p in "${ports_tcp[@]}"; do
    if nc -zvw 5 "$IP" "$p" >/dev/null 2>&1; then
        pass "TCP $p reachable from internet"
    else
        fail "TCP $p NOT reachable from internet (firewall vs game-listen drift?)"
    fi
done

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