provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}


resource "google_compute_network" "csye6225_vpc_network" {
  name                            = var.network
  auto_create_subnetworks         = var.vpc_auto_create_subnetworks
  routing_mode                    = var.vpc_routing_mode
  delete_default_routes_on_create = var.vpc_delete_default_routes_on_create
}


resource "google_compute_subnetwork" "webapp" {
  name          = var.subnetwork_webapp
  ip_cidr_range = var.webapp_subnetwork_ip_cidr_range
  region        = var.vpc_region
  network       = google_compute_network.csye6225_vpc_network.id
}

resource "google_compute_subnetwork" "db" {
  name          = var.subnetwork_db
  ip_cidr_range = var.db_subnetwork_ip_cidr_range
  region        = var.vpc_region
  network       = google_compute_network.csye6225_vpc_network.id
}

resource "google_compute_route" "hoproute" {
  name              = var.route_hop
  network           = google_compute_network.csye6225_vpc_network.self_link
  dest_range        = var.dest_range_route
  next_hop_gateway  = var.next_hop_gateway_route
}

// create vm from custom image gcp terraform
resource "google_compute_instance" "webapp_vm" {
  name         = var.webapp_vm_name
  machine_type = var.machine_type
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = var.base_image_name
      type = var.base_image_type
      size = var.boot_disk_size
    }
  }

  tags = [var.allow_port_3000_name, var.allow_port_5432_name,var.deny_port_22_name,var.allow_postgres]
  network_interface {
    # network = "default"
    network     = google_compute_network.csye6225_vpc_network.self_link
    subnetwork  = google_compute_subnetwork.webapp.self_link
    access_config {
      
    }
  }
  metadata = google_compute_project_metadata.web_metadata.metadata

  metadata_startup_script = <<-EOF
#!/bin/bash

MARKER_FILE="/var/run/webapp_configured"
ENV_FILE="/tmp/webapp/.env"
if [[ ! -e /tmp/webapp/.env ]]; then
    touch /tmp/webapp/.env
fi

if [ -f "$MARKER_FILE" ]; then
  echo "Web application is already configured. Skipping configuration."
else

  echo "DB_USER=\$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_USER)" >> $ENV_FILE
  echo "DB_PASSWORD=\$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_PASSWORD)" >> $ENV_FILE
  echo "DB_HOST=\$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_HOST)" >> $ENV_FILE
  echo "DB_NAME=\$(curl -H \"Metadata-Flavor: Google\" http://metadata.google.internal/computeMetadata/v1/instance/attributes/DB_NAME)" >> $ENV_FILE
  # Additional configurations...

  # Create the marker file to indicate successful configuration
  sudo touch $MARKER_FILE
fi
sudo systemctl stop csye-6225
sudo systemctl start csye-6225
sudo systemctl status csye-6225
EOF
}

resource "google_compute_project_metadata" "web_metadata" {
  metadata = {
    "DB_NAME"       = var.webapp_DB_Name
    "DB_USER"       = var.webapp_DB_Name
    "DB_PASSWORD"   = random_password.password.result
    "DB_HOST"       = var.global_address_address
  }
}

resource "google_compute_firewall" "allow_port_3000" {
  name    = var.allow_port_3000_name
  network = google_compute_network.csye6225_vpc_network.self_link

  allow {
    protocol = var.allow_tcp_port_protocol
    ports    = [var.allow_port_3000]
  }

  source_ranges = [var.sourse_range_firewall]
  target_tags   = [var.allow_port_3000_name]
}

resource "google_compute_firewall" "allow_port_5432" {
  name    = var.allow_port_5432_name
  network = google_compute_network.csye6225_vpc_network.self_link

  allow {
    protocol = var.allow_tcp_port_protocol
    ports    = [var.allow_port_5432]
  }

  source_ranges = [var.sourse_range_firewall]
  target_tags   = [var.allow_port_5432_name]
}

resource "google_compute_firewall" "deny_port_22" {
  name    = var.deny_port_22_name
  network = google_compute_network.csye6225_vpc_network.self_link
  deny {
    protocol  = var.allow_tcp_port_protocol
    ports     = [var.deny_port_22]
  }
  source_ranges   = [var.sourse_range_firewall]
  target_tags     = [var.deny_port_22_name] 
}


resource "google_sql_database_instance" "webapp_sql_instance" {
  name             = "webapp-sql-instance-${random_id.random_db_instance_id.hex}"
  database_version = "MYSQL_8_0"
  region           = var.region

  depends_on = [ google_service_networking_connection.webapp_private_vpc_connection ]
  settings {
    tier = "db-f1-micro"
    edition = "ENTERPRISE"
    disk_autoresize     = false
    disk_size           = 10
    disk_type           = "PD_HDD"
    availability_type   = "REGIONAL"
    ip_configuration {
      ipv4_enabled    = false
      private_network = google_compute_network.csye6225_vpc_network.self_link
    }
    backup_configuration {
      binary_log_enabled = true
      enabled = true
    }
  }
  deletion_protection = false
}

resource "google_compute_global_address" "global_address" {
  provider      = google-beta
  project       = var.project
  name          = var.global_address_name
  purpose       = var.global_address_purpose
  network       = google_compute_network.csye6225_vpc_network.id
  address_type = "INTERNAL"
  address       = var.global_address_address
}

resource "google_service_networking_connection" "webapp_private_vpc_connection" {
  provider              = google-beta
  network                 = google_compute_network.csye6225_vpc_network.id
  service                 = "servicenetworking.googleapis.com"
  reserved_peering_ranges = [google_compute_global_address.global_address.name]
}

resource "google_sql_database" "sql_database" {
  name     = var.webapp_DB_Name
  instance = google_sql_database_instance.webapp_sql_instance.name
}

resource "google_sql_user" "sql_user" {
  name = var.webapp_DB_Name
  instance = google_sql_database_instance.webapp_sql_instance.name
  password = random_password.password.result
}

resource "random_password" "password" {
  length           = 16
  special          = true
  override_special = "!#$%&*()-_=+[]{}<>:?"
}


resource "random_id" "random_db_instance_id" {
  byte_length = 8
}
