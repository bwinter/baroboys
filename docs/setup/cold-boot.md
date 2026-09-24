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

Creates the Terraform state bucket, the `vm-runtime` service account with IAM roles,
the save-backup bucket with lifecycle rules, and the shared regional static IP used by
all game VMs.

```bash
make bootstrap
```

This also bootstraps and deploys the public, signature-protected Cloud Run VM-control service used to
start existing stopped game VMs. See [vm-control.md](vm-control.md) for manual
invocation and maintenance.

Note: Only one game VM can use the shared address at a time. Destroy or detach the current
game VM before applying a different game workspace. The address remains stable across
VM stop/start, recreation, and zone changes.

**If this fails:** Check `gcloud auth list` — you need project-owner permissions.
See [gcp-service-accounts.md](gcp-service-accounts.md) for what gets created.

### 3. Create secrets

Three secrets are needed. Each setter is safe to re-run.

```bash
make secret-set-password      # server password (game join, admin panel, RCON)
make secret-set-deploy-key    # SSH key for VM to clone/push this repo
make secret-set-duckdns-token # DuckDNS token for baroboys.duckdns.org
```

`secret-set-deploy-key` generates an ECDSA key, adds it to GitHub as a deploy key (write access),
and stores the private key in Secret Manager. Requires `gh` CLI.

**If `secret-set-deploy-key` fails:** Check `gh auth status`. The deploy key can also be created
manually — see [github-deploy-key.md](github-deploy-key.md).

The DuckDNS token comes from the [DuckDNS account page](https://www.duckdns.org/login?generateRequest=persona).
The local Terraform apply workflow will update `baroboys.duckdns.org` after applying
the VM's static IP. The static IP remains the primary endpoint; DuckDNS provides a
recoverable hostname if the address ever changes.

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

- **Game:** Connect using the shared static IP printed by `make bootstrap` or the `make terraform-apply-<GAME>` commands and the password from step 3
- **Admin panel:** `http://<STATIC-IP>:8080/` — username `Hex`, password from step 3
- **SSH:** `make game-ssh-VRising`

### 7. Shut down

The VM auto-shuts down after 30 minutes of CPU idle. To shut down manually:

```bash
make game-shutdown-VRising       # graceful: save → git push → poweroff
```

To destroy the VM entirely (lowest cost):

```bash
make terraform-destroy-VRising   # or: make destroy (all games)
```

---

## What's happening under the hood

- `make bootstrap` → Terraform state bucket + runtime IAM + save-backup bucket + Static IP + VM control
- `make secret-set-password` → `scripts/tools/set_secret.sh`
- `make secret-set-deploy-key` → `scripts/tools/set_deploy_key.sh`
- `make secret-set-duckdns-token` → `scripts/tools/duckdns/set_duckdns_token.sh`
- `make build` → `packer/build.sh` (layered images, shares vars with Terraform)
- `make terraform-apply-<Game>` → `terraform/build.sh` (workspace select + apply)

See [architecture.md](../architecture.md) for the full system reference.
