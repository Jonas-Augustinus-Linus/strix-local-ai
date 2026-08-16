#!/usr/bin/env bash
# llama-router systemd user 서비스 설치/갱신
set -euo pipefail

REPO="$(cd "$(dirname "$0")/.." && pwd)"

# API 키 없으면 생성
if [[ ! -f ~/.config/llama-api-key ]]; then
  mkdir -p ~/.config
  python3 -c "import secrets; print('sk-local-'+secrets.token_hex(24))" > ~/.config/llama-api-key
  chmod 600 ~/.config/llama-api-key
  echo "[i] API 키 생성: ~/.config/llama-api-key"
fi

mkdir -p ~/.config/systemd/user
ln -sfn "$REPO/server/llama-router.service" ~/.config/systemd/user/llama-router.service
systemctl --user daemon-reload
systemctl --user enable --now llama-router.service
sleep 3
systemctl --user status llama-router.service --no-pager | head -8
