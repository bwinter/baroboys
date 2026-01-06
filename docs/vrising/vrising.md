# 🧰 V Rising Server Admin:

---

### 📜 VRising game log (in-game server events):

```bash
tail -n 200 /home/bwinter_sc81/baroboys/VRising/logs/VRisingServer.log
```

---

### 📣 Restart via `mcrcon` (graceful in-game notice)

To gracefully restart the server with visible player warnings:

```bash
mcrcon -H 127.0.0.1 -P 25575 -p <PW> \
  "announce Server restarting in 60 seconds." \
  "announcerestart 1" \
  "shutdown 60 Restarting for maintenance"
```

This will:

* Notify players with a "Server restarting in 60 seconds." message.
* Begin shutdown in 60 seconds.

---

### ⚡️ Immediate restart (use with caution)

For fast testing, you can skip the warning:

```bash
mcrcon -H 127.0.0.1 -P 25575 -p <PW> \
  "shutdown 5 Immediate restart"
```

---

### 💾 Want to auto-save before restarting?

If you are SSH'd into the VM, you can trigger a graceful shutdown manually:

```bash
/usr/bin/sudo /root/baroboys/scripts/services/vrising/shutdown.sh
```

This will:

* Save the game
* Commit to Git
* Shut down the VM cleanly

---

# Server Configuration References:

https://steamcommunity.com/app/1604030/discussions/0/4615641262430325784/
https://vrising.fandom.com/wiki/V_Rising_Dedicated_Server#Server_Configuration
https://github.com/StunlockStudios/vrising-dedicated-server-instructions

# In Game Commands

* 🧙‍♂️ Use in-game [admin commands](https://vrising.fandom.com/wiki/Console)

---

## 🧙‍♂️ In-Game Console Access

1. Enable developer console:  
   *Settings → General → Enable Console*

2. Join the server

3. Press `~` to open the in-game console

4. Authenticate:
   ```bash
   adminauth
   ````

5. Command reference:
   [https://vrising.fandom.com/wiki/Console](https://vrising.fandom.com/wiki/Console)