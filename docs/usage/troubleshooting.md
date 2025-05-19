## ✅ Troubleshooting

### 🧭 When to Use Each Diagnostic Tool

| Tool                                                   | Scope                            | When to Use                                                            |
| ------------------------------------------------------ | -------------------------------- | ---------------------------------------------------------------------- |
| `gcloud compute instances get-serial-port-output`      | Serial console output (boot log) | VM won't start properly, startup script failed, SSH is unreachable     |
| `journalctl -u google-startup-scripts.service`         | Local systemd unit logs          | VM booted, but startup script failed partially or silently             |
| `sudo systemctl status google-startup-scripts.service` | Summary status of startup unit   | Checking whether the startup unit even ran, or why it failed to reload |
| `gcloud logging read ...`                              | Cloud Logging (Stackdriver)      | You enabled OSConfig & Logging APIs; want historical logs post-boot    |
| `gcloud compute ssh ...`                               | SSH shell                        | Use if VM is up and you want to explore, fix, or inspect directly      |

---

### 🧰 Helpful Commands

#### Startup script logs:

  ```bash
  sudo journalctl -u google-startup-scripts.service -e
  ```

#### Debugging a reboot or restart:

  ```bash
  sudo systemctl status google-startup-scripts.service
  ```

#### Logs via CLI:

  ```bash
  gcloud logging read \
    "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" \
    --project=europan-world \
    --limit=50 \
    --format="json"
  ```

#### SSH onto the machine:

  ```bash
  gcloud compute ssh bwinter_sc81@europa \
    --project=europan-world \
    --zone=us-west1-b
  ```

#### SSH through IAP (if no external IP):

  ```bash
  gcloud compute ssh bwinter_sc81@europa \
    --project=europan-world \
    --zone=us-west1-b \
    --tunnel-through-iap
  ```