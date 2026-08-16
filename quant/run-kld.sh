#!/usr/bin/env bash
# 한국어 KLD 측정: F16 기준 로짓 1회 생성 후 각 양자화판 비교.
# 주의: -c는 전 단계 동일(기본 512) 유지 — 다르면 결과 무효.
set -euo pipefail

LLAMA=~/llama.cpp/build-current/bin
WORK=~/models/work/kanana-quant
EVAL=~/strix-local-ai/quant/eval/eval-ko.txt
KLD=$WORK/eval-ko.kld
F16=$WORK/kanana-1.5-8b-instruct-2505-F16.gguf
OUT=~/strix-local-ai/benchmarks/kanana-kld-results.txt

if [[ ! -f $KLD ]]; then
  echo "=== F16 기준 로짓 생성 (1회, 대용량 주의) ==="
  "$LLAMA/llama-perplexity" -m "$F16" -f "$EVAL" --kl-divergence-base "$KLD" -ngl 99
  ls -lh "$KLD"
fi

shift_or_all=("$@")
[[ ${#shift_or_all[@]} -eq 0 ]] && shift_or_all=("$WORK"/*.KO-i1-*.gguf ~/models/work/baseline/*.gguf)

for Q in "${shift_or_all[@]}"; do
  [[ "$Q" == *imatrix* ]] && continue
  echo "===== $(basename "$Q") =====" | tee -a "$OUT"
  "$LLAMA/llama-perplexity" -m "$Q" --kl-divergence-base "$KLD" --kl-divergence -ngl 99 2>/dev/null \
    | grep -E "Mean|RMS|Same|ppl" | tee -a "$OUT"
done
echo "결과 누적: $OUT"
