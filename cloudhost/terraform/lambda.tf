# ==============================================================================
# AWS Lambda Serverless Event Processor & S3 Notification Trigger
# ==============================================================================

# 1. Lambda Assume Role Policy Document
data "aws_iam_policy_document" "lambda_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }
  }
}

# 2. IAM Role for Lambda Processor
resource "aws_iam_role" "lambda_exec" {
  name               = "${var.project_name}-lambda-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.lambda_trust.json

  tags = {
    Name = "${var.project_name}-lambda-role-${var.environment}"
  }
}

# 3. Least-Privilege IAM Policy for Lambda Execution
resource "aws_iam_policy" "lambda_policy" {
  name        = "${var.project_name}-lambda-policy-${var.environment}"
  description = "Allows Lambda to log to CloudWatch, read S3 objects, and update DynamoDB items"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "CloudWatchLogsAccess"
        Effect = "Allow"
        Action = [
          "logs:CreateLogGroup",
          "logs:CreateLogStream",
          "logs:PutLogEvents"
        ]
        Resource = "arn:aws:logs:*:*:*"
      },
      {
        Sid    = "S3ReadOnlyAccess"
        Effect = "Allow"
        Action = [
          "s3:GetObject",
          "s3:GetObjectVersion"
        ]
        Resource = "${aws_s3_bucket.storage.arn}/uploads/*"
      },
      {
        Sid    = "DynamoDBUpdateAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:UpdateItem",
          "dynamodb:GetItem",
          "dynamodb:Scan"
        ]
        Resource = aws_dynamodb_table.files.arn
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_attach" {
  role       = aws_iam_role.lambda_exec.name
  policy_arn = aws_iam_policy.lambda_policy.arn
}

# 4. CloudWatch Log Group with 7-Day Log Retention
resource "aws_cloudwatch_log_group" "lambda_logs" {
  name              = "/aws/lambda/${var.project_name}-processor-${var.environment}"
  retention_in_days = 7

  tags = {
    Name = "${var.project_name}-lambda-logs-${var.environment}"
  }
}

# 5. AWS Lambda Function
resource "aws_lambda_function" "processor" {
  function_name    = "${var.project_name}-processor-${var.environment}"
  description      = "Asynchronous integrity processor computing SHA-256 for uploaded files"
  filename         = "${path.module}/../lambda/processor.zip"
  source_code_hash = filebase64sha256("${path.module}/../lambda/processor.zip")
  runtime          = "python3.12"
  handler          = "processor.lambda_handler"
  role             = aws_iam_role.lambda_exec.arn
  timeout          = 30
  memory_size      = 128

  environment {
    variables = {
      DYNAMODB_TABLE_NAME = aws_dynamodb_table.files.name
    }
  }

  depends_on = [
    aws_iam_role_policy_attachment.lambda_attach,
    aws_cloudwatch_log_group.lambda_logs
  ]

  tags = {
    Name = "${var.project_name}-processor-${var.environment}"
  }
}

# 6. Lambda Permission: Allow Amazon S3 to invoke function
resource "aws_lambda_permission" "s3_invoke" {
  statement_id  = "AllowS3Invocation"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.processor.function_name
  principal     = "s3.amazonaws.com"
  source_arn    = aws_s3_bucket.storage.arn
}

# 7. S3 Bucket Event Notification: Trigger Lambda upon ObjectCreated in uploads/
resource "aws_s3_bucket_notification" "bucket_notification" {
  bucket = aws_s3_bucket.storage.id

  lambda_function {
    lambda_function_arn = aws_lambda_function.processor.arn
    events              = ["s3:ObjectCreated:*"]
    filter_prefix       = "uploads/"
  }

  depends_on = [
    aws_lambda_permission.s3_invoke
  ]
}
