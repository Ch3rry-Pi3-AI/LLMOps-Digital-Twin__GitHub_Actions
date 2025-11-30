# ------------------------------------------------------------
# 🔧 Terraform Configuration
# ------------------------------------------------------------
terraform {
  # Require Terraform version 1.0 or higher
  required_version = ">= 1.0"

  # Declare required providers
  required_providers {
    aws = {
      # Use the official HashiCorp AWS provider
      source  = "hashicorp/aws"

      # Allow versions in the 6.x range
      version = "~> 6.0"
    }
  }
}

# ------------------------------------------------------------
# 🌍 Default AWS Provider (uses AWS CLI config)
# ------------------------------------------------------------
provider "aws" {
  # No region set here — inherits from:
  # ~/.aws/config or environment variables
}

# ------------------------------------------------------------
# 🌎 Additional AWS Provider (explicit region)
# ------------------------------------------------------------
provider "aws" {
  # Alias for multi-region deployments
  alias = "us_east_1"

  # Explicit region for targeted resources
  region = "us-east-1"
}
