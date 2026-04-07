# GitHub SSH Deploy Key — Manual Setup

> **Prefer `make set-deploy-key`** — it automates all three steps below.
> This doc is the manual fallback if the `gh` CLI isn't available.

---

## 1. Generate SSH Key Pair

```bash
ssh-keygen -t ecdsa -b 521 -C "vm-github-access" -f github-deploy-key -N ""
```

⚠️ **Do not commit the private key to source control.**

---

## 2. Add the Public Key to GitHub

* Go to your GitHub repository → **Settings** → **Deploy Keys**
* Click **Add deploy key**
* Paste in the contents of `github-deploy-key.pub`
* Grant **write** access (needed for git push on shutdown)

---

## 3. Store the Private Key in Secret Manager

```bash
gcloud secrets create github-deploy-key --replication-policy=automatic
gcloud secrets versions add github-deploy-key --data-file=github-deploy-key
```

---

## Notes

* The `vm-runtime` service account has `roles/secretmanager.secretAccessor` — it can read this secret at boot.
* The key is retrieved by `refresh_repo.sh` on every boot for cloning/pulling.
