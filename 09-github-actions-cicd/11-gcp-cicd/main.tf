resource "google_storage_bucket" "lab" {
  name                        = "${var.bucket_prefix}-${var.project_id}"
  project                     = var.project_id
  location                    = upper(var.region)
  uniform_bucket_level_access = true
  public_access_prevention    = "enforced"
  force_destroy               = false

  versioning {
    enabled = true
  }

  labels = {
    purpose    = "github-actions-terraform-lab"
    managed_by = "terraform"
  }
}
