#!/bin/sh
# Module: Codex skills install (text-to-cad)
#
# Installs the text-to-cad skill library into the Codex agent's skill
# directory so the Codex harness inside OpenClaw can discover them.
#
# The text-to-cad repo is mounted read-only at /extensions/text-to-cad
# (see docker-compose volume ../../extensions:/extensions:ro). Its skills
# live under /extensions/text-to-cad/skills/<skill-id>/.
#
# Codex resolves its home (CODEX_HOME) per agent:
#   homeScope "agent" (default) -> <agentDir>/codex-home
#   homeScope "user"            -> $HOME/.codex
# Skills are read from $CODEX_HOME/skills/<skill-id>/.
#
# IMPORTANT: Codex does NOT follow symlinks for skills ("plugin add drops
# them silently"), so we COPY each skill directory, never symlink.

TTC_SKILLS_SRC="/extensions/text-to-cad/skills"
OPENCLAW_DIR="/home/node/.openclaw"
AGENTS_DIR="$OPENCLAW_DIR/agents"

if [ ! -d "$TTC_SKILLS_SRC" ]; then
    echo "Codex skills: source not found ($TTC_SKILLS_SRC), skipping"
    return 0 2>/dev/null || exit 0
fi

# install_into <codex_home>
# Copies every skill dir from the text-to-cad source into <codex_home>/skills.
install_into() {
    codex_home="$1"
    [ -n "$codex_home" ] || return 0

    skills_dst="$codex_home/skills"
    mkdir -p "$skills_dst" || return 0

    count=0
    for skill_dir in "$TTC_SKILLS_SRC"/*/; do
        [ -d "$skill_dir" ] || continue
        # Require a SKILL.md so we only copy real skill directories.
        [ -f "$skill_dir/SKILL.md" ] || continue

        name="$(basename "$skill_dir")"
        # Fresh copy each run (Codex ignores symlinks; keep it a real dir).
        rm -rf "$skills_dst/$name"
        if cp -R "$skill_dir" "$skills_dst/$name" 2>/dev/null; then
            count=$((count + 1))
        fi
    done

    echo "Codex skills: installed $count skill(s) into $skills_dst"
}

installed_any=0

# 1) Agent-scoped Codex homes: <agents>/<id>/agent/codex-home
if [ -d "$AGENTS_DIR" ]; then
    for agent_dir in "$AGENTS_DIR"/*/agent; do
        [ -d "$agent_dir" ] || continue
        install_into "$agent_dir/codex-home"
        installed_any=1
    done
fi

# On a fresh client the gateway has never started, so no agent dir exists yet.
# OpenClaw's default agent id is "main" (or the ids listed in agents.list),
# so pre-create the Codex home for those agents.
if [ "$installed_any" -eq 0 ]; then
    agent_ids=""
    if command -v jq >/dev/null 2>&1 && [ -f "$OPENCLAW_DIR/openclaw.json" ]; then
        agent_ids="$(jq -r '.agents.list[]?.id // empty' "$OPENCLAW_DIR/openclaw.json" 2>/dev/null | tr '\n' ' ')"
    fi
    [ -n "$agent_ids" ] || agent_ids="main"
    for id in $agent_ids; do
        install_into "$AGENTS_DIR/$id/agent/codex-home"
        installed_any=1
    done
fi

# 2) User-scoped Codex home: $HOME/.codex (covers homeScope "user")
if [ -n "${HOME:-}" ]; then
    install_into "$HOME/.codex"
    installed_any=1
fi

if [ "$installed_any" -eq 0 ]; then
    echo "Codex skills: no Codex home found, nothing installed"
fi

return 0 2>/dev/null || exit 0
