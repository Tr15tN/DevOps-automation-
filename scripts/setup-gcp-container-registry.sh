#!/bin/bash
# Setup script for GCP Container Registry
# This script helps set up the Container Registry and service account for GitLab CI

set -e

PROJECT_ID="${GCP_PROJECT_ID:-automation-alchemy}"
SA_NAME="gitlab-ci"
SA_EMAIL="${SA_NAME}@${PROJECT_ID}.iam.gserviceaccount.com"

echo "🔧 Setting up GCP Container Registry for GitLab CI"
echo "Project ID: ${PROJECT_ID}"
echo ""

# Check if gcloud is installed
if ! command -v gcloud &> /dev/null; then
    echo "❌ Error: gcloud CLI is not installed"
    echo "Install it from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

# Set project
echo "📋 Setting GCP project..."
gcloud config set project ${PROJECT_ID}

# Enable Container Registry API
echo "🔌 Enabling Container Registry API..."
gcloud services enable containerregistry.googleapis.com --project=${PROJECT_ID}

# Check if service account exists
if gcloud iam service-accounts describe ${SA_EMAIL} --project=${PROJECT_ID} &> /dev/null; then
    echo "⚠️  Service account ${SA_EMAIL} already exists"
    read -p "Do you want to recreate it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "🗑️  Deleting existing service account..."
        gcloud iam service-accounts delete ${SA_EMAIL} --project=${PROJECT_ID} --quiet || true
    else
        echo "✅ Using existing service account"
        SKIP_SA_CREATION=true
    fi
fi

# Create service account if needed
if [ "${SKIP_SA_CREATION}" != "true" ]; then
    echo "👤 Creating service account..."
    gcloud iam service-accounts create ${SA_NAME} \
        --display-name="GitLab CI Service Account" \
        --project=${PROJECT_ID}
fi

# Grant permissions
echo "🔐 Granting permissions..."
gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/storage.admin" \
    --condition=None

gcloud projects add-iam-policy-binding ${PROJECT_ID} \
    --member="serviceAccount:${SA_EMAIL}" \
    --role="roles/iam.serviceAccountUser" \
    --condition=None

# Create and download key
echo "🔑 Creating service account key..."
KEY_FILE="gitlab-ci-key.json"
gcloud iam service-accounts keys create ${KEY_FILE} \
    --iam-account=${SA_EMAIL} \
    --project=${PROJECT_ID}

# Encode key for GitLab
echo ""
echo "📝 Base64 encoded key (for GitLab CI variable GCP_SERVICE_ACCOUNT_KEY):"
echo "=========================================="
if [[ "$OSTYPE" == "darwin"* ]]; then
    # macOS
    cat ${KEY_FILE} | base64
elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
    # Linux
    cat ${KEY_FILE} | base64 -w 0
else
    # Windows (Git Bash)
    cat ${KEY_FILE} | base64 -w 0
fi
echo ""
echo "=========================================="
echo ""

# Cleanup instructions
echo "✅ Setup complete!"
echo ""
echo "📋 Next steps:"
echo "1. Copy the base64 encoded key above"
echo "2. Go to GitLab → Settings → CI/CD → Variables"
echo "3. Add variable: GCP_SERVICE_ACCOUNT_KEY (paste the base64 key)"
echo "4. Mark it as Protected and Masked"
echo "5. Delete ${KEY_FILE} from your local machine (it contains sensitive data)"
echo ""
echo "⚠️  Security: Delete ${KEY_FILE} after adding it to GitLab!"

