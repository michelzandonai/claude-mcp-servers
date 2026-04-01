#!/bin/bash
# Hook: PreToolUse (Bash) com if: "Bash(git commit*)"
# Antes de commitar, lembra de verificar se docs precisam de atualizacao

# Verificar se existem docs no projeto
has_docs=false
[ -d "docs" ] && has_docs=true
[ -d "src/docs" ] && has_docs=true

# Se nao tem docs, sair silenciosamente
[ "$has_docs" = "false" ] && exit 0

# Verificar arquivos staged que podem impactar docs
staged_files=$(git diff --cached --name-only 2>/dev/null)
[ -z "$staged_files" ] && exit 0

# Contar arquivos de codigo staged (excluindo docs, tests, configs)
code_changes=$(echo "$staged_files" | grep -cE '\.(ts|js|tsx|jsx|vue|py)$' | grep -v -E '(test|spec|__tests__)' || echo "0")

# Se tem mudancas de codigo significativas, lembrar sobre docs
if [ "$code_changes" -gt 0 ]; then
  # Verificar se algum doc foi modificado no mesmo commit
  doc_changes=$(echo "$staged_files" | grep -cE '(docs/|\.md$|\.json$)' || echo "0")

  if [ "$doc_changes" -eq 0 ]; then
    cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "additionalContext": "LEMBRETE PRE-COMMIT (hook automatico):\n\nVoce esta commitando ${code_changes} arquivo(s) de codigo sem nenhuma alteracao em documentacao.\n\nVerifique rapidamente:\n- Algum PRD precisa ser atualizado com novas funcionalidades?\n- Alguma decisao arquitetural nova justifica um ADR?\n- Se houver task ativa, atualize o status.\n- Se modificou docs, atualize dateModified e changelog.\n\nSe nenhuma doc precisa de atualizacao, prossiga normalmente."
  }
}
EOF
  fi
fi
