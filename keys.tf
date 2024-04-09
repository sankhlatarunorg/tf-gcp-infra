resource "google_kms_key_ring" "webapp_keyring" {
  name     = var.webapp_keyring_name
  location = var.region
}

resource "google_kms_crypto_key" "webapp_key" {
  name     = var.webapp_key_name
  key_ring = google_kms_key_ring.webapp_keyring.id
  purpose = "ENCRYPT_DECRYPT"
  rotation_period   = var.rotation_period_key

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "sql_instance_key" {
  name     = var.sql_instance_key_name
  key_ring = google_kms_key_ring.webapp_keyring.id
  rotation_period   = var.rotation_period_key

  lifecycle {
    prevent_destroy = false
  }
}

resource "google_kms_crypto_key" "bucket_storage_key" {
  name     = var.bucket_storage_key_name
  key_ring = google_kms_key_ring.webapp_keyring.id
  rotation_period   = var.rotation_period_key
  
  lifecycle {
    prevent_destroy = false
  }
}
