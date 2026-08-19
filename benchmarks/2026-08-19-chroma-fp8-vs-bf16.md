# Chroma1-HD: fp8 vs bf16 on Radeon 890M (2026-08-19)

**질문**: 32GB 통합메모리(GTT 26GiB) AMD iGPU에서 Chroma1-HD를 돌릴 때
fp8을 써야 하나, bf16(레퍼런스 정밀도)이 되나?

**답**: **bf16이 되고, 속도도 fp8과 동일하다.** 32GB 기기라면 bf16을 쓰면 된다.

## 실측 (동일 조건: 시드 20260819, 26스텝, cfg 4, euler, 1024², T5-XXL fp8 scaled)

| | 파일 크기 | 총 소요 (로드+인코드+26스텝+VAE) | GTT 피크 |
|---|---|---|---|
| fp8 scaled (silveroxides hybrid rev2) | 8.6G | 667초 | 20.4 GiB |
| **bf16 (원본)** | 16.6G | **673초** | **24.3 GiB** |

- 속도 차 <1% — **RDNA 3.5는 fp8 네이티브 연산이 없어** ComfyUI가 에뮬레이션
  (`emulated ops: float8_e4m3fn`, 저널 확인). fp8은 저장만 8비트, 연산은 bf16 캐스트.
  1024² 디퓨전은 연산 바운드라 대역폭 절감도 속도로 이어지지 않음.
- bf16 피크 24.3GiB — `--reserve-vram 2` + dynamic-vram 순차 로딩(T5 인코드 후
  트랜스포머 스테이징)으로 26GiB 상한 안에서 안정 동작. gpu-guard 개입 없음.
- 결과물: 같은 시드에서 구도 동일, bf16이 원경/안개 층위가 미세하게 더 정돈.
  fp8도 체감 동급 — 품질로 fp8을 기피할 이유는 없음.

## 권장

| 상황 | 선택 |
|---|---|
| 32GB 통합메모리 (GTT 26GiB) | **bf16** — 같은 속도에 레퍼런스 품질 |
| 24GB 이하, 또는 고해상도/배치/LoRA 여유 필요 | fp8 scaled (피크 -3.9GiB) |
| NVIDIA Ada/Blackwell (fp8 네이티브) | fp8이 속도 이득 있을 것 (이 문서 범위 밖) |

## 구성 (재현)

- ComfyUI c173938, torch 2.11.0+rocm7.14.0 (설치: scripts/setup-comfyui.sh)
- UNETLoader(weight_dtype default) + CLIPLoader(type=chroma, t5xxl_fp8_e4m3fn_scaled)
  + VAELoader(Chroma 레포 동봉 diffusers VAE 160M — FLUX.1-schnell 게이트 우회)
- EmptySD3LatentImage, 소스: lodestones/Chroma1-HD (bf16, apache-2.0),
  silveroxides/Chroma1-HD-fp8-scaled, comfyanonymous/flux_text_encoders
