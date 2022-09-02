locals {
    vm_name = "${var.vm_name}-${var.suffix}"
    rg_name = "${var.rg_name}-${var.suffix}"
}

variable "region" {
    default = "East US 2"
    type    = string
}

variable "suffix" {
    default = "test-des-tje"
    type    = string
}

variable "rg_name" {
    default = "rg"
    type    = string
}

variable "vm_name" {
    default = "vm"
    type    = string
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Recommended: Standard_E8-4s_v5"
}