#!/usr/bin/env python3
# Wan2.2-T2V-A14B (2-expert MoE) gfx1150 스모크. HighNoise(0→boundary)→LowNoise(boundary→end).
# 480² 1초(17f) 8스텝 — 행 감지용 짧게. Wan 5B는 작동함(메모리) → 14B가 되는지가 관건.
import json, time, urllib.request, sys
H="http://127.0.0.1:8188"
POS="a serene Korean woman in a hanbok walking through an autumn hanok courtyard, falling leaves, cinematic, smooth camera motion"
NEG="static image, blurry, distorted, low quality, watermark, text"
STEPS=8; BND=4; W=480; HT=480; LEN=17
wf={
 "1":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":"HighNoise/Wan2.2-T2V-A14B-HighNoise-Q5_K_M.gguf"}},
 "2":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":"LowNoise/Wan2.2-T2V-A14B-LowNoise-Q5_K_M.gguf"}},
 "3":{"class_type":"ModelSamplingSD3","inputs":{"model":["1",0],"shift":8.0}},
 "4":{"class_type":"ModelSamplingSD3","inputs":{"model":["2",0],"shift":8.0}},
 "5":{"class_type":"CLIPLoader","inputs":{"clip_name":"umt5_xxl_fp8_e4m3fn_scaled.safetensors","type":"wan"}},
 "6":{"class_type":"VAELoader","inputs":{"vae_name":"wan2.2_vae.safetensors"}},
 "7":{"class_type":"CLIPTextEncode","inputs":{"text":POS,"clip":["5",0]}},
 "8":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["5",0]}},
 "9":{"class_type":"Wan22ImageToVideoLatent","inputs":{"vae":["6",0],"width":W,"height":HT,"length":LEN,"batch_size":1}},
 "10":{"class_type":"KSamplerAdvanced","inputs":{"add_noise":"enable","noise_seed":42,"steps":STEPS,"cfg":3.5,"sampler_name":"euler","scheduler":"simple","start_at_step":0,"end_at_step":BND,"return_with_leftover_noise":"enable","model":["3",0],"positive":["7",0],"negative":["8",0],"latent_image":["9",0]}},
 "11":{"class_type":"KSamplerAdvanced","inputs":{"add_noise":"disable","noise_seed":42,"steps":STEPS,"cfg":3.5,"sampler_name":"euler","scheduler":"simple","start_at_step":BND,"end_at_step":10000,"return_with_leftover_noise":"disable","model":["4",0],"positive":["7",0],"negative":["8",0],"latent_image":["10",0]}},
 "12":{"class_type":"VAEDecode","inputs":{"samples":["11",0],"vae":["6",0]}},
 "13":{"class_type":"VHS_VideoCombine","inputs":{"images":["12",0],"frame_rate":16,"loop_count":0,"filename_prefix":"video/wan-a14b-test","format":"video/h264-mp4","pingpong":False,"save_output":True}}
}
def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))
print("══════ Wan2.2-A14B T2V (480² %df %dstep, high→low@%d) ══════"%(LEN,STEPS,BND),flush=True)
t0=time.time()
try: pid=post("/prompt",{"prompt":wf})["prompt_id"]
except Exception as e:
    import urllib.error
    if isinstance(e,urllib.error.HTTPError):
        print("SUBMIT-FAIL 400:",e.read().decode()[:500],flush=True)
    else: print("SUBMIT-FAIL:",e,flush=True)
    sys.exit(2)
print("submitted",pid,flush=True)
while time.time()-t0 < 900:
    time.sleep(6)
    try: hist=get("/history/"+pid)
    except Exception: continue
    if pid in hist:
        st=hist[pid].get("status",{})
        if st.get("completed"):
            outs=[]
            for k,v in hist[pid]["outputs"].items():
                for key in ("gifs","videos","images"):
                    for im in v.get(key,[]): outs.append(im.get("subfolder","")+"/"+im.get("filename",""))
            print("DONE %.0fs outputs=%s"%(time.time()-t0,outs),flush=True); sys.exit(0)
        if st.get("status_str")=="error":
            print("ERROR %.0fs :: %s"%(time.time()-t0,json.dumps(st)[:500]),flush=True); sys.exit(3)
    if int(time.time()-t0)%30<6: print("  ...running %.0fs"%(time.time()-t0),flush=True)
print("TIMEOUT %.0fs (행 의심)"%(time.time()-t0),flush=True); sys.exit(4)
