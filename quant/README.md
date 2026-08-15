# quant/ — GGUF 양자화 파이프라인

목표: HF 원본 모델 → 한국어 특화 imatrix 양자화 GGUF 세트 → HF Hub 공개.

## 파이프라인 단계

```
HF safetensors
  │  convert_hf_to_gguf.py (llama.cpp)
  ▼
F16(or BF16) GGUF          ← 기준 원본, 디스크만 차지하고 재사용
  │  llama-imatrix -m f16.gguf -f corpus.txt
  ▼
imatrix.dat                ← 한국어+영어 혼합 코퍼스로 생성 (차별화 포인트)
  │  llama-quantize --imatrix imatrix.dat
  ▼
Q4_K_M / Q5_K_M / Q6_K / IQ4_XS / Q8_0 ...
  │  llama-perplexity (품질 검증: ppl, KLD)
  ▼
HF 업로드 (모델 카드 + 측정치 첨부)
```

## 규칙

- **라이선스 확인 필수**: 재배포(양자화판 업로드)가 허용되는 라이선스만 다룬다.
  Apache-2.0 / MIT / Llama 계열 라이선스(조건부) OK, 연구용 한정 라이선스는 업로드 금지.
- 모든 양자화판은 같은 imatrix, 같은 llama.cpp 커밋으로 생산하고 커밋 해시를 모델 카드에 기록.
- 품질 검증 없이 업로드하지 않는다: 최소 wikitext ppl + 한국어 텍스트 ppl 두 가지.
- 작업 공간: `~/models/work/<모델명>/` (F16, imatrix, 산출물), 완성본은 `~/models/`.

## 메모리 제약 참고

- F16 변환은 디스크만 사용 (24B → ~48GB, 여유 충분)
- imatrix 생성은 모델을 실제 실행 → 24B F16은 RAM 초과.
  → 큰 모델은 Q8_0으로 먼저 내려서 imatrix 생성 (정확도 손실 미미, 공인된 우회법)

## 첫 릴리스 타깃: kanana-1.5

- 카카오 kanana-1.5, **Apache 2.0** → 재배포 문제 없음
- 한국어 보정 imatrix 데이터셋은 공개된 것이 전무(2026-08-15 리서치로 확인) → 이 공백이 기여 지점
- 산출물: 한국어 imatrix GGUF 세트 + 한국어 KLD/ppl 측정치를 모델 카드에 첨부

## TODO

- [ ] `corpus/` 한국어+영어 imatrix 코퍼스 구성 (위키, 문학, 대화체, 코드 혼합)
- [ ] `run-quant.sh`: 위 파이프라인 원커맨드 자동화
- [ ] `verify.sh`: ppl/KLD 자동 측정 → benchmarks/에 기록
- [ ] `upload.sh`: huggingface_hub로 업로드 + 모델 카드 템플릿
