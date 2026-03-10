# VRising Deploy + Inspection Runbook

Tracks a full deploy-and-verify run. Check off stages as completed.
Commands recorded here are the seed of a future CI smoke test script.

**Context:** Run after the VRisingServer.log symlink change (b334b10) and full image rebuild
to verify: symlink works, admin panel serves the log, VRising boots cleanly under Wine.

---

## Stage 1 — Environment Check
- [ ] direnv vars active (`PROJECT`, `ZONE`, `MACHINE_NAME`, `GCP_USER`)
- [ ] gcloud authenticated and pointing at correct project

```bash
echo "PROJECT=$PROJECT ZONE=$ZONE MACHINE_NAME=$MACHINE_NAME GCP_USER=$GCP_USER"
gcloud config get-value project
gcloud auth list --filter=status:ACTIVE --format="value(account)"
```

---

## Stage 2 — Terraform Apply
- [ ] `make terraform-apply-vrising` exits 0
- [ ] External IP printed in terraform output

```bash
make terraform-apply-vrising
```

Expected output includes:
```
admin_server_url = "http://<IP>:8080"
```

---

## Stage 3 — Boot Watch (Serial Port)
- [ ] VM reaches `RUNNING` state
- [ ] Serial output shows systemd boot sequence in order:
  - [ ] `refresh-repo-startup`
  - [ ] `game-setup`
  - [ ] `xvfb-startup`
  - [ ] `game-startup`
- [ ] No `Failed` or `dependency failed` lines

```bash
# Poll VM status
gcloud compute instances describe europa \
  --zone=us-west1-c \
  --project=europan-world \
  --format="value(status,networkInterfaces[0].accessConfigs[0].natIP)"

# Watch boot sequence
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-c \
  --project=europan-world
```

---

## Stage 4 — SSH Inspection
- [ ] SSH succeeds
- [ ] `game-setup.service` completed successfully
- [ ] `game-startup.service` active (running)
- [ ] `admin-server-startup.service` active
- [ ] Symlink exists: `/var/log/baroboys/VRisingServer.log -> .../VRising/logs/VRisingServer.log`
- [ ] VRisingServer.exe process visible in `ps`
- [ ] Admin server responding on :5000

```bash
# SSH in
make ssh

# --- on the VM ---

# Service health
sudo systemctl status game-setup.service
sudo systemctl status game-startup.service
sudo systemctl status admin-server-startup.service

# Verify symlink (KEY CHECK for b334b10)
ls -la /var/log/baroboys/VRisingServer.log

# VRising process running
ps aux | grep -i vrising

# Admin server alive
curl -s http://localhost:5000/ping
```

---

## Stage 5 — Admin Panel
- [ ] Admin panel reachable at `http://<IP>:8080`
- [ ] Health check (`/ping`) responds
- [ ] VRisingServer.log accessible via log endpoint (no 404/500)

```bash
# Get URL
make admin-url

# Health check (replace IP)
curl -s -u Hex:$(gcloud secrets versions access latest --secret=server-password) \
  http://<IP>:8080/api/ping

# VRisingServer.log via admin panel
curl -s -u Hex:$(gcloud secrets versions access latest --secret=server-password) \
  http://<IP>:8080/api/logs/VRisingServer.log | head -20
```

---

## Stage 6 — Teardown
- [ ] `make destroy` exits 0 (or idle timeout triggers naturally after 30 min)

```bash
make destroy
```

---

## Notes / Issues Found

*(record anything unexpected here during the run)*

---

## Status

- [ ] Run complete — all checks passed