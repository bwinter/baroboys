# 🎮🧛‍♂️ Server Admin (V Rising)

## ✅ What You Can Do

* 🟢 Start / 🔴 Stop server
* 🧙‍♂️ Use in-game admin [commands](https://vrising.fandom.com/wiki/Console)

---

## 🖥️ Server Lifecycle

👉 [**Open server admin page in GCP**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)

1. 🟢 Click **Start**
   - **Boot** Server 
   - **Load** most recent save
2. 🟡 Server **Auto-Saves** every 10 minutes
3. 🟠 Click **Stop** to poweroff

---

## 🧙‍♂️ V Rising Admin Console Access

1. First time only:
   * Start V Rising → Settings → General → Enable Console

2. Log into server (Mc's Playground)

3. Press `~` in-game to open **console**

4. Authenticate as admin by typing this in the console:

   ```bash
   adminauth
   ```

5. V Rising Console Wiki: https://vrising.fandom.com/wiki/Console

# 📜 Logs

1. [**Open server admin page in GCP**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)
2. Look for your VM's external IP
3. Open the following URL in your browser (replace with actual IP):
   - `http://[SERVER_EXTERNAL_IP]:8080/logs`
   - Username: vrising
   - Password: (normal password)

---

### 🔄 Update Log Access Password

To change the log access password, run:

```bash
htpasswd -c temp_htpasswd vrising
gcloud secrets versions add nginx-htpasswd \
--data-file=temp_htpasswd
```

> 📝 `-c` overwrites the file. Omit `-c` if you're adding a new user to an existing file.
