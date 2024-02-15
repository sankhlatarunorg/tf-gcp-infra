provider "google" {
  credentials = file(var.credentials_file)
  project     = var.project
  region      = var.region
  zone        = var.zone
}


resource "google_compute_network" "csye6225_vpc_network" {
  name                            = "csye6225-network"
  auto_create_subnetworks         = "false"
  routing_mode                    = "REGIONAL"
  delete_default_routes_on_create = "true"
}


resource "google_compute_subnetwork" "webapp" {
  name          = "webapp-subnetwork"
  ip_cidr_range = "10.20.0.0/24"
  region        = "us-central1"
  network       = google_compute_network.csye6225_vpc_network.id
}

resource "google_compute_subnetwork" "db" {
  name          = "db-subnetwork"
  ip_cidr_range = "10.20.1.0/24"
  region        = "us-central1"
  network       = google_compute_network.csye6225_vpc_network.id
}

resource "google_compute_route" "hoproute" {
  name = "network-route"
  network = google_compute_network.csye6225_vpc_network.self_link
  dest_range = "0.0.0.0/0"
  next_hop_gateway = "default-internet-gateway"
}


# resource "google_compute_instance" "my_instance" {
#   name                      = var.vmInstance
#   machine_type              = "f1-micro"
#   zone                      = var.zone
#   allow_stopping_for_update = true
#   boot_disk {
#     initialize_params {
#       image = var.os_image
#     }
#   }

#   network_interface {
#     network = "default"
#     # network    = google_compute_network.csye_network.self_link
#     # subnetwork = google_compute_subnetwork.csye_subnetwork.self_link
#     access_config {

#     }
#   }
# }
