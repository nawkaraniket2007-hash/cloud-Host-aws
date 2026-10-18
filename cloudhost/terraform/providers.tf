# ==============================================================================
# AWS Provider Configuration
# ==============================================================================

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
      Course      = "BTech-CSE-CloudComputingLab"
    }
  }
}

provider "random" {}
