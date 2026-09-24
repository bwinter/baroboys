# VM Control Cloud Run Service

The VM-control service is a Cloud Run service that can inspect and start
configured VM instances. It is intentionally separate from the per-game Terraform
workspaces: Terraform creates and destroys VMs, while this service starts existing
stopped instances.

## Setup

`make bootstrap` includes the VM-control bootstrap. It is idempotent and:

- Enables the required Cloud Run, Cloud Build, Artifact Registry, Compute Engine,
  and IAM APIs.
- Creates the `vm-control` runtime service account.
- Creates or updates the project-level `vmController` custom role.
- Grants the service account permission to inspect and start instances.
- Deploys the initial private Cloud Run revision.

The service is publicly reachable for Discord interactions. Every Discord request
must pass Ed25519 signature validation and match the configured guild and control
channel. Manual invocations still use a Google identity token.

## Manual invocation

List configured VM states:

```bash
make vm-control-invoke ACTION=status
```

Start a stopped VM instance:

```bash
make vm-control-invoke ACTION=start INSTANCE=valheim
```

Possible responses include `starting`, `already_running`, `NOT_DEPLOYED`, and
`another_instance_active`. A destroyed VM is reported as not deployed; this service
does not run Terraform.

## Deploying changes

After changing `cloud_run/vm_control/`, deploy a new revision with:

```bash
make vm-control-deploy
```

The deploy script passes the Discord public key and allowed guild/channel pairs from
`scripts/tools/discord/config.sh`. Locations use the format
`guild_id:channel_id;guild_id:channel_id`, allowing one service to support multiple
Discord servers or channels. It also passes `VM_ADMIN_URL`, the human-facing admin
page URL linked in Discord responses. Override this configuration when using a
different DuckDNS hostname or admin endpoint. The public key and admin URL are not
secrets.

The Discord bot token is stored separately from the VM-control service:

```bash
make secret-set-discord-bot-token
```

Register the development commands with the bot token:

```bash
make discord-register-commands
```

The commands are guild-scoped so updates appear immediately. The bot token is
read from Secret Manager and is not passed to Cloud Run.

The initial Discord interface is intentionally single-server: `/status` and
`/start` automatically target the only deployed VM. The underlying VM-control
API remains instance-aware for manual use and future multi-game support.
