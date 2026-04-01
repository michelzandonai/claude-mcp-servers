---
name: evidence-collection
description: Use when verifying bug fixes, testing features, collecting proof for issues/PRs, or when the screenshot-analyzer hook requests structured evidence — enforces BEFORE/AFTER capture and written analysis for every piece of evidence
---

# Evidence Collection

## Core Principle

**Sem ANTES e DEPOIS, nao existe evidencia. Sem analise escrita, nao existe prova.**

## The Iron Law

NO EVIDENCE WITHOUT BEFORE/AFTER CAPTURE AND WRITTEN ANALYSIS.

## Workflow

```
DEFINE   -> Quais sao os criterios de aceitacao?
BEFORE   -> Capturar estado quebrado/anterior (OBRIGATORIO)
EXECUTE  -> Aplicar fix ou mudanca
AFTER    -> Capturar estado corrigido/novo (OBRIGATORIO)
COMPARE  -> Descrever diferencas ANTES vs DEPOIS
VALIDATE -> Evidencia prova os criterios? SIM/NAO + justificativa
```

Pular qualquer etapa = evidencia invalida.

## Evidence Type Selection

Pense como dev senior. Match evidencia ao problema:

| Tipo de Problema | Evidencia Primaria | Evidencia de Suporte |
|---|---|---|
| Bug visual/UI | Screenshot ANTES + DEPOIS | Accessibility tree diff |
| Bug de dados/logica | Query DB ANTES + DEPOIS | Resposta API comparada |
| Performance | Metricas/timing ANTES + DEPOIS | Output do profiler |
| Crash/erro | Stack trace + logs | Screenshot estado recuperado |
| Integracao | Request/response capturados | Logs dos dois lados |
| Mobile | Screenshot device + logcat | adb shell dumpsys |

Screenshot de login NAO prova bug de calculo. Teste passando NAO prova UI correta.

## Multi-Step Flows

Fluxos com multiplas telas: capturar em CADA transicao critica.

```
Login -> Dashboard [captura] -> Feature [captura] -> Acao [captura] -> Resultado [captura]
```

Nao so a tela final.

## Output Format (compativel com issue-writing)

Cada bloco de evidencia em issue/PR DEVE seguir:

```markdown
### Evidencia: [o que esta sendo provado]

**ANTES (estado anterior):**
[screenshot/dados + descricao do que e visivel]

**DEPOIS (estado corrigido):**
[screenshot/dados + descricao do que e visivel]

**Comparacao:** [descricao explicita do que mudou]
**Validacao:** [prova o criterio? SIM/NAO + justificativa]
```

## Red Flags — PARE

- Pular captura ANTES ("ja apliquei o fix")
- Tipo errado de evidencia para o problema
- Screenshot mostra loading/spinner/erro
- Evidencia de tela/feature errada
- "Funciona" sem mostrar O QUE funciona
- Screenshot unico sem comparacao

Qualquer um desses: recomece com coleta adequada.

## Rationalization Prevention

| Desculpa | Realidade |
|---|---|
| "Ja apliquei o fix" | Reverta, capture ANTES, reaplique |
| "O ANTES e obvio" | Obvio pra voce, nao pro revisor |
| "Um screenshot basta" | ANTES + DEPOIS, sempre |
| "Testes provam que funciona" | Testes provam logica; evidencia prova comportamento |
| "Muitos passos pra capturar" | Capture transicoes criticas, nao decorativas |
