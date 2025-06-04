resource "google_service_account" "terraform" {
  account_id   = "terraform"
  display_name = "Terraform Service Account"
  project      = var.project
}

locals {
  terraform_sa_member = "serviceAccount:${google_service_account.terraform.email}"
}

resource "google_project_iam_member" "terraform_compute_admin" {
  project = var.project
  role    = "roles/compute.admin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_compute_security_admin" {
  project = var.project
  role    = "roles/compute.securityAdmin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_iam_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_logging_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_monitoring_metric_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_osconfig_guest_policy_admin" {
  project = var.project
  role    = "roles/osconfig.guestPolicyAdmin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_iam_role_admin" {
  project = var.project
  role    = "roles/iam.roleAdmin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_project_iam_admin" {
  project = var.project
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = local.terraform_sa_member
}
