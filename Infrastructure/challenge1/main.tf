terraform {
  required_providers {
    google = {
      source = "hashicorp/google"
      version = "4.45.0"
    }
    kubernetes = {
      source = "hashicorp/kubernetes"
      version = "2.16.1"
    }
  }
}

provider "google" {
    account_file = "${var.account_file_path}"
    client_secrets_file = "${var.client_secrets_path}"
    project = "${var.project_name}"
    region = "${var.region_name}"
    zone = "${var.zone_name}"
}