 variable "folder_id" {
  description = "ID of the demo folder"
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

variable "yc_db_name" {
    description = "db_name"
    type = string
}

variable "yc_db_user" {
    description = "db_user"
    type = string
}