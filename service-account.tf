resource "google_service_account" "haproxy-compute-svc" {
  account_id   = "ha-proxy-compute"
  display_name = "Compute Engine Service Account to run instances with HAProxy"
}

resource "google_project_iam_member" "log-writer" {
  project    = var.project_id
  role       = "roles/logging.logWriter"
  member     = "serviceAccount:${google_service_account.haproxy-compute-svc.email}"
  depends_on = [google_service_account.haproxy-compute-svc]
}

resource "google_project_iam_member" "autoscaling-writer" {
  project    = var.project_id
  role       = "roles/autoscaling.metricsWriter"
  member     = "serviceAccount:${google_service_account.haproxy-compute-svc.email}"
  depends_on = [google_service_account.haproxy-compute-svc]
}

resource "google_project_iam_member" "secret-accessor" {
  project    = var.project_id
  role       = "roles/secretmanager.secretAccessor"
  member     = "serviceAccount:${google_service_account.haproxy-compute-svc.email}"
  depends_on = [google_service_account.haproxy-compute-svc]
}