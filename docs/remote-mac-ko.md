# 맥(또는 다른 기기)에서 이 컴퓨터의 AI 쓰기 — tailscale 원격

이 컴퓨터(strix, 890M+NPU)가 연산하고, 맥은 브라우저로 조작만. 같은 tailnet이면
어디서든 접속됩니다. FQDN: **amd-ai-gt-370.tail5b345c.ts.net**

## 맥 브라우저에서 접속할 주소

| 용도 | 주소 | 조건 |
|---|---|---|
| 💬 채팅 (무검열 LLM) | https://amd-ai-gt-370.tail5b345c.ts.net | 채팅 모드일 때 |
| 🖼️ 이미지 생성 | https://amd-ai-gt-370.tail5b345c.ts.net:8444/simple-image.html | **이미지 모드일 때** |
| ⚙️ ComfyUI 본체 | https://amd-ai-gt-370.tail5b345c.ts.net:8445 | 이미지 모드일 때 |
| 🔌 LLM API | https://amd-ai-gt-370.tail5b345c.ts.net:8443/v1 | 채팅 모드일 때 |

## ⚠️ 핵심: GPU 모드에 따라 뭐가 켜지는지 다름

이 컴퓨터는 GPU가 하나라 채팅과 이미지를 동시에 못 켭니다.
- **채팅**을 맥에서 쓰려면 → strix가 채팅 모드 (`gpu-mode chat`)
- **이미지**를 맥에서 쓰려면 → strix가 이미지 모드 (`gpu-mode image`)

맥에서 이미지 페이지(:8444)를 열었는데 안 되면, strix가 채팅 모드일 가능성.
strix에서 `gpu-mode image` 하거나, 원격 전환을 원하면 아래.

## 맥에서 원격으로 GPU 모드 전환 (선택)

SSH로 트리거:
```bash
ssh amd-ai@amd-ai-gt-370.tail5b345c.ts.net 'systemctl --user start comfyui'   # 이미지 모드
ssh amd-ai@amd-ai-gt-370.tail5b345c.ts.net 'systemctl --user stop comfyui'    # 채팅 복귀
```
(SSH는 tailscale SSH나 일반 sshd 설정 필요 — 미설정이면 strix에서 직접 전환)

## serve 관리 (strix에서)

```bash
tailscale serve status              # 노출 현황
tailscale serve --https=8444 off    # 이미지 페이지 노출 끄기
tailscale serve --https=8445 off    # ComfyUI 노출 끄기
```
serve는 재부팅에도 유지됩니다. **절대 `funnel`은 쓰지 말 것** (인터넷 전체 공개 금지).

## 동작 원리
- 이미지 페이지는 접속 호스트를 감지: localhost면 8188 직접, tailnet이면 :8445로 ComfyUI 호출
- 연산은 전부 strix(890M)에서 — 맥은 화면·업로드·다운로드만
- 무검열 스택이 맥에서도 그대로 (검열 없는 이미지/채팅)
