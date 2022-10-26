resource "google_compute_address" "lb_address" {
  project      = var.project_id
  name         = "lb-haproxy-${var.region}"
  address_type = "EXTERNAL"
  region       = var.region
}

resource "google_compute_http_health_check" "lb-healthcheck" {
  name                = "lb-haproxy-heath"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10
  request_path        = "/api/about"
  port                = 8080
}

resource "google_compute_target_pool" "target-pool" {
  name          = "haproxy-target-pool"
  region        = var.region
  health_checks = [google_compute_http_health_check.lb-healthcheck.name]
  depends_on    = [google_compute_http_health_check.lb-healthcheck]
}


resource "google_compute_forwarding_rule" "haproxy-forward-rules" {
  name                  = "haproxy-tcp-forwarding-rule"
  ip_protocol           = "TCP"
  load_balancing_scheme = "EXTERNAL"
  port_range            = "443-8906"
  target                = google_compute_target_pool.target-pool.id
  ip_address            = google_compute_address.lb_address.id
  region                = var.region
  depends_on            = [google_compute_target_pool.target-pool, google_compute_address.lb_address]
}

