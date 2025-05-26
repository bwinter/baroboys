# 🎮 How to Admin the V Rising Server on GCP

## ✅ What you can do

You've been granted access to:

* Start or stop the V Rising server via Google Cloud Console.
* Connect in-game as an admin.
* Use admin console commands (e.g., autosave, restart, message players).

---

## 🔌 1. How to Start or Stop the Server

### 👉 Link to the server instance:

**[Open in Google Cloud Console](https://console.cloud.google.com/compute/instancesDetail/zones/us-west1-b/instances/europa?project=europan-world)**

### 🟢 To start the server:

1. Visit the link above.
2. Click the **Start** button (top panel).

### 🔴 To stop the server:

1. Same page, click the **Stop** button.
2. Wait \~30 seconds for the shutdown process to complete (it auto-saves before shutdown).

---

## 🧙‍♂️ 2. How to Become Admin in V Rising

### Step A: Connect to the Server as Normal

### Step B: Enable the Admin Console

1. Open **Settings > General** in V Rising.
2. Enable **Console** (toggle switch).
3. Press **\~** (tilde key) in-game to open the admin console.

   > On some keyboard layouts, it may be under ESC or `²`.

### Step C: Authenticate as Admin

In the console, type:

```bash
adminauth
```

If your Steam ID is on the admin list (which it is), you'll now have admin access.

---

## 💾 3. How to Trigger an Autosave (In Game)

Once you’ve authenticated as admin:

1. Open the console (`~`).
2. Run the command:

```bash
SaveGame
```

You’ll see confirmation in the console and in the server logs. The game will stutter briefly while saving.

---

## 🛑 Optional: Restart the Server Gracefully (via Command)

If you're comfortable using commands, you can send a shutdown notice with a delay using the admin console:

```bash
announce Server restarting in 60 seconds.
shutdown 60 Restarting for maintenance
```

Then wait 60 seconds and use the GCP console to restart the VM.