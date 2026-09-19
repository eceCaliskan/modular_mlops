#This file is responsible for creating the compute instance for GCP using Terraform
#
#This file is a part of OUT2 A reproducible open-source MLOps pipeline modules implemented with IaC approach.
#
# Main resources used https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_instance
#
#Defining the project, region and zone information for GCP
provider "google" {
  project     = "project-8fba7723-3f35-48db-ae1"
  region      = "us-central1"
  zone        = "us-central1-a"
}

#Create google compute instance called training
# Source https://registry.terraform.io/providers/hashicorp/google/latest/docs/data-sources/compute_instance
resource "google_compute_instance" "default" {
  provider = google
  name = "training"
  machine_type = "e2-micro"
  network_interface {
    network = "default"
  }
  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2004-focal-v20220712"
    }
  }
  allow_stopping_for_update = true
}