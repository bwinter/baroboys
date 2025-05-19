# 🔐 GitHub SSH Deploy Key Setup (Automated via Secret Manager)

To allow VMs to securely clone private GitHub repositories via SSH, this setup stores an SSH private key in Secret
Manager, accessible only by the VM's runtime service account.

---

## 1. Generate SSH Key Pair

```bash
ssh-keygen -t ecdsa -b 521 -C "vm-github-access"
````

Name the key `github-deploy-key` or similar.

⚠️ **Do not commit the private key to source control.**

---

## 2. Add the Public Key to GitHub

* Go to your GitHub repository → **Settings** → **Deploy Keys**
* Click **Add deploy key**
* Paste in the contents of `github-deploy-key.pub`
* Grant **read-only** or **write** access depending on need

---

## 3. Store the Private Key in Secret Manager

```bash
gcloud secrets create github-deploy-key \
  --replication-policy="automatic"

gcloud secrets versions add github-deploy-key \
  --data-file="github-deploy-key"
```

---

## 🧠 Notes

* The service account `vm-runtime@...` is attached to the VM via Terraform.
* The key is retrieved at boot (inside the startup script) and used for `git clone` via SSH.
* This avoids embedding credentials in your image or using GitHub tokens.
