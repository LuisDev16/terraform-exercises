variable "project_id" {
  description = "Google Cloud project ID."
  type        = string
}

variable "region" {
  description = "Default region for the lab."
  type        = string
  default     = "us-central1"
}

variable "bucket_prefix" {
  description = "Bucket prefix: lowercase letters, numbers, or hyphens."
  type        = string
  default     = "gha-terraform-lab"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{2,25}$", var.bucket_prefix))
    error_message = "bucket_prefix must be 3-26 lowercase letters, numbers, or hyphens."
  }
}
