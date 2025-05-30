## 🧰 V Rising Server Admin: Restarting & Monitoring

### 🔁 Restart via systemd

To gracefully restart the server through systemd:

```bash
sudo systemctl restart vrising.service
```

#### ✅ Check server status:

```bash
sudo systemctl status vrising.service
```

#### 📜 Tail live logs:

```bash
journalctl -u vrising.service -f
```

---

### 📣 Restart via `mcrcon` (graceful in-game notice)

To gracefully restart the server with visible player warnings:

```bash
mcrcon -H 127.0.0.1 -P 25575 -p Donalds \
  "announce Server restarting in 60 seconds." \
  "announcerestart 1" \
  "shutdown 60 Restarting for maintenance"
```

This will:

* Notify players with a custom message.
* Trigger a localized (translated) restart warning.
* Begin shutdown in 60 seconds.

---

### ⚡️ Immediate restart (use with caution)

For fast testing, you can skip the warning:

```bash
mcrcon -H 127.0.0.1 -P 25575 -p Donalds \
  "shutdown 5 Immediate restart"
```

Then restart the systemd unit:

```bash
sudo systemctl restart vrising.service
```

---

> Omit `-c` to append new users instead of replacing the file.

### 💾 Want to auto-save before restarting?

If you are SSH'd into the VM, you can trigger a graceful shutdown manually:

```bash
sudo /root/baroboys/scripts/teardown/shutdown.sh
```

This will:

* Save the game
* Commit to Git
* Shut down the VM cleanly

---

# REFS

https://steamcommunity.com/app/1604030/discussions/0/4615641262430325784/
https://vrising.fandom.com/wiki/V_Rising_Dedicated_Server#Server_Configuration
https://github.com/StunlockStudios/vrising-dedicated-server-instructions
