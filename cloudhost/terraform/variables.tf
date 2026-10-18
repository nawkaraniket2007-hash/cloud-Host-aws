# ==============================================================================
# Terraform Input Variables
# ==============================================================================

variable "aws_region" {
  type        = string
  description = "Target AWS region for deploying resources"
  default     = "us-east-1"
}

variable "environment" {
  type        = string
  description = "Deployment environment identifier (e.g., dev, lab, staging)"
  default     = "lab"
}

variable "project_name" {
  type        = string
  description = "Project naming prefix used for resource identification"
  default     = "cloudhost"
}

# ------------------------------------------------------------------------------
# Networking Variables
# ------------------------------------------------------------------------------
variable "vpc_cidr" {
  type        = string
  description = "CIDR block assigned to the custom project VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidr" {
  type        = string
  description = "CIDR block for the public subnet hosting the EC2 web server"
  default     = "10.0.1.0/24"
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "CIDR blocks for private subnets hosting the RDS MySQL database (must be at least 2 for RDS DB subnet group)"
  default     = ["10.0.10.0/24", "10.0.11.0/24"]

  validation {
    condition     = length(var.private_subnet_cidrs) >= 2
    error_message = "At least two private subnets in different Availability Zones are required for the RDS DB subnet group."
  }
}

variable "admin_ip" {
  type        = string
  description = "Trusted administrative CIDR block allowed to SSH into the EC2 instance (e.g., '203.0.113.25/32'). DO NOT use '0.0.0.0/0'."
  default     = "127.0.0.1/32" # Safe placeholder default; students configure their public IP in terraform.tfvars
}

# ------------------------------------------------------------------------------
# EC2 Compute Variables
# ------------------------------------------------------------------------------
variable "ec2_instance_type" {
  type        = string
  description = "EC2 instance type for the application server"
  default     = "t3.micro"
}

variable "ec2_key_name" {
  type        = string
  description = "Optional name of an existing EC2 Key Pair for SSH access (leave empty if using AWS SSM Session Manager)"
  default     = ""
}

# ------------------------------------------------------------------------------
# Amazon RDS MySQL Variables
# ------------------------------------------------------------------------------
variable "db_instance_class" {
  type        = string
  description = "RDS instance class for the MySQL database"
  default     = "db.t3.micro"
}

variable "db_name" {
  type        = string
  description = "Name of the initial MySQL database to create"
  default     = "cloudhost_db"
}

variable "db_username" {
  type        = string
  description = "Master username for the RDS MySQL database"
  default     = "cloudhost_admin"
}

variable "db_allocated_storage" {
  type        = number
  description = "Allocated storage size in Gigabytes for RDS MySQL"
  default     = 20
}

variable "db_backup_retention_period" {
  type        = number
  description = "Database backup retention period in days (set to 0 for lab environments to disable automatic automated snapshots and reduce cost)"
  default     = 0
}

variable "enable_deletion_protection" {
  type        = bool
  description = "If true, prevents the RDS database from being accidentally destroyed without updating this setting first"
  default     = false
}

# ------------------------------------------------------------------------------
# Amazon S3 Variables
# ------------------------------------------------------------------------------
variable "s3_bucket_prefix" {
  type        = string
  description = "Prefix for the dedicated Amazon S3 bucket (a random suffix will be appended to ensure global uniqueness)"
  default     = "cloudhost-storage"
}
