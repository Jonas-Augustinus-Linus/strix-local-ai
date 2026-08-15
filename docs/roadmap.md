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

### 후보 모델 (2026-08-15 리서치에서 검증된 선정)

| 우선순위 | 모델 | 예상 성능 | 비고 |
|---|---|---|---|
| 1 | Gemma 4 26B-A4B QAT Q4_0 | ~25–30 t/s | MoE, 256k 컨텍스트 전체가 GTT에 들어감 |
| 2 | gpt-oss-20b MXFP4 | 23.4 t/s (890M 실측 보고) | |
| 한국어 품질 | EXAONE 4.0 32B Q4 | ~4–5 t/s | 품질 합격, 단 1.2-NC 라이선스 → 재배포 불가 |
| 검증용 | Qwen3-4B-Instruct Q4_K_M | 빠름 | 파이프라인 검증 · 상시 경량 서버 |

주의: Qwen3.6-35B-A3B는 HX 370에서 크래시 버그(#22425) 열려 있음 — 회피.
밀집(dense) 27B+는 3.8–6 t/s로 실사용 부적합, MoE 위주로 간다.

커뮤니티 파인튠(무검열 계열 포함)은 위 베이스의 파생판 중 한국어 성능이 유지되는
것을 벤치마크로 골라낸다. 선정 기준: ① 한국어 자연스러움 ② 창작 품질 ③ 지시 추종
④ 라이선스(재배포 가능 여부 — 양자화 업로드 전제).

## Phase 2 — 양자화 기여 파이프라인

- [ ] `quant/` 파이프라인: HF safetensors → `convert_hf_to_gguf.py` → F16 GGUF
- [ ] imatrix 데이터셋 준비 (한국어+영어 혼합 코퍼스 — 한국어 특화 imatrix가 차별점)
- [ ] `llama-imatrix` → `llama-quantize` (Q4_K_M, Q5_K_M, Q6_K, IQ4_XS 등 세트 생산)
- [ ] perplexity/KLD 품질 검증 자동화 (benchmarks/)
- [ ] HF Hub 업로드 자동화 (모델 카드 템플릿 포함, 라이선스 확인 단계 필수)
- [ ] **첫 릴리스 목표: kanana-1.5 (Apache 2.0) 한국어 보정 imatrix 양자화 + 한국어 KLD 수치**
  — 한국어 imatrix 보정 데이터셋은 현재 어디에도 없음(리서치로 확인된 공백) → 확실한 기여 지점

## Phase 3 — 이미지/영상 생성 (경로 확정됨, 2026-08-15 리서치)

- [ ] Python 환경 분리 후 **ROCm 안정 휠** 설치 (유일한 올바른 경로, DKMS 절대 금지 — 커널 7.0에서 깨짐):
  `pip install --index-url https://repo.amd.com/rocm/whl-multi-arch/ "torch[device-gfx1150]==2.12.0+rocm7.14.0"`
- [ ] ComfyUI 플래그: `--force-shared-vram --enable-dynamic-vram --disable-mmap --cache-none --bf16-vae`
- [ ] 이미지 모델: Illustrious XL v2 / NoobAI / Pony (~1–3분/장), Chroma1-HD FP8
- [ ] 영상: Wan 2.2 5B / HunyuanVideo 1.5 Q4 + 4-step LoRA (~15–45분/5초 480p), Wan A14B ~1–2시간
- [ ] LoRA 학습: SDXL LoRA 밤샘 학습, 7B QLoRA 로컬 가능 (Unsloth AMD 공식, `HSA_USE_SVM=0`)
- 주의: ROCm nightly 회피, Vulkan MES wedge(#5993) 미해결 → GPU 동시 부하 회피

## Phase 4 — XDNA2 NPU

- [ ] ryzen-npu-linux 작업과 연계
- [ ] XRT/amdxdna 스택에서 행렬곱 오프로딩 실험
- [ ] llama.cpp NPU 백엔드 동향 추적, 기여 지점 탐색

## 운영 원칙

- 모든 것은 완전 로컬. 외부 API 의존 없음.
- 모델 파일은 `~/models` (git 밖), 재현 스크립트와 결과만 레포에 기록.
- 벤치마크는 항상 같은 조건(같은 프롬프트 세트, 같은 컨텍스트 길이)으로 기록.
