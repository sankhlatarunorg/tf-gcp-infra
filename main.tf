provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}


resource "google_compute_network" "csye6225_vpc_network" {
  count                           = length(var.vpc_network_list)
  name                            = var.vpc_network_list[count.index]
  auto_create_subnetworks         = var.vpc_auto_create_subnetworks
  routing_mode                    = var.vpc_routing_mode
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}


resource "google_compute_subnetwork" "webapp" {
  name          = var.subnetwork_webapp
  ip_cidr_range = var.webapp_subnetwork_ip_cidr_range
  region        = var.vpc_region
  network       = google_compute_network.csye6225_vpc_network[0].id
}

resource "google_compute_subnetwork" "db" {
  name          = var.subnetwork_db
  ip_cidr_range = var.db_subnetwork_ip_cidr_range
  region        = var.vpc_region
  network       =  google_compute_network.csye6225_vpc_network[0].id
}

resource "google_compute_route" "hoproute" {
  name             = var.route_hop
  network          = google_compute_network.csye6225_vpc_network[0].self_link
  dest_range       = var.dest_range_route
  next_hop_gateway = var.next_hop_gateway_route
}

resource "google_service_account" "default" {
  account_id    = var.google_service_account_name
  display_name  = var.google_service_account_name
  project       = var.project 
}

resource "google_project_iam_binding" "csye_service_account_logging" {
  project = var.project
  role    = var.csye_service_account_logging_role
  members = [ "serviceAccount:${google_service_account.default.email}"]
}

resource "google_project_iam_binding" "csye_service_account_metric_writer" {
  project = var.project
  role    = var.csye_service_account_metric_writer_role
  members = [ "serviceAccount:${google_service_account.default.email}"]
}

resource "google_project_iam_binding" "pubsub" {
  project = var.project
  role    = var.pubsub_role
  members = [
    "serviceAccount:${google_service_account.default.email}"
    ]
}

resource "google_pubsub_subscription_iam_binding" "webapp_subscription_binding" {
  project = var.project
  subscription = google_pubsub_subscription.cloud_function_subscription.name
  role= var.pubsub_role_subscriber
  members = var.google_pubsub_subscription_iam_binding_members
}

resource "google_compute_instance" "webapp_vm" {
  name                      = var.webapp_vm_name
  machine_type              = var.machine_type
  zone                      = var.zone
  allow_stopping_for_update = true
  tags                      = var.firewall_policy_to_apply_name
  depends_on                = [ google_sql_database_instance.webapp_sql_instance,  google_service_account.default, google_project_iam_binding.csye_service_account_logging, google_project_iam_binding.csye_service_account_metric_writer]
  metadata                  = google_compute_project_metadata.web_metadata.metadata
  metadata_startup_script   = templatefile("metadata_script.tpl", {
    DB_USER     = "webapp",
    DB_PASSWORD = random_password.password.result,
    DB_HOST     = google_sql_database_instance.webapp_sql_instance.private_ip_address,
    DB_NAME     = "webapp"
  })
  boot_disk {
    initialize_params {
      image = var.base_image_name
      type  = var.base_image_type
      size  = var.boot_disk_size
    }
  }
  network_interface {
    network    = google_compute_network.csye6225_vpc_network[0].self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
    access_config {

    }
  }
  service_account {
    email  = google_service_account.default.email
    scopes = var.service_account_scopes_logging
  }
}

resource "google_dns_record_set" "webapp_dns_record_set" {
  name          = var.dns_record_set_name
  type          = var.dns_record_type
  ttl           = var.dns_record_set_ttl
  managed_zone  = var.dns_record_zone
  rrdatas     = [ google_compute_instance.webapp_vm.network_interface[0].access_config[0].nat_ip ]
}
resource "google_compute_project_metadata" "web_metadata" {
  metadata = {
    "DB_NAME"       = var.webapp_DB_Name
    "DB_USER"       = var.webapp_USER_Name
    "DB_PASSWORD"   = random_password.password.result
    "DB_HOST"       = google_sql_database_instance.webapp_sql_instance.private_ip_address
  }
}

resource "google_compute_firewall" "custom_firewall_rules" {
  count = length(var.firewall_rules_policy)
  name    = var.firewall_rules_policy[count.index].name
  network = google_compute_network.csye6225_vpc_network[0].self_link

  dynamic "allow" {
    for_each = var.firewall_rules_policy[count.index].rule_type == var.allow ? [1] : []
    content {
      protocol = var.firewall_rules_policy[count.index].port_protocol
      ports    = [var.firewall_rules_policy[count.index].port]
    }
  }

  dynamic "deny" {
    for_each = var.firewall_rules_policy[count.index].rule_type == var.deny ? [1] : []
    content {
      protocol = var.firewall_rules_policy[count.index].port_protocol
      ports    = [var.firewall_rules_policy[count.index].port]
    }
  }

  source_ranges = [var.firewall_rules_policy[count.index].source_range]
}

resource "google_sql_database_instance" "webapp_sql_instance" {
  name             = "webapp-sql-instance-${random_id.random_db_instance_id.hex}"
  database_version = var.database_version
  region           = var.region
  depends_on       = [ google_service_networking_connection.webapp_private_vpc_connection ]
  deletion_protection = false
  settings {
    tier                = var.database_tier
    # edition             = var.database_edition
    # disk_autoresize     = var.database_disk_autoresize
    disk_size           = var.database_disk_size
    # disk_type           = var.database_disk_type
    # availability_type   = var.database_availability_type
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.csye6225_vpc_network[0].self_link
    }
    backup_configuration {
      binary_log_enabled  = true
      enabled             = true
    }
  }
}

resource "google_pubsub_topic" "verify_email_topic" {
  name = var.topic_name
}

resource "google_pubsub_subscription" "cloud_function_subscription" {
  name  = var.google_pubsub_subscription_name
  topic = google_pubsub_topic.verify_email_topic.name
  ack_deadline_seconds = 10  
  message_retention_duration = var.google_pubsub_subscription_message_retention_duration
  expiration_policy {
    ttl = var.google_pubsub_subscription_expiration_policy_ttl
  }
  # push_config {
  #   push_endpoint = "https://cloudfunctions.googleapis.com/v1/projects/${var.project}/locations/${var.region}/functions/${google_cloudfunctions_function.process_new_user_message.name}"
  # }
}

resource "google_storage_bucket" "bucket" {
  name     = "${var.project}-gcf-source"
  location = var.google_storage_bucket_location
  uniform_bucket_level_access = true
}

resource "google_storage_bucket_object" "csye_object" {
  name   = var.google_storage_bucket_object_name
  bucket = google_storage_bucket.bucket.name
  source = var.google_storage_bucket_object_source 
}

resource "google_compute_subnetwork" "default" {
  name          = var.google_compute_subnetwork_name
  ip_cidr_range = var.google_compute_subnetwork_ip_cidr_range
  region        = var.region
  network       =  google_compute_network.csye6225_vpc_network[0].id
}

resource "google_project_service" "serverless_vpc_access" {
  service = var.google_project_service_name
}
resource "google_vpc_access_connector" "webapp_connector" {
  name                    = var.serverless_connector_name
  region                  = var.region
  network                 = google_compute_network.csye6225_vpc_network[0].self_link
  ip_cidr_range           = var.google_vpc_access_connector_ip_cidr_range
  min_instances           = var.google_vpc_access_connector_min_instances
  max_instances           = var.google_vpc_access_connector_max_instances
  machine_type            = var.google_vpc_access_connector_machine_type
  depends_on = [google_project_service.serverless_vpc_access]
}

# resource "google_vpc_access_connector" "conn" {
#   name          = "conn"
#   subnet {
#     name = google_compute_subnetwork.default.name
#   }
#   machine_type = "e2-standard-4"
# }

# Define the Cloud Function
resource "google_cloudfunctions2_function" "process_new_user_message" {
  name        = var.google_cloudfunctions2_function_name
  description = var.google_cloudfunctions2_function
  location = var.region

  build_config {
    runtime = var.google_cloudfunctions2_runtime
    entry_point =var.google_cloudfunctions2_function_entry_point
    source {
      storage_source {
        bucket = google_storage_bucket.bucket.name
        object = google_storage_bucket_object.csye_object.name
      }
    }
  }
  service_config {
    min_instance_count    = 1
    available_memory      = var.google_cloudfunctions2_function_service_config_availability
    timeout_seconds       = 60
    service_account_email = google_service_account.default.email
    vpc_connector = google_vpc_access_connector.webapp_connector.name
    environment_variables = {
      SERVICE_CONFIG_TEST     = var.google_cloudfunctions2_function_service_config_SERVICE_CONFIG_TEST
      DB_HOST="${google_sql_database_instance.webapp_sql_instance.private_ip_address}"
      DB_USER=var.DB_USER
      DB_NAME=var.DB_USER
      DB_PASSWORD="${ random_password.password.result}"
    } 
  }
  depends_on = [ google_sql_database_instance.webapp_sql_instance, google_vpc_access_connector.webapp_connector ]
  event_trigger {
    trigger_region = var.region
    event_type = var.google_cloudfunctions2_function_event_trigger_event_type
    pubsub_topic = google_pubsub_topic.verify_email_topic.id
    retry_policy = var.google_cloudfunctions2_function_event_trigger_retry_policy
  }
}

resource "google_compute_global_address" "global_address" {
  provider      = google-beta
  project       = var.project
  name          = var.global_address_name
  purpose       = var.global_address_purpose
  network       = google_compute_network.csye6225_vpc_network[0].self_link
  address_type  = var.global_address_type
  prefix_length = 16
}

resource "google_service_networking_connection" "webapp_private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.csye6225_vpc_network[0].self_link
  service                 = var.private_vpc_connection_service
  reserved_peering_ranges = [google_compute_global_address.global_address.name]
  deletion_policy         = var.deletion_policy
}

resource "google_sql_database" "sql_database" {
  name     = var.webapp_DB_Name
  instance = google_sql_database_instance.webapp_sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name      = var.webapp_USER_Name
  instance  = google_sql_database_instance.webapp_sql_instance.name
  password  = random_password.password.result
}

resource "random_password" "password" {
  length           = 16
  special          = false
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "random_id" "random_db_instance_id" {
  byte_length = 8
}


# resource "google_compute_firewall" "allow_port_3000" {
#   name    = var.allow_port_3000_name
#   network = google_compute_network.csye6225_vpc_network.self_link

#   allow {
#     protocol = var.allow_tcp_port_protocol
#     ports    = [var.allow_port_3000]
#   }

#   source_ranges = [var.sourse_range_firewall]
# }

# resource "google_compute_firewall" "deny_port_22" {
#   name    = var.deny_port_22_name
#   network = google_compute_network.csye6225_vpc_network.self_link
#   allow {
#     protocol  = var.allow_tcp_port_protocol
#     ports     = [var.deny_port_22]
#   }
#   source_ranges   = [var.sourse_range_firewall]
# }
