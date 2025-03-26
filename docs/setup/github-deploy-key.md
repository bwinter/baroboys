## 🔐 GitHub SSH Deploy Key Setup (Automated via Secret Manager)

To allow VMs to clone private GitHub repositories securely:

### 1. Generate SSH Key Pair
```bash
ssh-keygen -t ecdsa -b 521 -C "vm-github-access"
```
Name the key something like `id_ecdsa_github`.  
**Keep the private key secure.**

### 2. Add the Public Key to GitHub
- Go to your GitHub repo → **Settings** → **Deploy Keys**
- Add the contents of `id_ecdsa_github.pub` as a new key (read-only or write access as needed)

### 3. Store the Private Key in Secret Manager
```bash
gcloud secrets create github-deploy-key \
  --replication-policy="automatic"

gcloud secrets versions add github-deploy-key \
  --data-file="id_ecdsa_github"
```

### 4. Grant Access to the VM's Service Account
```bash
gcloud projects add-iam-policy-binding europan-world \
  --member="serviceAccount:git-service-account@europan-world.iam.gserviceaccount.com" \
  --role="roles/secretmanager.secretAccessor"
```

### 5. In Your Startup Script on the VM
```bash
gcloud secrets versions access latest --secret="github-deploy-key" \
  | tee "/root/.ssh/id_ecdsa"

chmod 700 "/root/.ssh/id_ecdsa"
```

> This securely retrieves the deploy key at boot and makes it available for `git clone` without requiring tokens or embedding credentials in your image.

