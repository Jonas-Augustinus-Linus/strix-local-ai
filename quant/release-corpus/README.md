---
license: cc-by-sa-4.0
language:
- ko
- en
tags:
- korean
- calibration
- imatrix
- quantization
- gguf
- llama.cpp
pretty_name: Korean imatrix Calibration Corpus (KO-i1)
size_categories:
- n<1K
---

# Korean imatrix Calibration Corpus — KO-i1 보정 코퍼스

**한국어 중심 imatrix 보정 코퍼스의 첫 공개 릴리스** (우리가 아는 한).

공개 GGUF 양자화 생태계의 importance matrix는 거의 전부 영어 위주 코퍼스로
수집됩니다. 그 결과 한국어 토큰 분포에서의 양자화 손실이 체계적으로 커집니다.
이 데이터셋은 그 공백을 메우기 위해 만들어졌고, 실측으로 효과가 입증됐습니다.

## 실측 효과 (이 코퍼스로 만든 KO-i1 릴리스들)

| 릴리스 | 비교 대상 | 결과 |
|---|---|---|
| [kanana-1.5-8b KO-i1](https://huggingface.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF) | 영어 보정 i1 | 저비트 KLD **-5~6%** (IQ2_M 3.3σ), 비트 낮을수록 이득 증가 |
| [Qwen3.6-35B-A3B KO-i1](https://huggingface.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF) | 영어 보정 i1 | 전 타입 우세, **-5.1~-6.8%** (최대 4.3σ), MoE는 4비트도 유의 |
| [Qwen3.8-27B-abl KO-i1](https://huggingface.co/augustine223/Huihui-Qwen3.8-27B-abliterated-KO-i1-GGUF) | 정적 양자 (동급 크기) | KLD **-23.7% (9.1σ)** |

## 구성

`calibration.txt` (1.53MB, 한국어 79% / 영어+코드 21%) — 아래 세그먼트에서
`build_calibration.py`로 조립. 세그먼트 원문도 전부 동봉:

| 파일 | 크기 | 내용 | 출처 수 | 라이선스 |
|---|---|---|---|---|
| seg1-wiki-ko.txt | 2.3MB | 한국어 위키백과 백과사전 산문 | 111편 | CC BY-SA 4.0 |
| seg2-literature-ko.txt | 1.3MB | 퍼블릭 도메인 한국 문학 | 191편 | Public Domain |
| seg3-conversation-ko.txt | 1.2MB | 허용 라이선스 대화체 | 6종 | Apache/MIT/CC |
| seg4-code.txt + seg4-english.txt | 1.0MB | 코드 + 영어 산문 | 45건 | 허용 라이선스 |

전체 출처 302개는 `seg*-sources.md`에 URL·라이선스 단위로 문서화.

**보너스**: `eval-ko.txt` (151KB) — KLD 측정용 held-out 평가셋 (KLUE-MRC 47지문
+ korea.kr 2026-08 기사 9건, 보정 코퍼스와 오염 검사 완료). ⚠️ 이 파일은
**평가 전용**입니다 — 여기에 보정하면 위 릴리스들과의 비교가 무효가 됩니다.

## 사용법

```bash
# 어떤 모델이든 한국어 보정 imatrix 만들기 (llama.cpp)
llama-imatrix -m <모델>.gguf -f calibration.txt -o <모델>.imatrix.gguf \
  -c 512 --output-frequency 10 --save-frequency 50
# 그 imatrix로 양자화
llama-quantize --imatrix <모델>.imatrix.gguf <BF16>.gguf <출력>.gguf IQ4_XS
```

- RAM보다 큰 모델은 CPU 빌드로 돌리세요 (iGPU/Vulkan 로드는 시스템 크래시 위험 —
  [함정 문서](https://github.com/Jonas-Augustinus-Linus/strix-local-ai/blob/main/docs/gotchas.md) G6 참조)
- MoE는 expert 커버리지를 `--show-statistics`로 확인 (위 릴리스들은 ≥99.6%)
- 전체 파이프라인 스크립트: [strix-local-ai](https://github.com/Jonas-Augustinus-Linus/strix-local-ai)

## 라이선스

컴파일 전체: **CC BY-SA 4.0** (가장 제한적인 구성요소 기준).
세그먼트별 상세는 위 표와 `seg*-sources.md` 참조 — PD 문학은 자유 사용 가능,
위키백과 유래분은 BY-SA 준수 필요. 평가셋: KLUE(CC BY-SA 4.0) + korea.kr(KOGL 1유형).
