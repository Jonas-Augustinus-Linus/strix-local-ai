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

## 공개 산출물

| 산출물 | 내용 |
|---|---|
| [kanana-1.5-8b KO-i1-GGUF](https://huggingface.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF) | 한국어 보정 imatrix 양자 9종 — 세계 최초 한국어 중심 보정 (저비트에서 영어 보정 대비 KLD -5~6%, 최대 3.3σ) |
| [Qwen3.6-35B-A3B KO-i1-GGUF](https://huggingface.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF) | 한국어 보정 8종 — MoE에서 4비트조차 유의한 이득 (-5.1~-6.8%, 최대 4.3σ) |
| [Huihui-Qwen3.8-27B-abliterated KO-i1-GGUF](https://huggingface.co/augustine223/Huihui-Qwen3.8-27B-abliterated-KO-i1-GGUF) | **무검열 + 한국어 보정** — 이 조합의 첫 공개 릴리스 (정적 배포판 대비 KLD -23.7%, 9.1σ) |
| [Huihui-Qwen3.6-35B-A3B-abliterated KO-i1-GGUF](https://huggingface.co/augustine223/Huihui-Qwen3.6-35B-A3B-abliterated-KO-i1-GGUF) | 무검열 MoE 8종 — 정식판과 같은 코퍼스로 검증: **abliteration은 quant 품질 무영향**(±1σ) |
| [korean-imatrix-calibration-corpus](https://huggingface.co/datasets/augustine223/korean-imatrix-calibration-corpus) | 한국어 imatrix 보정 코퍼스 데이터셋 — 세그먼트 원문 + 302개 출처 + 빌드 스크립트 + 평가셋 (누구나 한국어 보정 quant 제작 가능) |
| [ryzen-npu-linux](https://github.com/Jonas-Augustinus-Linus/ryzen-npu-linux) | XDNA1/XDNA2 NPU 리눅스 활용 — W4A16 GEMM 5.94 TOPS (오픈 스택) |

방법론과 실측 수치는 [benchmarks/](benchmarks/), 함정 모음은 [docs/gotchas.md](docs/gotchas.md) 참조.

## 디렉터리 구조

```
strix-local-ai/
├── docs/         # 사용자 가이드 · 하드웨어 · 로드맵
├── server/       # systemd 유닛 · 이미지 서버 · 워크플로
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

## 현재 되는 것

이 머신에서 지금 실제로 가동 중인 기능:

- **로컬 LLM 채팅** — llama-router 다중 모델 상시 서버 (OpenAI 호환 API)
- **GGUF 양자화 파이프라인** — HF → GGUF → imatrix → 업로드, 한국어 보정 코퍼스 공개
- **로컬 이미지 생성** — SDXL 5종 (Animagine · Illustrious · NoobAI · Pony · RealVis) + Chroma, ComfyUI 백엔드 + 초간단 웹 페이지
- **ControlNet** — 자세(OpenPose) · 구도(Canny Union) 참조 이미지 기반 제어
- **LoRA 훈련** — sd-scripts 기반 학습 스크립트

한국어 실행 가이드:

- [docs/run-guide-ko.md](docs/run-guide-ko.md) — 공개 릴리스 실행법
- [docs/uncensored-guide-ko.md](docs/uncensored-guide-ko.md) — 무검열 방침
- [docs/comfyui-guide-ko.md](docs/comfyui-guide-ko.md) — 이미지 생성 (ComfyUI)
- [docs/lora-training-ko.md](docs/lora-training-ko.md) — LoRA 훈련

## 로드맵

[docs/roadmap.md](docs/roadmap.md) 참고. 큰 줄기:

1. **Phase 1 — 추론 기반** ✅: llama.cpp Vulkan 빌드, 4B~24B 모델 벤치마크, 상시 서버
2. **Phase 2 — 양자화 기여** ✅: HF → GGUF 변환 파이프라인, imatrix 양자화, HF 업로드 자동화
3. **Phase 3 — 이미지/영상** ✅: ComfyUI + SDXL 5종 · Chroma, ControlNet(자세/구도), LoRA 훈련 가동 중 (영상은 진행 중)
4. **Phase 4 — NPU**: XDNA2 오프로딩 실험 (ryzen-npu-linux 연계)
