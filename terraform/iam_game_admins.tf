# Operator capability represented as a service account
resource "google_service_account" "baroboys_operators" {
  account_id   = "baroboys-operators"
  display_name = "Baroboys Operators (Human IAM proxy)"
  project      = var.project
}

# Operator role bound once, canonically
resource "google_project_iam_binding" "baroboys_operator_binding" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"

  members = [
    "serviceAccount:${google_service_account.baroboys_operators.email}"
  ]
}
