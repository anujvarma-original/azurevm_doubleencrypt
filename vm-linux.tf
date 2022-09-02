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
    public_key = file("~/.ssh/id_rsa.pub")
  }

  os_disk {
    caching                = "ReadWrite"
    storage_account_type   = "Standard_LRS"
    # Add this line - azurerm_disk_encryption_set.os.id i sin vm-diskset
    disk_encryption_set_id = azurerm_disk_encryption_set.os.id
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "UbuntuServer"
    sku       = "20.04-LTS"
    version   = "latest"
  }
}

resource "azurerm_managed_disk" "data" {
  name                   = "${local.vm_name}-data"
  location               = azurerm_resource_group.rg_des.location
  resource_group_name    = azurerm_resource_group.rg_des.name
  storage_account_type   = "Standard_LRS"
  create_option          = "Empty"
  disk_size_gb           = "128"
  # Add this line - azurerm_disk_encryption_set.data.id i sin vm-diskset
  disk_encryption_set_id = azurerm_disk_encryption_set.data.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_linux_virtual_machine.lvm.id
  lun                = "0"
  caching            = "ReadOnly"
}
