#!/bin/bash

# Cross-platform build and run script for OpenClaw message listener
# Works on both macOS and Ubuntu

set -e  # Exit on any error

# Detect OS
OS_TYPE=$(uname -s | tr '[:upper:]' '[:lower:]')

echo "Detected OS: $OS_TYPE"

# Navigate to the project directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

cd templates

echo "Current directory: $(pwd)"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

if ! command_exists docker-compose; then
    echo "Warning: docker-compose not found"
    if ! command_exists docker compose; then
        echo "Error: Neither 'docker-compose' nor 'docker compose' found"
        echo "Please install Docker Compose"
        exit 1
    else
        # Use 'docker compose' instead of 'docker-compose'
        COMPOSE_CMD="docker compose"
    fi
else
    COMPOSE_CMD="docker-compose"
fi

echo "Using compose command: $COMPOSE_CMD"

# Check if Node.js and npm are available for building TypeScript
if command_exists node && command_exists npm; then
    echo "Node.js and npm found, building TypeScript..."
    
    # Navigate to the plugin directory
    cd openclaw-message-listener
    
    # Install dependencies if package-lock.json or node_modules doesn't exist
    if [[ ! -f package-lock.json ]] && [[ ! -d node_modules ]]; then
        echo "Installing dependencies..."
        npm install
    fi
    
    # Build TypeScript
    echo "Building TypeScript..."
    # npx tsc
    npm run build
    
    # Copy additional plugin files to dist directory
    echo "Copying additional plugin files to dist..."
    if [ -f "openclaw.plugin.json" ]; then
        cp openclaw.plugin.json dist/
        echo "Copied openclaw.plugin.json to dist/"
    else
        echo "Warning: openclaw.plugin.json not found in plugin root"
    fi
    
    # Navigate back to main directory
    cd ..
else
    echo "Node.js or npm not found, skipping TypeScript build"
    echo "Make sure the plugin is already built in ./openclaw-message-listener/dist/"
fi

if [[ $(docker network create -d bridge neonx-network) ]];
then
    echo "Created neonx-network"
else
    echo "Network found";
fi

# Stop existing containers
echo "Stopping existing containers..."
$COMPOSE_CMD down || true

# Start services
echo "Starting services..."
$COMPOSE_CMD up -d --force-recreate

# Wait a moment for services to start
sleep 3

# Show running containers
echo "Running containers:"
$COMPOSE_CMD ps

echo ""
echo "AI Agent services are now running!"
# echo "You can access the service at http://localhost:3000"
echo ""
echo "To view logs: $COMPOSE_CMD logs -f"
echo "To stop: $COMPOSE_CMD down"