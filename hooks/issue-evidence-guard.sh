#!/bin/bash
# Hook: PreToolUse (Bash) — bloqueia posts em issues/PRs com evidencia sem analise
# GATE: evidencia DEVE ter analise escrita para ser publicada
# Intercepta: gh issue/pr create/comment/close, glab issue/mr create/comment/close

input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command // empty' 2>/dev/null)
[ -z "$cmd" ] && exit 0

# Verificar se e interacao com issue/PR
echo "$cmd" | grep -qE '(gh|glab)\s+(issue|pr|merge-request|mr)\s+(create|comment|close|edit)' || exit 0

# Extrair body/message do comando
body=""
if echo "$cmd" | grep -qE '\-\-body|\-\-message|\-m '; then
  body=$(echo "$cmd" | sed -n "s/.*--body[= ]*['\"]\\(.*\\)['\"].*/\\1/p")
  [ -z "$body" ] && body=$(echo "$cmd" | sed -n "s/.*--message[= ]*['\"]\\(.*\\)['\"].*/\\1/p")
fi

# Tambem verificar conteudo heredoc/EOF
if echo "$cmd" | grep -qE 'EOF|HEREDOC|cat <<'; then
  body="$cmd"
fi

# Sem body = interacao simples (close sem comentario, etc) — permitir
[ -z "$body" ] && exit 0

# Verificar se body contem evidencia (imagens, dados, referencias a screenshots)
has_evidence=false
echo "$body" | grep -qiE '!\[|\.png|\.jpg|\.jpeg|\.gif|screenshot|screencap|captura|evidencia|print|tela' && has_evidence=true
echo "$body" | grep -qiE 'logcat|dumpsys|sqlite|query.result|stack.trace|api.response|resultado.da.query' && has_evidence=true

# Sem evidencia detectada — permitir normalmente
[ "$has_evidence" = "false" ] && exit 0

# Evidencia detectada — verificar marcadores de analise
has_analysis=false

# Formato completo ANTES/DEPOIS (skill evidence-collection)
if echo "$body" | grep -qiE '(ANTES|BEFORE)' && echo "$body" | grep -qiE '(DEPOIS|AFTER)'; then
  has_analysis=true
fi

# Formato alternativo com marcadores de validacao
if echo "$body" | grep -qiE '(Comparacao|Comparison|Validacao|Validation)'; then
  has_analysis=true
fi

# Formato inline (screenshot-analyzer): descricao + avaliacao
if echo "$body" | grep -qiE '(visivel|visible|mostra|shows).*(prova|proves|demonstra|confirms)'; then
  has_analysis=true
fi

if [ "$has_analysis" = "false" ]; then
  cat <<'BLOCK'
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "BLOQUEADO: Evidencia sem analise detectada.\n\nVoce esta tentando postar evidencia (screenshots/dados) em uma issue/PR sem a analise obrigatoria.\n\nCADA evidencia DEVE incluir:\n1. Descricao do que e visivel/presente nos dados\n2. Estado ANTES e DEPOIS da mudanca\n3. Comparacao explicita do que mudou\n4. Validacao: a evidencia prova o criterio? SIM/NAO\n\nUse a skill evidence-collection para gerar o formato correto.\nDepois reformule o comando com a analise incluida no body."
  }
}
BLOCK
  exit 1
fi

# Analise presente — permitir
exit 0
