# Local variables
locals {
  project_name = var.project_name
  environment  = "production"
  region       = var.region
  zone         = var.zone

  common_labels = {
    project     = local.project_name
    environment = local.environment
    managed_by  = "terraform"
  }
}

# GCP Network Module
module "network" {
  source = "../../modules/gcp-network"

  project_name      = local.project_name
  vpc_name          = "${local.project_name}-vpc"
  region            = local.region
  gke_subnet_cidr   = var.gke_subnet_cidr
  gke_pods_cidr     = var.gke_pods_cidr
  gke_services_cidr = var.gke_services_cidr
}

# GKE Cluster Module
module "gke_cluster" {
  source = "../../modules/gke-cluster"

  project_id          = var.project_id
  cluster_name        = "${local.project_name}-cluster"
  zone                = local.zone
  environment         = local.environment
  
  # Network configuration from network module
  network_name        = module.network.vpc_name
  subnet_name         = module.network.subnet_name
  pods_range_name     = module.network.pods_range_name
  services_range_name = module.network.services_range_name

  # Node pool configuration
  initial_node_count = var.initial_node_count
  min_node_count     = var.min_node_count
  max_node_count     = var.max_node_count
  machine_type       = var.machine_type
  disk_size_gb       = var.disk_size_gb
  preemptible_nodes  = var.preemptible_nodes

  # Security
  authorized_networks = var.authorized_networks

  # Labels
  cluster_labels = local.common_labels
  node_labels    = local.common_labels
  node_tags      = ["gke-node", "${local.project_name}-node"]

  # Workload Identity
  lgtm_namespace         = var.lgtm_namespace
  enable_cert_manager_sa = true
  enable_external_dns_sa = false
}

# GCS Buckets Module
module "gcs_buckets" {
  source = "../../modules/gcs-buckets"

  project_id = var.project_id
  location   = var.gcs_location

  # Service accounts from GKE module
  loki_service_account_email  = module.gke_cluster.loki_service_account_email
  mimir_service_account_email = module.gke_cluster.mimir_service_account_email

  # Retention settings
  loki_retention_days  = var.loki_retention_days
  mimir_retention_days = var.mimir_retention_days

  # Lifecycle policies
  enable_lifecycle_rules   = true
  loki_lifecycle_age_days  = 30
  mimir_lifecycle_age_days = 90

  # Backup bucket
  create_grafana_backup_bucket = true

  # Labels
  common_labels = local.common_labels
}

# Cloud DNS Zone (if you need to create one)
resource "google_dns_managed_zone" "main" {
  count = var.create_dns_zone ? 1 : 0

  name        = "${local.project_name}-zone"
  dns_name    = "${var.domain_name}."
  description = "DNS zone for ${local.project_name}"

  labels = local.common_labels
}

# DNS Records for services
resource "google_dns_record_set" "grafana" {
  count = var.create_dns_zone ? 1 : 0

  managed_zone = google_dns_managed_zone.main[0].name
  name         = "grafana.${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = [module.network.ingress_ip_address]
}

resource "google_dns_record_set" "argocd" {
  count = var.create_dns_zone ? 1 : 0

  managed_zone = google_dns_managed_zone.main[0].name
  name         = "argocd.${var.domain_name}."
  type         = "A"
  ttl          = 300
  rrdatas      = [module.network.ingress_ip_address]
}

# IAM roles for cert-manager (DNS-01 challenges)
resource "google_project_iam_member" "cert_manager_dns" {
  count = var.create_dns_zone ? 1 : 0

  project = var.project_id
  role    = "roles/dns.admin"
  member  = "serviceAccount:${module.gke_cluster.cert_manager_service_account_email}"
}

# Output important values for ArgoCD configuration
resource "local_file" "cluster_values" {
  filename = "${path.module}/outputs/cluster-values.yaml"
  content = templatefile("${path.module}/templates/cluster-values.yaml.tpl", {
    cluster_name               = module.gke_cluster.cluster_name
    ingress_ip                 = module.network.ingress_ip_address
    loki_bucket                = module.gcs_buckets.loki_bucket_name
    mimir_bucket               = module.gcs_buckets.mimir_bucket_name
    loki_service_account       = module.gke_cluster.loki_service_account_email
    mimir_service_account      = module.gke_cluster.mimir_service_account_email
    cert_manager_service_account = module.gke_cluster.cert_manager_service_account_email
    grafana_domain             = "grafana.${var.domain_name}"
    argocd_domain              = "argocd.${var.domain_name}"
  })
}