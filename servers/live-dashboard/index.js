#!/usr/bin/env node

const { McpServer } = require('@modelcontextprotocol/sdk/server/mcp.js')
const { StdioServerTransport } = require('@modelcontextprotocol/sdk/server/stdio.js')
const { z } = require('zod')
const http = require('http')
const { WebSocketServer } = require('ws')
const { execSync } = require('child_process')

// ── State ──────────────────────────────────────────────────────────────
let dashboardPort = null
let httpServer = null
let wss = null
let wsClients = new Set()
let currentHtml = '<h2>Dashboard iniciando...</h2>'
let events = []
let projectInfo = { name: '', dir: '', task: '' }

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
</style>
</head>
<body>
${content}
<script>
  var ws = new WebSocket('ws://' + window.location.host);
  ws.onmessage = function(e) {
    var data = JSON.parse(e.data);
    if (data.type === 'update') {
      var scripts = document.querySelectorAll('script');
      var lastScript = scripts[scripts.length - 1];
      document.body.innerHTML = data.html;
      document.body.appendChild(lastScript);
    }
  };
  window.selectedChoice = null;
  window.toggleSelect = function(el) {
    var container = el.closest('.options');
    if (container) container.querySelectorAll('.option').forEach(function(o) { o.classList.remove('selected'); });
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
  httpServer = http.createServer(function(req, res) {
    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' })
    res.end(wrapHtml(currentHtml))
  })

  wss = new WebSocketServer({ server: httpServer })

  wss.on('connection', function(ws) {
    wsClients.add(ws)
    ws.on('message', function(data) {
      try {
        var event = JSON.parse(data.toString())
        event.receivedAt = Date.now()
        events.push(event)
      } catch {}
    })
    ws.on('close', function() { wsClients.delete(ws) })
  })

  httpServer.listen(port, '127.0.0.1', function() {
    dashboardPort = port
  })
}

function broadcastUpdate(html) {
  currentHtml = html
  var msg = JSON.stringify({ type: 'update', html: html })
  for (var ws of wsClients) {
    try { ws.send(msg) } catch {}
  }
}

// ── MCP Server ─────────────────────────────────────────────────────────
var mcpServer = new McpServer({
  name: 'live-dashboard',
  version: '1.0.0'
})

mcpServer.tool(
  'dashboard_start',
  'Inicia o dashboard no browser. Retorna a URL.',
  {
    port: z.number().optional().describe('Porta HTTP (padrao: 9099)'),
    projectName: z.string().optional().describe('Nome do projeto'),
    projectDir: z.string().optional().describe('Diretorio do projeto'),
    task: z.string().optional().describe('Descricao da tarefa atual')
  },
  async function(params) {
    var port = params.port || 9099
    projectInfo = {
      name: params.projectName || 'projeto',
      dir: params.projectDir || process.cwd(),
      task: params.task || ''
    }

    if (httpServer) {
      return { content: [{ type: 'text', text: 'Dashboard ja rodando em http://localhost:' + dashboardPort }] }
    }

    startDashboardServer(port)
    events = []

    var url = 'http://localhost:' + port
    try { execSync('open "' + url + '"') } catch {}

    return { content: [{ type: 'text', text: 'Dashboard iniciado em ' + url + '. Browser aberto.' }] }
  }
)

mcpServer.tool(
  'dashboard_update',
  'Atualiza o conteudo HTML do dashboard. O browser atualiza automaticamente via WebSocket.',
  {
    html: z.string().describe('HTML content (body content, sem wrapper)')
  },
  async function(params) {
    if (!httpServer) {
      return { content: [{ type: 'text', text: 'Dashboard nao esta rodando. Use dashboard_start primeiro.' }] }
    }

    var header = '<div style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px;background:#0f172a;border-radius:8px;margin-bottom:24px;border:1px solid #1e293b;">' +
      '<div style="display:flex;gap:16px;align-items:center;">' +
      '<div><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Projeto</div><div style="font-size:14px;font-weight:600;color:#e2e8f0;">' + projectInfo.name + '</div></div>' +
      '<div style="width:1px;height:28px;background:#334155;"></div>' +
      '<div><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Diretorio</div><div style="font-size:12px;font-family:monospace;color:#94a3b8;">' + projectInfo.dir + '</div></div>' +
      '</div>' +
      '<div style="text-align:right;"><div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Tarefa</div><div style="font-size:14px;font-weight:600;color:#60a5fa;">' + projectInfo.task + '</div></div>' +
      '</div>'

    broadcastUpdate(header + params.html)
    return { content: [{ type: 'text', text: 'Dashboard atualizado. ' + wsClients.size + ' client(s) conectado(s).' }] }
  }
)

mcpServer.tool(
  'dashboard_read_events',
  'Le eventos do browser (clicks, confirms, feedback). Limpa a fila apos leitura.',
  {
    peek: z.boolean().optional().describe('Se true, nao limpa os eventos apos leitura')
  },
  async function(params) {
    var result = events.slice()
    if (!params.peek) events = []
    return { content: [{ type: 'text', text: result.length > 0 ? JSON.stringify(result, null, 2) : 'Nenhum evento pendente.' }] }
  }
)

mcpServer.tool(
  'dashboard_stop',
  'Para o dashboard e fecha o servidor.',
  {},
  async function() {
    if (httpServer) {
      for (var ws of wsClients) { try { ws.close() } catch {} }
      httpServer.close()
      httpServer = null
      wss = null
      wsClients.clear()
      dashboardPort = null
    }
    return { content: [{ type: 'text', text: 'Dashboard parado.' }] }
  }
)

// ── Start ──────────────────────────────────────────────────────────────
async function main() {
  var transport = new StdioServerTransport()
  await mcpServer.connect(transport)
}

main().catch(console.error)
