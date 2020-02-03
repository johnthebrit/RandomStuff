data "azurerm_resource_group" "ResGroup" {
  name = "RG-SCUSTFStorage"
}

resource "azurerm_storage_account" "StorAccount" {
  name                     = "savtechtfstorage2020"
  resource_group_name      = data.azurerm_resource_group.ResGroup.name
  location                 = data.azurerm_resource_group.ResGroup.location
  account_tier             = "Standard"
  account_replication_type = var.replicationType
}

resource "azurerm_storage_container" "ContName" {
  name                  = "images"
  storage_account_name  = azurerm_storage_account.StorAccount.name
  container_access_type = "private"
}