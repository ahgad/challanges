terraform {
  backend "gcs" {
    bucket  = var.bucket_name
    prefix  = var.tf_prefix
  }
}
