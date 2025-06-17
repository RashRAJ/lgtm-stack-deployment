# Cluster Information
output "cluster_name" {
  description = "Name of the GKE cluster"
  value       = module.gke_cluster.cluster_name
}

output "cluster_endpoint" {
  description = "Endpoint for the GKE cluster"
  value       = module.gke_cluster.cluster_endpoint
  sensitive   = true
}

output "cluster_location" {
  description = "Location of the GKE cluster"
  value       = module.gke_cluster.cluster_location
}

output "kubectl_command" {
  description = "Command to configure kubectl"
  value       = module.gke_cluster.kubectl_config_command
}

# Network Information
output "vpc_name" {
  description = "Name of the VPC"
  value       = module.network.vpc_name
}

output "ingress_ip" {
  description = "Static IP address for ingress"
  value       = module.network.ingress_ip_address
}

# Storage Information
output "loki_bucket" {
  description = "Name of the Loki storage bucket"
  value       = module.gcs_buckets.loki_bucket_name
}

output "mimir_bucket" {
  description = "Name of the Mimir storage bucket"
  value       = module.gcs_buckets.mimir_bucket_name
}

output "grafana_backup_bucket" {
  description = "Name of the Grafana backup bucket"
  value       = module.gcs_buckets.grafana_backup_bucket_name
}

# Service Account Information
output "loki_service_account" {
  description = "Email of the Loki service account"
  value       = module.gke_cluster.loki_service_account_email
}

output "mimir_service_account" {
  description = "Email of the Mimir service account"
  value       = module.gke_cluster.mimir_service_account_email
}

output "cert_manager_service_account" {
  description = "Email of the cert-manager service account"
  value       = module.gke_cluster.cert_manager_service_account_email
}

# DNS Information
output "dns_zone_name" {
  description = "Name of the DNS zone"
  value       = var.create_dns_zone ? google_dns_managed_zone.main[0].name : "existing-zone"
}

output "grafana_url" {
  description = "URL for Grafana"
  value       = "https://grafana.${var.domain_name}"
}

output "argocd_url" {
  description = "URL for ArgoCD"
  value       = "https://argocd.${var.domain_name}"
}

# Summary output for easy reference
output "deployment_summary" {
  description = "Summary of the deployment"
  value = <<-EOT
    LGTM Stack Deployment Summary
    ============================
    
    Cluster: ${module.gke_cluster.cluster_name}
    Region: ${module.gke_cluster.cluster_location}
    
    Access URLs:
    - Grafana: https://grafana.${var.domain_name}
    - ArgoCD: https://argocd.${var.domain_name}
    
    Storage Buckets:
    - Loki: ${module.gcs_buckets.loki_bucket_name}
    - Mimir: ${module.gcs_buckets.mimir_bucket_name}
    
    Configure kubectl:
    ${module.gke_cluster.kubectl_config_command}
    
    Next Steps:
    1. Configure kubectl using the command above
    2. Bootstrap ArgoCD: kubectl apply -k kubernetes/bootstrap/
    3. Apply App-of-Apps: kubectl apply -f kubernetes/applications/app-of-apps.yaml
  EOT
}