#!/usr/bin/env python3
"""세그먼트별 비율 유지 서브샘플링으로 imatrix 보정 코퍼스 생성.

문단(빈 줄 구분) 단위로 균등 간격 샘플링 — 다양성 보존, 결정론적(재현 가능).
목표 ~1.5MB, 한국어 ~79% (방법론: ~1MB 이상 수확 체감, mradermacher 권고 준수).
"""
import pathlib

DIR = pathlib.Path(__file__).parent / "corpus"
OUT = DIR / "calibration.txt"

# (파일, 목표 바이트)
PLAN = [
    ("seg1-wiki-ko.txt", 550_000),
    ("seg2-literature-ko.txt", 330_000),
    ("seg3-conversation-ko.txt", 330_000),
    ("seg4-english.txt", 220_000),
    ("seg4-code.txt", 100_000),
]

def sample(path: pathlib.Path, target: int) -> str:
    paras = [p for p in path.read_text(encoding="utf-8").split("\n\n") if p.strip()]
    total = sum(len(p.encode("utf-8")) for p in paras)
    if total <= target:
        return "\n\n".join(paras)
    # 균등 간격으로 문단 선택
    picked, acc, step, i = [], 0, total / target, 0.0
    while int(i) < len(paras) and acc < target:
        p = paras[int(i)]
        picked.append(p)
        acc += len(p.encode("utf-8")) + 2
        i += step
    return "\n\n".join(picked)

parts, report = [], []
for name, target in PLAN:
    text = sample(DIR / name, target)
    parts.append(text)
    report.append(f"{name}: {len(text.encode('utf-8')):,} bytes (목표 {target:,})")

OUT.write_text("\n\n".join(parts), encoding="utf-8")
total = OUT.stat().st_size
ko = sum(len(p.encode("utf-8")) for p, (n, _) in zip(parts, PLAN) if "-ko" in n)
print("\n".join(report))
print(f"TOTAL: {total:,} bytes | 한국어 비중 ≈ {ko/total:.0%}")
