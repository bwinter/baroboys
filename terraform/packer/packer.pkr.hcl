# packer.pkr.hcl

packer {
  required_plugins {
    googlecompute = {
      version = ">= 1.1.9"
      source  = "github.com/hashicorp/googlecompute"
    }
  }
}

source "googlecompute" "baroboys-base" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  service_account_email = var.service_account_email
  scopes = ["https://www.googleapis.com/auth/cloud-platform"]

  source_image_family = var.gcp_image_family
  source_image_project_id = [var.gcp_image_project]

  disk_size    = 20
  image_name   = "baroboys-base-{{timestamp}}"
  image_family = var.custom_image_family

  ssh_username = "packer"

  # pause_before_connect = "5m"  # 🟠 Uncomment for manual SSH debugging
}

build {
  name = "baroboys-base-image"
  sources = ["source.googlecompute.baroboys-base"]

  provisioner "file" {
    source      = "clone_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] Installing Git and Cloning Repo...'",
      "sudo apt-get install -yq git",
      "sudo chmod +x /tmp/clone_repo.sh",
      "sudo /tmp/clone_repo.sh",
      "test -d /root/baroboys && echo '✅ Repo cloned' || { echo '❌ Clone failed'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] apt_core.sh...'",
      "sudo /root/baroboys/scripts/setup/install/apt_core.sh",
      "command -v curl >/dev/null && echo '✅ curl found' || { echo '❌ curl missing'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] apt_gcloud.sh...'",
      "sudo /root/baroboys/scripts/setup/install/apt_gcloud.sh",
      "command -v gcloud >/dev/null && echo '✅ gcloud found' || { echo '❌ gcloud missing'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] apt_steam.sh...'",
      "sudo /root/baroboys/scripts/setup/install/apt_steam.sh",
      "command -v steamcmd >/dev/null && echo '✅ steamcmd found' || { echo '❌ steamcmd missing'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] apt_wine.sh...'",
      "sudo /root/baroboys/scripts/setup/install/apt_wine.sh",
      "wine --version && echo '✅ wine installed' || { echo '❌ wine missing'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] apt_nginx.sh...'",
      "sudo /root/baroboys/scripts/setup/install/apt_nginx.sh",
      "test -f /etc/nginx/sites-available/vrising-logs && echo '✅ nginx config installed' || { echo '❌ nginx setup failed'; exit 1; }"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] Re-syncing baroboys repo...'",
      "sudo /root/baroboys/scripts/setup/install/repositories.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🔧 [STEP] Installing systemd services...'",
      "sudo /root/baroboys/scripts/setup/install/services.sh"
    ]
  }

  provisioner "shell" {
    inline = [
      "echo '🧹 [STEP] Cleaning up...'",
      "sudo apt-get -yq autoremove"
    ]
  }
}
