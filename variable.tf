 variable "project" {
   default = "csye-6225-tarun-002294529"
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
