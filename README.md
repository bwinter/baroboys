# Infrastructure Automation for Game Servers

This project automates the hosting of game servers (currently works for VRising and Barotrauma).

A design priority was low cost, ideally 0 when unused. To that end, this repo saves all state (essentially) to GitHub — allowing `terraform destroy` to purge GCP down to a near 0 cost.

Tech Stack tl;dr is: GCP, Packer, Terraform, and Bash. (+ Steam, and a few linux tools)

There is a small admin console for managing the server and accessing the logs. It was designed to give limited admin control and debugging details without needing technical skills.

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

### 3. Create secrets

Set the shared password for game servers, admin panel, and RCON:

```bash
make set-password
```

Create the GitHub deploy key so the VM can clone this repo (requires `gh` CLI):

```bash
make set-deploy-key
```

---

### 4. Build all packer images

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

### 5. Apply Terraform to create the VM and start the game server

```bash
make terraform-apply-<Game>
```

* Replace `<Game>` with `VRising` or `Barotrauma`.
* This boots the game VM in its own Terraform workspace.
* The server shuts down after 30 minutes of inactivity, saving the game automatically.
* To restart: `make start-<Game>`
* To grant others the ability to start the server: `make iam-add-admin`
* To get the admin panel URL: `make admin-url`

---

### 6. (Optional) Destroy the instance when done

```bash
make destroy              # all games
make terraform-destroy-<Game>  # one game
```

---

### 7. See Makefile help for more options

```bash
make help
```

---

## 🛠️ Debugging

| Goal              | Command                                                                    |
|-------------------|----------------------------------------------------------------------------|
| View startup logs | `gcloud compute instances get-serial-port-output <MACHINE_NAME> --zone=us-west1-c` |
| View service logs | `make admin-logs`                                                          |

---

## 📦 Repo Structure

- **General Documentation** (`/docs`)
    - Setup and usage instructions
    - [`docs/design.md`](docs/design.md) — design philosophy and mental models
    - [`docs/architecture.md`](docs/architecture.md) — full system architecture reference
    - [`docs/known-issues.md`](docs/known-issues.md) — known bugs and gaps
    - [`docs/admin/using_admin.md`](docs/admin/using_admin.md) — admin panel usage guide

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

- **Barotrauma State & Mods** (`/Barotrauma`)
    - Contains saved games, mod files, and game server config

- **VRising State & Mods** (`/VRising`)
    - Contains saved games and game server config

---

## License

This project is licensed under the [Polyform Small Business License](https://polyformproject.org/licenses/small-business/1.0.0/).

- ✅ Free for personal, educational use
- ❌ Commercial use by larger companies requires a commercial license

If you're a business that would like to use this project, please contact me at [bwinter.sc81@gmail.com].