#!/bin/bash
# Rollback Script
# Reverts to a previous Docker image version

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
APP_DIR="${APP_DIR:-/opt/app}"
VERSION_FILE="${APP_DIR}/.deployed-version"
PREVIOUS_VERSION_FILE="${APP_DIR}/.previous-version"
CONTAINER_REGISTRY="${CONTAINER_REGISTRY:-europe-north1-docker.pkg.dev}"
GCP_PROJECT_ID="${GCP_PROJECT_ID:-automation-alchemy}"
IMAGE_NAME="${IMAGE_NAME:-app-server}"

echo -e "${BLUE}🔄 Rollback Script${NC}"
echo "=================="
echo ""

# Check if version file exists
if [ ! -f "$VERSION_FILE" ]; then
    echo -e "${RED}✗${NC} No version file found at $VERSION_FILE"
    echo "This might be the first deployment. Cannot rollback."
    exit 1
fi

# Read current version
CURRENT_VERSION=$(cat "$VERSION_FILE" 2>/dev/null || echo "")
if [ -z "$CURRENT_VERSION" ]; then
    echo -e "${RED}✗${NC} Current version file is empty"
    exit 1
fi

# Read previous version
PREVIOUS_VERSION=$(cat "$PREVIOUS_VERSION_FILE" 2>/dev/null || echo "")

if [ -z "$PREVIOUS_VERSION" ]; then
    echo -e "${YELLOW}⚠${NC} No previous version found"
    echo "Current version: $CURRENT_VERSION"
    echo ""
    echo "Available options:"
    echo "1. Use 'latest' tag"
    echo "2. Specify a version manually"
    echo ""
    read -p "Enter version to rollback to (or 'latest'): " ROLLBACK_VERSION
    if [ -z "$ROLLBACK_VERSION" ]; then
        ROLLBACK_VERSION="latest"
    fi
else
    ROLLBACK_VERSION="$PREVIOUS_VERSION"
    echo -e "${GREEN}✓${NC} Previous version found: $PREVIOUS_VERSION"
fi

# Construct image path
if [ "$ROLLBACK_VERSION" = "latest" ]; then
    ROLLBACK_IMAGE="${CONTAINER_REGISTRY}/${GCP_PROJECT_ID}/${IMAGE_NAME}/${IMAGE_NAME}:latest"
else
    ROLLBACK_IMAGE="${CONTAINER_REGISTRY}/${GCP_PROJECT_ID}/${IMAGE_NAME}/${IMAGE_NAME}:${ROLLBACK_VERSION}"
fi

echo ""
echo "Current version:  $CURRENT_VERSION"
echo "Rollback version: $ROLLBACK_VERSION"
echo "Rollback image:   $ROLLBACK_IMAGE"
echo ""

# Confirm rollback
read -p "Are you sure you want to rollback? (yes/no): " CONFIRM
if [ "$CONFIRM" != "yes" ]; then
    echo "Rollback cancelled."
    exit 0
fi

echo ""
echo -e "${BLUE}Starting rollback...${NC}"

# Save current version as previous
echo "$CURRENT_VERSION" > "$PREVIOUS_VERSION_FILE"

# Update version file with rollback version
echo "$ROLLBACK_VERSION" > "$VERSION_FILE"

# Pull the rollback image
echo "Pulling rollback image: $ROLLBACK_IMAGE"
docker pull "$ROLLBACK_IMAGE" || {
    echo -e "${RED}✗${NC} Failed to pull rollback image"
    exit 1
}

# Update docker-compose.yml to use rollback image
cd "$APP_DIR"
if [ -f "docker-compose.yml" ]; then
    # Backup current docker-compose.yml
    cp docker-compose.yml docker-compose.yml.backup
    
    # Update image in docker-compose.yml
    if grep -q "image:" docker-compose.yml; then
        # Replace the image line for app-server
        sed -i "s|image:.*app-server.*|image: ${ROLLBACK_IMAGE}|g" docker-compose.yml
    else
        echo -e "${YELLOW}⚠${NC} Could not find image line in docker-compose.yml"
        echo "You may need to manually update docker-compose.yml"
    fi
fi

# Restart containers
echo "Restarting containers..."
docker compose up -d --pull always || {
    echo -e "${RED}✗${NC} Failed to restart containers"
    echo "Restoring backup..."
    mv docker-compose.yml.backup docker-compose.yml
    exit 1
}

# Wait for containers to be healthy
echo "Waiting for containers to be healthy..."
sleep 10

# Verify rollback
if docker ps | grep -q "app-server.*healthy"; then
    echo -e "${GREEN}✓${NC} Rollback successful!"
    echo ""
    echo "Current version: $ROLLBACK_VERSION"
    echo "Previous version (now): $CURRENT_VERSION"
else
    echo -e "${YELLOW}⚠${NC} Container may not be healthy yet"
    echo "Check status with: docker ps"
fi

echo ""
echo -e "${GREEN}Rollback complete!${NC}"

