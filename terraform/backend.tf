###############################################################################
# 🌐 Terraform Remote Backend Configuration (S3)
#
# This block declares that Terraform will use an S3 backend for state storage.
# The actual backend values (bucket, key, region, DynamoDB lock table) are NOT
# hardcoded here. Instead, they are supplied dynamically by:
#
#   • deploy.sh / deploy.ps1  (during terraform init)
#   • destroy.sh / destroy.ps1 (during terraform init)
#
# This ensures:
#   • No secrets in code
#   • Environment-specific state files (dev/test/prod)
#   • Full compatibility with CI/CD (GitHub Actions)
#
# Local development:
#   terraform init \
#     -backend-config="bucket=..." \
#     -backend-config="key=dev/terraform.tfstate" \
#     -backend-config="region=us-east-1" \
#     -backend-config="dynamodb_table=..."
#
###############################################################################

terraform {
  backend "s3" {
    # Intentionally empty.
    # Values are injected at runtime via -backend-config flags.
    #
    # Example values set by deploy scripts:
    #   bucket         = "twin-terraform-state-123456789012"
    #   key            = "dev/terraform.tfstate"
    #   region         = "us-east-1"
    #   dynamodb_table = "twin-terraform-locks"
    #   encrypt        = true
  }
}
