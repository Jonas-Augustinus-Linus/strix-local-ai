#!/usr/bin/env bash
# 보정 코퍼스 데이터셋 업로드. 사용법: ./upload.sh <hf-username>
set -euo pipefail

USER_="${1:?사용법: ./upload.sh <hf-username>}"
REPO="$USER_/korean-imatrix-calibration-corpus"
HF=~/venvs/convert/bin/hf
CORPUS=~/strix-local-ai/quant/corpus
EVAL=~/strix-local-ai/quant/eval
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "=== 데이터셋 레포 생성: $REPO ==="
$HF repo create "$REPO" --repo-type dataset 2>&1 | tail -1 || true

$HF upload --repo-type dataset "$REPO" "$HERE/README.md" README.md
for f in calibration.txt seg1-wiki-ko.txt seg2-literature-ko.txt seg3-conversation-ko.txt \
         seg4-code.txt seg4-english.txt seg1-sources.md seg2-sources.md seg3-sources.md seg4-sources.md; do
  $HF upload --repo-type dataset "$REPO" "$CORPUS/$f" "$f"
done
$HF upload --repo-type dataset "$REPO" ~/strix-local-ai/quant/build_calibration.py build_calibration.py
$HF upload --repo-type dataset "$REPO" "$EVAL/eval-ko.txt" eval/eval-ko.txt
$HF upload --repo-type dataset "$REPO" "$EVAL/eval-sources.md" eval/eval-sources.md

echo "[✓] https://huggingface.co/datasets/$REPO"
