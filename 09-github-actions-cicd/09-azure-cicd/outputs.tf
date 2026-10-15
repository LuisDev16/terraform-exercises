output "resource_group_name" {
  value = azurerm_resource_group.lab.name
}

output "storage_account_name" {
  value = azurerm_storage_account.lab.name
}

output "primary_blob_endpoint" {
  value = azurerm_storage_account.lab.primary_blob_endpoint
}
