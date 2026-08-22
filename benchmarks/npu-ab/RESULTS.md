# NPU vs iGPU — measured A/B (2026-08-22)

Strix Point / Ryzen AI 9 HX PRO 370 · Radeon 890M (gfx1150) · XDNA2 (aie2p) · 32GB LPDDR5x
NPU = FastFlowLM (W4A16, native) · iGPU = llama.cpp Vulkan (Q4_K_M, `-fa 1 -ngl 99`)
Prompt 512 tok · gen 128 tok · median of 3 · same OpenAI streaming client both sides

## Decode throughput (bandwidth-bound — the load-bearing question)

| Model | iGPU decode t/s | NPU decode t/s | NPU/iGPU |
|---|--:|--:|--:|
| Qwen3-4B | 33.02 | — | — |

## Prefill throughput (compute-bound — NPU's expected strength)

| Model | iGPU prefill t/s | NPU prefill t/s | NPU/iGPU |
|---|--:|--:|--:|
| Qwen3-4B | 558.9 | — | — |

## TTFT (time to first token, chat-realistic 512-tok prompt)

| Model | iGPU TTFT ms | NPU TTFT ms |
|---|--:|--:|
| Qwen3-4B | 1043 | — |

## Verdict

_Filled from the numbers above once measured:_
- **Q1 decode NPU>iGPU?** — see decode ratio column (>1.0× = NPU wins the daily-driver metric).
- **Q2 prefill win** — prefill ratio column (long-context / RAG cost).
- **Q3 TTFT** — responsiveness for chat.
- **Q4 27B usable** — add the 27B row; <~4 t/s decode = borderline.

<sub>Reproduce: `benchmarks/npu-ab/run_ab.sh`. Raw per-run JSON + llama-bench reference under `results/`. No secrets/tailnet addresses in this report.</sub>
