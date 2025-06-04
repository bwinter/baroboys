resource "google_service_account" "vm_runtime" {
  account_id   = "vm-runtime"
  display_name = "VM Runtime Service Account"
  project      = var.project
}

locals {
  vm_runtime_sa = "serviceAccount:${google_service_account.vm_runtime.email}"
}

resource "google_project_iam_member" "vm_runtime_log_writer" {
  project = var.project
  role    = "roles/logging.logWriter"
  member  = local.vm_runtime_sa
}

resource "google_project_iam_member" "vm_runtime_monitoring_writer" {
  project = var.project
  role    = "roles/monitoring.metricWriter"
  member  = local.vm_runtime_sa
}

resource "google_project_iam_member" "vm_runtime_guest_policy_admin" {
  project = var.project
  role    = "roles/osconfig.guestPolicyAdmin"
  member  = local.vm_runtime_sa
}

resource "google_project_iam_member" "vm_runtime_secret_accessor" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = local.vm_runtime_sa
}

resource "google_secret_manager_secret_iam_member" "vm_runtime_github_deploy_access" {
  project   = var.project
  secret_id = "github-deploy-key"

  role   = "roles/secretmanager.secretAccessor"
  member = local.vm_runtime_sa
}
