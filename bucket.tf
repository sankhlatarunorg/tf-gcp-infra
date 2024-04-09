
resource "google_storage_bucket" "bucket" {
  name                         = "${var.project}-gcf-source"
  location                     = var.google_storage_bucket_location
#   uniform_bucket_level_access   = var.google_storage_bucket_uniform_bucket_level_access
  encryption {
    default_kms_key_name = google_kms_crypto_key.bucket_storage_key.id
  }
}

resource "google_storage_bucket_object" "csye_object" {
    name   = var.google_storage_bucket_object_name
    bucket = google_storage_bucket.bucket.name
    source = var.google_storage_bucket_object_source 
    # kms_key_name = google_kms_crypto_key.bucket_storage_key.name
    # depends_on = [ google_kms_crypto_key.bucket_storage_key ]
}
