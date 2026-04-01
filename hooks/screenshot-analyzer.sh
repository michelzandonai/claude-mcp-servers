#!/bin/bash
# Hook: PostToolUse — forca analise de toda evidencia capturada
# HARD GATE: agente NAO pode usar evidencia sem descrever o que viu
# Intercepta: Playwright screenshots, computer-use screenshots, ADB screencap/dumpsys/sqlite3

input=$(cat)
tool_name="${CLAUDE_TOOL_NAME:-}"

# Para comandos Bash, verificar se e coleta de evidencia
if [ -z "$tool_name" ] || [ "$tool_name" = "Bash" ]; then
  bash_cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)

  is_evidence=false
  if echo "$bash_cmd" | grep -qE 'adb.*(screencap|shell dumpsys|shell sqlite3|shell content|pull.*\.(png|jpg)|exec-out screencap)'; then
    is_evidence=true
  elif echo "$bash_cmd" | grep -qE 'logcat'; then
    is_evidence=true
  fi

  [ "$is_evidence" = "false" ] && exit 0
fi

# Tracker de repeticao — apos 1a injecao, mensagem curta
marker="/tmp/claude-evidence-session-${PPID}.count"
count=0
[ -f "$marker" ] && count=$(cat "$marker")
count=$((count + 1))
echo "$count" > "$marker"

if [ "$count" -gt 1 ]; then
  # Mensagem curta para capturas subsequentes
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "EVIDENCIA CAPTURADA — analise obrigatoria: (1) descreva o que e visivel, (2) avalie se prova a afirmacao, (3) se nao prova, tome acao corretiva."
  }
}
EOF
else
  # Mensagem completa na primeira captura
  cat <<'EOF'
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "ANALISE DE EVIDENCIA OBRIGATORIA (hook automatico):\n\nVoce capturou evidencia. ANTES de prosseguir:\n\n1. DESCREVA exatamente o que e visivel (tela, dados, estado)\n2. DECLARE o que esta evidencia deveria provar\n3. AVALIE se a evidencia REALMENTE prova a afirmacao\n4. Se NAO prova: NAO use — tome acao corretiva\n\nPense como dev senior: loading spinner? Tela errada? Erro 500? Dados vazios?\n\nSe estiver verificando bug fix ou testando feature, use a skill evidence-collection para workflow completo ANTES/DEPOIS."
  }
}
EOF
fi
