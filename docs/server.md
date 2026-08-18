# AI 허브 서버 아키텍처

이 머신을 테일넷의 프라이빗 AI 허브로 운영하는 구성. 속도보다 프라이버시/안정성 우선.

```
[테일넷 디바이스들]  iPhone / MacBook / Mac Studio / Windows / 에이전트들
        │  (WireGuard 암호화, 테일넷 전용 — funnel 절대 금지)
        ▼
[tailscale serve]  https://<your-machine>.<your-tailnet>.ts.net
        ├─ :443  → 127.0.0.1:3000  Open WebUI (채팅 UI)
        └─ :8443 → 127.0.0.1:8080  OpenAI 호환 API (자동화/에이전트용)
        ▼
[llama-router.service]  (systemd user, linger로 상시)
   llama-server 라우터 모드: --models-dir ~/models --models-preset server/models.ini
   API 키: ~/.config/llama-api-key (Bearer)
        │  요청의 "model" 필드로 라우팅, 온디맨드 로드/언로드
        ├─ gemma4-26b-a4b        주력 (리즈닝+비전, budget 2048, 부팅 시 로드)
        ├─ gpt-oss-20b-MXFP4     추론 특화
        └─ Qwen3-4B-...-Q4_K_M   경량 고속
```

## 핵심 결정과 이유

- **`--models-max 1`**: 라우터 모드는 단독 실행보다 VRAM을 더 쓰고(#20582), 동시 요청 시
  max가 안 지켜지는 레이스(#20137)가 있음. GTT 26GB에서 대형 2개 동시 로드는 OOM →
  MES 웻지 위험이라 1개로 고정. 모델 전환 ~10-30초는 감수 (속도 비핵심).
- **reasoning-budget = 2048 (Gemma)**: 무제한이면 자동화 호출이 사고만 하다 max_tokens 소진.
- **Open WebUI는 --network=host**: llama-server가 127.0.0.1 바인딩이라 host-gateway로는
  도달 불가. 인증 유지(첫 계정=관리자, ENABLE_SIGNUP=false) — 테일넷 전원이 관리자가 되는
  WEBUI_AUTH=false는 금지 (Functions = 임의 코드 실행 권한).
- **tailscale serve 2포트** (경로 라우팅 대신): 일부 OpenAI 클라이언트가 경로 포함
  base URL을 잘못 다루고 WebUI는 서브패스에서 깨짐. serve 설정은 재부팅에도 유지됨.
- 텔레메트리 전부 차단 (SCARF_NO_ANALYTICS, DO_NOT_TRACK, ANONYMIZED_TELEMETRY,
  버전 체크 오프).

## 클라이언트 설정 (모든 테일넷 디바이스/에이전트 공통)

```
Base URL : https://<your-machine>.<your-tailnet>.ts.net:8443/v1
API Key  : ~/.config/llama-api-key 내용
모델 이름 : gemma4-26b-a4b | gpt-oss-20b-MXFP4 | Qwen3-4B-Instruct-2507-Q4_K_M
```

## 운영 명령

```bash
systemctl --user status|restart llama-router   # 라우터
docker logs -f open-webui                      # WebUI 로그
tailscale serve status                         # 노출 상태
curl -H "Authorization: Bearer $(cat ~/.config/llama-api-key)" \
  http://127.0.0.1:8080/v1/models              # 모델/로드 상태
```

## 주의 (라우터 모드 알려진 이슈)

- 동시에 서로 다른 모델을 부르는 클라이언트가 여럿이면 전환 직렬화 필요 (#20137)
- GET 엔드포인트도 자동 로드를 유발 — 모니터링은 `&autoload=false` (#23096)
- 전환이 멈추면: `POST /models/unload` 또는 서비스 재시작 (#24960)
- 모델 추가 후엔 서비스 재시작 (또는 `GET /models?reload=1`)
