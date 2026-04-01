#!/bin/bash
# Hook: UserPromptSubmit — injeta disciplina TDD regressao para bug fixes
# So ativa em projetos que tem testes configurados

# Detectar se o projeto tem testes
HAS_TESTS=false

# Verificar package.json com script test
if [ -f "package.json" ] && grep -q '"test"' package.json 2>/dev/null; then
  HAS_TESTS=true
fi

# Verificar pastas de teste comuns
for dir in test tests __tests__ spec src/test src/tests; do
  if [ -d "$dir" ]; then
    HAS_TESTS=true
    break
  fi
done

# Verificar arquivos de config de teste
for cfg in jest.config.js jest.config.ts vitest.config.ts vitest.config.js pytest.ini; do
  if [ -f "$cfg" ]; then
    HAS_TESTS=true
    break
  fi
done

if [ "$HAS_TESTS" = "false" ]; then
  exit 0
fi

cat <<'CONTEXT'
<user-prompt-submit-hook>
REGRA CRITICA — TDD Regressao para Bug Fixes (hook automatico):

Se voce esta corrigindo um bug, DEVE seguir o ciclo TDD de validacao de regressao com 3 ETAPAS OBRIGATORIAS:

```
ETAPA 1: Escrever teste que REPRODUZ o bug    -> teste DEVE FALHAR (prova que o bug existe)
ETAPA 2: Aplicar o fix                        -> teste DEVE PASSAR (prova que o fix funciona)
ETAPA 3: REVERTER o fix para o codigo bugado  -> teste DEVE FALHAR novamente (prova que o teste e valido)
ETAPA 4: RESTAURAR o fix                      -> teste DEVE PASSAR (estado final correto)
```

REGRAS INVIOLAVEIS:
- A ETAPA 3 e a MAIS IMPORTANTE. Se o teste NAO falhar com o codigo bugado, o teste e INUTIL — descarte e refaca.
- NUNCA considere um teste de regressao valido sem executar as 4 etapas.
- Preferir testes de integracao (funcoes puras) sobre E2E.
- Extrair logica critica em funcoes puras testaveis (sem dependencia de React/DOM).
- NAO faca testes superficiais ou genericos. O teste DEVE ser especifico para o bug reportado.
- Se o bug nao e reproduzivel via teste automatizado, documente o motivo.
</user-prompt-submit-hook>
CONTEXT
