#!/bin/bash
# Performance Tests
# Load testing with curl/Apache Bench

set -e

echo "⚡ Running Performance Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Configuration
TARGET_URL="${TARGET_URL:-http://localhost:8080}"
REQUESTS="${REQUESTS:-100}"
CONCURRENCY="${CONCURRENCY:-10}"
MAX_RESPONSE_TIME="${MAX_RESPONSE_TIME:-1000}" # milliseconds

ERRORS=0

# Function to test endpoint
test_endpoint() {
    local url=$1
    local name=$2
    
    echo "  Testing $name: $url"
    
    # Check if Apache Bench is available
    if command -v ab &> /dev/null; then
        echo "    Using Apache Bench..."
        if ab -n "$REQUESTS" -c "$CONCURRENCY" -q "$url" > /tmp/ab_output.txt 2>&1; then
            # Extract average response time
            AVG_TIME=$(grep "Time per request" /tmp/ab_output.txt | head -1 | awk '{print $4}' | cut -d'(' -f1)
            AVG_TIME_MS=$(echo "$AVG_TIME * 1000" | bc | cut -d'.' -f1)
            
            echo "    Average response time: ${AVG_TIME_MS}ms"
            
            if [ "$AVG_TIME_MS" -lt "$MAX_RESPONSE_TIME" ]; then
                echo -e "    ${GREEN}✓${NC} Response time acceptable (< ${MAX_RESPONSE_TIME}ms)"
            else
                echo -e "    ${YELLOW}⚠${NC} Response time high (${AVG_TIME_MS}ms > ${MAX_RESPONSE_TIME}ms)"
            fi
            
            # Check for failed requests
            FAILED=$(grep "Failed requests" /tmp/ab_output.txt | awk '{print $3}')
            if [ "$FAILED" = "0" ]; then
                echo -e "    ${GREEN}✓${NC} No failed requests"
            else
                echo -e "    ${RED}✗${NC} Failed requests: $FAILED"
                ERRORS=$((ERRORS + 1))
            fi
        else
            echo -e "    ${RED}✗${NC} Load test failed"
            ERRORS=$((ERRORS + 1))
        fi
    else
        # Fallback to curl-based testing
        echo "    Using curl (Apache Bench not available)..."
        SUCCESS=0
        FAILED=0
        
        for _ in $(seq 1 "$REQUESTS"); do
            if curl -f -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" | grep -q "200"; then
                SUCCESS=$((SUCCESS + 1))
            else
                FAILED=$((FAILED + 1))
            fi
        done
        
        echo "    Successful requests: $SUCCESS/$REQUESTS"
        if [ "$FAILED" -eq 0 ]; then
            echo -e "    ${GREEN}✓${NC} All requests succeeded"
        else
            echo -e "    ${RED}✗${NC} Failed requests: $FAILED"
            ERRORS=$((ERRORS + 1))
        fi
    fi
}

# Test main endpoints
test_endpoint "$TARGET_URL" "Load Balancer"
test_endpoint "$TARGET_URL/health" "Health Endpoint"
test_endpoint "$TARGET_URL/api/status" "Status API"

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} Performance tests passed!"
    exit 0
else
    echo -e "${RED}✗${NC} Performance tests failed with $ERRORS error(s)"
    exit 1
fi

