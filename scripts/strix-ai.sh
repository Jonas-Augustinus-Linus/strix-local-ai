#!/usr/bin/env bash
# Strix 로컬 AI 원클릭 런처 — 서비스 보장 + 모드 전환 + 브라우저
# 사용: strix-ai.sh [chat|image|status|menu]  (인자 없으면 menu)
export PATH="$HOME/.local/bin:/usr/local/bin:/usr/bin:/bin"
HERE="$(cd "$(dirname "$0")" && pwd)"
WEBUI="http://localhost:3000"

notify(){ notify-send -a "Strix AI" "$1" "${2:-}" 2>/dev/null || true; }

ensure_services(){
  # WebUI(docker) 보장
  if ! curl -s -m 2 "$WEBUI/health" >/dev/null 2>&1; then
    docker start open-webui >/dev/null 2>&1 || true
  fi
  # 채팅 라우터 보장 (이미지 모드가 아니면)
  systemctl --user is-active --quiet comfyui || systemctl --user start llama-router 2>/dev/null || true
}

open_browser(){ xdg-open "$WEBUI" >/dev/null 2>&1 & }

wait_webui(){ for i in $(seq 1 20); do curl -s -m 2 "$WEBUI/health" >/dev/null 2>&1 && return 0; sleep 1; done; }

case "${1:-menu}" in
  chat)
    notify "채팅 모드 준비 중…" "LLM 라우터를 켭니다"
    "$HERE/gpu-mode.sh" chat >/dev/null 2>&1
    ensure_services; wait_webui; open_browser
    notify "채팅 준비 완료" "브라우저에서 대화하세요"
    ;;
  image)
    notify "이미지 모드 준비 중…" "ComfyUI를 켭니다 (채팅 잠시 정지)"
    "$HERE/gpu-mode.sh" image >/dev/null 2>&1
    docker start open-webui >/dev/null 2>&1 || true
    wait_webui; open_browser
    notify "이미지 준비 완료" "WebUI 이미지 아이콘으로 생성하세요"
    ;;
  status)
    st=$("$HERE/gpu-mode.sh" status 2>/dev/null)
    web=$(curl -s -m 2 "$WEBUI/health" >/dev/null 2>&1 && echo "켜짐" || echo "꺼짐")
    if [ -n "${DISPLAY:-}${WAYLAND_DISPLAY:-}" ] && command -v zenity >/dev/null; then
      zenity --info --title="Strix AI 상태" --width=380 \
        --text="WebUI(브라우저): $web\n\n$st" 2>/dev/null || { echo "WebUI: $web"; echo "$st"; }
    else
      echo "WebUI: $web"; echo "$st"
    fi
    ;;
  menu|*)
    ch=$(zenity --list --title="Strix 로컬 AI" --width=420 --height=320 \
      --text="무엇을 하시겠어요?" --column="동작" --column="설명" \
      "채팅" "글쓰기·번역·코딩 (무검열 LLM)" \
      "이미지" "그림 생성 (Illustrious/NoobAI/Pony)" \
      "상태" "지금 무엇이 켜져 있나" \
      2>/dev/null)
    case "$ch" in
      채팅) exec "$0" chat ;;
      이미지) exec "$0" image ;;
      상태) exec "$0" status ;;
    esac
    ;;
esac
