#!/usr/bin/env python3
# Z-Image BASE (z-image-Q8_0, 풀CFG+네거티브) gfx1150 검증. simple-image.html zimageWf(base)와 동일.
import json, time, urllib.request, sys, urllib.error
H="http://127.0.0.1:8188"
wf={
 "1":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":"z-image-Q8_0.gguf"}},
 "2":{"class_type":"ModelSamplingAuraFlow","inputs":{"model":["1",0],"shift":3.0}},
 "3":{"class_type":"CLIPLoader","inputs":{"clip_name":"qwen_3_4b_fp8_mixed.safetensors","type":"lumina2"}},
 "4":{"class_type":"CLIPTextEncode","inputs":{"text":"a photorealistic portrait of an elegant Korean woman wearing a deep indigo and crimson hanbok with gold embroidery, ornate norigae, standing in a candle-lit hanok at night, cinematic rim light, ultra detailed skin, 8k","clip":["3",0]}},
 "5":{"class_type":"CLIPTextEncode","inputs":{"text":"lowres, blurry, deformed hands, extra fingers, watermark, text, cartoon, 3d render, plastic skin","clip":["3",0]}},
 "6":{"class_type":"EmptySD3LatentImage","inputs":{"width":832,"height":1216,"batch_size":1}},
 "7":{"class_type":"VAELoader","inputs":{"vae_name":"z_image_ae.safetensors"}},
 "8":{"class_type":"KSampler","inputs":{"seed":7,"steps":24,"cfg":4.5,"sampler_name":"euler","scheduler":"simple","denoise":1.0,"model":["2",0],"positive":["4",0],"negative":["5",0],"latent_image":["6",0]}},
 "9":{"class_type":"VAEDecode","inputs":{"samples":["8",0],"vae":["7",0]}},
 "10":{"class_type":"SaveImage","inputs":{"filename_prefix":"zimage/base-test","images":["9",0]}}
}
def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"});return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))
print("══ Z-Image Base 832x1216 24step cfg4.5 ══",flush=True)
t0=time.time()
try: pid=post("/prompt",{"prompt":wf})["prompt_id"]
except urllib.error.HTTPError as e: print("SUBMIT-FAIL 400:",e.read().decode()[:400],flush=True); sys.exit(2)
print("submitted",pid,flush=True)
while time.time()-t0<600:
    time.sleep(5)
    try: hist=get("/history/"+pid)
    except Exception: continue
    if pid in hist:
        st=hist[pid].get("status",{})
        if st.get("completed"):
            imgs=[im["subfolder"]+"/"+im["filename"] for k,v in hist[pid]["outputs"].items() for im in v.get("images",[])]
            print("DONE %.0fs %s"%(time.time()-t0,imgs),flush=True); sys.exit(0)
        if st.get("status_str")=="error": print("ERROR %.0fs %s"%(time.time()-t0,json.dumps(st)[:400]),flush=True); sys.exit(3)
    if int(time.time()-t0)%30<5: print("  ...%.0fs"%(time.time()-t0),flush=True)
print("TIMEOUT",flush=True); sys.exit(4)
