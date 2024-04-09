
resource "google_pubsub_topic" "verify_email_topic" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "cloud_function_subscription" {
  name                        = var.google_pubsub_subscription_name
  topic                       = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds        = var.google_pubsub_subscription_ack_deadline
  message_retention_duration  = var.google_pubsub_subscription_message_retention_duration
  expiration_policy {
    ttl = var.google_pubsub_subscription_expiration_policy_ttl
  }
}
