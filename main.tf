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
