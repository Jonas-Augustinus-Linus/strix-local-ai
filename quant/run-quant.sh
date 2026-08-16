#!/usr/bin/env bash
# kanana-1.5-8b 한국어 imatrix 양자화 파이프라인 (방법론: 2026-08-16 리서치로 검증)
# 단계: convert → imatrix → quantize 세트. KLD 측정은 run-kld.sh 별도.
set -euo pipefail

LLAMA=~/llama.cpp/build-current/bin
SRC=~/models/work/kanana-1.5-8b-instruct-2505
WORK=~/models/work/kanana-quant
CALIB=~/strix-local-ai/quant/corpus/calibration.txt
F16=$WORK/kanana-1.5-8b-instruct-2505-F16.gguf
IMAT=$WORK/kanana-1.5-8b-instruct-2505.imatrix.gguf
NAME=kanana-1.5-8b-instruct-2505
mkdir -p "$WORK"

step=${1:-all}

if [[ $step == convert || $step == all ]]; then
  echo "=== [1/3] F16 GGUF 변환 (CPU) ==="
  ~/venvs/convert/bin/python ~/llama.cpp/convert_hf_to_gguf.py "$SRC" \
    --outfile "$F16" --outtype f16
  ls -lh "$F16"
fi

if [[ $step == imatrix || $step == all ]]; then
  echo "=== [2/3] 한국어 imatrix 생성 (Vulkan -ngl 99, 기본 c=512 유지) ==="
  # 주의: GPU 선점 — llama-router의 로드된 모델을 먼저 내릴 것 (run-quant.sh 밖에서)
  "$LLAMA/llama-imatrix" -m "$F16" -f "$CALIB" -o "$IMAT" -ngl 99
  ls -lh "$IMAT"
fi

if [[ $step == quantize || $step == all ]]; then
  echo "=== [3/3] 양자화 세트 생산 ==="
  # imatrix 필수: IQ2_M(IQ2_S 텐서), IQ3_XXS / 강한 이득: IQ3_M, IQ4_XS, Q2~Q4 계열
  for T in Q8_0 Q6_K Q5_K_M Q4_K_M IQ4_XS Q3_K_M IQ3_M IQ3_XXS IQ2_M; do
    OUT="$WORK/$NAME.KO-i1-$T.gguf"
    [[ -f "$OUT" ]] && { echo "skip $T (존재)"; continue; }
    "$LLAMA/llama-quantize" --imatrix "$IMAT" "$F16" "$OUT" "$T" "$(nproc)"
  done
  ls -lh "$WORK"/*.gguf
fi
