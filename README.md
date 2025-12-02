# 🧹 **Clean Up Existing Infrastructure — Branch Overview**

This branch prepares the project for the next phase: implementing **CI/CD with GitHub Actions**.
Before automation can manage the Digital Twin infrastructure, the AWS environment must be reset to a clean baseline.
This ensures Terraform and GitHub Actions can deploy new dev/test/prod environments without conflicts or leftover resources.

## **Step 1: Destroy All Environments**

Use the destruction scripts created in the Terraform project to remove the development, test, and production environments.

### Mac/Linux

```bash
./scripts/destroy.sh dev
./scripts/destroy.sh test
./scripts/destroy.sh prod    # only if you previously created prod
```

### Windows PowerShell

```powershell
.\scripts\destroy.ps1 -Environment dev
.\scripts\destroy.ps1 -Environment test
.\scripts\destroy.ps1 -Environment prod   # only if created
```

CloudFront distributions may take several minutes to complete deletion due to global propagation delays.

## **Step 2: Clean Up Terraform Workspaces**

After destroying the environments, remove the Terraform workspaces to ensure CI/CD can recreate them.

```bash
cd terraform

terraform workspace select default
terraform workspace delete dev
terraform workspace delete test
terraform workspace delete prod

cd ..
```

Only delete workspaces that actually exist.

## **Step 3: Verify Clean State in AWS**

Before proceeding, verify that all Digital Twin resources have been removed.

### Lambda

Confirm there are no functions beginning with:
`twin-`

### S3 Buckets

Ensure none of the following remain:

* `twin-dev-frontend-*`
* `twin-dev-memory-*`
* `twin-test-frontend-*`
* `twin-test-memory-*`
* `twin-prod-*` (if previously created)

### API Gateway

There should be no APIs named:

* `twin-dev-api-gateway`
* `twin-test-api-gateway`
* `twin-prod-api-gateway`

### CloudFront

Ensure there are no distributions associated with the Digital Twin frontend.

### Optional Additional Checks

* IAM roles or policies beginning with `twin-`
* ACM certificates if you experimented with custom domains
* Route 53 records (only if you previously tested custom domains)

## **Checkpoint**

Your AWS environment is now fully reset and ready for the next stage of the project.
With all manual and Terraform-managed resources removed, the CI/CD pipeline can begin managing deployments cleanly and consistently.
