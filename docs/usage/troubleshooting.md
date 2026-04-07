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
gcloud compute instances get-serial-port-output <MACHINE_NAME> \
  --zone=us-west1-c
```

Where `<MACHINE_NAME>` is the game's VM name (e.g. `vrising`, `barotrauma`).

Optional full boot output:

```bash
gcloud compute instances get-serial-port-output <MACHINE_NAME> \
  --zone=us-west1-c --port=1
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
gcloud compute ssh <GCP_USER>@<MACHINE_NAME> \
  --project=europan-world \
  --zone=us-west1-c
```

### SSH via IAP (no external IP):

```bash
gcloud compute ssh <GCP_USER>@<MACHINE_NAME> \
  --project=europan-world \
  --zone=us-west1-c \
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

## 🔁 Restart Game Server

To gracefully restart the server through systemd:

```bash
/usr/bin/sudo systemctl restart game-startup.service
```

## ✅ Check Game Server Status:

```bash
/usr/bin/sudo systemctl status game-startup.service
```

---

## 🎮 **Game Server Logs**

### `game-startup.service` logs (game lifecycle):

```bash
/usr/bin/sudo journalctl -u game-startup.service --since="-10min" --no-pager
```

### `game-shutdown.service` logs (shutdown & save):

```bash
/usr/bin/sudo journalctl -u game-shutdown.service --since="-10min" --no-pager
```

### `game-refresh.service` logs (game setup & provisioning):

```bash
/usr/bin/sudo journalctl -u game-refresh.service --since="-10min" --no-pager
```

---

## 🌐 **Steam Master Server Check**

Ensure the server is externally discoverable:

```bash
curl -s "https://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=$(curl -s ifconfig.me)"
```