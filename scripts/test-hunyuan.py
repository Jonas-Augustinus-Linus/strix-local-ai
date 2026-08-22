#!/usr/bin/env python3
# HunyuanVideo 1.5 (8B) gfx1150 스모크. 512²/17f/6step (작게=행위험 최소). 8B라 Wan14B보다 작음 → 경계선 테스트.
import json, time, urllib.request, sys, urllib.error
H="http://127.0.0.1:8188"
POS="a Korean woman in a hanbok smiling in an autumn hanok courtyard, gentle breeze, cinematic, smooth motion"
NEG="static, blurry, distorted, low quality, watermark"
wf={
 "1":{"class_type":"UnetLoaderGGUF","inputs":{"unet_name":"720p/hunyuanvideo1.5_720p_t2v-Q6_K.gguf"}},
 "2":{"class_type":"DualCLIPLoader","inputs":{"clip_name1":"qwen_2.5_vl_7b_fp8_scaled.safetensors","clip_name2":"byt5_small_glyphxl_fp16.safetensors","type":"hunyuan_video_15"}},
 "3":{"class_type":"VAELoader","inputs":{"vae_name":"hunyuanvideo15_vae_fp16.safetensors"}},
 "4":{"class_type":"CLIPTextEncode","inputs":{"text":POS,"clip":["2",0]}},
 "5":{"class_type":"CLIPTextEncode","inputs":{"text":NEG,"clip":["2",0]}},
 "6":{"class_type":"EmptyHunyuanVideo15Latent","inputs":{"width":512,"height":512,"length":17,"batch_size":1}},
 "7":{"class_type":"KSampler","inputs":{"seed":42,"steps":6,"cfg":6.0,"sampler_name":"euler","scheduler":"simple","denoise":1.0,"model":["1",0],"positive":["4",0],"negative":["5",0],"latent_image":["6",0]}},
 "8":{"class_type":"VAEDecodeTiled","inputs":{"samples":["7",0],"vae":["3",0],"tile_size":256,"overlap":64,"temporal_size":8,"temporal_overlap":4}},
 "9":{"class_type":"VHS_VideoCombine","inputs":{"images":["8",0],"frame_rate":16,"loop_count":0,"filename_prefix":"video/hunyuan-test","format":"video/h264-mp4","pingpong":False,"save_output":True}}
}
def post(p,o):
    r=urllib.request.Request(H+p,data=json.dumps(o).encode(),headers={"Content-Type":"application/json"})
    return json.load(urllib.request.urlopen(r,timeout=30))
def get(p): return json.load(urllib.request.urlopen(H+p,timeout=30))
print("══════ HunyuanVideo1.5 T2V (512² 17f 6step) ══════",flush=True)
t0=time.time()
try: pid=post("/prompt",{"prompt":wf})["prompt_id"]
except urllib.error.HTTPError as e:
    print("SUBMIT-FAIL 400:",e.read().decode()[:600],flush=True); sys.exit(2)
except Exception as e:
    print("SUBMIT-FAIL:",e,flush=True); sys.exit(2)
print("submitted",pid,flush=True)
while time.time()-t0 < 900:
    time.sleep(6)
    try: hist=get("/history/"+pid)
    except Exception: continue
    if pid in hist:
        st=hist[pid].get("status",{})
        if st.get("completed"):
            outs=[im.get("subfolder","")+"/"+im.get("filename","") for k,v in hist[pid]["outputs"].items() for key in ("gifs","videos","images") for im in v.get(key,[])]
            print("DONE %.0fs outputs=%s"%(time.time()-t0,outs),flush=True); sys.exit(0)
        if st.get("status_str")=="error":
            print("ERROR %.0fs :: %s"%(time.time()-t0,json.dumps(st)[:600]),flush=True); sys.exit(3)
    if int(time.time()-t0)%30<6: print("  ...running %.0fs (gpu=%s%%)"%(time.time()-t0, open('/sys/class/drm/card0/device/gpu_busy_percent').read().strip() if __import__('os').path.exists('/sys/class/drm/card0/device/gpu_busy_percent') else '?'),flush=True)
print("TIMEOUT %.0fs (행 의심)"%(time.time()-t0),flush=True); sys.exit(4)
