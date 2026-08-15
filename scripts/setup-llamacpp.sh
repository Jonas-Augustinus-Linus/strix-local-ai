#!/usr/bin/env bash
# llama.cpp 클론 + 빌드. Vulkan 의존성이 있으면 Vulkan 백엔드, 없으면 CPU 전용.
#   사전 준비(권장): sudo apt install -y libvulkan-dev glslc libcurl4-openssl-dev
set -euo pipefail

LLAMA_DIR="${LLAMA_DIR:-$HOME/llama.cpp}"
JOBS="$(nproc)"

if [[ ! -d "$LLAMA_DIR" ]]; then
  git clone https://github.com/ggml-org/llama.cpp "$LLAMA_DIR"
fi
cd "$LLAMA_DIR"
git pull --ff-only || true

CMAKE_ARGS=(-DCMAKE_BUILD_TYPE=Release -DGGML_NATIVE=ON)

# libcurl 개발 헤더 없으면 내장 다운로더 비활성화
if ! pkg-config --exists libcurl 2>/dev/null; then
  CMAKE_ARGS+=(-DLLAMA_CURL=OFF)
  echo "[i] libcurl4-openssl-dev 없음 → -DLLAMA_CURL=OFF"
fi

# Vulkan 의존성 확인 (헤더 + glslc)
if [[ -f /usr/include/vulkan/vulkan.h ]] && command -v glslc >/dev/null; then
  CMAKE_ARGS+=(-DGGML_VULKAN=ON)
  BUILD_DIR=build-vulkan
  echo "[i] Vulkan 백엔드로 빌드"
else
  BUILD_DIR=build-cpu
  echo "[!] Vulkan 의존성 없음 → CPU 전용 빌드"
  echo "    Vulkan 빌드하려면: sudo apt install -y libvulkan-dev glslc && 이 스크립트 재실행"
fi

cmake -B "$BUILD_DIR" -G Ninja "${CMAKE_ARGS[@]}"
cmake --build "$BUILD_DIR" -j "$JOBS"

# 최신 빌드를 가리키는 심볼릭 링크
ln -sfn "$BUILD_DIR" build-current
echo
echo "[✓] 빌드 완료: $LLAMA_DIR/$BUILD_DIR/bin"
"$LLAMA_DIR/$BUILD_DIR/bin/llama-cli" --version 2>&1 | head -3 || true
