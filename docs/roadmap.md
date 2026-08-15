# 로드맵

## Phase 1 — 추론 기반 구축 (진행 중)

- [x] 하드웨어/소프트웨어 조사 (docs/hardware.md)
- [x] llama.cpp 클론 + CPU 빌드 (즉시 사용 가능한 폴백)
- [ ] Vulkan 의존성 설치 (`libvulkan-dev`, `glslc`) 후 Vulkan 빌드
- [x] 테스트 모델(Qwen3-4B)로 추론 검증
- [ ] 후보 모델군 벤치마크 (benchmarks/에 tok/s 기록)
  - 4B / 8B / 12B / 24B 급에서 한국어 능력 위주 비교
- [ ] `llama-server` 상시 기동 (systemd user unit, OpenAI 호환 API)
- [ ] Open WebUI 또는 경량 프론트엔드 연결

### 후보 모델 (시중 공개 모델 위주로 시작)

| 급 | 후보 | 비고 |
|---|---|---|
| 4B | Qwen3-4B-Instruct | 상시 구동, 빠른 응답 |
| 8B | Qwen3-8B, Llama-3.1-8B 계열 | 일상 주력 |
| 12B | Mistral-Nemo-12B 계열, Gemma-3-12B | 한국어/창작 균형 |
| 24B | Mistral-Small-3.x-24B 계열 | 품질 주력 (GTT 한계 내 최대 실용선) |

커뮤니티 파인튠(무검열 계열 포함)은 위 베이스 모델의 파생판 중 한국어 성능이
유지되는 것을 벤치마크로 골라낸다. 선정 기준: ① 한국어 자연스러움 ② 창작(소설/시나리오)
품질 ③ 지시 추종 ④ 라이선스(재배포 가능 여부 — 양자화 업로드 전제).

## Phase 2 — 양자화 기여 파이프라인

- [ ] `quant/` 파이프라인: HF safetensors → `convert_hf_to_gguf.py` → F16 GGUF
- [ ] imatrix 데이터셋 준비 (한국어+영어 혼합 코퍼스 — 한국어 특화 imatrix가 차별점)
- [ ] `llama-imatrix` → `llama-quantize` (Q4_K_M, Q5_K_M, Q6_K, IQ4_XS 등 세트 생산)
- [ ] perplexity/KLD 품질 검증 자동화 (benchmarks/)
- [ ] HF Hub 업로드 자동화 (모델 카드 템플릿 포함, 라이선스 확인 단계 필수)
- [ ] 목표: 한국어 imatrix 양자화 GGUF 시리즈를 HF에 공개

## Phase 3 — 이미지/영상 생성

- [ ] Python 3.12 별도 환경 (uv) — PyTorch 호환성 확보
- [ ] ROCm gfx1150 지원 현황 재조사 vs PyTorch Vulkan/therock 빌드 검토
- [ ] ComfyUI 설치, SDXL → FLUX.1-dev(GGUF 양자화판) 순서로 검증
- [ ] 영상: Wan2.x / LTX-Video 등 GGUF 양자화판을 GTT 26GB 안에서 실험
- [ ] LoRA 학습: SDXL LoRA부터 (iGPU 학습 가능성 검증, 안 되면 kohya CPU/클라우드 분리)

## Phase 4 — XDNA2 NPU

- [ ] ryzen-npu-linux 작업과 연계
- [ ] XRT/amdxdna 스택에서 행렬곱 오프로딩 실험
- [ ] llama.cpp NPU 백엔드 동향 추적, 기여 지점 탐색

## 운영 원칙

- 모든 것은 완전 로컬. 외부 API 의존 없음.
- 모델 파일은 `~/models` (git 밖), 재현 스크립트와 결과만 레포에 기록.
- 벤치마크는 항상 같은 조건(같은 프롬프트 세트, 같은 컨텍스트 길이)으로 기록.
