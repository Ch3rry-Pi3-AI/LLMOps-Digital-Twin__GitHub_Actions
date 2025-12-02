# ⚙️ Create GitHub Actions Workflows

This branch establishes automated CI/CD for the Digital Twin project using GitHub Actions and AWS OIDC.
It introduces the standard workflow directory structure and defines both deployment and destruction pipelines.
These workflows integrate tightly with the Terraform-based infrastructure created earlier.

## Part 1: Create GitHub Actions Workflow Directory

### Step 1: Create `.github/workflows/`

Set up the directory structure required for GitHub Actions:

1. In Cursor’s Explorer, right-click within the project
2. Select **New Folder** and name it `.github`
3. Right-click the `.github` folder
4. Select **New Folder**
5. Name it `workflows`

Your project should now include:

```
.github/
└── workflows/
```

GitHub automatically scans this location for workflow files.

## Part 2: Create Deployment Workflow

### Step 1: Add `deploy.yml`

Create the deployment workflow at:

```
.github/workflows/deploy.yml
```

This workflow performs the following:

* Automatically deploys on every push to `main`, or manually via workflow dispatch
* Authenticates with AWS using OpenID Connect
* Runs the Python backend build
* Applies Terraform for environment provisioning
* Builds and uploads the frontend to S3
* Invalidates CloudFront cache
* Outputs the deployment URLs for verification

Use the exact workflow YAML content provided in the instructions.

## Part 3: Create Destroy Workflow

### Step 1: Add `destroy.yml`

Create the destruction workflow at:

```
.github/workflows/destroy.yml
```

This workflow:

* Is manually triggered only
* Requires explicit typed confirmation to prevent accidental deletions
* Authenticates with AWS using OIDC
* Executes `scripts/destroy.sh` to remove infrastructure
* Cleans up all resources for dev, test, or prod
* Prints confirmation when the environment is fully torn down

Insert the YAML content exactly as given.

## Part 4: Commit and Push Workflows

### Step 1: Commit and publish workflow files

Use the following commands to add and push all changes:

```bash
git add .
git status
git commit -m "Add GitHub Actions deployment and destroy workflows"
git push
```

Once pushed, you will see both workflows under:

**GitHub → Actions**

They will now be active and ready for use.

## Part 5: Test the CI/CD Workflows

### Step 1: Automatic Dev Deployment

Since the workflows trigger on every push to the `main` branch:

1. Open your GitHub repository
2. Select the **Actions** tab
3. You should see **Deploy Digital Twin** running automatically
4. Open the workflow to follow its progress
5. Wait for it to complete (5–10 minutes)

After completion:

6. Expand the **Deployment Summary** step
7. You will see the environment URLs:

* CloudFront distribution URL
* API Gateway endpoint
* Frontend bucket name

8. Open the CloudFront URL in your browser to load the Digital Twin frontend.

### Step 2: Manual Test Deployment

To deploy to the test environment:

1. Go to the **Actions** tab
2. Select **Deploy Digital Twin**
3. Click **Run workflow**
4. Enter:

   * Branch: `main`
   * Environment: `test`
5. Run the workflow
6. Follow the real-time logs until completion

### Step 3: Manual Production Deployment

If your project includes a custom domain:

1. Go to **Actions**
2. Open **Deploy Digital Twin**
3. Click **Run workflow**
4. Select:

   * Branch: `main`
   * Environment: `prod`
5. Run the workflow

The production deployment may take slightly longer depending on CloudFront caching and certificate validation.

### Step 4: Verify Each Deployment

Once each environment has deployed:

1. Review the workflow summary
2. Copy the CloudFront URL
3. Visit the URL in your browser
4. Interact with your Digital Twin to confirm expected behaviour

Your CI/CD pipeline is now fully operational across all environments.

## Result

This branch introduces a complete CI/CD automation layer, enabling:

* Zero-touch deployments on push
* Manual multi-environment deployments
* Safe destruction workflows
* AWS authentication using secure OIDC
* Terraform-managed infrastructure provisioning
* Automated frontend distribution and CloudFront invalidation

Your Digital Twin now has a modern, reproducible, and production-ready deployment pipeline.
