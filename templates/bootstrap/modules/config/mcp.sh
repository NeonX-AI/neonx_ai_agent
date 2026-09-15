#!/bin/sh
# Module: legacy MCP cleanup
#
# These CAD MCP endpoints were bundled by an older template. They point at a
# host-local service that is not present in normal client deployments, causing
# gateway startup and doctor warnings. Remove only these retired entries; any
# MCP servers configured by a client remain untouched.

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"

if [ -f "$CONFIG" ]; then
    if jq -e '(.mcp.servers? // {}) | has("autodesk-fusion") or has("autocad")' "$CONFIG" >/dev/null; then
        TMP=$(mktemp)
        jq '
        del(.mcp.servers."autodesk-fusion", .mcp.servers.autocad) |
        if .mcp.servers == {} then del(.mcp.servers) else . end |
        if .mcp == {} then del(.mcp) else . end
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Removed retired Autodesk Fusion and AutoCAD MCP configuration"
    fi
fi
