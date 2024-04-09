resource "google_project_iam_binding" "csye_service_account_KMS" {
  project = var.project
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  members = ["serviceAccount:${local.cloud_storage_service_account}",]
}


resource "google_kms_crypto_key_iam_binding" "crypto_key_binding_sql" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.sql_instance_key.id
  role          = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${local.cloud_storage_service_account}"
  ]
}

resource "google_kms_crypto_key_iam_binding" "crypto_key_binding_bucket_storage" {
  provider      = google-beta
  crypto_key_id = google_kms_crypto_key.bucket_storage_key.id
  role          = "roles/cloudkms.admin"

  members = [
    "serviceAccount:${local.cloud_storage_service_account}","serviceAccount:${google_service_account.webapp_service_account.email}"
  ]
}

resource "google_project_iam_binding" "csye_service_account_logging" {
  project = var.project
  role    = var.csye_service_account_logging_role
  members = [ "serviceAccount:${google_service_account.webapp_service_account.email}"]
}

resource "google_project_iam_member" "name" {
    project = var.project
    role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
    member  = "serviceAccount:${google_project_service_identity.cloudsql_sa.email}"
}

resource "google_project_iam_member" "grant-google-storage-service-encrypt-decrypt" {
    project = var.project
  role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
  member  = "serviceAccount:${local.cloud_storage_service_account}"
}

# resource "google_project_iam_binding" "csye_service_account_compute_engine_encrypt_decrypt" {
#   project = var.project
#   role    = "roles/cloudkms.cryptoKeyEncrypterDecrypter"
#   members = [ "serviceAccount:service-738558818349@compute-system.iam.gserviceaccount.com"]
# }

resource "google_project_iam_binding" "csye_service_account_metric_writer" {
  project = var.project
  role    = var.csye_service_account_metric_writer_role
  members = [ "serviceAccount:${google_service_account.webapp_service_account.email}"]
}

resource "google_project_iam_binding" "pubsub" {
  project = var.project
  role    = var.pubsub_role
  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"
    ]
}

resource "google_pubsub_subscription_iam_binding" "webapp_subscription_binding" {
  project       = var.project
  subscription  = google_pubsub_subscription.cloud_function_subscription.name
  role          = var.pubsub_role_subscriber
  members       = var.google_pubsub_subscription_iam_binding_members
}

resource "google_kms_key_ring_iam_binding" "key_ring" {
  key_ring_id = google_kms_key_ring.webapp_keyring.id
  role        = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  members = [
    "serviceAccount:${google_service_account.webapp_service_account.email}"]
}
