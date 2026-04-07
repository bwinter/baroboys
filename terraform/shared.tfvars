# Canonical source for Terraform/Packer variables.
# project/zone/region are mirrored in .envrc for shell/Make — keep in sync.
# machine_name is per-game — see terraform/game/<Game>.tfvars.
project               = "europan-world"
service_account_email = "vm-runtime@europan-world.iam.gserviceaccount.com"
region                = "us-west1"
zone                  = "us-west1-c"
machine_type          = "n2-custom-2-6144"
gcp_image_family      = "debian-12"
gcp_image_project     = "debian-cloud"
core_image            = "core"
admin_image           = "admin"
