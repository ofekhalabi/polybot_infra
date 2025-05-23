variable "control_plane_instance_id" {
  description = "ID of the Kubernetes control plane EC2 instance"
  type        = string
}

variable "secret_name" {
  description = "Name of the secret in AWS Secrets Manager"
  type        = string
  default     = "k8s-worker-join-command"
}

variable "lambda_function_name" {
  description = "Name of the Lambda function"
  type        = string
  default     = "k8s-token-manager"
}

variable "schedule_expression" {
  description = "EventBridge schedule expression for Lambda trigger"
  type        = string
  default     = "rate(8 hours)"
}

variable "lambda_timeout" {
  description = "Lambda function timeout in seconds"
  type        = number
  default     = 300  # 5 minutes
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
} 