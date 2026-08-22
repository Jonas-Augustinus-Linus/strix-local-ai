#!/usr/bin/env python3
"""Aggregate results/*.{igpu,npu}.json into a publishable RESULTS.md table.
Usage: python3 tabulate.py <results_dir> <stamp>   (stamp = date string, passed in)
"""
import json, sys, glob, os

resdir = sys.argv[1]
stamp = sys.argv[2] if len(sys.argv) > 2 else "manual"

def load(p):
    try:
        with open(p) as f: return json.load(f)
    except Exception: return None

# pair up <label>.igpu.json <-> <label>.npu.json
labels = sorted({os.path.basename(p).split(".")[0]
                 for p in glob.glob(os.path.join(resdir, "*.json"))})

def cell(v, fmt="{:.1f}"):
    return fmt.format(v) if isinstance(v, (int, float)) else "—"

rows = []
for lb in labels:
    ig = load(os.path.join(resdir, f"{lb}.igpu.json"))
    np = load(os.path.join(resdir, f"{lb}.npu.json"))
    def g(d, k): return (d or {}).get(k)
    ig_dec, np_dec = g(ig, "decode_tps"), g(np, "decode_tps")
    ig_pre, np_pre = g(ig, "prefill_tps"), g(np, "prefill_tps")
    dec_ratio = (np_dec / ig_dec) if (ig_dec and np_dec) else None
    pre_ratio = (np_pre / ig_pre) if (ig_pre and np_pre) else None
    rows.append((lb, ig, np, ig_dec, np_dec, ig_pre, np_pre, dec_ratio, pre_ratio))

print(f"# NPU vs iGPU — measured A/B ({stamp})")
print()
print("Strix Point / Ryzen AI 9 HX PRO 370 · Radeon 890M (gfx1150) · XDNA2 (aie2p) · 32GB LPDDR5x")
print("NPU = FastFlowLM (W4A16, native) · iGPU = llama.cpp Vulkan (Q4_K_M, `-fa 1 -ngl 99`)")
print(f"Prompt {512} tok · gen {128} tok · median of 3 · same OpenAI streaming client both sides")
print()
print("## Decode throughput (bandwidth-bound — the load-bearing question)")
print()
print("| Model | iGPU decode t/s | NPU decode t/s | NPU/iGPU |")
print("|---|--:|--:|--:|")
for lb, ig, np, igd, npd, igp, npp, dr, pr in rows:
    print(f"| {lb} | {cell(igd,'{:.2f}')} | {cell(npd,'{:.2f}')} | "
          f"{cell(dr,'{:.2f}×') if dr else '—'} |")
print()
print("## Prefill throughput (compute-bound — NPU's expected strength)")
print()
print("| Model | iGPU prefill t/s | NPU prefill t/s | NPU/iGPU |")
print("|---|--:|--:|--:|")
for lb, ig, np, igd, npd, igp, npp, dr, pr in rows:
    print(f"| {lb} | {cell(igp)} | {cell(npp)} | {cell(pr,'{:.2f}×') if pr else '—'} |")
print()
print("## TTFT (time to first token, chat-realistic 512-tok prompt)")
print()
print("| Model | iGPU TTFT ms | NPU TTFT ms |")
print("|---|--:|--:|")
for lb, ig, np, *_ in rows:
    print(f"| {lb} | {cell((ig or {}).get('ttft_ms'),'{:.0f}')} | "
          f"{cell((np or {}).get('ttft_ms'),'{:.0f}')} |")
print()
print("## Verdict")
print()
print("_Filled from the numbers above once measured:_")
print("- **Q1 decode NPU>iGPU?** — see decode ratio column (>1.0× = NPU wins the daily-driver metric).")
print("- **Q2 prefill win** — prefill ratio column (long-context / RAG cost).")
print("- **Q3 TTFT** — responsiveness for chat.")
print("- **Q4 27B usable** — add the 27B row; <~4 t/s decode = borderline.")
print()
print("<sub>Reproduce: `benchmarks/npu-ab/run_ab.sh`. Raw per-run JSON + llama-bench "
      "reference under `results/`. No secrets/tailnet addresses in this report.</sub>")
