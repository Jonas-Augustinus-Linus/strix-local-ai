#!/usr/bin/env bash
# GPU 모드 전환 — 채팅(LLM) ↔ 이미지(ComfyUI)
# 890M은 GPU를 한 번에 하나만: MES 웨지(#5993) 때문에 llama-router와 ComfyUI
# 동시 실행 불가. comfyui.service의 Conflicts=llama-router가 자동 배제하므로
# 이 스크립트는 그 전환을 원터치로 감싼다. WebUI는 두 모드에서 같은 창.
set -euo pipefail
mode="${1:-status}"

case "$mode" in
  image|img)
    echo "→ 이미지 모드: ComfyUI 기동 (채팅 LLM 자동 정지)"
    systemctl --user start comfyui
    for i in $(seq 1 40); do curl -s -m 2 http://127.0.0.1:8188/system_stats >/dev/null 2>&1 && break; sleep 2; done
    curl -s -m 3 http://127.0.0.1:8188/system_stats >/dev/null 2>&1 \
      && echo "✓ ComfyUI 준비됨 (localhost:8188). WebUI에서 이미지 생성 가능." \
      || echo "✗ ComfyUI 응답 없음 — journalctl --user -u comfyui 확인"
    ;;
  chat|llm)
    echo "→ 채팅 모드: ComfyUI 정지 (LLM 라우터 자동 복귀)"
    systemctl --user stop comfyui 2>/dev/null || true
    for i in $(seq 1 15); do systemctl --user is-active --quiet llama-router && break; sleep 1; done
    systemctl --user is-active --quiet llama-router \
      && echo "✓ LLM 라우터 복귀 (localhost:8080). WebUI에서 채팅 가능." \
      || { echo "라우터 수동 기동"; systemctl --user start llama-router; }
    ;;
  status|*)
    c=$(systemctl --user is-active comfyui 2>/dev/null || echo inactive)
    r=$(systemctl --user is-active llama-router 2>/dev/null || echo inactive)
    g=$(cat /sys/class/drm/card*/device/mem_info_gtt_used 2>/dev/null | head -1)
    echo "ComfyUI(이미지): $c | llama-router(채팅): $r | GTT $(awk -v v="${g:-0}" 'BEGIN{printf "%.1f", v/2^30}')GiB"
    echo "전환: gpu-mode.sh image  |  gpu-mode.sh chat"
    ;;
esac
