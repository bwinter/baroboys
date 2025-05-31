/**
 * Baroboys Terraform Config – GCP VM + Firewall + Cleanup Hardened
 * Author: Brendan / ChatGPT assisted
 */

# Uncomment if remote state desired.
# terraform {
#   backend "gcs" {
#     credentials = "./europan-world-terraform-key.json"
#     bucket      = "tf-state-baroboys"
#     prefix      = "terraform/state"
#   }
# }

// ─────────────────────────────────────────────────────────────────────────────
// 🔐 Provider & Project Setup
// ─────────────────────────────────────────────────────────────────────────────

provider "google" {
  credentials = file("${path.module}/../.secrets/europan-world-terraform-key.json")
  project = var.project
  region  = var.region
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔑 Random ID (if needed)
// ─────────────────────────────────────────────────────────────────────────────

resource "random_id" "instance_id" {
  byte_length = 8
}

// ─────────────────────────────────────────────────────────────────────────────
// 📦 Image Source (from Packer build)
// ─────────────────────────────────────────────────────────────────────────────

data "google_compute_image" "base_steam_image" {
  family  = var.base_steam_image
  project = var.project
}

// ─────────────────────────────────────────────────────────────────────────────
// 🖥️ Compute Engine VM
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_instance" "default" {
  provider     = google
  name         = var.machine_name
  machine_type = var.machine_type
  zone         = var.zone

  tags = [
    "barotrauma-server",
    "vrising-server",
    "nginx-server"
  ]

  labels = {
    project     = "baroboys"
    environment = "dev"
  }

  metadata = {
    startup-script  = "/usr/bin/bash /root/baroboys/scripts/setup/startup.sh"
    shutdown-script = "/usr/bin/bash /root/baroboys/scripts/teardown/shutdown.sh"
  }

  boot_disk {
    auto_delete = true  // ✅ ensures boot disk is deleted when VM is destroyed
    initialize_params {
      image = data.google_compute_image.base_steam_image.self_link
    }
  }

  network_interface {
    network = "default"
    access_config {}
    // Ephemeral external IP
  }

  service_account {
    email = var.service_account_email
    scopes = ["cloud-platform"]
  }

  lifecycle {
    prevent_destroy = false
    ignore_changes = [metadata["startup-script"], metadata["shutdown-script"]]
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 Firewall Rules – Barotrauma
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_firewall" "barotrauma_ports" {
  name    = "barotrauma-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["27015", "27016"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["barotrauma-server"]
}

resource "google_compute_firewall" "barotrauma_ports_udp" {
  name    = "barotrauma-ports-udp"
  network = "default"

  allow {
    protocol = "udp"
    ports = ["27015", "27016"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["barotrauma-server"]
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔥 Firewall Rules – V Rising
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_firewall" "vrising_ports" {
  name    = "vrising-ports"
  network = "default"

  allow {
    protocol = "tcp"
    ports = ["9876", "9877"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["vrising-server"]
}

resource "google_compute_firewall" "vrising_ports_udp" {
  name    = "vrising-ports-udp"
  network = "default"

  allow {
    protocol = "udp"
    ports = ["9876", "9877"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["vrising-server"]
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌐 Firewall – Nginx Logs Port (8080)
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_firewall" "nginx_logs" {
  name        = "nginx-logs"
  network     = "default"
  description = "Allow HTTP access to exposed Nginx logs on port 8080"

  allow {
    protocol = "tcp"
    ports = ["8080"]
  }

  direction = "INGRESS"
  priority  = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags = ["nginx-server"]
}
