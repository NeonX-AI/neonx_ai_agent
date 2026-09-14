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

# Configure Facebook channel from environment variables (injected from .env / .env.meta)
#
# Multi-account format (matches the plugin's documented schema): EVERY fanpage —
# including the primary one — lives in channels.facebook.accounts.<id>, and
# `defaultAccount` points at the primary account.
#
#   Fanpage 1 (primary):  FACEBOOK_PAGE_ID, FACEBOOK_PAGE_ACCESS_TOKEN
#                         (+ shared FACEBOOK_APP_SECRET / FACEBOOK_VERIFY_TOKEN)
#   Fanpage N (2..10):    FACEBOOK_PAGE_<N>_ID, FACEBOOK_PAGE_<N>_ACCESS_TOKEN
#                         FACEBOOK_PAGE_<N>_APP_SECRET / _VERIFY_TOKEN (optional,
#                         fall back to shared FACEBOOK_APP_SECRET / _VERIFY_TOKEN)
#                         FACEBOOK_PAGE_<N>_NAME (optional display name)
#
# All accounts share one webhook path (/facebook/webhook); Meta routes events by
# page id, so each fanpage only needs its own webhook subscription.

# Shared app credentials used as fallback for extra fanpages
FACEBOOK_APP_SECRET_SHARED="${FACEBOOK_APP_SECRET:-}"
FACEBOOK_VERIFY_TOKEN_SHARED="${FACEBOOK_VERIFY_TOKEN:-}"

# Start from a clean multi-account structure (drop any legacy single-page fields)
jq '.channels.facebook = {enabled: true, accounts: {}}' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"

FB_COUNT=0
FB_DEFAULT_ACCT=""
n=1
while [ "$n" -le 10 ]; do
    if [ "$n" -eq 1 ]; then
        # Primary fanpage uses the non-suffixed env vars
        page_id="${FACEBOOK_PAGE_ID:-}"
        page_token="${FACEBOOK_PAGE_ACCESS_TOKEN:-}"
        page_secret="${FACEBOOK_APP_SECRET:-}"
        page_verify="${FACEBOOK_VERIFY_TOKEN:-}"
        page_name="${FACEBOOK_PAGE_NAME:-}"
        # NOTE: must NOT use the account id "default" — the plugin treats that id
        # specially and resolves its credentials from top-level config / env vars
        # only, ignoring accounts.default. Use "page1" so it resolves like the rest.
        acct_id="page1"
    else
        eval "page_id=\${FACEBOOK_PAGE_${n}_ID:-}"
        eval "page_token=\${FACEBOOK_PAGE_${n}_ACCESS_TOKEN:-}"
        eval "page_secret=\${FACEBOOK_PAGE_${n}_APP_SECRET:-\${FACEBOOK_APP_SECRET_SHARED:-}}"
        eval "page_verify=\${FACEBOOK_PAGE_${n}_VERIFY_TOKEN:-\${FACEBOOK_VERIFY_TOKEN_SHARED:-}}"
        eval "page_name=\${FACEBOOK_PAGE_${n}_NAME:-}"
        acct_id="page$n"
    fi

    if [ -n "$page_id" ] && [ -n "$page_token" ]; then
        jq \
            --arg acctId "$acct_id" \
            --arg pageId "$page_id" \
            --arg pageAccessToken "$page_token" \
            --arg appSecret "$page_secret" \
            --arg verifyToken "$page_verify" \
            --arg name "$page_name" \
            '
            .channels.facebook.accounts[$acctId] = (
                {
                    enabled: true,
                    pageId: $pageId,
                    pageAccessToken: $pageAccessToken,
                    appSecret: $appSecret,
                    verifyToken: $verifyToken,
                    dmPolicy: "open",
                    allowFrom: ["*"]
                }
                + (if $name != "" then {name: $name} else {} end)
            )
            ' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
        echo "Configured Facebook fanpage: $acct_id (id=$page_id)"
        FB_COUNT=$((FB_COUNT + 1))
        if [ -z "$FB_DEFAULT_ACCT" ]; then
            FB_DEFAULT_ACCT="$acct_id"
        fi
    fi
    n=$((n + 1))
done

if [ "$FB_COUNT" -gt 0 ]; then
    # Point defaultAccount at the first configured fanpage
    # (note: "def" is a jq reserved word, so the arg must use another name)
    jq --arg defAcct "$FB_DEFAULT_ACCT" '.channels.facebook.defaultAccount = $defAcct' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
    echo "Configured $FB_COUNT Facebook fanpage(s); defaultAccount=$FB_DEFAULT_ACCT"
else
    # No fanpage configured -> drop the empty channel block
    jq 'del(.channels.facebook)' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"
fi

# Remove sensitive environment variables after use
unset FACEBOOK_APP_SECRET FACEBOOK_VERIFY_TOKEN FACEBOOK_PAGE_ID FACEBOOK_PAGE_ACCESS_TOKEN FACEBOOK_PAGE_NAME
unset FACEBOOK_APP_SECRET_SHARED FACEBOOK_VERIFY_TOKEN_SHARED
n=2
while [ "$n" -le 10 ]; do
    unset "FACEBOOK_PAGE_${n}_ID" "FACEBOOK_PAGE_${n}_ACCESS_TOKEN" \
          "FACEBOOK_PAGE_${n}_APP_SECRET" "FACEBOOK_PAGE_${n}_VERIFY_TOKEN" \
          "FACEBOOK_PAGE_${n}_NAME"
    n=$((n + 1))
done
