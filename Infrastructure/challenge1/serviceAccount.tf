resource "google_service_account" "myaccount" {
  account_id   = "myaccount"
  display_name = "My Service Account"
}

# note this requires the terraform to be run regularly
resource "time_rotating" "mykey_rotation" {
  rotation_days = 30
}

resource "google_service_account_key" "mykey" {
  service_account_id = "${google_service_account.myaccount.name}"

  keepers = {
    rotation_time = time_rotating.mykey_rotation.rotation_rfc3339
  }
}

resource "kubernetes_secret" "google-application-credentials" {
  metadata {
    name = "google-application-credentials"
  }
  data = {
    credentials.json = "${base64decode(google_service_account_key.mykey.private_key)}"
  }
}