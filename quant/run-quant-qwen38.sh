#!/usr/bin/env bash
# Huihui-Qwen3.8-27B-abliterated 한국어 imatrix 파이프라인 (3차 릴리스)
# 무검열 베이스 + 한국어 보정 = 세상에 없던 조합. 방법론은 1·2차와 동일 (-c 512).
# 베이스: huihui 배포 bf16 GGUF (변환 단계 불필요). 덴스 27B — MoE 커버리지 이슈 없음.
# 주의: 전 단계 CPU 빌드 (bf16 50.9G > RAM — Vulkan 로드는 시스템 사망, gotchas G6)
#       실행 전 llama-router 정지 (RAM 플러딩 + 고정 GTT 조합 금지)
set -euo pipefail

LLAMA=${LLAMA_BIN:-$HOME/llama.cpp/build-cpu/bin}
WORK=~/models/work/qwen38-quant
CALIB=~/strix-local-ai/quant/corpus/calibration.txt
BF16=$WORK/Huihui-Qwen3.8-27B-abliterated-bf16.gguf
NAME=Huihui-Qwen3.8-27B-abliterated
Q8=$WORK/$NAME.KO-i1-Q8_0.gguf
IMAT=$WORK/$NAME.imatrix.gguf

step=${1:-all}

if [[ $step == q8 || $step == all ]]; then
  echo "=== [1/3] Q8_0 생산 (imatrix 계산용 + 릴리스용) ==="
  if [[ ! -f $Q8 ]]; then
    "$LLAMA/llama-quantize" "$BF16" "$Q8.tmp" Q8_0 "$(nproc)"
    mv "$Q8.tmp" "$Q8"   # 부분 파일 함정 차단: 성공 시에만 최종 이름
  fi
  ls -lh "$Q8"
fi

if [[ $step == imatrix || $step == all ]]; then
  echo "=== [2/3] 한국어 imatrix (Q8, CPU 빌드) ==="
  GTT_GUARD_MAX_USED_GIB="${GTT_GUARD_MAX_USED_GIB:-4}"
  gtt_used=$(cat /sys/class/drm/card*/device/mem_info_gtt_used 2>/dev/null | head -1)
  if [[ -n ${gtt_used:-} ]] && (( gtt_used > GTT_GUARD_MAX_USED_GIB * 1073741824 )); then
    echo "중단: GTT 점유 초과 — 'systemctl --user stop llama-router' 후 재시도" >&2
    exit 1
  fi
  LOG=$WORK/imatrix-$(date +%Y%m%d-%H%M%S).log
  echo "로그: $LOG"
  [[ -f $IMAT ]] || "$LLAMA/llama-imatrix" -m "$Q8" -f "$CALIB" -o "$IMAT" \
    -c 512 -b 1024 -ub 1024 -t 12 \
    --output-frequency 10 --save-frequency 50 2>&1 | tee "$LOG"
  echo "--- 커버리지 감사 ---"
  "$LLAMA/llama-imatrix" -m "$Q8" --in-file "$IMAT" --show-statistics 2>&1 | tail -15 || true
fi

if [[ $step == quantize || $step == all ]]; then
  echo "=== [3/3] 양자화 사다리 (BF16 + 한국어 imatrix) ==="
  # blk.64 = MTP(nextn) 레이어: 그래프 비활성 → imatrix 미수집 → 초저비트 bail (G7)
  #   → imatrix 불필요한 q4_K로 고정 (2026-08-18 dry-run으로 blk.64 확인)
  for T in Q6_K Q5_K_M Q4_K_M IQ4_XS IQ3_M IQ3_XXS IQ2_M; do
    OUT="$WORK/$NAME.KO-i1-$T.gguf"
    [[ -f "$OUT" ]] && { echo "skip $T"; continue; }
    "$LLAMA/llama-quantize" --imatrix "$IMAT" \
      --tensor-type 'blk\.64\.=q4_K' \
      "$BF16" "$OUT.tmp" "$T" "$(nproc)"
    mv "$OUT.tmp" "$OUT"
  done
  ls -lh "$WORK"/*.KO-i1-*.gguf
fi
