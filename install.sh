#!/bin/bash
# Claude MCP Servers — Instalador
# Instala MCP servers, skills e hooks
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude MCP Servers — Instalador ==="
echo ""

# 1. MCP: live-dashboard
echo "[1/4] Instalando MCP: live-dashboard..."
mkdir -p "$CLAUDE_DIR/mcp-servers/dashboard"
cp "$SCRIPT_DIR/servers/live-dashboard/index.js" "$CLAUDE_DIR/mcp-servers/dashboard/"
cp "$SCRIPT_DIR/servers/live-dashboard/package.json" "$CLAUDE_DIR/mcp-servers/dashboard/"
cd "$CLAUDE_DIR/mcp-servers/dashboard" && npm install --production --silent 2>/dev/null
echo "  Instalado em $CLAUDE_DIR/mcp-servers/dashboard/"

# 2. Registrar MCP no Claude Code
echo "[2/4] Registrando MCP no Claude Code..."
DASHBOARD_PATH="$CLAUDE_DIR/mcp-servers/dashboard/index.js"
if command -v claude &>/dev/null; then
  claude mcp add live-dashboard -- node "$DASHBOARD_PATH" 2>/dev/null && echo "  Registrado via 'claude mcp add'" || echo "  Falha no registro automatico. Registre manualmente: claude mcp add live-dashboard -- node $DASHBOARD_PATH"
else
  echo "  Claude CLI nao encontrado. Registre manualmente:"
  echo "    claude mcp add live-dashboard -- node $DASHBOARD_PATH"
fi

# 3. Hooks
echo "[3/4] Instalando hooks..."
mkdir -p "$CLAUDE_DIR/hooks"
cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "  $(ls "$SCRIPT_DIR/hooks/" | wc -l | tr -d ' ') hooks instalados"

# 4. Skills
echo "[4/4] Instalando skills..."
mkdir -p "$CLAUDE_DIR/skills/live-dashboard"
mkdir -p "$CLAUDE_DIR/skills/evidence-collection"
cp -r "$SCRIPT_DIR/skills/live-dashboard/" "$CLAUDE_DIR/skills/live-dashboard/"
cp -r "$SCRIPT_DIR/skills/evidence-collection/" "$CLAUDE_DIR/skills/evidence-collection/"
echo "  Skills instaladas: live-dashboard, evidence-collection"

# Settings template
if [ ! -f "$CLAUDE_DIR/settings.json" ]; then
  cp "$SCRIPT_DIR/settings-template.json" "$CLAUDE_DIR/settings.json"
  echo "  settings.json criado a partir do template"
else
  echo "  settings.json ja existe — use settings-template.json para merge manual de hooks"
fi

echo ""
echo "=== Instalacao concluida! ==="
echo ""
echo "MCP Servers:"
echo "  live-dashboard  — Dashboard visual no browser (porta 9099)"
echo ""
echo "Para verificar: claude mcp list"
echo "Reinicie o Claude Code para ativar."
