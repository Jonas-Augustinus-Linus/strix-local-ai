# 한국어 보정 GGUF 실행 가이드 — 처음이라도 10분이면 됩니다

이 가이드는 [augustine223의 KO-i1 릴리스](https://huggingface.co/augustine223)
(kanana-1.5-8b, Qwen3.6-35B-A3B 등)를 **처음 로컬 LLM을 접하는 분** 기준으로
실행하는 방법입니다. 프로그래밍 지식이 없어도 됩니다.

## 0. 어떤 파일을 받아야 하나 (가장 중요!)

레포에는 같은 모델의 여러 "압축 강도" 버전이 있습니다. **하나만** 받으면 됩니다.
내 컴퓨터 **RAM**(맥은 통합메모리) 기준으로 고르세요:

### kanana-1.5-8b (가볍고 빠름 — 노트북용 추천)
| 내 RAM | 받을 파일 | 품질 |
|---|---|---|
| 8GB | `KO-i1-IQ3_M` (3.6GB) | 쓸만함 |
| 16GB | `KO-i1-Q4_K_M` (4.6GB) | **표준 추천** |
| 32GB+ | `KO-i1-Q6_K` (6.2GB) | 고품질 |

### Qwen3.6-35B-A3B (고성능 — 데스크톱/고급 노트북용)
| 내 RAM | 받을 파일 | 품질 |
|---|---|---|
| 16GB | `KO-i1-IQ2_M` (12GB) | 빠듯함, 다른 앱 닫기 |
| 24GB | `KO-i1-IQ3_M` (15GB) | 양호 |
| 32GB | `KO-i1-IQ4_XS` (18GB) | **표준 추천** |
| 48GB+ | `KO-i1-Q5_K_M` (24GB) | 고품질 |

> 왜 "KO-i1"인가: 흔한 양자화판은 영어 텍스트 기준으로 압축 손실을 최소화합니다.
> KO-i1은 **한국어 기준으로 보정**해서, 같은 용량에서 한국어 품질이 더 좋습니다
> (측정치는 각 모델 카드 참조).

## 1. 가장 쉬운 방법 — LM Studio (GUI, 클릭만으로 끝)

1. https://lmstudio.ai 에서 설치 (Windows/Mac/Linux)
2. 왼쪽 🔍(Discover) 클릭 → 검색창에 **`augustine223`** 입력
3. 원하는 모델 선택 → 오른쪽에서 위 표의 파일 하나 선택 → **Download**
4. 다운로드 끝나면 💬(Chat) → 상단에서 모델 선택 → 대화 시작

끝입니다. 설정은 기본값이면 충분하고, 느리면 더 작은 파일로 바꾸세요.

**Qwen3.6 사용 시 한 가지**: 이 모델은 답하기 전에 "생각"을 합니다(reasoning).
응답이 비어 보이면 LM Studio 설정에서 **max tokens를 4000 이상**으로 올리세요 —
생각 토큰이 한도를 다 먹으면 정작 답변이 잘립니다.

## 2. 터미널이 무섭지 않다면 — ollama 한 줄

[ollama](https://ollama.com) 설치 후:

```bash
# kanana (표준 추천 양자)
ollama run hf.co/augustine223/kanana-1.5-8b-instruct-2505-KO-i1-GGUF:Q4_K_M

# Qwen3.6 (RAM 32GB 기준)
ollama run hf.co/augustine223/Qwen3.6-35B-A3B-KO-i1-GGUF:IQ4_XS
```

파일을 따로 받을 필요 없이 이 한 줄이 다운로드+실행을 다 합니다.

## 3. 창작·롤플레이 용도라면 — KoboldCpp

무검열 창작 커뮤니티에서 애용하는 단일 실행파일 GUI입니다.
https://github.com/LostRuins/koboldcpp 에서 받아서 실행 → GGUF 파일 선택 → Launch.
브라우저에 채팅+스토리 모드 UI가 뜹니다.

## 4. 최대 성능을 원한다면 — llama.cpp 직접

이 레포(strix-local-ai)가 쓰는 방식입니다. 내장 웹UI도 있습니다:

```bash
llama-server -m <받은파일>.gguf -c 8192 --jinja -fa on -ngl 99
# 브라우저에서 http://localhost:8080 접속 → 바로 채팅 가능
```

- `-ngl 99`: GPU 있으면 최대 오프로드 (없으면 자동으로 CPU)
- `-c 8192`: 대화 길이(컨텍스트). **반드시 명시** — 생략하면 모델 최대치로 잡아 RAM 폭발
- AMD 내장그래픽(Ryzen AI 시리즈)에서 Qwen3.6은 `-b 1024 -ub 1024` 추가 필수
- 세부 튜닝: [vulkan-tuning.md](vulkan-tuning.md), 상시 서버 구성: [server.md](server.md)

## 자주 묻는 것

- **느려요** → 한 단계 작은 파일로. RAM보다 큰 파일은 고르지 마세요.
- **한국어가 어색해요** → 같은 모델의 다른 배포판(영어 보정)을 받지 않았는지 확인.
  파일명에 `KO-i1`이 있어야 이 가이드의 물건입니다.
- **응답이 비어요** → max tokens를 4000+로 (Qwen3.6 등 리즈닝 모델 공통).
- **어떤 모델을 골라야 해요?** → 노트북·일상 대화 = kanana / 고사양·코딩·긴 글 = Qwen3.6.
