---
name: live-dashboard
description: Dashboard visual no browser com progresso de agentes, opcoes interativas e feedback bidirecional. Ative com /dashboard para qualquer projeto.
user_invocable: true
---

# Live Dashboard

Dashboard visual no browser para acompanhar trabalho em tempo real.

## Quando Usar

- Antes de lancar agentes em paralelo
- Durante brainstorming que envolva opcoes visuais
- Quando o usuario pedir para visualizar progresso

## Como Funciona

1. Inicia servidor WebSocket via superpowers brainstorm
2. Publica HTML no browser com contexto do projeto
3. Atualiza a cada mudanca de estado (agente concluido, opcao selecionada, etc.)
4. Le eventos do browser (clicks, comentarios, confirmacoes)

## Startup

```bash
BRAINSTORM_SCRIPTS="$HOME/.claude/plugins/cache/claude-plugins-official/superpowers/5.0.7/skills/brainstorming/scripts"
$BRAINSTORM_SCRIPTS/start-server.sh --project-dir $(pwd)
```

Salve `screen_dir` e `state_dir` do JSON retornado. Abra a URL no browser com `open <url>`.

## Dashboard Header (OBRIGATORIO em toda pagina)

Toda pagina HTML DEVE comecar com o header contextual:

```html
<div style="display:flex;justify-content:space-between;align-items:center;padding:12px 16px;background:#0f172a;border-radius:8px;margin-bottom:24px;border:1px solid #1e293b;">
  <div style="display:flex;gap:16px;align-items:center;">
    <div>
      <div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Projeto</div>
      <div style="font-size:14px;font-weight:600;color:#e2e8f0;">{NOME_PROJETO}</div>
    </div>
    <div style="width:1px;height:28px;background:#334155;"></div>
    <div>
      <div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Diretorio</div>
      <div style="font-size:12px;font-family:monospace;color:#94a3b8;">{CWD}</div>
    </div>
  </div>
  <div style="text-align:right;">
    <div style="font-size:10px;text-transform:uppercase;letter-spacing:1px;color:#64748b;">Tarefa</div>
    <div style="font-size:14px;font-weight:600;color:#60a5fa;">{DESCRICAO_TAREFA}</div>
  </div>
</div>
```

## Templates de Pagina

### 1. Progresso de Agentes

Quando lancar agentes em paralelo, SEMPRE publique um dashboard de progresso.

Para CADA agente, criar um card com:
- Nome/descricao do agente
- Status: `AGUARDANDO` (cinza), `EM ANDAMENTO` (amarelo), `CONCLUIDO` (verde), `ERRO` (vermelho)
- Detalhes do que esta fazendo

Status colors:
- Aguardando: `border-left:4px solid #64748b; background:#64748b22; color:#64748b;`
- Em andamento: `border-left:4px solid #f59e0b; background:#f59e0b22; color:#f59e0b;`
- Concluido: `border-left:4px solid #22c55e; background:#22c55e22; color:#22c55e;`
- Erro: `border-left:4px solid #ef4444; background:#ef444422; color:#ef4444;`

Barra de progresso global:
```html
<div style="display:flex;align-items:center;gap:8px;">
  <div style="flex:1;height:8px;background:#1e293b;border-radius:4px;overflow:hidden;">
    <div style="width:{PCT}%;height:100%;background:linear-gradient(90deg,#3b82f6,#22c55e);border-radius:4px;transition:width 0.5s;"></div>
  </div>
  <span style="font-size:13px;color:#94a3b8;">{PCT}%</span>
</div>
```

### 2. Opcoes Interativas

Use as classes do visual companion: `.options`, `.option`, `data-choice`, `toggleSelect(this)`.

SEMPRE inclua:
- Campo de comentario livre (textarea)
- Botao "Confirmar" usando `window.brainstorm.send()`
- Botao "Quero Mudar" com comentario obrigatorio

Template do botao de confirmar:
```html
<button onclick="
  var sel = document.querySelector('.option.selected');
  if(sel){
    var c = sel.getAttribute('data-choice');
    var t = sel.querySelector('h3').textContent;
    var comment = document.getElementById('user-comment')?.value?.trim() || '';
    window.brainstorm.send({type:'confirm',choice:c,text:'CONFIRMADO: '+t,comment:comment});
    this.textContent='Confirmado! Envie msg no terminal';
    this.style.background='#22c55e';
    this.disabled=true;
  } else {
    this.textContent='Selecione uma opcao primeiro!';
    this.style.background='#ef4444';
    var btn=this;
    setTimeout(function(){btn.textContent='Confirmar';btn.style.background='#3b82f6';},2000);
  }
" style="padding:14px 48px;font-size:16px;font-weight:600;background:#3b82f6;color:white;border:none;border-radius:8px;cursor:pointer;">
  Confirmar Escolha
</button>
```

### 3. Feedback Livre

Sempre incluir area de feedback:
```html
<textarea id="user-comment" placeholder="Adicione observacoes..." style="width:100%;min-height:60px;padding:12px;background:#0f172a;border:1px solid #334155;border-radius:8px;color:#e2e8f0;font-family:system-ui;font-size:14px;resize:vertical;"></textarea>
<button onclick="
  var c=document.getElementById('user-comment').value.trim();
  if(!c){document.getElementById('user-comment').focus();return;}
  window.brainstorm.send({type:'feedback',text:c});
  this.textContent='Enviado!';
  this.style.background='#22c55e';
" style="padding:10px 24px;font-size:14px;font-weight:600;background:#64748b;color:white;border:none;border-radius:8px;cursor:pointer;">
  Enviar Feedback
</button>
```

## Regras de Atualizacao

1. **Ao lancar agentes**: Publicar dashboard com todos os agentes em status AGUARDANDO/EM ANDAMENTO
2. **Ao receber resultado de agente**: Atualizar card para CONCLUIDO com resumo curto
3. **Ao receber erro**: Atualizar card para ERRO com mensagem
4. **Barra de progresso**: Calcular % como (concluidos / total) * 100
5. **NUNCA reutilizar nomes de arquivo** — use sufixos: `progress-v1.html`, `progress-v2.html`
6. **Ler eventos**: Antes de cada resposta ao usuario, ler `$STATE_DIR/events`

## Leitura de Eventos

IMPORTANTE: O arquivo `events` e LIMPO quando uma nova tela e publicada. Para nao perder eventos, leia do `server.log` que mantem o historico completo.

Apos o usuario enviar mensagem no terminal:
```bash
# Preferir server.log (historico completo) — filtrar por user-event
grep '"source":"user-event"' $STATE_DIR/server.log 2>/dev/null | tail -10

# Fallback: events (pode estar vazio se tela foi atualizada)
cat $STATE_DIR/events 2>/dev/null
```

Tipos de evento:
- `click` — usuario clicou opcao (choice field tem a letra)
- `confirm` — usuario confirmou escolha
- `feedback` — usuario enviou texto livre
- `change-request` — usuario quer mudar algo (text field tem o pedido)

## Dicas

- Modelo simples (haiku) pode ser usado para gerar HTML de atualizacao
- O servidor WebSocket garante refresh automatico no browser
- Sempre informar o usuario: "Envie msg no terminal para eu ler sua resposta"
- Ao finalizar, publicar pagina de resumo com resultados
