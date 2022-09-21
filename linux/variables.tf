locals {
    vm_name = "${var.vm_name}-${var.suffix}"
    rg_name = "${var.rg_name}-${var.suffix}"
}

variable "region" {
    default = "East US 2"
    type    = string
}

variable "suffix" {
    default = "test-des-av-lnx"
    type    = string
}

variable "rg_name" {
    default = "rglnx"
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

variable "gallery_name" {
  type        = string
  default = "wincustom"
  description = "image gallery name"
}

variable "custom_image_name" {
  type        = string
  default     = "customlnxdef"
  description = "custom image name"
}