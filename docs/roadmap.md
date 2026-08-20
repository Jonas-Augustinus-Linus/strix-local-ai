# 로드맵

## Phase 1 — 추론 기반 구축 (진행 중)

- [x] 하드웨어/소프트웨어 조사 (docs/hardware.md)
- [x] llama.cpp 클론 + CPU 빌드 (즉시 사용 가능한 폴백)
- [x] Vulkan 의존성 설치 후 Vulkan 빌드 (890M 인식, coopmat 활성 — pp512 3.3배)
- [x] 테스트 모델(Qwen3-4B)로 추론 검증
- [x] 후보 모델군 1차 벤치마크 — Qwen3-4B / gpt-oss-20b / Gemma 4 26B-A4B 전부 32 t/s대 확인,
  FA on 확정. 주력: Gemma 4 26B-A4B. (EXAONE 4.0 32B 한국어 품질 비교는 추후)
- [x] `llama-server` 상시 기동 (systemd user unit, OpenAI 호환 API)
- [x] Open WebUI 또는 경량 프론트엔드 연결

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

## 릴리스 전략 (2026-08-16 확정)

원칙: **"이 머신에서 최고"를 기준으로 잡는다** — 절대 성능 1위(수백 GB급)는 어떤 소비자
하드웨어에도 안 들어가므로, GTT 26GB 안에서 최고인 모델에 커스텀을 집중한다.

1. **1차 릴리스 — kanana-1.5-8b (방법론 입증)**: 한국어 보정 imatrix가 영어 보정 대비
   실제로 낫다는 것을 KLD 수치로 입증하는 깨끗한 첫 타자 (Apache 2.0, 한국어 특화).
2. **2차 릴리스 — Qwen3.6-35B-A3B (임팩트 릴리스)**: 소비자 하드웨어에서 돌아가는
   현세대 최고 MoE(SWE-bench 73.4, Apache 2.0)의 세계 최초 한국어 보정 양자화.
   기술 난관: F16 70GB > 메모리 → **MoE 희소성 활용 mmap 스트리밍 + Q8 기반 imatrix**
   (토큰당 ~3B만 활성화되므로 페이지 캐시가 감당, 공인된 우회법)로 해결.
3. **3차 — LoRA 커스텀 (Phase 4와 연결)**: 양자화 다음의 진짜 커스텀. 사용자 문체/도메인
   주입. Unsloth AMD 공식 지원 확인됨, 7~8B급 로컬 밤샘 학습 가능.

## Phase 2 — 양자화 기여 파이프라인

- [x] `quant/` 파이프라인: HF safetensors → `convert_hf_to_gguf.py` → F16 GGUF
- [x] imatrix 데이터셋 준비 (한국어+영어 혼합 코퍼스 — 한국어 특화 imatrix가 차별점)
- [x] `llama-imatrix` → `llama-quantize` (Q4_K_M, Q5_K_M, Q6_K, IQ4_XS 등 세트 생산)
- [x] perplexity/KLD 품질 검증 자동화 (benchmarks/)
- [x] HF Hub 업로드 자동화 (모델 카드 템플릿 포함, 라이선스 확인 단계 필수)
- [x] **첫 릴리스 목표: kanana-1.5 (Apache 2.0) 한국어 보정 imatrix 양자화 + 한국어 KLD 수치**
  — **완료: https://huggingface.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF**

## Phase 3 — 이미지/영상 생성 (경로 확정됨, 2026-08-15 리서치)

- [x] Python 환경 분리 후 **ROCm 안정 휠** 설치 (유일한 올바른 경로, DKMS 절대 금지 — 커널 7.0에서 깨짐):
  `pip install --index-url https://repo.amd.com/rocm/whl-multi-arch/ "torch[device-gfx1150]==2.12.0+rocm7.14.0"`
- [x] ComfyUI 플래그: `--enable-dynamic-vram --disable-mmap --cache-none --bf16-vae --reserve-vram 2`
- [x] 이미지 모델: Illustrious XL v2 / NoobAI / Pony (~1–3분/장), Chroma1-HD FP8
- [x] **영상: Wan 2.2 TI2V-5B fp16 가동 확인 (2026-08-20)** — 890M ROCm에서 480²·2초·20스텝 = **258초**, GTT 피크 21.3G(안전). T2V/I2V 둘 다 동작(`Wan22ImageToVideoLatent` start_image). `simple-video.html` 초간단 페이지 제공. 해상도·길이 상승 시 급격히 느려짐(720p/5초는 수십 분)
  - 品질 천장(A14B GGUF Q5 + lightx2v)은 **보류**(2026-08-20 결정): 확산 영상은 단일 생성 ≤5초, 분 단위는 5초 조각 I2V 이어붙이기 → 890M에선 ROI 낮음. 5B 스택은 그대로 유지(가끔 짧은 클립용), 영상은 **더 좋은 dGPU 기기 확보 시** 재개
- **기기 포지셔닝(2026-08-20): 이 머신의 주력은 로컬 LLM + 이미지 생성(+GGUF 양자화 공개). 영상은 되지만 비주력.**
- [x] LoRA 학습: SDXL LoRA 밤샘 학습, 7B QLoRA 로컬 가능 (Unsloth AMD 공식, `HSA_USE_SVM=0`)
- 주의: ROCm nightly 회피, Vulkan MES wedge(#5993) 미해결 → GPU 동시 부하 회피

## Phase 4 — XDNA2 NPU

- [ ] ryzen-npu-linux 작업과 연계
- [ ] XRT/amdxdna 스택에서 행렬곱 오프로딩 실험
- [ ] llama.cpp NPU 백엔드 동향 추적, 기여 지점 탐색

## 운영 원칙

- 모든 것은 완전 로컬. 외부 API 의존 없음.
- 모델 파일은 `~/models` (git 밖), 재현 스크립트와 결과만 레포에 기록.
- 벤치마크는 항상 같은 조건(같은 프롬프트 세트, 같은 컨텍스트 길이)으로 기록.
