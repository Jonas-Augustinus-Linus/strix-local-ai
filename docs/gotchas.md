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
