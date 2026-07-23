#!/usr/bin/env bash
set -euo pipefail

NODE_ENV="${1:?Usage: deploy.sh <NODE_ENV> <BASE_URL> <API_KEY>}"

echo ">>> Create .env file"
cat > templates/.env <<EOF
NODE_ENV=${NODE_ENV}
EOF

# echo ">>> Start services"
# docker compose up -d --force-recreate

# echo ">>> Done"
# docker compose ps
