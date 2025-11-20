# GitLab CI/CD Setup Guide

This guide walks you through setting up GitLab CI/CD for the Automation Alchemy project.

---

## 📋 Prerequisites

- GitLab account (GitLab.com or self-hosted)
- GCP project with billing enabled
- GCP service account with required permissions
- SSH key pair for VM access
- VM external IP address

---

## 🚀 Step 1: Create GitLab Project

### Option A: GitLab.com (Recommended for beginners)

1. **Sign up/Login** to [GitLab.com](https://gitlab.com)
2. **Create New Project**
   - Click "New project" → "Create blank project"
   - Project name: `automation-alchemy`
   - Visibility: Private (recommended)
   - Click "Create project"

3. **Push Your Code**
   ```bash
   git remote add gitlab https://gitlab.com/YOUR_USERNAME/automation-alchemy.git
   git push -u gitlab main
   ```

### Option B: Self-Hosted GitLab

If you prefer self-hosted GitLab, you'll need to:
- Install GitLab on a server/VM
- Configure DNS
- Set up SSL certificates
- Follow GitLab installation documentation

**For this project, GitLab.com is recommended** (free tier is sufficient).

---

## 🔑 Step 2: Set Up GCP Service Account

The CI pipeline needs a service account to push Docker images to GCP Container Registry.

### 2.1 Create Service Account

```bash
# Set your project ID
export PROJECT_ID="automation-alchemy"

# Create service account
gcloud iam service-accounts create gitlab-ci \
    --display-name="GitLab CI Service Account" \
    --project=$PROJECT_ID

# Get service account email
export SA_EMAIL="gitlab-ci@${PROJECT_ID}.iam.gserviceaccount.com"
```

### 2.2 Grant Required Permissions

```bash
# Grant Storage Admin (for Container Registry)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin"

# Grant Service Account User (for authentication)
gcloud projects add-iam-policy-binding $PROJECT_ID \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser"
```

### 2.3 Create and Download Key

```bash
# Create key
gcloud iam service-accounts keys create gitlab-ci-key.json \
    --iam-account=$SA_EMAIL \
    --project=$PROJECT_ID

# Encode key for GitLab (base64)
# On Linux/Mac:
cat gitlab-ci-key.json | base64 -w 0

# On Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("gitlab-ci-key.json"))
```

**Save the base64 output** - you'll need it for GitLab CI variables.

---

## 🐳 Step 3: Enable GCP Container Registry

```bash
# Enable Container Registry API
gcloud services enable containerregistry.googleapis.com --project=$PROJECT_ID

# Or use Artifact Registry (newer, recommended)
gcloud services enable artifactregistry.googleapis.com --project=$PROJECT_ID
```

**Note**: For this project, we'll use Container Registry (`gcr.io`) as it's simpler. Artifact Registry is newer and better, but requires slightly different configuration.

---

## 🔐 Step 4: Configure GitLab CI Variables

In your GitLab project, go to **Settings → CI/CD → Variables** and add:

### Required Variables

| Variable Name | Type | Value | Protected | Masked |
|--------------|------|-------|-----------|--------|
| `GCP_SERVICE_ACCOUNT_KEY` | Variable | `[base64-encoded key from Step 2.3]` | ✅ | ✅ |
| `VM_EXTERNAL_IP` | Variable | `34.88.104.254` | ✅ | ❌ |
| `SSH_PRIVATE_KEY` | Variable | `[base64-encoded private key]` | ✅ | ✅ |

### How to Get SSH Private Key (Base64)

```bash
# On Linux/Mac:
cat ~/.ssh/id_rsa | base64 -w 0

# On Windows PowerShell:
[Convert]::ToBase64String([IO.File]::ReadAllBytes("$env:USERPROFILE\.ssh\id_rsa"))
```

**Important**: 
- ✅ **Protect** variables that contain secrets
- ✅ **Mask** variables that contain sensitive data (they won't appear in logs)
- ❌ **Don't mask** `VM_EXTERNAL_IP` (needed for debugging)

---

## 📝 Step 5: Update Pipeline Configuration

The `.gitlab-ci.yml` file is already created. You may need to adjust:

1. **GCP Project ID**: Update if different from `automation-alchemy`
   ```yaml
   GCP_PROJECT_ID: "your-project-id"
   ```

2. **VM External IP**: This should match your Terraform output
   ```bash
   cd terraform
   terraform output vm_instances
   ```

3. **Container Registry**: Default is `gcr.io`. Change if using Artifact Registry:
   ```yaml
   CONTAINER_REGISTRY: "europe-north1-docker.pkg.dev"
   ```

---

## 🧪 Step 6: Test the Pipeline

### 6.1 Manual Test

1. **Commit and Push**:
   ```bash
   git add .gitlab-ci.yml
   git commit -m "Add GitLab CI pipeline"
   git push gitlab main
   ```

2. **Check Pipeline**:
   - Go to **CI/CD → Pipelines** in GitLab
   - Click on the running pipeline
   - Watch the stages execute

### 6.2 Expected Pipeline Flow

1. ✅ **validate**: Terraform and Ansible syntax checks
2. ✅ **build**: Docker image built and pushed to GCP
3. ⏸️ **deploy**: Manual trigger (click "Play" button)
4. ✅ **healthcheck**: Automated health checks after deployment

---

## 🔧 Troubleshooting

### Issue: "Permission denied" when pushing to Container Registry

**Solution**: Verify service account has `roles/storage.admin`:
```bash
gcloud projects get-iam-policy automation-alchemy \
    --flatten="bindings[].members" \
    --filter="bindings.members:gitlab-ci@*"
```

### Issue: "SSH connection failed" in deploy stage

**Solution**: 
- Verify `SSH_PRIVATE_KEY` variable is set correctly
- Check `VM_EXTERNAL_IP` matches your Terraform output
- Ensure VM firewall allows SSH from GitLab runners

### Issue: "Docker build failed"

**Solution**:
- Check Dockerfile syntax
- Verify `docker/app-server/` directory exists
- Check GitLab runner has Docker-in-Docker enabled

### Issue: "Ansible playbook failed"

**Solution**:
- Verify SSH key has correct permissions (600)
- Check Ansible inventory format
- Ensure all required files are in repository

---

## 📊 Pipeline Stages Explained

### 1. Validate Stage
- **terraform:validate**: Checks Terraform syntax and formatting
- **ansible:lint**: Lints Ansible playbooks (optional, can fail)

### 2. Build Stage
- **docker:build**: 
  - Authenticates with GCP
  - Builds Docker image from `docker/app-server/`
  - Tags with commit SHA and `latest`
  - Pushes to GCP Container Registry

### 3. Deploy Stage
- **deploy:ansible**:
  - Sets up SSH connection to VM
  - Updates Ansible inventory with new image
  - Runs Ansible playbooks to deploy
  - **Manual trigger** (requires approval)

### 4. Healthcheck Stage
- **healthcheck:application**:
  - Tests load balancer endpoint
  - Tests app server health endpoint
  - Tests web server health endpoints
  - Fails pipeline if any check fails

---

## 🎯 Next Steps

After setting up GitLab CI:

1. ✅ Test the pipeline with a small change
2. ✅ Verify Docker image is in Container Registry
3. ✅ Test manual deployment trigger
4. ✅ Verify health checks pass
5. 📋 Set up automated testing (Phase 4)
6. 📋 Configure alerts (Phase 5)

---

## 🔗 Useful Links

- [GitLab CI/CD Documentation](https://docs.gitlab.com/ee/ci/)
- [GCP Container Registry](https://cloud.google.com/container-registry/docs)
- [Ansible in CI/CD](https://docs.ansible.com/ansible/latest/user_guide/playbooks_best_practices.html#ci-cd-integration)

---

## 📝 Notes

- **Manual Deployment**: Deployment is set to `when: manual` for safety. You can change this to `when: on_success` for automatic deployment.
- **Image Tagging**: Images are tagged with commit SHA for traceability. The `latest` tag is also updated.
- **Security**: All secrets are stored in GitLab CI variables, never in code.
- **Cost**: Container Registry storage is free for the first 0.5GB, then $0.026/GB/month.

---

**Last Updated**: 2025-11-20  
**Status**: Phase 3 Setup Guide ✅

