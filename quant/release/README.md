---
license: apache-2.0
base_model: kakaocorp/kanana-1.5-8b-instruct-2505
language:
- ko
- en
library_name: llama.cpp
tags:
- gguf
- imatrix
- korean
- quantized
- kanana
---

# kanana-1.5-8b-instruct-2505 — 한국어 보정 imatrix GGUF (KO-i1)

**한국어 중심 코퍼스로 보정한 최초의 imatrix 양자화** (우리가 확인한 범위에서).

기존 공개 양자화들은 영어 위주 코퍼스로 importance matrix를 생성합니다. 이 릴리스는
**한국어 79% / 영어+코드 21%** 코퍼스(위키백과 111편, 퍼블릭 도메인 문학 191편,
허용 라이선스 대화 데이터 6종, 영어/코드)로 보정하여 한국어 토큰 분포에서의 양자화
손실을 줄였습니다.

## 측정 결과 (한국어 held-out 텍스트, KLD vs F16)

**보정 언어 효과 — 비트가 낮을수록 한국어 보정의 우위가 커집니다:**

| 타입 | 이 릴리스 (한국어 보정) | 영어 보정 (mradermacher i1) | ΔKLD | 유의성 |
|---|---|---|---|---|
| Q4_K_M | 0.02703 | 0.02742 | -1.4% | 0.6σ |
| IQ4_XS | 0.03327 | 0.03447 | -3.5% | 1.4σ |
| IQ3_M | 0.08902 | 0.09381 | **-5.1%** | 2.4σ |
| IQ3_XXS | 0.15438 | 0.16289 | **-5.2%** | 2.6σ |
| IQ2_M | 0.25717 | 0.27245 | **-5.6%** | 3.3σ |

**imatrix 자체의 효과** (Q4_K_M): 무보정 0.04715 → imatrix 0.02703 (**-42%**)

정직한 요약: 4비트에서는 보정 언어 차이가 오차범위 수준이고, **3비트 이하에서
통계적으로 유의한 이득**이 있습니다. 저비트를 쓸수록 이 릴리스의 가치가 커집니다.

## 파일

| 파일 | 크기 | 한국어 KLD | Same-top | 권장 용도 |
|---|---|---|---|---|
| KO-i1-Q8_0 | 8.0GB | 0.00284 | 97.3% | 사실상 무손실 |
| KO-i1-Q6_K | 6.2GB | 0.00662 | 95.8% | 고품질 |
| KO-i1-Q5_K_M | 5.4GB | 0.01060 | 94.9% | 균형 |
| KO-i1-Q4_K_M | 4.6GB | 0.02703 | 92.5% | 표준 권장 |
| KO-i1-IQ4_XS | 4.2GB | 0.03327 | 91.6% | 메모리 절약 |
| KO-i1-Q3_K_M | 3.8GB | 0.07663 | 87.8% | |
| KO-i1-IQ3_M | 3.6GB | 0.08902 | 87.0% | 저메모리 |
| KO-i1-IQ3_XXS | 3.1GB | 0.15438 | 82.8% | |
| KO-i1-IQ2_M | 2.8GB | 0.25717 | 78.1% | 극한 압축 |

`kanana-1.5-8b-instruct-2505.imatrix.gguf`(4.8MB)도 동봉 — 다른 타입을 직접 만들 수 있습니다.

## 재현성

- llama.cpp build 10450 (`ece963f41`), 전 측정 `-c 512` 동일
- imatrix: 774청크(~39.6만 토큰), 기본 설정(`llama-imatrix -ngl 99`)
- 평가: KLUE-MRC 검증셋 + 2026-08 korea.kr 기사 (보정 코퍼스와 오염 검사 30/30×2 통과)
- 보정 코퍼스 전체 출처(302개)와 파이프라인 스크립트: 함께 공개된
  `calibration-sources.md` 및 제작 레포 참조
- 제작 하드웨어: AMD Ryzen AI 9 HX PRO 370 (Radeon 890M iGPU, Vulkan/RADV)

## 사용

```bash
llama-cli -hf <THIS_REPO>:Q4_K_M
# 또는
llama-server -m kanana-1.5-8b-instruct-2505.KO-i1-Q4_K_M.gguf -ngl 99 -c 8192 --jinja
```

## 라이선스

원본 모델 Apache 2.0 (Kakao). 이 양자화판도 Apache 2.0.
보정 코퍼스 출처: 전부 PD / CC BY / CC BY-SA / Apache / MIT / KOGL-1 (문서화됨).
