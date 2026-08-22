#!/usr/bin/env python3
# HiDream Dev/Full gfx1150 생성 테스트. gpu-only 모드 필요(인코더 GPU). Dev 28step/cfg1, Full 50step/cfg5.
import json, time, urllib.request, sys

H = "http://127.0.0.1:8188"
POS = ("a photorealistic portrait of a Korean woman wearing an elegant traditional hanbok, "
       "delicate embroidery, refined face, soft natural window light, hanok interior, ultra detailed, 8k")
NEG = "lowres, bad anatomy, deformed hands, extra fingers, blurry, watermark, text, jpeg artifacts, cartoon, 3d render"

def wf(dit, steps, cfg, tag, seed=42):
    return {
      "1":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":dit}},
      "2":{"class_type":"ModelSamplingSD3","inputs":{"model":["1",0],"shift":3.0}},
      "3":{"class_type":"QuadrupleCLIPLoaderGGUF","inputs":{"clip_name1":"clip_l_hidream.safetensors","clip_name2":"clip_g_hidream.safetensors","clip_name3":"t5xxl-Q5_K_M.gguf","clip_name4":"llama-3.1-8b-abliterated-Q6_K.gguf"}},
      "4":{"class_type":"CLIPTextEncode","inputs":{"text":POS,"clip":["3",0]}},
      "5":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["3",0]}},
      "6":{"class_type":"EmptySD3LatentImage","inputs":{"width":1024,"height":1024,"batch_size":1}},
      "7":{"class_type":"VAELoader","inputs":{"vae_name":"hidream-ae.safetensors"}},
      "8":{"class_type":"KSampler","inputs":{"seed":seed,"steps":steps,"cfg":cfg,"sampler_name":"euler","scheduler":"normal","denoise":1.0,"model":["2",0],"positive":["4",0],"negative":["5",0],"latent_image":["6",0]}},
      "9":{"class_type":"VAEDecode","inputs":{"samples":["8",0],"vae":["7",0]}},
      "10":{"class_type":"SaveImage","inputs":{"filename_prefix":"hidream/"+tag,"images":["9",0]}}
    }

def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))

def run(label, dit, steps, cfg, tag, budget=1800):
    print("══════ %s (%s, %dstep cfg%.1f) ══════" % (label, dit, steps, cfg), flush=True)
    t0=time.time()
    try: pid=post("/prompt",{"prompt":wf(dit,steps,cfg,tag)})["prompt_id"]
    except Exception as e: print("SUBMIT-FAIL %s :: %s"%(label,e),flush=True); return
    while time.time()-t0 < budget:
        time.sleep(6)
        try: hist=get("/history/"+pid)
        except Exception: continue
        if pid in hist:
            st=hist[pid].get("status",{})
            if st.get("completed"):
                imgs=[im["subfolder"]+"/"+im["filename"] for k,v in hist[pid]["outputs"].items() for im in v.get("images",[])]
                print("DONE %s %.0fs images=%s"%(label,time.time()-t0,imgs),flush=True); return
            if st.get("status_str")=="error":
                print("ERROR %s %.0fs :: %s"%(label,time.time()-t0,json.dumps(st)[:400]),flush=True); return
        if int(time.time()-t0)%30<6:
            print("  ...%s running %.0fs"%(label,time.time()-t0),flush=True)
    print("TIMEOUT %s %.0fs (행 의심)"%(label,time.time()-t0),flush=True)

run("HiDream-Dev",  "hidream-i1-dev-Q6_K.gguf",   28, 1.0, "dev-dvram", budget=1500)
print("=== HiDream Dev test done ===",flush=True)
