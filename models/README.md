# models/

실제 모델 파일은 `~/models`에 저장한다 (git 관리 밖, .gitignore 처리됨).
이 디렉터리에는 보유 모델 목록과 출처만 기록한다.

| 파일 | 출처 | 용도 |
|---|---|---|
| Qwen3-4B-Instruct-2507-Q4_K_M.gguf | unsloth/Qwen3-4B-Instruct-2507-GGUF | 파이프라인 검증용 첫 모델 (Qwen 공식 GGUF 레포는 없음) |
| gemma-4-26B_q4_0-it.gguf (14.4GB) | google/gemma-4-26B-A4B-it-qat-q4_0-gguf | 주력 1순위. MoE 26B-A4B, QAT Q4_0, Apache 2.0. 레포명 대소문자 주의 |
| gemma-4-26B-it-mmproj.gguf (1.2GB) | 〃 | Gemma 4 비전 프로젝터 (이미지 입력용) |
| gpt-oss-20b-MXFP4.gguf (12.1GB) | ggml-org/gpt-oss-20b-GGUF | 주력 2순위. `--jinja` 필수 (Harmony 템플릿). eagle3 드래프트 모델 별도 존재 |
