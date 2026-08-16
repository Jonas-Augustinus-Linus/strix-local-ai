---
license: apache-2.0
base_model: kakaocorp/kanana-1.5-8b-instruct-2505
language: [ko, en]
tags: [gguf, llama.cpp, imatrix, korean, quantized]
---

# kanana-1.5-8b-instruct-2505 — 한국어 보정 imatrix GGUF

**세계 최초(우리가 아는 한)의 한국어 중심 imatrix 보정 양자화.**
기존 공개 양자화들은 영어 위주 코퍼스로 importance matrix를 만들었습니다. 이 릴리스는
한국어 78% / 영어+코드 22% 코퍼스(위키백과, 퍼블릭 도메인 문학, 대화체, 기술문서)로
보정해 **한국어 토큰 분포에서의 양자화 손실을 최소화**했습니다.

## 측정 결과 (대조군: 영어 보정 imatrix 양자화)

| 양자화 | 크기 | 한국어 KLD (ours) | 한국어 KLD (영어 보정) | 개선 |
|---|---|---|---|---|
| (측정 후 기입) | | | | |

- 평가 텍스트: (코퍼스와 겹치지 않는 held-out 한국어 텍스트, 출처 명시)
- 기준 로짓: F16, llama.cpp build (기입), `--kl-divergence` 워크플로

## 파일

| 파일 | 타입 | 크기 | 용도 |
|---|---|---|---|
| (기입) | | | |

## 재현성

- llama.cpp commit: (기입)
- imatrix: 동봉된 `imatrix.dat` + 코퍼스 구성 명세는 [strix-local-ai](비공개→공개 예정) 참조
- 보정 코퍼스 소스: 전부 PD/CC BY/CC BY-SA/Apache — 목록은 `calibration-sources.md`
- 변환: `convert_hf_to_gguf.py --outtype f16` → `llama-imatrix` → `llama-quantize --imatrix`

## 라이선스

원본 모델: Apache 2.0 (kakaocorp). 이 양자화판도 Apache 2.0.

## 제작

Ryzen AI 9 HX PRO 370 (Radeon 890M iGPU, Vulkan/RADV)에서 제작.
