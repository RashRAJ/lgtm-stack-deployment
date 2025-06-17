# Generate random suffix for bucket names to ensure uniqueness
resource "random_id" "bucket_suffix" {
  byte_length = 4
}

# Loki storage bucket
resource "google_storage_bucket" "loki" {
  name          = "${var.project_id}-loki-${random_id.bucket_suffix.hex}"
  location      = var.location
  force_destroy = var.force_destroy

  # Storage class for cost optimization
  storage_class = var.storage_class

  # Retention policy
  dynamic "retention_policy" {
    for_each = var.loki_retention_days > 0 ? [1] : []
    content {
      retention_period = var.loki_retention_days * 86400 # Convert days to seconds
    }
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_rules ? [1] : []
    content {
      condition {
        age = var.loki_lifecycle_age_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_rules ? [1] : []
    content {
      condition {
        age = var.loki_lifecycle_age_days * 3
      }
      action {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
    }
  }

  # Versioning
  versioning {
    enabled = var.enable_versioning
  }

  # Uniform bucket-level access
  uniform_bucket_level_access = true

  labels = merge(
    var.common_labels,
    {
      component = "loki"
      purpose   = "logs-storage"
    }
  )
}

# Mimir storage bucket
resource "google_storage_bucket" "mimir" {
  name          = "${var.project_id}-mimir-${random_id.bucket_suffix.hex}"
  location      = var.location
  force_destroy = var.force_destroy

  storage_class = var.storage_class

  # Retention policy
  dynamic "retention_policy" {
    for_each = var.mimir_retention_days > 0 ? [1] : []
    content {
      retention_period = var.mimir_retention_days * 86400
    }
  }

  # Lifecycle rules
  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_rules ? [1] : []
    content {
      condition {
        age = var.mimir_lifecycle_age_days
      }
      action {
        type          = "SetStorageClass"
        storage_class = "NEARLINE"
      }
    }
  }

  dynamic "lifecycle_rule" {
    for_each = var.enable_lifecycle_rules ? [1] : []
    content {
      condition {
        age = var.mimir_lifecycle_age_days * 3
      }
      action {
        type          = "SetStorageClass"
        storage_class = "COLDLINE"
      }
    }
  }

  versioning {
    enabled = var.enable_versioning
  }

  uniform_bucket_level_access = true

  labels = merge(
    var.common_labels,
    {
      component = "mimir"
      purpose   = "metrics-storage"
    }
  )
}

# IAM binding for Loki service account
resource "google_storage_bucket_iam_member" "loki_bucket_access" {
  bucket = google_storage_bucket.loki.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.loki_service_account_email}"
}

# IAM binding for Mimir service account
resource "google_storage_bucket_iam_member" "mimir_bucket_access" {
  bucket = google_storage_bucket.mimir.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${var.mimir_service_account_email}"
}

# Optional: Backup bucket for Grafana dashboards and configs
resource "google_storage_bucket" "grafana_backup" {
  count = var.create_grafana_backup_bucket ? 1 : 0

  name          = "${var.project_id}-grafana-backup-${random_id.bucket_suffix.hex}"
  location      = var.location
  force_destroy = var.force_destroy

  storage_class = "STANDARD"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      num_newer_versions = 10
    }
    action {
      type = "Delete"
    }
  }

  uniform_bucket_level_access = true

  labels = merge(
    var.common_labels,
    {
      component = "grafana"
      purpose   = "backup-storage"
    }
  )
}