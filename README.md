# Claude MCP Servers

Colecao de MCP servers personalizados para Claude Code.

## Servers

| MCP | Porta | Descricao |
|-----|-------|-----------|
| **live-dashboard** | 9099 | Dashboard visual no browser — progresso de agentes, opcoes interativas, feedback |

## Instalacao

```bash
git clone https://github.com/michelzandonai/claude-mcp-servers.git
cd claude-mcp-servers
./install.sh
```

O instalador:
1. Copia o MCP server para `~/.claude/mcp-servers/dashboard/`
2. Registra no Claude Code via `claude mcp add`
3. Instala hooks e skills auxiliares
4. Reinicie o Claude Code para ativar

### Instalacao manual (apenas o MCP)

```bash
cd servers/live-dashboard
npm install
claude mcp add live-dashboard -- node ~/.claude/mcp-servers/dashboard/index.js
```

## live-dashboard

Dashboard visual que roda no browser e e controlado pelo Claude via MCP tools.

### Tools

| Tool | Descricao |
|------|-----------|
| `dashboard_start` | Inicia o dashboard e abre no browser |
| `dashboard_update` | Atualiza o HTML do dashboard (push via WebSocket) |
| `dashboard_read_events` | Le interacoes do usuario no browser |
| `dashboard_stop` | Para o dashboard |

### Como funciona

1. Claude chama `dashboard_start` — abre `http://localhost:9099`
2. Claude chama `dashboard_update` com HTML — browser atualiza em tempo real via WebSocket
3. Usuario interage no browser (clica opcoes, escreve feedback)
4. Claude chama `dashboard_read_events` para ler as interacoes
5. Claude atualiza o dashboard com novos resultados

### Exemplo de uso

```
voce: Investigue essas 5 rotas da API
Claude: [chama dashboard_start]
Claude: [lanca 5 agentes em paralelo]
Claude: [chama dashboard_update com cards de progresso]
Claude: [conforme agentes completam, atualiza cards para CONCLUIDO]
voce: [ve tudo no browser em tempo real]
```

### Interacao no browser

O dashboard suporta:
- **Opcoes clicaveis** — selecionar entre alternativas
- **Texto livre** — escrever feedback/comentarios
- **Botao confirmar** — enviar escolha

Apos interagir no browser, envie qualquer mensagem no terminal para o Claude ler os eventos.

## Estrutura

```
claude-mcp-servers/
├── servers/
│   └── live-dashboard/
│       ├── index.js          # MCP server (Node.js)
│       └── package.json
├── hooks/                    # Hooks auxiliares para Claude Code
├── skills/                   # Skills auxiliares
├── settings-template.json    # Template de configuracao
├── install.sh                # Instalador automatico
└── README.md
```

## Adicionando novos MCPs

1. Crie um diretorio em `servers/meu-mcp/`
2. Implemente o server usando `@modelcontextprotocol/sdk`
3. Adicione o registro no `install.sh`
4. Documente no README

## Requisitos

- Node.js 18+
- Claude Code CLI
- macOS ou Linux
