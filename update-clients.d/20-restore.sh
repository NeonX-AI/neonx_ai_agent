#!/usr/bin/env bash
set -euo pipefail

source "$SCRIPT_DIR/update-clients.d/00-common.sh"

# Ensure Facebook plugin dist/ directory is restored from git (macOS filesystem issue)
FACEBOOK_DIST_DIR="$TEMPLATES_DIR/agent_data/extensions/facebook/dist"
if [ ! -d "$FACEBOOK_DIST_DIR" ] || [ -z "$(ls -A "$FACEBOOK_DIST_DIR" 2>/dev/null)" ]; then
    echo ">>> Restoring Facebook plugin dist/ from git..."
    mkdir -p "$FACEBOOK_DIST_DIR"
    if git archive HEAD:templates/agent_data/extensions/facebook/dist 2>/dev/null | tar -x -C "$FACEBOOK_DIST_DIR" 2>/dev/null; then
        echo "  ✓ Facebook plugin dist/ restored ($(find "$FACEBOOK_DIST_DIR" -type f | wc -l) files)"
    else
        echo "  ✗ Failed to restore Facebook plugin dist/ from git"
    fi
fi
