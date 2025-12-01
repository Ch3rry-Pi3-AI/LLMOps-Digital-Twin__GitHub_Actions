# 🔐 Configure GitHub Repository Secrets & OIDC Role

This branch configures **secure authentication between GitHub Actions and AWS** using **OpenID Connect (OIDC)**, and then wires that into your GitHub repository via **encrypted repository secrets**.

By the end of this branch:

* GitHub Actions will assume an **IAM role** via OIDC (no long-lived AWS keys).
* Terraform will know about that role.
* Your GitHub repo will have the correct **AWS secrets** configured for CI/CD.



## Part 1: Create AWS IAM Role for GitHub Actions (OIDC)

### Stage 1: Define the OIDC Role in Terraform

Create `terraform/github-oidc.tf`:

```hcl
# This creates an IAM role that GitHub Actions can assume
# Run this once, then you can remove the file

variable "github_repository" {
  description = "GitHub repository in format 'owner/repo'"
  type        = string
}

# Note: aws_caller_identity.current is already defined in main.tf

# GitHub OIDC Provider
# Note: If this already exists in your account, you'll need to import it:
# terraform import aws_iam_openid_connect_provider.github arn:aws:iam::ACCOUNT_ID:oidc-provider/token.actions.githubusercontent.com
resource "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
  
  client_id_list = [
    "sts.amazonaws.com"
  ]
  
  # This thumbprint is from GitHub's documentation
  # Verify current value at: https://github.blog/changelog/2023-06-27-github-actions-update-on-oidc-integration-with-aws/
  thumbprint_list = [
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# IAM Role for GitHub Actions
resource "aws_iam_role" "github_actions" {
  name = "github-actions-twin-deploy"
  
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.github.arn
        }
        Action = "sts:AssumeRoleWithWebIdentity"
        Condition = {
          StringEquals = {
            "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
          }
          StringLike = {
            "token.actions.githubusercontent.com:sub" = "repo:${var.github_repository}:*"
          }
        }
      }
    ]
  })
  
  tags = {
    Name        = "GitHub Actions Deploy Role"
    Repository  = var.github_repository
    ManagedBy   = "terraform"
  }
}

# Attach necessary policies
resource "aws_iam_role_policy_attachment" "github_lambda" {
  policy_arn = "arn:aws:iam::aws:policy/AWSLambda_FullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_s3" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_apigateway" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_cloudfront" {
  policy_arn = "arn:aws:iam::aws:policy/CloudFrontFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_iam_read" {
  policy_arn = "arn:aws:iam::aws:policy/IAMReadOnlyAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_bedrock" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonBedrockFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_dynamodb" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_acm" {
  policy_arn = "arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess"
  role       = aws_iam_role.github_actions.name
}

resource "aws_iam_role_policy_attachment" "github_route53" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonRoute53FullAccess"
  role       = aws_iam_role.github_actions.name
}

# Custom policy for additional permissions
resource "aws_iam_role_policy" "github_additional" {
  name = "github-actions-additional"
  role = aws_iam_role.github_actions.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "iam:CreateRole",
          "iam:DeleteRole",
          "iam:AttachRolePolicy",
          "iam:DetachRolePolicy",
          "iam:PutRolePolicy",
          "iam:DeleteRolePolicy",
          "iam:GetRole",
          "iam:GetRolePolicy",
          "iam:ListRolePolicies",
          "iam:ListAttachedRolePolicies",
          "iam:UpdateAssumeRolePolicy",
          "iam:PassRole",
          "iam:TagRole",
          "iam:UntagRole",
          "iam:ListInstanceProfilesForRole",
          "sts:GetCallerIdentity"
        ]
        Resource = "*"
      }
    ]
  })
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions.arn
}
```

### Stage 2: Check for an Existing GitHub OIDC Provider

From the `terraform/` directory, ensure you are on the **default workspace**:

```bash
cd terraform
terraform workspace select default
```

Now check if the GitHub OIDC provider already exists in your AWS account.

**Mac/Linux:**

```bash
aws iam list-open-id-connect-providers | grep token.actions.githubusercontent.com
```

**Windows (PowerShell):**

```powershell
aws iam list-open-id-connect-providers | Select-String "token.actions.githubusercontent.com"
```

* If you see an ARN like
  `arn:aws:iam::123456789012:oidc-provider/token.actions.githubusercontent.com`
  then the provider already exists (you will need to **import** it).
* If you see nothing, **Terraform will create it** for you in Scenario A.

### Stage 3: (Optional) Import Existing OIDC Provider

If the provider already exists, import it into Terraform state **before** applying.

**Mac/Linux:**

```bash
# Get your AWS Account ID
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)
echo "Your AWS Account ID is: $AWS_ACCOUNT_ID"

# Only run this if the provider already exists:
# terraform import aws_iam_openid_connect_provider.github arn:aws:iam::${AWS_ACCOUNT_ID}:oidc-provider/token.actions.githubusercontent.com
```

**Windows (PowerShell):**

```powershell
# Get your AWS Account ID
$awsAccountId = aws sts get-caller-identity --query Account --output text
Write-Host "Your AWS Account ID is: $awsAccountId"

# Only run this if the provider already exists:
# terraform import aws_iam_openid_connect_provider.github "arn:aws:iam::${awsAccountId}:oidc-provider/token.actions.githubusercontent.com"
```

> Note: During import you will be prompted for `var.github_repository`. Use the format `your-username/your-repo-name` (no URL prefix).



## Part 2: Apply GitHub OIDC Resources

### Stage 4: Scenario A – OIDC Provider Does **Not** Exist

Use this if the earlier check returned **no** existing provider.

**Important:**

* Replace `YOUR_GITHUB_USERNAME` with your actual GitHub username.
* The `github_repository` **must** be in the form `username/repo-name`
  e.g. `johndoe/digital-twin`
* Do **not** include `https://github.com/` or you will get cryptic errors.

**Mac/Linux:**

```bash
# Apply ALL resources including OIDC provider (one long command)
terraform apply \
  -target=aws_iam_openid_connect_provider.github \
  -target=aws_iam_role.github_actions \
  -target=aws_iam_role_policy_attachment.github_lambda \
  -target=aws_iam_role_policy_attachment.github_s3 \
  -target=aws_iam_role_policy_attachment.github_apigateway \
  -target=aws_iam_role_policy_attachment.github_cloudfront \
  -target=aws_iam_role_policy_attachment.github_iam_read \
  -target=aws_iam_role_policy_attachment.github_bedrock \
  -target=aws_iam_role_policy_attachment.github_dynamodb \
  -target=aws_iam_role_policy_attachment.github_acm \
  -target=aws_iam_role_policy_attachment.github_route53 \
  -target=aws_iam_role_policy.github_additional \
  -var="github_repository=YOUR_GITHUB_USERNAME/digital-twin"
```

**Windows (PowerShell):**

```powershell
# Apply ALL resources including OIDC provider (one long command)
terraform apply `
  -target="aws_iam_openid_connect_provider.github" `
  -target="aws_iam_role.github_actions" `
  -target="aws_iam_role_policy_attachment.github_lambda" `
  -target="aws_iam_role_policy_attachment.github_s3" `
  -target="aws_iam_role_policy_attachment.github_apigateway" `
  -target="aws_iam_role_policy_attachment.github_cloudfront" `
  -target="aws_iam_role_policy_attachment.github_iam_read" `
  -target="aws_iam_role_policy_attachment.github_bedrock" `
  -target="aws_iam_role_policy_attachment.github_dynamodb" `
  -target="aws_iam_role_policy_attachment.github_acm" `
  -target="aws_iam_role_policy_attachment.github_route53" `
  -target="aws_iam_role_policy.github_additional" `
  -var="github_repository=YOUR_GITHUB_USERNAME/digital-twin"
```

### Stage 5: Scenario B – OIDC Provider Already Imported

Use this if you previously imported the OIDC provider via `terraform import`.

**Important:**

* Use the **same** `github_repository` value you provided during import
  e.g. `your-username/digital-twin`.

**Mac/Linux:**

```bash
# Apply ONLY the IAM role and policies (NOT the OIDC provider) - one long command
terraform apply \
  -target=aws_iam_role.github_actions \
  -target=aws_iam_role_policy_attachment.github_lambda \
  -target=aws_iam_role_policy_attachment.github_s3 \
  -target=aws_iam_role_policy_attachment.github_apigateway \
  -target=aws_iam_role_policy_attachment.github_cloudfront \
  -target=aws_iam_role_policy_attachment.github_iam_read \
  -target=aws_iam_role_policy_attachment.github_bedrock \
  -target=aws_iam_role_policy_attachment.github_dynamodb \
  -target=aws_iam_role_policy_attachment.github_acm \
  -target=aws_iam_role_policy_attachment.github_route53 \
  -target=aws_iam_role_policy.github_additional \
  -var="github_repository=YOUR_GITHUB_USERNAME/your-repo-name"
```

**Windows (PowerShell):**

```powershell
# Apply ONLY the IAM role and policies (NOT the OIDC provider) - one long command
terraform apply `
  -target="aws_iam_role.github_actions" `
  -target="aws_iam_role_policy_attachment.github_lambda" `
  -target="aws_iam_role_policy_attachment.github_s3" `
  -target="aws_iam_role_policy_attachment.github_apigateway" `
  -target="aws_iam_role_policy_attachment.github_cloudfront" `
  -target="aws_iam_role_policy_attachment.github_iam_read" `
  -target="aws_iam_role_policy_attachment.github_bedrock" `
  -target="aws_iam_role_policy_attachment.github_dynamodb" `
  -target="aws_iam_role_policy_attachment.github_acm" `
  -target="aws_iam_role_policy_attachment.github_route53" `
  -target="aws_iam_role_policy.github_additional" `
  -var="github_repository=YOUR_GITHUB_USERNAME/your-repo-name"
```

### Stage 6: Capture Role ARN and Clean Up Setup File

After a successful apply:

```bash
# From terraform directory
terraform output github_actions_role_arn
```

* Copy the output ARN (e.g. `arn:aws:iam::123456789012:role/github-actions-twin-deploy`).
* This will be used as `AWS_ROLE_ARN` in GitHub.

Once confirmed, you can remove the setup file:

**Mac/Linux:**

```bash
rm github-oidc.tf
```

**Windows (PowerShell):**

```powershell
Remove-Item github-oidc.tf
```



## Part 3: Configure Terraform Backend (S3)

### Stage 7: Configure S3 Backend for Terraform State

Create `terraform/backend.tf`:

```hcl
terraform {
  backend "s3" {
    # These values will be set by deployment scripts
    # For local development, they can be passed via -backend-config
  }
}
```

This tells Terraform to use **S3** for its state, but the concrete values (bucket, key, region, DynamoDB table) are supplied at runtime by your deployment scripts via `-backend-config`.



## Part 4: Add GitHub Repository Secrets

### Stage 8: Add Required Secrets in GitHub

1. Open your GitHub repository in the browser.
2. Go to **Settings**.
3. In the left sidebar, select **Secrets and variables → Actions**.
4. Click **New repository secret** for each secret below.

**Secret 1: `AWS_ROLE_ARN`**

* Name: `AWS_ROLE_ARN`
* Value: The IAM role ARN from `terraform output github_actions_role_arn`
  e.g. `arn:aws:iam::123456789012:role/github-actions-twin-deploy`

**Secret 2: `DEFAULT_AWS_REGION`**

* Name: `DEFAULT_AWS_REGION`
* Value: `us-east-1` (or your preferred AWS region, consistent with your setup)

**Secret 3: `AWS_ACCOUNT_ID`**

* Name: `AWS_ACCOUNT_ID`
* Value: Your 12-digit AWS account ID
  e.g. `123456789012`

### Stage 9: Verify Secrets

After adding them, you should see **three** repository secrets:

* `AWS_ROLE_ARN`
* `DEFAULT_AWS_REGION`
* `AWS_ACCOUNT_ID`

✅ **Checkpoint:**
GitHub Actions can now **securely authenticate** to your AWS account using **OIDC + IAM role assumption**, with no long-lived AWS keys stored anywhere.
