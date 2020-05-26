provider "azurerm" {
  version = "=2.11"
  features {}
}

variable "KV" {} #This will pull in value from TF_VAR_KV set in environment variable

data "azurerm_key_vault_secret" "SamplePassword" {
  name = "SamplePassword"
  key_vault_id = "${var.KV}"
}

output "A_Secret_From_KeyVault_Shhhhh" {
    value = data.azurerm_key_vault_secret.SamplePassword.value
}