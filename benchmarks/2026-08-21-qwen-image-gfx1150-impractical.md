# Qwen-Image (20B) 로컬 배선 시도 — gfx1150에서 현재 실용 불가 (2026-08-21)

## 결론 (TL;DR)

Radeon 890M (gfx1150, RDNA 3.5) + ROCm 7.14 + torch 2.11 + ComfyUI에서
**Qwen-Image(base T2I, 20B MMDiT)를 로컬 배선했으나 실용적으로 돌리지 못했다.**
1024² 한 장이 **40분+ (2400s 타임아웃 초과)** 걸려, 이 하드웨어에선 현재 부적합.
부정 결과지만 다음 사람을 위해 기록한다 (무엇이 막고, 무엇을 시도했고, 다음 레버가 뭔지).

FLUX.1-dev는 같은 박스에서 잘 돈다 (Q8 1024 ~7분, 1536 ~19분). 차이는 아래.

## 배선 자체는 성공 (파일·워크플로 다 맞음)

3-에이전트 조사(wf_830ad30f)로 정확한 레시피 확정, 파일 다 확보·검증:
- DiT: city96/Qwen-Image-gguf Q6_K(15.7G)/Q8_0(20.3G)
- VAE: Comfy-Org qwen_image_vae.safetensors (16채널, **fp32 필수** — fp16/bf16 black/NaN)
- 워크플로: UnetLoaderGGUF → ModelSamplingAuraFlow(shift 3.1) → KSampler(euler/simple/cfg 2.5/20step, 진짜 네거티브) ← CLIPLoaderGGUF(type=qwen_image) ×2, EmptySD3LatentImage(16ch)
- CLIPLoaderGGUF가 type=qwen_image 지원 확인 ✓

## 두 개의 벽

### 벽 1 — Qwen2.5-VL 7B 텍스트 인코더가 CPU 병목
Qwen-Image는 텍스트 인코더로 **Qwen2.5-VL-7B**(디코더 LLM)를 쓴다. FLUX의 T5(encoder-only 4.7B)와 달리 무겁고, 이 ComfyUI 빌드의 **DynamicVRAM(기본 활성)이 인코더를 CPU에 스테이징** → 인코딩이 **~30분** (단일코어 CPU 91%, GPU 1%). 시도:
- INT8 safetensors 인코더(ethanfel ConvRot): CPU, 느림
- GGUF 인코더(mradermacher Q8_0): 여전히 CPU, 느림 (포맷 무관 — DynamicVRAM 스테이징이 원인)
- `--enable-dynamic-vram` 제거: 무효 (빌드 기본 활성이라 안 꺼짐)
- **`--gpu-only`: 인코딩을 GPU로 옮기는 데 성공** (인코더 로드→DiT 로드 12초). 하지만 →

### 벽 2 — DiT 샘플링이 gfx1150에서 행/극도 저속
`--gpu-only`로 인코딩을 넘긴 뒤, **DiT(QwenImage MMDiT) 샘플링에서 40분간 진행 로그 0** → 타임아웃.
FLUX의 대토큰 행을 고친 **`--use-split-cross-attention`이 Qwen엔 안 통한다** (FLUX는 표준 DiT, Qwen은 MMDiT+AuraFlow 샘플링 = 다른 커널 경로). peakGTT 16.5G(DiT는 로드됨, OOM 아님) — 순수 compute 행/저속.

## 시도한 구성 요약

| 구성 | 인코딩 | DiT 샘플링 | 결과 |
|---|---|---|---|
| dynamic-vram + INT8 enc | CPU ~30min | — | 타임아웃 |
| dynamic-vram + GGUF enc | CPU ~30min | — | 타임아웃 |
| (no dynamic-vram) + GGUF | CPU (기본활성) | GPU 도달했으나 | 타임아웃 |
| **--gpu-only + GGUF** | **GPU 빠름** | **행/저속(로그 0)** | 타임아웃 |

## 다음 레버 (미시도 — 향후/더 나은 HW에서)

1. `--use-quad-cross-attention` — Qwen MMDiT에 sub-quadratic attention이 통할 가능성 (split은 실패)
2. Qwen-Image **distilled** + **Lightning 4/8-step LoRA** — 샘플링 스텝 감소로 저속 완화 (행이 아니라 저속이면 유효)
3. 더 작은 인코더 Q4 + `--gpu-only` — 인코딩 메모리 절감
4. ComfyUI/ROCm 업스트림 개선 대기 (Qwen-Image gfx115x 지원)

## 권고: 대안

- **HiDream-I1** — DiT 더 가벼움(Q5 12.1G), 인코더는 Llama-3.1-8B(abliterated 스왑) + T5 + CLIP. Qwen보다 성숙한 무검열 생태계(e-n-v-y 전용 파인튜닝). 단 4-인코더 셋업 복잡.
- **현행 유지**: 한복·동아시아 SFW는 **SDXL(Animagine/Illustrious/NoobAI, 네거티브 있음)** 로 충분히 됨. FLUX는 실사 품질용(무검열, 단 인물 서구·누드 편향).

## 배경

이 시도의 출발: 사용자가 "Grok Image 2.0 로컬 대안"을 원했고, Qwen-Image가 타이포/동아시아 강점으로 후보였음. FLUX의 서구·누드 편향(네거티브 없어 억제 불가, [2026-08-21 배치 실험] 참조)을 Qwen의 진짜-CFG+네거티브로 넘으려던 것. Qwen이 못 돌아, 그 역할은 당분간 SDXL이 담당.
