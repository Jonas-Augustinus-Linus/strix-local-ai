# FLUX.1-dev 1536² 네이티브 생성 언락 — gfx1150 ROCm attention 튜닝 (2026-08-21)

## 요약 (TL;DR)

Radeon 890M (gfx1150, RDNA 3.5) + ROCm 7.14 + torch 2.11에서 FLUX DiT가
**1536² 이상 해상도에서 무조건 행(hang)** 걸리던 문제를
**`--use-split-cross-attention` 플래그 하나로 해결**했다.

- 원인: ComfyUI 기본 attention = **pytorch SDPA** — gfx1150 ROCm에서 큰 토큰수
  (1536² = 9,216 latent 토큰)의 attention 커널이 GPU 큐를 행시킴 (busy 1-2%로 추락,
  영원히 진행 없음). 반복 kill 시 MES 펌웨어 웨지(#5993)로 번져 **재부팅 전까지
  1024²조차 불가능**해짐.
- 해결: split attention은 attention을 청크로 쪼개 다른 커널 경로(bmm 기반)를 타므로
  대토큰에서도 안전. **1024² 속도 비용 = 0** (아래 실측).

## 실측 (FLUX.1-dev-abliterated-V2, 20 steps, euler/simple, cfg 1, FluxGuidance 3.5, seed 42)

| 조합 | attention | 결과 | 시간 | GTT 피크 (/26G) |
|---|---|---|---|---|
| Q6_K 1024² | pytorch SDPA (기본) | ✅ | 416s | 14G |
| Q6_K 1536² | pytorch SDPA (기본) | ❌ **행** → MES 웨지 | — | — |
| Q6_K 1536² | `--use-pytorch-cross-attention` 명시 | ❌ 더 악화 (1024²까지 파괴) | — | — |
| Q6_K 1024² | **split** | ✅ | **412s** | 14G |
| Q6_K 1536² | **split** | ✅ **언락!** | **1,144s (~19분)** | 23G |
| Q8_0 1024² | **split** | ✅ | **392s** | 16G |
| Q8_0 1536² | **split** | ✅ | **1,145s (~19분)** | 24G |
| Q8_0 1024² 28스텝 | **split** | ✅ | 562s (~21s/스텝 선형) | 16G |
| Q8_0 1024² + ESRGAN 2x (→2048²) | **split** | ✅ | 492s (업스케일 ~100s) | 18G |

핵심 발견 3가지:

1. **split attention은 공짜다** — 1024²에서 412s vs 416s (오차범위). 켜지 않을 이유가 없다.
2. **Q8_0이 Q6_K보다 빠르다** (392s vs 412s @1024²) — Q8_0 dequant가 Q6_K보다 단순해서
   GPU에서 더 싸다. 디스크(12.7G vs 9.2G)와 GTT(+2G)만 더 쓴다. 품질도 위이므로
   **26G GTT 머신이면 Q8_0이 기본값으로 옳다.** (1536²에선 1144s vs 1145s 동률 —
   attention이 지배해서 dequant 차이가 사라짐.)
3. 1536²는 1024² 대비 픽셀 2.25배지만 시간은 **2.78배** — attention 초선형 비용.
   ETA 추정은 픽셀 비례가 아니라 실측 기반 구간값을 쓸 것.

GTT 한계 메모: Q8@1536이 24G/26로 **이 머신의 실용 천장**이다. 그 이상(1792²+,
batch≥2 @1536)은 2026-08-16 하드크래시 교훈(캡 2-3G 이내 접근 금지) 위반 — 시도하지 말 것.

## 재현 (ComfyUI 실행 플래그)

```
python main.py --enable-dynamic-vram --disable-mmap --cache-none --bf16-vae \
  --reserve-vram 2 --use-split-cross-attention
```

- torch 2.11.0+rocm7.14.0, gfx1150 네이티브 (HSA_OVERRIDE 설정 금지)
- 시도했지만 필요 없었던 나머지 후보 (split만으로 해결):
  `--use-quad-cross-attention`, `TORCH_BLAS_PREFER_HIPBLASLT=0`,
  `PYTORCH_HIP_ALLOC_CONF=expandable_segments:True`, `HSA_ENABLE_SDMA=0`

## 웨지 복구 절차 (재발 시)

행 → 프로세스 kill 반복 → ROCm/MES 큐가 펌웨어 수준에서 웨지되면 (GTT 깨끗해도
클린 상태 Q6/1024까지 행) **재부팅이 유일한 확실한 복구**다.
Vulkan 경로(llama.cpp 채팅)는 웨지와 무관하게 정상 동작한다 — ROCm(HIP) 큐만 죽는다.

## 맥락

- 이전 기록: [2026-08-20-image-limits-890m.md](2026-08-20-image-limits-890m.md) (SDXL 한계),
  [2026-08-19-chroma-fp8-vs-bf16.md](2026-08-19-chroma-fp8-vs-bf16.md) (fp8 에뮬레이션)
- FLUX 도입: commit cfd490d, 1024 안전캡: commit bd52ac3 (이 문서로 캡 해제)
