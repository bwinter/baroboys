# 🧪 Nginx Log Access Troubleshooter

Having trouble accessing your admin logs at `http://<your-ip>:8080/logs/`?

Start here:

---

## 📄 1. Inspect Nginx Error Logs

SSH into the VM and check:

```bash
/usr/bin/sudo tail -n 50 /var/log/nginx/error.log
````

Look for messages like:

* `Permission denied`
* `user "vrising" was not found`
* `open() failed`
* `404 Not Found`

---

## ✅ 2. Confirm Nginx is Running

```bash
/usr/bin/sudo systemctl status nginx
```

If it's not running:

```bash
/usr/bin/sudo systemctl start nginx
```

Or to apply config changes:

```bash
/usr/bin/sudo systemctl reload nginx
```

---

## 🔐 3. Check .htpasswd Permissions

Error:

```
open() "/etc/nginx/.htpasswd" failed (13: Permission denied)
```

Fix it:

```bash
/usr/bin/sudo chmod 644 /etc/nginx/.htpasswd
```

---

## 👤 4. Check if `vrising` User Exists

Error:

```
user "vrising" was not found in "/etc/nginx/.htpasswd"
```

View file:

```bash
cat /etc/nginx/.htpasswd
```

If missing:

```bash
htpasswd -c temp_htpasswd vrising
gcloud secrets versions add nginx-htpasswd --data-file=temp_htpasswd
gcloud secrets versions access latest --secret=nginx-htpasswd \
  | /usr/bin/sudo tee /etc/nginx/.htpasswd > /dev/null
/usr/bin/sudo systemctl reload nginx
```

---

## 🌍 5. Confirm Logs Are Reachable

Visit:

```
http://<your-ip>:8080/logs/
```

If you get a `403 Forbidden`, fix log dir permissions:

```bash
/usr/bin/sudo chmod -R o+r /var/log/baroboys
```

If you get a `404`, ensure the trailing slash is present:

```
http://<your-ip>:8080/logs/   ✅
http://<your-ip>:8080/logs    ❌
```

---

> ℹ️ Once fixed, log files like `VRisingServer.log`, `startup.log`, and `shutdown.log` will be browsable via web browser
> with Basic Auth.
