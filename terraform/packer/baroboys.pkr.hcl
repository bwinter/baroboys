# baroboys.pkr.hcl

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

  image_labels = {
    source = "packer"
    role   = "baroboys-base"
  }
}

build {
  name = "baroboys-base-image"
  sources = ["source.googlecompute.baroboys-base"]

  provisioner "file" {
    source      = "${path.root}/../../scripts/setup/clone_repo.sh"
    destination = "/tmp/clone_repo.sh"
  }

  provisioner "shell" {
    environment_vars = [
      "DEBIAN_FRONTEND=noninteractive",
      "WINETRICKS_GUI=none",
      "WINEDEBUG=-all"
    ]
    inline = [
      "sudo apt-get install -yq git",
      "sudo chmod +x /tmp/clone_repo.sh",
      "sudo /tmp/clone_repo.sh",
      "sudo /root/baroboys/scripts/setup/bootstrap.sh",

      "sudo cp /root/baroboys/scripts/systemd/bootstrap.service /etc/systemd/system/bootstrap.service",
      "sudo cp /root/baroboys/scripts/systemd/teardown.service /etc/systemd/system/teardown.service",
      "sudo chmod 644 /etc/systemd/system/bootstrap.service",
      "sudo chmod 644 /etc/systemd/system/teardown.service",
      "sudo systemctl daemon-reexec",
      "sudo systemctl daemon-reload"
    ]
  }
}
