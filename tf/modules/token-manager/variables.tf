variable "control_plane_instance_id" {
  description = "ID of the Kubernetes control plane EC2 instance"
  type        = string
}

variable "secret_manager_name" {
  description = "Name of the AWS Secrets Manager secret"
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
  default     = 300 # 5 minutes
}

variable "tags" {
  description = "Tags to apply to resources"
  type        = map(string)
  default     = {}
}

variable "key_name" {
  description = "Name of the key pair to use for the EC2 instance"
  type        = string
  default     = "ofekh-tf-key"
}

variable "control_plane_role_name" {
  description = "IAM role for the control plane EC2 instance"
  type        = string
}