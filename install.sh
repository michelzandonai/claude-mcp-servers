#!/bin/bash
# Claude Code Toolkit — Instalador
# Copia skills, hooks, MCP server e configura settings.json
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Toolkit — Instalador ==="
echo "Diretorio Claude: $CLAUDE_DIR"
echo ""

# 1. Criar diretorios
echo "[1/5] Criando diretorios..."
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/skills/live-dashboard/scripts"
mkdir -p "$CLAUDE_DIR/skills/live-dashboard/templates"
mkdir -p "$CLAUDE_DIR/skills/evidence-collection"
mkdir -p "$CLAUDE_DIR/mcp-servers/dashboard"

# 2. Copiar hooks
echo "[2/5] Instalando hooks..."
cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "  $(ls "$SCRIPT_DIR/hooks/" | wc -l | tr -d ' ') hooks instalados"

# 3. Copiar skills
echo "[3/5] Instalando skills..."
cp -r "$SCRIPT_DIR/skills/live-dashboard/" "$CLAUDE_DIR/skills/live-dashboard/"
cp -r "$SCRIPT_DIR/skills/evidence-collection/" "$CLAUDE_DIR/skills/evidence-collection/"
echo "  Skills instaladas: live-dashboard, evidence-collection"

# 4. Instalar MCP Dashboard server
echo "[4/5] Instalando MCP Dashboard server..."
cp "$SCRIPT_DIR/mcp-dashboard/index.js" "$CLAUDE_DIR/mcp-servers/dashboard/"
cp "$SCRIPT_DIR/mcp-dashboard/package.json" "$CLAUDE_DIR/mcp-servers/dashboard/"
cd "$CLAUDE_DIR/mcp-servers/dashboard" && npm install --production --silent 2>/dev/null
echo "  MCP server instalado em $CLAUDE_DIR/mcp-servers/dashboard/"

# 5. Merge settings.json
echo "[5/5] Configurando settings.json..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "  settings.json ja existe. Merge manual necessario."
  echo "  Template disponivel em: $SCRIPT_DIR/settings-template.json"
  echo ""
  echo "  Adicione isso ao seu settings.json (secao mcpServers):"
  echo "    \"mcpServers\": {"
  echo "      \"live-dashboard\": {"
  echo "        \"type\": \"stdio\","
  echo "        \"command\": \"node\","
  echo "        \"args\": [\"$CLAUDE_DIR/mcp-servers/dashboard/index.js\"]"
  echo "      }"
  echo "    }"
else
  cp "$SCRIPT_DIR/settings-template.json" "$CLAUDE_DIR/settings.json"
  echo "  settings.json criado a partir do template"
fi

echo ""
echo "=== Instalacao concluida! ==="
echo ""
echo "MCP Tools disponiveis (apos reiniciar):"
echo "  dashboard_start         — Abre dashboard no browser"
echo "  dashboard_update        — Atualiza HTML do dashboard"
echo "  dashboard_read_events   — Le interacoes do browser"
echo "  dashboard_stop          — Para o dashboard"
echo ""
echo "Skills disponiveis:"
echo "  /live-dashboard  — Dashboard visual (usa MCP por baixo)"
echo ""
echo "Hooks ativos (8 total):"
echo "  SessionStart     — project-context-loader"
echo "  UserPromptSubmit — tdd-regression-guard, prompt-submit-docs-guard"
echo "  PostToolUse      — architecture-guard, screenshot-analyzer, agent-progress-tracker"
echo "  PreToolUse       — commit-docs-check, issue-evidence-guard"
echo ""
echo "Reinicie o Claude Code para ativar."
