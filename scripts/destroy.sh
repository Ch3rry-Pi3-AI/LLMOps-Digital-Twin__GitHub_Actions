#!/bin/bash
set -e

#######################################################################
# 🧹 Destroy Script (Mac/Linux)
# Cleans up Terraform-managed AWS infrastructure for a given environment.
# Ensures:
#   • Workspace selection
#   • S3 backend initialization
#   • Automatic S3 bucket emptying
#   • Safe Terraform destroy
#   • Workspace cleanup instructions
#######################################################################

# ---------------------------------------------------------
# Validate required environment parameter
# ---------------------------------------------------------
if [ $# -eq 0 ]; then
    echo "❌ Error: Environment parameter is required"
    echo "Usage: $0 <environment>"
    echo "Example: $0 dev"
    echo "Available environments: dev, test, prod"
    exit 1
fi

ENVIRONMENT=$1
PROJECT_NAME=${2:-twin}

echo "🗑️ Preparing to destroy ${PROJECT_NAME}-${ENVIRONMENT} infrastructure..."

# ---------------------------------------------------------
# Move into terraform directory
# ---------------------------------------------------------
cd "$(dirname "$0")/../terraform"

# ---------------------------------------------------------
# Retrieve AWS account + region for backend configuration
# ---------------------------------------------------------
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}

# ---------------------------------------------------------
# Initialize Terraform with S3 backend configuration
# Ensures remote state + DynamoDB locking is active
# ---------------------------------------------------------
echo "🔧 Initializing Terraform with S3 backend..."
terraform init -input=false \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=twin-terraform-locks" \
  -backend-config="encrypt=true"

# ---------------------------------------------------------
# Verify that the workspace exists before proceeding
# ---------------------------------------------------------
if ! terraform workspace list | grep -q "$ENVIRONMENT"; then
    echo "❌ Error: Workspace '$ENVIRONMENT' does not exist"
    echo "Available workspaces:"
    terraform workspace list
    exit 1
fi

# ---------------------------------------------------------
# Select the environment workspace
# ---------------------------------------------------------
terraform workspace select "$ENVIRONMENT"

echo "📦 Emptying S3 buckets..."

# ---------------------------------------------------------
# Construct bucket names based on environment + account ID
# ---------------------------------------------------------
FRONTEND_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-frontend-${AWS_ACCOUNT_ID}"
MEMORY_BUCKET="${PROJECT_NAME}-${ENVIRONMENT}-memory-${AWS_ACCOUNT_ID}"

# ---------------------------------------------------------
# Empty frontend bucket if it exists
# ---------------------------------------------------------
if aws s3 ls "s3://$FRONTEND_BUCKET" 2>/dev/null; then
    echo "  Emptying $FRONTEND_BUCKET..."
    aws s3 rm "s3://$FRONTEND_BUCKET" --recursive
else
    echo "  Frontend bucket not found or already empty"
fi

# ---------------------------------------------------------
# Empty memory bucket if it exists
# ---------------------------------------------------------
if aws s3 ls "s3://$MEMORY_BUCKET" 2>/dev/null; then
    echo "  Emptying $MEMORY_BUCKET..."
    aws s3 rm "s3://$MEMORY_BUCKET" --recursive
else
    echo "  Memory bucket not found or already empty"
fi

# ---------------------------------------------------------
# Perform Terraform destroy
# ---------------------------------------------------------
echo "🔥 Running terraform destroy..."

# Terraform destroy requires the lambda zip to exist; create dummy if missing
if [ ! -f "../backend/lambda-deployment.zip" ]; then
    echo "Creating dummy lambda package for destroy operation..."
    echo "dummy" | zip ../backend/lambda-deployment.zip -
fi

# Use prod.tfvars if environment is prod
if [ "$ENVIRONMENT" = "prod" ] && [ -f "prod.tfvars" ]; then
    terraform destroy \
        -var-file=prod.tfvars \
        -var="project_name=$PROJECT_NAME" \
        -var="environment=$ENVIRONMENT" \
        -auto-approve
else
    terraform destroy \
        -var="project_name=$PROJECT_NAME" \
        -var="environment=$ENVIRONMENT" \
        -auto-approve
fi

# ---------------------------------------------------------
# Completion message + workspace cleanup note
# ---------------------------------------------------------
echo "✅ Infrastructure for ${ENVIRONMENT} has been destroyed!"
echo ""
echo "💡 To remove the workspace completely, run:"
echo "   terraform workspace select default"
echo "   terraform workspace delete $ENVIRONMENT"
