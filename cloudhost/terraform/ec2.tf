# ==============================================================================
# Amazon EC2 Compute Instance & Application Host Configuration
# ==============================================================================

# 1. Dynamically locate the latest official Ubuntu 22.04 LTS (Jammy) AMI
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical Official Owner ID
}

# 2. EC2 Web Server Instance
resource "aws_instance" "web" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = var.ec2_instance_type
  subnet_id                   = aws_subnet.public.id
  vpc_security_group_ids      = [aws_security_group.ec2.id]
  iam_instance_profile        = aws_iam_instance_profile.ec2_profile.name
  key_name                    = var.ec2_key_name != "" ? var.ec2_key_name : null
  associate_public_ip_address = true

  # Security Parameter: Encrypted Root EBS Volume
  root_block_device {
    volume_size           = 20
    volume_type           = "gp3"
    encrypted             = true
    delete_on_termination = true

    tags = {
      Name = "${var.project_name}-ec2-root-volume-${var.environment}"
    }
  }

  # Security Parameter: Mandatory IMDSv2 Session Token Enforcement
  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "required" # Enforce IMDSv2 strictly
    http_put_response_hop_limit = 2
  }

  user_data = templatefile("${path.module}/user_data.sh.tftpl", {
    aws_region           = var.aws_region
    s3_bucket_name       = aws_s3_bucket.storage.id
    dynamodb_table_name  = aws_dynamodb_table.files.name
    lambda_function_name = aws_lambda_function.processor.function_name
  })

  depends_on = [
    aws_dynamodb_table.files,
    aws_s3_bucket.storage,
    aws_s3_object.app_package,
    aws_lambda_function.processor
  ]

  tags = {
    Name = "${var.project_name}-web-server-${var.environment}"
  }
}
