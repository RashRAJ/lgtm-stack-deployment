# GCP Network Module

This module creates a custom VPC network with the necessary configuration for running a private GKE cluster.

## Features

- Custom VPC with configurable CIDR ranges
- Subnet with secondary ranges for GKE pods and services
- Cloud NAT for outbound internet access from private nodes
- Cloud Router for NAT functionality
- Firewall rules for health checks and internal communication
- Static IP reservation for ingress

## Usage

```hcl
module "network" {
  source = "../../modules/gcp-network"

  project_name      = "my-project"
  vpc_name          = "my-vpc"
  region            = "us-central1"
  gke_subnet_cidr   = "10.0.0.0/24"
  gke_pods_cidr     = "10.1.0.0/16"
  gke_services_cidr = "10.2.0.0/20"
}
```

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|----------|
| project_name | Name of the project, used for resource naming | string | "lgtm-stack" | no |
| vpc_name | Name of the VPC network | string | "lgtm-vpc" | no |
| region | GCP region for resources | string | "us-central1" | no |
| gke_subnet_cidr | CIDR range for GKE nodes subnet | string | "10.0.0.0/24" | no |
| gke_pods_cidr | CIDR range for GKE pods (secondary range) | string | "10.1.0.0/16" | no |
| gke_services_cidr | CIDR range for GKE services (secondary range) | string | "10.2.0.0/20" | no |
| enable_flow_logs | Enable VPC flow logs for the subnet | bool | true | no |

## Outputs

| Name | Description |
|------|-------------|
| vpc_id | The ID of the VPC |
| vpc_name | The name of the VPC |
| subnet_name | Name of the GKE subnet |
| subnet_self_link | The URI of the GKE subnet |
| pods_range_name | Name of the secondary range for pods |
| services_range_name | Name of the secondary range for services |
| ingress_ip_address | Static IP address reserved for ingress |

## Network Architecture

The module creates:
1. A custom VPC without auto-created subnets
2. A single subnet with:
   - Primary range for GKE nodes
   - Secondary range for pods (larger CIDR)
   - Secondary range for services
3. Cloud NAT for secure outbound connectivity
4. Firewall rules allowing:
   - Google health checks
   - Internal communication between nodes, pods, and services

## Security Considerations

- All GKE nodes will be private (no public IPs)
- Outbound internet access is provided through Cloud NAT
- VPC flow logs are enabled by default for network monitoring
- Firewall rules follow the principle of least privilege