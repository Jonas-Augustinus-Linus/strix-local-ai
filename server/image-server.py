#!/usr/bin/env python3
# Strix 이미지 페이지 서버 (8189): 정적 파일 + 한→영 오프라인 번역 엔드포인트
# 번역은 Argos Translate (CPU, 오프라인) — 이미지 모드에서 LLM이 꺼져도 작동
import json, os
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

ROOT = os.path.dirname(os.path.abspath(__file__))

# Argos 번역기 lazy 로드 (없으면 원문 반환)
_tr = None
def translate(text):
    global _tr
    if not text.strip():
        return text
    try:
        if _tr is None:
            import argostranslate.translate as t
            _tr = t
        return _tr.translate(text, "ko", "en")
    except Exception as e:
        return text  # 실패 시 원문 (영어면 그대로)

class H(BaseHTTPRequestHandler):
    def _send(self, code, body, ctype="application/json"):
        self.send_response(code)
        self.send_header("Content-Type", ctype)
        self.send_header("Access-Control-Allow-Origin", "*")
        self.end_headers()
        if isinstance(body, str): body = body.encode()
        self.wfile.write(body)

    def do_POST(self):
        if self.path == "/translate":
            n = int(self.headers.get("Content-Length", 0))
            data = json.loads(self.rfile.read(n) or b"{}")
            out = translate(data.get("text", ""))
            self._send(200, json.dumps({"text": out}, ensure_ascii=False))
        else:
            self._send(404, "{}")

    def do_GET(self):
        path = "index.html" if self.path in ("/", "") else self.path.lstrip("/")
        path = path.split("?")[0]
        fp = os.path.join(ROOT, os.path.basename(path))
        if os.path.isfile(fp):
            ctype = "text/html" if fp.endswith(".html") else "application/octet-stream"
            with open(fp, "rb") as f:
                self._send(200, f.read(), ctype)
        else:
            self._send(404, "not found", "text/plain")

    def log_message(self, *a): pass

if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8189), H).serve_forever()
