#!/usr/bin/env bash
# Qwen3.8-27B-abl KO-i1 릴리스 업로드 (3차). 사전조건: hf auth login.
# 사용법: ./upload.sh <hf-username>   (GGUF 8종 총 ~131GB)
set -euo pipefail

USER_="${1:?사용법: ./upload.sh <hf-username>}"
REPO="$USER_/Huihui-Qwen3.8-27B-abliterated-KO-i1-GGUF"
HF=~/venvs/convert/bin/hf
WORK=~/models/work/qwen38-quant
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "=== 레포 생성: $REPO ==="
$HF repo create "$REPO" --repo-type model 2>&1 | tail -1 || true

echo "=== 소형 파일 먼저 ==="
$HF upload "$REPO" "$HERE/README.md" README.md
$HF upload "$REPO" "$WORK/Huihui-Qwen3.8-27B-abliterated.imatrix.gguf" Huihui-Qwen3.8-27B-abliterated.imatrix.gguf
cat ~/strix-local-ai/quant/corpus/seg*-sources.md > /tmp/calibration-sources.md
$HF upload "$REPO" /tmp/calibration-sources.md calibration-sources.md

echo "=== GGUF 8종 (작은 것부터) ==="
for f in $(ls -S -r "$WORK"/*.KO-i1-*.gguf); do
  echo "--- $(basename "$f") ($(du -h "$f" | cut -f1)) ---"
  $HF upload "$REPO" "$f" "$(basename "$f")"
done

echo "[✓] 업로드 완료: https://huggingface.co/$REPO"
