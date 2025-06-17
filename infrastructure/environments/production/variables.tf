# infrastructure/environments/production/variables.tf

# Project Configuration
variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "lgtm-stack"
}

variable "region" {
  description = "GCP region for regional resources"
  type        = string
  default     = "us-central1"
}

variable "zone" {
  description = "GCP zone for zonal resources"
  type        = string
  default     = "us-central1-a"
}

# Network Configuration
variable "gke_subnet_cidr" {
  description = "CIDR range for GKE nodes subnet"
  type        = string
  default     = "10.0.0.0/24"
}

variable "gke_pods_cidr" {
  description = "CIDR range for GKE pods (secondary range)"
  type        = string
  default     = "10.1.0.0/16"
}

variable "gke_services_cidr" {
  description = "CIDR range for GKE services (secondary range)"
  type        = string
  default     = "10.2.0.0/20"
}

# GKE Configuration
variable "initial_node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 2
}

variable "min_node_count" {
  description = "Minimum number of nodes in the node pool"
  type        = number
  default     = 1
}

variable "max_node_count" {
  description = "Maximum number of nodes in the node pool"
  type        = number
  default     = 4
}

variable "machine_type" {
  description = "Machine type for GKE nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB for GKE nodes"
  type        = number
  default     = 100
}

variable "preemptible_nodes" {
  description = "Use preemptible nodes for cost savings"
  type        = bool
  default     = false
}

variable "authorized_networks" {
  description = "List of networks authorized to access the master endpoint"
  type = list(object({
    cidr_block   = string
    display_name = string
  }))
  default = [
    {
      cidr_block   = "0.0.0.0/0"
      display_name = "all-networks"
    }
  ]
}

# Storage Configuration
variable "gcs_location" {
  description = "Location for GCS buckets"
  type        = string
  default     = "US"
}

variable "loki_retention_days" {
  description = "Retention period in days for Loki data (0 = no retention policy)"
  type        = number
  default     = 30
}

variable "mimir_retention_days" {
  description = "Retention period in days for Mimir data (0 = no retention policy)"
  type        = number
  default     = 90
}

# LGTM Configuration
variable "lgtm_namespace" {
  description = "Kubernetes namespace for LGTM stack"
  type        = string
  default     = "lgtm"
}

# DNS Configuration
variable "create_dns_zone" {
  description = "Create a new DNS zone (set to false if zone already exists)"
  type        = bool
  default     = false
}

variable "domain_name" {
  description = "Base domain name for services"
  type        = string
}