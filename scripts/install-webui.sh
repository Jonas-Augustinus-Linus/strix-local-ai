#!/usr/bin/env bash
# Open WebUI 설치 (Docker, --network=host — llama-server가 127.0.0.1 바인딩이라 필수)
# 최초 접속(http://localhost:3000)에서 만드는 첫 계정이 관리자가 됨.
set -euo pipefail

KEY=$(cat ~/.config/llama-api-key)

# 세션 암호화 키 (컨테이너 재생성에도 로그인 유지)
if [[ ! -f ~/.config/open-webui-secret ]]; then
  python3 -c "import secrets; print(secrets.token_hex(32))" > ~/.config/open-webui-secret
  chmod 600 ~/.config/open-webui-secret
fi
SECRET=$(cat ~/.config/open-webui-secret)

docker rm -f open-webui 2>/dev/null || true
docker run -d --name open-webui --restart always \
  --network=host \
  -e PORT=3000 \
  -v open-webui:/app/backend/data \
  -e OPENAI_API_BASE_URL=http://127.0.0.1:8080/v1 \
  -e OPENAI_API_KEY="$KEY" \
  -e ENABLE_OLLAMA_API=false \
  -e ENABLE_SIGNUP=false \
  -e WEBUI_SECRET_KEY="$SECRET" \
  -e SCARF_NO_ANALYTICS=true \
  -e DO_NOT_TRACK=true \
  -e ANONYMIZED_TELEMETRY=false \
  -e ENABLE_VERSION_UPDATE_CHECK=false \
  -e AIOHTTP_CLIENT_TIMEOUT=300 \
  -e AIOHTTP_CLIENT_TIMEOUT_MODEL_LIST=60 \
  ghcr.io/open-webui/open-webui:main

echo "[✓] Open WebUI: http://localhost:3000 (첫 계정 = 관리자)"
echo "[i] 관리자 설정 → 연결에서 Provider를 'llama.cpp'로 바꾸면 로드 표시/Eject 버튼 활성화"
