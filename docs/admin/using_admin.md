# 🎮🧛‍♂️ V Rising Server Admin Guide

## ✅ Available Operations

* 🟢 Start the server
* 💾 Save game state and gracefully shut down
* 🔍 Check system status
* 📜 View logs

---

## 🖥️ VM Lifecycle

👉 [**Open GCP VM Admin Page
**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-c/instances/europa?project=europan-world)

1. 🟢 Click **Start**

    * Boots the server
    * Loads the most recent saved game state

2. 🟡 Each game saves on its own cadence.

3. 🔴 To shut down, visit the **Web Admin Interface**  
   *See `💾 Save & Shutdown` section below*

---

### 🌐 Use the Admin Panel

1. Visit:

   ```
   http://<server-external-ip>:8080/
   ```

   > You can find this IP *see `🖥️ VM Lifecycle` section above*

2. Login:

    * **Username:** `Hex`
    * **Password:** *(same as game password)*

3. Click **🟠 Save & Shutdown**

    * Captures the latest save
    * Powers down the server

   ⚠️ **Note:** This ensures the latest progress is saved remotely before shutting down.

4. When the server shuts down, the page will turn orange.

    * Can also watch `shutdown.log`

---

## 📜 Logs

Click **📜 View Logs** in the admin panel to inspect server behavior.

### Log Descriptions

| Log File          | Description                                                           |
|-------------------|-----------------------------------------------------------------------|
| **startup.logs**  | Records the game's boot process and initialization steps.             |
| **shutdown.logs** | Tracks actions during graceful shutdown, including save confirmation. |

Logs are accessible from the admin page and are automatically refreshed.

---

## 🦸‍♂️ Super Admin Notes

### 🔐 Rotate Admin Password

```bash
htpasswd -c temp_htpasswd vrising  # Replace current credentials
gcloud secrets versions add nginx-htpasswd \
  --data-file=temp_htpasswd

# 🚨 Then SSH into the server and restart Nginx:
/usr/bin/sudo systemctl reload nginx
```