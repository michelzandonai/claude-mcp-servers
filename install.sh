#!/bin/bash
# Claude Code Toolkit — Instalador
# Copia skills, hooks e configura settings.json
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"

echo "=== Claude Code Toolkit — Instalador ==="
echo "Diretorio Claude: $CLAUDE_DIR"
echo ""

# 1. Criar diretorios
echo "[1/4] Criando diretorios..."
mkdir -p "$CLAUDE_DIR/hooks"
mkdir -p "$CLAUDE_DIR/skills/live-dashboard/scripts"
mkdir -p "$CLAUDE_DIR/skills/live-dashboard/templates"
mkdir -p "$CLAUDE_DIR/skills/evidence-collection"

# 2. Copiar hooks
echo "[2/4] Instalando hooks..."
cp "$SCRIPT_DIR/hooks/"*.sh "$CLAUDE_DIR/hooks/"
chmod +x "$CLAUDE_DIR/hooks/"*.sh
echo "  $(ls "$SCRIPT_DIR/hooks/" | wc -l | tr -d ' ') hooks instalados"

# 3. Copiar skills
echo "[3/4] Instalando skills..."
cp -r "$SCRIPT_DIR/skills/live-dashboard/" "$CLAUDE_DIR/skills/live-dashboard/"
cp -r "$SCRIPT_DIR/skills/evidence-collection/" "$CLAUDE_DIR/skills/evidence-collection/"
echo "  Skills instaladas: live-dashboard, evidence-collection"

# 4. Merge settings.json
echo "[4/4] Configurando settings.json..."
if [ -f "$CLAUDE_DIR/settings.json" ]; then
  echo "  settings.json ja existe. Merge manual necessario."
  echo "  Template disponivel em: $SCRIPT_DIR/settings-template.json"
  echo "  Compare e adicione os hooks que faltam."
else
  cp "$SCRIPT_DIR/settings-template.json" "$CLAUDE_DIR/settings.json"
  echo "  settings.json criado a partir do template"
fi

echo ""
echo "=== Instalacao concluida! ==="
echo ""
echo "Skills disponiveis:"
echo "  /live-dashboard  — Dashboard visual no browser"
echo ""
echo "Hooks ativos:"
echo "  SessionStart     — project-context-loader"
echo "  UserPromptSubmit — tdd-regression-guard, prompt-submit-docs-guard"
echo "  PostToolUse      — architecture-guard, screenshot-analyzer, agent-progress-tracker"
echo "  PreToolUse       — commit-docs-check, issue-evidence-guard"
echo ""
echo "Reinicie o Claude Code para ativar."
