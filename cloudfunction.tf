# Define the Cloud Function
resource "google_cloudfunctions2_function" "process_new_user_message" {
  name        = var.google_cloudfunctions2_function_name
  description = var.google_cloudfunctions2_function
  location    = var.region

  build_config {
    runtime     = var.google_cloudfunctions2_runtime
    entry_point = var.google_cloudfunctions2_function_entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.csye_object.name
      }
    }
  }
  service_config {
    min_instance_count    = var.google_cloudfunctions2_function_service_config_min_instances
    available_memory      = var.google_cloudfunctions2_function_service_config_availability
    timeout_seconds       = var.google_cloudfunctions2_function_service_config_timeout
    service_account_email = google_service_account.webapp_service_account.email
    vpc_connector         = google_vpc_access_connector.webapp_connector.name
    environment_variables = {
      SERVICE_CONFIG_TEST     = var.google_cloudfunctions2_function_service_config_SERVICE_CONFIG_TEST
      DB_HOST                 = "${google_sql_database_instance.webapp_sql_instance.private_ip_address}"
      DB_USER                 = var.DB_USER
      DB_NAME                 = var.DB_USER
      DB_PASSWORD             = "${ random_password.password.result}"
    } 
  }
  depends_on = [ google_sql_database_instance.webapp_sql_instance, google_vpc_access_connector.webapp_connector ]
  event_trigger {
    trigger_region  = var.region
    event_type      = var.google_cloudfunctions2_function_event_trigger_event_type
    pubsub_topic    = google_pubsub_topic.verify_email_topic.id
    retry_policy    = var.google_cloudfunctions2_function_event_trigger_retry_policy
  }
}
