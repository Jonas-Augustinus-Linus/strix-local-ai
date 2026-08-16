# eval-ko.txt — Source Attribution

Held-out Korean evaluation text for KLD/perplexity measurement of quantized models.
Built 2026-08-16. Total: 150,924 bytes (KLUE 103,474 B + korea.kr 47,447 B), 232 paragraphs, plain UTF-8.

**Held-out guarantee:** disjoint from the imatrix calibration corpus (`../corpus/*.txt`).
Contamination check: 2 × 30 random 40-char substrings grepped (`grep -F`) against all corpus
files — 30/30 clean (seed 20260816) and 30/30 clean (seed 777). No ko.wikipedia or
ko.wikisource content was used (both are in the calibration corpus).

## Segment 1 — KLUE MRC validation contexts (~103.5 KB)

- **Dataset:** KLUE (Korean Language Understanding Evaluation), config `mrc`, split `validation` (5,841 rows)
- **URL:** https://huggingface.co/datasets/klue/klue
- **License:** CC BY-SA 4.0
- **Citation:** Park et al., "KLUE: Korean Language Understanding Evaluation," NeurIPS 2021 Datasets and Benchmarks.
- **Field used:** `context` only (no questions/answers)
- **Fetch method:** HF datasets-server rows API
  (`https://datasets-server.huggingface.co/rows?dataset=klue%2Fklue&config=mrc&split=validation`)
- **Offsets fetched (length 100 each):** 0, 500, 1000, 1500, 2000, 2500, 3000, 3500, 4000, 4500, 5000, 5500
- **Selection:** contexts deduplicated by whitespace-stripped SHA-1 (MRC repeats contexts across
  questions; 1,200 rows yielded 1,092 unique contexts), then 47 contexts taken round-robin across
  the 12 offsets (4 per offset, 3 from offset 5500) for topical diversity.
- **Cleaning:** HTML entity unescape, residual tag/footnote-marker removal, whitespace
  normalization; each context is one paragraph.

## Segment 2 — korea.kr 정책브리핑 policy news articles (~47.4 KB)

- **Publisher:** 대한민국 정책브리핑 (Korea Policy Briefing), www.korea.kr
- **License:** KOGL Type 1 (공공누리 제1유형 — attribution, free use including commercial and derivative works)
- **Attribution note:** 본 저작물은 대한민국 정책브리핑(www.korea.kr)의 정책뉴스 자료를 이용하였으며,
  해당 저작물은 공공누리 제1유형으로 개방되어 있습니다.
- **Extraction:** article body (`div.article_body`) only; HTML tags, navigation, footers, photo
  captions (Yonhap-copyrighted), and boilerplate stripped via Python `html.parser` + regex.
  All 9 pages verified published in August 2026 via each page's `regiDate` field.

| # | Date | Title | URL |
|---|------|-------|-----|
| 1 | 2026-08-15 | 이 대통령 "새로운 광복 필요…대체불가 대한민국 향해 나아가야" | https://www.korea.kr/news/policyNewsView.do?newsId=148970156 |
| 2 | 2026-08-07 | 세계 두드린 청년 장제사들 "정답 없는 일…말이 믿어줄 때 가장 행복" | https://www.korea.kr/news/policyNewsView.do?newsId=148969630 |
| 3 | 2026-08-12 | 정부, '7대 SEED' 추진 방안 발표…SMR·양자·우주 등 미래 먹거리로 | https://www.korea.kr/news/policyNewsView.do?newsId=148969972 |
| 4 | 2026-08-13 | 수도권에 23만 호+α 추가 공급…부동산PF 자금지원 늘려 속도전 | https://www.korea.kr/news/policyNewsView.do?newsId=148970016 |
| 5 | 2026-08-11 | 이 대통령 "세종·충청이 새 균형발전 시대의 중심…범정부적 최선" | https://www.korea.kr/news/policyNewsView.do?newsId=148969862 |
| 6 | 2026-08-11 | 자녀 돌봄 필요할 때 1~2주 단기 육아휴직…20일부터 시행 | https://www.korea.kr/news/policyNewsView.do?newsId=148969857 |
| 7 | 2026-08-14 | "수출 확대·내수 개선으로 경기회복 흐름 강화" 최근 경제동향 | https://www.korea.kr/news/policyNewsView.do?newsId=148970103 |
| 8 | 2026-08-14 | 김정관 장관, 빌 게이츠 테라파워 의장 면담…SMR 협력방안 논의 | https://www.korea.kr/news/policyNewsView.do?newsId=148970126 |
| 9 | 2026-08-14 | 서대문형무소에서 홀로그램으로 다시 만나는 '유관순 열사' | https://www.korea.kr/news/policyNewsView.do?newsId=148970104 |
