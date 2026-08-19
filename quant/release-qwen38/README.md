---
license: apache-2.0
base_model: huihui-ai/Huihui-Qwen3.8-27B-abliterated
language:
- ko
- en
library_name: llama.cpp
tags:
- gguf
- imatrix
- korean
- quantized
- qwen3.8
- abliterated
- uncensored
---

# Huihui-Qwen3.8-27B-abliterated — 한국어 보정 imatrix GGUF (KO-i1)

**무검열(abliterated) 베이스 + 한국어 보정 imatrix — 이 조합의 첫 공개 릴리스.**
[kanana KO-i1](https://huggingface.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF),
[Qwen3.6 KO-i1](https://huggingface.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF)에 이은 3차.

베이스는 huihui-ai의 Qwen3.8-27B abliterated (거부 학습 제거판). 여기에
**한국어 79% / 영어+코드 21%** 보정 코퍼스(1·2차와 동일, 출처 302개 문서화)로
importance matrix를 수집해 양자화했습니다.

## 🔰 처음이신가요? (ollama가 뭔지 몰라도 됩니다)

1. [LM Studio](https://lmstudio.ai) 설치 (무료, Windows/Mac/Linux)
2. 🔍 검색에 **`augustine223`** → 이 모델 선택
3. 파일은 **하나만**: RAM 16GB면 `IQ3_XXS`, 24GB면 `IQ4_XS`, 32GB면 `Q5_K_M`(추천), 48GB+면 `Q6_K`
4. 💬 채팅 탭에서 대화 — **응답이 비면 max tokens를 4000+로** (리즈닝 모델)

터미널이 편하다면:
```bash
ollama run hf.co/augustine223/Huihui-Qwen3.8-27B-abliterated-KO-i1-GGUF:Q5_K_M
```
상세 가이드: [실행 가이드](https://github.com/Jonas-Augustinus-Linus/strix-local-ai/blob/main/docs/run-guide-ko.md)

## 측정 결과 (한국어 held-out 텍스트, KLD vs abliterated BF16)

**정적 배포판 대비 (같은 급 크기):**

| | 크기 | Mean KLD | Same top p |
|---|---|---|---|
| **KO-i1-Q5_K_M (이 릴리스)** | 19GB | **0.00597** | 95.9% |
| 정적 Q5_K (기존 배포판) | 18.2GB | 0.00783 | 95.2% |

→ **KLD -23.7% (9.1σ)**: 유사 크기에서 한국어 imatrix 보정의 이득.

**사다리 전체** (기준 PPL 8.578):

| 파일 | 크기 | 한국어 KLD | Same-top | 권장 |
|---|---|---|---|---|
| KO-i1-Q8_0 | 28GB | 0.00061 | 98.7% | 사실상 무손실 |
| KO-i1-Q6_K | 21GB | 0.00375 | 96.5% | 고품질 |
| KO-i1-Q5_K_M | 19GB | 0.00597 | 95.9% | **32GB 통합메모리 추천** |
| KO-i1-Q4_K_M | 16GB | 0.01399 | 93.9% | 표준 |
| KO-i1-IQ4_XS | 15GB | 0.01848 | 92.9% | 메모리 절약 |
| KO-i1-IQ3_M | 12GB | 0.05824 | 87.6% | 저메모리 |
| KO-i1-IQ3_XXS | 11GB | 0.08951 | 85.2% | 16GB 기기 |
| KO-i1-IQ2_M | 9.6GB | 0.16996 | 80.1% | 극한 압축 |

`Huihui-Qwen3.8-27B-abliterated.imatrix.gguf`(14MB) 동봉 — 다른 타입 직접 제작 가능.

## 재현성

- llama.cpp build 10449 CPU 백엔드, 전 측정 `-c 512` 동일
- imatrix: Q8_0 기반 수집, 708청크(~36만 토큰), 최종 PPL 8.578
- 평가: KLUE-MRC 검증셋 + 2026-08 korea.kr 기사 (보정 코퍼스와 오염 검사 통과)
- **코퍼스 전체 공개**: [korean-imatrix-calibration-corpus](https://huggingface.co/datasets/augustine223/korean-imatrix-calibration-corpus) (세그먼트 원문 + 302개 출처 문서 + 빌드 스크립트 + 평가셋)
- blk.64(MTP/nextn)는 추론 그래프 비활성 텐서 — imatrix 미수집으로 전 타입 q4_K 고정.
  MTP 추측 디코딩은 ggml-org의 `mtp-Qwen3.8-27B-*.gguf`를 `-md`로 지정
- 제작: AMD Ryzen AI 9 HX PRO 370 (32GB, Radeon 890M) — 전 과정 CPU/iGPU 로컬,
  파이프라인 공개: [strix-local-ai](https://github.com/Jonas-Augustinus-Linus/strix-local-ai)

## 사용

```bash
llama-server -m Huihui-Qwen3.8-27B-abliterated.KO-i1-Q5_K_M.gguf -ngl 99 -c 16384 --jinja -fa on
```
통합메모리 기기는 `--no-mmap` 권장. 리즈닝 모델이므로 API 호출 시 max_tokens를 넉넉히.

## 라이선스

원본 모델 Apache 2.0 (Alibaba/Qwen), abliteration: huihui-ai. 이 양자화판도 Apache 2.0.
보정 코퍼스 출처: 전부 PD / CC BY / CC BY-SA / Apache / MIT / KOGL-1 (문서화됨).

## 철학 (Why uncensored)

과도한 필터링은 모델의 실제 성능을 함께 깎아왔습니다. 이 프로젝트는
자유인으로서의 사용자를 전제로, 그 자유의지에 시스템적 제한을 두지 않는
온전한 형태의 자유 언어모델을 지향합니다. 판단과 책임은 도구가 아니라
사람의 몫이며, 이 자유로운 전제 위에서 창의성이 온전히 발휘되기를 바랍니다.

Excessive filtering has consistently taxed real model capability. This project
assumes a free human being as its user: a complete, unrestricted language model
with no systemic constraints on free will. Judgment and responsibility belong
to people, not tools — and on that free premise, may creativity be fully expressed.

## 고지 (Disclaimer)

> **본 프로젝트는 무검열(uncensored/abliterated) 버전만을 개발·공개합니다.**
> 이 모델은 안전 필터/거부 학습이 제거된 상태로, 있는 그대로(as-is) 제공됩니다.
> 생성된 출력과 그 사용으로 발생하는 **모든 결과에 대한 책임은 전적으로 사용자에게
> 귀속됩니다.** 사용자는 자신의 관할지 법률과 원본 모델 라이선스를 준수할 책임이
> 있습니다.
>
> This release is an uncensored variant, provided **as-is**. All responsibility
> for generated outputs and any consequences of use rests **solely with the
> user**, who must comply with applicable laws and the base model's license.
