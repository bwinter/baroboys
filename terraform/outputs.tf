output "google_caller_identity" {
  value = data.google_client_openid_userinfo.me.email
}

data "google_client_openid_userinfo" "me" {}

output "admin_server_url" {
  description = "Direct link to the Admin page."
  value       = "http://${google_compute_instance.default.network_interface[0].access_config[0].nat_ip}:8080/"
}
