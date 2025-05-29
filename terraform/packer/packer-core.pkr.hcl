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
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image_family      = var.gcp_image_family
  source_image_project_id  = [var.gcp_image_project]

  disk_size    = 20
  image_name   = var.base_core_image
  image_family = var.base_core_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-core"
  }
}

build {
  name    = "baroboys-core-image"
  sources = ["source.googlecompute.baroboys-core"]

  provisioner "file" {
    source      = "clone_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 Updating APT and installing Git'",
      "sudo apt-get update",
      "sudo apt-get install -yq git",
      "echo '🔧 Cloning Baroboys repo'",
      "sudo chmod +x /tmp/clone_repo.sh",
      "sudo /tmp/clone_repo.sh",
      "echo '🔧 Running apt_core.sh'",
      "sudo /root/baroboys/scripts/setup/install/apt_core.sh",
      "echo '🔧 Running apt_gcloud.sh'",
      "sudo /root/baroboys/scripts/setup/install/apt_gcloud.sh",
      "echo '🧹 Running autoremove'",
      "sudo apt-get -yq autoremove"
    ]
  }
}