#!/usr/bin/env python3
# augustinus 허브 서버 (8189): 접근코드 인증 + 정적페이지 + 한→영 번역 + GPU 모드전환 + 결과물 갤러리
#   인증: 첫 방문 시 코드 설정(기본 비번 없음) → HMAC 서명 쿠키(30일). 코드는 해시로만 저장.
#   갤러리: ~/사진/strix-ai 이미지 색인/썸네일/삭제 (원격 데스크탑 대신 폴더 색인).
import json, os, base64, time, subprocess, urllib.parse, hmac, hashlib, secrets, io, glob, shutil
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))
COMFY_INPUT = os.path.expanduser("~/ComfyUI/input")
GALLERY = os.path.realpath(os.path.expanduser("~/사진/strix-ai"))
CFG_DIR = os.path.expanduser("~/.config/strix-hub")
CFG_FILE = os.path.join(CFG_DIR, "auth.json")
IMG_EXT = (".png", ".jpg", ".jpeg", ".webp")

# ---------------- 인증 ----------------
def load_cfg():
    os.makedirs(CFG_DIR, exist_ok=True)
    cfg = {}
    if os.path.isfile(CFG_FILE):
        try: cfg = json.load(open(CFG_FILE))
        except Exception: cfg = {}
    if "secret" not in cfg:
        cfg["secret"] = secrets.token_hex(32); save_cfg(cfg)
    return cfg
def save_cfg(cfg):
    os.makedirs(CFG_DIR, exist_ok=True)
    with open(CFG_FILE, "w") as f: json.dump(cfg, f)
    try: os.chmod(CFG_FILE, 0o600)
    except Exception: pass
def hash_code(salt, code): return hashlib.sha256((salt + code).encode()).hexdigest()
def make_token(secret, days=30):
    exp = int(time.time()) + days * 86400
    msg = str(exp).encode()
    sig = hmac.new(bytes.fromhex(secret), msg, hashlib.sha256).hexdigest()
    return base64.urlsafe_b64encode(msg).decode().rstrip("=") + "." + sig
def valid_token(secret, token):
    try:
        b64, sig = token.split(".")
        msg = base64.urlsafe_b64decode(b64 + "===")
        exp = int(msg.decode())
        good = hmac.compare_digest(sig, hmac.new(bytes.fromhex(secret), msg, hashlib.sha256).hexdigest())
        return good and exp > time.time()
    except Exception: return False

# ---------------- 번역 ----------------
_tr = None
def translate(text):
    global _tr
    if not text.strip(): return text
    try:
        if _tr is None:
            import argostranslate.translate as t; _tr = t
        return _tr.translate(text, "ko", "en")
    except Exception: return text

# ---------------- 갤러리 경로 안전 ----------------
def safe(rel):
    p = os.path.realpath(os.path.join(GALLERY, rel.lstrip("/")))
    return p if (p == GALLERY or p.startswith(GALLERY + os.sep)) else None

# ---------------- 웹터미널 자격증명 동기화 (비번 = 허브 접근코드) ----------------
TERM_CRED = os.path.expanduser("~/.config/strix-hub/terminal-cred")
def sync_term_cred(code, restart=True):
    cfg = load_cfg()
    user = cfg.get("term_user", "augustinus")
    os.makedirs(os.path.dirname(TERM_CRED), exist_ok=True)
    with open(TERM_CRED, "w") as f: f.write(f"{user}:{code}")
    try: os.chmod(TERM_CRED, 0o600)
    except Exception: pass
    if restart:
        try: subprocess.run(["systemctl", "--user", "restart", "ttyd"], timeout=12)
        except Exception: pass

LOGIN_HTML = """<!doctype html><html lang=ko><head><meta charset=utf-8>
<title>augustinus · auth</title><meta name=viewport content="width=device-width,initial-scale=1">
<link href="https://fonts.googleapis.com/css2?family=Nanum+Gothic+Coding:wght@400;700&family=JetBrains+Mono:wght@400;700&display=swap" rel=stylesheet>
<style>
:root{--bg:#0A0C10;--panel:#0F1218;--line:#1E2530;--fg:#ECEEF1;--dim:#828A94;--faint:#4A515C;--grn:#4DE08A;--grn-d:#2C9E5F;--grn-bg:#0E1E16;--red:#F0645A}
*{box-sizing:border-box}body{margin:0;min-height:100vh;display:grid;place-items:center;background:var(--bg);
color:var(--fg);font-family:"Nanum Gothic Coding","JetBrains Mono",ui-monospace,monospace;padding:20px;font-size:14px;
background-image:radial-gradient(900px 400px at 50% 0%,#12161d 0,transparent 70%)}
.box{width:100%;max-width:420px;background:var(--panel);border:1px solid var(--line);padding:22px 22px 24px}
.bar{display:flex;gap:6px;margin:-22px -22px 18px;padding:8px 12px;border-bottom:1px solid var(--line);color:var(--dim);font-size:12px}
.bar .d{width:9px;height:9px;border-radius:50%;background:#2a2f39;display:inline-block;margin-top:4px}
.bar .d.g{background:var(--grn-d)}
pre.logo{color:var(--grn);font-size:10.5px;line-height:1.25;margin:0 0 14px;font-family:"JetBrains Mono",monospace;white-space:pre;overflow-x:auto}
.line{color:var(--dim);font-size:12.5px;margin:2px 0}.line .g{color:var(--grn)}
label{font-size:12px;color:var(--dim);display:block;margin:16px 0 6px}label::before{content:"$ ";color:var(--grn)}
input{width:100%;padding:11px 12px;border:1px solid var(--line);background:#070A0E;color:var(--grn);
font-size:15px;font-family:inherit;letter-spacing:.1em}
input:focus{outline:none;border-color:var(--grn)}
button{width:100%;margin-top:18px;padding:12px;border:1px solid var(--grn-d);background:var(--grn-bg);color:var(--grn);
font-size:14px;font-weight:700;font-family:inherit;cursor:pointer}button:hover{background:var(--grn);color:#04110A}
.err{color:var(--red);font-size:12.5px;margin-top:12px;min-height:16px}.err:not(:empty)::before{content:"✗ "}
.hint{color:var(--faint);font-size:11.5px;margin-top:14px;line-height:1.6}.hint::before{content:"# ";color:var(--grn-d)}
.cur{display:inline-block;width:7px;height:14px;background:var(--grn);vertical-align:-2px;animation:bl 1s step-end infinite}
@keyframes bl{50%{opacity:0}}
</style></head><body><div class=box>
<div class=bar><span class="d g"></span><span class=d></span><span class=d></span>&nbsp;augustinus — auth</div>
<div style="color:var(--grn);font-size:26px;font-weight:700;letter-spacing:1px;margin:0 0 12px">augustinus</div>
<div class=line id=sub><span class=g>root@amd-ai-gt-370</span>:~$ auth<span class=cur></span></div>
<label id=lb1>enter passcode</label><input id=c1 type=password autocomplete=off autofocus>
<div id=set2 style=display:none><label>confirm passcode</label><input id=c2 type=password autocomplete=off></div>
<button id=go>authenticate →</button><div class=err id=err></div>
<div class=hint id=hint></div>
<script>
let configured=true;
async function boot(){
 try{const r=await fetch('/auth/status');const j=await r.json();configured=j.configured;}catch(e){}
 if(!configured){
  document.getElementById('sub').innerHTML='<span class="g">root@amd-ai-gt-370</span>:~$ auth --set-passcode<span class=cur></span>';
  document.getElementById('lb1').textContent='set new passcode';document.getElementById('set2').style.display='block';
  document.getElementById('go').textContent='set & authenticate →';
  document.getElementById('hint').textContent='첫 설정 — 기본 비번 없음. 이 코드로 허브·이미지·갤러리에 접근. 잊지 마세요.';}
}
async function submit(){
 const c1=document.getElementById('c1').value, err=document.getElementById('err');err.textContent='';
 if(!c1){err.textContent='코드를 입력하세요';return;}
 if(!configured){const c2=document.getElementById('c2').value;
  if(c1.length<4){err.textContent='4자 이상으로 정하세요';return;}
  if(c1!==c2){err.textContent='두 코드가 다릅니다';return;}}
 const r=await fetch('/auth',{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify({code:c1})});
 if(r.ok){location.href='/';}else{err.textContent='코드가 틀렸습니다';document.getElementById('c1').value='';}
}
document.getElementById('go').onclick=submit;
document.addEventListener('keydown',e=>{if(e.key==='Enter')submit();});
boot();
</script></body></html>"""

# ---------------- 시스템 상태 ----------------
try:
    CPU_MODEL = next(l.split(":",1)[1].strip() for l in open("/proc/cpuinfo") if l.startswith("model name"))
except Exception:
    CPU_MODEL = "unknown"
def _rd(p, d=0):
    try: return int(open(p).read().strip())
    except Exception: return d
def _hwtemp(name, label=None):
    for h in sorted(glob.glob("/sys/class/hwmon/hwmon*")):
        try:
            if open(h+"/name").read().strip() != name: continue
            for ti in sorted(glob.glob(h+"/temp*_input")):
                if label:
                    lf = ti.replace("_input","_label")
                    if not os.path.exists(lf) or open(lf).read().strip() != label: continue
                return round(_rd(ti)/1000)
        except Exception: pass
    return None
def get_stats():
    def snap():
        v = list(map(int, open("/proc/stat").readline().split()[1:]))
        return v[3]+v[4], sum(v)
    i1,t1 = snap(); time.sleep(0.12); i2,t2 = snap()
    cpu = round((1 - (i2-i1)/max(1,(t2-t1)))*100, 1)
    mi = {}
    for line in open("/proc/meminfo"):
        k,_,rest = line.partition(":"); mi[k] = int(rest.split()[0])*1024
    mem_t = mi["MemTotal"]; mem_u = mem_t - mi.get("MemAvailable", mi.get("MemFree",0))
    G = "/sys/class/drm/card1/device"
    du = shutil.disk_usage("/")
    return {
        "cpu_model": CPU_MODEL, "threads": os.cpu_count(), "cpu_pct": cpu,
        "cpu_temp": _hwtemp("k10temp","Tctl"), "gpu_temp": _hwtemp("amdgpu","edge"), "nvme_temp": _hwtemp("nvme","Composite"),
        "mem_total": mem_t, "mem_used": mem_u,
        "gtt_total": _rd(G+"/mem_info_gtt_total"), "gtt_used": _rd(G+"/mem_info_gtt_used"),
        "vram_total": _rd(G+"/mem_info_vram_total"), "vram_used": _rd(G+"/mem_info_vram_used"),
        "gpu_busy": _rd(G+"/gpu_busy_percent"),
        "disk_total": du.total, "disk_used": du.used, "disk_free": du.free,
    }

class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json", extra=None):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        if extra:
            for k, v in extra: self.send_header(k, v)
        self.end_headers()
        if isinstance(body, str): body = body.encode()
        self.wfile.write(body)

    def _cookie(self):
        for part in self.headers.get("Cookie", "").split(";"):
            if "=" in part:
                k, v = part.strip().split("=", 1)
                if k == "strix_session": return v
        return ""
    def _authed(self):
        cfg = load_cfg()
        if "hash" not in cfg: return False
        return valid_token(cfg["secret"], self._cookie())

    def _login_page(self):
        self._send(200, LOGIN_HTML, "text/html")

    def do_POST(self):
        n = int(self.headers.get("Content-Length", 0))
        raw = self.rfile.read(n) if n else b"{}"
        try: data = json.loads(raw or b"{}")
        except Exception: data = {}
        path = self.path.split("?")[0]

        if path == "/auth":  # 로그인 또는 최초 설정 (공개)
            cfg = load_cfg(); code = data.get("code", "")
            if "hash" not in cfg:  # 미설정 → 설정 (최초 로그인)
                if len(code) < 4: return self._send(400, '{"error":"too short"}')
                salt = secrets.token_hex(8)
                cfg["salt"] = salt; cfg["hash"] = hash_code(salt, code); save_cfg(cfg)
                sync_term_cred(code)  # 터미널 비번 = 이 코드 (초기 비번 없음, 최초설정값이 비번)
                tok = make_token(cfg["secret"])
                return self._send(200, '{"ok":true}', extra=[("Set-Cookie", f"strix_session={tok}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=2592000")])
            if code and hash_code(cfg.get("salt", ""), code) == cfg["hash"]:
                tok = make_token(cfg["secret"])
                return self._send(200, '{"ok":true}', extra=[("Set-Cookie", f"strix_session={tok}; Path=/; HttpOnly; Secure; SameSite=Lax; Max-Age=2592000")])
            return self._send(401, '{"error":"bad code"}')

        # 이하 인증 필요
        if not self._authed(): return self._send(401, '{"error":"auth"}')

        if path == "/auth/change":  # 코드 변경
            cfg = load_cfg(); old = data.get("old", ""); new = data.get("new", "")
            if hash_code(cfg.get("salt", ""), old) != cfg.get("hash"):
                return self._send(401, '{"error":"old code wrong"}')
            if len(new) < 4: return self._send(400, '{"error":"too short"}')
            salt = secrets.token_hex(8); cfg["salt"] = salt; cfg["hash"] = hash_code(salt, new); save_cfg(cfg)
            sync_term_cred(new)  # 터미널 비번도 함께 변경
            return self._send(200, '{"ok":true}')
        if path == "/translate":
            return self._send(200, json.dumps({"text": translate(data.get("text", ""))}, ensure_ascii=False))
        if path == "/upload":
            b64 = data.get("image", "")
            if "," in b64: b64 = b64.split(",", 1)[1]
            os.makedirs(COMFY_INPUT, exist_ok=True)
            fn = "ref-%d.png" % int(time.time())
            with open(os.path.join(COMFY_INPUT, fn), "wb") as f: f.write(base64.b64decode(b64))
            return self._send(200, json.dumps({"filename": fn}))
        if path == "/terminal-cred":  # 웹터미널 아이디 변경 (비번은 허브 코드를 따름)
            import re
            user = data.get("user", "").strip()
            if not re.fullmatch(r"[A-Za-z0-9_.-]{2,32}", user):
                return self._send(400, '{"error":"bad username"}')
            cfg = load_cfg(); cfg["term_user"] = user; save_cfg(cfg)
            # 현재 비번(=허브코드) 유지한 채 아이디만 교체
            pw = ""
            if os.path.isfile(TERM_CRED):
                cur = open(TERM_CRED).read()
                if ":" in cur: pw = cur.split(":", 1)[1]
            if pw: sync_term_cred(pw)
            return self._send(200, '{"ok":true}')
        if path == "/delete":  # 갤러리 파일 삭제
            p = safe(data.get("path", ""))
            if not p or not os.path.isfile(p): return self._send(404, '{"error":"not found"}')
            try: os.remove(p); return self._send(200, '{"ok":true}')
            except Exception as e: return self._send(500, json.dumps({"error": str(e)}))
        return self._send(404, "{}")

    def do_GET(self):
        path = self.path.split("?")[0]
        q = urllib.parse.parse_qs(urllib.parse.urlparse(self.path).query)

        if path == "/auth/status":  # 공개 — 설정여부/인증여부
            cfg = load_cfg()
            return self._send(200, json.dumps({"configured": "hash" in cfg, "authed": self._authed()}))

        # 이하 전부 인증 필요. 미인증 시: 데이터 엔드포인트는 401, 페이지는 로그인 화면.
        if not self._authed():
            data_ep = path in ("/list", "/thumb", "/full", "/presets", "/logout", "/stats") or path.startswith("/mode")
            return self._send(401, '{"error":"auth"}') if data_ep else self._login_page()

        if path == "/logout":
            return self._send(200, '{"ok":true}', extra=[("Set-Cookie", "strix_session=; Path=/; Max-Age=0")])
        if path.startswith("/mode"):
            to = q.get("to", [""])[0]
            if to == "image": subprocess.run(["systemctl", "--user", "start", "comfyui"], timeout=10)
            elif to == "chat": subprocess.run(["systemctl", "--user", "stop", "comfyui"], timeout=15)
            def active(u):
                return subprocess.run(["systemctl", "--user", "is-active", u], capture_output=True, text=True).stdout.strip() == "active"
            mode = "image" if active("comfyui") else ("chat" if active("llama-router") else "off")
            return self._send(200, json.dumps({"mode": mode}))
        if path == "/presets":
            pdir = os.path.join(COMFY_INPUT, "presets")
            files = sorted(f for f in os.listdir(pdir)) if os.path.isdir(pdir) else []
            files = [f for f in files if f.lower().endswith(IMG_EXT)]
            return self._send(200, json.dumps(files))
        if path == "/stats":  # 시스템 상태 (CPU/RAM/GTT/온도/디스크)
            try: return self._send(200, json.dumps(get_stats()))
            except Exception as e: return self._send(500, json.dumps({"error": str(e)}))
        if path == "/list":  # 갤러리 색인
            items = []
            for root, _, files in os.walk(GALLERY):
                for fn in files:
                    if fn.lower().endswith(IMG_EXT):
                        fp = os.path.join(root, fn)
                        rel = os.path.relpath(fp, GALLERY)
                        try: st = os.stat(fp)
                        except Exception: continue
                        folder = os.path.dirname(rel) or "."
                        items.append({"path": rel, "name": fn, "folder": folder, "size": st.st_size, "mtime": int(st.st_mtime)})
            items.sort(key=lambda x: x["mtime"], reverse=True)
            return self._send(200, json.dumps(items, ensure_ascii=False))
        if path in ("/thumb", "/full"):
            p = safe((q.get("p", [""])[0]))
            if not p or not os.path.isfile(p): return self._send(404, "no", "text/plain")
            if path == "/full":
                ct = "image/png" if p.lower().endswith(".png") else "image/jpeg"
                with open(p, "rb") as f: return self._send(200, f.read(), ct)
            try:
                from PIL import Image
                im = Image.open(p).convert("RGB"); im.thumbnail((360, 360))
                buf = io.BytesIO(); im.save(buf, "JPEG", quality=80)
                return self._send(200, buf.getvalue(), "image/jpeg")
            except Exception:
                with open(p, "rb") as f: return self._send(200, f.read(), "image/png")

        # 정적 파일
        rel = "index.html" if path in ("/", "") else path.lstrip("/")
        fp = os.path.join(ROOT, os.path.basename(rel))
        if os.path.isfile(fp):
            ext = os.path.splitext(fp)[1]
            ct = {".html":"text/html", ".js":"text/javascript", ".css":"text/css",
                  ".json":"application/json", ".svg":"image/svg+xml"}.get(ext, "application/octet-stream")
            with open(fp, "rb") as f: return self._send(200, f.read(), ct+"; charset=utf-8" if ct.startswith("text") else ct)
        return self._send(404, "not found", "text/plain")

    def log_message(self, *a): pass

if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8189), H).serve_forever()
