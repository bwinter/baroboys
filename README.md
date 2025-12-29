# Infrastructure Automation for Game Servers

This project automates the hosting of game servers (currently for myself and my friends).

A design priority was no cost when unused. Hence, essentially all state lives in GitHub - allowing `terraform destory` to purge all of GCP.

Tech tl;dr is basically: GCP, Terraform, and Bash. (+ Steam, Packer, and a few linux tools)

There is a small admin console for managing the server and accessing the logs as well. It was designed to give limited admin control and debugging details without needing technical skills. It doesn't cleanly separate games yet, so the UI log access is a bit messy.

---

## 🧰 Requirements

- Terraform
    ```shell
    brew tap hashicorp/tap
    brew install hashicorp/tap/terraform
    ```
- Packer
    ```shell
    brew tap hashicorp/tap
    brew install hashicorp/tap/packer
    ```
- Google Cloud SDK (`gcloud`)
    ```shell
    curl -O https://dl.google.com/dl/cloudsdk/channels/rapid/downloads/google-cloud-cli-457.0.0-darwin-arm.tar.gz
    tar -xvzf google-cloud-cli-457.0.0-darwin-arm.tar.gz
    ./google-cloud-sdk/setup.sh
    ```
- A valid GCP project (e.g., `europan-world`)
- GitHub account (where game state lives currently)

---

## 🚀 Getting Started

1. **Configure GitHub SSH access** (once)
    - See [`docs/setup/github-deploy-key.md`](./docs/setup/github-deploy-key.md)
    - This ensures your VM can clone private repos

2. **Install GCP tooling** (once)
    - See [`docs/setup/installing-gcloud.md`](docs/setup/gcp-service-accounts.md)

3. **Configure GCP tooling** (once)
    - See [`docs/setup/gcp-service-account.md`](docs/setup/gcp-service-accounts.md)
    - After completion, Makefile should now be usable

4. **Debug server**
    - See [`docs/usage/troubleshooting.md`](./docs/usage/troubleshooting.md)
    - Some basic commands you can run to debug install and game server issues.

---

## 🚀 Step-by-Step Setup

### 1. Clone the repo and initialize Terraform

```bash
git clone git@github.com:bwinter/baroboys.git
cd baroboys/terraform
terraform init
```

---

### 2. Build all packer images

```bash
make build
```

* Installs dependencies and enables services that run on boot.
    * (see `scripts/dependencies` and `scripts/services`)
    * Steam, Wine, Xvfb, and their dependencies
    * Some helpful server side command line tools. e.g., curl, wget, etc.
    * Install GCP monitoring packages.
* (Note that this builds images both games. See Makefile for more fine-grained control.)

---

### 3. Apply Terraform to create the VM and start the game server

Select the game by editing terraform/variables.tf (update `game_image` variable)

```bash
make apply
```

* This boots a VM
    * Every boot the repo pulls HEAD, and the game updates if necessary.

---

### 4. (Optional) Destroy the instance when done with the server

```bash
make destroy
```

If you skip this, the server will power off after 30 minutes of disuse. This will leave it in a powered-off state, where it can be manually started in the GPC UI. (Something simple enough that non-technical users are able to start the server on their own.)

---

## 🛠️ Debugging

| Goal              | Command                                                                    |
|-------------------|----------------------------------------------------------------------------|
| View startup logs | `gcloud compute instances get-serial-port-output europa --zone=us-west1-c` |
| View systemd logs | `journalctl -u google-startup-scripts.service -e`                          |

---

## 📦 Repo Structure

- **General Documentation** (`/docs`)
    - Setup and usage instructions

- **Setting up Access Management** (`/iam`)
    - Sets up terraform and VM service accounts (functional, but also a WIP)

- **Building VM Image** (`/packer`)
    - Installs dependencies and enables services that run on boot.

- **Infrastructure** (`/terraform`)
    - Provisions VMs, setup firewall rules, etc. 

- **Gameserver Setup and Execution** (`/scripts`)
    - Installers / updaters for environment dependencies
    - Services that support the game's server
    - Misc tools for debugging and development
    - (Note: This section is a work in progress and may evolve as the project matures.)
      - It works fairly well, but it's possible there might be a better separation of concerns. 

- **Barotrauma State & Mods** (`/Barotrauma`)
    - Contains saved games, mod files, and game server config

- **VRising State & Mods** (`/VRising`)
    - Contains saved games, and game server config

---

## 🔐 Security Notes

- All secrets (e.g., GitHub deploy key, service account JSON) should be stored locally or in GCP secrete store and excluded from version control (e.g., see `.gitignore`).

## License

This project is licensed under the [Polyform Small Business License](https://polyformproject.org/licenses/small-business/1.0.0/).

- ✅ Free for personal, educational use
- ❌ Commercial use by larger companies requires a commercial license

If you’re a business that would like to use this project, please contact me at [bwinter.sc81@gmail.com].
