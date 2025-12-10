# 🔐 GCP Service Account (SA) Bootstrap Guide

This project uses two service accounts:

| Service Account  | Purpose                                            |
|------------------|----------------------------------------------------|
| `terraform@...`  | Provisions infrastructure via Terraform            |
| `vm-runtime@...` | Runs inside VM to fetch secrets, send logs/metrics |

---

## ✅ One-Time Setup

Ensure you are authenticated as a project owner:

```bash
gcloud auth login
gcloud config set project europan-world
````

Then run the following bootstrap script:
```bash
make iam-boostrap
```

---

## Results:

### 1. Bootstrap Terraform Service Account

Creates `terraform@...` and assigns roles needed for infrastructure provisioning.

This script assigns:

* `roles/compute.admin`
* `roles/iam.serviceAccountUser`
* `roles/iam.serviceAccountAdmin`
* `roles/resourcemanager.projectIamAdmin`

---

### 2. Bootstrap VM Runtime Service Account

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

---

## 🚀 Activate Service Accounts

Activate the Terraform SA:

```bash
gcloud auth activate-service-account terraform@europan-world.iam.gserviceaccount.com \
  --key-file=.secrets/europan-world-terraform-key.json

gcloud config set account terraform@europan-world.iam.gserviceaccount.com
```