#!/usr/bin/env bash
# 이미지/영상 모델 다운로드. DiT/체크포인트 = ComfyUI diffusion_models 폴더(플랫).
# HiDream 계열은 기존 인코더·VAE 재사용. Z-Image/Wan/Hunyuan은 배선 단계에서 인코더 별도.
HF=/home/amd-ai/venvs/comfy/bin/hf
DIFF=/home/amd-ai/models/comfyui/diffusion_models
LOG=/home/amd-ai/strix-local-ai/scripts/fetch-images.log
: > "$LOG"
echo "=== IMAGE fetch start $(date '+%F %T') ===" >>"$LOG"

# label | repo | include-glob | dest
MODELS=(
  "HiDream-Dev|city96/HiDream-I1-Dev-gguf|*Q6_K*.gguf|$DIFF"
  "HiDream-Full|city96/HiDream-I1-Full-gguf|*Q5_K_S*.gguf|$DIFF"
  "HiDream-uncensored-fp8|e-n-v-y/hidream-uncensored|*full_uncensored_fp8*.safetensors|$DIFF"
  "HiDream-E1.1-edit|QuantStack/HiDream-E1-1-GGUF|*Q6_K*.gguf|$DIFF"
  "Z-Image-Turbo|unsloth/Z-Image-Turbo-GGUF|*Q8_0*.gguf|$DIFF"
  "Z-Image-base|unsloth/Z-Image-GGUF|*Q8_0*.gguf|$DIFF"
  "Wan2.2-T2V-A14B|QuantStack/Wan2.2-T2V-A14B-GGUF|*Q5_K_M*.gguf|$DIFF"
  "HunyuanVideo-1.5|jayn7/HunyuanVideo-1.5_T2V_720p-GGUF|*Q6_K*.gguf|$DIFF"
)

for m in "${MODELS[@]}"; do
  IFS='|' read -r label repo inc dest <<<"$m"
  echo "" >>"$LOG"; echo ">>> [$label] $repo :: $inc  ($(date '+%T'))" >>"$LOG"
  before=$(find "$dest" -maxdepth 1 -newer "$LOG" 2>/dev/null | wc -l)
  if "$HF" download "$repo" --include "$inc" --local-dir "$dest" >>"$LOG" 2>&1; then
    echo "OK   [$label]" >>"$LOG"
  else
    echo "FAIL [$label] hf download 실패 (repo/quant/인증 확인)" >>"$LOG"
  fi
done
echo "" >>"$LOG"; echo "=== IMAGE fetch done $(date '+%F %T') ===" >>"$LOG"
echo "SUMMARY:"; grep -E '^(OK|FAIL)' "$LOG"
echo "diffusion_models 현재:"; ls -la "$DIFF"