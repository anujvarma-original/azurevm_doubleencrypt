# Azure Provider source and version being used
#AV - ensure provider version 3.3.0 or above, else, azure key vault resource fails on cryptic GetCertificateContacts error 
terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "=3.3.0"
    }
  }
}

# Configure the Microsoft Azure Provider
provider "azurerm" {
  features {}
}
