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

  disk_size = 20
  disk_type = "pd-ssd"

  min_cpu_platform      = "Intel Cascade Lake"
  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image = var.base_core_image

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
    source      = "refresh_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 Cloning Baroboys repo'",
      "/usr/bin/sudo chmod +x /tmp/clone_repo.sh",
      "/usr/bin/sudo /tmp/clone_repo.sh",
      "echo '🔧 Ensure Both Users have Latest Copy of Repo'",
      "/usr/bin/sudo /root/baroboys/scripts/utils/setup_users.sh",
      "echo '🔧 Install Wine'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/wine/apt_wine.sh",
      "echo '🔧 Install Nginx'",
      "/usr/bin/sudo /root/baroboys/scripts/dependencies/nginx/apt_nginx.sh",
      "echo '🔧 Install Steam'",
      "/usr/bin/sudo /root/baroboys/scripts/dependecies/steam/apt_steam.sh",
      # Refreshes & Enables Startup Service (Installs self to ensure refresh and startup also occurs after restart.)
      "echo '🔧 Install vm-startup Service'",
      "/usr/bin/sudo /root/baroboys/scripts/services/vm-startup/setup.sh",
      "echo '🔧 Install vm-shutdown Service'",
      "/usr/bin/sudo /root/baroboys/scripts/services/vm-shutdown/setup.sh",
      "echo '🧹 Running autoremove'",
      "/usr/bin/sudo apt-get -yq autoremove"
    ]
  }
}