# Gemma 4 26B-A4B QAT Q4_0 — Vulkan(890M) + FA A/B

- 날짜: 2026-08-15
- llama.cpp: build 10450 (`ece963f41`), Vulkan(RADV), `-ngl 99`
- 모델: google/gemma-4-26B-A4B-it-qat-q4_0-gguf (13.43 GiB, MoE 25.2B 총 / ~4B 활성, QAT)

## llama-bench — Flash Attention A/B

| fa | pp512 (t/s) | tg128 (t/s) |
|---|---|---|
| off | 437.11 ± 3.29 | 31.59 ± 0.21 |
| **on** | **466.09 ± 1.11 (+6.6%)** | **32.15 ± 0.05 (+1.8%)** |

→ FA on 확정. 리서치 예측(25~30 t/s)을 상회.

## 실사용 (llama-completion -cnv -st --jinja, -c 8192, 한국어 칼럼 작성)

- prefill 171.1 t/s / decode **31.6 t/s**
- **리즈닝 모델**: 영어로 사고 과정을 전개한 뒤 최종 한국어 답변 생성.
  사고 중 한국어 초안 품질이 칼럼니스트급으로 자연스러움 → 칼럼 작성 주력으로 적합
- 사고 토큰만큼 실효 응답 지연 증가 — `-n`을 넉넉히 주거나 사고 제어 옵션 탐색 필요 (TODO)
- 비전 입력은 mmproj(gemma-4-26B-it-mmproj.gguf) + `llama-mtmd-cli`로 별도 검증 예정

## 오늘의 3모델 종합 (Vulkan -ngl 99 -fa 1)

| 모델 | 무게 | pp512 | tg128 |
|---|---|---|---|
| Qwen3-4B Q4_K_M (밀집) | 2.3 GiB | 609.4 | 34.1 |
| gpt-oss-20b MXFP4 (MoE) | 11.3 GiB | 608.6 | 32.7 |
| Gemma 4 26B-A4B Q4_0 (MoE) | 13.4 GiB | 466.1 | 32.2 |

결론: GTT 26GB + MoE 조합으로 **26B급까지 속도 손실 거의 없이** 굴릴 수 있음이 실증됨.
이 머신의 일상 주력 = Gemma 4 26B-A4B (품질/속도/컨텍스트), 보조 = gpt-oss-20b (추론),
경량 상시 = Qwen3-4B.
