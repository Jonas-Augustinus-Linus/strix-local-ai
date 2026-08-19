#!/usr/bin/env bash
# Huihui-Qwen3.6-35B-A3B-abliterated 한국어 imatrix 파이프라인 (4차 릴리스)
# 2차(공식판)와 동일 방법론의 무검열판 형제. -c 512, CPU 빌드 강제(G6),
# blk.40 MTP q4_K 고정(G7), 부분 파일 차단(.tmp→mv). router 정지 후 실행.
set -euo pipefail

LLAMA=${LLAMA_BIN:-$HOME/llama.cpp/build-cpu/bin}
SRC=~/models/work/qwen36-abl-src
WORK=~/models/work/qwen36-abl-quant
CALIB=~/strix-local-ai/quant/corpus/calibration.txt
NAME=Huihui-Qwen3.6-35B-A3B-abliterated
BF16=$WORK/$NAME-BF16.gguf
Q8=$WORK/$NAME.KO-i1-Q8_0.gguf
IMAT=$WORK/$NAME.imatrix.gguf
mkdir -p "$WORK"

step=${1:-all}

if [[ $step == convert || $step == all ]]; then
  echo "=== [1/4] BF16 GGUF 변환 (텐서 스트리밍) ==="
  [[ -f $BF16 ]] || { ~/venvs/convert/bin/python ~/llama.cpp/convert_hf_to_gguf.py "$SRC" \
    --outfile "$BF16.tmp" --outtype bf16 && mv "$BF16.tmp" "$BF16"; }
  ls -lh "$BF16"
fi

if [[ $step == q8 || $step == all ]]; then
  echo "=== [2/4] Q8_0 생산 ==="
  [[ -f $Q8 ]] || { "$LLAMA/llama-quantize" "$BF16" "$Q8.tmp" Q8_0 "$(nproc)" && mv "$Q8.tmp" "$Q8"; }
  ls -lh "$Q8"
fi

if [[ $step == imatrix || $step == all ]]; then
  echo "=== [3/4] 한국어 imatrix (Q8, CPU) ==="
  gtt_used=$(cat /sys/class/drm/card*/device/mem_info_gtt_used 2>/dev/null | head -1)
  if [[ -n ${gtt_used:-} ]] && (( gtt_used > 4*1073741824 )); then
    echo "중단: GTT 점유 초과 — router 정지 후 재시도" >&2; exit 1
  fi
  LOG=$WORK/imatrix-$(date +%Y%m%d-%H%M%S).log
  [[ -f $IMAT ]] || "$LLAMA/llama-imatrix" -m "$Q8" -f "$CALIB" -o "$IMAT" \
    -c 512 -b 1024 -ub 1024 -t 12 --output-frequency 10 --save-frequency 50 2>&1 | tee "$LOG"
  "$LLAMA/llama-imatrix" -m "$Q8" --in-file "$IMAT" --show-statistics 2>&1 | tail -15 || true
fi

if [[ $step == quantize || $step == all ]]; then
  echo "=== [4/4] 양자화 사다리 ==="
  for T in Q6_K Q5_K_M Q4_K_M IQ4_XS IQ3_M IQ3_XXS IQ2_M; do
    OUT="$WORK/$NAME.KO-i1-$T.gguf"
    [[ -f "$OUT" ]] && { echo "skip $T"; continue; }
    "$LLAMA/llama-quantize" --im