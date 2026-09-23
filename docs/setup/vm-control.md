# VM Control Cloud Run Service

The VM-control service is a private Cloud Run service that can inspect and start
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

The service is deployed privately. Local invocations use a Google identity token;
there is no unauthenticated HTTP endpoint.

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

The first version uses IAM-authenticated local requests. A future Discord-facing
layer can call this private service for VM lifecycle commands, keeping game-specific
control in the VM's admin service.
