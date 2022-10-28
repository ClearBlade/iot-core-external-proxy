resource "google_compute_health_check" "auto-healing" {
  name                = "haproxy-auto-healing"
  check_interval_sec  = 30
  timeout_sec         = 5
  healthy_threshold   = 2
  unhealthy_threshold = 10

  https_health_check {
    request_path = "/api/about"
    port         = 443
  }
}
resource "google_compute_region_instance_group_manager" "haproxy-group" {
  name               = "haproxy-instance-group"
  description        = "HAProxy instance group"
  base_instance_name = "haproxy"
  region             = var.region
  version {
    instance_template = google_compute_instance_template.haproxy_template.id
  }

  named_port {
    name = "http"
    port = 8080
  }
  named_port {
    name = "https"
    port = 443
  }
  named_port {
    name = "mqtt-auth"
    port = 8906
  }

  named_port {
    name = "mqtt-ws"
    port = 8903
  }
  named_port {
    name = "mqtt-ws-auth"
    port = 8905
  }

  auto_healing_policies {
    health_check      = google_compute_health_check.auto-healing.id
    initial_delay_sec = 300
  }
  target_pools = [google_compute_target_pool.target-pool.id]
  target_size  = 1
  depends_on = [
    google_compute_target_pool.target-pool,
    google_compute_health_check.auto-healing,
    google_compute_instance_template.haproxy_template
  ]
}