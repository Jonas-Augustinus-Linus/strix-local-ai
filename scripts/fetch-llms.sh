#!/usr/bin/env bash
# LLM GGUF 다운로드 (권장 양자화만). 각 모델 = ~/models/<slug>/ 디렉터리 → 라우터 섹션명과 일치.
# 대소문자 양쪽 패턴 매칭(mlabonne=소문자 q5_k_m, mradermacher=대문자 Q5_K_M). 에러 무시하고 계속.
HF=/home/amd-ai/venvs/comfy/bin/hf
ROOT=/home/amd-ai/models
LOG=/home/amd-ai/strix-local-ai/scripts/fetch-llms.log
: > "$LOG"
echo "=== LLM fetch start $(date '+%F %T') ===" >>"$LOG"

# slug | repo | quant-token
MODELS=(
  "qwen3-coder-30b-a3b-abl|mradermacher/Huihui-Qwen3-Coder-30B-A3B-Instruct-abliterated-i1-GGUF|Q4_K_M"
  "gemma-3-27b-abl|mlabonne/gemma-3-27b-it-abliterated-GGUF|Q5_K_M"
  "cydonia-24b-v4.3|TheDrummer/Cydonia-24B-v4.3-GGUF|Q6_K"
  "mistral-small-3.2-24b-heretic|mradermacher/Mistral-Small-3.2-24B-Instruct-2506-ultra-uncensored-heretic-i1-GGUF|Q4_K_M"
  "qwen3-30b-a3b-thinking-abl|mradermacher/Huihui-Qwen3-30B-A3B-Thinking-2507-abliterated-GGUF|Q4_K_M"
  "magidonia-24b-v4.3|TheDrummer/Magidonia-24B-v4.3-GGUF|Q6_K"
  "qwen3.5-9b-abl|mradermacher/Huihui-Qwen3.5-9B-abliterated-GGUF|Q6_K"
  "gemma-4-12b-heretic-abl|culturerevolt/gemma-4-12b-heretic-abliterated-GGUF|Q8_0"
)

for m in "${MODELS[@]}"; do
  IFS='|' read -r slug repo q <<<"$m"
  dest="$ROOT/$slug"
  lo="${q,,}"                                   # 소문자 변형
  echo "" >>"$LOG"; echo ">>> [$slug] $repo :: $q  ($(date '+%T'))" >>"$LOG"
  if "$HF" download "$repo" --include "*$q*.gguf" --include "*$lo*.gguf" \
        --local-dir "$dest" >>"$LOG" 2>&1; then
    got=$(find "$dest" -name '*.gguf' 2>/dev/null | wc -l)
    if [ "$got" -gt 0 ]; then echo "OK   [$slug] files=$got size=$(du -sh "$dest" 2>/dev/null | cut -f1)" >>"$LOG"
    else echo "EMPTY[$slug] 패턴 불일치 — 파일 0개" >>"$LOG"; fi
  else
    echo "FAIL [$slug] hf download 실패" >>"$LOG"
  fi
done
echo "" >>"$LOG"; echo "=== LLM fetch done $(date '+%F %T') ===" >>"$LOG"
echo "SUMMARY:"; grep -E '^(OK|FAIL|EMPTY)' "$LOG"