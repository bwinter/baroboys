
locals {
  vm_runtime_sa = "serviceAccount:vm-runtime@${var.project}.iam.gserviceaccount.com"
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