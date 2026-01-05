# 🔐 GCP Service Account (SA)

This project uses this service account:

| Service Account  | Purpose                                                                    |
|------------------|----------------------------------------------------------------------------|
| `vm-runtime@...` | VM uses this to clone repo, update server passwords, and send logs/metrics |

---

Creates `vm-runtime@...` and assigns roles needed for VM runtime operations.

Bootstrap script assigns:

* `roles/logging.logWriter`
* `roles/monitoring.metricWriter`
* `roles/secretmanager.secretAccessor`

---

## 🧠 Notes

* Bootstrap scripts are **idempotent** — safe to re-run
* SA has minimal runtime permissions