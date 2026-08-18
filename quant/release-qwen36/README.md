---
license: apache-2.0
base_model: Qwen/Qwen3.6-35B-A3B
language:
- ko
- en
library_name: llama.cpp
tags:
- gguf
- imatrix
- korean
- quantized
- qwen3.6
- moe
---

# Qwen3.6-35B-A3B — 한국어 보정 imatrix GGUF (KO-i1)

**한국어 중심 코퍼스로 보정한 imatrix 양자화** — [kanana-1.5 KO-i1](https://huggingface.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF)에 이은 2차 릴리스.

기존 공개 양자화들은 영어 위주 코퍼스로 importance matrix를 생성합니다. 이 릴리스는
**한국어 79% / 영어+코드 21%** 코퍼스(위키백과 111편, 퍼블릭 도메인 문학 191편,
허용 라이선스 대화 데이터 6종, 영어/코드 — 1차 릴리스와 동일)로 보정했습니다.

## 🔰 처음이신가요? (ollama가 뭔지 몰라도 됩니다)

1. [LM Studio](https://lmstudio.ai) 설치 (무료, Windows/Mac/Linux)
2. 🔍 검색에 **`augustine223`** → 이 모델 선택
3. 파일은 **하나만**: RAM 24GB면 `IQ3_M`, 32GB면 `IQ4_XS`(추천), 48GB+면 `Q5_K_M`
4. 다운로드 후 💬 채팅 탭에서 대화 — **응답이 비면 max tokens를 4000+로**
   (이 모델은 답하기 전에 "생각"하는 리즈닝 모델입니다)

터미널이 편하다면 한 줄:
```bash
ollama run hf.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF:IQ4_XS
```
상세 가이드(KoboldCpp/llama.cpp 포함): [실행 가이드](https://github.com/Jonas-Augustinus-Linus/strix-local-ai/blob/main/docs/run-guide-ko.md)

## 측정 결과 (한국어 held-out 텍스트, KLD vs BF16)

**보정 언어 효과 (영어 보정 mradermacher i1 대비):**

| 타입 | 이 릴리스 (한국어 보정) | 영어 보정 (mradermacher i1) | ΔKLD | 유의성 |
|---|---|---|---|---|
| Q4_K_M | 0.02320 | 0.02445 | **-5.1%** | 2.3σ |
| IQ4_XS | 0.02890 | 0.03058 | **-5.5%** | 2.3σ |
| IQ3_M | 0.07045 | 0.07194 | -2.1% | 1.0σ |
| IQ3_XXS | 0.11155 | 0.11963 | **-6.8%** | 3.6σ |
| IQ2_M | 0.20487 | 0.21951 | **-6.7%** | 4.3σ |

정직한 요약: IQ3_M을 제외한 전 타입에서 통계적으로 유의한 이득(2.3~4.3σ)이며,
저비트일수록 커집니다(IQ2_M -6.7%, 4.3σ). kanana 1차 릴리스와 달리 4비트에서도
유의한 차이가 관측됐습니다. (비교 대상과는 보정 코퍼스 외에 레시피 세부도 다를 수
있어 ΔKLD 전부가 보정 언어 효과만은 아닐 수 있습니다.)

**우리 사다리 전체** (기준 PPL 8.5328):

| 파일 | 크기 | 한국어 KLD | Same-top | 권장 용도 |
|---|---|---|---|---|
| KO-i1-Q8_0 | 36GB | 0.00446 | 96.8% | 사실상 무손실 |
| KO-i1-Q6_K | 28GB | 0.00987 | 94.8% | 고품질 |
| KO-i1-Q5_K_M | 24GB | 0.01185 | 94.3% | 균형 |
| KO-i1-Q4_K_M | 21GB | 0.02320 | 91.9% | 표준 권장 |
| KO-i1-IQ4_XS | 18GB | 0.02890 | 91.6% | **32GB 통합메모리 스윗스팟** |
| KO-i1-IQ3_M | 15GB | 0.07045 | 86.1% | 저메모리 |
| KO-i1-IQ3_XXS | 14GB | 0.11155 | 83.3% | |
| KO-i1-IQ2_M | 12GB | 0.20487 | 78.0% | 극한 압축 |

`Qwen3.6-35B-A3B.imatrix.gguf`(184MB)도 동봉 — 다른 타입을 직접 만들 수 있습니다.

## 재현성

- llama.cpp build 10449 CPU 백엔드, 전 측정 `-c 512` 동일
- imatrix: **Q8_0 기반** 수집(대형 MoE 표준 관행), 708청크(~36만 토큰), expert 커버리지 ≥99.61%
- 평가: KLUE-MRC 검증셋 + 2026-08 korea.kr 기사 (보정 코퍼스와 오염 검사 통과, 1차 릴리스와 동일 코퍼스)
- 보정 코퍼스 전체 출처(302개): 동봉된 `calibration-sources.md` 참조
- blk.40(MTP/nextn)은 추론 그래프 비활성 텐서 — imatrix가 수집되지 않아
  IQ3_XXS/IQ2_M에서는 q4_K로 고정(다른 타입은 각자 기본 믹스). MTP 추측 디코딩을
  쓰려면 ggml-org의 별도 `mtp-Qwen3.6-35B-A3B` GGUF를 `-md`로 지정하세요.
- 제작 하드웨어: AMD Ryzen AI 9 HX PRO 370 (32GB, Radeon 890M iGPU)

## 사용

```bash
llama-server -m Qwen3.6-35B-A3B.KO-i1-IQ4_XS.gguf -ngl 99 -c 32768 --jinja -fa on
```

**RDNA3.5 APU(890M 등) Vulkan 사용자 주의:** 이 모델은 `-b 1024 -ub 1024`가 필수입니다
(기본 배치에서 크래시, llama.cpp #22425). 통합메모리 기기에서는 `--no-mmap` 권장.

## 라이선스

원본 모델 Apache 2.0 (Alibaba/Qwen). 이 양자화판도 Apache 2.0.
보정 코퍼스 출처: 전부 PD / CC BY / CC BY-SA / Apache / MIT / KOGL-1 (문서화됨).
