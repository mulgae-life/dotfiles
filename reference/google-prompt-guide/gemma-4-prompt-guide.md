# Gemma 4 Prompting Guide

> **출처 (공식 1차)**:
> - [Gemma 4 model overview | Google AI for Developers](https://ai.google.dev/gemma/docs/core)
> - [Gemma 4 model card | Google AI for Developers](https://ai.google.dev/gemma/docs/core/model_card_4)
> - [Gemma 4 Prompt Formatting | Google AI for Developers](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
> - [Function calling with Gemma 4 | Google AI for Developers](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
> - [Gemma 4 Multi-Token Prediction (MTP) using Hugging Face Transformers | Google AI for Developers](https://ai.google.dev/gemma/docs/mtp/mtp)
> - [Gemma releases | Google AI for Developers](https://ai.google.dev/gemma/docs/releases)
> - [google/gemma-4-31B-it · Hugging Face](https://huggingface.co/google/gemma-4-31B-it) (chat template 2026-07-15 개정 포함)
> - [google/gemma-4-12B-it · Hugging Face](https://huggingface.co/google/gemma-4-12B-it)
> - [google/gemma-4-31B-it-assistant · Hugging Face](https://huggingface.co/google/gemma-4-31B-it-assistant) (MTP 드래프터)
> - [google/gemma-4-31B-it-qat-w4a16-ct · Hugging Face](https://huggingface.co/google/gemma-4-31B-it-qat-w4a16-ct) / [google/gemma-4-31B-it-qat-q4_0-gguf](https://huggingface.co/google/gemma-4-31B-it-qat-q4_0-gguf) (공식 QAT)
> - [Gemma 4 Technical Report | arXiv 2607.02770 (2026-07-02, v2 2026-07-24)](https://arxiv.org/abs/2607.02770)
> - [Gemma 4 — Google DeepMind](https://deepmind.google/models/gemma/gemma-4/)
> - [Gemma 4: Byte for byte, the most capable open models | Google blog (2026-04-02)](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/)
> - [Accelerating Gemma 4: faster inference with multi-token prediction drafters | Google blog (2026-05-05)](https://blog.google/innovation-and-ai/technology/developers-tools/multi-token-prediction-gemma-4/)
> - [Introducing Gemma 4 12B: a unified, encoder-free multimodal model | Google blog (2026-06-03)](https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemma-4-12b/)
> - [DiffusionGemma | Google blog (2026-06-10)](https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/)
> - [google-gemma/cookbook | GitHub](https://github.com/google-gemma/cookbook) (구 `google-gemini/gemma-cookbook`은 2026-05 아카이브)
>
> **출처 (검증된 외부)**:
> - [Welcome Gemma 4: Frontier multimodal intelligence on device | Hugging Face Blog (2026-04-02)](https://huggingface.co/blog/gemma4)
> - [Gemma4 | Transformers docs](https://huggingface.co/docs/transformers/model_doc/gemma4)
> - [Gemma 4: Byte for byte, the most capable open models | Simon Willison (2026-04-02)](https://simonwillison.net/2026/Apr/2/gemma-4/)
> - [The Big LLM Architecture Comparison (Sec. 23) | Sebastian Raschka, Apr 2026](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
> - [Gemma 4 Usage Guide | vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
> - [Gemma 4 - How to Run Locally | Unsloth](https://unsloth.ai/docs/models/gemma-4)
> - [gemma4 | Ollama Library](https://ollama.com/library/gemma4) / [Ollama v0.23.1 release (Gemma 4 MTP)](https://github.com/ollama/ollama/releases/tag/v0.23.1)
> - [LM Studio 0.4.11 changelog](https://lmstudio.ai/changelog/lmstudio-v0.4.11)
>
> **날짜**: 초판 2026-05-07, 갱신 2026-09-11 (갱신일에 모든 URL 재접근. 공식 페이지 자체 갱신일: model card 2026-07-30, prompt formatting 2026-06-03, function calling 2026-06-04)
> **이전 버전**: Gemma 3 (2025년 3월 출시) — 본 문서 §11 마이그레이션 체크리스트 참조
> **초판 이후 달라진 것**: 12B Unified 추가(5종 체제), chat template 2026-07-15 개정(`preserve_thinking`·인자 검증), audio 배치 규칙 변경(text 뒤), 빈 thought 블록 범위 정정(E2B/E4B 제외 전부), MTP 드래프터·공식 QAT 체크포인트·DiffusionGemma·기술 보고서 추가, 병렬 tool call 공식 포맷 확인. Gemma 4.1이나 5는 2026-09-11 기준 없음

---

## ⚠️ 가장 먼저 알아야 할 것 (Gemma 3 → 4 핵심 변화)

Gemma 4는 **Gemma 3의 드롭인 교체가 아니다.** chat template, control token, system role 정책이 모두 바뀌었다. Gemma 3 시절의 프롬프트를 그대로 쓰면 system 지시가 user 턴에 묻히거나 thinking 채널이 누수되어 출력 품질이 명확히 떨어진다.

Google 공식 문서 [공식, ai.google.dev/gemma/docs/core, 2026-05-07] 중 한 줄 요약:

> "Gemma 4 introduces built-in support for the system role" — Google AI for Developers

> "All models in the family are designed as highly capable reasoners, with configurable thinking modes." — google/gemma-4-31B-it 모델 카드

### 한 페이지 변화 요약

| 항목 | Gemma 3 | Gemma 4 |
|------|---------|---------|
| Chat template 토큰 | `<start_of_turn>` / `<end_of_turn>` | **`<\|turn>` / `<turn\|>`** (완전 교체) |
| System role | **미지원** ("only two roles: `user` and `model`") | **네이티브 지원** (`system` role 신규) |
| Thinking mode | 27B IT의 부분 지원 | **`<\|think\|>` 토큰 + `<\|channel>thought` 블록**으로 표준화, 5개 사이즈 전부 지원 |
| Multimodal | 4B/12B/27B에서 vision (Gemma 3 4B+) | **모든 사이즈 vision + E2B/E4B/12B는 audio 추가**, 모든 사이즈 video |
| Vision token budget | 고정 | **70 / 140 / 280 / 560 / 1120**의 가변 예산 |
| Context length | 128K (대형) | **256K (12B / 26B A4B / 31B)**, 128K (E2B / E4B) |
| Function calling | 비공식 | **6개 special token 기반 공식 포맷** + `<\|"\|>` 문자열 delimiter, 병렬 호출 포맷 명시 |
| 모델 변형 | 1B / 4B / 12B / 27B (밀집) | **E2B / E4B / 12B Unified (2026-06 추가) / 26B A4B (MoE) / 31B (밀집)** — MoE·인코더 없는 12B 신규 |
| 추론 가속 | 없음 | **MTP 드래프터**(`-assistant`, 최대 3배)·공식 QAT 체크포인트(W4A16·Q4_0)·DiffusionGemma(실험) |
| 라이선스 | Gemma Terms of Use (제한적) | **Apache 2.0** (상업 배포 자유) |
| 출시 | 2025-03 | **2026-04-02** |

> Hugging Face 공식 블로그 [검증된 외부, huggingface.co/blog/gemma4, 2026-04-02]: "These models are the real deal: truly open with Apache 2 licenses, high quality with pareto frontier arena scores, multimodal including audio, and sizes you can use everywhere including on-device."

---

## 개요

Gemma 4는 Google DeepMind가 2026년 4월 2일에 출시한 오픈 가중치 모델 패밀리다 [공식, blog.google/innovation-and-ai/technology/developers-tools/gemma-4/, 2026-05-07]. 2026년 6월 3일 12B Unified가 추가되어 5개 사이즈 체제가 됐다 [공식, ai.google.dev/gemma/docs/releases, 2026-09-11]. Apache 2.0 라이선스로 상업 배포 제약이 없으며, 5개 사이즈 모두 vision-capable이고 E2B/E4B/12B는 audio까지 입력으로 받는다. 기술 보고서는 2026-07-02 arXiv 2607.02770로 공개됐다 [공식].

### 핵심 강점

- **Native system role**: Gemma 3의 "user 턴에 system 지시 우겨넣기" 워크어라운드가 사라짐
- **Configurable thinking**: 시스템 프롬프트에 `<|think|>` 토큰 한 줄로 추론 채널 토글
- **Variable visual token budget**: OCR/문서 작업과 분류/캡셔닝을 같은 모델로 비용-품질 곡선 위에서 선택
- **Apache 2.0**: Gemma 3까지 발목 잡았던 라이선스 제약 해소
- **256K context** (12B·26B A4B·31B): 장문맥 retrieval, 코드베이스, 긴 PDF
- **공식 function calling 포맷**: 6개 special token 기반의 결정론적 파싱, 병렬 호출 결과 되돌리기 포맷 명시
- **MTP 드래프터**: 같은 프롬프트로 최대 3배 가속(출력 동일 주장), 5개 사이즈 전부 제공

### 명시적 프롬프팅이 여전히 필요한 영역

- Multi-turn에서 이전 thought 채널을 **반드시 제거**해야 한다는 룰 (자동으로 안 됨. 2026-07 template부터 `preserve_thinking` 인자가 tool call 턴의 예외를 담당)
- `<|"|>` 문자열 delimiter 사용 (표준 JSON quoting과 다름). tool call `arguments`는 문자열이 아니라 JSON 객체로 넘겨야 template이 예외를 내지 않는다
- Multimodal placement: image는 **text 앞**, audio는 **text 뒤** (2026-06 모델 카드 개정으로 audio 규칙이 바뀜)
- Thinking 비활성화 시에도 빈 thought 블록이 emit되는 동작 — E2B/E4B를 제외한 **모든** 모델 (앱 단에서 stripping 필요)

---

## 1. 모델 변형 (Variants)

Google AI for Developers 공식 모델 카드 [공식, ai.google.dev/gemma/docs/core/model_card_4, 페이지 갱신 2026-07-30, 2026-09-11 접근] 기준:

| Variant | 유효/총 파라미터 | 레이어 | Sliding window | Context | 모달리티 (입력) | BF16 메모리 (참고치) | 권장 사용처 |
|---------|------------------|-------|---------------|---------|----------------|---------------------|------------|
| **E2B** | 2.3B 유효 / 5.1B (임베딩 포함) | 35 | 512 | 128K | Text + Image + **Audio** | 9.6 GB | 모바일/IoT, on-device |
| **E4B** | 4.5B 유효 / 8B (임베딩 포함) | 42 | 512 | 128K | Text + Image + **Audio** | 15 GB | 엣지 디바이스, 스마트폰급 |
| **12B Unified** (2026-06-03 추가) | 11.95B (dense, 인코더 없음) | 48 | 1024 | 256K | Text + Image + **Audio** | ~25 GB | 16GB급 노트북에서 audio까지 받는 중형 |
| **26B A4B** | 3.8B active / 25.2B total (MoE, expert 8 active / 128 total + 1 shared) | 30 | 1024 | 256K | Text + Image | 48 GB | latency-optimized 서버, 대용량 동시 요청 |
| **31B** | 30.7B (dense) | 60 | 1024 | 256K | Text + Image | 59.0 GB | 최대 품질, 강한 추론 |

파라미터·레이어·sliding window·context·모달리티·expert 구성은 모델 카드 원문이다. **BF16 메모리 열은 모델 카드에 없다**: 31B 59.0 GB는 vLLM 레시피 QAT 표, 12B ~25 GB는 Unsloth 표 [검증된 외부], E2B·E4B·26B A4B 값은 초판 수치를 유지하되 이번 갱신에서 1차 출처를 다시 찾지 못했으므로 참고치로만 본다. 인코더 파라미터 [공식, 모델 카드]: vision ~150M(E2B/E4B)·~550M(26B A4B/31B), audio ~300M(E2B/E4B/12B). 12B는 vision encoder 항목이 없다(인코더 없는 구조).

> 모델 카드의 "E" 설명 [공식]: "The 'E' in E2B and E4B stands for 'effective' parameters. The smaller models incorporate Per-Layer Embeddings (PLE) to maximize parameter efficiency in on-device deployments."

> 12B "Unified" 설명 [공식, 모델 카드]: "The 'Unified' in Gemma 4 12B Unified refers to its encoder-free architecture ... projecting raw image patches and audio waveforms directly into the LLM's embedding space through lightweight linear layers." Google 블로그 [공식, 2026-06-03]: "No multimodal encoders. The vision and audio inputs flow directly into the LLM backbone." — 다른 4종은 ~150M/~550M vision encoder를 따로 둔다. 기술 보고서 §2.3: 48×48×3 RGB 패치를 단일 matmul(35M)로, 오디오는 16kHz에서 40ms 청크(640차원)로 직접 투영.

**26B A4B 총 파라미터**: 초판에는 "26B total"로 적었으나 현행 모델 카드는 25.2B total로 표기한다. 이름의 26B는 반올림.

**메모리 수치 읽는 법**: 위 표의 BF16 값은 가중치 적재 기준이고, §10.3의 Unsloth 표(31B BF16 62 GB 등)는 GGUF 추론 실행 기준이라 더 크다. KV cache는 둘 다 포함하지 않으므로 컨텍스트 길이에 따라 추가로 잡아야 한다.

**역할 이름**: chat template은 메시지 딕셔너리의 `assistant`를 렌더링 시 `model`로 바꾸고(`set role = 'model' if message['role'] == 'assistant'`), 첫 메시지의 `developer`를 `system`과 같이 취급한다 [공식, HF 31B `chat_template.jinja`]. 그래서 모델 카드는 "standard `system`, `assistant`, and `user` roles"라 적고, 프롬프트 포맷 문서는 렌더링 결과인 `<|turn>model`을 보여 준다. 메시지 API 수준에서는 `assistant`, 원시 텍스트 수준에서는 `model`이다.

**라이선스**: 모든 변형 Apache 2.0 [공식, 모델 카드]. MTP 드래프터·QAT 체크포인트·DiffusionGemma도 동일 [공식, 각 블로그].

### 1.1 파생 체크포인트 (2026-04 ~ 07 추가)

| 종류 | 모델 ID (31B 기준) | 용도 | 출처 |
|------|-------------------|------|------|
| MTP 드래프터 | `google/gemma-4-31B-it-assistant` (0.5B) | speculative decoding, 최대 3배 가속, 출력 동일 | [공식, HF 카드·Google 블로그 2026-05-05] |
| QAT W4A16 (compressed-tensors) | `google/gemma-4-31B-it-qat-w4a16-ct` | vLLM·SGLang·transformers, BF16 대비 메모리 약 1/3 | [공식, HF 카드], [검증된 외부, vLLM 레시피 "31B: 59GB→19.8GB"] |
| QAT Q4_0 GGUF | `google/gemma-4-31B-it-qat-q4_0-gguf` (17.7 GB) | llama.cpp·Ollama(`ollama run hf.co/google/gemma-4-31B-it-qat-q4_0-gguf:Q4_0`) | [공식, HF 카드] |
| DiffusionGemma | `google/diffusiongemma-26B-A4B-it` | 블록 확산 생성, 실험 단계 (§10.7) | [공식, Google 블로그 2026-06-10] |

드래프터는 5개 사이즈 전부(`-E2B-it-assistant` 78M, `-E4B-it-assistant` 78.8M, `-12B-it-assistant` 0.4B, `-26B-A4B-it-assistant` 0.4B, `-31B-it-assistant` 0.5B) 있고 [공식, HF collection google/gemma-4], 프롬프트 포맷은 target 모델과 같다. 프롬프트 엔지니어링 관점에서는 §10.5의 sampling 주의만 알면 된다.

**Audio/Video 길이 제한** [공식, huggingface.co/google/gemma-4-31B-it]:
> "Audio supports a maximum length of 30 seconds. Video supports a maximum of 60 seconds assuming the images are processed at one frame per second."

**다국어 지원** [공식, 모델 카드]:
> "Out-of-the-box support for 35+ languages, pre-trained on 140+ languages"

Sebastian Raschka [검증된 외부, magazine.sebastianraschka.com, 2026-04-02 업데이트]는 Gemma 4 아키텍처를 다음과 같이 요약:
> "Dense Gemma 4 scales the family to a 256K-context multimodal checkpoint without changing the core local-global recipe much"
> "the sparse Gemma 4 variant keeps the local:global attention backbone while swapping dense FFNs for MoE layers"
> "the smallest Gemma 4 edge model keeps the family's hybrid attention stack and adds native audio on a phone-scale multimodal footprint"

즉 E2B·E4B·26B A4B·31B 네 사이즈가 동일한 local-global hybrid attention backbone을 공유하므로, **변형 간 프롬프트는 거의 그대로 호환된다** (단, 256K context와 audio 입력은 사이즈별로 가용성이 다르다). 2026-06 추가된 12B Unified는 멀티모달 입력 경로만 인코더 없이 바꿨고 chat template·control token·thinking 규칙은 같다 [공식, HF 12B 카드의 Usage 절이 31B와 동일 문안].

---

## 2. Chat Template / 시스템 프롬프트 구조 (Gemma 4 핵심)

Google AI 공식 prompt formatting 문서 [공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4, 2026-05-07]에 따르면 Gemma 4는 **완전히 새로운 turn 토큰 체계**를 쓴다.

### 2.1 Control Token 전체 목록

| 카테고리 | 토큰 | 용도 |
|---------|------|------|
| **Dialogue** | `<\|turn>` / `<turn\|>` | 턴 시작/끝 (Gemma 3의 `<start_of_turn>` / `<end_of_turn>` 대체) |
| Roles | `system`, `user`, `model` | 역할 식별자 (`<\|turn>system\n...`) |
| **Thinking** | `<\|think\|>` | system 프롬프트에서 thinking 활성화 |
| Thinking 출력 | `<\|channel>thought ... <channel\|>` | 모델이 emit하는 내부 추론 블록 |
| **Multimodal** | `<\|image\|>` / `<\|audio\|>` | embedding placeholder |
| Multimodal embed | `<\|image>` / `<image\|>`, `<\|audio>` / `<audio\|>` | 임베딩 시작/끝 indicator |
| **Tool defs** | `<\|tool>` / `<tool\|>` | 도구 정의 블록 |
| **Tool calls** | `<\|tool_call>` / `<tool_call\|>` | 모델이 emit하는 함수 호출 |
| **Tool responses** | `<\|tool_response>` / `<tool_response\|>` | 도구 실행 결과 주입 |
| **String literal** | `<\|"\|>` | 함수 인자 문자열 delimiter (표준 quote 대체) |

### 2.2 Basic Chat Template

```
<|turn>system
[system instructions]<turn|>
<|turn>user
[user message]<turn|>
<|turn>model
[response]<turn|>
```

### 2.3 System Role 사용 (Gemma 4 신규)

Hugging Face 모델 카드 [공식, huggingface.co/google/gemma-4-31B-it, 2026-05-07]:
> "Gemma 4 introduces native support for the `system` role, enabling more structured and controllable conversations."

```python
messages = [
    {"role": "system", "content": "You are a helpful assistant."},
    {"role": "user", "content": "Write a short joke about saving RAM."},
]

text = processor.apply_chat_template(
    messages,
    tokenize=False,
    add_generation_prompt=True,
    enable_thinking=False,
)
```

**Gemma 3와의 가장 큰 차이**: Gemma 3 공식 가이드 [공식, ai.google.dev/gemma/docs/core/prompt-structure]는 명시적으로 다음과 같이 적었다:
> "Gemma's instruction-tuned models are designed to work with only two roles: `user` and `model`. Therefore, the `system` role or a system turn is not supported."

Gemma 4는 이 제약을 폐기했다. **Gemma 3에서 system 지시를 첫 user 메시지에 prepend하던 워크어라운드는 Gemma 4에서 제거하라.** 그대로 두면 system 토큰과 user 토큰에 동일 지시가 중복되어 모델이 우선순위를 혼동한다.

### 2.4 Anti-pattern (피할 것)

```
<!-- ❌ Gemma 3 스타일을 Gemma 4에 그대로 사용 -->
<start_of_turn>user
You are a helpful assistant. Now: knock knock<end_of_turn>
```

```
<!-- ✅ Gemma 4 -->
<|turn>system
You are a helpful assistant.<turn|>
<|turn>user
knock knock<turn|>
```

### 2.5 Chat template 2026-07-15 개정 (HF commit 68abe48)

가중치는 그대로 두고 `chat_template.jinja`와 README만 바뀐 개정이다 [공식, huggingface.co/google/gemma-4-31B-it/commits/main — 2026-05-07 이후 커밋은 평가 결과 추가(05-27), README(06-02·06-03·07-15), 기술 보고서 링크(07-10), template 수정(07-15), `response_template` 추가(07-20)뿐]. 커뮤니티가 "7월 Gemma 4 업데이트"라 부르는 것의 실체가 이것이다. 바뀐 점:

| 항목 | 내용 | 프롬프트·클라이언트 영향 |
|------|------|------------------------|
| `enable_thinking` | `enable_thinking \| default(false)` — 기본 OFF, `true`면 시스템 턴 맨 앞에 `<\|think\|>\n` 주입 | 초판과 같음 |
| `preserve_thinking` (신설) | `preserve_thinking \| default(false)`. `true`면 `tool_calls`가 있는 assistant 메시지의 `reasoning` 또는 `reasoning_content`를 `<\|channel>thought ... <channel\|>`로 다시 렌더링 | §3.2의 "tool call 중 thought 유지" 규칙을 template이 대신 처리. 도구 루프를 돌리는 클라이언트는 `preserve_thinking=True` + 필드 왕복 필요 |
| 인자 검증 (신설) | `tool_calls[].function.arguments`가 문자열이면 예외: "chat_template: tool_calls[].function.arguments must be a JSON object (mapping), not a string." | OpenAI 호환 클라이언트가 `arguments`를 JSON 문자열로 보내면 렌더링 실패. 객체로 파싱해서 넘길 것 |
| null 처리 | 인자 값이 `none`이면 `null`로 직렬화 | 이전엔 조용히 깨지던 케이스 |
| 턴 태그 균형 | assistant 메시지가 연속될 때 `<\|turn>` 중복 방지(앞으로 스캔) | 도구 루프 히스토리에서 태그 중복 사라짐 |

`response_template` (2026-07-20, `tokenizer_config.json`) [공식]: `thinking`은 `<|channel>thought\n` ~ `<channel|>`, `tool_calls`는 `<|tool_call>call:(?P<name>\w+)` ~ `<tool_call|>`, `content`는 `<turn|>`·`<|tool_response>`·`<eos>`로 닫히는 파서 정의. transformers의 구조화 응답 파싱이 이 정의를 쓴다. **직접 파서를 짜는 경우 이 경계 토큰을 그대로 따르면 된다.**

→ 런타임(vLLM·llama.cpp·LM Studio·Ollama)에 내장된 template 사본을 쓰는 경우 2026-07 이후 버전인지 확인. 구 template은 `preserve_thinking`과 인자 검증이 없다.

---

## 3. Thinking Mode (`<|think|>` 토큰)

Gemma 4의 가장 두드러진 신규 기능. Google AI 공식 문서 [공식, huggingface.co/google/gemma-4-31B-it]:

> "To properly manage the thinking process, use the following control tokens:
> **Trigger Thinking:** Thinking is enabled by including the `<|think|>` token at the start of the system prompt."

### 3.1 활성화 / 비활성화

**활성화**: 시스템 프롬프트의 **맨 앞**에 `<|think|>` 토큰을 추가하면 모델이 답변 전에 thought 채널을 emit한다.

활성화 시 출력 구조:
```
<|channel>thought
[Internal reasoning]
<channel|>
[Final answer]
```

**비활성화**: `<|think|>` 토큰을 제거. 단 **E2B/E4B를 제외한 모든 모델**(12B·26B A4B·31B)은 비활성화 상태에서도 빈 thought 블록을 여전히 emit한다 [공식, huggingface.co/google/gemma-4-31B-it, 2026-09-11]:
> "For all models except for the E2B and E4B variants, if thinking is disabled, the model will still generate the tags but with an empty thought block"
```
<|channel>thought
<channel|>
[Final answer]
```

(초판은 "31B의 경우"로 적었으나 현행 모델 카드는 E2B/E4B 제외 전부로 명시한다.)

→ **앱 단에서 thought 블록을 strip하는 후처리가 필수.** vLLM 사용 시 `--reasoning-parser gemma4`를 켜면 자동 처리된다 [검증된 외부, docs.vllm.ai]. llama.cpp 계열은 `--chat-template-kwargs '{"enable_thinking":false}'`로 끈다 [검증된 외부, unsloth.ai/docs/models/gemma-4, 2026-09-11].

**대화 중간에 끄기** [공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "If you want to disable thinking mode mid-conversation, you can remove the `<|think|>` token when you strip the previous thoughts."

→ 히스토리에서 thought를 strip하는 시점에 시스템 턴의 `<|think|>`도 함께 지우면 다음 턴부터 thinking OFF가 된다.

### 3.2 Multi-turn에서의 thought 처리 규칙 (중요)

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "You must remove (strip) the model's generated thoughts from the previous turn before passing the conversation history back to the model for the next turn."

Hugging Face 모델 카드도 동일 규칙 (2026-06 개정으로 예외 문구가 붙음):
> "In multi-turn conversations, the historical model output should only include the final response. Thoughts from previous model turns must _not be added_ before the next user turn begins, with the exception of tool call turns where thinking content should be preserved."

**예외 (Function calling 중)** [공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "If a single model turn involves function or tool calls, thoughts must NOT be removed between the function calls."

즉 **하나의 model 턴 안에서 여러 도구 호출이 일어나는 동안에는 thought를 유지**해야 한다. 턴이 종료된 뒤 다음 user 메시지로 넘어가기 직전에만 strip한다.

**template이 대신 해 주는 범위 (2026-07 개정)**: `apply_chat_template(..., preserve_thinking=True)`를 주고 assistant 메시지에 `reasoning`(또는 `reasoning_content`) 필드를 실어 보내면, `tool_calls`가 있는 메시지에 한해 template이 thought 블록을 다시 렌더링한다 (§2.5). 마지막 user 턴 이전 메시지의 thought는 `preserve_thinking`과 무관하게 렌더링하지 않으므로 "다음 user 턴 전 strip" 규칙은 template 수준에서 보장된다. 기본값이 `false`라 **도구 루프를 돌리는 클라이언트가 명시적으로 켜야** 예외 규칙이 적용된다.

### 3.3 Long-running agent 권장 패턴

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "A highly recommended inference technique is to extract, summarize, and feed the model's previous thoughts back into the context window as standard text."

→ 장기 에이전트에서는 직전 turn의 thought를 통째로 버리지 말고 1-2문단 요약본을 일반 텍스트로 주입. 문서는 이유를 적지 않았고, 같은 추론을 반복하는 루프를 막는다는 해석은 본 가이드의 것이다. (초판은 이 문장을 의역해 원문처럼 인용했다. 정정.)

### 3.4 Function calling과의 조합

[공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4]:
> When `enable_thinking=True`, the model uses internal reasoning to enhance "function-calling accuracy" and parameter precision before executing tool calls.

→ 도구 호출 정확도가 중요하면 thinking을 켜라. 단순 분류·완료에는 끄는 편이 토큰·지연시간 측면에서 유리.

---

## 4. Multimodal 입력

### 4.1 모달리티 매트릭스

| Variant | Text | Image | Audio | Video |
|---------|:----:|:-----:|:-----:|:-----:|
| E2B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| E4B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| 12B Unified | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s, 1fps) |
| 26B A4B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |
| 31B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |

[공식, ai.google.dev/gemma/docs/core/model_card_4 (2026-07-30 갱신), huggingface.co/google/gemma-4-31B-it, huggingface.co/google/gemma-4-12B-it]

### 4.2 Placement 권장 (image는 text 앞, audio는 text 뒤)

현행 모델 카드 [공식, huggingface.co/google/gemma-4-31B-it·gemma-4-12B-it, 2026-09-11]:
> "Place: Image content **before** the text in your prompt. Audio content **after** the text in your prompt."

초판(2026-05-07)의 모델 카드 문안은 "place image and/or audio content before the text"였다. 그 뒤 모델 카드 개정에서 audio 규칙이 **text 뒤**로 바뀌었다(HF README 커밋은 06-02·06-03·07-15에 있어 어느 커밋에서 바뀌었는지는 특정하지 않는다). transformers 공식 문서의 audio 예제도 text → audio 순서다 [검증된 외부, huggingface.co/docs/transformers/model_doc/gemma4]. Unsloth 페이지는 아직 옛 문안("images and/or audio before text")을 유지하므로 [검증된 외부, 2026-09-11], **모델 카드를 우선**한다. 31B·26B A4B는 audio를 받지 않으므로 image 앞 배치만 지키면 된다.

```python
# image: text 앞
messages = [{
    "role": "user",
    "content": [
        {"type": "image", "image": "https://..."},   # ← 먼저
        {"type": "text",  "text": "What's in this image?"}  # ← 나중
    ]
}]

# audio (E2B/E4B/12B): text 뒤
messages = [{
    "role": "user",
    "content": [
        {"type": "text",  "text": "Please transcribe the following audio:"},  # ← 먼저
        {"type": "audio", "url": "https://..."},                                # ← 나중
    ]
}]
```

### 4.3 Visual Token Budget

[공식, huggingface.co/google/gemma-4-31B-it]:
> "Gemma 4 supports variable image resolution through a configurable visual token budget, which controls how many tokens are used to represent an image."

| 예산 | 사용처 (공식 권장) |
|------|-------------------|
| **70** | 분류, 캡셔닝, 비디오 이해 (저비용 우선) |
| **140** | 동일 (조금 더 디테일) |
| **280** | **vLLM 디폴트** [검증된 외부, docs.vllm.ai], 일반 이미지 이해 |
| **560** | 차트·문서 이해 |
| **1120** | OCR, 문서 파싱, 작은 텍스트 읽기 (최고 정확도) |

→ **단순 캡셔닝/분류에 1120을 쓰면 토큰 낭비.** 반대로 OCR을 280으로 하면 작은 글자를 놓친다. 작업 유형별로 명시적으로 선택하라.

모델 카드 원문 [공식]: "Use lower budgets for classification, captioning, or video understanding, where faster inference and processing many frames outweigh fine-grained detail. Use higher budgets for tasks like OCR, document parsing, or reading small text."

**설정 방법** (모델 카드는 파라미터 이름을 적지 않는다. 아래는 런타임 문서 기준):

| 런타임 | 설정 | 출처 |
|--------|------|------|
| transformers | 프로세서 인자 `max_soft_tokens` — `{70, 140, 280, 560, 1120}` 중 하나, 기본 280. 이미지 가로세로는 48의 배수로 리사이즈됨(patch 16 × pooling 3) | [검증된 외부, huggingface.co/docs/transformers/model_doc/gemma4] |
| vLLM | 서버 전역 `--mm-processor-kwargs '{"max_soft_tokens": 560}'`, 요청별은 `hf_overrides`의 `vision_soft_tokens_per_image` | [검증된 외부, vLLM 레시피, 2026-09-11] |

---

## 5. Tokenizer / 어휘 특성

[공식, huggingface.co/google/gemma-4-31B-it, 2026-05-07]:

- **Vocabulary size**: 262K (Gemma 3의 256K에서 확장)
- **Sliding window**: 512 tokens (E2B/E4B), 1024 tokens (12B / 26B A4B / 31B) [공식, 모델 카드]
- **Vision encoder**: ~150M (E2B/E4B), ~550M (26B A4B / 31B). 12B Unified는 encoder 없이 35M matmul [공식, 기술 보고서 §2.3]
- **Audio encoder**: ~300M (E2B/E4B/12B) [공식, 모델 카드]. 12B는 기술 보고서 §2.3 기준 별도 인코더 없이 40ms 청크(640차원)를 직접 투영하므로, 모델 카드의 ~300M 표기가 무엇을 가리키는지는 미확인(§15)
- **EOS / turn 종료 토큰**: `<turn|>`. `response_template`의 `content.close`가 `<turn|>`·`<|tool_response>`·`<eos>` [공식, HF 31B `tokenizer_config.json`, 2026-07-20]
- **transformers 최소 버전**: v5.17.0 [검증된 외부, huggingface.co/docs/transformers/model_doc/gemma4]. 모델 카드 예제는 `AutoModelForMultimodalLM`, transformers 문서는 `Gemma4ForConditionalGeneration`(멀티모달)·`Gemma4ForCausalLM`(텍스트)·`AutoModelForImageTextToText`를 함께 쓴다

특이점: 함수 호출의 문자열 인자에 표준 따옴표 대신 **`<|"|>` 단일 토큰**을 delimiter로 쓴다. 이 설계는 인자 안에 `{`, `}`, `,`, `"` 같은 문자가 들어가도 파서가 깨지지 않게 한다 ([공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4] — 초판은 function calling 페이지로 적었으나 이 문장은 prompt formatting 페이지에 있다):
> "A single token, `<|"|>`, is used as a delimiter for all string values within the structured data blocks. This token ensures that any special characters (such as `{`, `}`, `,`, or quotes) inside a string are treated as literal text and not as part of the data structure's underlying syntax."

---

## 6. Tool Calling / Function Calling (공식 포맷)

Google AI 공식 가이드 [공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4, 2026-05-07] 기준.

### 6.1 Function Call 포맷

```
<|tool_call>call:function_name{parameter:<|"|>value<|"|>}<tool_call|>
```

- 모든 string 값은 `<|"|>`로 감싼다 (예: `key:<|"|>string value<|"|>`)
- 호출은 `<|tool_call> ... <tool_call|>` 안에 위치
- 도구 결과는 `<|tool_response> ... <tool_response|>` 안에 주입

### 6.2 4단계 워크플로우

[공식, 동일 페이지]:
1. **Define Tools** — 함수 시그니처/설명/타입을 명시 (JSON Schema 또는 Python 함수 시그니처 자동 추출)
2. **Model's Turn** — 모델이 user 프롬프트와 도구 목록을 받아 구조화된 함수 호출을 emit
3. **Developer's Turn** — "Always validate function names and arguments before execution"
4. **Final Response** — 도구 실행 결과를 모델에 주입하면 자연어 최종 답변 생성

### 6.3 도구 정의 방법

두 가지 모두 공식 지원 [공식, 동일 페이지]:
- **JSON Schema** (수동 dict 작성) — 복잡한 nested 객체 권장
- **Python 함수** (docstring + type hints에서 자동 추출) — Google Style docstring 권장

> 공식 캐비엇: "If a function uses a custom object (like a Config class) as an argument, the automatic converter may describe it simply as a generic 'object' without detailing its internal properties. In these cases, manually defining the JSON schema is preferred to ensure nested properties (such as theme or font_size within a config object) are explicitly defined for the model."

### 6.4 Tool Response 포맷

```python
"tool_responses": [
    {"name": function_name, "response": function_response}
]
```

**병렬(독립) 호출** [공식, 동일 페이지, 2026-06-04 갱신]: "In case of multiple independent requests" 절이 추가되어 한 턴에서 나온 여러 호출의 결과를 하나의 `tool_responses` 배열로 되돌린다.

```python
"tool_responses": [
    {"name": function_name_1, "response": function_response_1},
    {"name": function_name_2, "response": function_response_2},
]
```

→ 초판 §15에서 미확인이던 병렬 호출은 **공식 포맷이 확인됨**. 기술 보고서 Table 11은 단일 호출 예시만 실었으므로, 몇 개까지 안정적으로 동시 emit하는지는 실측 대상.

**stop sequence** [공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]: "`<|tool_response>` acts as an additional stop sequence for the inference engine." — 직접 서빙 루프를 짜면 `<turn|>` 외에 이 토큰에서도 생성을 멈추고 도구를 실행해야 한다.

**인자 타입 (2026-07 template)**: 히스토리에 넣는 `tool_calls[].function.arguments`는 **JSON 객체**여야 한다. 문자열이면 template이 예외를 낸다 (§2.5). OpenAI SDK 응답을 그대로 되돌리면 `arguments`가 문자열이므로 `json.loads` 후 넣을 것.

### 6.5 vLLM에서 활성화

[검증된 외부, docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html]:
```bash
vllm serve google/gemma-4-31B-it \
  --tensor-parallel-size 2 \
  --max-model-len 16384 \
  --enable-auto-tool-choice \
  --reasoning-parser gemma4 \
  --tool-call-parser gemma4 \
  --chat-template examples/tool_chat_template_gemma4.jinja
```

---

## 7. Long Context 처리

| Variant | Max context | Sliding window |
|---------|-------------|----------------|
| E2B / E4B | 128K | 512 |
| 12B / 26B A4B / 31B | **256K** (262,144) | 1024 |

[공식, ai.google.dev/gemma/docs/core, huggingface.co/google/gemma-4-31B-it]

→ **무조건 256K로 띄우지 말 것.** 메모리·KV cache가 선형 이상으로 증가한다. 실제 입력 길이에 가까운 `--max-model-len`으로 시작. (초판에 실었던 Unsloth의 "32K로 시작" 문구는 2026-09-11 현재 Unsloth 페이지에 없어 인용을 내렸다. 권고 자체는 vLLM 레시피의 워크로드별 조정 지침과 같다.)

vLLM 레시피 [검증된 외부, docs.vllm.ai, 2026-09-11]:
- 예시 명령의 `--max-model-len`은 "up to 131072"로 적혀 있다. 모델 한계(262,144)보다 낮은 값이며 레시피 예시 범위일 뿐 하드 리밋 근거는 없다. 그 이상은 직접 실측
- Thinking 모드: "Thinking mode produces additional tokens for the reasoning chain. Increase `--max-model-len` and `max_tokens` accordingly to accommodate longer outputs."
- GPU memory utilization: 0.90 (예시 명령), `--kv-cache-dtype fp8`로 KV 메모리 약 절반
- 31B BF16: 80GB GPU 1장 또는 TP=2. W4A16 QAT는 약 19.8GB (§10.6)

---

## 8. Instruction Tuning 관행

### 8.1 Instruct vs Base

[공식, deepmind.google/models/gemma/gemma-4/]: 모든 사이즈가 base + instruction-tuned 두 버전으로 제공. **프롬프트 가이드의 거의 모든 권장은 IT(Instruction-Tuned) 모델 기준.**

### 8.2 권장 샘플링 (모든 사용 사례 공통)

[공식, huggingface.co/google/gemma-4-31B-it]:
> "Use the following standardized sampling configuration across all use cases:
> - `temperature=1.0`
> - `top_p=0.95`
> - `top_k=64`"

> ⚠️ 이 설정은 OpenAI/Anthropic의 일반적인 `temperature=0.7` 관행과 다르다. Gemma 4는 학습 시 temperature 1.0 분포에 맞춰 RLHF되었으므로, **임의로 낮추면 분포가 좁아져 오히려 품질이 떨어질 수 있다.** 결정론이 필요한 경우만 0으로 낮추라.

vLLM 레시피 [검증된 외부, docs.vllm.ai, 2026-09-11]에는 권장 문장이 따로 없고, 예제 코드가 결정론 출력에 `temperature=0.0`, 창작 예제에 `0.7`을 쓴다. (초판은 이를 인용문처럼 적었으나 레시피에 그런 문장은 없다. 정정.)

→ 예제 값과 공식 권장이 다르다. **공식 모델 카드(1.0)를 우선**으로 두고, 결정론 필요 시에만 0으로 내릴 것을 권장.

### 8.3 Few-shot 권장

공식 문서에 명시적 few-shot 개수 권장은 없음 (확인되지 않은 영역, §15 참조).

---

## 9. 안전·정렬 (Google 공식)

[공식, ai.google.dev/gemma/docs/core/model_card_4]:

- 학습 시 적용된 필터: "Rigorous CSAM filtering", "Sensitive Data Filtering"
- Google AI Principles 기준 평가 완료
- **금지 사용처**: child abuse material, dangerous instructions, sexually explicit content, hate speech, harassment

The Agent Times의 보고 [커뮤니티, theagenttimes.com, 재현 가능 여부 검증 필요]에 따르면 출시 직후 r/LocalLLaMA에서 jailbreak 시도가 활발했으나, **본 가이드는 공식 안전 가이드라인 준수 전제로만 작성**한다.

---

## 10. 로컬 / 프로덕션 배포

### 10.1 지원 런타임 매트릭스

[검증된 외부, huggingface.co/blog/gemma4]:

| 런타임 | 지원 | 비고 |
|--------|:----:|------|
| `transformers` | ✅ | v5.17.0+, `AutoModelForMultimodalLM` (모델 카드 예제). MTP는 `assistant_model=` |
| `vllm` | ✅ | `--reasoning-parser gemma4 --tool-call-parser gemma4`, MTP는 `--speculative-config` |
| `SGLang` | ✅ | QAT W4A16 카드에 `sglang.launch_server` 예시 [공식] |
| `llama.cpp` | ✅ | GGUF 양자화, thinking OFF는 `--chat-template-kwargs '{"enable_thinking":false}'` |
| `ollama` | ✅ | `ollama run gemma4:31b` 등. v0.23.1+ MTP(`DRAFT`) |
| `MLX` | ✅ | Apple Silicon, "TurboQuant" 지원, Ollama `*-mlx` 태그 |
| `transformers.js` | ✅ | WebGPU 인-브라우저 |
| `Mistral.rs` | ✅ | Rust 네이티브 |
| `ONNX` | ✅ | 엣지 디바이스 |
| `LM Studio` | ✅ | 0.4.11부터 갱신된 chat template 지원 (§14.1) |

### 10.2 Ollama 기본

[검증된 외부, ollama.com/library/gemma4/tags, 2026-09-11]:
- 사이즈 태그: `e2b`, `e4b`, `12b`, `26b`, `31b`, 그리고 `latest`. 클라우드: `cloud`(256K), `31b-cloud`. (`latest`의 용량은 `e4b`와 같은 9.6GB지만 태그 페이지가 대응 관계를 명시하지 않으므로 단정하지 않는다)
- 양자화 태그: `<size>-it-q4_K_M`(기본), `-it-q8_0`, `-it-bf16`, `-it-qat`(공식 QAT, 31B 19GB), `-mlx`, `-mlx-bf16`, `-mxfp8`, `-nvfp4`
- MTP 번들 태그: `26b-a4b-it-mtp-q4_K_M`. `31b-coding-mtp-bf16`(64GB)도 있으나 이름의 "coding" 의미는 태그 페이지에 설명이 없어 미확인(§15)
- 기본 파라미터: `temperature=1.0, top_p=0.95, top_k=64` (공식 권장과 동일)
- Thinking 활성화: 시스템 프롬프트에 `<|think|>` 추가. 히스토리에서 thought 제외 안내도 동일
- MTP: v0.23.1(2026-05)부터 Modelfile `DRAFT` 명령으로 드래프터 지정, `--quantize-draft` 플래그 [검증된 외부, github.com/ollama/ollama PR #15980·release v0.23.1: "Gemma 4 MTP speculative decoding is now supported on Macs. This can give over a 2x speed increase for the Gemma 4 31B model on coding tasks."]. 처음엔 MLX 러너(Mac)만이었고 다른 러너는 이후 버전에서 확장 — 사용 버전에서 실측

### 10.3 Unsloth 현행 노트

[검증된 외부, unsloth.ai/docs/models/gemma-4, 2026-09-11]:
- 권장 sampling: 공식과 동일 `temperature=1.0, top_p=0.95, top_k=64`
- Thinking OFF: `--chat-template-kwargs '{"enable_thinking":false}'` (PowerShell은 `"{\"enable_thinking\":false}"`)
- GGUF 메모리 표: 31B 4-bit 17–20 GB / 8-bit 34–38 GB / BF16 62 GB, 12B 4-bit 7–8 GB / BF16 25 GB, 26B A4B 4-bit 16–18 GB
- Ollama에서 "Error: 500 Internal Server Error"가 나면 설치 스크립트로 Ollama 갱신

초판에 실었던 "CUDA 13.2 런타임 회피"와 "32K로 시작" 문구는 현재 페이지(본문·train 하위 페이지 모두)에 없다. 출처가 사라진 인용이라 본 개정에서 삭제했다. 멀티모달 배치 절은 아직 옛 문안(image/audio 모두 text 앞)이므로 §4.2대로 모델 카드를 우선한다.

### 10.4 Fine-tuning

[검증된 외부, huggingface.co/blog/gemma4]:
- TRL (Hugging Face) — multimodal tool response 포함 SFT 예제 제공. 2026-07-20 `tokenizer_config.json`에 추가된 `response_template`이 assistant 구간 파싱 기준 [공식]
- Unsloth Studio — UI 기반. Unsloth train 페이지: MoE(26B A4B)는 "start with shorter contexts and smaller ranks first", 멀티모달은 `finetune_vision_layers = False`부터
- Vertex AI (Google Cloud) — 공식 예제로 vision/audio tower freeze한 채 function calling 확장

> HF 블로그 노트 [검증된 외부]: "In tests with pre-release checkpoints, the models were so impressive out of the box that it was difficult to find good fine-tuning examples because they are so good out of the box."
> → **Gemma 4는 fine-tune 전에 먼저 prompt engineering으로 충분한지 검증할 가치가 있다.**

### 10.5 MTP 드래프터 (speculative decoding)

[공식, blog.google 2026-05-05, ai.google.dev/gemma/docs/mtp/mtp (2026-06-04 갱신), huggingface.co/google/gemma-4-31B-it-assistant]:
- 공개 시점: releases 페이지는 "April 16, 2026 — Release of Gemma 4 - MTP for E2B, E4B, 31B, and 26B A4B"로, 블로그는 2026-05-05로 적는다. 공식 자료끼리 날짜가 어긋나므로 둘을 함께 적어 둔다. 12B용 드래프터는 12B 본체(2026-06-03)보다 뒤에 올라왔다
- Google 주장: "deliver up to a 3x speedup" / "Zero quality degradation: Because the primary Gemma 4 model retains the final verification, you get identical frontier-class reasoning and accuracy, just delivered significantly faster."
- 구조: "The draft models seamlessly utilize the target model's activations and share its KV cache" — 31B용 드래프터는 0.5B, 반드시 같은 target(`google/gemma-4-31B-it`)과 짝
- Apple Silicon 26B MoE는 단일 요청보다 배치 4–8에서 최적(약 2.2배) [공식 블로그]
- 지원 런타임: transformers, MLX, vLLM(PR #41745), SGLang, Ollama(v0.23.1+)

```python
# transformers [공식, ai.google.dev/gemma/docs/mtp/mtp]
from transformers import AutoModelForCausalLM

assistant_model = AutoModelForCausalLM.from_pretrained(
    "google/gemma-4-31B-it-assistant", dtype="auto", device_map="auto",
)
outputs = target_model.generate(
    **inputs,
    assistant_model=assistant_model,
    max_new_tokens=256,
    # num_assistant_tokens=..., num_assistant_tokens_schedule="heuristic" | "constant"
)
```

```bash
# vLLM [검증된 외부, 레시피]
vllm serve google/gemma-4-31B-it \
  --speculative-config '{"model": "google/gemma-4-31B-it-assistant", "num_speculative_tokens": 4}'
```

프롬프트 관점 주의: 공식 MTP 문서 예제는 `do_sample=False`이고, 드래프터 카드는 target과 같은 `temperature=1.0, top_p=0.95, top_k=64`를 권한다. 샘플링 ON에서의 수락률·속도는 공식 수치가 없으므로 실측 대상(§15).

### 10.6 공식 QAT 체크포인트

[공식, HF 카드 2종]:
- `google/gemma-4-31B-it-qat-w4a16-ct`: "QAT checkpoint serialized in the compressed-tensors format for native, optimized inference" — vLLM `vllm serve google/gemma-4-31B-it-qat-w4a16-ct --max-model-len 32768 --gpu-memory-utilization 0.90`, SGLang `python3 -m sglang.launch_server --model-path ...`. vLLM 레시피 기준 31B 59GB → 19.8GB
- `google/gemma-4-31B-it-qat-q4_0-gguf`: 17.7 GB, llama.cpp·Ollama(`ollama run hf.co/google/gemma-4-31B-it-qat-q4_0-gguf:Q4_0`). Ollama 라이브러리 태그 `31b-it-qat`와 같은 계열
- 품질 주장: "preserving similar quality" to bfloat16. 프롬프트·template은 BF16과 동일
- **26B A4B는 W4A16 없음** [검증된 외부, vLLM 레시피]: "The 26B-A4B MoE model is not included — its small expert dimensions (704) cause excessive quality loss with 4-bit quantization." 26B A4B의 공식 QAT는 Q4_0 GGUF(`google/gemma-4-26B-A4B-it-qat-q4_0-gguf`)와 Ollama `26b-a4b-it-qat`뿐이다

### 10.7 DiffusionGemma (실험)

[공식, blog.google 2026-06-10]: 26B A4B 기반 블록 확산 모델(`google/diffusiongemma-26B-A4B-it`). 256토큰을 병렬 생성해 "up to 4x faster text generation on GPUs", H100 1장 1000+ tok/s. 블로그가 명시한 한계: 표준 Gemma 4보다 출력 품질이 낮고, 로컬·저동시성에 최적이며 고QPS 서빙엔 이점이 줄고, 통합 메모리(Apple Silicon)에서는 가속이 덜하며, **실험 단계라 프로덕션은 표준 Gemma 4 권장**. chat template·thinking 토큰이 같은지는 블로그·카드에 명시가 없다(§15). vLLM은 전용 컨테이너 `vllm/vllm-openai:gemma`로 서빙 [검증된 외부, 레시피].

---

## 11. Gemma 3 → 4 마이그레이션 체크리스트

1. [ ] 모델 ID를 `google/gemma-3-*` → `google/gemma-4-{E2B|E4B|12B|26B-A4B|31B}-it`로 교체
2. [ ] **Chat template 토큰 전수 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>`
3. [ ] **System 지시를 첫 user 메시지에서 분리**하여 별도 `system` role로 이동 (Gemma 3 워크어라운드 제거)
4. [ ] Thinking이 필요한 워크로드: 시스템 프롬프트 맨 앞에 `<|think|>` 추가
5. [ ] Thinking 비활성화 시: 빈 `<|channel>thought ... <channel|>` 블록 strip 후처리 추가 (E2B/E4B 제외 전부 해당)
6. [ ] **Multi-turn 히스토리에서 직전 model 턴의 thought 블록 제거** (단, function calling 중에는 유지 — template을 쓰면 `preserve_thinking=True` + `reasoning` 필드 왕복)
7. [ ] 장기 에이전트: thought 요약본을 일반 텍스트로 주입하여 reasoning loop 방지
8. [ ] Multimodal 입력 순서: image → text, text → audio
9. [ ] Vision token budget을 작업 유형별로 명시 (분류 70-140, OCR 1120; transformers `max_soft_tokens`, vLLM `--mm-processor-kwargs`)
10. [ ] Function calling 사용 시: `<|"|>` delimiter 포맷으로 마이그레이션, `tool_responses` 구조 채택, 히스토리의 `arguments`는 JSON 객체
11. [ ] vLLM 사용 시 `--reasoning-parser gemma4 --tool-call-parser gemma4` 추가
12. [ ] 샘플링 디폴트를 `temperature=1.0, top_p=0.95, top_k=64`로 정렬 (공식 권장)
13. [ ] Context length를 실제 사용량에 맞춰 시작하고 필요 시 증가 (무조건 256K 금지, thinking ON이면 `max_tokens` 여유)
14. [ ] Audio 입력이 필요한 워크로드는 E2B/E4B/12B 사용 (26B A4B·31B는 audio 미지원)
15. [ ] 라이선스 확인: Gemma 3의 Gemma Terms 제약 → Apache 2.0으로 자유로워짐
16. [ ] 런타임에 내장된 chat template이 2026-07-15 개정본인지 확인 (`preserve_thinking`·인자 검증 유무)
17. [ ] 지연이 문제면 MTP 드래프터(`-assistant`) 또는 QAT 체크포인트를 같은 프롬프트로 A/B

---

## 12. 한 페이지 치트시트

### 12.1 시스템 프롬프트 골격 (Gemma 4 기본)

```
<|turn>system
You are <one sentence role>.

<goal: one sentence>
<key constraint 1>
<key constraint 2>
<turn|>
<|turn>user
[user message]<turn|>
<|turn>model
```

### 12.2 시스템 프롬프트 골격 (Thinking 활성화)

```
<|turn>system
<|think|>
You are <one sentence role>.

<goal>
<constraints>
<turn|>
<|turn>user
[user message]<turn|>
<|turn>model
```

### 12.3 Multimodal 입력

```python
messages = [
    {"role": "system", "content": "You are an OCR specialist."},
    {"role": "user", "content": [
        {"type": "image", "image": "https://path/to/document.png"},
        {"type": "text",  "text": "Extract every visible text line."},
    ]},
]
```

### 12.4 Transformers 호출 디폴트

```python
# transformers >= 5.17.0
from transformers import AutoProcessor, AutoModelForMultimodalLM

MODEL_ID = "google/gemma-4-31B-it"
processor = AutoProcessor.from_pretrained(MODEL_ID)
model = AutoModelForMultimodalLM.from_pretrained(
    MODEL_ID, dtype="auto", device_map="auto"
)

inputs = processor.apply_chat_template(
    messages,
    tokenize=True,
    return_dict=True,
    return_tensors="pt",
    add_generation_prompt=True,
    enable_thinking=True,   # 또는 False
    # preserve_thinking=True,  # 도구 루프에서 reasoning 필드를 되돌릴 때
).to(model.device)

output = model.generate(
    **inputs,
    max_new_tokens=4000,
    temperature=1.0,        # 공식 권장
    top_p=0.95,
    top_k=64,
)
```

### 12.5 vLLM serve 디폴트

```bash
vllm serve google/gemma-4-31B-it \
  --tensor-parallel-size 2 \
  --max-model-len 32768 \
  --gpu-memory-utilization 0.90 \
  --enable-auto-tool-choice \
  --reasoning-parser gemma4 \
  --tool-call-parser gemma4 \
  --chat-template examples/tool_chat_template_gemma4.jinja \
  --limit-mm-per-prompt '{"image": 4}' \
  --async-scheduling
# 31B·26B A4B는 audio를 받지 않으므로 audio 슬롯을 0으로 둔다. 레시피: "For image-only workloads (no audio),
# pass --limit-mm-per-prompt.audio 0 to skip audio encoder memory allocation". 레시피의 전체 기능 예시는
# '{"image": 4, "audio": 1}'인데 이는 audio 지원 사이즈용이다.
# 가속 옵션: --speculative-config '{"model": "google/gemma-4-31B-it-assistant", "num_speculative_tokens": 4}'
# 메모리 옵션: --kv-cache-dtype fp8 / 모델을 google/gemma-4-31B-it-qat-w4a16-ct로 교체
```

---

## 13. Key Takeaways

1. **System role을 써라** — Gemma 3의 user-prepend 워크어라운드는 마이그레이션 시 1순위 제거 대상
2. **Chat template 토큰 전수 교체** — `<|turn>` / `<turn|>`. `<start_of_turn>`은 더 이상 유효하지 않음
3. **Thinking은 시스템 프롬프트 맨 앞 `<|think|>` 한 줄**로 토글
4. **Multi-turn에서 직전 thought 블록은 반드시 strip** (function calling 중 예외 — 2026-07 template은 `preserve_thinking=True`로 처리)
5. **Multimodal 입력은 image → text → audio 순서** (audio는 2026-06부터 text 뒤)
6. **Visual token budget을 작업별로 명시** (분류 70, OCR 1120)
7. **Function calling은 `<|"|>` delimiter + 6개 special token 포맷**, 병렬 호출은 `tool_responses` 배열, 히스토리 `arguments`는 JSON 객체
8. **샘플링 공식 디폴트는 temp=1.0, top_p=0.95, top_k=64** (`0.7` 관행 그대로 가져오지 말 것)
9. **Context는 실사용 길이로 시작**, 256K 무조건 띄우지 말 것. thinking ON이면 `max_tokens` 여유
10. **Apache 2.0** — Gemma 3까지의 라이선스 제약은 사라졌다. 드래프터·QAT·DiffusionGemma도 동일
11. **빈 thought 블록 strip은 E2B/E4B 제외 전부** 필요. 12B Unified도 해당
12. **속도가 문제면 MTP 드래프터**(출력 동일 주장) → 그다음 QAT. DiffusionGemma는 실험용

**가장 높은 레버리지 변경**: system role 분리 + chat template 토큰 전수 교체 + thinking 토글 정책 명시 + (2026-07 이후) 런타임 template 버전 확인.

---

## 14. 고수들의 노하우 (외부 검증)

### 14.1 Simon Willison — pelican SVG 벤치마크 + 31B LM Studio 이슈

**누가**: Simon Willison (simonwillison.net 운영자, Datasette 창립자)
**언제**: 2026-04-02 (Gemma 4 출시 당일)
**어디서**: [simonwillison.net/2026/Apr/2/gemma-4/](https://simonwillison.net/2026/Apr/2/gemma-4/)
**무엇을**:

- Google의 자평 인용: > "unprecedented level of intelligence-per-parameter" — small useful model 경쟁의 최전선임을 강조
- E2B/E4B의 "E"가 "Effective" 파라미터의 약어임을 첫 보도
- **출시일 발견**: LM Studio에서 31B 모델을 돌렸을 때 "the 31B (19.89GB) model was broken and spat out `\"---\\n\"` in a loop for every prompt I tried" — 작은 변형(2B, 4B, 26B-A4B)은 정상 작동. 글에는 HF discussion 링크가 없다. (초판에서 "HF discussion #53도 동일 증상"이라 적었으나 #53은 OpenWebUI·OpenCode에서 template이 복잡해 이중 CoT·tool call이 깨진 별개 이슈이고, 2026-04-09 vLLM PR #39027로 해결됐다는 코멘트로 끝난다. 정정.)
- **후속**: Google이 2026-04 chat template을 수정 배포했고(Unsloth GGUF discussion #16 "Apr 11: Updated with Google chat template fixes"), LM Studio 0.4.11 changelog에 "Support for updated Gemma 4 chat template"이 올라갔다 [검증된 외부, lmstudio.ai/changelog/lmstudio-v0.4.11]. Simon Willison 글 자체에는 사후 추가 문구가 없다
- 그의 "pelican riding bicycle" SVG 시각 품질 벤치마크: 26B-A4B가 작은 변형 대비 명확히 우수
- llm-gemini 도구로 AI Studio API 통합
- 이후 Gemma 관련 글은 DiffusionGemma 링크(2026-06-10)뿐, 12B·MTP 별도 분석 없음 [검증된 외부, simonwillison.net/tags/gemma/, 2026-09-11]

**시사점**: **출시 직후 third-party 런타임은 chat template 파싱이 깨질 수 있고, template은 그 뒤로도 두 번(2026-04, 2026-07) 바뀌었다.** 런타임 내장 template 버전을 확인하고, 의심되면 transformers 직접 호출로 교차 검증.

### 14.2 Sebastian Raschka — local-global hybrid attention 분석

**누가**: Sebastian Raschka (Lightning AI, "Build a Large Language Model from Scratch" 저자)
**언제**: 2026-04-02 ("The Big LLM Architecture Comparison" Section 23 추가)
**어디서**: [magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
**무엇을**:

- > "Dense Gemma 4 scales the family to a 256K-context multimodal checkpoint without changing the core local-global recipe much"
- > "the sparse Gemma 4 variant keeps the local:global attention backbone while swapping dense FFNs for MoE layers"
- > "the smallest Gemma 4 edge model keeps the family's hybrid attention stack and adds native audio on a phone-scale multimodal footprint"

**시사점**: Raschka가 다룬 출시 당시 4개 변형이 동일한 attention backbone을 공유하므로 **프롬프트 엔지니어링 노하우는 변형 간 거의 그대로 이전 가능**. 변형 선택은 주로 (a) 메모리 (b) audio 필요 여부 (c) latency vs 품질 트레이드오프로 결정.

### 14.3 Hugging Face Blog — PLE / Shared KV / TurboQuant

**누가**: Hugging Face 공식 블로그팀
**언제**: 2026-04-02
**어디서**: [huggingface.co/blog/gemma4](https://huggingface.co/blog/gemma4)
**무엇을 (재현 가능한 기술 디테일)**:

- **Per-Layer Embeddings (PLE)**: 각 레이어마다 저차원 conditioning pathway. E2B/E4B의 "Effective" 파라미터 수가 임베딩 포함 총 파라미터 수보다 작은 이유
- **Shared KV Cache**: "Last N layers reuse key-value states from earlier layers" — 추론 시 메모리 절감
- **MLX TurboQuant**: Apple Silicon에서 새 양자화 포맷 지원
- **Pareto frontier arena scores**: > "high quality with pareto frontier arena scores" — 원문은 "an estimated LMArena score (text only) of 1452" (31B), 26B MoE는 1441. 추정치이고 텍스트 전용 기준이다
- **Fine-tuning 노트**: > "the models were so impressive out of the box that it was difficult to find good fine-tuning examples" — fine-tune 전에 prompt engineering으로 충분한지 먼저 평가하라는 시사점

### 14.4 Unsloth — 로컬 실행 가이드 (2026-09 현행)

**누가**: Unsloth 팀 (오픈소스 fine-tuning 프레임워크)
**언제**: 2026-04-02 출시 시점 공개, 이후 12B·QAT·MLX·NVFP4 절이 추가되며 개정
**어디서**: [unsloth.ai/docs/models/gemma-4](https://unsloth.ai/docs/models/gemma-4)
**무엇을 (재현 가능한 운영 노하우)**:

- 공식 샘플링(temp=1.0, top_p=0.95, top_k=64) 재확인
- 사이즈·양자화별 GGUF 메모리 표 (31B 4-bit 17–20 GB, 12B 4-bit 7–8 GB)
- Thinking OFF 플래그 `--chat-template-kwargs '{"enable_thinking":false}'`
- Ollama 500 에러 시 Ollama 갱신

초판에서 인용한 두 문구가 현재 페이지에 없어 삭제한 경위와 멀티모달 배치 절의 충돌은 §10.3에 적었다.

### 14.5 vLLM 팀 — gemma4 reasoning/tool parser + MTP

**누가**: vLLM 프로젝트 메인테이너
**언제**: 2026-04 (Gemma 4 출시 직후), MTP는 PR #41745, 레시피는 이후 12B·QAT·DiffusionGemma 절 추가
**어디서**: [docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html), [docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/](https://docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/)
**무엇을**:

- 전용 `--reasoning-parser gemma4` 추가 — thinking 채널 자동 분리
- 전용 `--tool-call-parser gemma4` — `<|"|>` delimiter 포맷 자동 파싱
- 2026-04-09 PR #39027로 template 파싱 이슈(HF discussion #53) 수정
- MTP: `--speculative-config '{"model": "google/gemma-4-31B-it-assistant", "num_speculative_tokens": 4}'`
- 예시 명령에 `--limit-mm-per-prompt`·`--async-scheduling` 추가, `--kv-cache-dtype fp8` 옵션. 이미지 전용 워크로드는 `--limit-mm-per-prompt.audio 0`으로 audio encoder 메모리 할당을 건너뛰라고 명시
- TPU (Trillium / Ironwood), AMD GPU, NVIDIA GPU 모두 지원 레시피 제공
- 비디오는 "custom vLLM processing pipeline that extracts frames"로 처리

**시사점**: vLLM을 Gemma 3 설정 그대로 띄우면 thinking/tool 출력이 raw text로 누수된다. **Gemma 4 전용 parser 두 플래그를 반드시 켜라.** 레시피 sampling 예시(0.0/0.7)는 공식 1.0과 다르므로 §8.2대로 공식 우선.

### 14.6 Ollama / Gemma Cookbook — 표준 진입점

- **Ollama** [ollama.com/library/gemma4](https://ollama.com/library/gemma4): `ollama run gemma4:31b` 한 줄로 로컬 실행, thinking은 시스템 프롬프트에 `<|think|>` 추가로 활성화. v0.23.1(2026-05)부터 MTP 드래프터를 Modelfile `DRAFT`로 붙일 수 있다 (§10.2)
- **Google Gemma Cookbook** [github.com/google-gemma/cookbook](https://github.com/google-gemma/cookbook): 공식 예제 모음. `tutorials` / `apps` / `experiments` / `responsible` / `docs` 구조. 구 리포 `google-gemini/gemma-cookbook`은 2026-05 아카이브되고 새 리포로 안내. `tutorials/Image_Segmentation.ipynb`("Image Segmentation Task with Gemma 4")가 Gemma 4 노트북이고, 추론 기능 문서는 `docs/capabilities/`에 있다 [검증된 외부, 2026-09-11]

### 14.7 커뮤니티 "7월 업데이트" 소문 정리

[커뮤니티, techcityauthority.com 2026-07-16·explainx.ai — 단정 인용 회피]: 7월 중순 "Flash Attention 4로 prefill 25–70% 향상", "가중치 갱신" 등의 기사가 돌았다. HF 커밋 이력으로 확인되는 사실은 2026-07-15 `chat_template.jinja`·README 수정과 07-20 `tokenizer_config.json` 수정뿐이고 safetensors 커밋은 없다 (§2.5). 기사 자체도 커뮤니티 검증("only the README and chat_template.jinja files actually changed")을 인용한다. **프롬프트 관점에서 챙길 것은 template 개정 하나다.** FA4 성능 수치는 Google 1차 출처를 찾지 못해 본 가이드에 싣지 않는다.

---

## 15. 확인되지 않은 영역 (솔직한 빈칸)

2026-09-11 갱신 시점에 공식 1차 자료에서 확인 불가한 항목. 초판(2026-05-07) 항목 중 해소된 것은 아래 "해소됨"에 옮겼다.

1. **Few-shot 권장 개수**: Google 공식 모델 카드/문서/기술 보고서에 specific few-shot 권장(예: "3-5 examples") 명시 없음. 일반 통설(0-5)을 추측 인용하지 않음.
2. **시스템 프롬프트 권장 길이 상한**: 공식 권장 토큰 길이 가이드라인 없음.
3. **Sebastian Raschka 본문 직접 인용**: 검색 결과 발췌문은 확보했으나 본인이 작성한 Section 23 본문 전체는 fetch에서 잘려 직접 인용 불가. WebSearch 요약 기반 인용임을 명시.
4. **12B audio 경로의 파라미터 표기**: 모델 카드는 12B에도 audio encoder ~300M을 적고, 기술 보고서 §2.3은 별도 인코더 없이 40ms 청크를 직접 투영한다고 서술한다. 두 표기가 같은 구성 요소인지 미확인.
5. **Audio/Video 입력 시 visual token budget 효과**: 비디오는 1fps로 frame 추출되어 image budget이 적용되는지, 별도 video budget이 있는지 명시적 공식 인용 미확보.
6. **병렬 tool call의 동시 emit 상한**: 결과 되돌리기 포맷(§6.4)은 공식이나, 한 턴에서 몇 개까지 안정적으로 호출하는지·기술 보고서 Table 11이 단일 호출만 실은 이유는 미확인.
7. **MTP 드래프터와 샘플링 ON의 조합**: 공식 예제는 `do_sample=False`, 드래프터 카드는 target과 같은 sampling 권장. 샘플링 ON에서의 수락률·속도 공식 수치 없음.
8. **DiffusionGemma의 chat template·thinking 토큰 호환 여부**: 블로그·카드에 명시 없음. vLLM 전용 컨테이너로만 서빙 예시.
9. **2026-07-15 template 개정이 출력에 미치는 영향**: 가중치 무변경이므로 동일 히스토리·동일 렌더링이면 출력은 같아야 하나, `preserve_thinking`·인자 검증으로 렌더링 자체가 달라지는 케이스의 품질 비교는 공식 자료 없음.
10. **Ollama `31b-coding-mtp-bf16` 태그의 정체**: 태그 페이지가 일반 31B 설명만 보여 주어 "coding" 접미의 의미(코딩 특화 미세조정인지, 코딩 벤치용 MTP 번들인지) 미확인. 공식 HF 컬렉션에는 대응 모델 ID가 없다.
11. **7월 Flash Attention 4 성능 수치**: 커뮤니티 기사만 있고 Google 1차 출처 미확보 (§14.7).

**해소됨 (초판 §15 → 본문 반영)**:
- Gemma Cookbook Gemma 4 노트북 → 새 리포 `google-gemma/cookbook`에 존재 (§14.6)
- 31B LM Studio 루프 → Google template 수정(2026-04) + LM Studio 0.4.11 (§14.1)
- 병렬 tool call 공식 포맷 → 함수 호출 문서 "multiple independent requests" (§6.4)
- 기술 보고서 미공개 → 2026-07-02 arXiv 2607.02770 공개
- MoE expert 구성 → 현행 모델 카드가 "8 active / 128 total and 1 shared"로 공개 (§1 표). 기술 보고서 본문에는 없고 모델 카드에만 있다

위 항목은 향후 공식 문서 업데이트 시 보강 예정.

---

## Sources

### 공식 1차 (Google / DeepMind / 공식 모델 카드)
- [Gemma 4 model overview | Google AI for Developers](https://ai.google.dev/gemma/docs/core)
- [Gemma 4 model card | Google AI for Developers](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Gemma 4 Prompt Formatting | Google AI for Developers](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling with Gemma 4 | Google AI for Developers](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [Gemma 4 Multi-Token Prediction (MTP) using Hugging Face Transformers | Google AI for Developers](https://ai.google.dev/gemma/docs/mtp/mtp)
- [google/gemma-4-31B-it · Hugging Face](https://huggingface.co/google/gemma-4-31B-it) / [commits](https://huggingface.co/google/gemma-4-31B-it/commits/main) / [chat template 2026-07-15 commit 68abe48](https://huggingface.co/google/gemma-4-31B-it/commit/68abe48)
- [google/gemma-4-12B-it · Hugging Face](https://huggingface.co/google/gemma-4-12B-it)
- [google/gemma-4-26B-A4B-it · Hugging Face](https://huggingface.co/google/gemma-4-26B-A4B-it)
- [google/gemma-4-E4B-it · Hugging Face](https://huggingface.co/google/gemma-4-E4B-it)
- [google/gemma-4-31B-it-assistant · Hugging Face](https://huggingface.co/google/gemma-4-31B-it-assistant)
- [google/gemma-4-31B-it-qat-w4a16-ct · Hugging Face](https://huggingface.co/google/gemma-4-31B-it-qat-w4a16-ct)
- [google/gemma-4-31B-it-qat-q4_0-gguf · Hugging Face](https://huggingface.co/google/gemma-4-31B-it-qat-q4_0-gguf)
- [Gemma 4 collection | Hugging Face](https://huggingface.co/collections/google/gemma-4)
- [Gemma 4 Technical Report | arXiv 2607.02770](https://arxiv.org/abs/2607.02770)
- [Gemma 4 — Google DeepMind](https://deepmind.google/models/gemma/gemma-4/)
- [Gemma 4: Byte for byte, the most capable open models | Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/)
- [Accelerating Gemma 4: faster inference with multi-token prediction drafters | Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/multi-token-prediction-gemma-4/)
- [Introducing Gemma 4 12B: a unified, encoder-free multimodal model | Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/introducing-gemma-4-12b/)
- [DiffusionGemma | Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/diffusion-gemma-faster-text-generation/)
- [Gemma releases | Google AI for Developers](https://ai.google.dev/gemma/docs/releases)
- [google-gemma/cookbook | GitHub](https://github.com/google-gemma/cookbook)

### 검증된 외부 (Hugging Face, Simon Willison, Raschka, vLLM, Unsloth, Ollama, LM Studio)
- [Welcome Gemma 4: Frontier multimodal intelligence on device | Hugging Face Blog](https://huggingface.co/blog/gemma4)
- [Gemma 4 transformers docs](https://huggingface.co/docs/transformers/model_doc/gemma4)
- [Gemma 4: Byte for byte, the most capable open models | Simon Willison](https://simonwillison.net/2026/Apr/2/gemma-4/)
- [The Big LLM Architecture Comparison | Sebastian Raschka](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
- [Gemma 4 Usage Guide | vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [gemma4_tool_parser | vLLM API](https://docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/)
- [vLLM PR #41745 — Gemma4 MTP speculative decoding](https://github.com/vllm-project/vllm/pull/41745)
- [Gemma 4 - How to Run Locally | Unsloth](https://unsloth.ai/docs/models/gemma-4)
- [gemma4 | Ollama Library](https://ollama.com/library/gemma4) / [tags](https://ollama.com/library/gemma4/tags)
- [Ollama v0.23.1 release](https://github.com/ollama/ollama/releases/tag/v0.23.1) / [PR #15980 — Gemma4 MTP speculative decoding](https://github.com/ollama/ollama/pull/15980)
- [LM Studio 0.4.11 changelog](https://lmstudio.ai/changelog/lmstudio-v0.4.11)

### 커뮤니티 (참고용, 본문 단정 인용 회피)
- [google/gemma-4-31B-it discussion #53 (template 복잡도 → OpenWebUI·OpenCode 이중 CoT, vLLM PR #39027로 해결)](https://huggingface.co/google/gemma-4-31B-it/discussions/53)
- [google/gemma-4-26B-A4B-it discussion #26 (continue_final_message thinking 채널 누락 fix)](https://huggingface.co/google/gemma-4-26B-A4B-it/discussions/26)
- [unsloth/gemma-4-31B-it-GGUF discussion #16 (2026-04-11 Google chat template 수정 반영)](https://huggingface.co/unsloth/gemma-4-31B-it-GGUF/discussions/16)
- [Google ships a Gemma 4 update, sort of | techcityauthority (2026-07-16, 가중치 무변경 지적)](https://www.techcityauthority.com/2026/07/google-gemma-4-improvements-released.html)

**URL 접근 일자**: 초판 2026-05-07, 갱신 2026-09-11 (전 URL 재접근)
