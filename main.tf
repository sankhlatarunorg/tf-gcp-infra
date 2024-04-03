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
  name                      = var.subnetwork_webapp
  ip_cidr_range             = var.webapp_subnetwork_ip_cidr_range
  region                    = var.vpc_region
  network                   = google_compute_network.csye6225_vpc_network[0].id
  private_ip_google_access  = var.google_compute_subnetwork_private_ip_google_access
}

resource "google_compute_subnetwork" "db" {
  name                      = var.subnetwork_db
  ip_cidr_range             = var.db_subnetwork_ip_cidr_range
  region                    = var.vpc_region
  network                   =  google_compute_network.csye6225_vpc_network[0].id
  private_ip_google_access  = var.google_compute_subnetwork_private_ip_google_access
}

resource "google_compute_route" "hoproute" {
  name             = var.route_hop
  network          = google_compute_network.csye6225_vpc_network[0].self_link
  dest_range       = var.dest_range_route
  next_hop_gateway = var.next_hop_gateway_route
}

resource "google_service_account" "webapp_service_account" {
  account_id    = var.google_service_account_name
  display_name  = var.google_service_account_name
  project       = var.project 
}

resource "google_project_iam_binding" "csye_service_account_logging" {
  project = var.project
  role    = var.csye_service_account_logging_role
  members = [ "serviceAccount:${google_service_account.webapp_service_account.email}"]
}

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

resource "google_compute_region_instance_template" "webapp_vm_instance_template" {
  name          = var.webapp_vm_instance_template_name
  machine_type  = var.machine_type
  tags          = var.webapp_instance_tags
  region        = var.region
  depends_on    = [ google_sql_database_instance.webapp_sql_instance,  google_service_account.webapp_service_account, google_project_iam_binding.csye_service_account_logging, google_project_iam_binding.csye_service_account_metric_writer]
  metadata      = google_compute_project_metadata.web_metadata.metadata
  metadata_startup_script = templatefile("metadata_script.tpl", {
    DB_USER     = var.webapp_DB_Name,
    DB_PASSWORD = random_password.password.result,
    DB_HOST     = google_sql_database_instance.webapp_sql_instance.private_ip_address,
    DB_NAME     = var.webapp_DB_Name
  })
  disk {
    source_image = var.base_image_name
    auto_delete  = var.google_compute_region_instance_template_auto_delete
    disk_size_gb = var.boot_disk_size
    disk_type    = var.base_image_type
  }
  network_interface {
    network    = google_compute_network.csye6225_vpc_network[0].self_link
    subnetwork = google_compute_subnetwork.webapp.self_link
    # access_config {  }
  }
  service_account {
    email  = google_service_account.webapp_service_account.email
    scopes = var.service_account_scopes_logging
  }
}

resource "google_compute_health_check" "webapp_health_check" {
  name      = var.google_compute_health_check_name
  provider  = google-beta
  project   = var.project

  http_health_check {
    request_path        = var.http_health_check_path
    port                = var.http_health_check_port
    port_specification  = var.http_health_check_port_specification
    proxy_header        = var.http_health_check_proxy_header
  }
}

resource "google_compute_region_autoscaler" "webapp_autoscaler" {
  name        = var.webapp_autoscaler_name
  region      = var.region
  target      = google_compute_region_instance_group_manager.webapp_instance_group_manager_1.id
  depends_on  = [ google_compute_region_instance_group_manager.webapp_instance_group_manager_1 ]
  autoscaling_policy {
    min_replicas    = var.google_compute_region_autoscaler_min_replicas
    max_replicas    = var.google_compute_region_autoscaler_max_replicas
    cooldown_period = var.google_compute_region_autoscaler_cool_down_period_sec
    cpu_utilization {
      target = var.google_compute_region_autoscaler_cpu_utilization_target
    }
  }
}

resource "google_compute_region_instance_group_manager" "webapp_instance_group_manager_1" {
  name               = var.webapp_instance_group_manager_name
  region             = var.region
  base_instance_name = var.webapp_base_instance_name
  target_size        = var.google_compute_region_instance_group_manager_target
  version {
    instance_template = google_compute_region_instance_template.webapp_vm_instance_template.self_link
  }
  named_port {
    name = var.google_compute_instance_group_manager_named_ports_name
    port = var.google_compute_instance_group_manager_named_ports_port
  }
  auto_healing_policies {
    health_check      = google_compute_health_check.webapp_health_check.self_link
    initial_delay_sec = var.instance_group_autohealing_policy_initial_delay_sec
  }
}

resource "google_dns_record_set" "webapp_dns_record_set" {
  name          = var.dns_record_set_name
  type          = var.dns_record_type
  ttl           = var.dns_record_set_ttl
  managed_zone  = var.dns_record_zone
  rrdatas       = [ google_compute_global_forwarding_rule.webapp_forwarding_rule.ip_address]
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
  count   = length(var.firewall_rules_policy)
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
  name                = "webapp-sql-instance-${random_id.random_db_instance_id.hex}"
  database_version    = var.database_version
  region              = var.region
  depends_on          = [ google_service_networking_connection.webapp_private_vpc_connection ]
  deletion_protection = var.webapp_sql_instance_deletion_protection
  settings {
    tier                = var.database_tier
    disk_size           = var.database_disk_size
    ip_configuration {
      ipv4_enabled    = var.google_sql_database_instance_ip_config_ipv4_enabled
      private_network = google_compute_network.csye6225_vpc_network[0].self_link
    }
    backup_configuration {
      binary_log_enabled  = var.google_sql_database_instance_backup_configuration_binary_log_enabled
      enabled             = var.google_sql_database_instance_backup_configuration_log_enabled
    }
  }
}

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

resource "google_storage_bucket" "bucket" {
  name                         = "${var.project}-gcf-source"
  location                     = var.google_storage_bucket_location
  uniform_bucket_level_access   = var.google_storage_bucket_uniform_bucket_level_access
}

resource "google_storage_bucket_object" "csye_object" {
  name   = var.google_storage_bucket_object_name
  bucket = google_storage_bucket.bucket.name
  source = var.google_storage_bucket_object_source 
}

resource "google_compute_subnetwork" "webapp__vpc_connector" {
  name                      = var.google_compute_subnetwork_name
  ip_cidr_range             = var.google_compute_subnetwork_ip_cidr_range
  region                    = var.region
  network                   =  google_compute_network.csye6225_vpc_network[0].id
  private_ip_google_access  = var.google_compute_subnetwork_private_ip_google_access
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
  depends_on              = [google_project_service.serverless_vpc_access]
}

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

resource "google_compute_managed_ssl_certificate" "webapp_ssl_cert" {
  provider = google-beta
  name     = var.google_compute_managed_ssl_certificate_name
  project = var.project 
  managed {
    domains = [var.webapp_domain_name]
  }
}

resource "google_compute_firewall" "webapp_firewall_allow_health_check" {
  name          = var.webapp_firewall_allow_health_check_name
  provider      = google-beta
  direction     = var.webapp_firewall_allow_health_check_direction
  network       = google_compute_network.csye6225_vpc_network[0].self_link
  source_ranges = var.google_compute_firewall_source_ranges
  allow {
    protocol = var.webapp_firewall_allow_health_check_protocol
  }
  target_tags = var.google_compute_firewall_target_tags
  project     = var.project
}

resource "google_compute_backend_service" "webapp_backend_service" {
  name                    = var.google_compute_backend_service_name
  project                 =  var.project
  provider                = google-beta
  protocol                = var.google_compute_backend_service_protocol
  port_name               = var.google_compute_backend_service_port_name
  load_balancing_scheme   = var.google_compute_backend_service_load_balancing_scheme
  timeout_sec             = var.google_compute_backend_service_timeout_sec
  health_checks           = [google_compute_health_check.webapp_health_check.id]
  session_affinity        = var.google_compute_backend_service_session_affinity
  backend {
    group           = google_compute_region_instance_group_manager.webapp_instance_group_manager_1.instance_group
    balancing_mode  = var.google_compute_backend_service_backend_balancing_mode
    capacity_scaler = var.google_compute_backend_service_capacity_scaler
  }
  log_config {
    enable      = var.google_compute_backend_service_log_enabled
    sample_rate = var.google_compute_backend_service_log_sample_rate
  }
}

resource "google_compute_url_map" "webapp_url_map" {
  name            = var.webapp_url_map_name
  provider        = google-beta
  project         = var.project
  default_service = google_compute_backend_service.webapp_backend_service.id
}

resource "google_compute_target_https_proxy" "webapp_target_http_proxy" {
  name              = var.google_compute_target_https_proxy_name
  provider          = google-beta
  project           = var.project
  url_map           = google_compute_url_map.webapp_url_map.id
  ssl_certificates  = [google_compute_managed_ssl_certificate.webapp_ssl_cert.self_link]
}

resource "google_compute_global_forwarding_rule" "webapp_forwarding_rule" {
  name                  = var.google_compute_global_forwarding_rule_name
  project               = var.project
  provider              = google-beta
  ip_protocol           = var.google_compute_global_forwarding_rule_ip_protocol
  load_balancing_scheme = var.google_compute_global_forwarding_rule_load_balancing_scheme
  port_range            = var.google_compute_global_forwarding_rule_port_range
  target                = google_compute_target_https_proxy.webapp_target_http_proxy.id
}

resource "random_password" "password" {
  length           = var.random_password_length
  special          = var.random_password_special
  override_special = var.random_password_override_special
}


resource "random_id" "random_db_instance_id" {
  byte_length = var.random_id_instance_id
}
