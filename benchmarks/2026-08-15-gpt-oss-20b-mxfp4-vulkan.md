# gpt-oss-20b MXFP4 — Vulkan(890M) + FA A/B

- 날짜: 2026-08-15
- llama.cpp: build 10450 (`ece963f41`), Vulkan(RADV), `-ngl 99`
- 모델: ggml-org/gpt-oss-20b-GGUF (11.27 GiB, MoE 20.9B 총 / 3.6B 활성)

## llama-bench — Flash Attention A/B

| fa | pp512 (t/s) | tg128 (t/s) |
|---|---|---|
| off | 498.89 ± 5.56 | 31.76 ± 0.23 |
| **on** | **608.56 ± 5.03 (+22%)** | **32.65 ± 0.23 (+3%)** |

→ **FA on 확정** (PR #19625 Wave32 scalar FA 효과 실증). 리서치에서 본 23.4 t/s
보고치보다 40% 빠름 — Wave32 FA 이후 빌드 + coopmat 덕분으로 추정.

## 실사용 (llama-completion -cnv -st --jinja, -c 8192)

- prefill 236.3 t/s / decode **32.4 t/s**
- Harmony 템플릿 정상 (analysis→final 채널 분리 확인), 한국어 창작 품질 준수
- 주의: `--jinja` 없으면 Harmony 포맷이 깨져 출력 품질 저하

## 메모

- 20B MoE가 4B 밀집(34.1 t/s)과 사실상 동속 — **MoE가 이 하드웨어의 정답** 재확인
- 같은 레포의 eagle3 드래프트 GGUF로 speculative decoding 실험 여지 (TODO)
