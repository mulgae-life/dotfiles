# Gemma 4 Prompting Guide

> **출처 (공식 1차)**:
> - [Gemma 4 model overview | Google AI for Developers](https://ai.google.dev/gemma/docs/core)
> - [Gemma 4 model card | Google AI for Developers](https://ai.google.dev/gemma/docs/core/model_card_4)
> - [Gemma 4 Prompt Formatting | Google AI for Developers](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
> - [Function calling with Gemma 4 | Google AI for Developers](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
> - [google/gemma-4-31B-it · Hugging Face](https://huggingface.co/google/gemma-4-31B-it)
> - [Gemma 4 — Google DeepMind](https://deepmind.google/models/gemma/gemma-4/)
> - [Gemma 4: Byte for byte, the most capable open models | Google blog (2026-04-02)](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/)
>
> **출처 (검증된 외부)**:
> - [Welcome Gemma 4: Frontier multimodal intelligence on device | Hugging Face Blog (2026-04-02)](https://huggingface.co/blog/gemma4)
> - [Gemma 4: Byte for byte, the most capable open models | Simon Willison (2026-04-02)](https://simonwillison.net/2026/Apr/2/gemma-4/)
> - [The Big LLM Architecture Comparison (Sec. 23) | Sebastian Raschka, Apr 2026](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
> - [Gemma 4 Usage Guide | vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
> - [Gemma 4 Fine-tuning Guide | Unsloth](https://unsloth.ai/docs/models/gemma-4)
> - [gemma4 | Ollama Library](https://ollama.com/library/gemma4)
> - [google-gemini/gemma-cookbook | GitHub](https://github.com/google-gemini/gemma-cookbook)
>
> **날짜**: 2026-05-07 (모든 URL 동일 일자 접근)
> **이전 버전**: Gemma 3 (2025년 3월 출시) — 본 문서 §13 마이그레이션 체크리스트 참조

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
| Thinking mode | 27B IT의 부분 지원 | **`<\|think\|>` 토큰 + `<\|channel>thought` 블록**으로 표준화, 4개 사이즈 전부 지원 |
| Multimodal | 4B/12B/27B에서 vision (Gemma 3 4B+) | **모든 사이즈 vision + E2B/E4B는 audio 추가**, 모든 사이즈 video |
| Vision token budget | 고정 | **70 / 140 / 280 / 560 / 1120**의 가변 예산 |
| Context length | 128K (대형) | **256K (26B A4B / 31B)**, 128K (E2B / E4B) |
| Function calling | 비공식 | **6개 special token 기반 공식 포맷** + `<\|"\|>` 문자열 delimiter |
| 모델 변형 | 1B / 4B / 12B / 27B (밀집) | **E2B / E4B / 26B A4B (MoE) / 31B (밀집)** — MoE 신규 |
| 라이선스 | Gemma Terms of Use (제한적) | **Apache 2.0** (상업 배포 자유) |
| 출시 | 2025-03 | **2026-04-02** |

> Hugging Face 공식 블로그 [검증된 외부, huggingface.co/blog/gemma4, 2026-04-02]: "These models are the real deal: truly open with Apache 2 licenses, high quality with pareto frontier arena scores, multimodal including audio, and sizes you can use everywhere including on-device."

---

## 개요

Gemma 4는 Google DeepMind가 2026년 4월 2일에 출시한 오픈 가중치 모델 패밀리다 [공식, blog.google/innovation-and-ai/technology/developers-tools/gemma-4/, 2026-05-07]. Apache 2.0 라이선스로 상업 배포 제약이 없으며, 4개 사이즈 모두 vision-capable이고 E2B/E4B는 audio까지 입력으로 받는다.

### 핵심 강점

- **Native system role**: Gemma 3의 "user 턴에 system 지시 우겨넣기" 워크어라운드가 사라짐
- **Configurable thinking**: 시스템 프롬프트에 `<|think|>` 토큰 한 줄로 추론 채널 토글
- **Variable visual token budget**: OCR/문서 작업과 분류/캡셔닝을 같은 모델로 비용-품질 곡선 위에서 선택
- **Apache 2.0**: Gemma 3까지 발목 잡았던 라이선스 제약 해소
- **256K context** (대형 2종): 장문맥 retrieval, 코드베이스, 긴 PDF
- **공식 function calling 포맷**: 6개 special token 기반의 결정론적 파싱

### 명시적 프롬프팅이 여전히 필요한 영역

- Multi-turn에서 이전 thought 채널을 **반드시 제거**해야 한다는 룰 (자동으로 안 됨)
- `<|"|>` 문자열 delimiter 사용 (표준 JSON quoting과 다름)
- Multimodal placement: image/audio는 **text 앞에**
- Thinking 비활성화 시에도 빈 thought 블록이 emit되는 동작 (앱 단에서 stripping 필요)

---

## 1. 모델 변형 (Variants)

Google AI for Developers 공식 모델 카드 [공식, ai.google.dev/gemma/docs/core/model_card_4, 2026-05-07] 기준:

| Variant | 유효/총 파라미터 | Context | 모달리티 (입력) | BF16 메모리 | 권장 사용처 |
|---------|------------------|---------|----------------|-------------|------------|
| **E2B** | 2.3B 유효 / 5.1B (임베딩 포함) | 128K | Text + Image + **Audio** | 9.6 GB | 모바일/IoT, on-device |
| **E4B** | 4.5B 유효 / 8B (임베딩 포함) | 128K | Text + Image + **Audio** | 15 GB | 엣지 디바이스, 스마트폰급 |
| **26B A4B** | 3.8B active / 26B total (MoE) | 256K | Text + Image | 48 GB | latency-optimized 서버, 대용량 동시 요청 |
| **31B** | 30.7B (dense) | 256K | Text + Image | 58.3 GB | 최대 품질, 강한 추론 |

**라이선스**: 모든 변형 Apache 2.0 [공식, 모델 카드].

**Audio/Video 길이 제한** [공식, huggingface.co/google/gemma-4-31B-it]:
> "Audio supports a maximum length of 30 seconds. Video supports a maximum of 60 seconds assuming the images are processed at one frame per second."

**다국어 지원** [공식, 모델 카드]:
> "Out-of-the-box support for 35+ languages, pre-trained on 140+ languages"

Sebastian Raschka [검증된 외부, magazine.sebastianraschka.com, 2026-04-02 업데이트]는 Gemma 4 아키텍처를 다음과 같이 요약:
> "Dense Gemma 4 scales the family to a 256K-context multimodal checkpoint without changing the core local-global recipe much"
> "the sparse Gemma 4 variant keeps the local:global attention backbone while swapping dense FFNs for MoE layers"
> "the smallest Gemma 4 edge model keeps the family's hybrid attention stack and adds native audio on a phone-scale multimodal footprint"

즉 4개 사이즈가 동일한 local-global hybrid attention backbone을 공유하므로, **변형 간 프롬프트는 거의 그대로 호환된다** (단, 256K context와 audio 입력은 사이즈별로 가용성이 다르다).

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

**비활성화**: `<|think|>` 토큰을 제거. 단 31B의 경우, 비활성화 상태에서도 모델이 빈 thought 블록을 여전히 emit한다 [공식, huggingface.co/google/gemma-4-31B-it]:
```
<|channel>thought
<channel|>
[Final answer]
```

→ **앱 단에서 thought 블록을 strip하는 후처리가 필수.** vLLM 사용 시 `--reasoning-parser gemma4`를 켜면 자동 처리된다 [검증된 외부, docs.vllm.ai].

### 3.2 Multi-turn에서의 thought 처리 규칙 (중요)

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "You must remove (strip) the model's generated thoughts from the previous turn before passing the conversation history back to the model for the next turn."

Hugging Face 모델 카드도 동일 규칙:
> "In multi-turn conversations, the historical model output should only include the final response. Thoughts from previous model turns must _not be added_ before the next user turn begins."

**예외 (Function calling 중)** [공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "If a single model turn involves function or tool calls, thoughts must NOT be removed between the function calls."

즉 **하나의 model 턴 안에서 여러 도구 호출이 일어나는 동안에는 thought를 유지**해야 한다. 턴이 종료된 뒤 다음 user 메시지로 넘어가기 직전에만 strip한다.

### 3.3 Long-running agent 권장 패턴

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]:
> "Consider summarizing stripped thoughts and injecting them back as standard text to prevent reasoning loops in long-running agents."

→ 장기 에이전트에서는 직전 turn의 thought를 통째로 버리지 말고 1-2문단 요약본을 일반 텍스트로 주입. 그렇지 않으면 같은 추론을 반복하는 루프에 빠질 수 있다.

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
| 26B A4B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |
| 31B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |

[공식, ai.google.dev/gemma/docs/core/model_card_4, huggingface.co/google/gemma-4-31B-it]

### 4.2 Placement 권장 (반드시 image/audio가 text 앞)

[공식, huggingface.co/google/gemma-4-31B-it]:
> "For optimal performance with multimodal inputs, place image and/or audio content **before** the text in your prompt."

```python
messages = [{
    "role": "user",
    "content": [
        {"type": "image", "image": "https://..."},   # ← 먼저
        {"type": "text",  "text": "What's in this image?"}  # ← 나중
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

---

## 5. Tokenizer / 어휘 특성

[공식, huggingface.co/google/gemma-4-31B-it, 2026-05-07]:

- **Vocabulary size**: 262K (Gemma 3의 256K에서 확장)
- **Sliding window**: 1024 tokens
- **Vision encoder**: ~150M (E2B/E4B), ~550M (26B A4B / 31B)
- **EOS / turn 종료 토큰**: `<turn|>` (Unsloth 노트 [검증된 외부, unsloth.ai/docs/models/gemma-4]: "End of Sentence 토큰: `<turn|>`")

특이점: 함수 호출의 문자열 인자에 표준 따옴표 대신 **`<|"|>` 단일 토큰**을 delimiter로 쓴다. 이 설계는 인자 안에 `{`, `}`, `,`, `"` 같은 문자가 들어가도 파서가 깨지지 않게 한다 ([공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4]):
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

> 공식 캐비엇: "Manual JSON schemas are preferred for complex parameters like custom objects, as automatic conversion may oversimplify nested properties."

### 6.4 Tool Response 포맷

```python
"tool_responses": [
    {"name": function_name, "response": function_response}
]
```

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
| E2B / E4B | 128K | 1024 |
| 26B A4B / 31B | **256K** | 1024 |

[공식, ai.google.dev/gemma/docs/core, huggingface.co/google/gemma-4-31B-it]

Unsloth 권장 [검증된 외부, unsloth.ai/docs/models/gemma-4, 2026-05-07]:
> "32K 컨텍스트로 시작한 후 필요에 따라 증가시키세요."

→ **무조건 256K로 띄우지 말 것.** 메모리·KV cache가 선형 이상으로 증가한다. 실제 입력 길이에 가까운 `--max-model-len`으로 시작.

vLLM 디폴트 권장 [검증된 외부, docs.vllm.ai]:
- 최소 컨텍스트: 8192
- GPU memory utilization: 0.85-0.95
- 31B BF16: 80GB GPU 1장 또는 TP=2

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

vLLM의 비공식 권장 [검증된 외부, docs.vllm.ai]은 약간 다르다:
> "Use `temperature=0.0` for deterministic outputs; `temperature=0.7` for creative tasks."

→ 두 권장이 충돌. **공식 모델 카드(1.0)를 우선**으로 두고, 결정론 필요 시에만 0으로 내릴 것을 권장.

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
| `transformers` | ✅ | `AutoModelForMultimodalLM` 사용 |
| `vllm` | ✅ | `--reasoning-parser gemma4 --tool-call-parser gemma4` |
| `llama.cpp` | ✅ | GGUF 양자화 |
| `ollama` | ✅ | `ollama run gemma4:31b` 등 |
| `MLX` | ✅ | Apple Silicon, "TurboQuant" 지원 |
| `transformers.js` | ✅ | WebGPU 인-브라우저 |
| `Mistral.rs` | ✅ | Rust 네이티브 |
| `ONNX` | ✅ | 엣지 디바이스 |

### 10.2 Ollama 기본

[검증된 외부, ollama.com/library/gemma4, 2026-05-07]:
- 가용 태그: `e2b`, `e4b`, `26b`, `31b`, `31b-cloud`, 그 외 quantization variant
- Thinking 활성화: 시스템 프롬프트에 `<|think|>` 추가

### 10.3 Unsloth 알려진 이슈

[검증된 외부, unsloth.ai/docs/models/gemma-4]:
> "CUDA 13.2 런타임은 GGUF에서 저품질 출력을 유발하므로 피하세요"

→ 로컬 GGUF 사용 시 CUDA 13.2 회피 필요.

### 10.4 Fine-tuning

[검증된 외부, huggingface.co/blog/gemma4]:
- TRL (Hugging Face) — multimodal tool response 포함 SFT 예제 제공
- Unsloth Studio — UI 기반
- Vertex AI (Google Cloud) — 공식 예제로 vision/audio tower freeze한 채 function calling 확장

> HF 블로그 노트 [검증된 외부]: "In tests with pre-release checkpoints, the models were so impressive out of the box that it was difficult to find good fine-tuning examples because they are so good out of the box."
> → **Gemma 4는 fine-tune 전에 먼저 prompt engineering으로 충분한지 검증할 가치가 있다.**

---

## 11. Gemma 3 → 4 마이그레이션 체크리스트

1. [ ] 모델 ID를 `google/gemma-3-*` → `google/gemma-4-{E2B|E4B|26B-A4B|31B}-it`로 교체
2. [ ] **Chat template 토큰 전수 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>`
3. [ ] **System 지시를 첫 user 메시지에서 분리**하여 별도 `system` role로 이동 (Gemma 3 워크어라운드 제거)
4. [ ] Thinking이 필요한 워크로드: 시스템 프롬프트 맨 앞에 `<|think|>` 추가
5. [ ] Thinking 비활성화 시: 빈 `<|channel>thought ... <channel|>` 블록 strip 후처리 추가
6. [ ] **Multi-turn 히스토리에서 직전 model 턴의 thought 블록 제거** (단, function calling 중에는 유지)
7. [ ] 장기 에이전트: thought 요약본을 일반 텍스트로 주입하여 reasoning loop 방지
8. [ ] Multimodal 입력 순서를 image/audio → text로 재배치
9. [ ] Vision token budget을 작업 유형별로 명시 (분류 70-140, OCR 1120)
10. [ ] Function calling 사용 시: `<|"|>` delimiter 포맷으로 마이그레이션, `tool_responses` 구조 채택
11. [ ] vLLM 사용 시 `--reasoning-parser gemma4 --tool-call-parser gemma4` 추가
12. [ ] 샘플링 디폴트를 `temperature=1.0, top_p=0.95, top_k=64`로 정렬 (공식 권장)
13. [ ] Context length를 실제 사용량에 맞춰 시작 (32K → 필요 시 증가, 무조건 256K 금지)
14. [ ] Audio 입력이 필요한 워크로드는 E2B/E4B 사용 (대형 2종은 audio 미지원)
15. [ ] 라이선스 확인: Gemma 3의 Gemma Terms 제약 → Apache 2.0으로 자유로워짐

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
  --chat-template examples/tool_chat_template_gemma4.jinja
```

---

## 13. Key Takeaways

1. **System role을 써라** — Gemma 3의 user-prepend 워크어라운드는 마이그레이션 시 1순위 제거 대상
2. **Chat template 토큰 전수 교체** — `<|turn>` / `<turn|>`. `<start_of_turn>`은 더 이상 유효하지 않음
3. **Thinking은 시스템 프롬프트 맨 앞 `<|think|>` 한 줄**로 토글
4. **Multi-turn에서 직전 thought 블록은 반드시 strip** (function calling 중 예외)
5. **Multimodal 입력은 image/audio → text 순서**
6. **Visual token budget을 작업별로 명시** (분류 70, OCR 1120)
7. **Function calling은 `<|"|>` delimiter + 6개 special token 포맷**
8. **샘플링 공식 디폴트는 temp=1.0, top_p=0.95, top_k=64** (`0.7` 관행 그대로 가져오지 말 것)
9. **Context는 32K로 시작**, 256K 무조건 띄우지 말 것
10. **Apache 2.0** — Gemma 3까지의 라이선스 제약은 사라졌다

**가장 높은 레버리지 변경**: system role 분리 + chat template 토큰 전수 교체 + thinking 토글 정책 명시.

---

## 14. 고수들의 노하우 (외부 검증)

### 14.1 Simon Willison — pelican SVG 벤치마크 + 31B LM Studio 이슈

**누가**: Simon Willison (simonwillison.net 운영자, Datasette 창립자)
**언제**: 2026-04-02 (Gemma 4 출시 당일)
**어디서**: [simonwillison.net/2026/Apr/2/gemma-4/](https://simonwillison.net/2026/Apr/2/gemma-4/)
**무엇을**:

- Google의 자평 인용: > "unprecedented level of intelligence-per-parameter" — small useful model 경쟁의 최전선임을 강조
- E2B/E4B의 "E"가 "Effective" 파라미터의 약어임을 첫 보도
- **재현 가능한 발견 (커뮤니티에서 확인됨)**: LM Studio에서 31B 모델을 돌렸을 때 "was broken and spat out `\"---\\n\"` in a loop" — 모든 프롬프트에 대해. 작은 변형(2B, 4B, 26B-A4B)은 정상 작동. 출시 직후 LM Studio chat template 파싱 문제로 추정 (Hugging Face discussion #53도 동일 증상 보고)
- 그의 "pelican riding bicycle" SVG 시각 품질 벤치마크: 26B-A4B가 작은 변형 대비 명확히 우수
- llm-gemini 도구로 AI Studio API 통합

**시사점**: **출시 직후 third-party 런타임은 chat template 파싱이 깨질 수 있다.** 31B를 LM Studio에서 쓰는 경우 vLLM/transformers 직접 호출로 교차 검증 필수.

### 14.2 Sebastian Raschka — local-global hybrid attention 분석

**누가**: Sebastian Raschka (Lightning AI, "Build a Large Language Model from Scratch" 저자)
**언제**: 2026-04-02 ("The Big LLM Architecture Comparison" Section 23 추가)
**어디서**: [magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
**무엇을**:

- > "Dense Gemma 4 scales the family to a 256K-context multimodal checkpoint without changing the core local-global recipe much"
- > "the sparse Gemma 4 variant keeps the local:global attention backbone while swapping dense FFNs for MoE layers"
- > "the smallest Gemma 4 edge model keeps the family's hybrid attention stack and adds native audio on a phone-scale multimodal footprint"

**시사점**: 4개 변형이 동일한 attention backbone을 공유하므로 **프롬프트 엔지니어링 노하우는 변형 간 거의 그대로 이전 가능**. 변형 선택은 주로 (a) 메모리 (b) audio 필요 여부 (c) latency vs 품질 트레이드오프로 결정.

### 14.3 Hugging Face Blog — PLE / Shared KV / TurboQuant

**누가**: Hugging Face 공식 블로그팀
**언제**: 2026-04-02
**어디서**: [huggingface.co/blog/gemma4](https://huggingface.co/blog/gemma4)
**무엇을 (재현 가능한 기술 디테일)**:

- **Per-Layer Embeddings (PLE)**: 각 레이어마다 저차원 conditioning pathway. E2B/E4B의 "Effective" 파라미터 수가 임베딩 포함 총 파라미터 수보다 작은 이유
- **Shared KV Cache**: "Last N layers reuse key-value states from earlier layers" — 추론 시 메모리 절감
- **MLX TurboQuant**: Apple Silicon에서 새 양자화 포맷 지원
- **Pareto frontier arena scores**: > "high quality with pareto frontier arena scores" — LMArena 기준 1452 (31B)
- **Fine-tuning 노트**: > "the models were so impressive out of the box that it was difficult to find good fine-tuning examples" — fine-tune 전에 prompt engineering으로 충분한지 먼저 평가하라는 시사점

### 14.4 Unsloth — CUDA 13.2 회피, 32K 시작 권장

**누가**: Unsloth 팀 (오픈소스 fine-tuning 프레임워크)
**언제**: 2026-04-02 출시 시점에 가이드 동시 공개
**어디서**: [unsloth.ai/docs/models/gemma-4](https://unsloth.ai/docs/models/gemma-4)
**무엇을 (재현 가능한 운영 노하우)**:

- > "32K 컨텍스트로 시작한 후 필요에 따라 증가시키세요" — 256K 무조건 띄우는 안티 패턴 경고
- > "CUDA 13.2 런타임은 GGUF에서 저품질 출력을 유발하므로 피하세요" — 환경 trap
- 공식 샘플링(temp=1.0, top_p=0.95, top_k=64) 재확인

### 14.5 vLLM 팀 — gemma4 reasoning/tool parser

**누가**: vLLM 프로젝트 메인테이너
**언제**: 2026-04 (Gemma 4 출시 직후)
**어디서**: [docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html), [docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/](https://docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/)
**무엇을**:

- 전용 `--reasoning-parser gemma4` 추가 — thinking 채널 자동 분리
- 전용 `--tool-call-parser gemma4` — `<|"|>` delimiter 포맷 자동 파싱
- TPU (Trillium / Ironwood), AMD GPU, NVIDIA GPU 모두 지원 레시피 제공
- 비디오는 "custom vLLM processing pipeline that extracts frames"로 처리

**시사점**: vLLM을 Gemma 3 설정 그대로 띄우면 thinking/tool 출력이 raw text로 누수된다. **Gemma 4 전용 parser 두 플래그를 반드시 켜라.**

### 14.6 Ollama / Gemma Cookbook — 표준 진입점

- **Ollama** [ollama.com/library/gemma4](https://ollama.com/library/gemma4): `ollama run gemma4:31b` 한 줄로 로컬 실행, thinking은 시스템 프롬프트에 `<|think|>` 추가로 활성화
- **Google Gemma Cookbook** [github.com/google-gemini/gemma-cookbook](https://github.com/google-gemini/gemma-cookbook): 공식 예제 모음. Tutorials / Apps / Experiments / Responsible / Docs 카테고리. **(2026-05-07 접근 시점)** Gemma 4 전용 노트북이 본 cookbook에 통합 중인지 별도 위치인지는 확인되지 않음 (§15 참조)

---

## 15. 확인되지 않은 영역 (솔직한 빈칸)

본 가이드 작성 시점(2026-05-07)에 공식 1차 자료에서 확인 불가했던 항목:

1. **Few-shot 권장 개수**: Google 공식 모델 카드/문서에 specific few-shot 권장(예: "3-5 examples") 명시 없음. 일반 통설(0-5)을 추측 인용하지 않음.
2. **시스템 프롬프트 권장 길이 상한**: 공식 권장 토큰 길이 가이드라인 없음.
3. **Sebastian Raschka 본문 직접 인용**: 검색 결과 발췌문은 확보했으나 본인이 작성한 Section 23 본문 전체는 fetch에서 잘려 직접 인용 불가. WebSearch 요약 기반 인용임을 명시.
4. **Gemma Cookbook의 Gemma 4 전용 디렉토리**: 공식 cookbook 리포에 `Gemma4/` 또는 동등 디렉토리가 있는지 2026-05-07 시점에 검색 결과로 확인 불가. Gemma 2/3 디렉토리는 존재.
5. **31B의 LM Studio 깨짐 문제 해결 여부**: Simon Willison이 출시 당일 보고. 본 가이드 작성 시점에 패치 여부 미확인. 사용 시 vLLM/transformers로 교차 검증 권장.
6. **MoE 26B A4B의 expert routing 디테일**: 모델 카드는 활성 파라미터 수만 공개. expert 수, top-k routing 등 학술 디테일은 technical report 미공개로 미확인.
7. **Tool calling의 parallel tool call 지원 여부**: 공식 가이드는 4-stage cycle만 설명. 한 model 턴에서 여러 도구를 동시에 호출하는 패턴의 공식 권장 포맷은 명시 없음 (function calling 중 thought 유지 규칙으로 미루어 지원되는 것으로 보이나 명시적 인용 불가).
8. **Audio/Video 입력 시 visual token budget 효과**: 비디오는 1fps로 frame 추출되어 image budget이 적용되는지, 별도 video budget이 있는지 명시적 공식 인용 미확보.

위 항목은 향후 공식 문서 업데이트나 technical report 공개 시 보강 예정.

---

## Sources

### 공식 1차 (Google / DeepMind / 공식 모델 카드)
- [Gemma 4 model overview | Google AI for Developers](https://ai.google.dev/gemma/docs/core)
- [Gemma 4 model card | Google AI for Developers](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Gemma 4 Prompt Formatting | Google AI for Developers](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling with Gemma 4 | Google AI for Developers](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [google/gemma-4-31B-it · Hugging Face](https://huggingface.co/google/gemma-4-31B-it)
- [google/gemma-4-26B-A4B-it · Hugging Face](https://huggingface.co/google/gemma-4-26B-A4B-it)
- [google/gemma-4-E4B-it · Hugging Face](https://huggingface.co/google/gemma-4-E4B-it)
- [Gemma 4 — Google DeepMind](https://deepmind.google/models/gemma/gemma-4/)
- [Gemma 4: Byte for byte, the most capable open models | Google blog](https://blog.google/innovation-and-ai/technology/developers-tools/gemma-4/)
- [Gemma releases | Google AI for Developers](https://ai.google.dev/gemma/docs/releases)
- [google-gemini/gemma-cookbook | GitHub](https://github.com/google-gemini/gemma-cookbook)

### 검증된 외부 (Hugging Face, Simon Willison, Raschka, vLLM, Unsloth)
- [Welcome Gemma 4: Frontier multimodal intelligence on device | Hugging Face Blog](https://huggingface.co/blog/gemma4)
- [Gemma 4 transformers docs](https://huggingface.co/docs/transformers/model_doc/gemma4)
- [Gemma 4: Byte for byte, the most capable open models | Simon Willison](https://simonwillison.net/2026/Apr/2/gemma-4/)
- [The Big LLM Architecture Comparison | Sebastian Raschka](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
- [Gemma 4 Usage Guide | vLLM Recipes](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [gemma4_tool_parser | vLLM API](https://docs.vllm.ai/en/latest/api/vllm/tool_parsers/gemma4_tool_parser/)
- [Gemma 4 Fine-tuning Guide | Unsloth](https://unsloth.ai/docs/models/gemma-4)
- [gemma4 | Ollama Library](https://ollama.com/library/gemma4)

### 커뮤니티 (참고용, 본문 단정 인용 회피)
- [google/gemma-4-31B-it discussion #53 (chat template 이슈)](https://huggingface.co/google/gemma-4-31B-it/discussions/53)
- [google/gemma-4-26B-A4B-it discussion #26 (continue_final_message thinking 채널 누락 fix)](https://huggingface.co/google/gemma-4-26B-A4B-it/discussions/26)

**모든 URL 접근 일자**: 2026-05-07
