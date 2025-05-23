# Create AWS Secrets Manager secret
resource "aws_secretsmanager_secret" "join_command" {
  name = var.secret_manager_name
  tags = var.tags
}

# Create IAM role for Lambda
resource "aws_iam_role" "lambda_role" {
  name = "${var.lambda_function_name}-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })

  tags = var.tags
}

# Create IAM policy for Lambda ansd attach to role
resource "aws_iam_role_policy" "lambda_policy" {
  name = "${var.lambda_function_name}-policy"
  role = aws_iam_role.lambda_role.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ssm:SendCommand",
          "ssm:GetCommandInvocation"
        ]
        Resource = [
          "arn:aws:ssm:*:*:document/AWS-RunShellScript",
          "arn:aws:ec2:*:*:instance/${var.control_plane_instance_id}"
        ]
      },
      {
        Effect = "Allow"
        Action = [
          "secretsmanager:PutSecretValue",
          "secretsmanager:UpdateSecret"
        ]
        Resource = [aws_secretsmanager_secret.join_command.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = ["arn:aws:logs:*:*:*"]
      }
    ]
  })
}

# Create Lambda function
data "archive_file" "lambda_zip" {
  type        = "zip"
  source_file = "${path.module}/lambda/token_manager.py"
  output_path = "${path.module}/lambda/token_manager.zip"
}

resource "aws_lambda_function" "token_manager" {
  filename         = data.archive_file.lambda_zip.output_path
  function_name    = var.lambda_function_name
  role             = aws_iam_role.lambda_role.arn
  handler          = "token_manager.lambda_handler"
  source_code_hash = data.archive_file.lambda_zip.output_base64sha256
  runtime          = "python3.9"
  timeout          = var.lambda_timeout

  environment {
    variables = {
      CONTROL_PLANE_INSTANCE_ID = var.control_plane_instance_id
      SECRET_MANAGER_NAME       = aws_secretsmanager_secret.join_command.name
    }
  }

  tags = var.tags
}

# Create EventBridge rule
resource "aws_cloudwatch_event_rule" "schedule" {
  name                = "${var.lambda_function_name}-schedule"
  description         = "Schedule for running token manager Lambda function"
  schedule_expression = var.schedule_expression
  tags                = var.tags
}

# Create EventBridge target for Lambda function
resource "aws_cloudwatch_event_target" "lambda" {
  rule      = aws_cloudwatch_event_rule.schedule.name
  target_id = "TokenManagerLambda"
  arn       = aws_lambda_function.token_manager.arn
}


resource "aws_lambda_permission" "allow_eventbridge" {
  statement_id  = "AllowEventBridgeInvoke"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.token_manager.function_name
  principal     = "events.amazonaws.com"
  source_arn    = aws_cloudwatch_event_rule.schedule.arn
}

# Modify control plane instance role to allow SSM
resource "aws_iam_role_policy_attachment" "ssm_policy" {
  role       = var.control_plane_role_name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
} 