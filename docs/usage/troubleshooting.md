#### Helpful Tools:

- Startup script logs:

  ```shell
  sudo journalctl -u google-startup-scripts.service -e
  ```

- Debugging a reboot:

  ```shell
  sudo systemctl status google-startup-scripts.service
  ```

- Logs via cli:

  ```shell
  gcloud logging read \
  "resource.type=gce_instance AND resource.labels.instance_id=INSTANCE_ID" \
  --project=europan-world \
  --limit=50 \
  --format="json"
  ```

- SSH onto the machine:

  ```shell
  gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b
  ```

- If No Public IP

  ```shell
  gcloud compute ssh bwinter_sc81@europa \
  --project=europan-world \
  --zone=us-west1-b \
  --tunnel-through-iap
  ```
