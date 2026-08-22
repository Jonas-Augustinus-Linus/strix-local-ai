#!/usr/bin/env python3
"""
LoRA 데이터셋 생성기 — 어떤 컨셉이든 우리 모델로 '다양성 있는' 이미지 세트를 뽑는다.
(한복은 예시일 뿐. style/person/character/costume/props/concept 전부 가능.)

핵심: LoRA엔 '일관된 대상 + 다양한 나머지'가 필요하다. base 프롬프트(=배울 대상)를 고정하고,
      프레이밍·각도·조명·배경·포즈를 자동으로 섞어 seed도 매번 바꿔 N장 생성한다.

사용:
  # 이미지 모드(ComfyUI) 켠 상태에서
  python3 gen_lora_dataset.py <name> --base "a Korean woman wearing an elegant hanbok" --count 30
  # 모델 선택 (기본 z-image-turbo = 동아시아 실사 최강·빠름)
  python3 gen_lora_dataset.py <name> --base "..." --model realvis --count 24
  # 스타일 LoRA: 대상을 다양화하려면 --subjects
  python3 gen_lora_dataset.py <name> --base "in the style of ukiyo-e woodblock print" \
        --subjects "a woman;a samurai;a mountain landscape;a cat;a flower" --count 30
출력: ~/사진/strix-ai/lora-src/<name>/  → 그다음 prep_lora_data.py 로 정규화+캡션.
"""
import argparse, json, time, urllib.request, sys, os, hashlib
H = "http://127.0.0.1:8188"

# 다양성 풀 (영어 — 모델이 영어 프롬프트를 이해)
FRAMING  = ["full body shot", "upper body portrait", "close-up portrait", "cowboy shot", "wide establishing shot"]
ANGLE    = ["front view", "side profile view", "three-quarter view", "from slightly above", "from a low angle"]
LIGHTING = ["soft natural window light", "golden hour backlight", "dramatic cinematic rim light",
            "overcast diffused light", "warm candlelight", "studio softbox lighting", "blue hour ambient light", "moody chiaroscuro"]
BACKDROP = ["plain neutral studio backdrop", "traditional hanok courtyard", "autumn garden with foliage",
            "night city street bokeh", "minimalist interior", "misty bamboo forest", "palace at dusk"]
POSE     = ["standing gracefully", "sitting elegantly", "walking mid-stride", "looking over the shoulder",
            "hands gently clasped", "turning toward the camera"]

def pick(pool, i, salt):  # seed 없이 결정적 다양성: index+salt 해시로 풀에서 선택
    h = int(hashlib.md5(f"{salt}-{i}".encode()).hexdigest(), 16)
    return pool[h % len(pool)]

def zimage_wf(dit, pos, neg, w, h, seed, steps, cfg):
    return {
      "1":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":dit}},
      "2":{"class_type":"ModelSamplingAuraFlow","inputs":{"model":["1",0],"shift":3.0}},
      "3":{"class_type":"CLIPLoader","inputs":{"clip_name":"qwen_3_4b_fp8_mixed.safetensors","type":"lumina2"}},
      "4":{"class_type":"CLIPTextEncode","inputs":{"text":pos,"clip":["3",0]}},
      "5":{"class_type":"CLIPTextEncode","inputs":{"text":neg,"clip":["3",0]}},
      "6":{"class_type":"EmptySD3LatentImage","inputs":{"width":w,"height":h,"batch_size":1}},
      "7":{"class_type":"VAELoader","inputs":{"vae_name":"z_image_ae.safetensors"}},
      "8":{"class_type":"KSampler","inputs":{"seed":seed,"steps":steps,"cfg":cfg,"sampler_name":"euler","scheduler":"simple","denoise":1.0,"model":["2",0],"positive":["4",0],"negative":["5",0],"latent_image":["6",0]}},
      "9":{"class_type":"VAEDecode","inputs":{"samples":["8",0],"vae":["7",0]}},
      "10":{"class_type":"SaveImage","inputs":{"filename_prefix":"lora-src/PH","images":["9",0]}}
    }
def sdxl_wf(ckpt, pos, neg, w, h, seed):
    return {
      "3":{"class_type":"KSampler","inputs":{"seed":seed,"steps":28,"cfg":6.0,"sampler_name":"euler_ancestral","scheduler":"normal","denoise":1.0,"model":["4",0],"positive":["6",0],"negative":["7",0],"latent_image":["5",0]}},
      "4":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":ckpt}},
      "5":{"class_type":"EmptyLatentImage","inputs":{"width":w,"height":h,"batch_size":1}},
      "6":{"class_type":"CLIPTextEncode","inputs":{"text":pos,"clip":["4",1]}},
      "7":{"class_type":"CLIPTextEncode","inputs":{"text":neg,"clip":["4",1]}},
      "8":{"class_type":"VAEDecode","inputs":{"samples":["3",0],"vae":["4",2]}},
      "10":{"class_type":"SaveImage","inputs":{"filename_prefix":"lora-src/PH","images":["8",0]}}
    }

MODELS = {  # 별칭 → (종류, 식별자, steps, cfg)
  "z-image-turbo": ("zimage","z-image-turbo-Q8_0.gguf",8,1.0),
  "z-image":       ("zimage","z-image-Q8_0.gguf",24,4.5),
  "realvis":       ("sdxl","RealVisXL-V5.safetensors",0,0),
  "illustrious":   ("sdxl","Illustrious-XL-v2.0.safetensors",0,0),
  "hidream-fast":  ("hidream","hidream-i1-fast-Q5_K_M.gguf",16,1.0),
}

def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--base", required=True, help="배울 대상(고정) — 예: 'a Korean woman in an elegant hanbok'")
    ap.add_argument("--subjects", default="", help="스타일 LoRA용: 대상 다양화 세미콜론 목록")
    ap.add_argument("--model", default="z-image-turbo", choices=list(MODELS))
    ap.add_argument("--count", type=int, default=30)
    ap.add_argument("--size", default="832x1216")
    ap.add_argument("--neg", default="lowres, blurry, deformed hands, extra fingers, watermark, text, cartoon, 3d render, multiple people")
    a=ap.parse_args()

    try: get("/system_stats")
    except Exception: sys.exit("ComfyUI(8188) 응답 없음 — 이미지 모드로 전환하세요 (허브에서 image 모드)")

    kind, ident, steps, cfg = MODELS[a.model]
    w,h = map(int, a.size.split("x"))
    subjects = [s.strip() for s in a.subjects.split(";") if s.strip()]
    prefix = f"lora-src/{a.name}/img"
    print(f"=== {a.name}: {a.count}장 생성 ({a.model}, {w}x{h}) ===", flush=True)
    done=0
    for i in range(a.count):
        # 다양성 조합
        parts=[a.base]
        if subjects: parts=[subjects[i % len(subjects)] + ", " + a.base]
        parts += [pick(POSE,i,"pose"), pick(FRAMING,i,"frame"), pick(ANGLE,i,"angle"),
                  pick(BACKDROP,i,"bg"), pick(LIGHTING,i,"light"), "ultra detailed, sharp focus, 8k"]
        pos=", ".join(parts)
        seed=(i*7919 + 13) % 2_000_000_000
        if kind=="zimage": wf=zimage_wf(ident,pos,a.neg,w,h,seed,steps,cfg)
        elif kind=="sdxl": wf=sdxl_wf(ident,pos,a.neg,w,h,seed)
        else: sys.exit(f"{a.model} 워크플로 미구현(여기선 z-image/sdxl)")
        wf["10"]["inputs"]["filename_prefix"]=prefix
        try: pid=post("/prompt",{"prompt":wf})["prompt_id"]
        except Exception as e: print(f"  [{i+1}] 제출실패 {e}", flush=True); continue
        # 완료 대기
        t0=time.time()
        while time.time()-t0<400:
            time.sleep(4)
            try: hist=get("/history/"+pid)
            except Exception: continue
            if pid in hist and hist[pid].get("status",{}).get("completed"):
                done+=1; print(f"  [{done}/{a.count}] ok ({time.time()-t0:.0f}s) :: {pick(LIGHTING,i,'light')}", flush=True); break
            if pid in hist and hist[pid].get("status",{}).get("status_str")=="error":
                print(f"  [{i+1}] 에러", flush=True); break
    outdir = f"~/사진/strix-ai/lora-src/{a.name}"   # 파일: img_0000N_.png
    print(f"\n=== 완료: {done}/{a.count}장 → {outdir}/ (img_*.png) ===", flush=True)
    print(f"다음: python3 scripts/prep_lora_data.py {a.name} --src {outdir} --trigger <트리거>", flush=True)

if __name__=="__main__":
    main()
