# gfx1150(Radeon 890M)에서 무검열 이미지/영상 DiT 모델 실측 — 되는 것 vs 행나는 것 (2026-08-22)

## 요약 (TL;DR)

AMD Radeon 890M(gfx1150, RDNA3.5, ROCm 7.14) iGPU에서 여러 확산 모델을 스모크 테스트한 결과,
**일부 대형 DiT(Diffusion Transformer)는 샘플링 첫 스텝에서 하드 행(hang)한다.** 행의 특징:
모델 로드까지는 정상(로그에 "Requested to load …")이지만 그 뒤 **GPU 사용률이 1%로 유휴**인 채
스텝 진행이 0이고, 수백 초가 지나도 아무 출력이 없다(= 커널이 시작조차 안 됨). 메모리 초과가
아니다 — dynamic-vram으로 peak를 낮춰도 동일하게 행한다.

**되는 것**: Z-Image(6B) · Wan2.2-5B · **HunyuanVideo-1.5(8B)** · FLUX.1-dev(12B) · HiDream-Fast(17B 증류) · SDXL 전종.
**행나는 것**: Wan2.2-A14B(14B) · HiDream-Dev/Full(17B) · Qwen-Image(20B).
**경계선은 ~12-13B**: 12B 이하는 다 되고(Hunyuan 8B·FLUX 12B 포함), 14B 이상 비증류 DiT는 행.
17B HiDream은 **강하게 증류된 Fast만** 예외적으로 통과. (아래 분석)

이건 "이 하드웨어에서 실제로 뭐가 되는지"를 측정한 것으로, 같은 iGPU(Strix Point / Ryzen AI 300)
사용자가 헛되이 대형 DiT를 받지 않도록 돕기 위한 공개 데이터다.

## 하드웨어 / 환경

- AMD Ryzen AI 9 HX PRO 370 (Strix Point), iGPU Radeon 890M = **gfx1150** (RDNA3.5)
- ROCm 7.14, torch 2.11.0, ComfyUI(2026-08-18 빌드) + ComfyUI-GGUF
- 32GB LPDDR5x, 26GiB GTT. `--use-split-cross-attention` 상시(대형 토큰 SDPA 행 회피)

## 방법

각 모델을 ComfyUI API로 최소 설정(짧은 해상도/스텝)으로 제출하고, `/history`로 완료를 폴링하면서
`gpu_busy_percent`를 관찰. **컴퓨팅 중이면 GPU ~100%, 행이면 ~1% 유휴.** 행 판정은
"모델 로드 후 GPU 유휴 + 스텝 진행 0 + 수백 초 무출력". 웨지 후 ComfyUI 재시작으로 복구(재부팅 불필요).

## 결과

| 모델 | 파라미터 | 증류 | 결과 | 근거 |
|---|---|---|---|---|
| **Z-Image Turbo** | 6B | 8-step 증류 | ✅ **작동** | 1024² 8스텝 **88초**, 한복 실사 완벽 |
| **Wan2.2-TI2V-5B** | 5B | — | ✅ 작동 | 480²·33f·20step 258초(기존 측정) |
| **HiDream-I1 Fast** | 17B | 16-step 증류 | ✅ 작동 | 1024² 16스텝 431초(기존) |
| **FLUX.1-dev-abliterated** | 12B | guidance-distilled(cfg1) | ✅ 작동 | 1024² 20스텝 392-505초(기존) |
| **SDXL (Illustrious/NoobAI/Pony/…)** | ~2.6B | — | ✅ 작동 | 1-2분/장 |
| **HiDream-I1 Dev** | 17B | guidance-distilled(28step) | ⛔ **행** | DiT 로드 후 GPU 1%, 484s+ 진행 0 (gpu-only·dynamic-vram 둘 다) |
| **HiDream-I1 Full** | 17B | 비증류(50step cfg5) | ⛔ 행 | 동일 — DiT 샘플링 시작 안 됨 |
| **Wan2.2-T2V-A14B** | 14B(expert) | 비증류(2-expert) | ⛔ 행 | umt5 인코더 통과 → "Requested to load WAN21" → GPU 1% 600s+ |
| **Qwen-Image** | 20B | 비증류 | ⛔ 행 | 별도 문서 2026-08-21 (DiT 40분+ 무진행) |
| **HunyuanVideo 1.5** | 8B | — | ✅ **작동** | 512²·17f·6step **303초**, 한복 영상 성공 (VAE는 아래 주의) |

### HunyuanVideo 1.5 주의 — DiT는 되는데 VAE 디코드가 OOM
Hunyuan 8B는 **DiT 샘플링이 정상 진행**(30초/스텝, 6/6 완료)했으나, 기본 `VAEDecode`가
17프레임 512²를 한 번에 13.5GiB 할당하려다 **OOM**(프래그멘테이션으로 12.6GiB만 여유). 두 가지로 해결:
1. comfyui 서비스에 **`PYTORCH_CUDA_ALLOC_CONF=expandable_segments:True`** (예약-미할당 메모리 회수) — 상시 추가함(모든 모델에 이로움).
2. **`VAEDecodeTiled`**(tile_size 256, temporal_size 8 등)로 프레임을 청킹 디코드.
→ 둘 적용 후 303초에 완주. **DiT 호환성과 VAE 메모리는 별개 문제** — DiT가 돼도 영상 VAE는 따로 튜닝 필요.

## 분석 — 왜 어떤 건 되고 어떤 건 안 되나

- **메모리 문제가 아니다.** HiDream Dev를 dynamic-vram(인코더를 순차 오프로드해 peak를 낮춤)으로
  돌려도 동일하게 행했다. 인코더는 GPU로 빠르게 통과했고(30분 CPU 함정 아님), DiT 로드 직후 멈췄다.
- **단순 파라미터 규모도 완전한 설명은 아니다.** FLUX(12B)는 되고 Wan-A14B(14B)는 안 되며,
  HiDream-Fast(17B)는 되는데 HiDream-Dev(같은 17B)는 안 된다.
- **가장 잘 맞는 경계**: ~12B 이하 DiT는 되고, 14B 이상 비증류 DiT는 샘플링 커널이 시작조차 못 한다.
  17B HiDream은 **강하게 증류된 Fast만** 통과 — 증류가 (스텝 수가 아니라 어떤 형태로든) 문제의
  어텐션/샘플링 경로를 우회하게 해주는 것으로 추정. 정확한 커널 원인은 미규명(ROCm/HIP 어텐션
  구현이 특정 큰 DiT 형상에서 시작 안 됨). split-cross-attention은 이 계열엔 안 통한다
  (Qwen-Image에서도 무효였음).

## 실용 결론 (같은 iGPU 사용자용)

- **무검열 실사**: **Z-Image Turbo(6B, 빠르고 동아시아 강함)** + **HiDream Fast**(정밀·네거티브).
- **무검열 애니**: SDXL(Illustrious/NoobAI/Pony) 전종.
- **최고품질 FLUX**: FLUX.1-dev-abliterated(12B)까지 OK.
- **영상**: **Wan2.2-5B** + **HunyuanVideo-1.5(8B, 720p 가능·무검열, VAEDecodeTiled 필수)**. Wan2.2-A14B는 행.
- **받지 말 것(dGPU 전까지)**: Qwen-Image, HiDream Dev/Full, Wan2.2-A14B — 전부 gfx1150에서 행.
  파일은 미래 dGPU용으로 보존은 가능하나 이 iGPU에선 못 돌린다.

## 복구

행이 나면 GPU가 웨지되어 이후 작업도 행한다. **ComfyUI 재시작(`systemctl --user stop→start comfyui`)으로
해제**되며 재부팅은 불필요(firmware MES 웨지 #5993과는 다른, 소프트 큐 웨지).

## 맥락 / 관련 문서
- Qwen-Image 실용불가: [2026-08-21-qwen-image-gfx1150-impractical.md](2026-08-21-qwen-image-gfx1150-impractical.md)
- HiDream-I1 Fast 성공: [2026-08-22-hidream-i1-gfx1150.md](2026-08-22-hidream-i1-gfx1150.md)
- FLUX split-attention: [2026-08-21-flux-split-attention-gfx1150.md](2026-08-21-flux-split-attention-gfx1150.md)
- 재현 스크립트: `scripts/test-{zimage,hidream,wan-a14b,hunyuan}.py`
