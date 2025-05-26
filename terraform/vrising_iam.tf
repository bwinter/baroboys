# List of users allowed to administer VMs
variable "vrising_operators" {
  type    = list(string)
  default = [
    "nilsen.j.k@gmail.com"
  ]
}

# Grant the custom role to each user
resource "google_project_iam_binding" "vrising_operator_binding" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"

  members = [
    for user in var.vrising_operators : "user:${user}"
  ]
}
