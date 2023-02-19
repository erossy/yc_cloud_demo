 variable "folder_id" {
  description = "ID of the demo folder"
  type        = string
}

 variable "vm_ssh_key_label" {
  description = "ssh creds for VMs"
  type        = string
}

variable "k8s_version" {
    description = "K8S version to install"
    type = string
    default = "1.22"
}

variable "service_account_id" {
    description = "SA ID"
    type = string
}

variable "kms_key_id" {
    description = "KMS Key ID"
    type = string
}

variable "yc_network_id" {
    description = "VPC ID"
    type = string
}