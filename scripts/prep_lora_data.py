#!/usr/bin/env python3
"""
LoRA 데이터 준비 도구 — 원본 이미지 폴더를 학습용으로 정규화 + 검증 + 캡션.

하는 일:
  1) 어떤 포맷/크기든 읽어 → EXIF 회전 보정 → RGB 변환(알파 제거) → 최대변 1024로 축소(확대 안 함)
     → ~/lora-data/<name>/img/NNN.png 로 저장
  2) 완전 중복(동일 해시) 자동 스킵, 너무 작은 이미지(경고) 리포트
  3) 캡션: --trigger <단어> 면 각 이미지에 "<단어>" 만 적은 .txt 생성(스타일 LoRA 정석)
     (캐릭터/개념 LoRA로 세부 태그가 필요하면 --wd14 로 자동 태깅 — onnxruntime 필요)

사용:
  python3 prep_lora_data.py <name> --src <원본폴더> [--trigger mystyle] [--max 1024] [--wd14]
예:
  # 스타일 LoRA (트리거만)
  python3 prep_lora_data.py hanbok_style --src ~/사진/원본한복 --trigger hanbokstyle
  # 캐릭터 LoRA (자동 태그)
  python3 prep_lora_data.py mychar --src ~/raw/mychar --trigger mychar --wd14
"""
import argparse, os, sys, hashlib, subprocess
from pathlib import Path
try:
    from PIL import Image, ImageOps
except ImportError:
    sys.exit("PIL 없음 — /home/amd-ai/venvs/lora/bin/python 로 실행하세요")

EXT = {".png", ".jpg", ".jpeg", ".webp", ".bmp", ".tiff", ".avif"}

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("name")
    ap.add_argument("--src", required=True)
    ap.add_argument("--trigger", default="")
    ap.add_argument("--max", type=int, default=1024)
    ap.add_argument("--min", type=int, default=768, help="이보다 작은 원본은 경고(작으면 품질↓)")
    ap.add_argument("--wd14", action="store_true")
    a = ap.parse_args()

    src = Path(os.path.expanduser(a.src))
    if not src.is_dir(): sys.exit(f"원본 폴더 없음: {src}")
    outdir = Path.home() / "lora-data" / a.name / "img"
    outdir.mkdir(parents=True, exist_ok=True)

    raws = sorted([p for p in src.iterdir() if p.suffix.lower() in EXT])
    if not raws: sys.exit(f"이미지 없음: {src} (지원: {sorted(EXT)})")

    seen, kept, small, dup, bad = set(), 0, [], 0, []
    idx = 1
    for p in raws:
        try:
            im = Image.open(p); im = ImageOps.exif_transpose(im); im = im.convert("RGB")
        except Exception as e:
            bad.append(f"{p.name}: {e}"); continue
        w, h = im.size
        if min(w, h) < a.min: small.append(f"{p.name} ({w}x{h})")
        # 완전중복 검사 (리사이즈 전 픽셀 해시)
        hsh = hashlib.md5(im.tobytes()).hexdigest()
        if hsh in seen: dup += 1; continue
        seen.add(hsh)
        # 최대변 max로 축소(확대 금지)
        scale = min(a.max / max(w, h), 1.0)
        if scale < 1.0: im = im.resize((round(w*scale), round(h*scale)), Image.LANCZOS)
        fn = outdir / f"{idx:03d}.png"; im.save(fn)
        if a.trigger:
            (outdir / f"{idx:03d}.txt").write_text(a.trigger + "\n")
        idx += 1; kept += 1

    print(f"\n=== {a.name} 데이터 준비 완료 ===")
    print(f"  저장: {kept}장 → {outdir}")
    if dup:   print(f"  중복 스킵: {dup}장")
    if small: print(f"  ⚠ 작은 이미지({a.min}px 미만) {len(small)}장 — 품질 저하 가능: " + ", ".join(small[:5]) + ("…" if len(small)>5 else ""))
    if bad:   print(f"  ✗ 읽기 실패 {len(bad)}장: " + "; ".join(bad[:3]))
    if a.trigger: print(f"  캡션: 각 이미지에 트리거 '{a.trigger}' .txt 생성")
    # 권장치 체크
    if kept < 10: print(f"  ⚠ {kept}장은 적음 — 15~40장 권장(스타일은 20~50)")
    elif kept > 60: print(f"  ⚠ {kept}장은 많음 — 처음엔 20~40장으로 시작 권장")
    else: print(f"  ✓ 장수 적정")

    if a.wd14:
        print("\n=== WD14 자동 태깅 ===")
        sds = Path.home() / "sd-scripts"
        py = Path.home() / "venvs" / "lora" / "bin" / "python"
        try: subprocess.run([str(py), "-c", "import onnxruntime"], check=True, capture_output=True)
        except Exception:
            print("  onnxruntime 없음 — 설치: /home/amd-ai/venvs/lora/bin/pip install onnxruntime")
            print("  (설치 후 다시 --wd14 로 실행하거나 아래 명령 직접 실행)")
        print(f"  실행: cd {sds} && {py} finetune/tag_images_by_wd14_tagger.py \\")
        print(f"          --repo_id SmilingWolf/wd-v1-4-moat-tagger-v2 --thresh 0.35 --batch_size 4 {outdir}")
        print(f"  → 각 이미지에 danbooru 태그 .txt 생성됨. 그다음 트리거 '{a.trigger}'를 각 .txt 맨 앞에 추가하세요.")

    print(f"\n다음: 확인 후  →  lora-train.sh {a.name}")

if __name__ == "__main__":
    main()
