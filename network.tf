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


resource "google_compute_subnetwork" "webapp__vpc_connector" {
  name                      = var.google_compute_subnetwork_name
  ip_cidr_range             = var.google_compute_subnetwork_ip_cidr_range
  region                    = var.region
  network                   =  google_compute_network.csye6225_vpc_network[0].id
  private_ip_google_access  = var.google_compute_subnetwork_private_ip_google_access
}

resource "google_service_networking_connection" "webapp_private_vpc_connection" {
  provider                = google-beta
  network                 = google_compute_network.csye6225_vpc_network[0].self_link
  service                 = var.private_vpc_connection_service
  reserved_peering_ranges = [google_compute_global_address.global_address.name]
  deletion_policy         = var.deletion_policy
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
