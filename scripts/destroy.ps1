param(
    # Target environment to destroy: dev | test | prod
    [Parameter(Mandatory = $true)]
    [string]$Environment,

    # Project name used in resource naming conventions
    [string]$ProjectName = "twin"
)

# Stop execution immediately if any command fails
$ErrorActionPreference = "Stop"

# -------------------------------------------------------------------
# 1. Validate Input
# -------------------------------------------------------------------

# Ensure the environment parameter is one of the supported values
if ($Environment -notmatch '^(dev|test|prod)$') {
    Write-Host "Error: Invalid environment '$Environment'" -ForegroundColor Red
    Write-Host "Available environments: dev, test, prod" -ForegroundColor Yellow
    exit 1
}

Write-Host "Preparing to destroy $ProjectName-$Environment infrastructure..." -ForegroundColor Yellow

# -------------------------------------------------------------------
# 2. Change to Terraform Directory
# -------------------------------------------------------------------

# Move from /scripts to the terraform/ folder in the project root
Set-Location (Join-Path (Split-Path $PSScriptRoot -Parent) "terraform")

# -------------------------------------------------------------------
# 3. Configure Backend (S3 + DynamoDB)
# -------------------------------------------------------------------

# Retrieve the current AWS account ID for backend naming
$awsAccountId = aws sts get-caller-identity --query Account --output text

# Resolve AWS region from DEFAULT_AWS_REGION or fall back to us-east-1
$awsRegion = if ($env:DEFAULT_AWS_REGION) { $env:DEFAULT_AWS_REGION } else { "us-east-1" }

# Initialise Terraform using the remote S3 backend (state bucket + DynamoDB locks)
Write-Host "Initializing Terraform with S3 backend..." -ForegroundColor Yellow
terraform init -input=false `
  -backend-config="bucket=twin-terraform-state-$awsAccountId" `
  -backend-config="key=$Environment/terraform.tfstate" `
  -backend-config="region=$awsRegion" `
  -backend-config="dynamodb_table=twin-terraform-locks" `
  -backend-config="encrypt=true"

# -------------------------------------------------------------------
# 4. Select Workspace for Target Environment
# -------------------------------------------------------------------

# List existing workspaces so we can validate the requested environment
$workspaces = terraform workspace list

# If the workspace does not exist, abort with a helpful message
if (-not ($workspaces | Select-String $Environment)) {
    Write-Host "Error: Workspace '$Environment' does not exist" -ForegroundColor Red
    Write-Host "Available workspaces:" -ForegroundColor Yellow
    terraform workspace list
    exit 1
}

# Select the workspace corresponding to the target environment
terraform workspace select $Environment

# -------------------------------------------------------------------
# 5. Empty S3 Buckets (Frontend + Memory)
# -------------------------------------------------------------------

Write-Host "Emptying S3 buckets..." -ForegroundColor Yellow

# Derive bucket names that match the Day 4 naming convention
$FrontendBucket = "$ProjectName-$Environment-frontend-$awsAccountId"
$MemoryBucket   = "$ProjectName-$Environment-memory-$awsAccountId"

# Try to empty the frontend bucket if it exists
try {
    aws s3 ls "s3://$FrontendBucket" 2>$null | Out-Null
    Write-Host "  Emptying $FrontendBucket..." -ForegroundColor Gray
    aws s3 rm "s3://$FrontendBucket" --recursive
}
catch {
    Write-Host "  Frontend bucket not found or already empty" -ForegroundColor Gray
}

# Try to empty the memory bucket if it exists
try {
    aws s3 ls "s3://$MemoryBucket" 2>$null | Out-Null
    Write-Host "  Emptying $MemoryBucket..." -ForegroundColor Gray
    aws s3 rm "s3://$MemoryBucket" --recursive
}
catch {
    Write-Host "  Memory bucket not found or already empty" -ForegroundColor Gray
}

# -------------------------------------------------------------------
# 6. Run Terraform Destroy
# -------------------------------------------------------------------

Write-Host "Running terraform destroy..." -ForegroundColor Yellow

# Use prod.tfvars for production, if present; otherwise use inline variables only
if ($Environment -eq "prod" -and (Test-Path "prod.tfvars")) {
    terraform destroy -var-file=prod.tfvars `
                     -var="project_name=$ProjectName" `
                     -var="environment=$Environment" `
                     -auto-approve
}
else {
    terraform destroy -var="project_name=$ProjectName" `
                     -var="environment=$Environment" `
                     -auto-approve
}

# -------------------------------------------------------------------
# 7. Final Summary / Next Steps
# -------------------------------------------------------------------

Write-Host "Infrastructure for $Environment has been destroyed!" -ForegroundColor Green
Write-Host ""  # Blank line for readability
Write-Host "  To remove the workspace completely, run:" -ForegroundColor Cyan
Write-Host "   terraform workspace select default" -ForegroundColor White
Write-Host "   terraform workspace delete $Environment" -ForegroundColor White
