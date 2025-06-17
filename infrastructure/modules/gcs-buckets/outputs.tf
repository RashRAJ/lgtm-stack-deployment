output "loki_bucket_name" {
  description = "Name of the Loki storage bucket"
  value       = google_storage_bucket.loki.name
}

output "loki_bucket_url" {
  description = "URL of the Loki storage bucket"
  value       = google_storage_bucket.loki.url
}

output "mimir_bucket_name" {
  description = "Name of the Mimir storage bucket"
  value       = google_storage_bucket.mimir.name
}

output "mimir_bucket_url" {
  description = "URL of the Mimir storage bucket"
  value       = google_storage_bucket.mimir.url
}

output "grafana_backup_bucket_name" {
  description = "Name of the Grafana backup bucket"
  value       = var.create_grafana_backup_bucket ? google_storage_bucket.grafana_backup[0].name : null
}

output "grafana_backup_bucket_url" {
  description = "URL of the Grafana backup bucket"
  value       = var.create_grafana_backup_bucket ? google_storage_bucket.grafana_backup[0].url : null
}

output "bucket_suffix" {
  description = "Random suffix used for bucket naming"
  value       = random_id.bucket_suffix.hex
}