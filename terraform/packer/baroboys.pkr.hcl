# baroboys.pkr.hcl

source "googlecompute" "baroboys-base" {
  project_id   = var.project
  zone         = var.zone
  machine_type = var.machine_type

  source_image_family  = var.image_family
  source_image_project = var.image_project

  disk_size  = 20
  image_name = "baroboys-base-{{timestamp}}"

  ssh_username = "packer"
}

build {
  name = "baroboys-base-image"
  sources = ["source.googlecompute.baroboys-base"]
  labels = {
    source = "packer"
    role   = "baroboys-base"
  }

  provisioner "file" {
    source      = "${path.root}/../../scripts/systemd/bootstrap.service"
    destination = "/etc/systemd/system/bootstrap.service"
  }

  provisioner "file" {
    source      = "${path.root}/../../scripts/systemd/teardown.service"
    destination = "/etc/systemd/system/teardown.service"
  }

  provisioner "file" {
    source      = "${path.root}/../../"
    destination = "/root/baroboys"
  }

  provisioner "shell" {
    inline = [
      "chmod 644 /etc/systemd/system/bootstrap.service",
      "chmod 644 /etc/systemd/system/teardown.service",
      "systemctl daemon-reload"
    ]
  }
}
