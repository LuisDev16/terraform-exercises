variable "aws_region" {
  description = "AWS region for the lab."
  type        = string
  default     = "us-east-1"
}

variable "name_prefix" {
  description = "Lowercase bucket prefix (3-20 chars)."
  type        = string
  default     = "gha-tf-lab"

  validation {
    condition     = can(regex("^[a-z0-9-]{3,20}$", var.name_prefix))
    error_message = "name_prefix must be 3-20 lowercase letters, numbers, or hyphens."
  }
}
