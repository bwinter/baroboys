/**
 * Copyright 2018 Google LLC
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *      http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

// Configure the Google Cloud provider
provider "google" {
  credentials = file("${path.module}/../.secrets/europan-world-terraform-key.json")
  project = var.project
  region  = var.region
}

// Optional: use GCS backend for shared Terraform state
// Requires service account terraform@europan-world.iam.gserviceaccount.com
// with role: Storage Object Admin (for GCS bucket access)
// Commented out to avoid GCS storage costs during local-only use

# terraform {
#   backend "gcs" {
#     credentials = "./europan-world-terraform-key.json"
#     bucket      = "tf-state-baroboys"
#     prefix      = "terraform/state"
#   }
# }

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}

data "google_compute_image" "baroboys_base" {
  family  = var.custom_image_family
  project = var.project
}

// A Single Compute Engine instance
resource "google_compute_instance" "default" {
  provider     = google
  name         = var.machine_name
  machine_type = var.machine_type
  zone         = var.zone
  tags = ["barotrauma-server", "vrising-server"]
  labels = {
    project     = "baroboys"
    environment = "dev"
  }

  advanced_machine_features {
    threads_per_core   = 1
    visible_core_count = 2
  }

  metadata = {
    startup-script   = "systemctl start boot.service"
    shutdown-script  = "systemctl start teardown.service"
  }

  boot_disk {
    initialize_params {
      image = data.google_compute_image.baroboys_base.self_link
    }
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }

  service_account {
    // Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

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
    ports    = ["9876", "9877"]
  }

  direction = "INGRESS"
  priority  = 1000

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["vrising-server"]
}
