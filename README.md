# strix-local-ai

**Ryzen AI 9 HX PRO 370 (Strix Point) 기반 완전 로컬 AI 스택 구축 프로젝트**

클라우드 없이 이 머신 한 대에서 LLM 추론 · 양자화 · 이미지/영상 생성까지 해결하는 것이 목표.
장기적으로는 GGUF 양자화 결과물을 Hugging Face에 공개하고 로컬 LLM 생태계에 기여한다.

## 하드웨어

| 항목 | 사양 |
|---|---|
| CPU | AMD Ryzen AI 9 HX PRO 370 (Zen 5, 12C/24T) |
| iGPU | Radeon 890M (RDNA 3.5, gfx1150) — RADV Vulkan |
| NPU | XDNA2 (`/dev/accel0`) |
| RAM | 32GB (GTT 26GB → iGPU가 시스템 RAM을 VRAM처럼 사용) |
| 디스크 | 1.9TB NVMe |

상세: [docs/hardware.md](docs/hardware.md)

## 디렉터리 구조

```
strix-local-ai/
├── docs/         # 하드웨어 조사, 로드맵, 모델 선정 노트
├── scripts/      # 셋업/실행 스크립트 (llama.cpp 빌드, 서버 기동 등)
├── quant/        # GGUF 양자화 파이프라인 (HF → GGUF → imatrix → 업로드)
├── benchmarks/   # 모델별 tok/s, 품질 측정 결과
└── models/       # 모델 저장소 심볼릭 링크 안내 (실제 파일은 ~/models, git 제외)
```

외부 소스 트리 (git 관리 밖):
- `~/llama.cpp` — 추론/양자화 엔진 (Vulkan + CPU 백엔드)
- `~/models` — GGUF 및 safetensors 저장소

## 빠른 시작

```bash
# 1. llama.cpp 빌드 (Vulkan 의존성 설치 후)
sudo apt install -y libvulkan-dev glslc libcurl4-openssl-dev
./scripts/setup-llamacpp.sh

# 2. 모델 다운로드
./scripts/download-model.sh

# 3. 로컬 서버 기동 (OpenAI 호환 API)
./scripts/serve.sh
```

## 로드맵

[docs/roadmap.md](docs/roadmap.md) 참고. 큰 줄기:

1. **Phase 1 — 추론 기반**: llama.cpp Vulkan 빌드, 4B~24B 모델 벤치마크, 상시 서버
2. **Phase 2 — 양자화 기여**: HF → GGUF 변환 파이프라인, imatrix 양자화, HF 업로드 자동화
3. **Phase 3 — 이미지/영상**: ComfyUI + SDXL/FLUX/WanVideo (Vulkan/ROCm 검토)
4. **Phase 4 — NPU**: XDNA2 오프로딩 실험 (ryzen-npu-linux 연계)
