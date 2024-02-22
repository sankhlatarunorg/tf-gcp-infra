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
  name         = "webapp-instance"
  machine_type = "e2-standard-2"
  zone         = var.zone
  boot_disk {
    initialize_params {
      image = "csye6225-image-a3"
      type = "pd-balanced"
    }
  }

  tags = ["allow-port-3000", "allow-port-5432"]
  network_interface {
    # network = "default"
    network     = google_compute_network.csye6225_vpc_network.self_link
    subnetwork  = google_compute_subnetwork.webapp.self_link
    access_config {
      
    }
  }
}


resource "google_compute_firewall" "allow_port_3000" {
  name    = "allow-port-3000"
  network = google_compute_network.csye6225_vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["3000"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-port-3000"]
}

resource "google_compute_firewall" "allow_port_5432" {
  name    = "allow-port-5432"
  network = google_compute_network.csye6225_vpc_network.self_link

  allow {
    protocol = "tcp"
    ports    = ["5432"]
  }

  deny {
    protocol = "tcp"
    ports    = ["22"]
  }

  source_ranges = ["0.0.0.0/0"]
  target_tags   = ["allow-port-5432"]
}



# resource "google_compute_firewall" "allow_internet_traffic" {
#   name    = "allow-internet-traffic"
#   network = google_compute_network.csye6225_vpc_network.self_link

#   allow {
#     protocol = "tcp"
#     ports    = ["3000"]
#   }

#   source_ranges = ["0.0.0.0/0"]
#   target_tags   = ["allow-internet-traffic"]
# }
