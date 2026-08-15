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
# --http1.1: HF CDN의 HTTP/2 스트림 CANCEL(curl err 92) 회피
# --retry-all-errors: err 92 같은 프로토콜 오류도 재시도 (-C -로 이어받기)
curl -L --fail --http1.1 -sS \
  --retry 10 --retry-delay 5 --retry-all-errors -C - \
  -o "$OUT" "$URL"

# 크기 검증: HF API의 원본 크기와 대조
EXPECTED=$(curl -sL "https://huggingface.co/api/models/${REPO}/tree/main" \
  | python3 -c "import json,sys; print(next((f['size'] for f in json.load(sys.stdin) if f['path']=='$FILE'), 0))" 2>/dev/null || echo 0)
ACTUAL=$(stat -c %s "$OUT")
if [[ "$EXPECTED" != "0" && "$ACTUAL" != "$EXPECTED" ]]; then
  echo "[✗] 크기 불일치: $ACTUAL / $EXPECTED bytes — 재실행하면 이어받습니다" >&2
  exit 1
fi
echo "[✓] 완료: $(du -h "$OUT" | cut -f1) (크기 검증 통과)"
