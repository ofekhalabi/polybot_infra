terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.55"
    }
  }

  required_version = ">= 1.7.0"

  # Configure the backend to store the state file in S3
  backend "s3" {
    bucket = "ofekh-polybot-tfstate"
    key    = "env/${var.region}/terraform.tfstate"
    region = "eu-north-1"
  }
}

provider "aws" {
  region = var.aws_region
}

module "k8s_cluster" {
  source = "./modules/k8s-cluster"

  region       = var.aws_region
  cluster_name = var.cluster_name
  key_name     = var.key_name
  # Add other required variables
}

module "token_manager" {
  source = "./modules/token-manager"

  control_plane_instance_id = module.k8s_cluster.control_plane_instance_id
  control_plane_role_name   = module.k8s_cluster.control_plane_role_name
  lambda_function_name      = "${var.cluster_name}-token-manager"

  tags = {
    Terraform   = "true"
    Environment = var.environment
    Cluster     = var.cluster_name
  }

  depends_on = [module.k8s_cluster]
}

