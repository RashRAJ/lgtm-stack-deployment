output "vpc_id" {
  description = "The ID of the VPC"
  value       = google_compute_network.vpc.id
}

output "vpc_name" {
  description = "The name of the VPC"
  value       = google_compute_network.vpc.name
}

output "vpc_self_link" {
  description = "The URI of the VPC"
  value       = google_compute_network.vpc.self_link
}

output "subnet_name" {
  description = "Name of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.name
}

output "subnet_id" {
  description = "ID of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.id
}

output "subnet_self_link" {
  description = "The URI of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.self_link
}

output "subnet_cidr" {
  description = "CIDR range of the GKE subnet"
  value       = google_compute_subnetwork.gke_subnet.ip_cidr_range
}

output "pods_range_name" {
  description = "Name of the secondary range for pods"
  value       = google_compute_subnetwork.gke_subnet.secondary_ip_range[0].range_name
}

output "services_range_name" {
  description = "Name of the secondary range for services"
  value       = google_compute_subnetwork.gke_subnet.secondary_ip_range[1].range_name
}

output "router_name" {
  description = "Name of the Cloud Router"
  value       = google_compute_router.router.name
}

output "nat_name" {
  description = "Name of the Cloud NAT"
  value       = google_compute_router_nat.nat.name
}

output "ingress_ip_address" {
  description = "Static IP address reserved for ingress"
  value       = google_compute_global_address.ingress_ip.address
}

output "ingress_ip_name" {
  description = "Name of the static IP address resource"
  value       = google_compute_global_address.ingress_ip.name
}