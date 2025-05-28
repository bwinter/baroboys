Here's a streamlined and polished version of your admin doc, optimized for clarity, order, and tone — while preserving all the functionality:

---

# 🎮🧛‍♂️ Server Admin – V Rising

## ✅ What You Can Do

* 🟢 Start or 🔴 Stop the server (via GCP Console)
* 💾 Save and shut down gracefully (via browser or cURL)
* 🧙‍♂️ Use in-game admin [console commands](https://vrising.fandom.com/wiki/Console)

---

## 🖥️ Server Lifecycle

👉 [**Open the VM in Google Cloud**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)

1. 🟢 Click **Start**

   * Boots the server and loads the most recent save
2. 🟡 The server auto-saves every 10 minutes
3. 🔴 Click **Stop** to power off the VM

---

## 💾 Save & Shutdown

To save and gracefully shut down the server (runs `shutdown.service`):

### 🖱️ Browser Method

1. Visit:

   ```
   http://[SERVER_EXTERNAL_IP]:8080/
   ```
2. Log in with:

   * **Username**: `vrising`
   * **Password**: *(normal admin password)*
3. Click **🟠 Save & Shutdown**

### 🔁 Terminal (cURL)

```bash
curl -u vrising:yourpassword -X POST http://[SERVER_EXTERNAL_IP]:8080/trigger-shutdown
```

---

## 🧙‍♂️ In-Game Admin Console Access

1. First time only:
   Enable console → Settings → General → ✅ *Enable Console*

2. Join server (name: **Mc's Playground**)

3. Press `~` in-game to open the console

4. Type:

   ```bash
   adminauth
   ```

5. [Console command reference](https://vrising.fandom.com/wiki/Console)

---

## 📜 Logs

1. Get the VM's external IP from the [GCP Console](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)
2. Open in browser:

   ```
   http://[SERVER_EXTERNAL_IP]:8080/logs/
   ```
3. Login with:

   * **Username**: `vrising`
   * **Password**: *(same as admin)*

---

## 🦸‍♂️ Super Admin

### 🔐 Update Log Access Password

```bash
htpasswd -c temp_htpasswd vrising
gcloud secrets versions add nginx-htpasswd --data-file=temp_htpasswd
```

> 📝 Use `-c` to overwrite. Omit `-c` to add users to an existing file.

---

Would you like this version saved into `docs/usage/vrising_admin.md` or a new markdown file?
