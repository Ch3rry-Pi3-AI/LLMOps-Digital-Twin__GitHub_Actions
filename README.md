# 🧹 Final Cleanup

This branch covers the complete cleanup process once you have finished deploying, testing, and experimenting with the Digital Twin project.
It includes destroying all deployment environments, reviewing remaining costs, and removing GitHub Actions–related AWS resources if you want a full teardown.

## Part 1: Destroy All Environments

Before removing backend resources, ensure all deployed environments have been destroyed using GitHub Actions.

### Step 1: Destroy the Dev Environment

1. Go to your GitHub repository
2. Click the **Actions** tab
3. Select **Destroy Environment**
4. Click **Run workflow**
5. Choose:

   * Environment: `dev`
   * Confirm: type `dev`
6. Run the workflow
7. Wait for it to complete successfully

### Step 2: Destroy the Test Environment

If a test environment exists:

1. Open the **Destroy Environment** workflow
2. Run workflow with:

   * Environment: `test`
   * Confirm: type `test`
3. Run and wait for completion

### Step 3: Destroy the Production Environment (If Applicable)

If you deployed a production environment:

1. Open **Destroy Environment** workflow
2. Run workflow with:

   * Environment: `prod`
   * Confirm: type `prod`
3. Wait for the destruction to complete

Your AWS account should now have **no active application infrastructure** (Lambda, API Gateway, S3 frontend, CloudFront, etc.).

## Part 2: Clean Up GitHub Actions Resources

The GitHub Actions integration creates several backend resources used for Terraform state and CI/CD authentication. These incur minimal ongoing cost.

### Step 1: Review Remaining Cost

After application infrastructure is destroyed, the remaining AWS resources are:

| Resource                                | Purpose                       | Approx. Cost                      |
| --------------------------------------- | ----------------------------- | --------------------------------- |
| IAM Role (`github-actions-twin-deploy`) | GitHub OIDC authentication    | **Free**                          |
| S3 Bucket (`twin-terraform-state-*`)    | Stores Terraform state        | ~**$0.02/month**                  |
| DynamoDB Table (`twin-terraform-locks`) | Manages Terraform state locks | **$0.00/month** (PAY_PER_REQUEST) |

**Total estimated monthly cost if left in place: < $0.05**

If you want to stop here, it's safe and extremely low-cost.

If, however, you want a **full teardown**, continue below.

## Part 3: Remove GitHub Actions IAM and State Resources

### Step 1: Delete the IAM Role

Only remove the IAM role if you are completely finished with the course and no longer want GitHub Actions to interact with AWS.

Run the following:

```bash
# 1. Detach all policies from the GitHub Actions role
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AWSLambda_FullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonS3FullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonAPIGatewayAdministrator
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/CloudFrontFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/IAMReadOnlyAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonBedrockFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonDynamoDBFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AWSCertificateManagerFullAccess
aws iam detach-role-policy --role-name github-actions-twin-deploy --policy-arn arn:aws:iam::aws:policy/AmazonRoute53FullAccess

# Remove custom inline policy
aws iam delete-role-policy --role-name github-actions-twin-deploy --policy-name github-actions-additional

# Delete the role
aws iam delete-role --role-name github-actions-twin-deploy
```

### Step 2: Delete Terraform State Bucket

```bash
AWS_ACCOUNT_ID=$(aws sts get-caller-identity --query Account --output text)

aws s3 rm s3://twin-terraform-state-${AWS_ACCOUNT_ID} --recursive
aws s3 rb s3://twin-terraform-state-${AWS_ACCOUNT_ID}
```

### Step 3: Delete DynamoDB Lock Table

```bash
aws dynamodb delete-table --table-name twin-terraform-locks
```

## Part 4: Completion Checkpoint

Once all steps are complete:

✔ All environments (dev, test, prod) are destroyed
✔ GitHub Actions no longer has access to AWS
✔ Terraform state storage (S3 + DynamoDB) is fully removed
✔ Your AWS account returns to zero cost

Your Digital Twin CI/CD system has now been fully decommissioned.
