# === packer-steam.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-steam" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.base_core_image

  disk_size    = 20
  image_name   = "baroboys-steam-{{timestamp}}"
  image_family = "baroboys-steam"

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-steam"
  }
}

build {
  name = "baroboys-steam-image"
  sources = ["source.googlecompute.baroboys-steam"]

  provisioner "shell" {
    inline = [
      "sudo /root/baroboys/scripts/setup/install/apt_wine.sh",
      "sudo /root/baroboys/scripts/setup/install/apt_steam.sh",
      "sudo apt-get -yq autoremove"
    ]
  }
}