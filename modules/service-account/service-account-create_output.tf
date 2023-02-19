output "service_account_id" {
  value = yandex_iam_service_account.myaccount.id
}

output "kms_key_id" {
  value = yandex_kms_symmetric_key.kms-key.id
}