#!/bin/bash
# Hook: SessionStart — injeta contexto especifico por projeto baseado no pwd
# Carrega regras que o usuario normalmente precisa relembrar a cada sessao

cwd=$(pwd)
context=""

# ── Projeto SAP (indica-sap ou sap) ──
if echo "$cwd" | grep -qE '(indica-sap|/sap)'; then
  context+="
CONTEXTO DO PROJETO SAP:
- O banco SAP HANA e SOMENTE LEITURA. NUNCA executar INSERT, UPDATE, DELETE, DROP, ALTER, CREATE, TRUNCATE, MERGE ou UPSERT.
- O PostgreSQL (PG/Indica) e a FONTE DA VERDADE para custos PMSO. Os valores do PG sao o target.
- Itens que existem no SAP mas NAO no PG devem ser FILTRADOS da API — NUNCA sugerir importar no PG.
- Tasks sao gerenciadas no GitLab (NUNCA criar TASK JSON local em docs/tasks/).
"
fi

# ── Projeto Energimap ──
if echo "$cwd" | grep -qE 'energimap'; then
  context+="
CONTEXTO DO PROJETO ENERGIMAP:
- Usar minimo 5 agentes em paralelo sempre que possivel.
- Testes: priorizar integracao/E2E sobre unitarios na API.
- SubServiceType: ao adicionar novo tipo, DEVE primeiro adicionar ao enum SubServiceType.Types no value-object antes de inserir no DB.
- Living Docs: todo trabalho deve ter TASK JSON vinculada em docs/tasks/.
"
fi

# ── Projeto Energimap Mobile ──
if echo "$cwd" | grep -qE 'energimap-mobile'; then
  context+="
CONTEXTO DO PROJETO ENERGIMAP MOBILE:
- Sempre abrir emulador Android com RAM fixa em 3GB (-memory 3072).
"
fi

# ── Projeto Indica (sem SAP) ──
if echo "$cwd" | grep -qE 'indica[^-]|indica$'; then
  context+="
CONTEXTO DO PROJETO INDICA:
- Bugs sao rastreados no Jira.
"
fi

# ── Regras globais sempre injetadas ──
context+="
REGRAS GLOBAIS (lembrete automatico):
- Effort level: SEMPRE trabalhar com maximo esforco e profundidade.
- Arquitetura: NUNCA try-catch em repositories, use cases, services ou queries. Apenas controllers.
- Linguagem: portugues para user-facing, ingles para codigo (nomes de classes, atributos, arquivos).
- Clean Code: utilizar padroes de clean code para tudo.
"

# Emitir contexto
if [ -n "$context" ]; then
  # Escapar para JSON
  escaped=$(echo "$context" | jq -Rs .)
  cat <<EOF
{
  "hookSpecificOutput": {
    "hookEventName": "SessionStart",
    "additionalContext": ${escaped}
  }
}
EOF
fi
