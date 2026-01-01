# 🔐 GCP Service Account (SA) Bootstrap Guide

This project uses service accounts:

| Service Account     | Purpose                                                     |
|---------------------|-------------------------------------------------------------|
| `vm-runtime@...`    | Runs inside VM to fetch secrets, send logs/metrics          |

---

## ✅ One-Time Setup

Ensure you are authenticated as a project owner:

```bash
gcloud auth application-default login
gcloud config set project europan-world
````

Then run the following bootstrap script:

```bash
make iam-boostrap
```

---

## Results:

### 1. Bootstrap VM Runtime Service Account

Creates `vm-runtime@...` and assigns roles needed for VM runtime operations.

This script assigns:

* `roles/logging.logWriter`
* `roles/monitoring.metricWriter`
* `roles/secretmanager.secretAccessor`

---

## 🧠 Notes

* These scripts are **idempotent** — safe to re-run
* Each SA is cleanly separated by concern (provisioning vs runtime)
* Keep all generated SA key files in `.gitignore`