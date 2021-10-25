variable "gcp_project" {
  type = string
}

provider "google" {
  version = ">= 3.24.0"

  project = var.gcp_project
}
