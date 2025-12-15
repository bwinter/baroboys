# resource "google_service_account" "terraform" {
#   account_id   = "terraform"
#   display_name = "Terraform Service Account"
#   project      = var.project
# }

locals {
  terraform_sa_member = "serviceAccount:terraform@${var.project}.iam.gserviceaccount.com"
}

resource "google_project_iam_member" "terraform_compute_admin" {
  project = var.project
  role    = "roles/compute.admin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_iam_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountUser"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_iam_service_account_user" {
  project = var.project
  role    = "roles/iam.serviceAccountAdmin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_project_iam_admin" {
  project = var.project
  role    = "roles/resourcemanager.projectIamAdmin"
  member  = local.terraform_sa_member
}

resource "google_project_iam_member" "terraform_compute_admin" {
  project = var.project
  role    = "roles/secretmanager.secretAccessor"
  member  = local.terraform_sa_member
}
