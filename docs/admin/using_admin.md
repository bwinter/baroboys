# 🎮🧛‍♂️ Power User Guide

## Index

* [🖥️ The Server](#-the-server)
* [🌐 Web Interface](#-web-interface)
* [📜 Logs](#-logs)
* [🦸‍♂️ Super Admin Notes](#-super-admin-notes)

---

## 🖥️ The Server

👉 Open the GCP VM page for your game: `https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-c/instances/<MACHINE_NAME>?project=europan-world`

1. 🟢 Click **Start**

    * Boots the server
    * Loads the most recent saved game state

2. 🟡 Games don't have a consistent technique for saving. 
   - Some do on intervals, others checkpoints.

3. 🔴 To shut down, visit the [Web Admin Interface](#-web-admin-interface) **OR** simply logout and wait for idle timeout.

---

## 🌐 Web Interface

1. **Visit**:

   ```
   http://<server-external-ip>:8080/
   ```

   `<server-external-ip>` is the VM's external IP from the GCP Console

2. **Login**:

    * **Username:** `Hex`
    * **Password:** *(same as game password)*

3. **💾 Save & Shutdown**

    * Captures the latest save
    * Powers down the server

---

## 📜 Logs

Click the **📜 Logs** dropdown in the admin panel to inspect server various behavior.

### Log Descriptions

| Log File               | Description                                                          |
|------------------------|----------------------------------------------------------------------|
| **game-startup.logs**  | Game's erver Logs.                                                   |
| **game-shutdown.logs** | Actions taken during graceful shutdown, including save confirmation. |
| ***.logs**             | More system level logs exists, this is not an exhaustive list.       |

Logs are automatically refreshed.

---

## 🦸‍♂️ Super Admin Notes

### 🔐 Rotate Admin Password

```bash
make update-password

# 🚨 Then SSH into the server
make ssh
```

On the server:
```bash
# restart Nginx:
/usr/bin/sudo systemctl reload nginx

# rebuild configs:
/usr/bin/sudo systemctl restart game-setup.service

# restart the server:
/usr/bin/sudo systemctl restart game-startup.service
```