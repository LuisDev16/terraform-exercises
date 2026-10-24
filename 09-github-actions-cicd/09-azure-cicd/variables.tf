variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "location" {
  description = "Azure region for the lab."
  type        = string
  default     = "eastus"
}

variable "name_prefix" {
  description = "Prefix for resources; lowercase letters and numbers only."
  type        = string
  default     = "ghatflabterraform"

  validation {
    condition     = can(regex("^[a-z0-9]{3,10}$", var.name_prefix))
    error_message = "name_prefix must contain 3-10 lowercase letters or numbers."
  }
}
