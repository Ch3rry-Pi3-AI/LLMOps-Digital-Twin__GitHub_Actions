# ☁️ **Set Up Terraform S3 Backend**

This branch configures a **remote Terraform backend** using an S3 bucket and DynamoDB table.
This allows Terraform to store state securely, support team workflows, and integrate with CI/CD pipelines.
These resources are created once per AWS account and remain globally available.

## **Part 1: Create Remote Backend Resources**

### Stage 1: Add Backend Setup File

Create the file:

```
terraform/backend-setup.tf
```

Add the following configuration:

```hcl
# Creates the S3 bucket and DynamoDB table used for Terraform remote state
# Run this once per AWS account, then remove this file afterwards

resource "aws_s3_bucket" "terraform_state" {
  bucket = "twin-terraform-state-${data.aws_caller_identity.current.account_id}"

  tags = {
    Name        = "Terraform State Store"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

resource "aws_s3_bucket_versioning" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_server_side_encryption_configuration" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
  }
}

resource "aws_s3_bucket_public_access_block" "terraform_state" {
  bucket = aws_s3_bucket.terraform_state.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

resource "aws_dynamodb_table" "terraform_locks" {
  name         = "twin-terraform-locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = {
    Name        = "Terraform State Locks"
    Environment = "global"
    ManagedBy   = "terraform"
  }
}

output "state_bucket_name" {
  value = aws_s3_bucket.terraform_state.id
}

output "dynamodb_table_name" {
  value = aws_dynamodb_table.terraform_locks.name
}
```

This file defines:

* A secure, versioned S3 bucket
* Full server-side encryption
* Public access blocking
* A DynamoDB table for Terraform state locking
* Outputs confirming creation

### Stage 2: Apply Backend Resources

From the project root:

```bash
cd terraform
terraform workspace select default
terraform init
```

Apply backend resources:

**Mac/Linux**

```bash
terraform apply \
  -target=aws_s3_bucket.terraform_state \
  -target=aws_s3_bucket_versioning.terraform_state \
  -target=aws_s3_bucket_server_side_encryption_configuration.terraform_state \
  -target=aws_s3_bucket_public_access_block.terraform_state \
  -target=aws_dynamodb_table.terraform_locks
```

**Windows PowerShell**

```powershell
terraform apply --% `
  -target="aws_s3_bucket.terraform_state" `
  -target="aws_s3_bucket_versioning.terraform_state" `
  -target="aws_s3_bucket_server_side_encryption_configuration.terraform_state" `
  -target="aws_s3_bucket_public_access_block.terraform_state" `
  -target="aws_dynamodb_table.terraform_locks"
```

Verify creation:

```bash
terraform output
```

## **Part 2: Clean Up Setup File**

### Stage 3: Remove Setup File

Once the backend infrastructure exists, remove the setup file:

```bash
rm backend-setup.tf
```

The backend bucket and lock table remain permanently available to all Terraform workspaces.

## **Part 3: Update Deployment and Destroy Scripts**

### Stage 4: Update deploy.sh

Locate the line:

```bash
terraform init -input=false
```

Replace with:

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
AWS_REGION=${DEFAULT_AWS_REGION:-us-east-1}

terraform init -input=false \
  -backend-config="bucket=twin-terraform-state-${AWS_ACCOUNT_ID}" \
  -backend-config="key=${ENVIRONMENT}/terraform.tfstate" \
  -backend-config="region=${AWS_REGION}" \
  -backend-config="dynamodb_table=twin-terraform-locks" \
  -backend-config="encrypt=true"
```

### Stage 5: Update deploy.ps1

Replace the plain init line with:

```powershell
$awsAccountId = aws sts get-caller-identity --query Account --output text
$awsRegion = if ($env:DEFAULT_AWS_REGION) { $env:DEFAULT_AWS_REGION } else { "us-east-1" }

terraform init -input=false `
  -backend-config="bucket=twin-terraform-state-$awsAccountId" `
  -backend-config="key=$Environment/terraform.tfstate" `
  -backend-config="region=$awsRegion" `
  -backend-config="dynamodb_table=twin-terraform-locks" `
  -backend-config="encrypt=true"
```

### Stage 6: Replace destroy scripts

Update both `destroy.sh` and `destroy.ps1` with the new versions that include:

* S3 backend initialization
* S3 bucket emptying
* Region and account detection
* Additional stability handling for CI/CD runs

(These scripts were provided earlier and will be included in your repo.)

## **Completion Check**

When this branch is complete:

* A secure Terraform S3 backend exists
* DynamoDB state locking is enabled
* Backend setup file has been removed
* Deployment scripts and destroy scripts now support remote backend
* The project is ready for CI/CD integration
