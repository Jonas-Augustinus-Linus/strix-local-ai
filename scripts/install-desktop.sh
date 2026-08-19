#!/usr/bin/env bash
# 바탕화면 아이콘 + 앱 메뉴 등록 (GNOME). 3개: 채팅/이미지/상태 + 통합 런처.
set -euo pipefail
HERE="$(cd "$(dirname "$0")" && pwd)"
LAUNCH="$HERE/strix-ai.sh"
chmod +x "$LAUNCH" "$HERE/gpu-mode.sh"

APPS=~/.local/share/applications
DESK="$(xdg-user-dir DESKTOP 2>/dev/null || echo ~/바탕화면)"
mkdir -p "$APPS" "$DESK"

make_desktop(){ # name icon action comment
  cat <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=$1
Comment=$4
Exec=$LAUNCH $3
Icon=$2
Terminal=false
Categories=Utility;
StartupNotify=true
EOF
}

declare -A ENTRIES=(
  ["Strix-AI"]="applications-science|menu|로컬 AI 런처 (채팅·이미지 선택)"
  ["Strix-AI-채팅"]="user-available|chat|무검열 LLM 채팅 (글쓰기·번역·코딩)"
  ["Strix-AI-이미지"]="applications-graphics|image|이미지 생성 (Illustrious/NoobAI/Pony)"
  ["Strix-AI-상태"]="utilities-system-monitor|status|무엇이 켜져 있나 확인"
)

for name in "${!ENTRIES[@]}"; do
  IFS='|' read -r icon action comment <<< "${ENTRIES[$name]}"
  f="$APPS/$name.desktop"
  make_desktop "$name" "$icon" "$action" "$comment" > "$f"
  chmod +x "$f"
  # 바탕화면에도 복사 + GNOME 신뢰 설정
  d="$DESK/$name.desktop"
  cp "$f" "$d"; chmod +x "$d"
  gio set "$d" metadata::trusted true 2>/dev/null || true
done

update-desktop-database "$APPS" 2>/dev/null || true
echo "[✓] 설치 완료: 앱 메뉴 + 바탕화면 아이콘 4개 (Strix-AI, 채팅, 이미지, 상태)"
echo "    바탕화면 아이콘이 회색이면 우클릭 → '실행 허용' 한 번 필요할 수 있음 (GNOME 보안)"
