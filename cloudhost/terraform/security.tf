# ==============================================================================
# Security Group Configurations (Least-Privilege Defense-in-Depth)
# ==============================================================================

# EC2 Security Group: Allows HTTP ingress and restricted SSH
resource "aws_security_group" "ec2" {
  name        = "${var.project_name}-ec2-sg-${var.environment}"
  description = "Controls ingress and egress traffic for the CloudHost EC2 application server"
  vpc_id      = aws_vpc.main.id

  # Inbound HTTP (Port 80) from anywhere for public website access
  ingress {
    description = "Allow inbound HTTP web traffic"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Inbound SSH (Port 22) restricted strictly to trusted Administrator IP
  ingress {
    description = "Allow inbound SSH strictly from trusted admin IP"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.admin_ip]
  }

  # Outbound access to internet (required for apt packages, AWS API endpoints for S3 & DynamoDB)
  egress {
    description = "Allow all outbound traffic for package management and AWS API calls"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "${var.project_name}-ec2-sg-${var.environment}"
  }
}
