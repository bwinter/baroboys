# === packer-game.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-game" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.base_core_image

  image_name   = var.base_game_image
  image_family = var.base_game_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-game"
  }
}

build {
  name = "baroboys-game-image"
  sources = ["source.googlecompute.baroboys-game"]

  # provisioner "file" {
  #   source      = "refresh_repo.sh"
  #   destination = "/tmp/clone_repo.sh"
  # }

  provisioner "shell" {
    inline = [
      "echo '🔧 Build an image with latest version of game.'",
      "/usr/bin/sudo systemd start --wait vm-startup",
      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}