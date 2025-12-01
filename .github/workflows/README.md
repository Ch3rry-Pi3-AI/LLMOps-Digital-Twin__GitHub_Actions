# 📁 GitHub Actions Workflows

This folder contains all automated CI/CD workflows used to deploy, update, and destroy the Digital Twin infrastructure on AWS.
All workflows use **GitHub OIDC**, ensuring secure authentication without long-lived AWS keys.

## Purpose of This Folder

The `.github/workflows` directory defines the automation pipeline responsible for:

* running deployments to dev, test, and prod
* destroying environments safely
* managing AWS credentials through OIDC
* orchestrating Terraform operations
* packaging and deploying backend + frontend assets

Each workflow is designed to be deterministic, auditable, and fully compatible with the Terraform S3 backend created earlier.

## Included Workflows

### 1. Deploy Digital Twin (`deploy.yml`)

Automatically deploys the entire system when:

* code is pushed to the `main` branch, or
* the workflow is manually triggered with a specified environment.

Key capabilities:

* assumes AWS IAM role via OIDC
* runs `scripts/deploy.sh` end-to-end
* provisions all Terraform-managed infrastructure
* uploads frontend build to S3
* invalidates CloudFront cache
* outputs deployment URLs

### 2. Destroy Environment (`destroy.yml`)

Safely removes an entire environment (dev, test, or prod).

Key protections:

* manual trigger only
* mandatory typed confirmation
* empties S3 buckets prior to destruction
* calls `scripts/destroy.sh` to perform cleanup
* uses Terraform for full state-aware teardown

## How This Folder Fits in the Project

This directory forms the automation layer of your Digital Twin platform, enabling:

* consistent deployments
* reproducible infrastructure
* secure authentication
* separation between code and cloud execution
* zero manual AWS console interactions

These workflows provide the final step in transitioning the Digital Twin into a fully automated, production-ready MLOps system.

If you would like, I can also prepare:

* a CI/CD architecture diagram
* a top-level README section referencing this folder
* a workflow summary table for your main project README
