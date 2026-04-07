# Cold Boot — From Zero to Running Game Server

This doc covers everything needed to go from an empty machine to a running game server.
For the quick version, see the [README Step-by-Step](../../README.md#-step-by-step-setup).

---

## Prerequisites

Install these before starting. Order doesn't matter.

| Tool | Install | Needed for |
|------|---------|-----------|
| gcloud CLI | `brew install --cask google-cloud-sdk` ([details](installing-gcloud.md)) | All GCP operations |
| Terraform | `brew install hashicorp/tap/terraform` | VM provisioning |
| Packer | `brew install hashicorp/tap/packer` | Image building |
| gh CLI | `brew install gh` | Deploy key creation |
| direnv | `brew install direnv` | Environment variables (`.envrc`) |

After installing, authenticate:

```bash
gcloud auth login
gcloud auth application-default login
gcloud config set project europan-world
gh auth login
```

---

## Steps (in order)

### 1. Clone the repo

```bash
git clone git@github.com:<YOUR_USER>/<YOUR_FORK>.git
cd <YOUR_FORK>
direnv allow   # loads .envrc
```

### 2. Bootstrap GCP infrastructure

Creates the Terraform state bucket and the `vm-runtime` service account with IAM roles.

```bash
make bootstrap
```

**If this fails:** Check `gcloud auth list` — you need project-owner permissions.
See [gcp-service-accounts.md](gcp-service-accounts.md) for what gets created.

### 3. Create secrets

Two secrets are needed. Both are created idempotently (safe to re-run).

```bash
make set-password      # server password (game join, admin panel, RCON)
make set-deploy-key    # SSH key for VM to clone/push this repo
```

`set-deploy-key` generates an ECDSA key, adds it to GitHub as a deploy key (write access),
and stores the private key in Secret Manager. Requires `gh` CLI.

**If `set-deploy-key` fails:** Check `gh auth status`. The deploy key can also be created
manually — see [github-deploy-key.md](github-deploy-key.md).

### 4. Build Packer images

Images are built in layers. `make build` handles the full chain:

```bash
make build
```

This takes 10-15 minutes. Layer order: `debian-12 → core → admin → <game>`.

**If a game layer fails:** The base layers are cached. Re-run `make build-game-VRising`
(or the specific game) without rebuilding everything.

### 5. Deploy a game

```bash
make terraform-apply-VRising    # or Barotrauma
```

This creates a VM in the `vrising` (or `barotrauma`) Terraform workspace. Each game
gets independent state — deploying one doesn't affect the other.

The VM boots, pulls the latest repo, and starts the game automatically (~3-5 min).

### 6. Connect

- **Game:** Connect using the server's external IP and the password from step 3
- **Admin panel:** `http://<VM-IP>:8080/` — username `Hex`, password from step 3
- **SSH:** `make ssh-VRising`

### 7. Shut down

The VM auto-shuts down after 30 minutes of CPU idle. To shut down manually:

```bash
make save-and-shutdown-VRising   # graceful: save → git push → poweroff
```

To destroy the VM entirely (lowest cost):

```bash
make terraform-destroy-VRising   # or: make destroy (all games)
```

---

## What's happening under the hood

- `make bootstrap` → `bootstrap/bootstrap_tf_state_bucket.sh` + `bootstrap/bootstrap_vm_runtime_sa.sh`
- `make set-password` → `scripts/tools/set_secret.sh`
- `make set-deploy-key` → `scripts/tools/set_deploy_key.sh`
- `make build` → `packer/build.sh` (layered images, shares vars with Terraform)
- `make terraform-apply-<Game>` → `terraform/build.sh` (workspace select + apply)

See [architecture.md](../architecture.md) for the full system reference.
