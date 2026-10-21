resource "azurerm_resource_group" "lab" {
  name     = "rg-gha-tf-azure-lab"
  location = var.location

  tags = {
    environment = "lab"
    managed_by  = "terraform"
  }
}

resource "azurerm_storage_account" "lab" {
  name                            = "ghatfazurelab01"
  resource_group_name             = azurerm_resource_group.lab.name
  location                        = azurerm_resource_group.lab.location
  account_tier                    = "Standard"
  account_replication_type        = "LRS"
  min_tls_version                 = "TLS1_2"
  https_traffic_only_enabled      = true
  allow_nested_items_to_be_public = false

  tags = azurerm_resource_group.lab.tags
}
