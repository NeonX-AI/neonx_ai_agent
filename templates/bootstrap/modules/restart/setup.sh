#!/bin/sh
# Module: self-restart script
# Creates openclaw-restart command

cat > /usr/local/bin/openclaw-restart << 'EOF'
#!/bin/sh
echo "Restarting OpenClaw agent..."
# Kill the main gateway process - Docker will restart the container
kill 1
EOF
chmod +x /usr/local/bin/openclaw-restart
echo "Self-restart script created: openclaw-restart"
