# 🧹 **Clean Slate — Remove Manual Resources**

Before introducing Terraform to manage your entire AWS infrastructure, it is essential to remove all previously created manual resources.
This ensures Terraform begins with a completely clean state, preventing conflicts, duplication, or infrastructure drift.

Follow the steps below to fully reset your AWS environment.

## Step 1: Delete the Lambda Function

1. Sign in to AWS Console as your IAM user: `aiengineer`
2. Navigate to **Lambda**
3. Select the function named `twin-api`
4. Click **Actions** → **Delete**
5. Type `delete` to confirm
6. Click **Delete**

This removes your manually deployed backend compute resource.

## Step 2: Delete API Gateway

1. Go to **API Gateway** in the AWS Console
2. Select the API called `twin-api-gateway`
3. Click **Actions** → **Delete**
4. Type the API name to confirm
5. Click **Delete**

This clears out your manual API routing layer.

## Step 3: Empty and Delete S3 Buckets

### Memory Bucket

1. Navigate to **S3**
2. Open your memory bucket (e.g., `twin-memory-xyz`)
3. Click **Empty**
4. Type `permanently delete` to confirm
5. Click **Empty**
6. Once empty, click **Delete**
7. Type the bucket name to confirm
8. Click **Delete bucket**

### Frontend Bucket

1. Navigate to your frontend bucket (e.g., `twin-frontend-xyz`)
2. Repeat the **empty** → **delete** process from above

Both buckets must be fully removed so Terraform can recreate them reliably.

## Step 4: Delete CloudFront Distribution

1. Navigate to **CloudFront**
2. Select your distribution
3. Click **Disable**
4. Wait until the status updates to **Deployed** (typically 5–10 minutes)
5. Once disabled, click **Delete**
6. Confirm deletion

CloudFront distributions must be disabled before they can be removed.

## Step 5: Verify a Clean State

Ensure the following:

* Lambda → no `twin-api` function exists
* API Gateway → no `twin-api-gateway` API exists
* S3 → no buckets beginning with `twin-` remain
* CloudFront → no distributions related to your Digital Twin exist

A fully empty state ensures Terraform can provision every resource cleanly and consistently.

## Checkpoint

Your AWS account is now clean.
Terraform will build **all** resources from this point forward — backend, frontend, memory storage, networking, and infrastructure.
