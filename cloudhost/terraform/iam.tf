# ==============================================================================
# AWS IAM Configuration (Least Privilege Role & Instance Profile for EC2)
# ==============================================================================

# 1. EC2 Assume Role Trust Policy
data "aws_iam_policy_document" "ec2_trust" {
  statement {
    effect  = "Allow"
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# 2. IAM Role for CloudHost EC2 Server
resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role-${var.environment}"
  assume_role_policy = data.aws_iam_policy_document.ec2_trust.json

  tags = {
    Name = "${var.project_name}-ec2-role-${var.environment}"
  }
}

# 3. Least-Privilege S3 Access Policy
resource "aws_iam_policy" "s3_access" {
  name        = "${var.project_name}-s3-policy-${var.environment}"
  description = "Grants least-privilege S3 operations strictly for the CloudHost bucket"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "ListCloudHostBucket"
        Effect = "Allow"
        Action = [
          "s3:ListBucket",
          "s3:GetBucketLocation"
        ]
        Resource = [
          aws_s3_bucket.storage.arn
        ]
      },
      {
        Sid    = "ManageCloudHostObjects"
        Effect = "Allow"
        Action = [
          "s3:PutObject",
          "s3:GetObject",
          "s3:DeleteObject"
        ]
        Resource = [
          "${aws_s3_bucket.storage.arn}/*"
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "s3_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.s3_access.arn
}

# 4. Least-Privilege DynamoDB Access Policy
resource "aws_iam_policy" "dynamodb_access" {
  name        = "${var.project_name}-dynamodb-policy-${var.environment}"
  description = "Allows EC2 instance to perform CRUD operations on the CloudHost DynamoDB table"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "DynamoDBTableAccess"
        Effect = "Allow"
        Action = [
          "dynamodb:PutItem",
          "dynamodb:GetItem",
          "dynamodb:DeleteItem",
          "dynamodb:Scan",
          "dynamodb:Query",
          "dynamodb:UpdateItem",
          "dynamodb:DescribeTable"
        ]
        Resource = [
          aws_dynamodb_table.files.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "dynamodb_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.dynamodb_access.arn
}

# 5. Security Parameter: Read-Only Lambda Policy for Application Health Checks
resource "aws_iam_policy" "lambda_read" {
  name        = "${var.project_name}-lambda-read-policy-${var.environment}"
  description = "Allows EC2 application to verify Lambda health without invoke permissions"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "LambdaConfigRead"
        Effect = "Allow"
        Action = [
          "lambda:GetFunctionConfiguration"
        ]
        Resource = [
          aws_lambda_function.processor.arn
        ]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_read_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.lambda_read.arn
}

# 6. AWS Systems Manager (SSM) Core Policy Attachment
resource "aws_iam_role_policy_attachment" "ssm_attach" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

# 7. IAM Instance Profile for EC2 Instance
resource "aws_iam_instance_profile" "ec2_profile" {
  name = "${var.project_name}-ec2-instance-profile-${var.environment}"
  role = aws_iam_role.ec2_role.name
}
