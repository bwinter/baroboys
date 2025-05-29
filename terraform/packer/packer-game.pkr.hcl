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

  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.base_steam_image

  disk_size    = 20
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

  provisioner "shell" {
    inline = [
      "echo '🔧 Running repositories.sh'",
      "sudo /root/baroboys/scripts/setup/install/repositories.sh",
      "echo '🔧 Running services.sh'",
      "sudo /root/baroboys/scripts/setup/install/services.sh",
      "echo '🔧 Running apt_nginx.sh'",
      "sudo /root/baroboys/scripts/setup/install/apt_nginx.sh",
      "echo '🧹 Running autoremove'",
      "sudo apt-get -yq autoremove"
    ]
  }
}
