# 🎮 V Rising Server – Quick Admin Guide

## ✅ What You Can Do

* 🟢 Start / 🔴 Stop the server via Google Cloud
* 🧙‍♂️ Use in-game admin commands (e.g., `shutdown`, which triggers a save)

---

## 🖥️ Start / Stop the Server

👉 [**Open the Server in Google Cloud Console**](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)

* 🟢 Click **Start** to boot the server
* 🔴 Before stopping, run the save command below
* Then click **Stop** to shut it down

---

## 💾 Save Before Shutdown (In-Game)

1. First time only, **enable the console**:
   *Go to Settings → General → Enable Console*

2. Log into the server and press `~` to open the console

3. Type or paste the following:

   ```bash
   adminauth
   shutdown 1
   ```

This triggers an **autosave and graceful shutdown** in 1 minute. After that, you can safely click **Stop** in the Cloud Console.