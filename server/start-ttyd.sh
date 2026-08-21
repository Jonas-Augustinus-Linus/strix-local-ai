#!/bin/bash
# ttyd 웹 터미널 — ~/.config/strix-hub/terminal-cred (user:pass) 읽어 베이직 인증으로 실행.
CRED=$(cat "$HOME/.config/strix-hub/terminal-cred" 2>/dev/null)
[ -z "$CRED" ] && { echo "자격증명 없음 — ~/.config/strix-hub/terminal-cred 에 user:pass 필요"; exit 1; }
exec "$HOME/.local/bin/ttyd" -p 7681 -i 127.0.0.1 -W -c "$CRED" \
  -t fontSize=15 -t 'theme={"background":"#0e1014","foreground":"#e8eaef"}' \
  -t titleFixed="Strix 터미널" bash
