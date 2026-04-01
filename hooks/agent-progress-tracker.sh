#!/bin/bash
# Hook: PostToolUse for Agent
# Grava estado do agente em arquivo compartilhado para o dashboard ler
# O dashboard (skill live-dashboard) usa esses arquivos para atualizar o browser

TRACKER_DIR="${HOME}/.claude/agent-tracker"
mkdir -p "$TRACKER_DIR"

# Input vem via stdin do Claude Code hook system
TOOL_NAME="${CLAUDE_TOOL_NAME:-}"
TOOL_INPUT="${CLAUDE_TOOL_INPUT:-}"

# Se nao for Agent tool, sai
if [ "$TOOL_NAME" != "Agent" ]; then
  exit 0
fi

# Grava timestamp do ultimo agente
echo "$(date +%s)" > "$TRACKER_DIR/last_agent_ts"

# Incrementa contador de agentes ativos
ACTIVE_COUNT=$(cat "$TRACKER_DIR/active_count" 2>/dev/null || echo "0")
echo $((ACTIVE_COUNT + 1)) > "$TRACKER_DIR/active_count"

# Emite mensagem para o contexto
echo "AGENT_LAUNCHED: Agente detectado. Dashboard pode ser atualizado via /dashboard."
