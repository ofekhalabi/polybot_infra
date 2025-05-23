variable "aws_region" {
    description = "AWS region"
    type        = string
    default     = "eu-north-1"
}

variable "cluster_name" {
    description = "Name of the Kubernetes cluster"
    type        = string
    default     = "ofekh-polybot-cluster"
}

variable "environment" {
    description = "Environment name"
    type        = string
    default     = "dev"
}

variable "sqs_queue_name" {
    description = "Name of the SQS queue"
    type        = string
    default     = "ofekh-polybot-sqs-queue"
}

variable "s3_bucket_name" {
    description = "Name of the S3 bucket"
    type        = string
    default     = "ofekh-polybot-s3-bucket"
}

variable "secret_name_prefix" {
    description = "Prefix for secret names"
    type        = string
    default     = "k8s"
}

variable "key_name" {
    description = "Name of the AWS key pair to use for EC2 instances"
    type        = string
}

