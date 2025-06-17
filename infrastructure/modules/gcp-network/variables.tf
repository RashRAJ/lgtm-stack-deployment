variable "project_name" {
  description = "Name of the project, used for resource naming"
  type        = string
  default     = "lgtm-stack"
}

variable "vpc_name" {
  description = "Name of the VPC network"
  type        = string
  default     = "lgtm-vpc"
}

variable "region" {
  description = "GCP region for resources"
  type        = string
  default     = "us-central1"
}

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

variable "enable_flow_logs" {
  description = "Enable VPC flow logs for the subnet"
  type        = bool
  default     = true
}

variable "additional_firewall_rules" {
  description = "Additional firewall rules to create"
  type = list(object({
    name          = string
    direction     = string
    priority      = number
    source_ranges = list(string)
    target_tags   = list(string)
    allow = list(object({
      protocol = string
      ports    = list(string)
    }))
  }))
  default = []
}