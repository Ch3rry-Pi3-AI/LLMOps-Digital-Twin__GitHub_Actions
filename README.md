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

Expected console output:

```
Initializing the backend...
Initializing provider plugins...
- Finding hashicorp/aws versions matching "~> 6.0"...
- Installing hashicorp/aws v6.23.0...
- Installed hashicorp/aws v6.23.0 (signed by HashiCorp)
Terraform has created a lock file .terraform.lock.hcl to record the provider
selections it made above. Include this file in your version control repository
so that Terraform can guarantee to make the same selections by default when
you run "terraform init" in the future.

Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

Terraform is now ready to manage infrastructure for your Digital Twin.

### **2. Deploy Using the Script**

You can now deploy *everything* automatically using the deployment scripts created in this branch.

#### **Mac/Linux**

```bash
./scripts/deploy.sh dev
```

#### **Windows PowerShell**

```powershell
.\scripts\deploy.ps1 -Environment dev
```

The script performs the full pipeline:

1. Builds and packages the Lambda function
2. Creates or selects the correct Terraform workspace
3. Applies the Terraform infrastructure
4. Builds your frontend
5. Uploads the static site to S3
6. Prints all deployment URLs (CloudFront, API Gateway, etc.)

### **3. Test the Deployed Dev Environment**

Once deployment completes:

1. Open the **CloudFront URL** displayed in the script’s output
2. Confirm the frontend loads correctly
3. Test the chat functionality to verify end-to-end behaviour

If everything works, your **development environment is now fully operational**, deployed entirely through automated scripts.

## ✅ Branch Summary

This branch establishes the foundation for repeatable, automated deployments. From now on, bringing up or updating the dev environment is as simple as running:

```bash
./scripts/deploy.sh dev
```

(or the PowerShell equivalent on Windows)

This ensures consistent deployments and prepares you for the CI/CD automation in upcoming branches.
