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

  tags = concat(var.game_tags, ["admin"])

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
// 🔥 Firewall Rules
//
// Game ports come from the per-game tfvars.json (game_ports_udp/tcp).
// Single source of truth: same file feeds Terraform here AND bash readers
// (shared/refresh.sh, smoke test). Each workspace owns its own firewall
// rules; per-workspace names + count guards prevent collisions when both
// workspaces are deployed.
// ─────────────────────────────────────────────────────────────────────────────

resource "google_compute_firewall" "game_ports_tcp" {
  count   = length(var.game_ports_tcp) > 0 ? 1 : 0
  name    = "${var.machine_name}-ports-tcp"
  network = "default"

  allow {
    protocol = "tcp"
    ports    = [for p in var.game_ports_tcp : tostring(p)]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.game_tags
}

resource "google_compute_firewall" "game_ports_udp" {
  count   = length(var.game_ports_udp) > 0 ? 1 : 0
  name    = "${var.machine_name}-ports-udp"
  network = "default"

  allow {
    protocol = "udp"
    ports    = [for p in var.game_ports_udp : tostring(p)]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = var.game_tags
}

// Admin server firewall is shared in concept (port 8080 reaches whichever
// game's VM is up) but per-workspace in implementation: each workspace
// creates its own admin-server-${workspace} firewall targeting the "admin"
// tag, which both games' VMs carry. Workspace-scoped names avoid the
// "resource already exists" conflict that a single shared name would cause.
resource "google_compute_firewall" "admin_server" {
  name        = "admin-server-${terraform.workspace}"
  network     = "default"
  description = "Allow HTTP access to exposed Admin server on port 8080"

  allow {
    protocol = "tcp"
    ports    = ["8080"]
  }

  direction     = "INGRESS"
  priority      = 1000
  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["admin"]
}
