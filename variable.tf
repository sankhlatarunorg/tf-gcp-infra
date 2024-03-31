 variable "project" {
   default = "csye6225tarundev"
 }

 variable "credentials_file" {
   default = "credentials.json"
 }

 variable "region" {
    type = string
   default = "us-central1"
   description = "value of the region"
 }

 variable "zone" {
   default = "us-central1-a"
 }

 variable "os_image" {
   default = "cos-cloud/cos-stable"
 }

variable "network" {
  default = "csye6225-network"
}

variable "subnetwork_webapp" {
  default = "webapp-subnetwork"
}

variable "subnetwork_db" {
  default = "db-subnetwork"
}

variable "route_hop" {
  default = "network-route"
}

variable "vmInstance" {
  default = "csye6225-terraform-instance"
}

variable "vpc_routing_mode" {
  default = "REGIONAL"
}

variable "vpc_auto_create_subnetworks" {
  default = "false"
}

variable "vpc_delete_default_routes_on_create" {
  default = "true"
}

variable "webapp_subnetwork_ip_cidr_range" {
  default = "10.20.0.0/24"
}

variable "db_subnetwork_ip_cidr_range" {
  default = "10.20.1.0/24"
}

variable "dest_range_route" {
  default = "0.0.0.0/0"
}

variable "next_hop_gateway_route" {
  default = "default-internet-gateway"
  
}

variable "vpc_region" {
  default = "us-central1"
}

variable "sourse_range_firewall" {
  default = "0.0.0.0/0"
}

variable "allow_port_3000_name" {
  default = "allow-port-3000"
}

variable "allow_port_5432_name" {
  default = "allow-port-5432"
}

variable "deny_port_22_name" {
  default = "deny-port-22"
}

variable "allow_port_3000" {
  default = "3000"
}

variable "allow_port_5432" {
  default = "5432"
}

variable "allow_tcp_port_protocol" {
  default = "tcp"
}


variable "deny_port_22" {
  default = "22"
}

variable "webapp_vm_name" {
  default = "webapp-instance-csye6225"
}

variable "machine_type" {
  default = "e2-standard-2"
  
}

variable "base_image_name" {
  default = "csye6225-image-a7-demo"
}


variable "base_image_type" {
  default = "pd-balanced"
}


variable "boot_disk_size" {
  default = "100"
}

variable "allow_postgres" {
  default = "postgrestag"
}

variable "global_address_name" {
  default = "global-psconnect-ip-1"
}

variable "global_address_purpose" {
  default = "VPC_PEERING"
}


variable "global_address_network_tier" {
  default = "PREMIUM"
}

variable "global_address_address" {
  default = "10.193.0.0"
}

variable "global_forwarding_rule_name" {
  default = "globalrule"
}

variable "target_global_forwarding_rule" {
  default = "all-apis"
}

variable "load_balancing_scheme" {
  default = ""
}

variable "webapp_DB_Name" {
  default = "webapp"
}

variable "webapp_USER_Name" {
  default = "webapp"
}

variable "firewall_rules_policy"  {
  type = list(object({
    rule_type     = string
    name          = string
    port_protocol = string
    port          = number
    source_range  = string
  }))
  default = [ {
    rule_type     = "allow"
    name          = "allow-port-3000"
    port_protocol = "tcp"
    port          = 3000
    source_range  = "0.0.0.0/0"
  },
  {
    rule_type     = "deny"
    name          = "deny-port-22"
    port_protocol = "tcp"
    port          = 22
    source_range  = "0.0.0.0/0"
  }]
}

variable "firewall_policy_to_apply_name" {
  type = list(string)
  default =[ "allow-port-3000", "deny-port-22"]
  
}

variable "allow" {
  default = "allow"
}

variable "deny" {
  default = "deny"
}

variable "service_account_email" {
  default = "738558818349-compute@developer.gserviceaccount.com"
}
variable "service_account_scopes" {
  type = list(string)
  default = ["https://www.googleapis.com/auth/devstorage.read_only", "https://www.googleapis.com/auth/logging.write", "https://www.googleapis.com/auth/monitoring.write", "https://www.googleapis.com/auth/service.management.readonly", "https://www.googleapis.com/auth/servicecontrol", "https://www.googleapis.com/auth/trace.append"]
}

variable "service_account_scopes_csye_vm" {
  type = list(string)
  default = ["logging-write", "monitoring", "monitoring-read", "monitoring-write"]
}
variable "vpc_network_list" {
  type = list(string)
  default = ["csye6225-network-01"]
}

variable "database_version" {
  default = "MYSQL_8_0"
}

variable "database_tier" {
  default = "db-n1-standard-1"
}

variable "database_edition" {
  default = "ENTERPRISE"
}

variable "database_disk_autoresize"{
  type = bool
  default = false
}

variable "database_disk_size" {
  type = number
  default = 100
}

variable "database_disk_type" {
  type = string
  default = "PD_SSD"
}

variable "database_availability_type" {
  default = "REGIONAL"
  
}

variable "global_address_type" {
  default = "INTERNAL"
  
}

variable "private_vpc_connection_service" {
  default = "servicenetworking.googleapis.com"
}

variable "metadata_startup_script" {
  default = "metadata_script.tpl"
  
}

variable "dns_record_type" {
  default = "A"
}

variable "dns_record_zone" {
  default = "csye-6225-zone"
}

variable "dns_record_set_name" {
  default = "tarunsankhla.me."
}

variable "dns_record_set_ttl" {
  default = "300"
}

variable "service_account_scopes_logging" {
  type = list(string)
  default = ["logging-write","monitoring-read","monitoring-write","cloud-platform"]

}

variable "csye_service_account_logging_role" {
  default = "roles/logging.admin"
}

variable "csye_service_account_metric_writer_role" {
  default = "roles/monitoring.metricWriter"
}

variable "google_service_account_name" {
  default = "webapp-service-account"
}

variable "deletion_policy" {
  default = "ABANDON"
  
}

variable "serverless_connector_name" {
  default = "serverless-connector"

}

variable "pubsub_role" {
  default = "roles/pubsub.publisher"  
}

variable "pubsub_role_subscriber" {
  default = "roles/pubsub.subscriber"

}

variable "abandon_deletion_policy" {
  default = "ABANDON"
}

variable "topic_name" {
  default = "verify_email"
}

variable "google_pubsub_subscription_iam_binding_members" {
  type = list(string)
  default = ["allUsers"]  
}

variable "google_pubsub_subscription_name" {
  default = "cloud_function_subscription"

}

variable "google_storage_bucket_location" {
  default = "US"
}

variable "google_storage_bucket_object_name" {
  default = "serverless-bucket"
}

variable "google_storage_bucket_object_source" {
  default = "./serverless.zip"
}

variable "google_compute_subnetwork_name" {
  default = "vpc-connector"

}

variable "google_compute_subnetwork_ip_cidr_range" {
  default = "10.2.0.0/28"

}

variable "google_project_service_name" {
  default = "vpcaccess.googleapis.com"

}

variable "google_vpc_access_connector_ip_cidr_range" {
  default = "10.8.0.0/28"

}

variable "google_vpc_access_connector_min_instances" {
  default = 2
}

variable "google_vpc_access_connector_max_instances" {
  default = 3 
}

variable "google_vpc_access_connector_machine_type" {
  default = "f1-micro"
}

variable "google_cloudfunctions2_function_name" {
  default = "cloud-funcation-process-new-user-message"
}

variable "google_cloudfunctions2_function" {
  default = "Process new user messages from Pub/Sub"
}

variable "google_cloudfunctions2_runtime" {
  default = "nodejs18"
}

variable "google_cloudfunctions2_function_entry_point" {
  default = "processNewUserMessage"
}

variable "google_cloudfunctions2_function_service_config_availability" {
  default = "256M"
}

variable "google_cloudfunctions2_function_service_config_SERVICE_CONFIG_TEST" {
  default = "config_test"
}

variable "google_cloudfunctions2_function_event_trigger_event_type" {
  default = "google.cloud.pubsub.topic.v1.messagePublished"
}

variable "google_cloudfunctions2_function_event_trigger_retry_policy" {
  default = "RETRY_POLICY_RETRY"
}

variable "DB_USER" {
  default = "webapp"
}

variable "google_pubsub_subscription_message_retention_duration" {
  default = "604800s"
}

variable "google_pubsub_subscription_expiration_policy_ttl" {
  default = "604800s"

}


variable "webapp_vm_instance_template_name" {
  default = "webapp-instance-template"
}
