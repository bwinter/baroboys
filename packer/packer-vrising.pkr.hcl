# === packer-vrising.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-vrising" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.base_admin_image
  source_image_project_id = [var.project]

  image_name   = var.base_vrising_image
  image_family = var.base_vrising_image

  ssh_username = "packer"

  image_labels = {
    role = "baroboys-vrising"
  }
}

build {
  name = "baroboys-vrising-image"
  sources = ["source.googlecompute.baroboys-vrising"]

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
      "/usr/bin/sudo install -m 644 '/root/baroboys/scripts/services/refresh_repo/refresh-repo-setup.service' '/etc/systemd/system/'",
      "/usr/bin/sudo systemctl start --wait refresh-repo-setup.service",
      "/usr/bin/sudo systemctl start --wait refresh-repo-startup.service",

      "echo '🔧 Install Wine'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/wine/apt_wine.sh",

      "echo '🔧 Install latest version of Xvfb'",
      "/usr/bin/sudo install -m 644 '/root/baroboys/scripts/services/xvfb/xvfb-setup.service' '/etc/systemd/system/'",
      "/usr/bin/sudo systemctl start --wait xvfb-setup.service",

      "echo '🔧 Install latest version of V Rising'",
      "/usr/bin/sudo install -m 644 '/root/baroboys/scripts/services/vrising/game-setup.service' '/etc/systemd/system/'",
      "/usr/bin/sudo systemctl start --wait game-setup.service",

      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}