resource "google_compute_firewall" "haproxy-firewall" {
  name    = "clearblade-firewall"
  network = google_compute_network.clearblade-network.name
  allow {
    protocol = "tcp"
    ports    = ["443", "1884", "8080", "8443", "8903", "8904", "8905", "8906"]
  }
  target_tags   = google_compute_instance_template.haproxy_template.tags
  source_ranges = ["0.0.0.0/0"]
  depends_on = [
    google_compute_instance_template.haproxy_template,
    google_compute_network.clearblade-network
  ]
}

resource "google_compute_firewall" "iap-ssh-allow" {
  name    = "iap-ssh-allow"
  network = google_compute_network.clearblade-network.name
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
  target_tags   = google_compute_instance_template.haproxy_template.tags
  source_ranges = ["35.235.240.0/20"]
  depends_on = [
    google_compute_instance_template.haproxy_template,
    google_compute_network.clearblade-network
  ]
}

resource "google_compute_network" "clearblade-network" {
  name                    = "clearblade-network"
  auto_create_subnetworks = false
}

resource "google_compute_subnetwork" "clearblade-subnetwork" {
  name          = "cb-subnetwork"
  ip_cidr_range = "10.2.0.0/16"
  region        = var.region
  network       = google_compute_network.clearblade-network.id
}

resource "google_compute_router" "cb-router" {
  name       = "cb-router"
  region     = google_compute_subnetwork.clearblade-subnetwork.region
  network    = google_compute_network.clearblade-network.id
  depends_on = [google_compute_subnetwork.clearblade-subnetwork]
}

resource "google_compute_router_nat" "cb-nat" {
  name                                = "cb-nat"
  router                              = google_compute_router.cb-router.name
  region                              = google_compute_router.cb-router.region
  nat_ip_allocate_option              = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat  = "ALL_SUBNETWORKS_ALL_IP_RANGES"
  enable_dynamic_port_allocation      = true
  min_ports_per_vm                    = 32
  enable_endpoint_independent_mapping = false
}