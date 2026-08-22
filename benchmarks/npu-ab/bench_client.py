#!/usr/bin/env python3
"""
Backend-agnostic OpenAI-streaming benchmark client.

Measures, against ANY OpenAI-compatible /v1/chat/completions endpoint
(llama.cpp llama-server on iGPU-Vulkan, FastFlowLM `flm serve` on NPU, ...):

  - TTFT         : time to first streamed token (s)
  - prefill t/s  : prompt_tokens / TTFT           (compute-bound signal)
  - decode t/s   : (gen-1) / (t_end - t_first)     (bandwidth-bound signal)
  - end-to-end   : wall time, total tokens/s

Stdlib only (urllib) — no pip deps, runs in any venv or bare python3.
Fair A/B: point it at each backend in turn with identical prompt/gen settings.

Usage:
  python3 bench_client.py --url http://127.0.0.1:8080/v1 --model qwen3.8-27b \
      --prompt-tokens 512 --gen 128 --repeat 3 --label "iGPU-Vulkan Q4_K_M"
"""
import argparse, json, time, sys, os, urllib.request, statistics

# Optional bearer key (env only — never hard-code / never publish). llama-server
# with --api-key-file needs it; FLM serve typically needs none.
API_KEY = os.environ.get("LLM_API_KEY", "sk-noauth")

# ~1 token per word for this filler is close enough for a *relative* A/B;
# both backends see the identical string, so any tokenizer skew cancels out.
FILLER = ("The quick brown fox jumps over the lazy dog while counting "
          "numbers one two three four five and reciting the alphabet. ")

def make_prompt(target_tokens):
    # crude word≈token packing; identical across backends so bias cancels
    words = []
    per = FILLER.split()
    while len(words) < target_tokens:
        words.extend(per)
    return " ".join(words[:target_tokens])

def one_run(base_url, model, prompt, gen, timeout, nonce=""):
    # `nonce` (unique per run) defeats server-side prompt caching so PREFILL is
    # actually recomputed each run — otherwise TTFT collapses to ~0 and the
    # prefill t/s number is fiction. cache_prompt:false belt-and-suspenders (llama.cpp).
    content = (nonce + " " if nonce else "") + prompt + "\n\nContinue this text."
    body = json.dumps({
        "model": model,
        "messages": [{"role": "user", "content": content}],
        "max_tokens": gen,
        "temperature": 0.0,
        "stream": True,
        "cache_prompt": False,
        "stream_options": {"include_usage": True},
    }).encode()
    req = urllib.request.Request(
        base_url.rstrip("/") + "/chat/completions",
        data=body, headers={"Content-Type": "application/json",
                            "Authorization": "Bearer " + API_KEY})
    t0 = time.perf_counter()
    t_first = None
    n_tok = 0
    usage = {}
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        for raw in resp:
            line = raw.decode("utf-8", "replace").strip()
            if not line or not line.startswith("data:"):
                continue
            data = line[5:].strip()
            if data == "[DONE]":
                break
            try:
                obj = json.loads(data)
            except json.JSONDecodeError:
                continue
            if obj.get("usage"):
                usage = obj["usage"]
            choices = obj.get("choices") or []
            if not choices:
                continue
            delta = choices[0].get("delta", {})
            piece = delta.get("content")
            if piece:
                if t_first is None:
                    t_first = time.perf_counter()
                n_tok += 1
    t_end = time.perf_counter()
    if t_first is None:
        raise RuntimeError("no tokens streamed (endpoint/model wrong?)")
    ttft = t_first - t0
    decode_s = max(t_end - t_first, 1e-9)
    # prefer server-reported prompt token count; else our target estimate
    p_tok = usage.get("prompt_tokens") or 0
    g_tok = usage.get("completion_tokens") or n_tok
    return {
        "ttft": ttft,
        "decode_tps": (g_tok - 1) / decode_s if g_tok > 1 else 0.0,
        "prefill_tps": (p_tok / ttft) if (p_tok and ttft > 0) else None,
        "e2e_tps": g_tok / max(t_end - t0, 1e-9),
        "prompt_tokens": p_tok, "gen_tokens": g_tok,
        "wall": t_end - t0,
    }

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--url", required=True, help="base, e.g. http://127.0.0.1:8080/v1")
    ap.add_argument("--model", required=True)
    ap.add_argument("--prompt-tokens", type=int, default=512)
    ap.add_argument("--gen", type=int, default=128)
    ap.add_argument("--repeat", type=int, default=3)
    ap.add_argument("--warmup", type=int, default=1)
    ap.add_argument("--timeout", type=int, default=600)
    ap.add_argument("--label", default="")
    ap.add_argument("--json-out", default="")
    args = ap.parse_args()

    prompt = make_prompt(args.prompt_tokens)
    nonce = lambda tag: f"[{tag}-{os.urandom(4).hex()}]"  # unique → no prefill cache hit
    for i in range(args.warmup):
        try: one_run(args.url, args.model, prompt, min(args.gen, 16), args.timeout, nonce(f"w{i}"))
        except Exception as e: print(f"[warmup skip] {e}", file=sys.stderr)

    runs = []
    for i in range(args.repeat):
        r = one_run(args.url, args.model, prompt, args.gen, args.timeout, nonce(f"r{i}"))
        runs.append(r)
        print(f"  run {i+1}/{args.repeat}: TTFT {r['ttft']*1000:6.0f}ms  "
              f"prefill {r['prefill_tps'] or 0:6.1f} t/s  "
              f"decode {r['decode_tps']:6.2f} t/s  "
              f"(p={r['prompt_tokens']} g={r['gen_tokens']})", file=sys.stderr)

    def med(k): return statistics.median([x[k] for x in runs if x[k] is not None]) if any(x[k] is not None for x in runs) else None
    agg = {
        "label": args.label, "url": args.url, "model": args.model,
        "prompt_tokens_req": args.prompt_tokens, "gen": args.gen, "repeat": args.repeat,
        "ttft_ms": (med("ttft") or 0)*1000,
        "prefill_tps": med("prefill_tps"),
        "decode_tps": med("decode_tps"),
        "e2e_tps": med("e2e_tps"),
        "runs": runs,
    }
    print(json.dumps(agg))
    if args.json_out:
        with open(args.json_out, "w") as f: json.dump(agg, f, indent=2)

if __name__ == "__main__":
    main()
