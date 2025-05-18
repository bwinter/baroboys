Install Google Cloud SDK:
```shell
brew install --cask google-cloud-sdk
```

Login to GCP:
```shell
gcloud auth login
```

Set GCP project ID:
```shell
gcloud config set project europan-world
```

Create Service Account:
```shell
gcloud iam service-accounts create terraform \
  --description="SA for Terraform provisioning" \
  --display-name="Terraform"
```

Create Policy Bindings:
```shell
gcloud projects add-iam-policy-binding europan-world \
  --member="serviceAccount:terraform@europan-world.iam.gserviceaccount.com" \
  --role="roles/owner"
```
Grant roles/owner for simplicity.


Create Key File:
```shell
gcloud iam service-accounts keys create europan-world.json \
  --iam-account=terraform@europan-world.iam.gserviceaccount.com
```
⚠️ Keep this key secure. It's used by Terraform to authenticate when applying infrastructure. **Do NOT commit it to this repo**