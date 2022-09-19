data "azurerm_shared_image" "azure_image_repo" {
  name                = var.custom_image_name
  gallery_name        = var.gallery_name
  resource_group_name = var.rg_name
}

resource "azurerm_virtual_network" "wvm" {
  name                = "vnet-${var.suffix}"
  address_space       = ["10.0.0.0/16"]
  location            = azurerm_resource_group.rg_des_win.location
  resource_group_name = azurerm_resource_group.rg_des_win.name
}

resource "azurerm_subnet" "wvm" {
  name                 = "snet-${var.suffix}"
  resource_group_name  = azurerm_resource_group.rg_des_win.name
  virtual_network_name = azurerm_virtual_network.wvm.name
  address_prefixes     = ["10.0.2.0/24"]
}

resource "azurerm_network_interface" "wvm" {
  name                = "${local.vm_name}-nic"
  location            = azurerm_resource_group.rg_des_win.location
  resource_group_name = azurerm_resource_group.rg_des_win.name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.wvm.id
    private_ip_address_allocation = "Dynamic"
  }
}

# Create (and display) an SSH key
resource "tls_private_key" "win_test_ssh" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "azurerm_windows_virtual_machine" "wvm" {
  name                = local.vm_name
  computer_name       = "av-test-win"
  resource_group_name = azurerm_resource_group.rg_des_win.name
  location            = azurerm_resource_group.rg_des_win.location
  size                = var.vm_size
  admin_username      = "adminuser"
  admin_password      = "Passw0rd%"
  network_interface_ids = [
    azurerm_network_interface.wvm.id,
  ]

  source_image_id = data.azurerm_shared_image.azure_image_repo.id

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
    # Add this line - 
    #azurerm_disk_encryption_set.os.id i sin vm-diskset
    disk_encryption_set_id = azurerm_disk_encryption_set.os.id
  }


  /*source_image_reference {
    publisher = "MicrosoftWindowsServer"
    offer     = "WindowsServer"
    sku       = var.windows_2022_sku
    version   = "latest"  
 }*/
}

resource "azurerm_managed_disk" "data" {
  name                 = "${local.vm_name}-data"
  location             = azurerm_resource_group.rg_des_win.location
  resource_group_name  = azurerm_resource_group.rg_des_win.name
  storage_account_type = "Standard_LRS"
  create_option        = "Empty"
  disk_size_gb         = "128"
  #azurerm_disk_encryption_set.data.id i sin vm-diskset
  disk_encryption_set_id = azurerm_disk_encryption_set.data.id
}

resource "azurerm_virtual_machine_data_disk_attachment" "data-disk" {
  managed_disk_id    = azurerm_managed_disk.data.id
  virtual_machine_id = azurerm_windows_virtual_machine.wvm.id
  lun                = "1"
  caching            = "ReadWrite"
  depends_on = [
    azurerm_windows_virtual_machine.wvm
  ]
}

/*
 resource azurerm_virtual_machine_data_disk_attachment attachDisk {
      managed_disk_id    = azurerm_managed_disk.dataDisk.id
      virtual_machine_id = azurerm_linux_virtual_machine.vm.id
      lun                = 1
      caching            = ReadWrite
      depends_on = [
        azurerm_linux_virtual_machine.vm
      ]
}
*/