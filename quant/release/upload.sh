#!/usr/bin/env bash
# kanana KO-i1 릴리스 업로드. 사전조건: hf auth login 완료.
# 사용법: ./upload.sh <hf-username>
set -euo pipefail

USER_="${1:?사용법: ./upload.sh <hf-username>}"
REPO="$USER_/kanana-1.5-8b-instruct-2505-KO-i1-GGUF"
HF=~/venvs/convert/bin/hf
WORK=~/models/work/kanana-quant
HERE="$(cd "$(dirname "$0")" && pwd)"

echo "=== 레포 생성: $REPO ==="
$HF repo create "$REPO" --repo-type model 2>&1 | tail -1 || true

echo "=== 소형 파일 먼저 (README, imatrix, 출처 문서) ==="
$HF upload "$REPO" "$HERE/README.md" README.md
$HF upload "$REPO" "$WORK/kanana-1.5-8b-instruct-2505.imatrix.gguf" kanana-1.5-8b-instruct-2505.imatrix.gguf
# 보정 코퍼스 출처 통합 문서
cat ~/strix-local-ai/quant/corpus/seg*-sources.md > /tmp/calibration-sources.md
$HF upload "$REPO" /tmp/calibration-sources.md calibration-sources.md

echo "=== GGUF 9종 (작은 것부터, 이어받기는 hf가 처리) ==="
for f in $(ls -S -r "$WORK"/*.KO-i1-*.gguf); do
  echo "--- $(basename "$f") ($(du -h "$f" | cut -f1)) ---"
  $HF upload "$REPO" "$f" "$(basename "$f")"
done

echo "[✓] 업로드 완료: https://huggingface.co/$REPO"
