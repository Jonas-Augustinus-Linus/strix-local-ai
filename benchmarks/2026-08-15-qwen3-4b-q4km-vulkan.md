# Qwen3-4B-Instruct-2507 Q4_K_M — Vulkan(890M) vs CPU

- 날짜: 2026-08-15
- llama.cpp: build 10450, commit `ece963f41`, Vulkan(RADV) 빌드
- 디바이스: AMD Radeon 890M (RADV STRIX1), uma:1, fp16:1, **KHR_coopmat 활성**, GTT 26.7GB 가용
- `-ngl 99` (전체 레이어 오프로드), 전원: AC

## llama-bench

| backend | pp512 (t/s) | tg128 (t/s) |
|---|---|---|
| **Vulkan -ngl 99** | **609.43 ± 1.46** | **34.08 ± 0.08** |
| CPU ×12 (전일 측정) | 184.79 | 27.26 |
| 배율 | ×3.30 | ×1.25 |

## 실사용 (llama-completion, -c 4096, 한국어)

- prefill 244.9 t/s, decode **34.4 t/s**, 한국어 출력 품질 정상

## 해석

- prefill은 연산 바운드 → iGPU(coopmat)가 3.3배.
- decode는 LPDDR5X 대역폭(~120GB/s) 바운드 → 1.25배에 그침. 예상과 일치.
- 결론: 프롬프트가 긴 작업(문서 요약, RAG, 코딩)에서 Vulkan 이득이 크다.
  MoE 모델(활성 파라미터 소수)은 decode도 GTT 용량 덕을 크게 볼 것.
