#!/usr/bin/env bash
# Huihui-Qwen3.6-35B-A3B-abliterated 한국어 imatrix 파이프라인 (4차 릴리스)
# 무검열 A3B MoE + 한국어 보정. 2차(정식 Qwen3.6 KO-i1)와 같은 방법론·코퍼스 →
#   같은 조건 정식-vs-abliterated 비교 가능 (abliteration이 한국어 보정에 주는 영향).
# 베이스: huihui safetensors 26샤드 → convert로 f16 GGUF (변환 단계 포함).
# 주의: 전 단계 CPU 빌드 (f16 66G > RAM, G6). router 정지 후 실행.
set -euo pipefail

LLAMA=${LLAMA_BIN:-$HOME/llama.cpp/build-cpu/bin}
WORK=~/models/work/qwen36abl-quant
SRC=~/models/work/qwen36-abl-src
CALIB=~/strix-local-ai/quant/corpus/calibration.txt
BF16=$WORK/Huihui-Qwen3.6-35B-A3B-abliterated-f16.gguf
NAME=Huihui-Qwen3.6-35B-A3B-abliterated
Q8=$WORK/$NAME.KO-i1-Q8_0.gguf
IMAT=$WORK/$NAME.imatrix.gguf
# MTP(nextn) 레이어 번호 — dry-run 확정: blk.40 (2026-08-19, 정식판과 동일) (G7)
MTP_BLK="${MTP_BLK:-40}"
mkdir -p "$WORK"

step=${1:-all}

if [[ $step == convert || $step == all ]]; then
  echo "=== [1/4] f16 GGUF 변환 (텐서 스트리밍, RAM 안전) ==="
  [[ -f $BF16 ]] || ~/venvs/convert/bin/python ~/llama.cpp/convert_hf_to_gguf.py "$SRC" \
    --outfile "$BF16.tmp" --outtype f16 && mv "$BF16.tmp" "$BF16"
  ls -lh "$BF16"
fi

if [[ $step == q8 || $step == all ]]; then
  echo "=== [2/4] Q8_0 생산 ==="
  if [[ ! -f $Q8 ]]; then
    "$LLAMA/llama-quantize" "$BF16" "$Q8.tmp" Q8_0 "$(nproc)"; mv "$Q8.tmp" "$Q8"
  fi
  ls -lh "$Q8"
fi

if [[ $step == imatrix || $step == all ]]; then
  echo "=== [3/4] 한국어 imatrix (Q8, CPU 빌드) ==="
  GTT_GUARD_MAX_USED_GIB="${GTT_GUARD_MAX_USED_GIB:-4}"
  gtt_used=$(cat /sys/class/drm/card*/device/mem_info_gtt_used 2>/dev/null | head -1)
  if [[ -n ${gtt_used:-} ]] && (( gtt_used > GTT_GUARD_MAX_USED_GIB * 1073741824 )); then
    echo "중단: GTT 점유 초과 — 'systemctl --user stop llama-router' 후 재시도" >&2; exit 1
  fi
  LOG=$WORK/imatrix-$(date +%Y%m%d-%H%M%S).log; echo "로그: $LOG"
  [[ -f $IMAT ]] || "$LLAMA/llama-imatrix" -m "$Q8" -f "$CALIB" -o "$IMAT" \
    -c 512 -b 1024 -ub 1024 -t 12 --output-frequency 10 --save-frequency 50 2>&1 | tee "$LOG"
  echo "--- 커버리지 감사 ---"
  "$LLAMA/llama-imatrix" -m "$Q8" --in-file "$IMAT" --show-statistics 2>&1 | tail -15 || true
fi

if [[ $step == quantize || $step == all ]]; then
  echo "=== [4/4] 양자화 사다리 (blk.$MTP_BLK = MTP q4_K 고정, G7) ==="
  for T in Q6_K Q5_K_M Q4_K_M IQ4_XS IQ3_M IQ3_XXS IQ2_M; do
    OUT="$WORK/$NAME.KO-i1-$T.gguf"
    [[ -f "$OUT" ]] && { echo "skip $T"; continue; }
    "$LLAMA/llama-quantize" --imatrix "$IMAT" \
      --tensor-type "blk\\.$MTP_BLK\\.=q4_K" \
      "$BF16" "$OUT.tmp" "$T" "$(nproc)"; mv "$OUT.tmp" "$OUT"
  done
  ls -lh "$WORK"/*.KO-i1-*.gguf
fi
