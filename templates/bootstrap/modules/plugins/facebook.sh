#!/bin/sh
# Module: Facebook plugin setup
# Copies the bundled Dj-Shortcut Facebook plugin into the container extensions dir
# (no network download; source is mounted read-only from ../../extensions)

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
TMP=$(mktemp)
FACEBOOK_PLUGIN_ID="facebook"
PLUGIN_SOURCE="/extensions/dj-shortcut-facebook"
PLUGIN_DEST="$CONFIG_PATH/extensions/facebook"
PLUGIN_DIR="$CONFIG_PATH/npm/projects"

# Remove stale plugin entries (old plugin names)
for stale_id in "openclaw-facebook" "agntdata-facebook"; do
    if jq -e ".plugins.entries[\"$stale_id\"]" "$CONFIG" >/dev/null 2>&1; then
        jq --arg sid "$stale_id" 'del(.plugins.entries[$sid]) | .plugins.allow |= map(select(. != $sid))' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Removed stale $stale_id config"
    fi
done

# Remove old plugin copies from npm/projects (legacy install locations)
if [ -d "$PLUGIN_DIR" ]; then
    for old_dir in "$PLUGIN_DIR"/agntdata-openclaw-facebook-* "$PLUGIN_DIR"/dj-shortcut-facebook-* "$PLUGIN_DIR"/openclaw-facebook-*; do
        if [ -d "$old_dir" ]; then
            echo "Removing old plugin dir: $old_dir"
            rm -rf "$old_dir"
        fi
    done
fi

# Remove leftover install staging dirs (from interrupted `openclaw plugins install`)
for stage_dir in "$CONFIG_PATH/extensions"/.openclaw-install-stage-*; do
    if [ -d "$stage_dir" ]; then
        echo "Removing install staging dir: $stage_dir"
        rm -rf "$stage_dir"
    fi
done

# Remove stale facebook install records from the installed-plugin index.
# Old records (from `openclaw plugins install`) plus the extensions/ dir scan
# cause "duplicate plugin id" warnings since we now ship the plugin locally.
if command -v node >/dev/null 2>&1 && [ -f "$CONFIG_PATH/state/openclaw.sqlite" ]; then
    if node --input-type=module <<'NODE_EOF' 2>/dev/null
import { DatabaseSync } from "node:sqlite";
const db = new DatabaseSync("/home/node/.openclaw/state/openclaw.sqlite");
const row = db.prepare("SELECT install_records_json FROM installed_plugin_index WHERE index_key='installed-plugin-index'").get();
if (row) {
    const records = JSON.parse(row.install_records_json);
    if (records.facebook) {
        delete records.facebook;
        db.prepare("UPDATE installed_plugin_index SET install_records_json=? WHERE index_key='installed-plugin-index'")
            .run(JSON.stringify(records));
        console.log("cleaned");
    }
}
NODE_EOF
    then
        echo "Cleaned stale facebook install records"
    fi
fi

# Copy bundled plugin from mounted /extensions (always refresh to bundled version)
echo "Setting up facebook plugin from $PLUGIN_SOURCE..."
if [ ! -f "$PLUGIN_SOURCE/package.json" ]; then
    echo "✗ Plugin source not found at $PLUGIN_SOURCE"
    echo "Please ensure the extensions directory is mounted in docker-compose.yml"
else
    if [ -d "$PLUGIN_DEST" ]; then
        echo "Plugin already exists at $PLUGIN_DEST, updating..."
        rm -rf "$PLUGIN_DEST"
    fi

    mkdir -p "$CONFIG_PATH/extensions"
    cp -R "$PLUGIN_SOURCE" "$PLUGIN_DEST"

    # Wire runtime deps without network installs:
    # - openclaw SDK resolves to the host app at /app (peer dependency)
    # - zod resolves from the host app's node_modules
    mkdir -p "$PLUGIN_DEST/node_modules"
    ln -sfn /app "$PLUGIN_DEST/node_modules/openclaw"
    if [ -d /app/node_modules/zod ]; then
        ln -sfn /app/node_modules/zod "$PLUGIN_DEST/node_modules/zod"
    else
        echo "⚠ zod not found in /app/node_modules; plugin may fail to load"
    fi

    if [ -f "$PLUGIN_DEST/package.json" ]; then
        echo "✓ Facebook plugin installed from local extensions"
    else
        echo "✗ Failed to install Facebook plugin"
    fi
fi

# Always ensure plugin is enabled in config
jq --arg pid "$FACEBOOK_PLUGIN_ID" '
.plugins.allow |= (. + [$pid] | unique) |
.plugins.entries[$pid] = {enabled: true}
' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
echo "Ensured plugin $FACEBOOK_PLUGIN_ID is enabled"

# Configure Facebook channel from environment variables (injected from .env.meta)
if [ -n "${FACEBOOK_PAGE_ID:-}" ] && [ -n "${FACEBOOK_PAGE_ACCESS_TOKEN:-}" ]; then
    jq \
        --arg pageId "$FACEBOOK_PAGE_ID" \
        --arg pageAccessToken "$FACEBOOK_PAGE_ACCESS_TOKEN" \
        --arg appSecret "${FACEBOOK_APP_SECRET:-}" \
        --arg verifyToken "${FACEBOOK_VERIFY_TOKEN:-}" \
        '
        .channels.facebook = {
            enabled: true,
            pageId: $pageId,
            pageAccessToken: $pageAccessToken,
            appSecret: $appSecret,
            verifyToken: $verifyToken,
            dmPolicy: "open",
            allowFrom: ["*"]
        }
        ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Configured Facebook channel from environment variables"
    
    # Remove sensitive environment variables after use
    unset FACEBOOK_APP_SECRET FACEBOOK_VERIFY_TOKEN FACEBOOK_PAGE_ID FACEBOOK_PAGE_ACCESS_TOKEN
    echo "Removed sensitive environment variables"
fi
