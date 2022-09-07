locals {
    vm_name = "${var.vm_name}-${var.suffix}"
    rg_name = "${var.rg_name}-${var.suffix}"
}

variable "region" {
    default = "East US 2"
    type    = string
}

variable "suffix" {
    default = "test-des-av-win"
    type    = string
}

variable "rg_name" {
    default = "rg"
    type    = string
}

variable "vm_name" {
    default = "vmwin"
    type    = string
}

variable "vm_size" {
  type        = string
  default     = "Standard_D2s_v3"
  description = "Recommended: Standard_E8-4s_v5"
}

# Windows Server 2022 SKU used to build VMs
variable "windows_2022_sku" {
  type        = string
  description = "Windows Server 2022 SKU used to build VMs"
  default     = "2022-Datacenter"
}
# Windows Server 2019 SKU used to build VMs
variable "windows_2019_sku" {
  type        = string
  description = "Windows Server 2019 SKU used to build VMs"
  default     = "2019-Datacenter"
}
# Windows Server 2016 SKU used to build VMs
variable "windows_2016_sku" {
  type        = string
  description = "Windows Server 2016 SKU used to build VMs"
  default     = "2016-Datacenter"
}