# === packer-core.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-core" {
  credentials_json = file(var.credentials_file)

  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image_family = var.gcp_image_family
  source_image_project_id = [var.gcp_image_project]

  image_name   = var.core_image
  image_family = var.core_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-core"
  }
}

build {
  name = "baroboys-core-image"
  sources = ["source.googlecompute.baroboys-core"]

  provisioner "file" {
    source      = "refresh_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 Updating APT and installing Git'",
      "/usr/bin/sudo apt-get update",
      "/usr/bin/sudo apt-get install -yq git",

      "echo '🔧 Cloning Baroboys repo'",
      "/usr/bin/sudo chmod +x /tmp/clone_repo.sh",
      "/usr/bin/sudo /tmp/clone_repo.sh",

      "echo '🔧 Ensure both users have latest copy of repo'",
      "/usr/bin/sudo /root/baroboys/scripts/services/refresh_repo/setup.sh",
      "/usr/bin/sudo /root/baroboys/scripts/services/refresh_repo/startup.sh",

      "echo '🔧 Update linux'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/apt_core/apt_core.sh",

      "echo '🔧 Update gcloud'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/gcloud/apt_gcloud.sh",

      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}