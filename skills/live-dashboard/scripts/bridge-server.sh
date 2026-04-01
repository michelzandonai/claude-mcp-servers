#!/bin/bash
# Bridge: recebe POST do browser e envia keystroke para o terminal ativo
# Roda em background como HTTP server minimalista na porta 9099

PORT="${1:-9099}"
PIPE="/tmp/claude-dashboard-bridge"

# Limpar pipe anterior
rm -f "$PIPE"
mkfifo "$PIPE"

echo "{\"type\":\"bridge-started\",\"port\":$PORT}"

while true; do
  # Servidor HTTP minimalista via netcat
  REQUEST=$(cat "$PIPE" 2>/dev/null)

  {
    read -r REQUEST_LINE
    # Ler headers
    while read -r HEADER && [ "$HEADER" != $'\r' ] && [ -n "$HEADER" ]; do :; done

    # Responder com CORS headers
    echo -e "HTTP/1.1 200 OK\r\nAccess-Control-Allow-Origin: *\r\nAccess-Control-Allow-Methods: POST, OPTIONS\r\nContent-Type: application/json\r\nConnection: close\r\n\r\n{\"ok\":true}"

    # Se for POST (não OPTIONS), enviar keystroke
    if echo "$REQUEST_LINE" | grep -q "POST"; then
      # Detectar terminal ativo e enviar "ok" + Enter
      osascript -e '
        tell application "System Events"
          set frontApp to name of first application process whose frontmost is true
        end tell
        -- Procura por terminais conhecidos
        set terminalApps to {"Ghostty", "iTerm2", "Terminal", "Code"}
        repeat with appName in terminalApps
          try
            if application appName is running then
              tell application appName to activate
              delay 0.3
              tell application "System Events"
                keystroke "ok"
                key code 36 -- Enter
              end tell
              exit repeat
            end if
          end try
        end repeat
      ' 2>/dev/null &
    fi
  } < <(nc -l "$PORT" 2>/dev/null)
done
