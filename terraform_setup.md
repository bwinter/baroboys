(Based on GCP Terraform Tutorial)

Install Google Cloud SDK:
```shell
brew install --cask google-cloud-sdk
```

Set GCP project ID:
```shell
gcloud config set project europan-world
```

Login to GCP:
```shell
gcloud auth login
```

Create Service Account:
```shell
gcloud iam service-accounts create \
    terraform --description="SA \
    for VM provisioning with \
    Terraform"
```

Create Policy Bindings:
```shell
gcloud projects \
    add-iam-policy-binding \
    europan-world \
    --member="serviceAccount:terraform@europan-world.iam.gserviceaccount.com" \
    --role="roles/iam.serviceAccountUser"

gcloud projects \
    add-iam-policy-binding \
    europan-world \
    --member="serviceAccount:terraform@europan-world.iam.gserviceaccount.com" \
    --role="roles/compute.admin"

gcloud projects \
    add-iam-policy-binding \
    europan-world \
    --member="serviceAccount:terraform@europan-world.iam.gserviceaccount.com" \
    --role="roles/osconfig.guestPolicyAdmin"
```

Create Key File:
```shell
gcloud iam service-accounts keys \
    create test-key.json \
    --iam-account=terraform@europan-world.iam.gserviceaccount.com
```

Download the configuration script to activate services and set permissions:
```shell
curl -O \
    https://cloud.google.com/stackdriver/docs/set-permissions.sh
```

Run script:
```shell
chmod +x set-permissions.sh

./set-permissions.sh \
    --project=europan-world
```