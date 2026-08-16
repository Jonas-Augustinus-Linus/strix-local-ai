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
  echo "=== [3/4] 한국어 imatrix (Q8 + 부분 오프로드: GTT ~23GB 목표) ==="
  # 주의: GPU 선점 — llama-router 정지 상태에서 실행할 것
  # --n-cpu-moe 24: 전문가 24개 레이어를 CPU(mmap)에 — GTT 사용량 보며 조정
  [[ -f $IMAT ]] || "$LLAMA/llama-imatrix" -m "$Q8" -f "$CALIB" -o "$IMAT" \
    -ngl 999 --n-cpu-moe 24 -c 512 -b 1024 -ub 1024 -t 12 \
    --output-frequency 10 --save-frequency 50
  echo "--- 전문가 커버리지 감사 ---"
  "$LLAMA/llama-imatrix" --in-file "$IMAT" --show-statistics 2>/dev/null | tail -20 || true
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
