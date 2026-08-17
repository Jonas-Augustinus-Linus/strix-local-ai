#!/usr/bin/env bash
# Qwen3.6-35B-A3B 한국어 KLD 측정: BF16 기준 로짓 1회 생성 후 각 양자화판 비교.
# 주의: -c는 전 단계 동일(기본 512) 유지 — 다르면 결과 무효.
# 전 단계 CPU 빌드 강제 — BF16(66GB) > RAM(29.5GiB)이라 Vulkan 로드는
#   mmap 프리페치 RAM 플러드 → amdgpu DeviceLost/시스템 행 (2026-08-16 실측).
#   CPU mmap 스트리밍은 안전. 실행 전 llama-router 정지 권장(고정 GTT + RAM 압박 조합 회피).
set -euo pipefail

LLAMA=${KLD_BIN_DIR:-$HOME/llama.cpp/build-cpu/bin}
WORK=~/models/work/qwen36-quant
EVAL=${EVAL_FILE:-$HOME/strix-local-ai/quant/eval/eval-ko.txt}
KLD=$WORK/eval-ko.kld
BF16=$WORK/Qwen3.6-35B-A3B-BF16.gguf
OUT=~/strix-local-ai/benchmarks/qwen36-kld-results.txt

if [[ ! -f $KLD ]]; then
  echo "=== BF16 기준 로짓 생성 (1회, vocab 248k × 토큰수 ≈ 수십 GB 주의) ==="
  "$LLAMA/llama-perplexity" -m "$BF16" -f "$EVAL" --kl-divergence-base "$KLD" -t 12
  ls -lh "$KLD"
fi

targets=("$@")
[[ ${#targets[@]} -eq 0 ]] && targets=("$WORK"/*.KO-i1-*.gguf)

for Q in "${targets[@]}"; do
  [[ "$Q" == *imatrix* ]] && continue
  echo "===== $(basename "$Q") =====" | tee -a "$OUT"
  "$LLAMA/llama-perplexity" -m "$Q" --kl-divergence-base "$KLD" --kl-divergence -t 12 2>/dev/null \
    | { grep -E "Mean|RMS|Same|ppl" || true; } | tee -a "$OUT"
done
echo "결과 누적: $OUT"
