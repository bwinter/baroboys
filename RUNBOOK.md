# VRising Deploy + Inspection Runbook

**Goal:** E2E smoke test — pave IaaS, boot VRising, probe the VM for life.
Built interactively: update each stage with actual commands + results as we go.

**Conversion:** At the end, invert this doc into a bash script — prose lines become
`# comments`, bash blocks stay as-is. The result is a repeatable CI smoke test.

**Context:** Verifying the VRisingServer.log symlink (b334b10) and full image rebuild.
Checks: symlink present, admin panel serves the log, VRising boots cleanly under Wine.

**Resume:** If context resets, `cat RUNBOOK.md` to see current state and next step.

---

## Stage 1 — Environment Check ✅

- [x] direnv vars active
- [x] gcloud authenticated, correct project

```bash
# Verify environment vars and gcloud auth
echo "PROJECT=$PROJECT ZONE=$ZONE MACHINE_NAME=$MACHINE_NAME GCP_USER=$GCP_USER"
gcloud config get-value project
gcloud auth list --filter=status:ACTIVE --format="value(account)"
```

**Result:** PROJECT=europan-world ZONE=us-west1-c MACHINE_NAME=europa GCP_USER=bwinter_sc81 / bwinter.sc81@gmail.com

---

## Stage 2 — Terraform Apply ✅

- [x] terraform apply exits 0
- [x] External IP visible in output

```bash
# Provision VRising VM + firewall rules
# Note: build.sh is interactive; call terraform directly with -auto-approve for scripting
cd terraform && terraform apply -auto-approve \
  -var-file="shared.tfvars" \
  -var-file="game/vrising.tfvars"
```

**Result:** 7 resources added (VM + 5 firewall rules + random_id). IP: 34.19.107.48. ~32s.

---

## Stage 3 — Boot Watch ✅

- [x] VM status reaches `RUNNING`
- [x] Serial output shows boot order: refresh-repo → game-setup → xvfb → game-startup
- [x] No `Failed` or `dependency failed` lines

```bash
# Poll until RUNNING, capture external IP
gcloud compute instances describe europa \
  --zone=us-west1-c --project=europan-world \
  --format="value(status,networkInterfaces[0].accessConfigs[0].natIP)"

# Inspect boot sequence via serial console (filter to systemd service lines)
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-c --project=europan-world 2>&1 \
  | grep -E "systemd|game-|refresh-repo|xvfb|admin-server|Started|Starting|Failed|dependency"
```

**Result:** RUNNING immediately. Boot completed in 46s (kernel 1.5s + userspace 45s).
Sequence confirmed: idle-check-setup → xvfb-startup → admin-server-setup → admin-server-startup
→ game-setup → game-startup. All OK, zero failures.

---

## Stage 4 — SSH Inspection ✅

- [x] SSH succeeds
- [x] `game-setup.service` completed
- [x] `game-startup.service` active
- [x] `admin-server-startup.service` active
- [x] Symlink correct: `/var/log/baroboys/VRisingServer.log -> .../VRising/logs/VRisingServer.log`
- [x] VRisingServer.exe process visible
- [x] Admin server responding on :5000

```bash
# SSH and run inline inspection
gcloud compute ssh bwinter_sc81@europa --zone=us-west1-c --project=europan-world \
  --command="
    echo '=== Service Status ===' && \
    sudo systemctl is-active game-setup.service && \
    sudo systemctl is-active game-startup.service && \
    sudo systemctl is-active admin-server-startup.service && \
    echo '=== Symlink Check ===' && \
    ls -la /var/log/baroboys/VRisingServer.log && \
    echo '=== VRising Process ===' && \
    ps aux | grep -i vrising | grep -v grep && \
    echo '=== Admin Ping ===' && \
    curl -s http://localhost:5000/ping
  "
```

**Result:** All services active. Symlink: `lrwxrwxrwx root root 58 -> /home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log` ✅.
VRisingServer.exe running at 71% CPU / 3.5GB RAM. Admin ping: `pong`.

---

## Stage 5 — Admin Panel ✅

- [x] Health ping responds
- [x] VRisingServer.log endpoint returns content (not 404/500)

```bash
# Capture URL and password
ADMIN_URL="http://34.19.107.48:8080"
SERVER_PASSWORD=$(gcloud secrets versions access latest --secret=server-password --project=europan-world)

# Health check
curl -s -u "Hex:${SERVER_PASSWORD}" "${ADMIN_URL}/api/ping"

# Verify VRisingServer.log accessible via admin panel (KEY CHECK for b334b10)
curl -s -u "Hex:${SERVER_PASSWORD}" "${ADMIN_URL}/api/logs/VRisingServer.log" | head -5
```

**Result:** ping → `pong`. Log endpoint returned game output — first line:
`ServerGameSettings - Field InventoryStacksModifier parsed value '5' was modified after it was converted and clamped...`
Symlink verified end-to-end through the admin panel. ✅

---

## Stage 6 — Teardown ✅

- [x] VM destroyed

```bash
# Destroy all provisioned infrastructure
# Note: make destroy is interactive — call terraform directly with -auto-approve for scripting
cd terraform && terraform destroy -auto-approve \
  -var-file="shared.tfvars" \
  -var-file="game/vrising.tfvars"
```

**Result:** 7 resources destroyed. VM took ~1m42s to destroy, firewalls ~21s.

---

## Issues Found

- `make terraform-apply-vrising` is interactive (asks "yes") — not scriptable as-is.
  Must call terraform directly with `-auto-approve` (see Stage 2 command above).

---

## Final Status
- [x] All stages passed — ready to convert to CI script