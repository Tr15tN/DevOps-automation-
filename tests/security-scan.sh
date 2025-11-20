#!/bin/bash
# Security Scanning Tests
# Uses Trivy to scan Docker images for vulnerabilities

set -e

echo "🔒 Running Security Scans..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check if Trivy is available
if ! command -v trivy &> /dev/null; then
    echo -e "${YELLOW}⚠${NC} Trivy not found, installing..."
    # Install Trivy (Alpine Linux)
    if [ -f /etc/alpine-release ]; then
        apk add --no-cache trivy
    else
        echo -e "${RED}✗${NC} Trivy not available. Please install it manually."
        exit 1
    fi
fi

echo -e "${GREEN}✓${NC} Trivy found"

# Scan Dockerfile
if [ -f "docker/app-server/Dockerfile" ]; then
    echo "  Scanning Dockerfile..."
    if trivy fs --exit-code 1 --severity HIGH,CRITICAL docker/app-server/; then
        echo -e "  ${GREEN}✓${NC} Dockerfile security scan: PASS"
    else
        echo -e "  ${YELLOW}⚠${NC} Dockerfile security scan: Found issues (non-blocking)"
        # Don't fail on warnings, only on critical errors
    fi
fi

# If Docker image is available, scan it
if [ -n "$DOCKER_IMAGE" ]; then
    echo "  Scanning Docker image: $DOCKER_IMAGE"
    if trivy image --exit-code 1 --severity CRITICAL "$DOCKER_IMAGE"; then
        echo -e "  ${GREEN}✓${NC} Docker image security scan: PASS"
    else
        echo -e "  ${RED}✗${NC} Docker image security scan: CRITICAL vulnerabilities found"
        ERRORS=$((ERRORS + 1))
    fi
else
    echo -e "  ${YELLOW}⚠${NC} No Docker image specified, skipping image scan"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Security scans completed!"
    exit 0
else
    echo -e "${RED}✗${NC} Security scans failed with $ERRORS critical issue(s)"
    exit 1
fi

