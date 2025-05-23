output "control_plane_public_ip" {
  description = "Public IP address of the Kubernetes control plane"
  value       = module.k8s_cluster.control_plane_public_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane"
  value       = module.k8s_cluster.control_plane_private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.k8s_cluster.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.k8s_cluster.public_subnet_ids
}

# Add outputs from polybot module if needed
