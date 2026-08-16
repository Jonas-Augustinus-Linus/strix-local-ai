# Segment 4 sources — English encyclopedic prose + source code

Segment 4 of the Korean imatrix calibration corpus: English/code admixture (~20% of corpus)
to prevent imatrix over-specialization on Korean text.

## 4a — seg4-english.txt (English Wikipedia, CC BY-SA 4.0)

Text extracted via the MediaWiki API (`action=query&prop=extracts&explaintext=1`) from
English Wikipedia (en.wikipedia.org), fetched 2026-08-16. Cleaning applied: section
headings removed; boilerplate sections (References, External links, See also, Notes,
Bibliography, etc.) dropped; `{\displaystyle ...}` LaTeX residue stripped; each article
trimmed to about 30 KB at a paragraph boundary. Body prose is otherwise unmodified.

**License: CC BY-SA 4.0** (Creative Commons Attribution-ShareAlike 4.0 International,
https://creativecommons.org/licenses/by-sa/4.0/). Attribution: Wikipedia contributors;
full author history available at each article URL.

| # | Article | URL | License |
|---|---------|-----|---------|
| 1 | Alan Turing | https://en.wikipedia.org/wiki/Alan_Turing | CC BY-SA 4.0 |
| 2 | Photosynthesis | https://en.wikipedia.org/wiki/Photosynthesis | CC BY-SA 4.0 |
| 3 | Roman Empire | https://en.wikipedia.org/wiki/Roman_Empire | CC BY-SA 4.0 |
| 4 | Quantum mechanics | https://en.wikipedia.org/wiki/Quantum_mechanics | CC BY-SA 4.0 |
| 5 | Ludwig van Beethoven | https://en.wikipedia.org/wiki/Ludwig_van_Beethoven | CC BY-SA 4.0 |
| 6 | Great Barrier Reef | https://en.wikipedia.org/wiki/Great_Barrier_Reef | CC BY-SA 4.0 |
| 7 | Machine learning | https://en.wikipedia.org/wiki/Machine_learning | CC BY-SA 4.0 |
| 8 | French Revolution | https://en.wikipedia.org/wiki/French_Revolution | CC BY-SA 4.0 |
| 9 | DNA | https://en.wikipedia.org/wiki/DNA | CC BY-SA 4.0 |
| 10 | Mount Everest | https://en.wikipedia.org/wiki/Mount_Everest | CC BY-SA 4.0 |
| 11 | William Shakespeare | https://en.wikipedia.org/wiki/William_Shakespeare | CC BY-SA 4.0 |
| 12 | Black hole | https://en.wikipedia.org/wiki/Black_hole | CC BY-SA 4.0 |
| 13 | Silk Road | https://en.wikipedia.org/wiki/Silk_Road | CC BY-SA 4.0 |
| 14 | Immune system | https://en.wikipedia.org/wiki/Immune_system | CC BY-SA 4.0 |
| 15 | Industrial Revolution | https://en.wikipedia.org/wiki/Industrial_Revolution | CC BY-SA 4.0 |
| 16 | Jazz | https://en.wikipedia.org/wiki/Jazz | CC BY-SA 4.0 |
| 17 | Antarctica | https://en.wikipedia.org/wiki/Antarctica | CC BY-SA 4.0 |
| 18 | Operating system | https://en.wikipedia.org/wiki/Operating_system | CC BY-SA 4.0 |
| 19 | Western honey bee | https://en.wikipedia.org/wiki/Western_honey_bee | CC BY-SA 4.0 |
| 20 | Renaissance | https://en.wikipedia.org/wiki/Renaissance | CC BY-SA 4.0 |
| 21 | Plate tectonics | https://en.wikipedia.org/wiki/Plate_tectonics | CC BY-SA 4.0 |
| 22 | Linguistics | https://en.wikipedia.org/wiki/Linguistics | CC BY-SA 4.0 |
| 23 | Game theory | https://en.wikipedia.org/wiki/Game_theory | CC BY-SA 4.0 |
| 24 | Impressionism | https://en.wikipedia.org/wiki/Impressionism | CC BY-SA 4.0 |
| 25 | Volcano | https://en.wikipedia.org/wiki/Volcano | CC BY-SA 4.0 |
| 26 | Cryptography | https://en.wikipedia.org/wiki/Cryptography | CC BY-SA 4.0 |

## 4b — seg4-code.txt (llama.cpp source code, MIT)

Twelve source files (3 Python, 7 C++, 2 shell) taken from the local checkout of
llama.cpp at commit `ece963f41b0b02d7a0d61436ae365762c073a4c8` (2026-08-15),
concatenated verbatim with a `// FILE: <path>` separator line before each file.

**License: MIT** (https://github.com/ggml-org/llama.cpp/blob/master/LICENSE),
Copyright (c) 2023-2026 The ggml authors.

| # | File | Repository URL | License |
|---|------|----------------|---------|
| 1 | convert_lora_to_gguf.py | https://github.com/ggml-org/llama.cpp/blob/master/convert_lora_to_gguf.py | MIT |
| 2 | gguf-py/gguf/gguf_reader.py | https://github.com/ggml-org/llama.cpp/blob/master/gguf-py/gguf/gguf_reader.py | MIT |
| 3 | gguf-py/gguf/quants.py | https://github.com/ggml-org/llama.cpp/blob/master/gguf-py/gguf/quants.py | MIT |
| 4 | examples/simple/simple.cpp | https://github.com/ggml-org/llama.cpp/blob/master/examples/simple/simple.cpp | MIT |
| 5 | examples/simple-chat/simple-chat.cpp | https://github.com/ggml-org/llama.cpp/blob/master/examples/simple-chat/simple-chat.cpp | MIT |
| 6 | examples/batched/batched.cpp | https://github.com/ggml-org/llama.cpp/blob/master/examples/batched/batched.cpp | MIT |
| 7 | examples/retrieval/retrieval.cpp | https://github.com/ggml-org/llama.cpp/blob/master/examples/retrieval/retrieval.cpp | MIT |
| 8 | examples/speculative/speculative.cpp | https://github.com/ggml-org/llama.cpp/blob/master/examples/speculative/speculative.cpp | MIT |
| 9 | tools/quantize/quantize.cpp | https://github.com/ggml-org/llama.cpp/blob/master/tools/quantize/quantize.cpp | MIT |
| 10 | tools/imatrix/imatrix.cpp | https://github.com/ggml-org/llama.cpp/blob/master/tools/imatrix/imatrix.cpp | MIT |
| 11 | scripts/check-requirements.sh | https://github.com/ggml-org/llama.cpp/blob/master/scripts/check-requirements.sh | MIT |
| 12 | ci/run.sh | https://github.com/ggml-org/llama.cpp/blob/master/ci/run.sh | MIT |

## Totals

- seg4-english.txt: 749,281 bytes (26 articles)
- seg4-code.txt: 269,284 bytes (12 files)
- Segment total: 1,018,565 bytes
