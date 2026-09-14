#!/bin/sh
# Module: Codex skills install (text-to-cad)
#
# Installs the text-to-cad skill library into the Codex agent's skill
# directory so the Codex harness inside OpenClaw can discover them.
#
# Template skills are mounted read-only at /template-skills. The bundled
# text-to-cad skills live under /template-skills/text-to-cad/skills/<skill-id>/.
#
# Codex resolves its home (CODEX_HOME) per agent:
#   homeScope "agent" (default) -> <agentDir>/codex-home
#   homeScope "user"            -> $HOME/.codex
# Skills are read from $CODEX_HOME/skills/<skill-id>/.
#
# IMPORTANT: Codex does NOT follow symlinks for skills ("plugin add drops
# them silently"), so we COPY each skill directory, never symlink.

TTC_SKILLS_SRC="/template-skills/text-to-cad/skills"
OPENCLAW_DIR="/home/node/.openclaw"
OPENCLAW_SKILLS_SRC="$OPENCLAW_DIR/skills"
AGENTS_DIR="$OPENCLAW_DIR/agents"

if [ ! -d "$OPENCLAW_SKILLS_SRC" ] && [ ! -d "$TTC_SKILLS_SRC" ]; then
    echo "Codex skills: no skill source found, skipping"
    return 0 2>/dev/null || exit 0
fi

# install_into <codex_home>
# Installs all client skills, with the client-specific OpenClaw copy taking precedence.
install_into() {
    codex_home="$1"
    [ -n "$codex_home" ] || return 0

    skills_dst="$codex_home/skills"
    mkdir -p "$skills_dst" || return 0

    count=0
    for skills_src in "$TTC_SKILLS_SRC" "$OPENCLAW_SKILLS_SRC"; do
        [ -d "$skills_src" ] || continue
        for skill_dir in "$skills_src"/*/; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue

            name="$(basename "$skill_dir")"
            rm -rf "$skills_dst/$name"
            if cp -R "$skill_dir" "$skills_dst/$name" 2>/dev/null; then
                count=$((count + 1))
            fi
        done
    done

    echo "Codex skills: synchronized $count skill copy/copies into $skills_dst"
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

# 2) Interactive Codex home used by start-codex.sh/start-codex.bat.
install_into "$OPENCLAW_DIR/codex-interactive"
installed_any=1

# Codex CLI 0.147+ discovers project skills from <workspace>/.agents/skills,
# not from $CODEX_HOME/skills. Mirror the installed copies into that location.
PROJECT_SKILLS_DST="$OPENCLAW_DIR/projects/.agents/skills"
mkdir -p "$PROJECT_SKILLS_DST"
for skill_dir in "$OPENCLAW_DIR/codex-interactive/skills"/*/; do
    [ -f "$skill_dir/SKILL.md" ] || continue
    name="$(basename "$skill_dir")"
    rm -rf "$PROJECT_SKILLS_DST/$name"
    cp -R "$skill_dir" "$PROJECT_SKILLS_DST/$name" 2>/dev/null || true
done
echo "Codex skills: synchronized project skills into $PROJECT_SKILLS_DST"

# 3) User-scoped Codex home: $HOME/.codex (covers homeScope "user")
if [ -n "${HOME:-}" ]; then
    install_into "$HOME/.codex"
    installed_any=1
fi

if [ "$installed_any" -eq 0 ]; then
    echo "Codex skills: no Codex home found, nothing installed"
fi

return 0 2>/dev/null || exit 0
