output "secret_arn" {
  description = "ARN of the Secrets Manager secret containing the join command"
  value       = aws_secretsmanager_secret.join_command.arn
}

output "lambda_function_arn" {
  description = "ARN of the Lambda function"
  value       = aws_lambda_function.token_manager.arn
}

output "lambda_function_name" {
  description = "Name of the Lambda function"
  value       = aws_lambda_function.token_manager.function_name
}

output "eventbridge_rule_arn" {
  description = "ARN of the EventBridge rule"
  value       = aws_cloudwatch_event_rule.schedule.arn
} 