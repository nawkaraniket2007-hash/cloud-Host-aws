# ==============================================================================
# Terraform Outputs (No Secrets or Passwords Exposed)
# ==============================================================================

output "website_url" {
  description = "Public HTTP URL to access the CloudHost web portal"
  value       = "http://${aws_instance.web.public_ip}"
}

output "website_dns_url" {
  description = "Public DNS URL to access the CloudHost web portal"
  value       = aws_instance.web.public_dns != "" ? "http://${aws_instance.web.public_dns}" : "http://${aws_instance.web.public_ip}"
}

output "ec2_public_ip" {
  description = "Public IPv4 address of the EC2 application host"
  value       = aws_instance.web.public_ip
}

output "ec2_instance_id" {
  description = "AWS EC2 Instance Identifier"
  value       = aws_instance.web.id
}

output "s3_bucket_name" {
  description = "Name of the dedicated Amazon S3 bucket used for object storage"
  value       = aws_s3_bucket.storage.id
}

output "dynamodb_table_name" {
  description = "Name of the Amazon DynamoDB table used for file metadata"
  value       = aws_dynamodb_table.files.name
}

output "lambda_function_name" {
  description = "Name of the AWS Lambda asynchronous security & integrity processor"
  value       = aws_lambda_function.processor.function_name
}

output "lambda_function_arn" {
  description = "ARN of the AWS Lambda asynchronous processor"
  value       = aws_lambda_function.processor.arn
}

output "ssm_session_manager_command" {
  description = "AWS CLI command to connect securely to the EC2 server without open SSH ports"
  value       = "aws ssm start-session --target ${aws_instance.web.id} --region ${var.aws_region}"
}
