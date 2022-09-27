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
  credentials = file("europan-world-6c508b9a66f6.json")
  project     = var.project
  region      = var.region
}

terraform {
  backend "gcs" {
    credentials = "./europan-world-6c508b9a66f6.json"
    bucket = "tf-state-baroboys"
    prefix = "terraform/state"
  }
}


// Terraform plugin for creating random ids
resource "random_id" "instance_id" {
  byte_length = 8
}


// A Single Compute Engine instance
resource "google_compute_instance" "default" {
  name         = var.machine_name
  machine_type = var.machine_type
  zone         = var.zone

  metadata_startup_script = file("${path.module}/startup.sh")

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
    // This non production example uses the default compute service account.
    email  = var.service_account_email
    scopes = ["cloud-platform"]
  }
}

// Cloud Ops Agent Policy
//module "agent_policy" {
//  source  = "terraform-google-modules/cloud-operations/google//modules/agent-policy"
//  version = "~> 0.1.0"
//
//  project_id = var.project
//  policy_id  = "ops-agents-example-policy"
//  agent_rules = [
//    {
//      type               = "ops-agent"
//      version            = "current-major"
//      package_state      = "installed"
//      enable_autoupgrade = true
//    },
//  ]
//  group_labels = [
//    {
//      created_by = "terraform"
//    }
//  ]
//
//  os_types = [
//    {
//      short_name = "debian"
//      version    = "11"
//    },
//  ]
//}
