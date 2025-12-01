param(
    [string]$Environment = "dev",    # dev | test | prod
    [string]$ProjectName = "twin"
)

$ErrorActionPreference = "Stop"

Write-Host "🚀 Deploying $ProjectName to $Environment ..." -ForegroundColor Green

# ---------------------------------------------------------
# 1. Build Lambda Package
# ---------------------------------------------------------
Set-Location (Split-Path $PSScriptRoot -Parent)   # Move to project root
Write-Host "📦 Building Lambda package..." -ForegroundColor Yellow

Set-Location backend
uv run deploy.py
Set-Location ..

# ---------------------------------------------------------
# 2. Terraform Init + Workspace + Apply
# ---------------------------------------------------------
Set-Location terraform
terraform init -input=false

# Create or select workspace
if (-not (terraform workspace list | Select-String $Environment)) {
    terraform workspace new $Environment
} else {
    terraform workspace select $Environment
}

# Use prod.tfvars for production
if ($Environment -eq "prod") {
    terraform apply -var-file=prod.tfvars -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
} else {
    terraform apply -var="project_name=$ProjectName" -var="environment=$Environment" -auto-approve
}

# Get Terraform outputs
$ApiUrl         = terraform output -raw api_gateway_url
$FrontendBucket = terraform output -raw s3_frontend_bucket

try {
    $CustomUrl = terraform output -raw custom_domain_url
} catch {
    $CustomUrl = ""
}

# ---------------------------------------------------------
# 3. Build + Deploy Frontend
# ---------------------------------------------------------
Set-Location ..\frontend

Write-Host "📝 Setting API URL for production..." -ForegroundColor Yellow
"NEXT_PUBLIC_API_URL=$ApiUrl" | Out-File .env.production -Encoding utf8

npm install
npm run build

aws s3 sync .\out "s3://$FrontendBucket/" --delete

Set-Location ..

# ---------------------------------------------------------
# 4. Final Summary
# ---------------------------------------------------------
$CfUrl = terraform -chdir=terraform output -raw cloudfront_url

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host "🌐 CloudFront URL : $CfUrl" -ForegroundColor Cyan

if ($CustomUrl) {
    Write-Host "🔗 Custom domain  : $CustomUrl" -ForegroundColor Cyan
}

Write-Host "📡 API Gateway    : $ApiUrl" -ForegroundColor Cyan
