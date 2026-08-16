# Segment 3 sources — Korean conversational & instruction-style text

Output file: `seg3-conversation-ko.txt` (1,204,539 bytes, UTF-8 plain text).
All rows fetched via the Hugging Face datasets-server API
(`https://datasets-server.huggingface.co/rows?dataset=<id>&config=default&split=train&offset=<o>&length=100`)
on 2026-08-16. Licenses verified via `https://huggingface.co/api/datasets/<id>` (`cardData.license`).
Q&A pairs reformatted as `질문: ... / 답변: ...` dialogue blocks; markup stripped, LaTeX-heavy and
non-Korean rows filtered, exact-duplicate blocks removed, trailing unanswered turns trimmed.
Byte counts per dataset are approximate (pre-cleanup).

| Dataset | URL | License | Split | Row ranges used (row_idx) | ~Bytes |
|---|---|---|---|---|---|
| nlpai-lab/kullm-v2 | https://huggingface.co/datasets/nlpai-lab/kullm-v2 | apache-2.0 | train | 0–151, 55000–55087, 110000–110050 | 301 KB |
| heegyu/korquad-chat-v1 | https://huggingface.co/datasets/heegyu/korquad-chat-v1 | mit | train | 0–89, 4800–4888 | 221 KB |
| jojo0217/korean_safe_conversation | https://huggingface.co/datasets/jojo0217/korean_safe_conversation | apache-2.0 | train | 0–145, 13500–13592 | 181 KB |
| maywell/koVast | https://huggingface.co/datasets/maywell/koVast | mit | train | 0–65, 340000–340096 | 221 KB |
| kyujinpy/KOpen-platypus | https://huggingface.co/datasets/kyujinpy/KOpen-platypus | cc-by-4.0 | train | 0–192, 12000–12911 (LaTeX-heavy rows skipped) | 132 KB |
| nlpai-lab/openassistant-guanaco-ko | https://huggingface.co/datasets/nlpai-lab/openassistant-guanaco-ko | apache-2.0 | train | 0–48, 5000–5039 | 151 KB |

## Candidates checked and REJECTED (no verified permissive license)

- beomi/KoAlpaca-v1.1a — no license in cardData
- HAERAE-HUB/KOREAN-WEBTEXT, HAERAE-HUB/KoInstruct-QA, HAERAE-HUB/K2-Feedback — no license in cardData
- HAERAE-HUB/HAE_RAE_BENCH_1.1 — cc-by-nc-nd-4.0 (NC/ND)
- maywell/ko_wikidata_QA — no license in cardData
- kyujinpy/KoOpenOrca-Platypus-v3 — no license in cardData
- heegyu/open-korean-instructions — mit card, but aggregates unlicensed sources (e.g. KoAlpaca); skipped for provenance safety
- devngho/korean-instruction-mix — cc-by-sa-4.0 card, but mixed provenance; skipped
- dbdu/ShareGPT-74k-ko — cc-by-2.0 card, but scraped ShareGPT provenance; skipped
- FreedomIntelligence/evol-instruct-korean, FreedomIntelligence/alpaca-gpt4-korean — no license
- neuralfoundry-coder/aihub-korean-education-instruct-sample — cc-by-nc-sa-4.0 (NC)
- CertifiedJoon/Korean-Instruction — cdla-permissive-2.0 (not in the allowed set)
- smilegate-ai/kor_ethical_question_answer — no license in cardData
- coastral/korean-writing-style-instruct — apache-2.0, eligible but unused (archaic writing style off-topic for this segment)
