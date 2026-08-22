#!/usr/bin/env python3
# IP-Adapter 테스트: simple-image.html의 SDXL+ipadapter 경로와 동일한 그래프. 참조=ipa-ref.png(한복).
import json,time,urllib.request,sys,urllib.error
H="http://127.0.0.1:8188"
wf={
 "3":{"class_type":"KSampler","inputs":{"seed":123,"steps":28,"cfg":6.0,"sampler_name":"euler_ancestral","scheduler":"normal","denoise":1.0,"model":["31",0],"positive":["6",0],"negative":["7",0],"latent_image":["5",0]}},
 "4":{"class_type":"CheckpointLoaderSimple","inputs":{"ckpt_name":"RealVisXL-V5.safetensors"}},
 "5":{"class_type":"EmptyLatentImage","inputs":{"width":832,"height":1216,"batch_size":1}},
 "6":{"class_type":"CLIPTextEncode","inputs":{"text":"a photorealistic portrait of an elegant woman, refined, cinematic, 8k, sharp focus","clip":["4",1]}},
 "7":{"class_type":"CLIPTextEncode","inputs":{"text":"lowres, blurry, deformed hands, extra fingers, watermark, cartoon, 3d","clip":["4",1]}},
 "8":{"class_type":"VAEDecode","inputs":{"samples":["3",0],"vae":["4",2]}},
 "9":{"class_type":"SaveImage","inputs":{"filename_prefix":"ipatest/ref","images":["8",0]}},
 "30":{"class_type":"LoadImage","inputs":{"image":"ipa-ref.png"}},
 "31a":{"class_type":"IPAdapterUnifiedLoader","inputs":{"model":["4",0],"preset":"PLUS (high strength)"}},
 "31":{"class_type":"IPAdapterAdvanced","inputs":{"model":["31a",0],"ipadapter":["31a",1],"image":["30",0],"weight":1.0,"weight_type":"linear","combine_embeds":"concat","start_at":0.0,"end_at":1.0,"embeds_scaling":"V only"}}
}
def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"});return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))
print("══ IP-Adapter 테스트 (RealVis + 한복참조) ══",flush=True)
t0=time.time()
try: pid=post("/prompt",{"prompt":wf})["prompt_id"]
except urllib.error.HTTPError as e: print("SUBMIT-FAIL 400:",e.read().decode()[:500],flush=True); sys.exit(2)
print("submitted",pid,flush=True)
while time.time()-t0<400:
    time.sleep(5)
    try: hist=get("/history/"+pid)
    except Exception: continue
    if pid in hist:
        st=hist[pid].get("status",{})
        if st.get("completed"):
            imgs=[im["subfolder"]+"/"+im["filename"] for k,v in hist[pid]["outputs"].items() for im in v.get("images",[])]
            print("DONE %.0fs %s"%(time.time()-t0,imgs),flush=True); sys.exit(0)
        if st.get("status_str")=="error": print("ERROR %.0fs %s"%(time.time()-t0,json.dumps(st)[:500]),flush=True); sys.exit(3)
    if int(time.time()-t0)%30<5: print("  ...%.0fs"%(time.time()-t0),flush=True)
print("TIMEOUT",flush=True); sys.exit(4)
