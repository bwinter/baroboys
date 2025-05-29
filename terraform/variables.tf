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

variable "region" {
  description = "region"
  type        = string
  default     = "us-west1"
}

variable "zone" {
  description = "Zone"
  type        = string
  default     = "us-west1-b"
}

variable "project" {
  description = "Project"
  type        = string
  default     = "europan-world"
}

variable "credentials_file" {
  description = "Credentials file"
  type        = string
  default     = ".secrets/europan-world-terraform-key.jsonn"
}

variable "service_account_email" {
  description = "Service Account Email"
  type        = string
  default     = "vm-runtime@europan-world.iam.gserviceaccount.com"
}

variable "machine_name" {
  description = "Machine Name"
  type        = string
  default     = "europa"
}

variable "machine_type" {
  description = "Machine Type"
  type        = string
  default     = "e2-standard-2"
}

variable "gcp_image_family" {
  description = "Image Family"
  type        = string
  default     = "debian-12"
}

variable "gcp_image_project" {
  description = "Image Project"
  type        = string
  default     = "debian-cloud"
}

variable "base_core_image" {
  description = "Core image used for the Steam layer"
  type        = string
  default     = "baroboys-core"
}

variable "base_steam_image" {
  description = "Steam image used for the Game layer"
  type        = string
  default     = "baroboys-steam"
}

variable "base_game_image" {
  description = "Game image used for Terraform VM provisioning"
  type        = string
  default     = "baroboys-game"
}
