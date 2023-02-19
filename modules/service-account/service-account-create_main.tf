terraform {
  required_providers {
    yandex = {
      source = "yandex-cloud/yandex"
    }
  }
  required_version = ">= 0.13"
}

resource "yandex_iam_service_account" "myaccount" {
  name        = var.sa_name
  description = "K8S regional service account"
}

resource "yandex_resourcemanager_folder_iam_binding" "k8s-clusters-agent" {
  # The service account is assigned the k8s.clusters.agent role.
  folder_id = var.folder_id
  role      = "k8s.clusters.agent"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "vpc-public-admin" {
  # The service account is assigned the vpc.publicAdmin role.
  folder_id = var.folder_id
  role      = "vpc.publicAdmin"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "images-puller" {
  # The service account is assigned the container-registry.images.puller role.
  folder_id = var.folder_id
  role      = "container-registry.images.puller"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "load-balancer-admin" {
  # The service account is assigned the load-balancer admin role
  folder_id = var.folder_id
  role      = "load-balancer.admin"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "alb-editor" {
  # The service account is assigned the load-balancer admin role
  folder_id = var.folder_id
  role      = "alb.editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "certificate-downloader" {
  # The service account is assigned the load-balancer admin role
  folder_id = var.folder_id
  role      = "certificate-manager.certificates.downloader"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "compute-viewer" {
  # The service account is assigned the load-balancer admin role
  folder_id = var.folder_id
  role      = "compute.viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_resourcemanager_folder_iam_binding" "editor" {
  # The service account is assigned the load-balancer admin role
  folder_id = var.folder_id
  role      = "editor"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}"
  ]
}

resource "yandex_kms_symmetric_key" "kms-key" {
  # A key for encrypting critical information, including passwords, OAuth tokens, and SSH keys.
  name              = "kms-key"
  default_algorithm = "AES_128"
  rotation_period   = "8760h" # 1 year.
}

resource "yandex_kms_symmetric_key_iam_binding" "viewer" {
  symmetric_key_id = yandex_kms_symmetric_key.kms-key.id
  role             = "viewer"
  members = [
    "serviceAccount:${yandex_iam_service_account.myaccount.id}",
  ]
}