#!/usr/bin/env bash
# llama-server 기동 — OpenAI 호환 API (http://127.0.0.1:8080)
# 사용법: ./serve.sh [모델경로.gguf] [추가 llama-server 인자...]
set -euo pipefail

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
MODELS_DIR="${MODELS_DIR:-$HOME/models}"
MODEL="${1:-$MODELS_DIR/Qwen3-4B-Instruct-2507-Q4_K_M.gguf}"
shift || true

BIN="$LLAMA_DIR/build-current/bin/llama-server"
[[ -x "$BIN" ]] || { echo "llama-server 없음 — scripts/setup-llamacpp.sh 먼저 실행"; exit 1; }

# Vulkan 빌드면 전체 레이어를 iGPU(GTT)로 오프로드
NGL_ARGS=()
if [[ "$(readlink "$LLAMA_DIR/build-current")" == *vulkan* ]]; then
  NGL_ARGS=(-ngl 99)
fi

exec "$BIN" -m "$MODEL" \
  --host 127.0.0.1 --port 8080 \
  -c 8192 --jinja \
  "${NGL_ARGS[@]}" \
  "$@"
