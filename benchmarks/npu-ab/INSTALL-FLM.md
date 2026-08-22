# FastFlowLM (FLM) 설치 — 이 머신 맞춤 (Strix Point / Ubuntu 26.04)

> FLM = AMD Ryzen AI **NPU 전용** LLM 런타임 (Ollama류, XDNA2에서 CPU/GPU 부하 0).
> 서버 모드는 OpenAI 호환, 기본 포트 **52625**.

## 이 머신은 전제조건을 이미 다 충족 (2026-08-22 확인)

| 요구사항 | 필요 | 이 머신 | 상태 |
|---|---|---|---|
| 커널 | ≥ 6.14 | 7.0.0-30 | ✅ |
| amdxdna 드라이버 | 로드됨 | `lsmod` 3개 로드 + `/dev/accel/accel0` | ✅ |
| XRT | libxrt-npu2 | 2.21.75 | ✅ |
| NPU 펌웨어 | — | 1.1.2.64 | ✅ |
| memlock | unlimited | unlimited | ✅ |
| OS | Ubuntu 24.04+ | 26.04 (resolute) | ✅ |

**→ 드라이버/재부팅 단계 전부 스킵. FLM 패키지(.deb) 하나만 얹으면 끝.**

## 설치 (사용자 직접 실행 — sudo)

프롬프트에서 `! 명령` 으로 실행하거나 터미널에 붙여넣으세요.
비번은 **영문 키보드**로 입력 (한글 IME 켜져 있으면 깨짐 — 과거 사고 있었음).

```bash
# 1) FLM v1.0.2 .deb (Ubuntu 26.04용) 내려받기
cd ~/Downloads
wget https://github.com/ROCm/FastFlowLM/releases/download/v1.0.2/fastflowlm_1.0.2_ubuntu26.04_amd64.deb

# 2) 설치 (의존성은 이미 충족, apt가 알아서 처리)
sudo apt install ./fastflowlm_1.0.2_ubuntu26.04_amd64.deb

# 3) NPU 검증 — 펌웨어/memlock OK 떠야 함
flm validate
```

`flm validate` 가 통과하면 준비 끝.

## 스모크 테스트 (사용자 or 나)

```bash
flm list                 # 지원 모델 태그 확인 (matrix에 넣을 정확한 id)
flm pull qwen3:4b        # 4B부터 (가장 빠름)
flm run  qwen3:4b        # REPL — 프롬프트 치면 t/s 출력됨
# 서버 모드 (A/B 하니스가 이걸 씀):
flm serve qwen3:4b       # → http://127.0.0.1:52625  (OpenAI 호환)
```

## 설치 직후, 실측 하니스 발사

```bash
cd ~/strix-local-ai/benchmarks/npu-ab
flm list                 # ← 실제 태그 확인 후 run_ab.sh 의 MODELS 배열 수정
./run_ab.sh 2026-08-22   # iGPU(Vulkan) vs NPU(FLM) 자동 측정 → RESULTS.md
```

하니스가 하는 일:
- comfyui/llama-router 정지(GPU/NPU 확보) → 모델별로 iGPU 서버·NPU 서버를
  차례로 띄우고 **동일 OpenAI 스트리밍 클라이언트**로 TTFT·prefill·decode t/s 측정
- iGPU는 `llama-bench` 원시 수치도 교차검증(커뮤니티 표준 레퍼런스)
- `results/*.json` + `RESULTS.md`(공개용, 시크릿/테일넷주소 없음) 생성
- 종료 시 라우터 자동 복원(chat 모드로 돌아옴)

## 주의
- **포트 52625**가 FLM 기본. `run_ab.sh`는 8081로 서브(충돌 회피) — `flm serve --port` 플래그는
  설치 후 `flm --help`로 확인해서 맞추면 됨(없으면 기본 52625로 두고 하니스 포트만 맞출 것).
- NPU(FLM)와 iGPU(llama.cpp)는 **다른 실리콘**이지만 **같은 LPDDR5x 대역폭**을 공유 →
  decode(대역폭 바운드) 비교가 이 벤치의 핵심.
