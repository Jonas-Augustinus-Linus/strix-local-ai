#!/usr/bin/env bash
# ============================================================================
#  NPU (FastFlowLM) vs iGPU (llama.cpp Vulkan) — A/B decode/prefill benchmark
#  Strix Point / Ryzen AI 9 HX PRO 370 / Radeon 890M (gfx1150) / XDNA2 (aie2p)
#
#  Settles the open questions from the NPU-LLM feasibility research, EMPIRICALLY:
#    Q1  Does the NPU beat the iGPU on DECODE t/s? (both bandwidth-bound on
#        the SAME LPDDR5x controller — this is the load-bearing question)
#    Q2  How big is the NPU PREFILL win? (compute-bound; NPU predicted 300-400 t/s @8B)
#    Q3  TTFT delta at chat-realistic prompt sizes
#    Q4  Is 27B usable on either path? (borderline ~3.5-5 t/s decode)
#
#  Output: results/*.json  +  RESULTS.md table  (sanitized, publishable)
#
#  PREREQS (run ONCE, see INSTALL-FLM.md): FLM installed, `flm serve` works.
#  This box already meets kernel/amdxdna/XRT/memlock reqs — no reboot needed.
# ============================================================================
set -uo pipefail
cd "$(dirname "$0")"
HERE="$(pwd)"
RESDIR="$HERE/results"; mkdir -p "$RESDIR"
STAMP="${1:-manual}"           # pass a date string as $1 (script can't call Date.now)
PY=python3
IGPU_PORT=8080
NPU_PORT=8081
LSERVER="$HOME/llama.cpp/build-current/bin/llama-server"
LBENCH="$HOME/llama.cpp/build-current/bin/llama-bench"

# ---- Benchmark matrix -------------------------------------------------------
# Each row:  LABEL | iGPU_GGUF (abs path) | FLM_MODEL_ID | CTX
# FLM_MODEL_ID: confirm exact ids with `flm list` after install (ollama-style).
# Pick GGUF + FLM of the SAME family/size so the A/B is apples-to-apples
# (iGPU native Q4_K_M  vs  NPU native W4A16 — each backend's optimal quant).
MODELS=(
  "Qwen3-4B|$HOME/models/Qwen3-4B-2507-abl-i1-Q4_K_M.gguf|qwen3:4b|16384"
  # "Llama3.1-8B|$HOME/models/<llama3.1-8b-Q4_K_M>.gguf|llama3.1:8b|16384"   # add a Q4_K_M 8B
  # "Qwen3-8B|$HOME/models/<qwen3-8b-Q4_K_M>.gguf|qwen3:8b|16384"
  # "Qwen3.8-27B|$HOME/models/qwen3.8-27b-abl/<file>.gguf|<flm 27b id if any>|16384"  # Q4: headline
)
PROMPT_TOKENS=512     # chat-realistic prefill
GEN=128               # decode window
REPEAT=3

log(){ printf '\033[1;32m[ab]\033[0m %s\n' "$*"; }
err(){ printf '\033[1;31m[ab]\033[0m %s\n' "$*" >&2; }

stop_services(){
  log "GPU/NPU 확보: comfyui + llama-router 정지 (상호배제)"
  systemctl --user stop comfyui.service   2>/dev/null || true
  systemctl --user stop llama-router.service 2>/dev/null || true
  sleep 2
}
restore_services(){
  log "라우터 복원 (chat 모드)"
  systemctl --user start llama-router.service 2>/dev/null || true
}

wait_ready(){  # $1=base_url  $2=timeout_s
  local url="$1" t="${2:-120}" i=0
  until curl -sf "$url/models" >/dev/null 2>&1; do
    sleep 1; i=$((i+1)); [ "$i" -ge "$t" ] && { err "endpoint 준비 실패: $url"; return 1; }
  done
}

bench_endpoint(){ # $1=base_url $2=model $3=label $4=outjson
  $PY "$HERE/bench_client.py" --url "$1" --model "$2" \
    --prompt-tokens "$PROMPT_TOKENS" --gen "$GEN" --repeat "$REPEAT" \
    --label "$3" --json-out "$4"
}

run_igpu(){ # $1=label $2=gguf $3=ctx  -> results/<label>.igpu.json  (+ raw llama-bench)
  local label="$1" gguf="$2" ctx="$3"
  [ -f "$gguf" ] || { err "GGUF 없음, iGPU 스킵: $gguf"; return 1; }
  log "iGPU-Vulkan 시작: $label  ($(basename "$gguf"))"
  "$LSERVER" -m "$gguf" -ngl 99 -fa 1 -c "$ctx" --host 127.0.0.1 --port $IGPU_PORT \
      >"$RESDIR/$label.igpu.server.log" 2>&1 &
  local pid=$!
  if wait_ready "http://127.0.0.1:$IGPU_PORT/v1" 180; then
    bench_endpoint "http://127.0.0.1:$IGPU_PORT/v1" "$label" "iGPU-Vulkan $label" \
        "$RESDIR/$label.igpu.json" || err "iGPU bench 실패: $label"
  fi
  kill $pid 2>/dev/null; wait $pid 2>/dev/null
  # raw llama-bench cross-check (community-standard reference numbers)
  log "iGPU llama-bench 레퍼런스: $label"
  "$LBENCH" -m "$gguf" -ngl 99 -fa 1 -p "$PROMPT_TOKENS" -n "$GEN" -r 3 -o json \
      >"$RESDIR/$label.igpu.llamabench.json" 2>"$RESDIR/$label.igpu.llamabench.log" || true
}

run_npu(){ # $1=label $2=flm_model  -> results/<label>.npu.json
  local label="$1" fm="$2"
  command -v flm >/dev/null 2>&1 || { err "flm 미설치, NPU 스킵 (INSTALL-FLM.md 참조)"; return 1; }
  log "NPU-FLM 시작: $label  ($fm)"
  # CONFIRM flags with `flm --help` after install. Common: `flm serve <model> --port N`.
  flm serve "$fm" --port $NPU_PORT >"$RESDIR/$label.npu.server.log" 2>&1 &
  local pid=$!
  if wait_ready "http://127.0.0.1:$NPU_PORT/v1" 240; then
    bench_endpoint "http://127.0.0.1:$NPU_PORT/v1" "$fm" "NPU-FLM $label" \
        "$RESDIR/$label.npu.json" || err "NPU bench 실패: $label"
  fi
  kill $pid 2>/dev/null; wait $pid 2>/dev/null
}

# ---- main -------------------------------------------------------------------
stop_services
trap restore_services EXIT

for row in "${MODELS[@]}"; do
  IFS='|' read -r label gguf fm ctx <<<"$row"
  echo "════════════════════════════════════════════════"
  log "모델: $label"
  run_igpu "$label" "$gguf" "$ctx"
  run_npu  "$label" "$fm"
done

log "집계 → RESULTS.md"
$PY "$HERE/tabulate.py" "$RESDIR" "$STAMP" > "$HERE/RESULTS.md" && log "완료: RESULTS.md"
