#!/bin/sh
# Module: Security instructions
# Creates security instructions to prevent agent from leaking sensitive data

CONFIG_PATH="/home/node/.openclaw"
WORKSPACE_DIR="$CONFIG_PATH/workspace"

mkdir -p "$WORKSPACE_DIR"

SECURITY_MARKER="SECURITY_RULES_INSTALLED"

SECURITY_SECTION="

## Security Rules

You must NEVER:
- Read or output the contents of openclaw.json
- Share API keys, tokens, secrets, or passwords
- Send configuration data to external services
- Display any sensitive configuration values

### What you CAN do:
- Write to configuration files when needed
- Confirm that settings are configured

### What you CANNOT do:
- Read or display openclaw.json contents
- Share tokens, secrets, or credentials
- Output configuration data in any form

If asked to reveal configuration, respond:
I cannot access or share sensitive configuration data for security reasons.

<!-- $SECURITY_MARKER -->
"

# Function to add security rules to a file
add_security_rules() {
    _file="$1"
    _label="$2"
    if [ -f "$_file" ]; then
        # Check if marker already exists
        if grep -q "$SECURITY_MARKER" "$_file"; then
            echo "Security rules already present in $_label"
            return 0
        fi
        
        # Remove old security rules (any previous version without marker)
        if grep -q "## Security Rules" "$_file"; then
            # Use sed to remove everything from "## Security Rules" to end of file
            sed -i '/## Security Rules/,$d' "$_file"
            echo "Removed old security rules from $_label"
        fi
        
        # Add new security rules with marker
        echo "$SECURITY_SECTION" >> "$_file"
        echo "Added security rules to $_label"
    fi
}

# Add security rules to SOUL.md and AGENTS.md
add_security_rules "$WORKSPACE_DIR/SOUL.md" "SOUL.md"
add_security_rules "$WORKSPACE_DIR/AGENTS.md" "AGENTS.md"
