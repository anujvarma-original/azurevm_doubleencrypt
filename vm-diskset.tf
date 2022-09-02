data "azurerm_client_config" "current" {}

resource "azurerm_key_vault" "lvm" {
  name                        = "des-example-keyvault"
  location                    = azurerm_resource_group.rg_des.location
  resource_group_name         = azurerm_resource_group.rg_des.name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  sku_name                    = "premium"
  enabled_for_disk_encryption = true
  soft_delete_enabled         = true
  purge_protection_enabled    = true
}

resource "azurerm_key_vault_key" "lvm" {
  name         = "kv-${var.suffix}-key"
  key_vault_id = azurerm_key_vault.lvm.id
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
    "wrapKey",
  ]
}

resource "azurerm_disk_encryption_set" "os" {
  name                = "os-des"
  resource_group_name = azurerm_resource_group.rg_des.name
  location            = azurerm_resource_group.rg_des.location
  key_vault_key_id    = azurerm_key_vault_key.lvm.id
  encryption_type     = "EncryptionAtRestWithPlatformAndCustomerKeys"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_disk_encryption_set" "data" {
  name                = "data-des"
  resource_group_name = azurerm_resource_group.rg_des.name
  location            = azurerm_resource_group.rg_des.location
  key_vault_key_id    = azurerm_key_vault_key.lvm.id
  encryption_type     = "EncryptionAtRestWithPlatformAndCustomerKeys"

  identity {
    type = "SystemAssigned"
  }
}

resource "azurerm_key_vault_access_policy" "os-disk" {
  key_vault_id = azurerm_key_vault.lvm.id

  tenant_id = azurerm_disk_encryption_set.os.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.os.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "data-disk" {
  key_vault_id = azurerm_key_vault.lvm.id

  tenant_id = azurerm_disk_encryption_set.data.identity.0.tenant_id
  object_id = azurerm_disk_encryption_set.data.identity.0.principal_id

  key_permissions = [
    "Get",
    "WrapKey",
    "UnwrapKey"
  ]
}

resource "azurerm_key_vault_access_policy" "example-user" {
  key_vault_id = azurerm_key_vault.lvm.id

  tenant_id = data.azurerm_client_config.current.tenant_id
  object_id = data.azurerm_client_config.current.object_id

  key_permissions = [
    "get",
    "create",
    "delete"
  ]
}