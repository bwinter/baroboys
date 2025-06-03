# ✅ **Troubleshooting the V Rising GCP Server**

## 🧭 **Which Tool to Use and When**

| Tool                                                            | Scope                         | When to Use                                                              |
|-----------------------------------------------------------------|-------------------------------|--------------------------------------------------------------------------|
| `gcloud compute instances get-serial-port-output`               | Serial console (boot)         | VM won’t boot, startup script fails silently, SSH not available          |
| `journalctl -u google-startup-scripts.service`                  | Startup script logs (systemd) | VM boots, but provisioning (e.g. startup.sh) fails or partially executes |
| `/usr/bin/sudo systemctl status google-startup-scripts.service` | Unit health summary           | Verify if startup unit ran, succeeded, or failed                         |
| `gcloud logging read`                                           | Cloud Logging (optional)      | Postmortem debugging (if OSConfig + logging enabled)                     |
| `gcloud compute ssh`                                            | Direct access                 | Live VM debugging (VRising, Git, system state, etc.)                     |

---

## 🔌 **VM Boot Diagnostics**

### 🪵 Serial console (no SSH required):

```bash
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-b
```

Optional full boot output:

```bash
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-b --port=1
```

---

### 📖 Cloud Logging (if enabled):

```bash
gcloud logging read \
  "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" \
  --project=europan-world \
  --limit=50 \
  --format="json"
```

---

## 🔐 **SSH Access**

### Standard SSH:

```bash
gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b
```

### SSH via IAP (no external IP):

```bash
gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b \
  --tunnel-through-iap
```

---

## 🧪 **Post-SSH System Diagnostics**

### Google startup script logs:

```bash
/usr/bin/sudo journalctl -u google-startup-scripts.service -e
```

### Startup unit status:

```bash
/usr/bin/sudo systemctl status google-startup-scripts.service
```

---

## 🎮 **Game and Service Logs**

### `vrising.service` logs (game lifecycle):

```bash
/usr/bin/sudo journalctl -u vrising.service --since="-10min" --no-pager
```

### `vm-shutdown.service` logs (shutdown & save):

```bash
/usr/bin/sudo journalctl -u vm-shutdown.service --since="-10min" --no-pager
```

### `vm-startup.service` logs (game startup & provisioning):

```bash
/usr/bin/sudo journalctl -u vm-startup.service --since="-10min" --no-pager
```

---

### 📜 VRising game log (in-game server events):

```bash
tail -n 200 /home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log
```

---

## 🌐 **Steam Master Server Check**

Ensure server is externally discoverable:

```bash
curl -s "https://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=$(curl -s ifconfig.me)"
```