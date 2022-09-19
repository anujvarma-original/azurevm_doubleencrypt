resource "azurerm_resource_group" "rg_des_win" {
  name     = local.rg_name
  location = var.region
}
