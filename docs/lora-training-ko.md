# LoRA 학습 가이드 (한국어)

LoRA는 **특정 캐릭터·화풍·개념을 모델에 추가로 가르치는** 작은 파일입니다.
예: 내가 만든 캐릭터를 여러 그림에서 일관되게, 특정 작가 화풍으로, 우리 강아지를
애니로 등. 한 번 학습하면 프롬프트에 불러 계속 씁니다.

> ⚠️ **먼저 알아둘 것 (이 기기 기준)**
> - SDXL LoRA 학습은 890M에서 **수 시간~하룻밤** 걸립니다 (연산이 느림)
> - 학습은 밤에 돌려두고 자는 용도. 그동안 채팅/이미지 GPU는 못 씁니다
> - LoRA는 "학습"이 맞습니다 (ControlNet과 달리 실제로 모델을 가르침)

## 0. 어떤 모델용 LoRA인가 — 먼저 정하기 (매우 중요)

**LoRA는 학습한 아키텍처에서만 작동한다.** SDXL로 학습한 LoRA는 SDXL 모델에만 붙고, Z-Image/FLUX엔 안 붙는다.

| 쓰고 싶은 모델 | LoRA 학습 도구 | 이 박스 현황 |
|---|---|---|
| **SDXL** (Illustrious/NoobAI/Pony/Animagine/RealVis) | **kohya sd-scripts** (`lora-train.sh`) | ✅ 셋업됨 — 아래 파이프라인 |
| **Z-Image** (실사·한복 최강) | **Ostris AI Toolkit** 또는 fal `z-image-base-trainer` | ⏳ 미설치 (원하면 설치) |
| **FLUX** | AI Toolkit / kohya(flux 브랜치) | ⏳ 미설치 |

→ **결정**: 애니·RealVis 실사 쪽이면 지금 바로 SDXL LoRA(아래). **Z-Image로 특정 인물/스타일을 고정**하고 싶으면 AI Toolkit 경로가 필요(890M에선 수 시간~밤, dGPU 오면 훨씬 편함). 처음엔 **SDXL LoRA로 흐름을 익히고**, Z-Image LoRA는 필요해지면 추가하는 걸 권한다.

## 1. 데이터 준비 (제일 중요)

학습 품질은 **데이터가 90%**입니다. 좋은 데이터셋:
- **이미지 10~30장** — 배우게 할 대상(캐릭터/화풍)이 뚜렷하게
- 다양한 각도·포즈·배경 (같은 그림만 여러 장 X)
- 배경이 단순하고 대상이 큼
- 해상도 1024 이상 권장 (작으면 자동 리사이즈)

**캐릭터 학습**이면: 그 캐릭터가 나온 그림 여러 장
**화풍 학습**이면: 그 화풍의 그림 여러 장 (대상은 다양해도 됨)

### 폴더 만들기
```bash
lora-train.sh --init 내캐릭터
# → ~/lora-data/내캐릭터/img/ 생성됨
```
이 `img/` 폴더에 이미지들을 넣으세요. 파일 탐색기로 드래그하면 됩니다.

### (선택) 캡션 — 품질을 크게 올림
각 이미지 옆에 같은 이름의 `.txt`를 두고, 그 그림의 태그를 적습니다:
- `1.png` → `1.txt`에 `myChar, 1girl, red hair, smiling, forest`
- 여기서 `myChar` 같은 **고유한 단어(트리거)**를 정하면, 나중에 그 단어로 불러냅니다
- 캡션이 없으면 폴더 이름이 트리거가 됩니다

**자동 캡션(20장 손으로 쓰기 귀찮을 때)**: WD14 Tagger로 태그를 자동 생성한 뒤 트리거 단어만 손보면 된다. ComfyUI-WD14-Tagger 노드 또는 kohya의 `finetune/tag_images_by_wd14_tagger.py` 사용. (스타일 LoRA는 캡션을 최소화[트리거만]하는 게 화풍을 더 잘 흡수한다.)

## 2. 학습 실행

```bash
# 채팅·이미지 둘 다 끄고 GPU 독점 (학습은 comfyui/router 밖의 별도 프로세스)
systemctl --user stop comfyui.service llama-router.service

lora-train.sh 내캐릭터          # 기본 1500스텝
# 끝나면 채팅 복원: systemctl --user start llama-router.service
lora-train.sh 내캐릭터 2000     # 스텝 지정 (많을수록 오래·강하게)
```
- 진행 상황이 터미널에 뜹니다. 500스텝마다 중간 저장
- 완료되면 `~/models/comfyui/loras/내캐릭터.safetensors` 생성

## 3. 학습한 LoRA 쓰기

ComfyUI(8188)에서 **LoraLoader** 노드를 추가해 연결하거나, 간단히는:
- 프롬프트에 **트리거 단어**(예: `myChar`)를 넣으면 그 캐릭터/화풍이 나옵니다
- LoRA 강도는 LoraLoader의 strength로 조절 (0.6~1.0)

## 4. 팁 & 문제 해결

- **결과가 대상과 안 닮음** → 데이터 부족/다양성 부족. 이미지 늘리기, 스텝 늘리기
- **다 똑같이 나옴(과학습)** → 스텝 줄이기(1000), 강도 낮추기(0.6)
- **너무 느림** → 이 기기의 한계. 이미지 수를 줄이거나(15장) 밤에 실행
- **메모리 부족 에러** → resolution을 768로, network_dim을 8로 (스크립트 편집)

## 정리

| 단계 | 명령 |
|---|---|
| 폴더 생성 | `lora-train.sh --init 이름` |
| 이미지 넣기 | `~/lora-data/이름/img/` 에 10~30장 |
| 학습 | `lora-train.sh 이름` (밤에, GPU 독점) |
| 사용 | 프롬프트에 트리거 단어 / ComfyUI LoraLoader |

*무거운 작업이라 처음엔 이미지 15장 + 1500스텝으로 가볍게 시험해보길 권합니다.*
