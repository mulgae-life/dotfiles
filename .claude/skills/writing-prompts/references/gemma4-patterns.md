# Gemma 4 프롬프트 패턴

## 목차
- [개요 (Gemma 3 → 4 핵심 변화)](#개요-gemma-3--4-핵심-변화)
- [1. Chat Template 변경 (핵심)](#1-chat-template-변경-핵심)
- [2. System Role 신규 지원](#2-system-role-신규-지원)
- [3. Thinking 모드 (`<|think|>`)](#3-thinking-모드-think)
- [4. Multimodal 입력 (placement + visual budget)](#4-multimodal-입력-placement--visual-budget)
- [5. Tool Calling 공식 포맷](#5-tool-calling-공식-포맷)
- [6. 공식 Sampling 권장값](#6-공식-sampling-권장값)
- [7. 배포 트랩 (template 버전, vLLM, LM Studio)](#7-배포-트랩-template-버전-vllm-lm-studio)
- [8. Gemma 3 → 4 마이그레이션 체크리스트](#8-gemma-3--4-마이그레이션-체크리스트)
- [참고](#참고)

> Gemma 4는 Gemma 3의 **드롭인 교체가 아니다**. chat template 토큰이 완전 교체되고 system role이 신규 지원되며, thinking 채널이 표준화됐다. 옛 프롬프트를 그대로 쓰면 system 지시가 user 턴에 묻히거나 thinking 블록이 raw text로 누수된다. 출시 후에도 chat template이 두 번(2026-04, 2026-07) 바뀌었고 12B Unified가 추가돼 5종 체제다.
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/google-prompt-guide/gemma-4-prompt-guide.md`](../../../../reference/google-prompt-guide/gemma-4-prompt-guide.md)

---

## 개요 (Gemma 3 → 4 핵심 변화)

| 항목 | Gemma 3 | Gemma 4 |
|------|---------|---------|
| Chat template 토큰 | `<start_of_turn>` / `<end_of_turn>` | **`<\|turn>` / `<turn\|>`** (완전 교체) |
| System role | **미지원** ("user / model 두 역할만") | **네이티브 지원** |
| Thinking | 27B IT 부분 지원 | **`<\|think\|>` + `<\|channel>thought` 표준화**, 5 사이즈 전부 |
| Multimodal | 4B+ vision | **모든 사이즈 vision + E2B/E4B/12B audio**, 모든 사이즈 video |
| Vision token budget | 고정 | **70 / 140 / 280 / 560 / 1120** 가변 |
| Context length | 128K (대형) | **256K** (12B / 26B A4B / 31B), 128K (E2B/E4B) |
| Function calling | 비공식 | **6개 special token + `<\|"\|>` delimiter** 공식, 병렬 호출 포맷 명시 |
| 모델 변형 | 1B / 4B / 12B / 27B (밀집) | **E2B / E4B / 12B Unified (인코더 없음) / 26B A4B (MoE) / 31B (밀집)** |
| 추론 가속 | 없음 | **MTP 드래프터** `-assistant`(최대 3배, 출력 동일 주장), 공식 QAT(W4A16·Q4_0 GGUF) |
| 라이선스 | Gemma Terms (제한) | **Apache 2.0** (드래프터·QAT 포함) |
| 출시 | 2025-03 | **2026-04-02**, 12B는 2026-06-03 |

[공식, ai.google.dev/gemma/docs/core·model_card_4, 2026-09-11 접근]

---

## 1. Chat Template 변경 (핵심)

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]

### 1.1 Basic Template

```
<|turn>system
[system instructions]<turn|>
<|turn>user
[user message]<turn|>
<|turn>model
[response]<turn|>
```

### 1.2 Anti-Pattern

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

### 1.3 주요 Control Token

| 카테고리 | 토큰 | 용도 |
|---------|------|------|
| Dialogue | `<\|turn>` / `<turn\|>` | 턴 시작/끝 |
| Roles | `system`, `user`, `model` | 역할 식별자 |
| Thinking | `<\|think\|>` | system 프롬프트에서 thinking 활성화 |
| Thinking 출력 | `<\|channel>thought ... <channel\|>` | 모델이 emit하는 추론 블록 |
| Tool calls | `<\|tool_call>` / `<tool_call\|>` | 함수 호출 |
| Tool responses | `<\|tool_response>` / `<tool_response\|>` | 도구 실행 결과 |
| String literal | `<\|"\|>` | 함수 인자 string delimiter (표준 quote 대체) |

---

## 2. System Role 신규 지원

[공식, huggingface.co/google/gemma-4-31B-it]
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

**Gemma 3 워크어라운드 제거 필수**: Gemma 3 공식 가이드는 명시적으로 system role 미지원이었다 ("only two roles: `user` and `model`"). Gemma 4에서는 system 지시를 첫 user 메시지에 prepend하던 워크어라운드를 **반드시 제거**한다. 그렇지 않으면 system 토큰과 user 토큰에 동일 지시가 중복돼 모델이 우선순위를 혼동한다.

### 2.1 Chat template 인자 (2026-07-15 개정본 기준)

[공식, huggingface.co/google/gemma-4-31B-it chat_template.jinja]

| 인자 | 기본값 | 동작 |
|------|--------|------|
| `enable_thinking` | `false` | `true`면 시스템 턴 맨 앞에 `<\|think\|>\n` 주입 |
| `preserve_thinking` | `false` | `true`면 `tool_calls`가 있는 assistant 메시지의 `reasoning`/`reasoning_content`를 thought 블록으로 다시 렌더링 |

같은 개정에서 `tool_calls[].function.arguments`가 **문자열이면 예외**("must be a JSON object (mapping), not a string")가 나고, `null` 인자 처리와 연속 assistant 턴의 `<|turn>` 중복이 고쳐졌다. 가중치는 그대로다. OpenAI 호환 클라이언트가 `arguments`를 JSON 문자열로 되돌리면 렌더링이 실패하므로 객체로 파싱해서 넣는다.

---

## 3. Thinking 모드 (`<|think|>`)

[공식, huggingface.co/google/gemma-4-31B-it]
> "Thinking is enabled by including the `<|think|>` token at the start of the system prompt."

### 3.1 활성화 / 비활성화

- **활성화**: 시스템 프롬프트의 **맨 앞**에 `<|think|>` 추가
- **비활성화**: 토큰 제거. 단 **E2B/E4B를 제외한 모든 모델**(12B·26B A4B·31B)은 비활성화 상태에서도 빈 thought 블록을 emit → **앱 단에서 strip 후처리 필수** (vLLM은 `--reasoning-parser gemma4`, llama.cpp 계열은 `--chat-template-kwargs '{"enable_thinking":false}'`)
- **대화 중간에 끄기** [공식, prompt formatting]: "If you want to disable thinking mode mid-conversation, you can remove the `<|think|>` token when you strip the previous thoughts."

활성화 시 출력 구조:
```
<|channel>thought
[Internal reasoning]
<channel|>
[Final answer]
```

### 3.2 Multi-turn 처리 (필수 규칙)

[공식]
> "You must remove (strip) the model's generated thoughts from the previous turn before passing the conversation history back to the model for the next turn."

> "If a single model turn involves function or tool calls, thoughts must NOT be removed between the function calls."

→ **턴 종료 후 다음 user 메시지로 넘어가기 직전에만 strip**. 한 model 턴 안에서 여러 도구 호출 중에는 유지.

template에 맡기려면 `apply_chat_template(..., preserve_thinking=True)`를 주고 assistant 메시지에 `reasoning`(또는 `reasoning_content`) 필드를 실어 보낸다. 기본값이 `false`라 **도구 루프 클라이언트가 명시적으로 켜야** 예외 규칙이 적용된다. 마지막 user 턴 이전의 thought는 인자와 무관하게 렌더링되지 않는다.

### 3.3 Long-running agent 패턴

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]
> "A highly recommended inference technique is to extract, summarize, and feed the model's previous thoughts back into the context window as standard text."

→ 장기 에이전트에서는 직전 turn의 thought를 통째로 버리지 말고 1-2문단 요약본을 일반 텍스트로 주입. 추론 루프 방지라는 이유는 문서에 없고 본 문서의 해석이다.

### 3.4 Function calling과의 조합

[공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4]
> When `enable_thinking=True`, the model uses internal reasoning to enhance "function-calling accuracy" and parameter precision before executing tool calls.

→ 도구 호출 정확도 중요 시 thinking ON. 단순 분류·완료에는 OFF로 토큰·지연시간 절감.

---

## 4. Multimodal 입력 (placement + visual budget)

### 4.1 Placement 권장 (image는 앞, audio는 뒤)

[공식, huggingface.co/google/gemma-4-31B-it·gemma-4-12B-it, 2026-09-11]
> "Place: Image content **before** the text in your prompt. Audio content **after** the text in your prompt."

2026-06 12B 공개와 함께 audio 규칙이 "text 앞"에서 "text 뒤"로 바뀌었다. Unsloth 페이지는 아직 옛 문안이므로 모델 카드를 우선한다.

```python
# image → text
messages = [{
    "role": "user",
    "content": [
        {"type": "image", "image": "https://..."},   # ← 먼저
        {"type": "text",  "text": "What's in this image?"}  # ← 나중
    ]
}]

# text → audio (E2B/E4B/12B)
messages = [{
    "role": "user",
    "content": [
        {"type": "text",  "text": "Please transcribe the following audio:"},
        {"type": "audio", "url": "https://..."},
    ]
}]
```

### 4.2 Visual Token Budget

| 예산 | 사용처 (공식 권장) |
|------|-------------------|
| **70** | 분류, 캡셔닝, 비디오 이해 (저비용) |
| **140** | 동일 (디테일 보강) |
| **280** | **vLLM 디폴트**, 일반 이미지 이해 |
| **560** | 차트·문서 이해 |
| **1120** | OCR, 문서 파싱, 작은 텍스트 (최고 정확도) |

→ 단순 캡셔닝/분류에 1120은 토큰 낭비, OCR을 280으로 하면 작은 글자 누락. **작업 유형별 명시 선택.** 설정은 transformers 프로세서 인자 `max_soft_tokens`, vLLM `--mm-processor-kwargs '{"max_soft_tokens": 560}'` [검증된 외부, transformers docs·vLLM 레시피].

### 4.3 모달리티 매트릭스

| Variant | Text | Image | Audio | Video |
|---------|:----:|:-----:|:-----:|:-----:|
| E2B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| E4B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| 12B Unified | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s, 1fps) |
| 26B A4B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |
| 31B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |

→ **Audio가 필요한 워크로드는 E2B/E4B/12B**, 26B A4B·31B는 미지원. 12B는 인코더 없이 패치·파형을 직접 투영하지만 프롬프트 규칙은 같다.

---

## 5. Tool Calling 공식 포맷

[공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4]

### 5.1 Function Call 포맷

```
<|tool_call>call:function_name{parameter:<|"|>value<|"|>}<tool_call|>
```

- 모든 string 값은 `<|"|>`로 감싼다
- 도구 결과는 `<|tool_response> ... <tool_response|>`로 주입

### 5.2 String Delimiter `<|"|>`

[공식, ai.google.dev/gemma/docs/core/prompt-formatting-gemma4]
> "A single token, `<|"|>`, is used as a delimiter for all string values within the structured data blocks. This token ensures that any special characters (such as `{`, `}`, `,`, or quotes) inside a string are treated as literal text and not as part of the data structure's underlying syntax."

→ 표준 JSON quote 대신 단일 토큰 사용. 인자에 `{`, `}`, `,`, `"` 들어가도 파서가 깨지지 않는다.

### 5.3 4단계 워크플로우

1. **Define Tools** — JSON Schema 또는 Python 함수 시그니처 자동 추출
2. **Model's Turn** — 모델이 구조화된 함수 호출 emit
3. **Developer's Turn** — "Always validate function names and arguments before execution"
4. **Final Response** — 도구 실행 결과 주입 → 자연어 답변

> 공식 캐비엇: "If a function uses a custom object (like a Config class) as an argument, the automatic converter may describe it simply as a generic 'object' without detailing its internal properties. In these cases, manually defining the JSON schema is preferred to ensure nested properties ... are explicitly defined for the model."

### 5.4 병렬 호출과 히스토리 규칙

[공식, 동일 페이지 2026-06-04 갱신] "In case of multiple independent requests" — 한 턴의 여러 호출 결과는 하나의 `tool_responses` 배열로 되돌린다.

```python
"tool_responses": [
    {"name": function_name_1, "response": function_response_1},
    {"name": function_name_2, "response": function_response_2},
]
```

히스토리의 `tool_calls[].function.arguments`는 JSON 객체(§2.1). 도구 루프 중 thought 유지는 `preserve_thinking=True`(§3.2). 직접 서빙 루프를 짜면 `<|tool_response>`에서도 생성을 멈춘다 — 공식: "`<|tool_response>` acts as an additional stop sequence for the inference engine."

---

## 6. 공식 Sampling 권장값

[공식, huggingface.co/google/gemma-4-31B-it]
> "Use the following standardized sampling configuration across all use cases:
> - `temperature=1.0`
> - `top_p=0.95`
> - `top_k=64`"

> ⚠️ OpenAI/Anthropic의 일반 관행 `temperature=0.7`과 다르다. Gemma 4는 학습 시 temperature 1.0 분포에 RLHF되어 **임의로 낮추면 분포가 좁아져 품질이 떨어질 수 있다**. 결정론이 필요한 경우만 0으로 낮춰라.

vLLM 레시피 [검증된 외부, docs.vllm.ai]는 권장 문장 없이 예제 코드에 `0.0`(결정론) / `0.7`(창작)을 쓴다 — 공식 1.0과 다름. **공식 모델 카드 우선.**

---

## 7. 배포 트랩 (template 버전, vLLM, LM Studio)

### 7.1 vLLM 필수 플래그

[검증된 외부, docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html, 2026-09-11]

```bash
vllm serve google/gemma-4-31B-it \
  --tensor-parallel-size 2 \
  --max-model-len 16384 \
  --enable-auto-tool-choice \
  --reasoning-parser gemma4 \
  --tool-call-parser gemma4 \
  --chat-template examples/tool_chat_template_gemma4.jinja \
  --limit-mm-per-prompt '{"image": 4}' \
  --async-scheduling
# audio 미지원 사이즈(26B A4B·31B)는 audio 슬롯 0. 레시피: "For image-only workloads (no audio), pass --limit-mm-per-prompt.audio 0"
# 가속: --speculative-config '{"model": "google/gemma-4-31B-it-assistant", "num_speculative_tokens": 4}'
# 메모리: --kv-cache-dtype fp8, 또는 모델을 google/gemma-4-31B-it-qat-w4a16-ct로
```

→ **두 parser 플래그를 빼면** thinking 채널과 tool call이 raw text로 누수된다. thinking ON이면 `max_tokens`를 늘린다(레시피 명시).

### 7.2 런타임 내장 template 버전

chat template은 2026-04(출시 직후 수정)와 2026-07-15(`preserve_thinking`·인자 검증) 두 번 바뀌었고 가중치는 그대로다. vLLM·llama.cpp·LM Studio·Ollama가 들고 있는 template 사본이 구버전이면 §2.1의 인자와 검증이 없다. **모델을 다시 받거나 template 파일을 직접 갱신**한 뒤 transformers 직접 호출과 출력을 대조한다.

### 7.3 Simon Willison 출시일 보고 (LM Studio 31B) — 해소됨

[검증된 외부, simonwillison.net/2026/Apr/2/gemma-4/, lmstudio.ai/changelog/lmstudio-v0.4.11]

LM Studio에서 31B 모델이 출시 직후 chat template 파싱 깨짐으로 `"---\n"` 무한 반복. 작은 변형(2B, 4B, 26B-A4B)은 정상. Google이 2026-04 template을 수정했고 LM Studio 0.4.11에 "Support for updated Gemma 4 chat template"로 반영됐다. **교훈은 유효하다 — 출시 직후·template 개정 직후의 third-party 런타임은 transformers로 교차 검증.**

### 7.4 MTP 드래프터·QAT (프롬프트는 동일)

- MTP: `google/gemma-4-31B-it-assistant`(0.5B)를 transformers `assistant_model=`, vLLM `--speculative-config`, Ollama v0.23.1+ Modelfile `DRAFT`로 붙인다. Google 주장 "up to a 3x speedup", "Zero quality degradation" [공식, blog.google 2026-05-05]. 공식 예제는 `do_sample=False`이고 샘플링 ON 수치는 없다
- QAT: `google/gemma-4-31B-it-qat-w4a16-ct`(vLLM/SGLang, 약 19.8GB), `google/gemma-4-31B-it-qat-q4_0-gguf`(17.7GB, llama.cpp/Ollama). Ollama 태그 `31b-it-qat`
- DiffusionGemma(26B A4B 기반)는 실험 단계라 프로덕션은 표준 Gemma 4 권장 [공식, blog.google 2026-06-10]

---

## 8. Gemma 3 → 4 마이그레이션 체크리스트

1. [ ] 모델 ID 교체: `google/gemma-3-*` → `google/gemma-4-{E2B|E4B|12B|26B-A4B|31B}-it`
2. [ ] **Chat template 토큰 전수 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>`
3. [ ] **System 지시를 첫 user 메시지에서 분리**하여 별도 `system` role로 이동
4. [ ] Thinking 워크로드: 시스템 프롬프트 맨 앞에 `<|think|>` 추가
5. [ ] Thinking 비활성화 시: 빈 `<|channel>thought ... <channel|>` 블록 strip 후처리 추가 (E2B/E4B 제외 전부)
6. [ ] **Multi-turn 히스토리에서 직전 model 턴의 thought 블록 제거** (함수 호출 중에는 유지 — template은 `preserve_thinking=True`)
7. [ ] 장기 에이전트: thought 요약본을 일반 텍스트로 주입 (reasoning loop 방지)
8. [ ] Multimodal 입력 순서: image → text, text → audio
9. [ ] Vision token budget을 작업 유형별로 명시 (분류 70-140, OCR 1120; `max_soft_tokens`)
10. [ ] Function calling: `<|"|>` delimiter 포맷 채택, `tool_responses` 구조 사용, 히스토리 `arguments`는 JSON 객체
11. [ ] vLLM에 `--reasoning-parser gemma4 --tool-call-parser gemma4` 추가
12. [ ] 샘플링 디폴트를 `temperature=1.0, top_p=0.95, top_k=64`로 정렬
13. [ ] Context를 실사용 길이로 시작 → 필요 시 증가 (무조건 256K 금지, thinking ON이면 `max_tokens` 여유)
14. [ ] Audio 워크로드: E2B/E4B/12B 사용 (26B A4B·31B는 audio 미지원)
15. [ ] 라이선스 변경: Gemma Terms → **Apache 2.0** (상업 배포 자유)
16. [ ] 런타임 내장 chat template이 2026-07-15 개정본인지 확인
17. [ ] 지연이 문제면 MTP 드래프터·QAT를 같은 프롬프트로 A/B

---

## 참고

- [Gemma 4 풀 가이드 (한국어)](../../../../reference/google-prompt-guide/gemma-4-prompt-guide.md) — 15섹션 + 외부 노하우 + 미확인 영역
- [Gemma 4 공식 모델 카드](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Prompt formatting 공식](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling 공식](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [MTP 공식 (transformers)](https://ai.google.dev/gemma/docs/mtp/mtp)
- [Gemma 4 Technical Report (arXiv 2607.02770)](https://arxiv.org/abs/2607.02770)
- [HuggingFace 모델 카드 (31B-it)](https://huggingface.co/google/gemma-4-31B-it)
- [HuggingFace 모델 카드 (12B-it)](https://huggingface.co/google/gemma-4-12B-it)
- [HuggingFace Blog — Gemma 4 출시](https://huggingface.co/blog/gemma4)
- [vLLM Gemma 4 Recipe](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [Simon Willison — Gemma 4 출시일 분석](https://simonwillison.net/2026/Apr/2/gemma-4/)
- [Sebastian Raschka — LLM Architecture Comparison](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
- [Unsloth Gemma 4 가이드](https://unsloth.ai/docs/models/gemma-4)
