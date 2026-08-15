#!/usr/bin/env bash
# Hugging Face에서 GGUF 모델 다운로드 (이어받기 지원)
# 사용법: ./download-model.sh [<repo> <filename>]
#   예:   ./download-model.sh Qwen/Qwen3-4B-Instruct-2507-GGUF Qwen3-4B-Instruct-2507-Q4_K_M.gguf
set -euo pipefail

MODELS_DIR="${MODELS_DIR:-$HOME/models}"
mkdir -p "$MODELS_DIR"

REPO="${1:-unsloth/Qwen3-4B-Instruct-2507-GGUF}"
FILE="${2:-Qwen3-4B-Instruct-2507-Q4_K_M.gguf}"

URL="https://huggingface.co/${REPO}/resolve/main/${FILE}"
OUT="$MODELS_DIR/$FILE"

echo "[i] $URL"
echo "[i] → $OUT"
curl -L --fail --retry 3 -C - -o "$OUT" "$URL"
echo "[✓] 완료: $(du -h "$OUT" | cut -f1)"
