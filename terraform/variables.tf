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
  default     = "us-west1-c"
}

variable "project" {
  description = "Project"
  type        = string
  default     = "europan-world"
}

variable "service_account_email" {
  description = "Service Account Email"
  type        = string
  default     = "vm-runtime@europan-world.iam.gserviceaccount.com"
}

variable "machine_name" {
  description = "Machine Name — set per-game in terraform/game/<Game>.tfvars"
  type        = string
}

variable "machine_type" {
  description = "Machine Type"
  type        = string
  default     = "n2-custom-2-6144"
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

variable "core_image" {
  description = "Image used for the base layer"
  type        = string
  default     = "core"
}

variable "admin_image" {
  description = "Image used for the admin layer"
  type        = string
  default     = "admin"
}

variable "game_tags" {
  description = "Network tags for firewall targeting — set per-game in terraform/game/<Game>.tfvars"
  type        = list(string)
}

variable "game_image" {
  description = "Image used for the Game layer — set per-game in terraform/game/<Game>.tfvars.json"
  type        = string
}

# ─────────────────────────────────────────────────────────────────────────────
# Cross-language config — Terraform reads these from the per-game JSON
# tfvars file. The same file is also read by bash (shared/refresh.sh,
# smoke test) to populate the manifest and runtime state, so port lists,
# game name, accent, etc. are declared exactly once per game.
# ─────────────────────────────────────────────────────────────────────────────

variable "game_ports_udp" {
  description = "UDP ports the game binds — opens matching firewall rules"
  type        = list(number)
  default     = []
}

variable "game_ports_tcp" {
  description = "TCP ports the game binds — opens matching firewall rules"
  type        = list(number)
  default     = []
}

# These exist as Terraform variables so JSON tfvars loads cleanly without
# warnings, but they're consumed by bash readers (shared/refresh.sh) and
# don't shape any Terraform resources. Defaults make them optional.

variable "game_name" {
  description = "Display name (e.g. VRising). Used by admin panel via manifest."
  type        = string
  default     = ""
}

variable "process_name" {
  description = "Process name for pgrep/pkill (e.g. VRisingServer.exe)"
  type        = string
  default     = ""
}

variable "uses_wine" {
  description = "Whether the game uses Wine — drives xvfb dependency in manifest"
  type        = bool
  default     = false
}

variable "accent_color" {
  description = "CSS hex color for admin panel branding"
  type        = string
  default     = "#0d6efd"
}

variable "process_ram_mb_min" {
  description = "Minimum process RSS in MB to consider the game 'fully bootstrapped'"
  type        = number
  default     = 200
}

variable "templates" {
  description = "List of [input, output] pairs envsubst'd at boot by shared/post-checkout.sh. Paths are relative to GAME_DIR."
  type        = list(list(string))
  default     = []
}
