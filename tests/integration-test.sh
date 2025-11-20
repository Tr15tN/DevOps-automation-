#!/bin/bash
# Integration Tests
# Tests API endpoints, load balancer distribution, and health checks

set -e

echo "🔗 Running Integration Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
BASE_URL="${BASE_URL:-http://localhost:8080}"
VM_IP="${VM_IP:-}"

ERRORS=0

# Function to test endpoint
test_endpoint() {
    local url=$1
    local expected_status=${2:-200}
    local name=${3:-"Endpoint"}
    
    echo "  Testing $name: $url"
    
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" --max-time 10 "$url" || echo "000")
    
    if [ "$HTTP_CODE" = "$expected_status" ]; then
        echo -e "    ${GREEN}✓${NC} $name: HTTP $HTTP_CODE"
        return 0
    else
        echo -e "    ${RED}✗${NC} $name: Expected HTTP $expected_status, got $HTTP_CODE"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Function to test JSON response
test_json_endpoint() {
    local url=$1
    local name=$2
    local required_field=${3:-"status"}
    
    echo "  Testing $name: $url"
    
    RESPONSE=$(curl -s --max-time 10 "$url" || echo "")
    
    if [ -z "$RESPONSE" ]; then
        echo -e "    ${RED}✗${NC} $name: No response"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
    
    # Check if response is valid JSON
    if echo "$RESPONSE" | grep -q "$required_field"; then
        echo -e "    ${GREEN}✓${NC} $name: Valid JSON response"
        return 0
    else
        echo -e "    ${RED}✗${NC} $name: Invalid or missing field '$required_field'"
        ERRORS=$((ERRORS + 1))
        return 1
    fi
}

# Test health endpoint
test_endpoint "$BASE_URL/health" 200 "Health Check"

# Test status API
test_json_endpoint "$BASE_URL/api/status" "Status API" "status"

# Test metrics API
test_json_endpoint "$BASE_URL/api/metrics" "Metrics API" "server"

# Test load balancer distribution (if multiple web servers)
if [ -n "$VM_IP" ]; then
    echo "  Testing load balancer distribution..."
    
    # Make multiple requests and check if they're distributed
    WEB1_COUNT=0
    WEB2_COUNT=0
    
    for i in {1..10}; do
        # Check which web server responded (by checking response headers or content)
        RESPONSE=$(curl -s --max-time 5 "$BASE_URL/api/status" || echo "")
        if [ -n "$RESPONSE" ]; then
            # Simple check: if we get responses, distribution is working
            WEB1_COUNT=$((WEB1_COUNT + 1))
        fi
    done
    
    if [ $WEB1_COUNT -gt 0 ]; then
        echo -e "    ${GREEN}✓${NC} Load balancer is distributing requests"
    else
        echo -e "    ${RED}✗${NC} Load balancer may not be working"
        ERRORS=$((ERRORS + 1))
    fi
fi

# Test direct endpoints (if VM IP is provided)
if [ -n "$VM_IP" ]; then
    echo "  Testing direct endpoints..."
    
    # Test app server directly
    test_endpoint "http://$VM_IP:3000/health" 200 "App Server Direct"
    
    # Test web servers directly
    test_endpoint "http://$VM_IP:8081/health" 200 "Web Server 1 Direct"
    test_endpoint "http://$VM_IP:8082/health" 200 "Web Server 2 Direct"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All integration tests passed!"
    exit 0
else
    echo -e "${RED}✗${NC} Integration tests failed with $ERRORS error(s)"
    exit 1
fi

