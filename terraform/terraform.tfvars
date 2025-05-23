project               = "europan-world"
credentials_file      = ".secrets/europan-world-terraform-key.json"
service_account_email = "vm-runtime@europan-world.iam.gserviceaccount.com"
region                = "us-west1"
zone                  = "us-west1-b"
machine_type          = "e2-medium"
machine_name          = "europa"
gcp_image_family      = "debian-12"
gcp_image_project     = "debian-cloud"
custom_image_family   = "baroboys-base"