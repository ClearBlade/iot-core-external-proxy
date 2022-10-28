resource "google_compute_instance_template" "haproxy_template" {
  name        = "haproxy-template"
  description = "This is HAProxy template instance"
  tags        = ["haproxy", "clearblade"]
  labels = {
    app       = "clearblade"
    component = "haproxy"
  }
  instance_description = "HA proxy node"
  machine_type         = "e2-medium"
  can_ip_forward       = false

  scheduling {
    automatic_restart   = true
    on_host_maintenance = "MIGRATE"
  }
  disk {
    source_image = "debian-cloud/debian-11"
    disk_size_gb = 10
    auto_delete  = true
    boot         = true
  }
  network_interface {
    network    = google_compute_network.clearblade-network.name
    subnetwork = google_compute_subnetwork.clearblade-subnetwork.name
  }
  service_account {
    email  = google_service_account.haproxy-compute-svc.email
    scopes = ["cloud-platform"]
  }
  metadata_startup_script = data.local_file.haproxy_config.content
  metadata = {
    CERTIFICATE_KEY_SECRET_NAME = element(split("/", google_secret_manager_secret.certificate-key.name), 3)
    CERTIFICATE_SECRET_NAME     = element(split("/", google_secret_manager_secret.certificate.name), 3)
    CLEARBLADE_IP               = var.clearblade_ip
    CLEARBLADE_MQTT_IP          = var.clearblade_mqtt_ip
  }
  depends_on = [google_service_account.haproxy-compute-svc,
    google_secret_manager_secret_version.certificate,
    google_secret_manager_secret_version.certificate-key,
    google_compute_subnetwork.clearblade-subnetwork
  ]
}

data "local_file" "haproxy_config" {
  filename = "${path.module}/startup.sh"
}