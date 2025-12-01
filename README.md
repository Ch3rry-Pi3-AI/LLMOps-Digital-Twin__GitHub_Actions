# 🚀 Deploy Development Environment
# 🚀 Deploy Development Environment

This branch introduces automated deployment for the **development environment**, using a combination of Terraform and custom deployment scripts. Once completed, your entire system (backend, frontend, infrastructure) can be deployed with a single command.

## 📂 What This Stage Covers

This branch adds:

* Terraform initialisation
* Automated deployment scripts (`deploy.sh` and `deploy.ps1`)
* A one-step deployment flow for the full dev environment
* CloudFront + Lambda + API Gateway + S3 provisioning
* Frontend build and upload automation

## 🧩 Steps Completed in This Branch

### **1. Initialise Terraform**

From the project root:

```bash
cd terraform
terraform init
```

Expected output:

```
Initializing the backend...
Initializing provider plugins...
- Installing hashicorp/aws v6.x.x...
Terraform has been successfully initialized!
```

### Step 2: Deploy Using the Script

Mac/Linux:

```bash
./scripts/deploy.sh dev
```

Windows PowerShell:

```powershell
.\scripts\deploy.ps1 -Environment dev
```

The script performs:

1. Lambda packaging
2. Terraform workspace creation
3. Full infrastructure deployment
4. Frontend build & S3 upload
5. Summary URLs printed to screen

### Step 3: Test Your Development Environment

1. Open the CloudFront URL in your browser
2. Confirm the UI loads correctly
3. Test the chat functionality

Your **dev environment is now live**, deployed entirely through automated scripts.
