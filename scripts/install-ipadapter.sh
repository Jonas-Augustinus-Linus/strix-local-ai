#!/usr/bin/env bash
# IP-Adapter (SDXL) 설치: cubiq 노드 + 모델 2개. 로그: install-ipadapter.log
HF=/home/amd-ai/venvs/comfy/bin/hf
CN=/home/amd-ai/ComfyUI/custom_nodes
IPA=/home/amd-ai/models/comfyui/ipadapter
CV=/home/amd-ai/models/comfyui/clip_vision
DL=/home/amd-ai/models/comfyui/.ipa-dl
LOG=/home/amd-ai/strix-local-ai/scripts/install-ipadapter.log
: > "$LOG"; mkdir -p "$IPA" "$CV" "$DL"
echo "=== IP-Adapter 설치 $(date '+%T') ===" >>"$LOG"
# 0) extra_model_paths.yaml에 clip_vision·ipadapter 매핑 추가 (없으면 ComfyUI가 폴더를 못 봄!)
YAML=/home/amd-ai/ComfyUI/extra_model_paths.yaml
if [ -f "$YAML" ]; then
  grep -q "clip_vision:" "$YAML" || sed -i '/embeddings: embeddings/a\  clip_vision: clip_vision' "$YAML"
  grep -q "ipadapter:"   "$YAML" || sed -i '/clip_vision: clip_vision/a\  ipadapter: ipadapter' "$YAML"
  echo "OK yaml(clip_vision+ipadapter 매핑)" >>"$LOG"
fi
# 1) 노드
if [ ! -d "$CN/ComfyUI_IPAdapter_plus" ]; then
  git -C "$CN" clone --depth 1 https://github.com/cubiq/ComfyUI_IPAdapter_plus.git >>"$LOG" 2>&1 && echo "OK node" >>"$LOG" || echo "FAIL node" >>"$LOG"
else echo "OK node(기존)" >>"$LOG"; fi
# 2) IP-Adapter Plus SDXL 모델
"$HF" download h94/IP-Adapter sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors --local-dir "$DL" >>"$LOG" 2>&1
cp -n "$DL"/sdxl_models/ip-adapter-plus_sdxl_vit-h.safetensors "$IPA/" 2>>"$LOG" && echo "OK ipadapter model" >>"$LOG" || echo "FAIL ipadapter model" >>"$LOG"
# 3) CLIP vision (ViT-H image encoder) → 유니파이드 로더가 기대하는 이름으로
"$HF" download h94/IP-Adapter models/image_encoder/model.safetensors --local-dir "$DL" >>"$LOG" 2>&1
cp -n "$DL"/models/image_encoder/model.safetensors "$CV/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" 2>>"$LOG" && echo "OK clip_vision" >>"$LOG" || echo "FAIL clip_vision" >>"$LOG"
rm -rf "$DL"
echo "=== done $(date '+%T') ===" >>"$LOG"
echo "SUMMARY:"; grep -E '^(OK|FAIL)' "$LOG"
ls -la "$IPA/ip-adapter-plus_sdxl_vit-h.safetensors" "$CV/CLIP-ViT-H-14-laion2B-s32B-b79K.safetensors" 2>/dev/null | awk '{print "  ",$5, $NF}'
