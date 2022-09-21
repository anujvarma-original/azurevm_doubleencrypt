resource "azurerm_resource_group" "rg_des" {
  name     = local.rg_name
  location = var.region
}