#!/bin/sh
# Module: openclaw-message-listener plugin setup
# Copies the plugin from host to container extensions directory

PLUGIN_NAME="openclaw-message-listener"
PLUGIN_SOURCE="/extensions/$PLUGIN_NAME"
PLUGIN_DEST="/home/node/.openclaw/extensions/$PLUGIN_NAME"

echo "Setting up $PLUGIN_NAME plugin..."

# Check if plugin source exists
if [ ! -d "$PLUGIN_SOURCE" ]; then
    echo "Error: Plugin source not found at $PLUGIN_SOURCE"
    echo "Please ensure the extensions directory is mounted in docker-compose.yml"
    exit 1
fi

# Create extensions directory if it doesn't exist
mkdir -p "$(dirname "$PLUGIN_DEST")"

# Copy plugin to extensions directory
if [ -d "$PLUGIN_DEST" ]; then
    echo "Plugin already exists at $PLUGIN_DEST, updating..."
    rm -rf "$PLUGIN_DEST"
fi

cp -R "$PLUGIN_SOURCE" "$PLUGIN_DEST"
echo "Plugin copied to $PLUGIN_DEST"

# Verify plugin was copied
if [ -d "$PLUGIN_DEST" ]; then
    echo "✓ $PLUGIN_NAME plugin installed successfully"
else
    echo "✗ Failed to install $PLUGIN_NAME plugin"
    exit 1
fi
