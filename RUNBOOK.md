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

---

## Stage 2 — Terraform Apply
- [ ] `make terraform-apply-vrising` exits 0
- [ ] External IP visible in terraform output

```bash
# Provision VRising VM + firewall rules
make terraform-apply-vrising
```

**Result:** *(fill in after running — IP, any errors)*

---

## Stage 3 — Boot Watch
- [ ] VM status reaches `RUNNING`
- [ ] Serial output shows boot order: refresh-repo → game-setup → xvfb → game-startup
- [ ] No `Failed` or `dependency failed` lines

```bash
# Poll until RUNNING, capture external IP
gcloud compute instances describe europa \
  --zone=us-west1-c --project=europan-world \
  --format="value(status,networkInterfaces[0].accessConfigs[0].natIP)"

# Inspect full boot sequence via serial console
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-c --project=europan-world
```

**Result:** *(fill in — boot time, any warnings)*

---

## Stage 4 — SSH Inspection
- [ ] SSH succeeds
- [ ] `game-setup.service` completed
- [ ] `game-startup.service` active (running)
- [ ] `admin-server-startup.service` active
- [ ] Symlink correct: `/var/log/baroboys/VRisingServer.log -> .../VRising/logs/VRisingServer.log`
- [ ] VRisingServer.exe process visible
- [ ] Admin server responding on :5000

```bash
# SSH and run inline inspection
gcloud compute ssh bwinter_sc81@europa --zone=us-west1-c --project=europan-world \
  --command="
    sudo systemctl is-active game-setup.service
    sudo systemctl is-active game-startup.service
    sudo systemctl is-active admin-server-startup.service
    ls -la /var/log/baroboys/VRisingServer.log
    ps aux | grep -i vrising | grep -v grep
    curl -s http://localhost:5000/ping
  "
```

**Result:** *(fill in — symlink target, process state, ping response)*

---

## Stage 5 — Admin Panel
- [ ] Admin panel reachable at `http://<IP>:8080`
- [ ] Health ping responds
- [ ] VRisingServer.log endpoint returns content (not 404/500)

```bash
# Capture IP from terraform output
ADMIN_URL=$(cd terraform && terraform output -raw admin_server_url)
SERVER_PASSWORD=$(gcloud secrets versions access latest --secret=server-password --project=europan-world)

# Health check
curl -s -u "Hex:${SERVER_PASSWORD}" "${ADMIN_URL}/api/ping"

# Verify VRisingServer.log accessible via admin panel (KEY CHECK)
curl -s -u "Hex:${SERVER_PASSWORD}" "${ADMIN_URL}/api/logs/VRisingServer.log" | head -5
```

**Result:** *(fill in — ping response, first log lines)*

---

## Stage 6 — Teardown
- [ ] VM destroyed (manual or idle timeout after 30 min)

```bash
# Destroy all provisioned infrastructure
make destroy
```

**Result:** *(fill in)*

---

## Issues Found

*(record anything unexpected during the run)*

---

## Final Status
- [ ] All stages passed — ready to convert to CI script