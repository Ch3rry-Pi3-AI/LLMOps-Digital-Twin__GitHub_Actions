# ⚙️ **LLMOps Digital Twin — CI/CD Automation (GitHub Actions Edition)**

This repository builds on the earlier Digital Twin projects by introducing a **complete CI/CD pipeline** using **GitHub Actions**, **Terraform remote state**, and **secure AWS OIDC authentication**.

The result is a streamlined, production-style automation workflow that handles deployments, environment management, and infrastructure teardown with minimal manual effort.

## 🎥 **Digital Twin Demo**

<div align="center">
  <img src="img/demo/twin_demo.gif" width="100%" alt="Digital Twin Demo">
</div>

This repo keeps the same application logic as before; the difference is that **everything is now deployed automatically**.

## 🧩 **Grouped Stages**

|  Stage | Category                 | Description                                                                                   |
| :----: | ------------------------ | --------------------------------------------------------------------------------------------- |
| **00** | Clean Slate              | Reset all prior Terraform state and AWS resources to ensure a controlled starting point.      |
| **01** | GitHub Setup             | Initialise repo, apply correct `.gitignore`, add `.env.example`, connect project to GitHub.   |
| **02** | S3 Backend Setup         | Create backend S3 bucket + DynamoDB lock table for remote Terraform state.                    |
| **03** | GitHub OIDC + Secrets    | Create OIDC provider, IAM role for GitHub Actions, and configure repository secrets.          |
| **04** | GitHub Actions Workflows | Add `deploy.yml` and `destroy.yml` for automated deploys and safe environment destruction.    |
| **05** | UI Improvements          | Fix chat input focus issue, add optional avatar, update favicon.                              |
| **06** | Final Cleanup            | Destroy all environments and optionally delete GitHub Actions IAM role and Terraform backend. |

## 🗂️ **Project Structure**

```
LLMOps-Digital-Twin__GitHub_Actions/
├── backend/
├── frontend/
│   ├── components/twin.tsx      (input focus fix + avatar support)
│   ├── public/favicon.*         (updated favicon)
│   └── public/avatar.png        (optional)
├── terraform/
│   ├── backend.tf               (S3 backend config stub)
│   ├── main.tf / variables.tf
│   ├── outputs.tf
│   └── *.tfvars
├── scripts/
│   ├── deploy.sh / deploy.ps1
│   ├── destroy.sh / destroy.ps1
├── .github/
│   └── workflows/
│       ├── deploy.yml
│       └── destroy.yml
├── img/demo/twin_demo.gif
└── README.md
```

## 🧠 **Core Components**

### 🔐 Secure AWS Authentication (OIDC)

GitHub Actions authenticates with AWS using **OIDC**, removing the need for access keys.
A one-time Terraform file creates:

* GitHub OIDC provider
* IAM role (`github-actions-twin-deploy`)
* Policy attachments for Lambda, S3, API Gateway, CloudFront, DynamoDB, ACM, Route53, IAM (read + needed write)

The repo uses three secrets:

* `AWS_ROLE_ARN`
* `DEFAULT_AWS_REGION`
* `AWS_ACCOUNT_ID`

### 🗳️ Remote Terraform State (S3 + DynamoDB)

A one-time `backend-setup.tf` creates:

* An encrypted, versioned S3 bucket
* A DynamoDB lock table

Then Terraform is switched to:

```hcl
terraform {
  backend "s3" {}
}
```

All backend values are passed in by the deployment scripts.

### 🚀 GitHub Actions CI/CD

Two workflows live in `.github/workflows/`:

#### `deploy.yml`

Handles:

* OIDC authentication
* Terraform init/apply
* Lambda packaging
* Frontend build + S3 upload
* CloudFront invalidation
* URL output (CloudFront, API Gateway, frontend bucket)

Triggered by:

* Push to `main` → deploys dev automatically
* Manual run for `test` or `prod`

#### `destroy.yml`

Handles:

* Confirmation step
* Terraform destroy
* S3 emptying
* Safe teardown

Used to destroy `dev`, `test`, or `prod`.

### 💬 UI Enhancements

Inside `frontend/components/twin.tsx`:

* **Input box automatically regains focus** after each reply (fixes the annoying UX issue).
* **Optional avatar** at `frontend/public/avatar.png`.
* **Updated favicon** for a more polished UI.

## 🗑️ **Final Cleanup**

You may remove:

1. All environments using **Destroy Environment** workflow
2. GitHub Actions IAM role
3. Terraform state bucket
4. DynamoDB lock table

Ongoing costs if left in place: **< $0.05/month**.