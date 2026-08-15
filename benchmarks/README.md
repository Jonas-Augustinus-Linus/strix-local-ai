# benchmarks/

모델별 성능/품질 측정 기록. 항상 같은 조건으로 측정해 비교 가능하게 유지한다.

## 측정 방법

```bash
# 처리량 (prefill pp512 / decode tg128)
~/llama.cpp/build-current/bin/llama-bench -m ~/models/<모델>.gguf [-ngl 99]

# 품질 (양자화 검증 시)
~/llama.cpp/build-current/bin/llama-perplexity -m <모델> -f <코퍼스>
```

## 기록 규칙

- 파일명: `YYYY-MM-DD-<모델명>.md`
- 필수 기재: llama.cpp 커밋 해시, 백엔드(CPU/Vulkan), -ngl, 컨텍스트, GTT 사용량
- 전원 상태 명시 (AC 연결 / 성능 프로파일)

## 결과 요약

| 날짜 | 모델 | 백엔드 | pp512 (t/s) | tg128 (t/s) | 비고 |
|---|---|---|---|---|---|
| 2026-08-15 | Qwen3-4B-2507 Q4_K_M | CPU ×12 | 184.8 | 27.3 | [상세](2026-08-15-qwen3-4b-q4km-cpu.md) |
| 2026-08-15 | Qwen3-4B-2507 Q4_K_M | Vulkan -ngl 99 | 609.4 | 34.1 | coopmat 활성, [상세](2026-08-15-qwen3-4b-q4km-vulkan.md) |
| 2026-08-15 | gpt-oss-20b MXFP4 | Vulkan -ngl 99 -fa 1 | 608.6 | 32.7 | FA on +22% pp, [상세](2026-08-15-gpt-oss-20b-mxfp4-vulkan.md) |
| 2026-08-15 | Gemma 4 26B-A4B Q4_0 | Vulkan -ngl 99 -fa 1 | 466.1 | 32.2 | 주력 확정, [상세](2026-08-15-gemma4-26b-a4b-q4_0-vulkan.md) |
