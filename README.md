# Claude Code Toolkit

Kit de skills e hooks para Claude Code. Inclui dashboard visual, guardas de arquitetura, TDD e tracking de agentes.

## Instalacao Rapida

```bash
git clone https://github.com/michelzandonai/claude-code-toolkit.git
cd claude-code-toolkit
chmod +x install.sh
./install.sh
```

Reinicie o Claude Code apos instalar.

## Estrutura

```
claude-code-toolkit/
├── hooks/                          # Shell scripts executados automaticamente
│   ├── project-context-loader.sh   # SessionStart: carrega contexto do projeto
│   ├── tdd-regression-guard.sh     # UserPromptSubmit: lembra ciclo TDD 3 etapas
│   ├── prompt-submit-docs-guard.sh # UserPromptSubmit: lembra regras de documentacao
│   ├── architecture-guard.sh       # PostToolUse(Edit|Write): valida arquitetura
│   ├── screenshot-analyzer.sh      # PostToolUse(screenshot): analisa evidencias
│   ├── agent-progress-tracker.sh   # PostToolUse(Agent): rastreia agentes paralelos
│   ├── commit-docs-check.sh        # PreToolUse(git commit): verifica docs
│   └── issue-evidence-guard.sh     # PreToolUse(gh): verifica evidencias
├── skills/
│   ├── live-dashboard/             # Dashboard visual no browser
│   │   ├── SKILL.md                # Definicao da skill
│   │   ├── scripts/                # Scripts auxiliares
│   │   └── templates/              # Templates HTML
│   └── evidence-collection/        # Coleta de evidencias BEFORE/AFTER
│       └── SKILL.md
├── settings-template.json          # Template do settings.json com hooks
├── install.sh                      # Script de instalacao
└── README.md
```

## Hooks

### SessionStart
| Hook | Descricao |
|------|-----------|
| `project-context-loader.sh` | Carrega contexto do projeto (SAP, PostgreSQL, regras) |

### UserPromptSubmit
| Hook | Descricao |
|------|-----------|
| `tdd-regression-guard.sh` | Lembra o ciclo TDD de 3 etapas para bug fixes |
| `prompt-submit-docs-guard.sh` | Lembra regras de documentacao Living Docs |

### PostToolUse
| Hook | Matcher | Descricao |
|------|---------|-----------|
| `architecture-guard.sh` | `Edit\|Write` | Valida que try-catch so existe em controllers |
| `screenshot-analyzer.sh` | `screenshot\|zoom\|adb` | Analisa screenshots capturadas |
| `agent-progress-tracker.sh` | `Agent` | Rastreia agentes em paralelo |

### PreToolUse
| Hook | Matcher | Descricao |
|------|---------|-----------|
| `commit-docs-check.sh` | `git commit` | Verifica se docs foram atualizados |
| `issue-evidence-guard.sh` | `gh` | Verifica evidencias antes de criar issues/PRs |

## Skills

### /live-dashboard

Dashboard visual no browser para acompanhar trabalho em tempo real.

```
/live-dashboard
```

Funcionalidades:
- Dashboard com progresso de agentes em paralelo
- Opcoes interativas (clique para selecionar)
- Campo de comentarios e feedback
- Header contextual (projeto, brand, diretorio)

Requer: plugin `superpowers` instalado (usa o brainstorm server).

### /evidence-collection

Coleta estruturada de evidencias BEFORE/AFTER para issues e PRs.

## Configuracao Manual

Se o `install.sh` detectar um `settings.json` existente, faca o merge manual:

1. Abra `~/.claude/settings.json`
2. Compare com `settings-template.json`
3. Adicione os hooks que faltam na secao `hooks`

## Requisitos

- Claude Code CLI instalado
- Plugin `superpowers` (para live-dashboard)
- macOS (hooks usam bash; testado em Darwin)

## Plugins Recomendados

```
superpowers, skill-creator, playwright, frontend-design, context7, code-simplifier
```

Instale via Claude Code: `/install-plugin <nome>@claude-plugins-official`
