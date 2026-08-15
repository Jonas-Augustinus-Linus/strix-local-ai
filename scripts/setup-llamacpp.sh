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

  # SPIRV-Headers CMake 패키지 필요 (build 10449+). 시스템에 없으면 ~/.local에 사용자 설치
  if [[ ! -f /usr/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake ]] \
     && [[ ! -f "$HOME/.local/share/cmake/SPIRV-Headers/SPIRV-HeadersConfig.cmake" ]]; then
    echo "[i] SPIRV-Headers 없음 → ~/.local에 설치"
    [[ -d ~/src/SPIRV-Headers ]] || git clone --depth 1 https://github.com/KhronosGroup/SPIRV-Headers ~/src/SPIRV-Headers
    cmake -S ~/src/SPIRV-Headers -B ~/src/SPIRV-Headers/build -DCMAKE_INSTALL_PREFIX="$HOME/.local"
    cmake --install ~/src/SPIRV-Headers/build
  fi
  CMAKE_ARGS+=(-DCMAKE_PREFIX_PATH="$HOME/.local")
  # llama.cpp가 SPIRV-Headers를 find만 하고 include 경로를 타깃에 안 붙임 → 직접 주입
  if [[ -f "$HOME/.local/include/spirv/unified1/spirv.hpp" ]]; then
    CMAKE_ARGS+=(-DCMAKE_CXX_FLAGS="-isystem $HOME/.local/include")
  fi
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
