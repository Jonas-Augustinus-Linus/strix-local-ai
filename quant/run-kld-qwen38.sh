#!/usr/bin/env bash
# Qwen3.8-27B-abliterated 한국어 KLD: BF16 기준 로짓 1회 생성 후 각 양자 비교.
# -c 512 전 단계 동일. 전부 CPU 빌드 (BF16 50.9G > RAM — G6). router 정지 필수.
set -euo pipefail

LLAMA=${KLD_BIN_DIR:-$HOME/llama.cpp/build-cpu/bin}
WORK=~/models/work/qwen38-quant
EVAL=~/strix-local-ai/quant/eval/eval-ko.txt
KLD=$WORK/eval-ko.kld
BF16=$WORK/Huihui-Qwen3.8-27B-abliterated-bf16.gguf
OUT=~/strix-local-ai/benchmarks/qwen38-kld-results.txt

if [[ ! -f $KLD ]]; then
  echo "=== BF16 기준 로짓 생성 (1회) ==="
  "$LLAMA/llama-perplexity" -m "$BF16" -f "$EVAL" --kl-divergence-base "$KLD" -t 12
  ls -lh "$KLD"
fi

targets=("$@")
[[ ${#targets[@]} -eq 0 ]] && targets=("$WORK"/*.KO-i1-*.gguf \
  "$HOME/models/qwen3.8-27b-abl/Huihui-Qwen3.8-27B-abliterated-Q5_K.gguf")

for Q in "${targets[@]}"; do
  [[ "$Q" == *imatrix* ]] && continue
  echo "===== $(basename "$Q") =====" | tee -a "$OUT"
  "$LLAMA/llama-perplexity" -m "$Q" --kl-divergence-base "$KLD" --kl-divergence -t 12 2>/dev/null \
    | { grep -E "Mean|RMS|Same|ppl" || true; } | tee -a "$OUT"
done
echo "결과 누적: $OUT"
