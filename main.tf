terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

//Initiating the provider. All parameters are configured as environment variables
provider "yandex" {} 

//Creating VPC
module "network-create" {
  source = "./modules/network-create"
}

//Creating service-accounts and its bindings
module "service-account-create" {
  source = "./modules/service-account"
  folder_id = var.folder_id
}

//Creating MDB
module "mdb-create" {
  source = "./modules/mdb-create"
  yc_network_id = module.network-create.yc_network_id
  service_account_id = module.service-account-create.service_account_id
  yc_db_password = var.yc_db_password
  yc_db_user = var.yc_db_user
  yc_db_name = var.yc_db_name
  depends_on = [module.service-account-create, module.network-create]
  folder_id = var.folder_id
}

//Creating k8s cluster
module "k8s-cluster-create" {
  source = "./modules/k8s-cluster-create"
  yc_network_id = module.network-create.yc_network_id
  vm_ssh_key_label = var.vm_ssh_key_label
  folder_id = var.folder_id
  service_account_id = module.service-account-create.service_account_id
  kms_key_id = module.service-account-create.kms_key_id
  depends_on = [module.service-account-create, module.network-create]
}

//Building docker image
module "container-build" {
  source = "./modules/container-build"
  yc_cr_id = var.yc_cr_id
}

//Creating ALB and instance group
module "alb-create" {
  source = "./modules/alb-create"
  service_account_id = module.service-account-create.service_account_id
  yc_network_id = module.network-create.yc_network_id
  depends_on = [module.service-account-create, module.network-create, module.mdb-create, module.container-build]
  yc_db_password = var.yc_db_password
  yc_db_user = var.yc_db_user
  yc_db_name = var.yc_db_name
  yc_db_host = module.mdb-create.yc_db_host
  yc_cr_id = var.yc_cr_id
  vm_ssh_key_label = var.vm_ssh_key_label
  folder_id = var.folder_id
  ssh_publickey = var.ssh_publickey
  ssh_username = var.ssh_username
}