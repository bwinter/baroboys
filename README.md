# Baroboys Infrastructure & Server Setup

Welcome to the Baroboys project — a fully automated and documented setup for deploying and running a dedicated Barotrauma game server on Google Cloud Platform using Terraform, startup scripts, and Secret Manager for secure configuration.

---

## 📦 What This Repo Contains

- **Terraform Infrastructure** (`/terraform`)
    - Provisions VMs, enables GCP APIs, and configures IAM
    - Automates project metadata and logging setup

- **Startup & Deployment Scripts** (`/scripts`)
    - Bootstraps Barotrauma environment on VM boot
    - Securely pulls GitHub SSH key from Secret Manager
    - Runs custom server setup logic

- **Barotrauma State & Mods** (`/Barotrauma`)
    - Contains saved games, mod files, and config data

- **Documentation** (`/docs`)
    - Clear setup and usage instructions
    - Covers service accounts, SSH key setup, troubleshooting, and more

---

## 🚀 Getting Started

1. **Configure GitHub SSH access**
    - See [`docs/setup/github-deploy-key.md`](./docs/setup/github-deploy-key.md)
    - This ensures your VM can clone private repos securely

2. **Provision GCP infrastructure**
    - See [`docs/setup/gcp-service-account.md`](./docs/setup/gcp-service-account.md)
    - Then apply Terraform from the `/terraform` folder

3. **Start or debug the server**
    - See [`docs/usage/troubleshooting.md`](./docs/usage/troubleshooting.md)

---

## 🔐 Security Notes
- All secrets (e.g., GitHub deploy key, service account JSON) should be stored locally and excluded from version control.
- Service account permissions should be locked down after initial bootstrap.

---

## 🧰 Requirements
- Terraform
- Google Cloud SDK (`gcloud`)
- GitHub account (for deploy keys)
- A valid GCP project (e.g., `europan-world`)

---

## 📂 Directory Overview
```
terraform/   → Terraform code and state
scripts/     → Startup and install scripts
Barotrauma/  → Game state, mod files, and server config
docs/        → Markdown docs for setup, usage, and troubleshooting
```