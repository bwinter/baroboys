output "google_caller_identity" {
  value = data.google_client_openid_userinfo.me.email
}

data "google_client_openid_userinfo" "me" {}

output "admin_server_url" {
  description = "Direct link to the Admin page."
  value       = "http://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}:8080/"
}

output "game_external_ip" {
  description = "The external IPv4 address assigned to the game VM."
  value       = google_compute_instance.default.network_interface[0].access_config[0].nat_ip
}

output "terraform_project_id" {
  description = "The GCP project used by this Terraform workspace."
  value       = var.project
}
