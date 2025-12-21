# === packer-barotrauma.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-barotrauma" {
  account_file = var.credentials_file

  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.admin_image
  source_image_project_id = [var.project]

  image_name   = var.game_image
  image_family = var.game_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-barotrauma"
  }
}

build {
  name = "baroboys-barotrauma-image"
  sources = ["source.googlecompute.baroboys-barotrauma"]

  provisioner "file" {
    source      = "refresh_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 Cloning Baroboys repo'",
      "/usr/bin/sudo chmod +x /tmp/clone_repo.sh",
      "/usr/bin/sudo /tmp/clone_repo.sh",

      "echo '🔧 Ensure both users have latest copy of repo'",
      "/usr/bin/sudo /root/baroboys/scripts/services/refresh_repo/setup.sh",
      "/usr/bin/sudo /root/baroboys/scripts/services/refresh_repo/startup.sh",

      "echo '🔧 Install Barotrauma'",
      "/usr/bin/sudo /root/baroboys/scripts/services/barotrauma/setup.sh",

      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}