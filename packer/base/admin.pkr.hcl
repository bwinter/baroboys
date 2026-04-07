# === packer-admin.pkr.hcl ===

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "admin" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.core_image
  source_image_project_id = [var.project]

  image_name   = var.admin_image
  image_family = var.admin_image

  ssh_username = "packer"

  image_labels = {
    role = "admin"
  }
}

build {
  name = "admin-image"
  sources = ["source.googlecompute.admin"]

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

      "echo '🔧 Install Nginx'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/nginx/apt_nginx.sh",

      "echo '🔧 Install Steam'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/steam/apt_steam.sh",

      "echo '🔧 Install Admin Server'",
      "/usr/bin/sudo /root/baroboys/scripts/services/admin_server/setup.sh",

      "echo '🔧 Install idle check service'",
      "/usr/bin/sudo /root/baroboys/scripts/services/idle_check/setup.sh",

      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}