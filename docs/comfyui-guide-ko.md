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
| **모델** (Illustrious/NoobAI/Pony) | "Load Checkpoint" 상자의 드롭다운 |
| **크기** | "Empty Latent Image" 상자 (width/height, 세로면 832×1216) |
| **여러 장** | "Empty Latent Image"의 batch_size 를 2~4로 |
| **품질(스텝)** | "KSampler" 상자의 steps (24~30, 높을수록 세밀·느림) |
| **랜덤/고정** | "KSampler"의 seed 옆 control: randomize(매번 다름)/fixed(같음) |

## 5. 품질 올리는 핵심 태그

**맨 앞에 품질 태그를 붙이면 확 좋아집니다:**
- Illustrious/NoobAI: `masterpiece, best quality, amazing quality, very aesthetic, absurdres,`
- **Pony는 반드시**: `score_9, score_8_up, score_7_up,` (이거 없으면 품질 급락!)

자주 쓰는 태그:
- 인물: `1girl` `1boy`, `long hair`, `blue eyes`, `smile`, `dress`, `kimono`
- 배경: `forest`, `city`, `night`, `sunset`, `cherry blossoms`, `mountains`
- 분위기: `detailed`, `cinematic lighting`, `beautiful`, `scenery`, `masterpiece`

**영어가 어려우면**: 채팅(WebUI)에서 LLM한테 "벚꽃 정원의 흰머리 소녀를 danbooru
태그로 만들어줘" 하면 정확한 태그를 만들어 줍니다. (채팅 모드로 전환 필요)

## 6. 사진/자세 참조로 그리기 (ControlNet — 추후 설치)

X에서 본 "관절 사진 → 그 자세로", "내 사진 → 애니로" 같은 건 **ControlNet**이라는
추가 기능입니다. 지금은 없지만 원하면 설치할 수 있습니다:
- **자세 제어**(OpenPose): 관절/포즈 이미지 → 그 자세의 캐릭터
- **구도 유지**(Canny/Depth): 사진 윤곽/깊이 → 같은 구도로 애니·실사 변환
- **부분 수정**(Inpaint): 기존 그림에서 얼굴만/옷만 교체

→ 설치를 원하면 "ControlNet 깔아줘"라고 말씀하세요 (모델 ~2.5GB씩 + 워크플로 세팅).

## 7. 문제 해결

- **화면이 비었다** → 폴더 아이콘에서 strix-SDXL 다시 불러오기
- **"프롬프트가 없다"** → 워크플로를 안 불러온 것 (2번 다시)
- **에러 뜸** → 모델 이름이 맞는지 (Load Checkpoint 드롭다운에서 다시 선택)
- **너무 느림/멈춤** → 크기를 1024로, batch를 1로 낮추기
- **채팅이 안 됨** → 지금 이미지 모드라 그럼. `gpu-mode chat`으로 전환

---

*간단하게 쓰고 싶으면 `localhost:8189/simple-image.html` (프롬프트 1칸 + 버튼)도
그대로 있습니다. ComfyUI 본체는 더 세밀한 조정과 ControlNet 등 고급 기능용입니다.*
