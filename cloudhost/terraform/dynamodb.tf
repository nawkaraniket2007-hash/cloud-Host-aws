# ==============================================================================
# Amazon DynamoDB Table Configuration (Encrypted, On-Demand NoSQL Metadata Store)
# ==============================================================================

resource "aws_dynamodb_table" "files" {
  name         = "${var.project_name}-files-${var.environment}"
  billing_mode = "PAY_PER_REQUEST" # On-demand, serverless pricing
  hash_key     = "file_id"

  attribute {
    name = "file_id"
    type = "S"
  }

  # Security Parameter: Enable Encryption at Rest
  server_side_encryption {
    enabled = true
  }

  point_in_time_recovery {
    enabled = false
  }

  tags = {
    Name = "${var.project_name}-dynamodb-files-${var.environment}"
  }
}
