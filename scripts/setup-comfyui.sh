#!/usr/bin/env bash
# ComfyUI + ROCm 안정 휠 설치 (Strix Point gfx1150, 2026-08-18 검증)
# 원칙: DKMS 절대 금지(커널 7.0에서 깨짐) — ROCm 런타임은 전부 pip 휠로 옴.
# 주의: AMD 휠은 cp310~cp313만 제공 — 시스템 python 3.14 불가, uv 관리 3.12 사용.
set -euo pipefail

VENV=~/venvs/comfy
COMFY=~/ComfyUI
PY=${COMFY_PYTHON:-$HOME/.local/bin/python3.12}

[[ -d $VENV ]] || { "$PY" -m venv "$VENV"; "$VENV/bin/pip" -q install -U pip; }

[[ -d $COMFY ]] || git clone --depth 1 https://github.com/comfyanonymous/ComfyUI "$COMFY"

# torch 3종 전부 +rocm 로컬버전 핀 — PyPI CUDA 빌드 혼입 차단.
# [device-gfx1150] 메타패키지가 rocm-sdk-device-gfx1150 런타임 휠을 끌어옴.
# 2.11 라인 고정 이유 (2026-08-18 실측): ComfyUI가 torchaudio를 하드 요구하는데
#   AMD 인덱스에 torchaudio 2.12가 없고 PyPI는 2.9.1이 끝(메인터넌스 모드).
#   torch 2.12 + torchaudio 2.11.x = undefined symbol (ABI 불일치).
#   torchaudio 2.11.0.2도 ABI 깨짐 — 정확히 2.11.0끼리만 짝이 맞음.
"$VENV/bin/pip" install \
  --index-url https://repo.amd.com/rocm/whl-multi-arch/ \
  --extra-index-url https://pypi.org/simple \
  'torch[device-gfx1150]==2.11.0+rocm7.14.0' \
  'torchvision==0.26.0+rocm7.14.0' \
  'torchaudio==2.11.0+rocm7.14.0'
"$VENV/bin/pip" install -r "$COMFY/requirements.txt"

# 실제 모델 파일은 ~/models/comfyui (repo 관행: 앱 디렉토리는 포인터만)
mkdir -p ~/models/comfyui/{checkpoints,loras,vae,controlnet,upscale_models,embeddings}
cat > "$COMFY/extra_model_paths.yaml" <<'EOF'
strix:
  base_path: /home/amd-ai/models/comfyui
  checkpoints: checkpoints
  loras: loras
  vae: vae
  controlnet: controlnet
  upscale_models: upscale_models
  embeddings: embeddings
EOF

"$VENV/bin/python" -c "import torch; assert torch.cuda.is_available(); print('[✓]', torch.__version__, torch.cuda.get_device_name(0))"

echo "실행 (llama-router 정지 후! — Vulkan MES 웨지 #5993, GPU 동시부하 금지):"
echo "  $VENV/bin/python $COMFY/main.py --enable-dynamic-vram --disable-mmap --cache-none --bf16-vae --reserve-vram 2"
echo "  # --force-shared-vram은 현 버전에 없음 (2026-08-18 확인)"
