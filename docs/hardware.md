# 하드웨어 조사 (2026-08-15)

## 개요

| 구성요소 | 내용 | 비고 |
|---|---|---|
| CPU | Ryzen AI 9 HX PRO 370, Zen 5 12C/24T | AVX-512 지원 → CPU 추론도 준수 |
| iGPU | Radeon 890M (RDNA 3.5, `gfx1150`) | RADV(Mesa) Vulkan 정상 동작 확인 |
| NPU | XDNA2, `/dev/accel0` 인식됨 | amdxdna 드라이버 로드됨 |
| RAM | 32GB (가용 ~29GB) | |
| GTT | **26.0GB** (`mem_info_gtt_total` = 27,917,287,424) | iGPU가 쓸 수 있는 통합 메모리 상한 |
| 디스크 | 1.9TB NVMe, 사용 67GB | 모델 저장 여유 충분 |
| 스왑 | 31GB | |

## 소프트웨어 상태

- OS: Ubuntu (커널 7.0.0-29-generic)
- Vulkan: RADV `AMD Radeon 890M Graphics (RADV STRIX1)` — **작동 확인**
- ROCm: **미설치**. gfx1150은 ROCm 공식 지원이 불완전 → 당분간 Vulkan 백엔드 사용
- Python 3.14.4 (시스템) — PyTorch 등 일부 ML 패키지는 3.12 별도 환경 필요할 수 있음
- 빌드 도구: gcc, cmake, ninja 준비됨
- gh CLI 인증 완료

## 추론 전략

1. **llama.cpp + Vulkan (RADV)**: 890M에서 가장 검증된 경로. GTT 26GB 덕분에
   Q4_K_M 기준 ~24B급 모델까지 iGPU에 전부 올릴 수 있음 (컨텍스트 포함 시 ~14B가 쾌적).
2. **CPU 폴백**: Zen 5 AVX-512로 소형 모델(≤8B)은 CPU만으로도 실용적.
3. **NPU (장기)**: XDNA2는 아직 LLM 추론 스택이 미성숙. prefill 오프로딩 등
   실험 대상 (Phase 4, ryzen-npu-linux 연계).

## 메모리 예산 (GTT 26GB 기준)

| 모델 크기 | Q4_K_M 무게 | 컨텍스트 여유 | 판정 |
|---|---|---|---|
| 4B | ~2.5GB | 매우 넉넉 | 상시 구동용 |
| 8B | ~5GB | 넉넉 | 일상 주력 |
| 12~14B | ~8~9GB | 충분 | 품질 주력 |
| 24B | ~14GB | 보통 | 고품질 작업용 |
| 32B | ~19GB | 빠듯 | 짧은 컨텍스트 한정 |
| 70B | ~40GB | 불가 | Q2 초저정밀도도 위험 |
