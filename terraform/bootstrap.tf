# Enable required APIs
resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
}

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"
}

resource "google_project_service" "osconfig" {
  service = "osconfig.googleapis.com"
}

# Project-wide metadata to enable guest policies
resource "google_compute_project_metadata" "osconfig_metadata" {
  metadata = {
    enable-guest-attributes = "TRUE"
    enable-osconfig         = "TRUE"
  }
}

# Grant logging and monitoring roles to your custom SA
resource "google_project_iam_member" "log_writer" {
  project = var.project
  role   = "roles/logging.logWriter"
  member = "serviceAccount:${var.service_account_email}"
}

resource "google_project_iam_member" "metric_writer" {
  project = var.project
  role   = "roles/monitoring.metricWriter"
  member = "serviceAccount:${var.service_account_email}"
}

# (Optional) Grant guest policy admin permissions to your SA
resource "google_project_iam_member" "guest_policy_admin" {
  project = var.project
  role   = "roles/osconfig.guestPolicyAdmin"
  member = "serviceAccount:${var.service_account_email}"
}
