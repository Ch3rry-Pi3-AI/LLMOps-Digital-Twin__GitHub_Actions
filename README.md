# 🗂️ **Initialize Git Repository — Branch Overview**

This branch prepares the project for source control and later CI/CD automation.
It guides the user through setting up `.gitignore`, initialising Git from a clean state, configuring user details, and pushing the Digital Twin project to GitHub.

## **Step 1: Create a Complete `.gitignore`**

Ensure the root `.gitignore` (`twin/.gitignore`) contains all required exclusions, including Terraform state, Lambda artefacts, environment files, frontend build outputs, Python caches, and AWS credentials.

```gitignore
# Terraform
*.tfstate
*.tfstate.*
.terraform/
.terraform.lock.hcl
terraform.tfstate.d/
*.tfvars.secret

# Lambda packages
lambda-deployment.zip
lambda-package/

# Memory storage (conversation history)
memory/

# Environment files
.env
.env.*
!.env.example

# Node
node_modules/
out/
.next/
*.log

# Python
__pycache__/
*.pyc
.venv/
venv/

# IDE
.vscode/
.idea/
*.swp
.DS_Store
Thumbs.db

# AWS
.aws/
```

This ensures sensitive files, generated artefacts, and platform-specific clutter do not enter version control.

## **Step 2: Create Example Environment File**

Provide a template `.env.example` to document required environment variables without exposing secrets.

Create the file at `twin/.env.example`:

```bash
# AWS Configuration
AWS_ACCOUNT_ID=your_12_digit_account_id
DEFAULT_AWS_REGION=us-east-1

# Project Configuration
PROJECT_NAME=twin
```

This file will serve as the basis for `.env` files used during deployment.

## **Step 3: Initialise Git in a Clean State**

Remove any nested git repositories created by tools such as `create-next-app` or `uv`.

### Mac/Linux

```bash
cd twin

rm -rf frontend/.git backend/.git 2>/dev/null

git init -b main

# If your Git version does not support -b:
# git init
# git checkout -b main

git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Windows (PowerShell)

```powershell
cd twin

Remove-Item -Path frontend/.git -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item -Path backend/.git -Recurse -Force -ErrorAction SilentlyContinue

git init -b main

# If -b is not supported:
# git init
# git checkout -b main

git config user.name "Your Name"
git config user.email "your.email@example.com"
```

### Add and commit all files

```bash
git add .
git commit -m "Initial commit: Digital Twin infrastructure and application"
```

Your repository is now initialised with a clean history and correct root-level structure.

## **Step 4: Create a New GitHub Repository**

1. Navigate to [https://github.com](https://github.com)

2. Select **New repository**

3. Configure:

   * **Repository name:** `digital-twin` (or your preferred name)
   * **Description:** AI Digital Twin deployed on AWS with Terraform
   * **Visibility:** Public or Private (Private recommended for personal data)
   * **Important:** Do **not** initialise with a README, `.gitignore`, or license

4. Click **Create repository**

GitHub will now give you a remote URL and push instructions.

## **Step 5: Push Local Repository to GitHub**

Replace `YOUR_USERNAME` with your GitHub username:

```bash
git remote add origin https://github.com/YOUR_USERNAME/digital-twin.git
git push -u origin main
```

If authentication is requested:

* **Username:** your GitHub username
* **Password:** a **Personal Access Token**

  * Generate at: GitHub → Settings → Developer settings → Personal access tokens
  * Select at least the `repo` scope

## **Checkpoint**

Your Digital Twin project is now:

* Version-controlled
* Cleanly initialised
* Structured for collaboration
* Ready for GitHub Actions and full CI/CD in the next Steps
