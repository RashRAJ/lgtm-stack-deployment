variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "location" {
  description = "The location for the storage buckets"
  type        = string
  default     = "US"
}

variable "storage_class" {
  description = "Storage class for the buckets"
  type        = string
  default     = "STANDARD"
  validation {
    condition     = contains(["STANDARD", "NEARLINE", "COLDLINE", "ARCHIVE"], var.storage_class)
    error_message = "Storage class must be one of: STANDARD, NEARLINE, COLDLINE, ARCHIVE"
  }
}

variable "force_destroy" {
  description = "Allow terraform to destroy buckets with content"
  type        = bool
  default     = true
}

variable "enable_versioning" {
  description = "Enable versioning for the buckets"
  type        = bool
  default     = false
}

variable "enable_lifecycle_rules" {
  description = "Enable lifecycle rules for automatic storage class transitions"
  type        = bool
  default     = true
}

# Loki specific variables
variable "loki_retention_days" {
  description = "Retention period in days for Loki data (0 = no retention policy)"
  type        = number
  default     = 0
}

variable "loki_lifecycle_age_days" {
  description = "Number of days before transitioning Loki data to NEARLINE storage"
  type        = number
  default     = 30
}

variable "loki_service_account_email" {
  description = "Email of the Loki service account"
  type        = string
}

# Mimir specific variables
variable "mimir_retention_days" {
  description = "Retention period in days for Mimir data (0 = no retention policy)"
  type        = number
  default     = 0
}

variable "mimir_lifecycle_age_days" {
  description = "Number of days before transitioning Mimir data to NEARLINE storage"
  type        = number
  default     = 90
}

variable "mimir_service_account_email" {
  description = "Email of the Mimir service account"
  type        = string
}

# Grafana backup bucket
variable "create_grafana_backup_bucket" {
  description = "Create a bucket for Grafana dashboard backups"
  type        = bool
  default     = true
}

# Labels
variable "common_labels" {
  description = "Common labels to apply to all buckets"
  type        = map(string)
  default = {
    managed_by = "terraform"
    stack      = "lgtm"
  }
}