#!/usr/bin/env bash
set -euo pipefail

NODE_ENV="${1:?Usage: deploy.sh <NODE_ENV>}"

echo ">>> Create .env file"
echo "NODE_ENV=${NODE_ENV}" > .env

# echo ">>> Start services"
# docker compose up -d --force-recreate

# echo ">>> Done"
# docker compose ps
