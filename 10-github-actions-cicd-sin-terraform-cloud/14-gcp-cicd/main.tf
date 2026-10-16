resource "google_storage_bucket" "lab" {
  name = "gha-tf-lab-${var.project_id}"
  project = var.project_id
  location = upper(var.region)
  uniform_bucket_level_access = true
  public_access_prevention = "enforced"
  force_destroy = false
  versioning {
    enabled = true
  }
  labels = {
    environment = "lab"
    managed_by = "terraform"
  }
}