# 함정 노트 (gotchas)

삽질을 반복하지 않기 위한 기록. 날짜와 llama.cpp 빌드를 함께 적는다.

## G1. 새 `llama-cli`는 TUI 앱 — 스크립트에서 쓰지 말 것 (build 10449+)

2025년 말 llama.cpp가 CLI를 재편하면서 `llama-cli`는 대화형 TUI 앱이 됐다.
비-TTY(파이프/리다이렉트) 환경에서 로딩 스피너가 무한 출력됨 — 실측 120초에
**1.7GB**의 스피너 문자를 뿜었다. 스크립트/원샷 생성에는 **`llama-completion`**을
사용할 것 (기존 llama-cli 인자 체계 그대로: `-no-cnv`, `-p`, `-n`, `-c`).

## G2. `-c` 기본값 0 = 모델 최대 컨텍스트 → KV 캐시 폭발

`-c`(ctx-size) 기본값이 0이고, 0은 "모델이 선언한 최대치"다. Qwen3-4B는 262,144
토큰이라 KV 캐시만으로 RAM ~19GB를 잡아먹는다. **항상 `-c`를 명시**할 것
(일상 4096~16384, 서버는 serve.sh가 8192 지정).

## G3. Qwen 공식 GGUF 레포 부재 (2507 세대)

`Qwen/Qwen3-4B-Instruct-2507-GGUF`는 존재하지 않음 (HF가 401 반환 — 없는 레포도
401로 응답하니 인증 문제로 오독하지 말 것). unsloth/ 또는 bartowski/ 미러 사용.

## G4. `pkill -f`는 자기 자신도 죽인다

패턴이 자기 셸 명령줄에 포함되면 래퍼 셸까지 죽는다. PID를 찾아 직접 kill 할 것.

## G5. Vulkan 빌드에 SPIRV-Headers 필요 + include 경로 미전파 (build 10449+)

`ggml-vulkan`이 `find_package(SPIRV-Headers CONFIG REQUIRED)`를 요구하는데, 우분투
`glslc`/`libvulkan-dev`에는 없다. 해법: `spirv-headers` apt 패키지 또는 KhronosGroup
소스를 `~/.local`에 설치. 단, llama.cpp가 find만 하고 **include 경로를 타깃에 연결하지
않아** 비표준 경로면 `-DCMAKE_CXX_FLAGS="-isystem $HOME/.local/include"` 주입 필요
(setup-llamacpp.sh가 자동 처리). 업스트림 개선 기여 후보.

## G6. RAM보다 큰 모델을 Vulkan 빌드로 로드하면 시스템이 죽는다 (2026-08-16 실측)

35GB Q8 GGUF를 Vulkan 빌드 `llama-imatrix`로 로드 → mmap 프리페치가 수 초 만에
RAM(29.5GiB)을 플러딩 → amdgpu CS ioctl ENOMEM → `Not enough memory for command
submission!` 무한 스팸 + DeviceLost. GTT가 비어 있어도, `--n-cpu-moe`를 아무리 올려도
(24/32/999 전부 재현) 발생 — 오프로드 분할의 문제가 아니라 **로드 자체**의 문제.
최악의 경우 데스크톱 컴포지터까지 연쇄 실패해 시스템 행 → 강제 전원(ext4 복구).
해법: RAM 초과 모델의 imatrix/평가는 **CPU 빌드**로 (mmap 스트리밍은 GPU가 없으면
안전). 라우터 모델이 무사한 이유: RAM에 들어가는 크기 + `--no-mmap`.
행 걸리면: 초반 수 분은 반응하니 프로세스 kill → 안 되면 Alt+SysRq+S,U,B.

## G7. ComfyUI ROCm: torch는 2.11.0 라인만 가능 — 2.12 불가 (2026-08-18 실측)

ComfyUI가 torchaudio를 하드 요구(comfy/ldm/lightricks/vae/audio_vae.py)하는데
AMD 휠 인덱스에 torchaudio 2.12가 없고 PyPI torchaudio는 2.9.1로 끝(메인터넌스).
torch 2.12 + ta 2.11.x, 그리고 ta 2.11.0.2까지도 `undefined symbol:
torch_exception_get_what_without_backtrace` (ABI 불일치). **정확히
torch 2.11.0 / torchvision 0.26.0 / torchaudio 2.11.0 (+rocm7.14.0) 조합만 작동.**
셋 다 +rocm 로컬버전으로 핀 고정할 것 (PyPI CUDA 빌드 혼입 차단). AMD 휠은
cp310~313만 있으므로 시스템 python 3.14 불가 — uv 관리 3.12로 venv.

## G8. ComfyUI `--force-shared-vram` 플래그는 존재하지 않는다 (2026-08-18)

2026-08-15 리서치 노트에 있던 플래그인데 현 ComfyUI(c173938)에는 없음.
`--enable-dynamic-vram --disable-mmap --cache-none --bf16-vae --reserve-vram 2` 사용.
동적 VRAM이 890M을 native로 잡고 GTT 26GiB 전체를 VRAM으로 인식한다.

## G9. systemd Conflicts + ExecStopPost의 블로킹 systemctl start = 데드락

comfyui.service(Conflicts=llama-router)의 ExecStopPost에서 `systemctl --user start
llama-router`를 블로킹으로 호출하면: router 시작 잡은 comfyui 정지 완료를 기다리고,
comfyui 정지는 ExecStopPost 종료를 기다림 → 상호 대기 → TimeoutStopSec 후 SIGKILL,
유닛은 failed(timeout). **`--no-block` 필수.** 증상: stop이 90초 걸리고 Result=timeout.

## G10. FLUX(GGUF)는 SDXL과 완전히 다른 그래프 — cfg·scheduler·VAE·latent 전부 주의 (2026-08-20 실측)

890M에서 FLUX.1-dev abliterated GGUF Q6_K 실측: 1024²·20스텝 505초, GTT 피크 13.8G(여유 큼).
단, SDXL 습관대로 짜면 깨진다:

- **cfg는 반드시 1.0** — FLUX-dev는 guidance-distilled라 real CFG(>1)를 쓰면 스텝당 연산 2배 +
  분포가 깨진다. 강도는 `FluxGuidance` 노드(≈3.5)로만 준다. 네거티브는 cfg=1에서 무시됨(빈 문자열).
- **scheduler=simple**(또는 beta/sgm_uniform), **euler**. SDXL의 karras/euler_ancestral 쓰면 품질 붕괴.
- **VAE는 bf16**(`--bf16-vae`). FLUX 16채널 VAE를 fp16으로 디코드하면 오버플로 → 검은/NaN 이미지.
- **latent은 `EmptySD3LatentImage`(16채널)**. SDXL의 `EmptyLatentImage`(4채널) 아님.
- **텍스트 인코더**: `DualCLIPLoader`(t5xxl_fp8 + clip_l, type=flux). Wan용 **umt5는 재사용 불가**
  (다른 모델). Chroma가 쓰던 t5xxl은 공유 가능. `clip missing: text_projection.weight` 경고는 무해.
- **`HSA_OVERRIDE_GFX_VERSION` 설정 금지** — gfx1150은 ROCm 7.14/torch 2.11에서 native 타깃이라
  11.0.0 오버라이드가 오히려 잘못된 커널을 고를 수 있다. 기존 `--enable-dynamic-vram`로 충분.
- **모델 특성**: abliterated 판은 무검열 방향으로 과편향 → 옷 지시("wearing ○○")를 무시하고 누드로
  갈 때가 있다. SFW는 "fully clothed" 강조 또는 SDXL 사용.

## G11. FLUX DiT를 1024 초과 해상도로 직접 돌리면 ROCm 큐가 wedge된다 (2026-08-21 실측)

890M(gfx1150)에서 FLUX.1-dev GGUF는 **1024²까지만 안정**. 네이티브 1536²(또는 hires의 latent 2차패스처럼 DiT를 큰 latent로 재실행)를 하면:

- KSampler가 **GPU busy 1~2%로 멈춤**(샘플링 안 들어감). 처음엔 1시간46분 방치 후 발견.
- `/interrupt`로 안 풀리고, 프로세스가 **SIGKILL로도 안 죽는 D-state**(GPU 커널에 물림)로 남아 ROCm 큐를 점유.
- 이후 **정상 설정(Q6/1024)조차 같은 지점에서 행** → ROCm/HIP 큐 wedge.
- **중요 구분**: 채팅(llama.cpp=**Vulkan** 백엔드)은 계속 정상. wedge는 **ComfyUI=ROCm/PyTorch** 경로에 국한. 즉 amdgpu 자체는 안 죽음.
- **복구**: 재부팅이 확실. (D-state 프로세스는 프로세스 재시작으로 안 풀림.)
- `--use-pytorch-cross-attention` 플래그는 **해결 못 하고 오히려 1024까지 망가뜨림** → 쓰지 말 것.

**대책(코드에 반영):** FLUX는 해상도 상한 1024, 고해상은 **DiT 재패스 금지 → ESRGAN 모델 업스케일러(4x-UltraSharp, 픽셀공간, DiT 안 거침)**로. Q8도 이 GPU에선 이점 없이 위험만 커서 미채택(Q6_K로 충분, 육안 차 거의 없음).
