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

variable "subnetwork" {
  default = "csye6225-subnetwork"
}

variable "vmInstance" {
  default = "csye6225-terraform-instance"
  
}
