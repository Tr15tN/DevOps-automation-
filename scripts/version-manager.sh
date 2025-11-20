#!/bin/bash
# Version Manager Script
# Tracks deployed versions and manages version history

set -e

# Configuration
APP_DIR="${APP_DIR:-/opt/app}"
VERSION_FILE="${APP_DIR}/.deployed-version"
PREVIOUS_VERSION_FILE="${APP_DIR}/.previous-version"
VERSION_HISTORY_FILE="${APP_DIR}/.version-history"

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
# YELLOW='\033[1;33m'  # Currently unused, reserved for future use
NC='\033[0m'

# Functions
save_version() {
    local version=$1
    local timestamp
    timestamp=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
    
    # Save current as previous
    if [ -f "$VERSION_FILE" ]; then
        local current
        current=$(cat "$VERSION_FILE")
        if [ -n "$current" ]; then
            echo "$current" > "$PREVIOUS_VERSION_FILE"
        fi
    fi
    
    # Save new version
    echo "$version" > "$VERSION_FILE"
    
    # Append to history
    echo "$timestamp|$version" >> "$VERSION_HISTORY_FILE"
    
    echo -e "${GREEN}✓${NC} Version saved: $version"
}

get_current_version() {
    if [ -f "$VERSION_FILE" ]; then
        cat "$VERSION_FILE"
    else
        echo "unknown"
    fi
}

get_previous_version() {
    if [ -f "$PREVIOUS_VERSION_FILE" ]; then
        cat "$PREVIOUS_VERSION_FILE"
    else
        echo "none"
    fi
}

list_history() {
    if [ -f "$VERSION_HISTORY_FILE" ]; then
        echo -e "${BLUE}Version History:${NC}"
        echo "=================="
        tail -10 "$VERSION_HISTORY_FILE" | while IFS='|' read -r timestamp version; do
            echo "$timestamp - $version"
        done
    else
        echo "No version history found"
    fi
}

# Main
case "${1:-}" in
    save)
        if [ -z "$2" ]; then
            echo "Usage: $0 save <version>"
            exit 1
        fi
        save_version "$2"
        ;;
    current)
        echo "Current version: $(get_current_version)"
        ;;
    previous)
        echo "Previous version: $(get_previous_version)"
        ;;
    history)
        list_history
        ;;
    *)
        echo "Version Manager"
        echo "=============="
        echo ""
        echo "Usage: $0 <command> [args]"
        echo ""
        echo "Commands:"
        echo "  save <version>    - Save a new version"
        echo "  current          - Show current version"
        echo "  previous         - Show previous version"
        echo "  history          - Show version history"
        echo ""
        echo "Current: $(get_current_version)"
        echo "Previous: $(get_previous_version)"
        ;;
esac

