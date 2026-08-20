#!/usr/bin/env bash
# SDXL LoRA 훈련 (kohya sd-scripts, ROCm/890M). 데이터 준비 → 이 스크립트 실행.
# 사용: lora-train.sh <이름> [스텝수]
#   예: lora-train.sh mychar 1500
# 사전: ~/lora-data/<이름>/img/ 에 학습 이미지(+선택 .txt 캡션) 넣기
set -euo pipefail

# --init <이름>: 데이터셋 폴더만 생성하고 안내
if [ "${1:-}" = "--init" ]; then
  NM="${2:?사용법: lora-train.sh --init <이름>}"
  mkdir -p "$HOME/lora-data/$NM/img"
  echo "[✓] 폴더 생성: ~/lora-data/$NM/img/"
  echo "    여기에 학습할 이미지 10~30장을 넣으세요 (같은 캐릭터/화풍)."
  echo "    (선택) 각 이미지 옆에 같은 이름의 .txt 캡션을 두면 품질↑"
  echo "    준비되면: lora-train.sh $NM"
  exit 0
fi

NAME="${1:?사용법: lora-train.sh <이름> [스텝수]  또는  --init <이름>}"
STEPS="${2:-1500}"
PY=$HOME/venvs/lora/bin
SDS=$HOME/sd-scripts
BASE=$HOME/models/comfyui/checkpoints/Illustrious-XL-v2.0.safetensors  # 베이스 모델
DATA=$HOME/lora-data/$NAME
IMGDIR=$DATA/img
OUT=$HOME/models/comfyui/loras
LOG=$DATA/train.log

# 데이터셋 폴더 규칙: sd-scripts는 "<반복수>_<개념>" 하위폴더를 요구
# 여기선 img/ 안의 이미지를 10회 반복으로 자동 구성
[ -d "$IMGDIR" ] || { echo "먼저 $IMGDIR 에 학습 이미지를 넣으세요 (lora-train.sh --init $NAME 로 폴더 생성)"; exit 1; }
N=$(find "$IMGDIR" -maxdepth 1 -type f \( -iname '*.png' -o -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.webp' \) | wc -l)
[ "$N" -ge 5 ] || { echo "학습 이미지가 $N장뿐 — 최소 10~15장 권장"; }
echo "학습 이미지 $N장, 목표 $STEPS 스텝"

# sd-scripts 폴더 구조 준비 (10_개념 형식)
REPEAT_DIR="$DATA/train/10_$NAME"
mkdir -p "$REPEAT_DIR" "$OUT"
cp -n "$IMGDIR"/* "$REPEAT_DIR"/ 2>/dev/null || true

# accelerate 무설정 실행 (단일 GPU)
cd "$SDS"
PYTORCH_HIP_ALLOC_CONF=expandable_segments:True \
"$PY/accelerate" launch --num_cpu_threads_per_process 8 sdxl_train_network.py \
  --pretrained_model_name_or_path="$BASE" \
  --train_data_dir="$DATA/train" \
  --output_dir="$OUT" --output_name="$NAME" \
  --resolution="1024,1024" --network_module=networks.lora \
  --network_dim=16 --network_alpha=8 \
  --train_batch_size=1 --max_train_steps="$STEPS" \
  --learning_rate=1e-4 --optimizer_type=AdamW \
  --mixed_precision=fp16 --save_precision=fp16 \
  --cache_latents --gradient_checkpointing \
  --save_model_as=safetensors --save_every_n_steps=500 \
  --seed=42 --no_half_vae 2>&1 | tee "$LOG"

echo "[✓] 완료: $OUT/$NAME.safetensors"
echo "    ComfyUI에서 LoraLoader로 불러 쓰거나, 프롬프트에 트리거 단어 사용"
