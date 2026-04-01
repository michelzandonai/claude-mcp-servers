#!/bin/bash
# Hook: PostToolUse (Edit|Write) — detecta violacoes de arquitetura
# Regra: NUNCA try-catch em repositories, use cases, services ou queries
# Apenas controllers podem usar try-catch

input=$(cat)

# Extrair o caminho do arquivo editado
file_path=$(echo "$input" | jq -r '.tool_input.file_path // .tool_response.filePath // empty' 2>/dev/null)

# Se nao conseguiu extrair o path, sair silenciosamente
[ -z "$file_path" ] && exit 0

# Apenas verificar arquivos TypeScript/JavaScript
echo "$file_path" | grep -qE '\.(ts|js|tsx|jsx)$' || exit 0

# Verificar se o arquivo e um repository, use case, service ou query
is_violation_zone=false
if echo "$file_path" | grep -qiE '(repository|repositories|repo)'; then
  layer="repository"
  is_violation_zone=true
elif echo "$file_path" | grep -qiE '(use-?case|usecases)'; then
  layer="use case"
  is_violation_zone=true
elif echo "$file_path" | grep -qiE '(service|services)'; then
  layer="service"
  is_violation_zone=true
elif echo "$file_path" | grep -qiE '(query|queries)'; then
  layer="query"
  is_violation_zone=true
fi

# Se nao e zona de violacao, sair
[ "$is_violation_zone" = "false" ] && exit 0

# Verificar se o arquivo existe e contem try-catch
[ -f "$file_path" ] || exit 0

if grep -qE '^\s*(try\s*\{|} catch)' "$file_path" 2>/dev/null; then
  # Contar ocorrencias
  count=$(grep -cE '^\s*(try\s*\{|} catch)' "$file_path" 2>/dev/null)

  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "PostToolUse",
    "additionalContext": "VIOLACAO DE ARQUITETURA DETECTADA no arquivo ${file_path}:\n\nEncontrado try-catch em camada de ${layer} (${count} ocorrencias).\n\nREGRA (CLAUDE.md global):\n- NUNCA usar try-catch em repositories, use cases, services ou queries\n- Repositories DEVEM propagar erros para camadas superiores\n- APENAS controllers podem usar try-catch para converter erros em respostas HTTP\n- try-catch NUNCA deve ser usado como controle de fluxo\n\nACOES REQUERIDAS:\n1. Remover os blocos try-catch deste arquivo\n2. Propagar erros naturalmente para o controller\n3. Se necessario, retornar null/undefined em vez de capturar 'not found'"
  }
}
EOF
fi
