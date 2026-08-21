# ComfyUI 사용 설명서 (초보자용, 한국어)

ComfyUI는 `localhost:8188`에서 열립니다. 처음엔 복잡해 보이지만, **딱 몇 곳만
알면** 됩니다. 우리가 미리 만들어 둔 워크플로(`strix-SDXL`)를 기준으로 설명합니다.

> **먼저**: 바탕화면 "Strix-AI-이미지" 아이콘을 누르거나 터미널에 `gpu-mode image`
> → 그다음 브라우저에서 `localhost:8188`

---

## 1. 화면 구조 (한눈에)

ComfyUI 화면은 **상자(노드)들이 선으로 연결된 그림**입니다. 각 상자가 한 단계예요:

```
[체크포인트]→[프롬프트]→[샘플러]→[VAE 디코드]→[이미지 저장]
 (모델 선택)  (뭘 그릴지)  (실제 생성)  (그림 만들기)  (저장)
```

- **마우스 휠**: 확대/축소
- **빈 곳 드래그**: 화면 이동
- **상자 드래그**: 상자 위치 옮기기

## 2. 우리 워크플로 불러오기 (처음 한 번만)

1. 화면 **왼쪽 세로줄의 📁 폴더 아이콘**(Workflows) 클릭
2. **`strix-SDXL`** 클릭 → 상자들이 화면에 나타남
3. 한 번 불러오면 브라우저가 기억함 (다음부터 자동)

## 3. 그림 그리기 (매번 하는 것)

우리 워크플로에는 한글로 이름 붙은 상자가 있습니다:

1. **"긍정 프롬프트 (여기에 그릴 것)"** 상자 → 그리고 싶은 걸 영어 태그로 입력
   - 예: `1girl, long white hair, blue eyes, kimono, cherry blossoms, detailed`
   - ⚠️ **한국어 문장은 잘 안 됩니다.** 영어 단어를 쉼표로 나열하세요
2. **"부정 프롬프트 (빼고 싶은 것)"** → 그대로 두셔도 됩니다
3. 화면 아래(또는 오른쪽 위)의 **▶ Queue / 실행 버튼** 클릭
4. 잠시 후 **Save Image 상자**에 그림이 뜸 → `~/사진/strix-ai`에도 자동 저장

## 4. 자주 바꾸는 것들

| 바꾸고 싶은 것 | 어디서 |
|---|---|
| **모델** (Animagine/Illustrious/NoobAI/Pony/RealVisXL) | "Load Checkpoint" 상자의 드롭다운 |
| **크기** | "Empty Latent Image" 상자 (width/height, 세로면 832×1216) |
| **여러 장** | "Empty Latent Image"의 batch_size 를 2~4로 |
| **품질(스텝)** | "KSampler" 상자의 steps (24~30, 높을수록 세밀·느림) |
| **랜덤/고정** | "KSampler"의 seed 옆 control: randomize(매번 다름)/fixed(같음) |

**설치된 모델 5종** (Load Checkpoint 드롭다운):
- **Animagine XL 4.0** — 애니 최고급 (기본 추천)
- **Illustrious XL v2.0** — 애니/일러스트 범용
- **NoobAI XL v1.1** — 애니, 다양한 화풍
- **Pony Diffusion V6 XL** — 애니/서양풍 (score 태그 필수)
- **RealVisXL V5** — 실사 최고급 (사진풍)

## 5. 품질 올리는 핵심 태그

**맨 앞에 품질 태그를 붙이면 확 좋아집니다:**
- Illustrious/NoobAI: `masterpiece, best quality, amazing quality, very aesthetic, absurdres,`
- Animagine XL 4.0: `masterpiece, high score, great score, absurdres,`
- **Pony는 반드시**: `score_9, score_8_up, score_7_up,` (이거 없으면 품질 급락!)
- **RealVisXL V5 (실사)**: `photorealistic, RAW photo, best quality, 8k uhd,` — 실사 전용이니 **애니 태그(masterpiece 등)는 쓰지 마세요**

자주 쓰는 태그:
- 인물: `1girl` `1boy`, `long hair`, `blue eyes`, `smile`, `dress`, `kimono`
- 배경: `forest`, `city`, `night`, `sunset`, `cherry blossoms`, `mountains`
- 분위기: `detailed`, `cinematic lighting`, `beautiful`, `scenery`, `masterpiece`

**영어가 어려우면**: 채팅(WebUI)에서 LLM한테 "벚꽃 정원의 흰머리 소녀를 danbooru
태그로 만들어줘" 하면 정확한 태그를 만들어 줍니다. (채팅 모드로 전환 필요)

## 6. 사진/자세 참조로 그리기 (ControlNet — 이미 설치됨)

X에서 본 "관절 사진 → 그 자세로", "참조 사진 → 같은 구도로" 같은 건
**ControlNet**입니다. **이미 설치·작동 중**이며, 가장 쉬운 사용처는 간단 페이지
`localhost:8189/simple-image.html`입니다 (ComfyUI 본체보다 편함):

1. 페이지에서 **ControlNet 드롭다운**을 엽니다 — 두 가지:
   - **자세(pose / OpenPose)**: 관절·포즈를 따라 그림
   - **구도(canny)**: 참조 사진의 윤곽·구도를 따라 그림
   - 💡 **자세 재현은 '구도(canny)'가 더 정확**합니다. 포즈까지 확실히 잡고
     싶으면 canny를 먼저 써 보세요.
2. **참조 사진 업로드**: 따라 하고 싶은 포즈/구도 사진을 올립니다.
   (사진이 없으면 **예시 프리셋** 버튼으로 바로 시험 가능)
3. **강도 슬라이더**: 높이면 참조를 더 강하게 따르고, 낮추면 자유롭게 그립니다.
   (보통 0.5~0.8 정도)
4. 프롬프트를 넣고 생성하면 참조 자세/구도대로 그려집니다.

설치된 모델: `models/comfyui/controlnet/`에 OpenPose + Union(canny)이 들어 있어
추가 설치 없이 바로 됩니다. ComfyUI 본체에서 직접 노드로 쓸 수도 있습니다.

## 7. 문제 해결

- **화면이 비었다** → 폴더 아이콘에서 strix-SDXL 다시 불러오기
- **"프롬프트가 없다"** → 워크플로를 안 불러온 것 (2번 다시)
- **에러 뜸** → 모델 이름이 맞는지 (Load Checkpoint 드롭다운에서 다시 선택)
- **너무 느림/멈춤** → 크기를 1024로, batch를 1로 낮추기
- **채팅이 안 됨** → 지금 이미지 모드라 그럼. `gpu-mode chat`으로 전환

## 8. FLUX 고품질 이미지 (무검열, 초간단 페이지)

초간단 페이지(`localhost:8189/simple-image.html`) 모델 드롭다운의 **FLUX 그룹**에서 선택.

- **FLUX.1-dev Abliterated V2** (무검열 GGUF, **Q8 기본** / Q6 저메모리) — SDXL을 넘어서는 실사·복잡장면 품질. 손·글자·프롬프트 정확도가 SDXL보다 위.
- **속도(890M 실측, split attention)**: 1024²·20스텝 = **~7분** (Q8 392초 — Q6 412초보다 오히려 빠름), **1536² 네이티브 = ~19분** (GTT 24G). 상세: [벤치마크](../benchmarks/2026-08-21-flux-split-attention-gfx1150.md).
- **1536²는 `--use-split-cross-attention` 필수** — 기본 pytorch SDPA는 gfx1150에서 대토큰 행(hang) → MES 웨지. comfyui.service에 이미 적용됨.
- **프롬프트는 문장식**: 태그 나열이 아니라 자연스러운 영어 문장(예: `a photorealistic portrait of a woman in a hanbok, golden hour, cinematic`). 번역 버튼으로 한국어 문장 그대로 변환해 쓰면 됨.
- **주의**: abliteration이 강해 옷 지시를 무시하고 누드로 갈 때가 있음 → SFW는 `fully clothed, wearing ○○` 강조. ControlNet은 FLUX에 미적용(SDXL 전용).
- 기술: `UnetLoaderGGUF` + `DualCLIPLoader`(t5xxl_fp8 + clip_l, type=flux) + `VAELoader`(flux-ae) → `CLIPTextEncode` → `FluxGuidance`(3.5) → `KSampler`(**cfg=1**, euler/**simple**, 20스텝, `EmptySD3LatentImage` 16채널) → `VAEDecode`. VAE는 bf16(fp16 금물), `HSA_OVERRIDE` 설정 금지.

## 9. 영상 만들기 (Wan 2.2 5B)

초간단 페이지 `localhost:8189/simple-video.html` (이미지 페이지 상단 "🎬 영상 생성으로"로도 이동).

- **텍스트→영상**: 프롬프트만 → 짧은 클립
- **이미지→영상(I2V)**: 시작 이미지를 올리면 그 그림이 움직임
- 길이 1~5초, 화면 480²~720p, 스텝 슬라이더
- **속도(890M 실측)**: 480²·2초·20스텝 ≈ **4.3분**. 해상도·길이를 올리면 급격히 느려짐(720p·5초는 수십 분) → 처음엔 480²·2초로 감 잡기
- 저장: `~/비디오/strix-ai` (mp4)
- 영상도 890M을 단독으로 쓰므로 **생성 모드** 필요(채팅과 동시 불가). 페이지 상단 버튼으로 전환
- ComfyUI 본체에서 직접 조립하려면: `UNETLoader(wan2.2_ti2v_5B_fp16)` → `ModelSamplingSD3(shift 8)` → `KSampler(20스텝, cfg 5, euler)`, `CLIPLoader(umt5, type=wan)`, `VAELoader(wan2.2_vae)`, `Wan22ImageToVideoLatent`(I2V면 start_image 연결) → `VAEDecode` → `VHS_VideoCombine(frame_rate 16, h264-mp4)`

---

*간단하게 쓰고 싶으면 `localhost:8189/simple-image.html`(이미지) · `simple-video.html`(영상)
을 그대로 쓰면 됩니다. ComfyUI 본체는 더 세밀한 조정과 ControlNet 등 고급 기능용입니다.*
