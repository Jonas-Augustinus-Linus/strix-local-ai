#!/usr/bin/env python3
# Z-Image Turbo gfx1150 스모크 테스트: 행(hang) 여부 검증. 8스텝이라 정상이면 ~1-2분.
import json, time, urllib.request, sys

H = "http://127.0.0.1:8188"
wf = {
  "1": {"class_type":"UnetLoaderGGUF","inputs":{"unet_name":"z-image-turbo-Q8_0.gguf"}},
  "2": {"class_type":"ModelSamplingAuraFlow","inputs":{"model":["1",0],"shift":3.0}},
  "3": {"class_type":"CLIPLoader","inputs":{"clip_name":"qwen_3_4b_fp8_mixed.safetensors","type":"lumina2"}},
  "4": {"class_type":"CLIPTextEncode","inputs":{"text":"a photorealistic portrait of a Korean woman wearing a traditional hanbok, elegant, detailed face, soft natural light, 8k","clip":["3",0]}},
  "5": {"class_type":"CLIPTextEncode","inputs":{"text":"","clip":["3",0]}},
  "6": {"class_type":"EmptySD3LatentImage","inputs":{"width":1024,"height":1024,"batch_size":1}},
  "7": {"class_type":"VAELoader","inputs":{"vae_name":"z_image_ae.safetensors"}},
  "8": {"class_type":"KSampler","inputs":{"seed":42,"steps":8,"cfg":1.0,"sampler_name":"euler","scheduler":"simple","denoise":1.0,"model":["2",0],"positive":["4",0],"negative":["5",0],"latent_image":["6",0]}},
  "9": {"class_type":"VAEDecode","inputs":{"samples":["8",0],"vae":["7",0]}},
  "10":{"class_type":"SaveImage","inputs":{"filename_prefix":"zimage/test","images":["9",0]}}
}

def post(path, obj):
    r = urllib.request.Request(H+path, data=json.dumps(obj).encode(), headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r, timeout=30))
def get(path):
    return json.load(urllib.request.urlopen(H+path, timeout=30))

t0=time.time()
try:
    pid = post("/prompt", {"prompt":wf})["prompt_id"]
except Exception as e:
    print("SUBMIT-FAIL:", e); sys.exit(2)
print("submitted prompt_id=%s" % pid)
last=""
while time.time()-t0 < 280:
    time.sleep(4)
    try: hist = get("/history/"+pid)
    except Exception as e: continue
    if pid in hist:
        st = hist[pid].get("status",{})
        if st.get("completed"):
            imgs=[]
            for k,v in hist[pid]["outputs"].items():
                for im in v.get("images",[]): imgs.append(im["subfolder"]+"/"+im["filename"])
            print("DONE %.0fs images=%s" % (time.time()-t0, imgs))
            sys.exit(0)
        if st.get("status_str")=="error":
            print("ERROR %.0fs :: %s" % (time.time()-t0, json.dumps(hist[pid].get("status",{}))[:400]))
            sys.exit(3)
    # queue/progress heartbeat
    try:
        q=get("/queue"); running=len(q.get("queue_running",[]))
        msg="running=%d t=%.0fs"%(running,time.time()-t0)
        if msg!=last: print(msg); last=msg
    except Exception: pass
print("TIMEOUT %.0fs — 행 의심 (gfx1150 wedge?)" % (time.time()-t0)); sys.exit(4)
