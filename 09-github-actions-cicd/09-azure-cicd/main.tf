resource "azurerm_resource_group" "lab" {
  name     = "rg-${var.name_prefix}-${substr(sha1(var.subscription_id), 0, 6)}"
  location = var.location

  tags = {
    purpose    = "github-actions-terraform-lab"
    managed_by = "terraform"
  }
}

resource "azurerm_storage_account" "lab" {
  name                            = "${var.name_prefix}${substr(sha1(var.subscription_id), 0, 8)}"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false
  shared_access_key_enabled       = false

  blob_properties {
    versioning_enabled = true
  }

  tags = azurerm_resource_group.lab.tags
}
