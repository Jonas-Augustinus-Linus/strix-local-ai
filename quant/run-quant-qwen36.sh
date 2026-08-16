#!/usr/bin/env bash
# Qwen3.6-35B-A3B 한국어 imatrix 파이프라인 (2차 릴리스)
# 방법론: 2026-08-16 워크플로 검증 (Q8 기반 imatrix = mradermacher 공인 방식,
#   부분 오프로드 수집 정확성 소스 검증됨, 774청크 = 전문가당 ~2.5만 활성화)
set -euo pipefail

LLAMA=~/llama.cpp/build-current/bin
SRC=~/models/work/qwen36-35b-a3b
WORK=~/models/work/qwen36-quant
CALIB=~/strix-local-ai/quant/corpus/calibration.txt
BF16=$WORK/Qwen3.6-35B-A3B-BF16.gguf
Q8=$WORK/Qwen3.6-35B-A3B.KO-i1-Q8_0.gguf
IMAT=$WORK/Qwen3.6-35B-A3B.imatrix.gguf
NAME=Qwen3.6-35B-A3B
mkdir -p "$WORK"

step=${1:-all}

if [[ $step == convert || $step == all ]]; then
  echo "=== [1/4] BF16 GGUF 변환 (텐서 스트리밍, RAM 안전) ==="
  [[ -f $BF16 ]] || ~/venvs/convert/bin/python ~/llama.cpp/convert_hf_to_gguf.py "$SRC" \
    --outfile "$BF16" --outtype bf16
  ls -lh "$BF16"
fi

if [[ $step == q8 || $step == all ]]; then
  echo "=== [2/4] Q8_0 생산 (imatrix 계산용 + 릴리스용, imatrix 불필요) ==="
  [[ -f $Q8 ]] || "$LLAMA/llama-quantize" "$BF16" "$Q8" Q8_0 "$(nproc)"
  ls -lh "$Q8"
fi

if [[ $step == imatrix || $step == all ]]; then
  echo "=== [3/4] 한국어 imatrix (Q8, CPU 빌드 전용 — Vulkan 금지) ==="
  # 2026-08-16 실측: Vulkan 빌드는 이 35GB Q8 로드 자체가 치명적 —
  #   mmap 프리페치가 RAM(29.5GiB)을 플러드 → amdgpu CS ENOMEM → DeviceLost,
  #   n-cpu-moe 24/32/999 전부 재현, GTT가 비어 있어도 발생. 한 번은 시스템 행→강제종료.
  #   RAM보다 큰 모델의 imatrix는 반드시 CPU 빌드로 (mmap 스트리밍, GPU 무관).
  IMATRIX_BIN="${IMATRIX_BIN:-$HOME/llama.cpp/build-cpu/bin/llama-imatrix}"

  # GTT 가드: GPU 점유가 크면(주로 llama-router 미정지) 시작 자체를 거부
  #   (CPU 실행이라도 RAM 압박이 GPU 클라이언트를 죽일 수 있음 — 위 실측)
  GTT_GUARD_MAX_USED_GIB="${GTT_GUARD_MAX_USED_GIB:-4}"
  gtt_used=$(cat /sys/class/drm/card*/device/mem_info_gtt_used 2>/dev/null | head -1)
  gtt_total=$(cat /sys/class/drm/card*/device/mem_info_gtt_total 2>/dev/null | head -1)
  if [[ -n ${gtt_used:-} ]]; then
    awk -v u="$gtt_used" -v t="$gtt_total" -v g="$GTT_GUARD_MAX_USED_GIB" \
      'BEGIN{printf "GTT 사용량: %.1f/%.1f GiB (가드 임계 %s GiB)\n", u/2^30, t/2^30, g}'
    if (( gtt_used > GTT_GUARD_MAX_USED_GIB * 1073741824 )); then
      echo "중단: GTT 점유가 임계를 초과 — 'systemctl --user stop llama-router' 후 재시도" >&2
      exit 1
    fi
  fi

  LOG=$WORK/imatrix-$(date +%Y%m%d-%H%M%S).log
  echo "로그: $LOG"
  [[ -f $IMAT ]] || "$IMATRIX_BIN" -m "$Q8" -f "$CALIB" -o "$IMAT" \
    -c 512 -b 1024 -ub 1024 -t 12 \
    --output-frequency 10 --save-frequency 50 2>&1 | tee "$LOG"
  echo "--- 전문가 커버리지 감사 ---"
  "$IMATRIX_BIN" -m "$Q8" --in-file "$IMAT" --show-statistics 2>&1 | tail -20 || true
fi

if [[ $step == quantize || $step == all ]]; then
  echo "=== [4/4] 양자화 사다리 (BF16 원본 + 한국어 imatrix) ==="
  for T in Q6_K Q5_K_M Q4_K_M IQ4_XS IQ3_M IQ3_XXS IQ2_M; do
    OUT="$WORK/$NAME.KO-i1-$T.gguf"
    [[ -f "$OUT" ]] && { echo "skip $T"; continue; }
    "$LLAMA/llama-quantize" --imatrix "$IMAT" "$BF16" "$OUT" "$T" "$(nproc)"
  done
  ls -lh "$WORK"/*.gguf
fi
