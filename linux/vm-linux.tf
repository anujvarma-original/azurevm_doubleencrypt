resource "azurerm_virtual_network" "lvm" {
  name                = "vnet-${var.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_des.location
  resource_group_name = azurerm_resource_group.rg_des.name
}

resource "azurerm_subnet" "lvm" {
  name                 = "snet-${var.suffix}"
  resource_group_name  = azurerm_resource_group.rg_des.name
  virtual_network_name = azurerm_virtual_network.lvm.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "lvm" {
  name                = "${local.vm_name}-nic"
  location            = azurerm_resource_group.rg_des.location
  resource_group_name = azurerm_resource_group.rg_des.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.lvm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "linux_test_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_linux_virtual_machine" "lvm" {
  name                = local.vm_name
  resource_group_name = azurerm_resource_group.rg_des.name
  location            = azurerm_resource_group.rg_des.location
  size                = var.vm_size
  admin_username      = "adminuser"
  network_interface_ids = [
    azurerm_network_interface.lvm.id,
  ]

  admin_ssh_key {
    username   = "adminuser"
    #public_key = file("~/.ssh/id_rsa.pub")
     public_key = tls_private_key.linux_test_ssh.public_key_openssh
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    # Add this line - 
    #azurerm_disk_encryption_set.os.id i sin vm-diskset
    disk_encryption_set_id = azurerm_disk_encryption_set.os.id
  }

  source_image_reference {
    offer                 = "0001-com-ubuntu-server-focal"
    publisher             = "Canonical"
    sku                   = "20_04-lts-gen2"
    version   = "latest"
  }
  /*source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
  }*/
}

resource "azurerm_managed_disk" "data" {
  name                   = "${local.vm_name}-data"
  location               = azurerm_resource_group.rg_des.location
  resource_group_name    = azurerm_resource_group.rg_des.name
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = "128"
  #azurerm_disk_encryption_set.data.id i sin vm-diskset
  disk_encryption_set_id = azurerm_disk_encryption_set.data.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.lvm.id
  lun                = "0"
  caching            = "ReadOnly"
}

data "azure_key_vault" "akv" {
  name = "lvm"
}

locals {
  vaultname = azure_key_vault.lvm.name
  subscriptionid = data.azurerm_client_config.current.subscription_id
}

resource "azurerm_virtual_machine_extension" "disk-encryption" {
  name                 = "DiskEncryption"
  location                    = data.azurerm_client_config.current.resourceGroups[0].location
  resource_group_name         = data.azurerm_client_config.current.resource_group_name
  tenant_id                   = data.azurerm_client_config.current.tenant_id
  
  publisher            = "Microsoft.Azure.Security"
  type                 = "AzureDiskEncryption"
  type_handler_version = "2.2"

  settings = <<SETTINGS
{
  "EncryptionOperation": "EnableEncryption",
  "KeyVaultURL": "https://${local.vaultname}.vault.azure.net",
  "KeyVaultResourceId": "/subscriptions/${local.subscriptionid}/resourceGroups/${local.vaultresourcegroup}/providers/Microsoft.KeyVault/vaults/${local.vaultname}",
  "KeyEncryptionKeyURL": "https://${local.vaultname}.vault.azure.net/keys/${local.keyname}/${local.keyversion}",
  "KekVaultResourceId": "/subscriptions/${local.subscriptionid}/resourceGroups/${local.vaultresourcegroup}/providers/Microsoft.KeyVault/vaults/${local.vaultname}",
  "KeyEncryptionAlgorithm": "RSA-OAEP",
  "VolumeType": "All"
}
SETTINGS
}
