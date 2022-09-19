data "azurerm_client_config" "current" {}

#AV - ensure provider version 3.3.0 or above - else, this resource fails on cryptic GetCertificateContacts error 
resource "azurerm_key_vault" "wvm" {
  name                = "des-kv-windws01"
  location            = azurerm_resource_group.rg_des_win.location
  resource_group_name = azurerm_resource_group.rg_des_win.name
  tenant_id           = data.azurerm_client_config.current.tenant_id
  sku_name            = "standard"
  #sku_name                    = "premium"
  enabled_for_disk_encryption = true
  #soft_delete_enabled         = true
  purge_protection_enabled = true
}

resource "azurerm_key_vault_key" "wvm" {
  name         = "kv-${var.suffix}-key01"
  key_vault_id = azurerm_key_vault.wvm.id
  key_type     = "RSA"
  key_size     = 2048

  depends_on = [
    azurerm_key_vault_access_policy.example-user
  ]

 key_opts = [
    "decrypt",
    "encrypt",
    "sign",
    "unwrapKey",
    "verify",
    "wrapKey"
  ]
}

resource "azurerm_disk_encryption_set" "os" {
  name                = "os-des01"
  resource_group_name = azurerm_resource_group.rg_des_win.name
  location            = azurerm_resource_group.rg_des_win.location
  key_vault_key_id    = azurerm_key_vault_key.wvm.id
  encryption_type     = "EncryptionAtRestWithPlatformAndCustomerKeys"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_disk_encryption_set" "data" {
  name                = "data-des01"
  resource_group_name = azurerm_resource_group.rg_des_win.name
  location            = azurerm_resource_group.rg_des_win.location
  key_vault_key_id    = azurerm_key_vault_key.wvm.id
  encryption_type     = "EncryptionAtRestWithPlatformAndCustomerKeys"

  identity {
    type = "SystemAssigned"
  }

}

resource "azurerm_key_vault_access_policy" "os-disk" {
  key_vault_id = azurerm_key_vault.wvm.id

  tenant_id = azurerm_disk_encryption_set.os.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.os.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "data-disk" {
  key_vault_id = azurerm_key_vault.wvm.id

  tenant_id = azurerm_disk_encryption_set.data.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.data.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

# #AV - diff route to get current user object id
# data external account_info {
#   program                      = [
#                                  "az",
#                                  "ad",
#                                  "signed-in-user",
#                                  "show",
#                                  "--query",
#                                  "{object_id:id}",
#                                  "-o",
#                                  "json",
#                                  ]
# }

resource "azurerm_key_vault_access_policy" "example-user" {

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id
  #AV - diff route to get current user object id
  # object_id = data.external.account_info.result.object_id

  key_vault_id = azurerm_key_vault.wvm.id

  key_permissions = [
    "Get",
    "Create",
    "Delete"
  ]
}
