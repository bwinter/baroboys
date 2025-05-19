# Game Server and Infrastructure Setup

This project is an attempt at fully automating steam headless servers.

Tech tl;dr is basically: Terraform and Bash.

---

## 🧰 Requirements
- Terraform
- Google Cloud SDK (`gcloud`)
- A valid GCP project (e.g., `europan-world`)
- GitHub account (for deploy keys)

---

## 🚀 Getting Started

1. **Configure GitHub SSH access (once)**
    - See [`docs/setup/github-deploy-key.md`](./docs/setup/github-deploy-key.md)
    - This ensures your VM can clone private repos

2. **Configure & install GCP tooling** (once)
    - See [`docs/setup/gcp-service-account.md`](./docs/setup/gcp-service-account.md)
    - Then apply Terraform in the `/terraform` folder

3. **Terraform Basics**
    - See [`docs/setup/terraform.md`](./docs/setup/gcp-service-account.md)
    - Basic Terraform usage

4. **Debug server**
    - See [`docs/usage/troubleshooting.md`](./docs/usage/troubleshooting.md)
    - Some basic commands you can run to debug install and game server issues.

5. **Barotrauma Submarine Development**
    - See [`docs/setup/barotrauma.md`](./docs/setup/gcp-service-account.md)
    - Helpful when building submarines.

---

## 🚀 Step-by-Step Setup

### 1. Clone the repo and initialize Terraform

```bash
git clone git@github.com:bwinter/baroboys.git
cd baroboys/terraform
terraform init
```

---

### 2. Set your game mode (optional, default is `vrising`)

```bash
./scripts/switch_game.sh
# or manually edit `.envrc`:
# export ACTIVE_GAME=barotrauma
```

Ensure `direnv` is installed and run (or set env manually):

```bash
direnv allow .
```

---

### 3. Apply Terraform to create your VM and configure the server

```bash
terraform apply
```

* This boots a VM
* Installs Wine, SteamCMD, Xvfb
* Clones this repo for both `root` and `bwinter_sc81`
* Installs and configures the selected game
* Registers a `systemd` service for the game
* Registers a shutdown hook to auto-save to Git

---

### 4. Manually trigger a save (anytime)

```bash
./scripts/manual/save_game.sh
```

---

### 5. Destroy the instance when done

```bash
terraform destroy
```

💡 Auto-save runs before shutdown if the game service exits cleanly.

---

## 🛠️ Debugging

| Goal              | Command                                                                    |
| ----------------- | -------------------------------------------------------------------------- |
| View startup logs | `gcloud compute instances get-serial-port-output europa --zone=us-west1-b` |
| View systemd logs | `journalctl -u google-startup-scripts.service -e`                          |
| Debug save        | `journalctl -u barotrauma.service -e` or check Git commit logs             |

---

## 📦 Developers

- **Documentation** (`/docs`)
    - Clear setup and usage instructions
    - Covers service accounts, SSH key setup, troubleshooting, and more

- **Terraform Infrastructure** (`/terraform`)
    - Provisions VMs, enables GCP APIs, and configures IAM

- **Startup & Deployment Scripts** (`/scripts`)
    - Bootstraps Barotrauma environment on VM boot
    - Securely pulls GitHub SSH key from Secret Manager
    - Runs custom server setup logic

- **Barotrauma State & Mods** (`/Barotrauma`)
    - Contains saved games, mod files, and game server config

---

## 🔐 Security Notes
- All secrets (e.g., GitHub deploy key, service account JSON) should be stored locally and excluded from version control.

## License

This project is licensed under the [Polyform Small Business License](https://polyformproject.org/licenses/small-business/1.0.0/).

- ✅ Free for personal, educational, and small business use (under $1M revenue)
- ❌ Commercial use by larger companies requires a commercial license

If you’re a business above the size threshold and would like to use this project, please contact me at [your-email@example.com].
