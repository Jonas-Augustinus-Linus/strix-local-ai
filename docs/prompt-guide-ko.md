# STRIX 이미지 프롬프트 정교화 가이드 (한국어)

내가 상상한 그림을 정확히 뽑기 위한 실전 가이드. **핵심: 모델은 학습되지 않는다 — 정확도는 프롬프트에서 나온다.**

## 0. 모델별로 프롬프트 방식이 다르다 (가장 중요)

| 모델 | 프롬프트 방식 | 네거티브 | 강점 |
|---|---|---|---|
| **Z-Image / FLUX / HiDream** | **영어 문장** (자연어 서술) | Z-Base·HiDream O / Turbo·FLUX 무효(cfg1) | 실사, 동아시아(Z-Image), 프롬프트 이해력 |
| **SDXL** (Illustrious/NoobAI/Pony/Animagine/RealVis) | **영어 태그 나열**(danbooru식) | O (필수) | 애니, 캐릭터, LoRA 생태계 |

문장 모델에 태그를 나열하거나, 태그 모델에 긴 문장을 쓰면 정확도가 떨어진다. **페이지가 모델 고르면 자동으로 안내 문구를 바꿔준다.**

## 1. 프롬프트 구조 (문장 모델 = Z-Image/FLUX/HiDream)

좋은 순서로 쌓으면 정확도가 올라간다:

```
[주체] + [외모/나이] + [의상/디테일] + [포즈/표정] + [배경/장소] + [조명] + [카메라/렌즈] + [화질]
```

예시 (한복 실사):
> a photorealistic portrait of an elegant Korean woman in her twenties, wearing a deep indigo dangui with gold embroidery and a crimson skirt, calm confident expression, standing in a candle-lit hanok at night, warm cinematic rim light, shot on 85mm lens, shallow depth of field, ultra detailed skin, 8k

각 조각을 바꿔가며 실험하면 어디서 어긋나는지 보인다.

## 2. 빛(lighting) 어휘 — 분위기의 90%

네가 특히 원하는 부분. 조명어를 명시하면 완전히 달라진다:

- **시간대**: `golden hour`(황금빛 노을), `blue hour`(푸른 새벽), `midday sun`, `overcast`(흐림, 부드러움), `night`
- **방향/종류**: `rim light`(윤곽광), `backlight / backlit`(역광), `side light`(측광), `top light`, `Rembrandt lighting`(렘브란트, 얼굴 삼각광), `butterfly lighting`(뷰티)
- **품질**: `soft diffused light`(부드러움), `hard light`(강한 그림자), `softbox`, `studio lighting`, `natural window light`
- **극적**: `dramatic lighting`, `chiaroscuro`(명암대비), `volumetric light`(빛줄기), `god rays`, `neon glow`, `candlelight`, `firelight`
- **색온도**: `warm light`(따뜻), `cool light`(차가움), `teal and orange`(영화톤)

조합 예: `cinematic rim light + warm candlelight + volumetric` → 극적인 야간 인물.

## 3. 인체표현(anatomy/pose) — 정확도 높이기

확산 모델의 약점(손·자세)을 다루는 법:

- **전신/구도**: `full body shot`, `upper body`, `close-up portrait`, `dynamic pose`, `three-quarter view`, `from below/above`
- **자세**: `standing gracefully`, `sitting`, `walking`, `arms crossed`, `hand on hip`, `looking over shoulder`
- **표정**: `gentle smile`, `serious gaze`, `laughing`, `calm expression`
- **손 문제 완화**: `detailed hands`를 긍정에, `deformed hands, extra fingers, fused fingers`를 네거티브에 (문장 모델은 손 프롬프트 효과 제한적 → 심하면 ControlNet/inpaint).
- **가장 확실한 자세 제어**: **참조 이미지로 조건화** → 자세=ControlNet(openpose, SDXL), 인물/빛 느낌=IP-Adapter(설치됨, SDXL). 정확한 포즈가 필요하면 이게 프롬프트보다 확실하다.

## 4. 네거티브 프롬프트 (SDXL / Z-Base / HiDream)

빼고 싶은 것을 명시. 페이지가 모델별 기본 네거티브를 자동으로 넣지만, 커스텀 가능:
- 실사 공통: `lowres, blurry, deformed hands, extra fingers, watermark, text, cartoon, 3d render, plastic skin, oversaturated`
- 애니(SDXL): `worst quality, low quality, jpeg artifacts, bad anatomy, extra limbs, signature`
- Pony 계열: 네거티브에 `score_1, score_2, score_3` (품질 하한 차단)

## 5. 모델별 프리셋 (복붙해서 시작)

### Z-Image (실사 인물·한복·동아시아) — 문장
```
정밀 실사 인물:
a photorealistic portrait of a Korean woman, [나이/외모], wearing [의상], [표정], [배경], soft natural window light, 85mm lens, shallow depth of field, ultra detailed skin texture, 8k
네거티브(Base): lowres, blurry, deformed hands, extra fingers, watermark, text, cartoon, plastic skin
```

### RealVis (서구/범용 실사) — 문장/태그 혼합
```
photorealistic, RAW photo, [주체], [의상], [배경], cinematic lighting, dramatic rim light, 8k uhd, sharp focus
```

### SDXL 애니 (Illustrious/NoobAI/Animagine) — 태그
```
1girl, [머리색] hair, [의상], [포즈], [배경], detailed background, cinematic lighting, masterpiece, best quality, highly detailed
Pony면 앞에: score_9, score_8_up, score_7_up,
```

### HiDream (무검열 정밀·한복) — 문장 + 진짜 네거티브
```
a cinematic photograph of [주체] wearing [한복 디테일], [배경], dramatic lighting, ultra detailed
neg: lowres, bad anatomy, deformed, watermark, text, oversaturated
```

## 6. 반복 워크플로 (정확도를 올리는 실전 루프)

1. **씨앗 고정**(seed) → 한 조각씩만 바꿔 A/B (조명만, 의상만) → 뭐가 효과 있는지 학습.
2. **베스트 컷 저장** → 나중에 **LoRA 데이터**로 쓰면 그 스타일/인물을 영구 고정 가능(→ [lora-training-ko.md](lora-training-ko.md)).
3. 자세/구도가 계속 안 맞으면 → **ControlNet/IP-Adapter**(참조 이미지)로 넘어가라. 프롬프트로 안 되는 건 조건화로.

## 요약
- 모델 맞는 방식(문장 vs 태그)으로 써라.
- **조명어를 반드시 명시**(rim light, golden hour, volumetric…).
- 자세/인물이 어긋나면 프롬프트 대신 **참조 조건화**(ControlNet/IP-Adapter).
- 반복되는 대상은 **LoRA**로 학습(모델은 저절로 안 배운다).
