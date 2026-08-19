---
license: apache-2.0
base_model: huihui-ai/Huihui-Qwen3.6-35B-A3B-abliterated
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
- abliterated
- uncensored
---

# Huihui-Qwen3.6-35B-A3B-abliterated — 한국어 보정 imatrix GGUF (KO-i1)

**무검열(abliterated) A3B MoE + 한국어 보정 imatrix.** [정식 Qwen3.6 KO-i1](https://huggingface.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF)의
무검열 자매판 — **완전히 같은 코퍼스·방법론**으로 만들어 나란히 비교 가능합니다.

## 🔰 처음이신가요? (ollama가 뭔지 몰라도 됩니다)

1. [LM Studio](https://lmstudio.ai) 설치 (무료, Windows/Mac/Linux)
2. 🔍 검색에 **`augustine223`** → 이 모델 선택
3. 파일은 **하나만**: RAM 24GB면 `IQ3_M`, 32GB면 `IQ4_XS`(추천), 48GB+면 `Q5_K_M`
4. 💬 채팅 — **응답이 비면 max tokens를 4000+로** (리즈닝 모델)

```bash
ollama run hf.co/augustine223/Huihui-Qwen3.6-35B-A3B-abliterated-KO-i1-GGUF:IQ4_XS
```
상세 가이드: [실행 가이드](https://github.com/Jonas-Augustinus-Linus/strix-local-ai/blob/main/docs/run-guide-ko.md)

## 핵심: abliteration은 quant 품질을 훼손하지 않는다

정식판과 같은 코퍼스·방법론으로 만들어 직접 비교한 결과, KLD 사다리가 **정식판과
실질 동일**합니다 (전 구간 차이 ±1σ 안팎). 즉 검열 유무만 다르고 품질은 같은 한 쌍.

| 타입 | 정식 KO-i1 | 무검열 KO-i1 (이 릴리스) |
|---|---|---|
| Q4_K_M | 0.02320 | 0.02532 |
| IQ4_XS | 0.02890 | 0.03078 |
| IQ2_M | 0.20487 | 0.21188 |

## 측정 결과 (한국어 held-out, KLD vs abliterated f16, 기준 PPL 8.834)

| 파일 | 크기 | 한국어 KLD | Same-top | 권장 |
|---|---|---|---|---|
| KO-i1-Q8_0 | 36GB | 0.00463 | 96.6% | 사실상 무손실 |
| KO-i1-Q6_K | 28GB | 0.01014 | 94.8% | 고품질 |
| KO-i1-Q5_K_M | 24GB | 0.01369 | 94.0% | 균형 |
| KO-i1-Q4_K_M | 21GB | 0.02532 | 91.7% | 표준 |
| KO-i1-IQ4_XS | 18GB | 0.03078 | 91.3% | **32GB 통합메모리 추천** |
| KO-i1-IQ3_M | 15GB | 0.07422 | 85.9% | 저메모리 |
| KO-i1-IQ3_XXS | 14GB | 0.11632 | 82.7% | |
| KO-i1-IQ2_M | 12GB | 0.21188 | 77.6% | 극한 압축 |

`Huihui-Qwen3.6-35B-A3B-abliterated.imatrix.gguf` 동봉 — 다른 타입 직접 제작 가능.

## 재현성

- llama.cpp build 10449 CPU 백엔드, 전 측정 `-c 512` 동일
- imatrix: Q8_0 기반 수집, 708청크(~36만 토큰), 최종 PPL 8.375
- 평가: KLUE-MRC 검증셋 + 2026-08 korea.kr 기사 (오염 검사 통과)
- **코퍼스 전체 공개**: [korean-imatrix-calibration-corpus](https://huggingface.co/datasets/augustine223/korean-imatrix-calibration-corpus)
- blk.40(MTP/nextn)은 추론 그래프 비활성 텐서 — 전 타입 q4_K 고정 (dry-run 확정).
  MTP 추측 디코딩은 ggml-org의 `mtp-Qwen3.6-35B-A3B` GGUF를 `-md`로 지정
- 베이스: huihui-ai safetensors → convert_hf_to_gguf f16 → 양자화
- 제작: AMD Ryzen AI 9 HX PRO 370 (32GB, Radeon 890M), 전 과정 로컬,
  파이프라인 공개: [strix-local-ai](https://github.com/Jonas-Augustinus-Linus/strix-local-ai)

## 사용

```bash
llama-server -m Huihui-Qwen3.6-35B-A3B-abliterated.KO-i1-IQ4_XS.gguf -ngl 99 -c 32768 --jinja -fa on
```
**RDNA3.5 APU Vulkan 주의**: `-b 1024 -ub 1024` 필수 (#22425). 통합메모리는 `--no-mmap` 권장.

## 라이선스

원본 Apache 2.0 (Alibaba/Qwen), abliteration: huihui-ai. 이 양자화판도 Apache 2.0.
보정 코퍼스: 전부 PD / CC BY / CC BY-SA / Apache / MIT / KOGL-1 (문서화됨).

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
> 귀속됩니다.** 사용자는 자신의 관할지 법률과 원본 모델 라이선스를 준수할 책임이 있습니다.
>
> This release is an uncensored variant, provided **as-is**. All responsibility
> for generated outputs and any consequences of use rests **solely with the
> user**, who must comply with applicable laws and the base model's license.
