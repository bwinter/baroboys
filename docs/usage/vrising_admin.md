# 🎮🧛‍♂️ V Rising Server Admin Guide

## ✅ Available Operations

* 🟢 Start the server  
* 💾 Save game state and gracefully shut down  
* 🔍 Check system status  
* 📜 View logs  
* 🧙‍♂️ Use in-game [admin commands](https://vrising.fandom.com/wiki/Console)

---

## 🖥️ VM Lifecycle

👉 [**Open GCP VM Admin Page**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)

1. 🟢 Click **Start**

   * Boots the server  
   * Loads the most recent saved game state

2. 🟡 The server auto-saves every 10 minutes

3. 🔴 To shut down, visit the **Web Admin Interface**  
   *See `💾 Save & Shutdown` section below*

---

## 🧙‍♂️ In-Game Console Access

1. Enable developer console:  
   *Settings → General → Enable Console*

2. Join the server (e.g., **Mc’s Playground**)

3. Press `~` to open the in-game console

4. Authenticate:
   ```bash
   adminauth
   ````

5. Command reference:
   [https://vrising.fandom.com/wiki/Console](https://vrising.fandom.com/wiki/Console)

---

## 💾 Save & Shutdown

Game progress must be saved before shutting down the server.

### 🌐 Use the Admin Panel

1. Visit:

   ```
   http://<your-server-external-ip>:8080/
   ```

   > You can find this IP *see `🖥️ VM Lifecycle` section above*

2. Login:

   * **Username:** `vrising`
   * **Password:** *(same as server password)*

3. Click **🟠 Save & Shutdown**

   * Captures the latest save
   * Commits it to Git
   * Powers down the server

   ⚠️ **Note:** This save is immediate and separate from autosaves. It ensures the latest progress is committed before shutdown.

4. Click **🔄 Refresh Status**

   * Displays system uptime and current server status

---

## 📜 Logs

Click **📜 View Logs** in the admin panel to inspect server behavior.

### Log Descriptions

| Log File              | Description                                                               |
| --------------------- | ------------------------------------------------------------------------- |
| **VRisingServer.log** | Main game server log. Shows player joins, saves, and any gameplay errors. |
| **startup.log**       | Records the server boot process and game initialization steps.            |
| **shutdown.log**      | Tracks actions during graceful shutdown, including save confirmation.     |

Logs are accessible from the same admin page and automatically refresh. No command-line tools are required.

---

## 🦸‍♂️ Super Admin Notes

### 🔐 Update Log Access Password

To rotate the admin web login credentials:

```bash
htpasswd -c temp_htpasswd vrising  # Replace current credentials
gcloud secrets versions add nginx-htpasswd \
  --data-file=temp_htpasswd

# 🚨 Then SSH into the server and restart Nginx:
sudo systemctl reload nginx
```

> Omit `-c` to append new users instead of replacing the file.

### 🧰 Optional: CLI Shutdown (Advanced)

If you are SSH'd into the VM, you can trigger a graceful shutdown manually:

```bash
sudo /root/baroboys/scripts/teardown/shutdown.sh
```

This will:

* Save the game
* Commit to Git
* Shut down the VM cleanly

---
