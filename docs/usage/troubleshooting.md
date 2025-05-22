## ✅ Troubleshooting

### 🧭 When to Use Each Diagnostic Tool

| Tool                                                   | Scope                            | When to Use                                                             |
| ------------------------------------------------------ | -------------------------------- | ----------------------------------------------------------------------- |
| `gcloud compute instances get-serial-port-output`      | Serial console output (boot log) | VM won’t boot, startup script fails silently, or SSH is unreachable     |
| `journalctl -u google-startup-scripts.service`         | Local systemd unit logs          | VM booted, but startup script failed partially or logged errors         |
| `sudo systemctl status google-startup-scripts.service` | Startup script unit health       | Quick status check — did the unit run, is it active, why did it stop?   |
| `gcloud logging read ...`                              | Cloud Logging (Stackdriver)      | View logs after boot or postmortem; requires OSConfig + logging enabled |
| `gcloud compute ssh ...`                               | SSH shell                        | Use if the VM is up and reachable, for interactive debugging            |

---

### 🧰 Helpful Commands

#### 🪵 Boot-time logs (no SSH required):

```bash
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-b
```

Optional extended logs:

```bash
gcloud compute instances get-serial-port-output europa \
  --zone=us-west1-b --port=1
```

---

#### 📖 Cloud Logging CLI (if enabled):

```bash
gcloud logging read \
  "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" \
  --project=europan-world \
  --limit=50 \
  --format="json"
```

---

#### 🔐 SSH to VM (normal):

```bash
gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b
```

#### 🔒 SSH with IAP (no external IP):

```bash
gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b \
  --tunnel-through-iap
```

---

#### 🧪 Run these after SSHing into the VM:

**Startup script logs:**

```bash
sudo journalctl -u google-startup-scripts.service -e
```

**Startup script status:**

```bash
sudo systemctl status google-startup-scripts.service
```

**Check steam Status:**

```shell
curl -s "https://api.steampowered.com/ISteamApps/GetServersAtAddress/v0001?addr=$(curl -s ifconfig.me)"
```