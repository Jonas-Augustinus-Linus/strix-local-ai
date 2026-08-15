# llama.cpp Vulkan(RADV) 튜닝 — Radeon 890M / Strix Point (2026-08 조사)

890M(gfx1150, RDNA 3.5) + RADV + GTT 26GB 조건의 검증된 설정. 출처는 llama.cpp
이슈/PR 번호로 표기.

## 권장 플래그

| 플래그 | 값 | 근거 |
|---|---|---|
| `-ngl` | 99 | UMA/GTT라 전체 오프로드가 거의 항상 정답 |
| `--flash-attn` | **on** (A/B 필수) | PR #19625(2026-02, Wave32 scalar FA)로 RDNA3.5에서 FA가 이득으로 반전. 깊은 컨텍스트 pp +10~23%. 모델별로 `llama-bench -fa 0,1` 확인 |
| `-ub` | 512~1024 | 2048+는 DeviceLost 위험 (#20515, #21724 — APU에서 한 submission이 amdgpu 2000ms 타임아웃 초과) |
| `--no-mmap` | 전체 오프로드 시 사용 | 가중치가 GTT로 복사되므로 mmap 페이지캐시는 이중 사본 (#21112). 부분 오프로드 시에는 mmap 유지 |
| `-dev` | Vulkan0 | 혼합 백엔드 빌드에서 디바이스 고정 |
| `-ctk/-ctv q8_0` | 벤치 후에만 | 양자화 KV의 FA 고속 경로는 coopmat2(NVIDIA) 전용 — RADV에선 오히려 손해 가능 |

## 환경 변수

- `GGML_VK_VISIBLE_DEVICES=0` — llvmpipe 등 다른 ICD 배제
- `AMD_VULKAN_ICD=RADV` — AMDVLK 강제 배제 (gfx115x에서 >2GiB 단일 버퍼 실패 #15054)
- `GGML_VK_ALLOW_GRAPHICS_QUEUE=1` — tg +5~10% (PR #20551/#20599, 기본 OFF).
  **헤드리스 전용** — 데스크톱 컴포지터를 굶겨 프레임 드랍 유발
- `GGML_VK_FORCE_MAX_ALLOCATION_SIZE` — 대형 KV 할당 실패 시 낮춰서(예: 2GiB) 버퍼 분할 유도 (#13024, #15120)
- 커널 부트 파라미터: `amdgpu.lockup_timeout=60000` — 큰 FA/ubatch submission의 2000ms 링 리셋 방지 (#21724)

## 이 실리콘의 함정 (중요)

- **MES 웻지**: gfx1150에서 10~20시간 연속 GPU 컴퓨트 후 MES 스케줄러(Ring 13)가
  복구 불가로 웻지됨 (amd-gfx 2025-12 보고, ROCm#5724/#6165, 완전한 픽스 없음 2026-08 기준).
  완화: linux-firmware 2026-04+ (MES 0x86+), **LLM 추론 + 이미지 생성 동시 부하 금지**,
  장시간 작업은 체크포인트.
- **Vulkan은 GTT 여유량을 정확히 못 읽음** (#15120) — 26GB 중 몇 GB는 항상 여유로 남기고
  `amdgpu_top`으로 감시.
- **Ollama 금지**: 벤더링된 llama.cpp가 Wave32 FA/graphics-queue 미포함 → 업스트림 대비
  ~56% 느림 (ollama#15601).
- 890M 관련 열린 버그: #19842(VkDevice 누수), #19471(Kimi-Linear 대형 ctx assert),
  #24432(RADV STRIX1 lost-context) — 이상 동작 시 설정 탓하기 전에 확인.
- ROCm 비교: pp는 ROCm이 앞서지만(7B 기준 333 vs 268) tg와 안정성은 Vulkan 우위 —
  일상 드라이버는 Vulkan/RADV 유지.
