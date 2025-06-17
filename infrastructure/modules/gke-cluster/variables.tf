# modules/gke-cluster/variables.tf

variable "project_id" {
  description = "The GCP project ID"
  type        = string
}

variable "cluster_name" {
  description = "Name of the GKE cluster"
  type        = string
  default     = "lgtm-cluster"
}

variable "zone" {
  description = "The zone for the zonal cluster"
  type        = string
  default     = "us-central1-a"
}

variable "environment" {
  description = "Environment name (e.g., production, staging)"
  type        = string
  default     = "production"
}

# Network configuration
variable "network_name" {
  description = "Name of the VPC network"
  type        = string
}

variable "subnet_name" {
  description = "Name of the subnet"
  type        = string
}

variable "pods_range_name" {
  description = "Name of the secondary range for pods"
  type        = string
}

variable "services_range_name" {
  description = "Name of the secondary range for services"
  type        = string
}

variable "master_cidr" {
  description = "CIDR block for the master nodes"
  type        = string
  default     = "172.16.0.0/28"
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
      display_name = "all"
    }
  ]
}

# Node pool configuration
variable "initial_node_count" {
  description = "Initial number of nodes in the node pool"
  type        = number
  default     = 1
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
  description = "Machine type for the nodes"
  type        = string
  default     = "e2-standard-4"
}

variable "disk_size_gb" {
  description = "Disk size in GB for the nodes"
  type        = number
  default     = 100
}

variable "preemptible_nodes" {
  description = "Use preemptible nodes"
  type        = bool
  default     = false
}

variable "node_service_account" {
  description = "Service account to be used by the nodes"
  type        = string
  default     = ""
}

# Labels and tags
variable "cluster_labels" {
  description = "Labels to apply to the cluster"
  type        = map(string)
  default     = {}
}

variable "node_labels" {
  description = "Labels to apply to the nodes"
  type        = map(string)
  default     = {}
}

variable "node_tags" {
  description = "Network tags to apply to the nodes"
  type        = list(string)
  default     = []
}

# Workload Identity
variable "lgtm_namespace" {
  description = "Kubernetes namespace for LGTM stack"
  type        = string
  default     = "lgtm"
}

variable "enable_cert_manager_sa" {
  description = "Create service account for cert-manager"
  type        = bool
  default     = true
}

variable "enable_external_dns_sa" {
  description = "Create service account for external-dns"
  type        = bool
  default     = false
}