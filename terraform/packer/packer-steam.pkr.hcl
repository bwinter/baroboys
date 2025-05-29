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
  image_name   = var.base_steam_image
  image_family = var.base_steam_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-steam"
  }
}

build {
  name = "baroboys-steam-image"
  sources = ["source.googlecompute.baroboys-steam"]

  provisioner "file" {
    source      = "clone_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 Cloning Baroboys repo'",
      "sudo chmod +x /tmp/clone_repo.sh",
      "sudo /tmp/clone_repo.sh",
      "echo '🔧 Running apt_wine.sh'",
      "sudo /root/baroboys/scripts/setup/install/apt_wine.sh",
      "echo '🔧 Running apt_steam.sh'",
      "sudo /root/baroboys/scripts/setup/install/apt_steam.sh",
      "echo '🧹 Running autoremove'",
      "sudo apt-get -yq autoremove"
    ]
  }
}