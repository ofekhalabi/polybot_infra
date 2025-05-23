variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "cluster_name" {
  description = "Name of the Kubernetes cluster"
  type        = string
  default     = "ofekh-polybot-cluster"
}

variable "control_plane_instance_type" {
  description = "Instance type for the control plane"
  type        = string
  default     = "t3.medium"
}

variable "worker_instance_type" {
  description = "Instance type for worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "worker_desired_capacity" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "worker_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "worker_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "ebs_volume_size" {
  description = "Size of the EBS volume in GB"
  type        = number
  default     = 30
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "vpc_public_subnets" {
  description = "Public subnets for VPC"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "vpc_private_subnets" {
  description = "Private subnets for VPC"
  type        = list(string)
  default     = ["10.0.3.0/24", "10.0.4.0/24"]
}

variable "vpc_tags" {
  description = "Tags to apply to VPC resources"
  type        = map(string)
  default     = {}
}

variable "kubernetes_version" {
  description = "Kubernetes version to install"
  type        = string
  default     = "v1.32"
}

variable "kubeadm_token" {
  description = "Token for kubeadm join command"
  type        = string
  default     = ""  # Will be generated if not provided
}

variable "kubeadm_token_hash" {
  description = "Token hash for kubeadm join command"
  type        = string
  default     = ""  # Will be generated if not provided
}

variable "lambda_runtime" {
  description = "Runtime for Lambda function"
  type        = string
  default     = "python3.9"
}

variable "alb_health_check_path" {
  description = "Health check path for the ALB target group"
  type        = string
  default     = "/"
}

variable "alb_health_check_port" {
  description = "Port for ALB health checks"
  type        = number
  default     = 80
}

variable "alb_health_check_interval" {
  description = "Interval between health checks (seconds)"
  type        = number
  default     = 30
}

variable "alb_health_check_timeout" {
  description = "Timeout for health checks (seconds)"
  type        = number
  default     = 5
}

variable "alb_health_check_healthy_threshold" {
  description = "Number of consecutive successful health checks required"
  type        = number
  default     = 2
}

variable "alb_health_check_unhealthy_threshold" {
  description = "Number of consecutive failed health checks required"
  type        = number
  default     = 2
}

variable "key_name" {
  description = "Name of the AWS key pair to use for instances"
  type        = string
  default     = "ofekh-tf-key"
}

variable "worker_role_name" {
  description = "Name of the IAM role for worker nodes"
  type        = string
  default     = "ofekh-polybot-worker-node-role"
}

variable "control_plane_role_name" {
  description = "Name of the IAM role for control plane"
  type        = string
  default     = "ofekh-polybot-control-plane-role"
}
