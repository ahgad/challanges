data "google_service_account_access_token" "my_kubernetes_sa" {
  target_service_account = "{{service_account}}"
  scopes                 = ["userinfo-email", "cloud-platform"]
  lifetime               = "3600s"
}

data "google_container_cluster" "my_cluster" {
  name     = "my-cluster"
  location = "us-central1"
}

provider "kubernetes" {
  host  = "https://${data.google_container_cluster.my_cluster.endpoint}"
  token = data.google_service_account_access_token.my_kubernetes_sa.access_token
  cluster_ca_certificate = base64decode(
    data.google_container_cluster.my_cluster.master_auth[0].cluster_ca_certificate,
  )
}

resource "google_container_cluster" "my-gke-cluster" {
  name     = "my-gke-cluster"
  location = "us-central1"

  remove_default_node_pool = true
  initial_node_count       = 1

  node_config {
    service_account = google_service_account.myaccount
  }

  lifecycle {
    ignore_changes = ["node_config"]
  }

  # other settings...
}