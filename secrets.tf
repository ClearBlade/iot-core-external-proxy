resource "google_secret_manager_secret" "certificate-key" {
  secret_id = "certificate-key"
  replication {
    user_managed {
      replicas {
        location = var.region
      }
    }
  }
}
resource "google_secret_manager_secret" "certificate" {
  secret_id = "certificate"
  replication {
    automatic = true
  }
}


resource "google_secret_manager_secret_version" "certificate-key" {
  secret = google_secret_manager_secret.certificate-key.id

  secret_data = data.local_file.certificate-key.content
  depends_on = [google_secret_manager_secret.certificate-key]
}

resource "google_secret_manager_secret_version" "certificate" {
  secret = google_secret_manager_secret.certificate.id

  secret_data = data.local_file.certificate.content
  depends_on = [google_secret_manager_secret.certificate]
}


data "local_file" "certificate-key" {
  filename = "${path.module}/certs/certificate.pem.key"
}
data "local_file" "certificate" {
  filename = "${path.module}/certs/certificate.pem"
}