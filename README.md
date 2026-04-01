# Claude Code Toolkit

Kit pessoal de skills e hooks para Claude Code. Dashboard visual, guardas de arquitetura, TDD automatizado e tracking de agentes em paralelo.

## Instalacao

```bash
git clone https://github.com/michelzandonai/claude-code-toolkit.git
cd claude-code-toolkit
./install.sh
```

Reinicie o Claude Code para ativar.

> Se ja tiver `~/.claude/settings.json`, o script NAO sobrescreve. Faca merge manual com `settings-template.json`.

## Como Usar

### 1. Live Dashboard (`/live-dashboard`)

Dashboard visual no browser para acompanhar o que o Claude esta fazendo.

**Iniciar:**
```
voce: /live-dashboard
```

O Claude abre um servidor local e mostra a URL. Abra no browser.

**O que aparece no dashboard:**
- Header com projeto, diretorio e tarefa atual
- Cards de progresso quando agentes rodam em paralelo
- Opcoes clicaveis para voce escolher sem sair do browser
- Campo de texto para enviar feedback/comentarios

**Fluxo de uso:**
1. Peca algo ao Claude (ex: "investigue essas 5 rotas")
2. Claude lanca agentes em paralelo e publica o progresso no dashboard
3. Voce vê cada agente completar em tempo real
4. Quando precisa de decisao, aparecem opcoes clicaveis
5. Voce clica, depois envia "ok" no terminal para o Claude ler

**Exemplo real — brainstorming de feature:**
```
voce: Preciso de um novo menu no sidebar
Claude: [abre dashboard com 3 opcoes visuais de layout]
voce: [clica na opcao B no browser]
voce: ok
Claude: Opcao B confirmada. Implementando...
Claude: [dashboard mostra 3 tarefas com barra de progresso]
```

### 2. Hooks Automaticos

Hooks rodam automaticamente sem voce precisar fazer nada.

**Ao iniciar sessao:**
- Carrega contexto do projeto (regras, banco de dados, convencoes)

**Ao enviar mensagem:**
- Lembra do ciclo TDD de 3 etapas para bug fixes
- Lembra regras de documentacao (Living Docs)

**Ao editar arquivo:**
- Valida que `try-catch` so existe em controllers (Clean Architecture)

**Ao fazer commit:**
- Verifica se documentacao foi atualizada

**Ao lancar agente:**
- Rastreia agentes em paralelo para o dashboard

**Ao tirar screenshot:**
- Analisa evidencia capturada automaticamente

### 3. Evidence Collection (`/evidence-collection`)

Coleta estruturada de evidencias BEFORE/AFTER.

```
voce: Corrigi o bug X, preciso de evidencias
Claude: [captura BEFORE, aplica fix, captura AFTER]
Claude: [gera relatorio com analise comparativa]
```

## Estrutura do Projeto

```
claude-code-toolkit/
├── hooks/
│   ├── project-context-loader.sh     # Contexto do projeto ao iniciar
│   ├── tdd-regression-guard.sh       # Ciclo TDD 3 etapas
│   ├── prompt-submit-docs-guard.sh   # Regras de documentacao
│   ├── architecture-guard.sh         # try-catch so em controllers
│   ├── screenshot-analyzer.sh        # Analise de screenshots
│   ├── agent-progress-tracker.sh     # Rastreio de agentes
│   ├── commit-docs-check.sh          # Docs antes de commit
│   └── issue-evidence-guard.sh       # Evidencias antes de issues
├── skills/
│   ├── live-dashboard/
│   │   └── SKILL.md                  # Skill do dashboard visual
│   └── evidence-collection/
│       └── SKILL.md                  # Skill de coleta de evidencias
├── settings-template.json            # Config com todos os hooks
├── install.sh                        # Instalador automatico
└── README.md
```

## Referencia de Hooks

| Quando | Hook | O que faz |
|--------|------|-----------|
| Sessao inicia | `project-context-loader` | Carrega regras do projeto |
| Voce envia msg | `tdd-regression-guard` | Lembra TDD 3 etapas |
| Voce envia msg | `prompt-submit-docs-guard` | Lembra Living Docs |
| Claude edita arquivo | `architecture-guard` | Valida Clean Architecture |
| Claude faz commit | `commit-docs-check` | Verifica docs atualizados |
| Claude lanca agente | `agent-progress-tracker` | Rastreia para dashboard |
| Claude tira screenshot | `screenshot-analyzer` | Analisa evidencia |
| Claude cria issue/PR | `issue-evidence-guard` | Exige evidencias |

## Requisitos

- **Claude Code** CLI instalado
- **macOS** (hooks usam bash; testado em Darwin 25.x)
- **Plugin superpowers** (para live-dashboard) — `superpowers@claude-plugins-official`

### Plugins Recomendados

| Plugin | Para que serve |
|--------|---------------|
| `superpowers` | Skills de brainstorming, TDD, planning, debugging |
| `skill-creator` | Criar e testar novas skills |
| `playwright` | Testes E2E no browser |
| `frontend-design` | UI com design de alta qualidade |
| `context7` | Documentacao atualizada de libs |
| `code-simplifier` | Simplificar codigo |

Instalar: `/install-plugin <nome>@claude-plugins-official`

## Personalizacao

### Adicionar novo hook

1. Crie o script em `~/.claude/hooks/meu-hook.sh`
2. Adicione no `~/.claude/settings.json` na secao `hooks`
3. Reinicie o Claude Code

### Adicionar nova skill

1. Crie o diretorio em `~/.claude/skills/minha-skill/`
2. Crie o `SKILL.md` com frontmatter (`name`, `description`, `user_invocable`)
3. Reinicie o Claude Code
4. Use com `/minha-skill`

## Troubleshooting

**Hooks nao estao funcionando:**
- Verifique se os scripts sao executaveis: `chmod +x ~/.claude/hooks/*.sh`
- Verifique se estao registrados em `~/.claude/settings.json`
- Reinicie o Claude Code

**Dashboard nao abre:**
- Verifique se o plugin `superpowers` esta instalado
- O servidor usa portas dinamicas — verifique se nao ha firewall bloqueando

**settings.json com conflito:**
- Faca backup: `cp ~/.claude/settings.json ~/.claude/settings.json.bak`
- Compare com `settings-template.json` e adicione os hooks que faltam
