# 미해결 쟁점 — Strix Point NPU vs iGPU, 실측으로 공개 결론내기

로컬 LLM을 AMD Ryzen AI(XDNA2) NPU에서 돌리는 게 iGPU 대비 실익이 있는가에 대해
생태계에 **측정 없는 주장**이 많다. 이 저장소는 **한 대의 레퍼런스 머신**에서 재현 가능한
숫자로 각 쟁점을 닫는다. (하드웨어: Ryzen AI 9 HX PRO 370 · Radeon 890M gfx1150 ·
XDNA2 aie2p · 32GB LPDDR5x · Ubuntu 26.04 · kernel 7.0 amdxdna.)

## 왜 이게 아직 열려 있나

NPU와 iGPU는 **다른 실리콘이지만 같은 메모리 컨트롤러**를 공유한다. LLM decode는
가중치를 매 토큰 훑는 **대역폭 바운드** 작업이라, "NPU가 전용 가속기니까 빠르다"는
직관이 decode에서는 성립하지 않을 수 있다. 반대로 prefill은 **연산 바운드**라 NPU의
systolic MAC이 크게 이길 여지가 있다. 그런데 대부분의 벤치가 이 둘을 안 나눈다.

## 쟁점 목록 (measured)

### Q1. NPU decode t/s > iGPU decode t/s 인가? *(load-bearing)*
- **주장**: FLM은 "NPU에서 CPU/GPU 부하 0으로 빠르게" 돌린다.
- **반론**: decode는 대역폭 바운드 → 같은 LPDDR5x면 iGPU Vulkan(FA on)과 대동소이하거나
  오히려 iGPU가 캐시/유닛 수로 앞설 수 있다.
- **측정**: 동일 프롬프트(512 tok)·동일 gen(128)·동일 OpenAI 스트리밍 클라이언트로
  양측 decode t/s 중앙값. `NPU/iGPU` 비율이 결론.

### Q2. NPU prefill 우위는 얼마나 큰가?
- prefill은 연산 바운드 → NPU가 이겨야 정상. **얼마나** 이기는지가 RAG/롱컨텍스트
  비용을 좌우.
- **측정**: prefill t/s = prompt_tokens / TTFT, 양측 비교.

### Q3. TTFT (첫 토큰까지)
- 채팅 체감 반응성. 512-tok 프롬프트에서 양측 TTFT(ms).

### Q4. 27B가 어느 쪽에서든 쓸 만한가?
- 예측: decode ~3.5-5 t/s로 경계선. FLM이 27B급을 지원하면 헤드라인 A/B.
- **측정**: 27B 행 추가, <~4 t/s면 borderline 판정.

### Q5. (후속) 하이브리드 — NPU+iGPU 동시 구동은 대역폭 경합으로 상쇄되나?
- 둘 다 같은 메모리 대역을 먹으므로 동시 구동이 합산 처리량을 안 줄 수 있음.
- 1차 A/B 끝난 뒤 별도 측정.

## 방법론 (재현성)
- iGPU: `llama.cpp` Vulkan 백엔드, `-fa 1 -ngl 99`, Q4_K_M (라우터 실사용 설정과 동일).
- NPU: `FastFlowLM` native W4A16, `flm serve`.
- 각 백엔드의 **native 최적 양자화**로 비교 = 사용자가 실제로 마주하는 선택(비트 동일 X,
  현실 동일 O). 원시 `llama-bench` 수치도 교차검증으로 첨부.
- 3회 중앙값, warmup 1회. 스크립트/원시 JSON 전부 공개. 시크릿·테일넷 주소 없음.

## 산출물
- `RESULTS.md` — 표(자동 생성). `results/*.json` — 원시 per-run.
- 실행: `./run_ab.sh <날짜>` (INSTALL-FLM.md 참조).

> 게시 대상: `ryzen-npu-linux` (공개). 이 문서와 표만 올리고, 서버/인증/테일넷 관련은 제외.
