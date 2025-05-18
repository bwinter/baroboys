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
    - This ensures your VM can clone private repos

2. **Provision GCP infrastructure**
    - See [`docs/setup/gcp-service-account.md`](./docs/setup/gcp-service-account.md)
    - Then apply Terraform in the `/terraform` folder

3. **Debug server**
    - See [`docs/usage/troubleshooting.md`](./docs/usage/troubleshooting.md)

---

## 🔐 Security Notes
- All secrets (e.g., GitHub deploy key, service account JSON) should be stored locally and excluded from version control.

## License

This project is licensed under the [Polyform Small Business License](https://polyformproject.org/licenses/small-business/1.0.0/).

- ✅ Free for personal, educational, and small business use (under $1M revenue)
- ❌ Commercial use by larger companies requires a commercial license

If you’re a business above the size threshold and would like to use this project, please contact me at [your-email@example.com].
