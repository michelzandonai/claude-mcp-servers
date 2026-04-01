#!/bin/bash
# Hook: UserPromptSubmit — injeta contexto de disciplina de docs e tasks
# Saida em stdout e adicionada ao contexto do Claude

# Verificar se estamos em um projeto com docs/ (evitar ruido em projetos sem Living Docs)
if [ ! -d "docs" ] && [ ! -d "src/docs" ]; then
  exit 0
fi

cat <<'CONTEXT'
<user-prompt-submit-hook>
REGRAS DE DISCIPLINA — Living Docs (lembrete automatico):

1. TASK OBRIGATORIA: Todo trabalho de implementacao DEVE estar vinculado a uma task em docs/tasks/.
   - Se nao existe task para o trabalho atual, crie uma ANTES de implementar.
   - Use o formato energimap-doc/v1 (GUIDELINE-001).
   - Nomeie como TASK-NNN-descricao-curta.json.

2. ATUALIZACAO DE DOCS: Ao finalizar implementacao, avalie se PRDs ou ADRs precisam ser atualizados.
   - PRD afetado? Atualize status, requisitos ou metricas em docs/prd/.
   - Decisao arquitetural nova? Crie ou atualize ADR em docs/adr/.
   - SEMPRE atualize dateModified e changelog dos docs modificados.

3. NUNCA implemente sem antes verificar se existe documentacao relevante (PRD, ADR, Task).
</user-prompt-submit-hook>
CONTEXT
