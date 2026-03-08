/**
 * Baroboys Terraform Config – GCP VM + Firewall + Cleanup Hardened
 * Author: Brendan / ChatGPT assisted
 */

terraform {
  backend "gcs" {}
}

// ─────────────────────────────────────────────────────────────────────────────
// 🔐 Provider & Project Setup
// ─────────────────────────────────────────────────────────────────────────────

provider "google" {
  project     = var.project
  region      = var.region
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

data "google_compute_image" "game_image" {
  family  = var.game_image
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
    "admin-server"
  ]

  labels = {
    project     = "baroboys"
    environment = "dev"
  }

  boot_disk {
    auto_delete = true
    initialize_params {
      image = data.google_compute_image.game_image.self_link
      type  = "pd-ssd" # changed from default
      size  = 20       # minimal but safe
    }
  }

  min_cpu_platform = "Intel Cascade Lake"

  network_interface {
    network = "default"
    access_config {}
    // Ephemeral external IP
  }

  service_account {
    email  = var.service_account_email
    scopes = ["cloud-platform"]
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
    ports    = ["27015", "27016"]
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
    ports    = ["27015", "27016"]
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
    ports    = ["9876", "9877"]
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
    ports    = ["9876", "9877"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["vrising-server"]
}

// ─────────────────────────────────────────────────────────────────────────────
// 🌐 Firewall – Admin Server Port (8080)
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_firewall" "admin_server" {
  name        = "admin-server"
  network     = "default"
  description = "Allow HTTP access to exposed Admin server on port 8080"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["admin-server"]
}
