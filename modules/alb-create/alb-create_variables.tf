 variable "folder_id" {
  description = "ID of the demo folder"
  type        = string
}

 variable "vm_ssh_key_label" {
  description = "ssh creds for VMs"
  type        = string
}

variable "service_account_id" {
    description = "SA ID"
    type = string
}

variable "yc_network_id" {
    description = "VPC ID"
    type = string
}

variable "yc_db_password" {
    description = "db_password"
    type = string
}

variable "yc_db_user" {
    description = "db_user"
    type = string
}

variable "yc_db_name" {
    description = "db_name"
    type = string
}

variable "yc_db_host" {
    description = "db_host"
    type = string
}

variable "yc_cr_id" {
    description = "cr_id"
    type = string
}

variable "ssh_username" {
    description = "ssh_username"
    type = string
}

variable "ssh_publickey" {
    description = "ssh_username"
    type = string
}