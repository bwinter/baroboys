# Infrastructure Automation for Game Servers

This project automates the hosting of game servers (currently works for VRising and Barotrauma).

A design priority was low cost, ideally 0 when unused. To that end, this repo saves (essentially) all state to GitHub - allowing `terraform destory` to purge GCP down to a near 0 cost.

(I would love to have demoed k8s and Go in this project, but I think they would be unnecessary complexities for a reltiavely simple project.)

Tech Stack tl;dr is: GCP, Packer, Terraform, and Bash. (+ Steam, and a few linux tools)

There is a small admin console for managing the server and accessing the logs as well. It was designed to give limited admin control and debugging details without needing technical skills. (It doesn't currently separate game UI well – aka it needs some work but is functional.)

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
- Google Cloud SDK (`gcloud`) (see [docs/setup/installing-gcloud.md](docs/setup/gcp-service-accounts.md) for help installing)
- A valid GCP project (e.g., `europan-world`)
- GitHub project (e.g. `baroboys`)
- `direnv` (see .envrc for configuration)
  - TODO: need to make a boostrap for this / centralize configuration.

---

## 🚀 Getting Started

1. **Configure GitHub SSH access** (once)
    - See [docs/setup/github-deploy-key.md](./docs/setup/github-deploy-key.md)
    - This ensures your VM can clone your repository.

2. **Running Server**
    - See [Step-by-Step Setup](#-step-by-step-setup) below.

3. **Runtime Debugging**
    - See [docs/usage/troubleshooting.md](./docs/usage/troubleshooting.md)
    - Some basic commands you can run to debug install and runtime issues.

---

## 🚀 Step-by-Step Setup

### 1. Fork this repo and then clone it

```bash
git clone git@github.com:<YOUR_USER>/<YOUR_FORK>.git
```

---

### 2. Create Service Accounts and Terraform Buckets

Ensure you are authenticated as a project owner:

```bash
gcloud auth application-default login
gcloud config set project <YOUR_PROJECT>
````

Boostrap Service Account:

```bash
make bootstrap
```

- See [`docs/setup/gcp-service-account.md`](docs/setup/gcp-service-accounts.md) for details.

---

### 3. Build all packer images

```bash
make build
```

* Installs dependencies and enables services that run on boot.
    * (see `scripts/dependencies` and `scripts/services`)
    * Steam, Wine, Xvfb, and their dependencies
    * Some helpful server side command line tools. e.g., curl, wget, etc.
    * Install GCP monitoring packages.
* (Note that this builds images for all games. See Makefile `help` for more fine-grained control.)

---

### 4. Apply Terraform to create the VM and start the game server

```bash
make apply GAME=barotrauma
```

* This boots game VM
* Note the server shutsdown after 30 minutes of inactivity. Saveing the game at the same time.
* To restart the server, simply power it back on via the GCP UI.
  * To grant others ability to start server, see `make iam-add-admin`.

---

### 5. (Optional) Destroy the instance when done with the server

```bash
make destroy
```

* Lowest GCP cost.

---

### 6. See Makefile help for more options

```bash
make help
```

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

- **Bootstrapping** (`/bootstrap`)
    - Sets up service accounts and TF buckets.

- **VM Image** (`/packer`)
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
    - Contains saved games and game server config

---

## License

This project is licensed under the [Polyform Small Business License](https://polyformproject.org/licenses/small-business/1.0.0/).

- ✅ Free for personal, educational use
- ❌ Commercial use by larger companies requires a commercial license

If you’re a business that would like to use this project, please contact me at [bwinter.sc81@gmail.com].
