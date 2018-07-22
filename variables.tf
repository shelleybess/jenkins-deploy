# Azure Credentials

variable "subscription_id" {}
variable "client_id" {}
variable "client_secret" {}
variable "tenant_id" {}

# Backend variables

variable "storage_account_name" {
  description = "Storage account name for .tfstate file."
}

variable "container_name" {
  description = "Container name for .tfstate file."
}

variable "tfstate_key" {
  description = "Key for backend .tfstate file."
}

variable "backend_access_key" {
  description = "Access Key to storage account."
}

# Variables

variable "location" {
  default = "East US"
}

variable "ssh_public_key_data" {
  description = "The SSH public key for remote connection of the Jenkins virtual machine."
}

variable "ssh_private_key_data" {
  description = "The SSH private key for remote connection."
}

variable "resource_group_name" {
  default = "resource_group"
}

variable "virtual_machine_osdisk_type" {
  description = "The managed OS disk type of the Jenkins virtual machine."
  default     = "Standard_LRS"
}

variable "vm_username" {}

variable "vm_size" {
  default = "Basic_A1"
}

variable "network_name" {
  default = "pipeline-virtual-network"
}

variable "subnet_name" {
  default = "pipeline-subnet"
}

variable "security_group_name" {
  default = "pipeline-securitygroup"
}

variable "vm_name" {
  default = "Pipeline_VM"
}

variable "os_name" {
  default = "Ubuntu"
}
