# List of users allowed to administer VMs
variable "baroboys_operators" {
  type = list(string)
  default = [
    "nilsen.j.k@gmail.com",
    "demapoppa@gmail.com",
    "menotquilty@gmail.com",
    "vduray@gmail.com"
  ]
}

# Grant the custom role to each user
resource "google_project_iam_binding" "baroboys_operator_binding" {
  project = var.project
  role    = "roles/compute.instanceAdmin.v1"

  members = [
    for user in var.baroboys_operators : "user:${user}"
  ]
}
