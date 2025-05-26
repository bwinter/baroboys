output "google_caller_identity" {
  value = data.google_client_openid_userinfo.me.email
}

data "google_client_openid_userinfo" "me" {}
