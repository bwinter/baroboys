# 🎮 V Rising Server – Quick Admin Guide

## ✅ What You Can Do

* Start / Stop the server on Google Cloud
* Use admin commands in-game (save, announce, etc.)

---

## 🔌 Start / Stop the Server

👉 **Use this link:**
[**Open the VM in Google Cloud**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)

* 🟢 **Start** = Click "Start"
* 🔴 **Stop** = Click "Stop" (auto-saves before shutdown)

---

## 🧙‍♂️ In-Game Admin Access

1. **Enable Console**:
   In-game → Settings → General → Enable Console

2. **Open Console**:
   Press `~` (tilde key)

3. **Login as Admin**:

   ```bash
   adminauth
   ```

You’re now an admin!

---

## 🔁 Optional: Graceful Restart

Send this via the admin console:

```bash
announce Server restarting in 60 seconds.
shutdown 60 Restarting for maintenance
```

Then restart the server via the Google Cloud link.