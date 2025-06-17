# Service Account for Loki to access GCS
resource "google_service_account" "loki_sa" {
  account_id   = "${var.cluster_name}-loki-sa"
  display_name = "Loki Service Account for ${var.cluster_name}"
  description  = "Service account for Loki to access GCS bucket"
}

# Service Account for Mimir to access GCS
resource "google_service_account" "mimir_sa" {
  account_id   = "${var.cluster_name}-mimir-sa"
  display_name = "Mimir Service Account for ${var.cluster_name}"
  description  = "Service account for Mimir to access GCS bucket"
}

# Allow Loki KSA to impersonate Loki GSA
resource "google_service_account_iam_member" "loki_workload_identity" {
  service_account_id = google_service_account.loki_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.lgtm_namespace}/loki]"
}

# Allow Mimir KSA to impersonate Mimir GSA
resource "google_service_account_iam_member" "mimir_workload_identity" {
  service_account_id = google_service_account.mimir_sa.name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[${var.lgtm_namespace}/mimir]"
}

# Service Account for cert-manager to manage Cloud DNS
resource "google_service_account" "cert_manager_sa" {
  count        = var.enable_cert_manager_sa ? 1 : 0
  account_id   = "${var.cluster_name}-cert-manager-sa"
  display_name = "cert-manager Service Account for ${var.cluster_name}"
  description  = "Service account for cert-manager to manage DNS-01 challenges"
}

# Allow cert-manager KSA to impersonate cert-manager GSA
resource "google_service_account_iam_member" "cert_manager_workload_identity" {
  count              = var.enable_cert_manager_sa ? 1 : 0
  service_account_id = google_service_account.cert_manager_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[cert-manager/cert-manager]"
}

# Service Account for external-dns (if needed)
resource "google_service_account" "external_dns_sa" {
  count        = var.enable_external_dns_sa ? 1 : 0
  account_id   = "${var.cluster_name}-external-dns-sa"
  display_name = "External DNS Service Account for ${var.cluster_name}"
  description  = "Service account for external-dns to manage Cloud DNS records"
}

# Allow external-dns KSA to impersonate external-dns GSA
resource "google_service_account_iam_member" "external_dns_workload_identity" {
  count              = var.enable_external_dns_sa ? 1 : 0
  service_account_id = google_service_account.external_dns_sa[0].name
  role               = "roles/iam.workloadIdentityUser"
  member             = "serviceAccount:${var.project_id}.svc.id.goog[external-dns/external-dns]"
}