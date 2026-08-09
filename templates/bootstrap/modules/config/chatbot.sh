#!/bin/sh
# Module: Chatbot mode (CHAT_BOT)
#
# When CHAT_BOT is "true" (also 1/yes/on, case-insensitive, non-empty), the
# agent runs in fast chatbot mode: ALL skills are hidden from the model and
# KNOWLEDGE.md is stubbed so the agent does not waste time reading every
# SKILL.md / knowledge file on startup.
#
# Mechanism (verified on openclaw 2026.7.1):
#   agents.defaults.skills = []   -> every skill is "Excluded by agent allowlist"
#                                    (Visible to model: 0)
#   agents.defaults.skills absent -> all skills visible to the model
#
# So: chatbot ON  -> set skills = [] + stub KNOWLEDGE.md
#     chatbot OFF -> delete the key + restore KNOWLEDGE.md from backup

CONFIG_PATH="/home/node/.openclaw"
CONFIG="$CONFIG_PATH/openclaw.json"
WORKSPACE="$CONFIG_PATH/workspace"
KNOWLEDGE="$WORKSPACE/KNOWLEDGE.md"
KNOWLEDGE_BACKUP="$WORKSPACE/KNOWLEDGE.md.chatbot-backup"

if [ ! -f "$CONFIG" ]; then
    echo "chatbot: config not found at $CONFIG, skipping"
    return 0 2>/dev/null || exit 0
fi

# Normalize CHAT_BOT to lowercase for comparison (CHATBOT_MODE is a legacy alias)
CHAT_BOT_RAW="${CHAT_BOT:-${CHATBOT_MODE:-}}"
CHAT_BOT_VAL=$(printf '%s' "$CHAT_BOT_RAW" | tr '[:upper:]' '[:lower:]')

TMP=$(mktemp)

case "$CHAT_BOT_VAL" in
    true|1|yes|on)
        # 1) Hide all skills from the model via an empty agent skills allowlist
        jq '.agents.defaults.skills = []' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"

        # 2) Stub KNOWLEDGE.md so session startup skips the skills/knowledge list
        if [ -f "$KNOWLEDGE" ]; then
            if [ ! -f "$KNOWLEDGE_BACKUP" ]; then
                cp "$KNOWLEDGE" "$KNOWLEDGE_BACKUP"
            fi
            cat > "$KNOWLEDGE" <<'EOF'
# Knowledge Base

Chatbot mode is ON (CHAT_BOT=true): skills and extended knowledge are disabled
for fast responses. Answer the user directly and concisely. Do not look for or
read skill files.
EOF
        fi
        echo "chatbot: CHAT_BOT=$CHAT_BOT_RAW -> skills DISABLED (fast chatbot mode)"
        ;;
    *)
        # 1) Remove the allowlist so all skills are visible again
        jq 'del(.agents.defaults.skills)' "$CONFIG" > "$TMP" && mv "$TMP" "$CONFIG"

        # 2) Restore KNOWLEDGE.md if we stubbed it earlier
        if [ -f "$KNOWLEDGE_BACKUP" ]; then
            mv "$KNOWLEDGE_BACKUP" "$KNOWLEDGE"
            echo "chatbot: KNOWLEDGE.md restored"
        fi
        if [ -n "$CHAT_BOT_RAW" ]; then
            echo "chatbot: CHAT_BOT=$CHAT_BOT_RAW -> skills enabled (normal mode)"
        else
            echo "chatbot: CHAT_BOT not set -> skills enabled (normal mode)"
        fi
        ;;
esac
