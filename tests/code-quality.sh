#!/bin/bash
# Code Quality Tests
# Runs ESLint for JavaScript and ShellCheck for bash scripts

set -e

echo "🔍 Running Code Quality Tests..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

ERRORS=0

# Check if ESLint is available
if command -v eslint &> /dev/null; then
    echo -e "${GREEN}✓${NC} ESLint found"
    
    # Check JavaScript files
    if [ -f "docker/app-server/server.js" ]; then
        echo "  Checking JavaScript files..."
        # Run ESLint from the app-server directory so it finds eslint.config.js
        if (cd docker/app-server && eslint server.js); then
            echo -e "  ${GREEN}✓${NC} JavaScript code quality: PASS"
        else
            echo -e "  ${RED}✗${NC} JavaScript code quality: FAIL"
            ERRORS=$((ERRORS + 1))
        fi
    fi
else
    echo -e "${YELLOW}⚠${NC} ESLint not found, skipping JavaScript checks"
fi

# Check if ShellCheck is available
if command -v shellcheck &> /dev/null; then
    echo -e "${GREEN}✓${NC} ShellCheck found"
    
    # Find all shell scripts
    echo "  Checking shell scripts..."
    SHELL_SCRIPTS=$(find . -type f -name "*.sh" ! -path "./.git/*" ! -path "./node_modules/*")
    
    if [ -z "$SHELL_SCRIPTS" ]; then
        echo -e "  ${YELLOW}⚠${NC} No shell scripts found"
    else
        for script in $SHELL_SCRIPTS; do
            echo "    Checking: $script"
            if shellcheck "$script"; then
                echo -e "      ${GREEN}✓${NC} $script"
            else
                echo -e "      ${RED}✗${NC} $script"
                ERRORS=$((ERRORS + 1))
            fi
        done
    fi
else
    echo -e "${YELLOW}⚠${NC} ShellCheck not found, skipping shell script checks"
fi

# Summary
echo ""
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✓${NC} All code quality checks passed!"
    exit 0
else
    echo -e "${RED}✗${NC} Code quality checks failed with $ERRORS error(s)"
    exit 1
fi

