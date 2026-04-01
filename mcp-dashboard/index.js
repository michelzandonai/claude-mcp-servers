#!/usr/bin/env node

const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js')
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js')
const express = require('express')
const { WebSocketServer } = require('ws')
const http = require('http')
const { execSync } = require('child_process')
const path = require('path')
const fs = require('fs')
const os = require('os')

// ── State ──────────────────────────────────────────────────────────────
let dashboardPort = null
let httpServer = null
let wss = null
let wsClients = new Set()
let currentHtml = '<h2>Dashboard iniciando...</h2>'
let events = []
let projectInfo = { name: '', dir: '', task: '' }
let autoTriggerTerminal = true

// ── Helper: detect terminal app ────────────────────────────────────────
function getTerminalApp() {
  const termApps = ['Ghostty', 'iTerm2', 'Terminal', 'Warp']
  for (const app of termApps) {
    try {
      const result = execSync(
        `osascript -e 'tell application "System Events" to (name of processes) contains "${app}"'`,
        { encoding: 'utf8', timeout: 2000 }
      ).trim()
      if (result === 'true') return app
    } catch {}
  }
  return 'Terminal'
}

function sendKeystrokeToTerminal(text) {
  if (!autoTriggerTerminal) return
  const app = getTerminalApp()
  try {
    execSync(`osascript -e '
      tell application "${app}" to activate
      delay 0.2
      tell application "System Events"
        keystroke "${text}"
        key code 36
      end tell
    '`, { timeout: 5000 })
  } catch (e) {
    // Silently fail — user can still type manually
  }
}

// ── HTML Frame ─────────────────────────────────────────────────────────
function wrapHtml(content) {
  return `<!DOCTYPE html>
<html lang="pt-BR">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>Live Dashboard</title>
<style>
  * { box-sizing: border-box; margin: 0; padding: 0; }
  body { font-family: system-ui, -apple-system, sans-serif; background: #0a0f1a; color: #e2e8f0; padding: 24px; min-height: 100vh; }
  h2 { font-size: 24px; margin-bottom: 8px; }
  h3 { font-size: 16px; margin-bottom: 8px; color: #e2e8f0; }
  p { color: #94a3b8; }
  .subtitle { color: #64748b; margin-bottom: 20px; }
  code { background: #1e293b; padding: 2px 6px; border-radius: 4px; font-size: 13px; }
  .options { display: grid; gap: 10px; margin: 12px 0; }
  .option { display: flex; align-items: flex-start; gap: 12px; padding: 14px; background: #1e293b; border: 2px solid transparent; border-radius: 8px; cursor: pointer; transition: all 0.2s; }
  .option:hover { border-color: #334155; }
  .option.selected { border-color: #3b82f6; background: #1e3a5f; }
  .letter { width: 32px; height: 32px; display: flex; align-items: center; justify-content: center; background: #3b82f6; color: white; border-radius: 6px; font-weight: 700; font-size: 14px; flex-shrink: 0; }
  .content { flex: 1; }
  .content h3 { margin: 0; font-size: 15px; }
  .content p { margin-top: 4px; font-size: 13px; color: #94a3b8; }
  .section { margin-bottom: 20px; }
  .mockup { background: #0f172a; border: 1px solid #1e293b; border-radius: 8px; overflow: hidden; }
  .mockup-header { padding: 8px 12px; background: #1e293b; font-size: 12px; color: #64748b; font-weight: 600; }
  .mockup-body { padding: 16px; }
  .pros-cons { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; margin-top: 8px; }
  .pros h4 { color: #22c55e; } .cons h4 { color: #ef4444; }
  .pros ul, .cons ul { padding-left: 16px; font-size: 13px; color: #94a3b8; }
</style>
</head>
<body>
${content}
<script>
  const ws = new WebSocket('ws://' + window.location.host);
  ws.onmessage = function(e) {
    const data = JSON.parse(e.data);
    if (data.type === 'update') document.body.innerHTML = data.html;
  };
  window.selectedChoice = null;
  window.toggleSelect = function(el) {
    const container = el.closest('.options');
    if (container) container.querySelectorAll('.option').forEach(o => o.classList.remove('selected'));
    el.classList.add('selected');
    window.selectedChoice = el.dataset.choice;
  };
  window.dashboard = {
    send: function(event) {
      event.timestamp = Date.now();
      ws.send(JSON.stringify(event));
    }
  };
</script>
</body>
</html>`
}

// ── HTTP + WebSocket Server ────────────────────────────────────────────
function startDashboardServer(port) {
  const app = express()
  app.get('/', (req, res) => { res.send(wrapHtml(currentHtml)) })

  httpServer = http.createServer(app)
  wss = new WebSocketServer({ server: httpServer })

  wss.on('connection', (ws) => {
    wsClients.add(ws)
    ws.on('message', (data) => {
      try {
        const event = JSON.parse(data.toString())
        event.receivedAt = Date.now()
        events.push(event)

        // Auto-trigger terminal on confirm/feedback
        if (['confirm', 'feedback', 'test-text', 'test-choice', 'test-feedback'].includes(event.type)) {
          sendKeystrokeToTerminal('ok')
        }
      } catch {}
    })
    ws.on('close', () => wsClients.delete(ws))
  })

  httpServer.listen(port, '127.0.0.1', () => {
    dashboardPort = port
  })
}

function broadcastUpdate(html) {
  currentHtml = html
  const msg = JSON.stringify({ type: 'update', html })
  for (const ws of wsClients) {
    try { ws.send(msg) } catch {}
  }
}

// ── MCP Server ─────────────────────────────────────────────────────────
const server = new McpServer({
  name: 'live-dashboard',
  version: '1.0.0'
})

server.tool('dashboard_start', {
  description: 'Inicia o dashboard no browser. Retorna a URL.',
  port: { type: 'number', description: 'Porta HTTP (padrao: 9099)' },
  projectName: { type: 'string', description: 'Nome do projeto' },
  projectDir: { type: 'string', description: 'Diretorio do projeto' },
  task: { type: 'string', description: 'Descricao da tarefa atual' }
}, async (params) => {
  const port = params.port || 9099
  projectInfo = {
    name: params.projectName || path.basename(process.cwd()),
    dir: params.projectDir || process.cwd(),
    task: params.task || ''
  }

  if (httpServer) {
    return { content: [{ type: 'text', text: `Dashboard ja rodando em http://localhost:${dashboardPort}` }] }
  }

  startDashboardServer(port)
  events = []

  const url = `http://localhost:${port}`
  try { execSync(`open "${url}"`) } catch {}

  return { content: [{ type: 'text', text: `Dashboard iniciado em ${url}. Browser aberto.` }] }
})

server.tool('dashboard_update', {
  description: 'Atualiza o conteudo HTML do dashboard. O browser atualiza automaticamente via WebSocket.',
  html: { type: 'string', description: 'HTML content (sem <html> wrapper — apenas o body content)' }
}, async (params) => {
  if (!httpServer) {
    return { content: [{ type: 'text', text: 'Dashboard nao esta rodando. Use dashboard_start primeiro.' }] }
  }

  // Inject header
  const header = `<div style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px;background:#0f172a;border-radius:8px;margin-bottom:24px;border:1px solid #1e293b;">
  <div style="display:flex;gap:16px;align-items:center;">
    <div><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Projeto</div><div style="font-size:14px;font-weight:600;color:#e2e8f0;">${projectInfo.name}</div></div>
    <div style="width:1px;height:28px;background:#334155;"></div>
    <div><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Diretorio</div><div style="font-size:12px;font-family:monospace;color:#94a3b8;">${projectInfo.dir}</div></div>
  </div>
  <div style="text-align:right;"><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Tarefa</div><div style="font-size:14px;font-weight:600;color:#60a5fa;">${projectInfo.task}</div></div>
</div>`

  broadcastUpdate(header + params.html)
  return { content: [{ type: 'text', text: `Dashboard atualizado. ${wsClients.size} client(s) conectado(s).` }] }
})

server.tool('dashboard_read_events', {
  description: 'Le eventos do browser (clicks, confirms, feedback). Limpa a fila apos leitura.',
  peek: { type: 'boolean', description: 'Se true, nao limpa os eventos apos leitura' }
}, async (params) => {
  const result = [...events]
  if (!params.peek) events = []
  return { content: [{ type: 'text', text: JSON.stringify(result, null, 2) }] }
})

server.tool('dashboard_stop', {
  description: 'Para o dashboard e fecha o servidor.'
}, async () => {
  if (httpServer) {
    for (const ws of wsClients) { try { ws.close() } catch {} }
    httpServer.close()
    httpServer = null
    wss = null
    wsClients.clear()
    dashboardPort = null
  }
  return { content: [{ type: 'text', text: 'Dashboard parado.' }] }
})

server.tool('dashboard_set_auto_trigger', {
  description: 'Ativa/desativa o auto-trigger que envia keystroke para o terminal quando o usuario interage no browser.',
  enabled: { type: 'boolean', description: 'true para ativar, false para desativar' }
}, async (params) => {
  autoTriggerTerminal = params.enabled
  return { content: [{ type: 'text', text: `Auto-trigger ${autoTriggerTerminal ? 'ATIVADO' : 'DESATIVADO'}` }] }
})

// ── Start ──────────────────────────────────────────────────────────────
async function main() {
  const transport = new StdioServerTransport()
  await server.connect(transport)
}

main().catch(console.error)
