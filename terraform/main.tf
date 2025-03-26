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
provider "google-beta" {
  # Service account: terraform@europan-world.iam.gserviceaccount.com
  # Keys
  credentials = file("europan-world.json")
  project     = var.project
  region      = var.region
}

// Bucket needs user: terraform@europan-world.iam.gserviceaccount.com
// with: Storage Object Admin
terraform {
  backend "gcs" {
    credentials = "./europan-world.json"
    bucket      = "tf-state-baroboys"
    prefix      = "terraform/state"
  }
}

// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}

// A Single Compute Engine instance
resource "google_compute_instance" "default" {
  provider     = google-beta
  name         = var.machine_name
  machine_type = var.machine_type
  zone         = var.zone

  advanced_machine_features {
    threads_per_core   = 1
    visible_core_count = 2
  }

  metadata_startup_script = file("${path.module}/scripts/setup.sh")

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }
  labels = {
    created_by = "terraform"
  }

  network_interface {
    network = "default"

    access_config {
      // Include this section to give the VM an external ip address
    }
  }
  service_account {
    // Google recommends custom service accounts that have cloud-platform scope and permissions granted via IAM Roles.
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}