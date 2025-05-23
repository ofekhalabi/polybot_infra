output "control_plane_public_ip" {
  description = "Public IP address of the Kubernetes control plane"
  value       = aws_instance.control_plane.public_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane"
  value       = aws_instance.control_plane.private_ip
}

output "vpc_id" {
  description = "ID of the VPC"
  value       = module.polybot-vpc.vpc_id
}

output "public_subnet_ids" {
  description = "IDs of the public subnets"
  value       = module.polybot-vpc.public_subnets
}

output "worker_security_group_id" {
  description = "ID of the worker nodes security group"
  value       = aws_security_group.worker.id
}

output "control_plane_security_group_id" {
  description = "ID of the control plane security group"
  value       = aws_security_group.control_plane.id
}

output "vpc_cidr_block" {
  description = "CIDR block of the VPC"
  value       = module.polybot-vpc.vpc_cidr_block
}

output "public_subnet_cidr_blocks" {
  description = "CIDR blocks of the public subnets"
  value       = module.polybot-vpc.public_subnets_cidr_blocks
}

output "alb_dns_name" {
  description = "DNS name of the Application Load Balancer"
  value       = aws_lb.main.dns_name
}

output "alb_zone_id" {
  description = "Route 53 zone ID of the Application Load Balancer"
  value       = aws_lb.main.zone_id
}

output "alb_target_group_arn" {
  description = "ARN of the ALB target group"
  value       = aws_lb_target_group.polybot-tg.arn
}

output "alb_security_group_id" {
  description = "ID of the ALB security group"
  value       = aws_security_group.alb.id
}

output "control_plane_instance_id" {
  description = "ID of the Kubernetes control plane EC2 instance"
  value       = aws_instance.control_plane.id
}

output "worker_role_name" {
  description = "Name of the worker node IAM role"
  value       = aws_iam_role.worker_node_role.name
}

output "worker_role_arn" {
  description = "ARN of the worker node IAM role"
  value       = aws_iam_role.worker_node_role.arn
}

output "worker_instance_profile_arn" {
  description = "ARN of the worker node instance profile"
  value       = aws_iam_instance_profile.worker_node_profile.arn
}

output "worker_instance_profile_name" {
  description = "Name of the worker node instance profile"
  value       = aws_iam_instance_profile.worker_node_profile.name
}

output "control_plane_role_name" {
  description = "Name of the control plane IAM role"
  value       = aws_iam_role.control_plane_role.name
}

output "control_plane_role_arn" {
  description = "ARN of the control plane IAM role"
  value       = aws_iam_role.control_plane_role.arn
}

output "control_plane_instance_profile_arn" {
  description = "ARN of the control plane instance profile"
  value       = aws_iam_instance_profile.control_plane_profile.arn
}

output "control_plane_instance_profile_name" {
  description = "Name of the control plane instance profile"
  value       = aws_iam_instance_profile.control_plane_profile.name
}
