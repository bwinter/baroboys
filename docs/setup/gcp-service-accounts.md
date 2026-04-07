# GCP Service Account — Reference

> Created by `make bootstrap` (`bootstrap/bootstrap_vm_runtime_sa.sh`).

## Service Account

| Name | Email | Purpose |
|------|-------|---------|
| `vm-runtime` | `vm-runtime@europan-world.iam.gserviceaccount.com` | VM runtime identity — secrets, logs, metrics |

## IAM Roles

| Role | Purpose |
|------|---------|
| `roles/logging.logWriter` | Ops Agent log forwarding |
| `roles/monitoring.metricWriter` | Ops Agent metrics |
| `roles/secretmanager.secretAccessor` | Read all secrets (server-password, github-deploy-key) |

## APIs Enabled

`compute`, `secretmanager`, `logging`, `monitoring`, `osconfig` — all enabled by the bootstrap script.

## Notes

* Bootstrap is **idempotent** — safe to re-run
* SA has minimal runtime permissions — no write access to secrets, no compute admin
* To grant someone VM start/stop access: `make iam-add-admin`
