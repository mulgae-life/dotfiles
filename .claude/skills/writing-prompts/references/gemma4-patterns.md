# Gemma 4 프롬프트 패턴

## 목차
- [개요 (Gemma 3 → 4 핵심 변화)](#개요-gemma-3--4-핵심-변화)
- [1. Chat Template 변경 (핵심)](#1-chat-template-변경-핵심)
- [2. System Role 신규 지원](#2-system-role-신규-지원)
- [3. Thinking 모드 (`<|think|>`)](#3-thinking-모드-think)
- [4. Multimodal 입력 (placement + visual budget)](#4-multimodal-입력-placement--visual-budget)
- [5. Tool Calling 공식 포맷](#5-tool-calling-공식-포맷)
- [6. 공식 Sampling 권장값](#6-공식-sampling-권장값)
- [7. 배포 트랩 (vLLM, CUDA, LM Studio)](#7-배포-트랩-vllm-cuda-lm-studio)
- [8. Gemma 3 → 4 마이그레이션 체크리스트](#8-gemma-3--4-마이그레이션-체크리스트)
- [참고](#참고)

> Gemma 4는 Gemma 3의 **드롭인 교체가 아니다**. chat template 토큰이 완전 교체되고 system role이 신규 지원되며, thinking 채널이 표준화됐다. 옛 프롬프트를 그대로 쓰면 system 지시가 user 턴에 묻히거나 thinking 블록이 raw text로 누수된다.
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/google-prompt-guide/gemma-4-prompt-guide.md`](../../../../reference/google-prompt-guide/gemma-4-prompt-guide.md)

---

## 개요 (Gemma 3 → 4 핵심 변화)

| 항목 | Gemma 3 | Gemma 4 |
|------|---------|---------|
| Chat template 토큰 | `<start_of_turn>` / `<end_of_turn>` | **`<\|turn>` / `<turn\|>`** (완전 교체) |
| System role | **미지원** ("user / model 두 역할만") | **네이티브 지원** |
| Thinking | 27B IT 부분 지원 | **`<\|think\|>` + `<\|channel>thought` 표준화**, 4 사이즈 전부 |
| Multimodal | 4B+ vision | **모든 사이즈 vision + E2B/E4B audio**, 모든 사이즈 video |
| Vision token budget | 고정 | **70 / 140 / 280 / 560 / 1120** 가변 |
| Context length | 128K (대형) | **256K** (26B A4B / 31B), 128K (E2B/E4B) |
| Function calling | 비공식 | **6개 special token + `<\|"\|>` delimiter** 공식 |
| 모델 변형 | 1B / 4B / 12B / 27B (밀집) | **E2B / E4B / 26B A4B (MoE) / 31B (밀집)** |
| 라이선스 | Gemma Terms (제한) | **Apache 2.0** |
| 출시 | 2025-03 | **2026-04-02** |

[공식, ai.google.dev/gemma/docs/core, 2026-05-07 접근]

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

---

## 3. Thinking 모드 (`<|think|>`)

[공식, huggingface.co/google/gemma-4-31B-it]
> "Thinking is enabled by including the `<|think|>` token at the start of the system prompt."

### 3.1 활성화 / 비활성화

- **활성화**: 시스템 프롬프트의 **맨 앞**에 `<|think|>` 추가
- **비활성화**: 토큰 제거. 단 31B는 비활성화 상태에서도 빈 thought 블록을 emit → **앱 단에서 strip 후처리 필수**

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

### 3.3 Long-running agent 패턴

[공식]
> "Consider summarizing stripped thoughts and injecting them back as standard text to prevent reasoning loops in long-running agents."

→ 장기 에이전트에서는 직전 turn의 thought를 통째로 버리지 말고 1-2문단 요약본을 일반 텍스트로 주입.

### 3.4 Function calling과의 조합

[공식, ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4]
> When `enable_thinking=True`, the model uses internal reasoning to enhance "function-calling accuracy" and parameter precision before executing tool calls.

→ 도구 호출 정확도 중요 시 thinking ON. 단순 분류·완료에는 OFF로 토큰·지연시간 절감.

---

## 4. Multimodal 입력 (placement + visual budget)

### 4.1 Placement 권장

[공식, huggingface.co/google/gemma-4-31B-it]
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

### 4.2 Visual Token Budget

| 예산 | 사용처 (공식 권장) |
|------|-------------------|
| **70** | 분류, 캡셔닝, 비디오 이해 (저비용) |
| **140** | 동일 (디테일 보강) |
| **280** | **vLLM 디폴트**, 일반 이미지 이해 |
| **560** | 차트·문서 이해 |
| **1120** | OCR, 문서 파싱, 작은 텍스트 (최고 정확도) |

→ 단순 캡셔닝/분류에 1120은 토큰 낭비, OCR을 280으로 하면 작은 글자 누락. **작업 유형별 명시 선택.**

### 4.3 모달리티 매트릭스

| Variant | Text | Image | Audio | Video |
|---------|:----:|:-----:|:-----:|:-----:|
| E2B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| E4B | ✅ | ✅ | ✅ (≤30s) | ✅ (≤60s) |
| 26B A4B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |
| 31B | ✅ | ✅ | ❌ | ✅ (≤60s, 1fps) |

→ **Audio가 필요한 워크로드는 E2B/E4B만 가능**, 대형 2종은 미지원.

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

[공식]
> "A single token, `<|"|>`, is used as a delimiter for all string values within the structured data blocks. This token ensures that any special characters (such as `{`, `}`, `,`, or quotes) inside a string are treated as literal text and not as part of the data structure's underlying syntax."

→ 표준 JSON quote 대신 단일 토큰 사용. 인자에 `{`, `}`, `,`, `"` 들어가도 파서가 깨지지 않는다.

### 5.3 4단계 워크플로우

1. **Define Tools** — JSON Schema 또는 Python 함수 시그니처 자동 추출
2. **Model's Turn** — 모델이 구조화된 함수 호출 emit
3. **Developer's Turn** — "Always validate function names and arguments before execution"
4. **Final Response** — 도구 실행 결과 주입 → 자연어 답변

> 공식 캐비엇: "Manual JSON schemas are preferred for complex parameters like custom objects, as automatic conversion may oversimplify nested properties."

---

## 6. 공식 Sampling 권장값

[공식, huggingface.co/google/gemma-4-31B-it]
> "Use the following standardized sampling configuration across all use cases:
> - `temperature=1.0`
> - `top_p=0.95`
> - `top_k=64`"

> ⚠️ OpenAI/Anthropic의 일반 관행 `temperature=0.7`과 다르다. Gemma 4는 학습 시 temperature 1.0 분포에 RLHF되어 **임의로 낮추면 분포가 좁아져 품질이 떨어질 수 있다**. 결정론이 필요한 경우만 0으로 낮춰라.

vLLM 비공식 권장 [검증된 외부, docs.vllm.ai]은 `0.0` (결정론) / `0.7` (창작)을 권장 — 공식 1.0과 충돌. **공식 모델 카드 우선.**

---

## 7. 배포 트랩 (vLLM, CUDA, LM Studio)

### 7.1 vLLM 필수 플래그

[검증된 외부, docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html]

```bash
vllm serve google/gemma-4-31B-it \
  --tensor-parallel-size 2 \
  --max-model-len 16384 \
  --enable-auto-tool-choice \
  --reasoning-parser gemma4 \
  --tool-call-parser gemma4 \
  --chat-template examples/tool_chat_template_gemma4.jinja
```

→ **두 parser 플래그를 빼면** thinking 채널과 tool call이 raw text로 누수된다.

### 7.2 Unsloth 알려진 이슈

[검증된 외부, unsloth.ai/docs/models/gemma-4]
> "CUDA 13.2 런타임은 GGUF에서 저품질 출력을 유발하므로 피하세요"
> "32K 컨텍스트로 시작한 후 필요에 따라 증가시키세요" — 256K 무조건 띄우는 안티 패턴 경고

### 7.3 Simon Willison 출시일 보고 (LM Studio 31B)

[검증된 외부, simonwillison.net/2026/Apr/2/gemma-4/]

LM Studio에서 31B 모델이 출시 직후 chat template 파싱 깨짐으로 `"---\n"` 무한 반복. 작은 변형(2B, 4B, 26B-A4B)은 정상. **출시 직후 third-party 런타임은 chat template 파싱이 깨질 수 있다 — vLLM/transformers로 교차 검증 권장.**

---

## 8. Gemma 3 → 4 마이그레이션 체크리스트

1. [ ] 모델 ID 교체: `google/gemma-3-*` → `google/gemma-4-{E2B|E4B|26B-A4B|31B}-it`
2. [ ] **Chat template 토큰 전수 교체**: `<start_of_turn>` → `<|turn>`, `<end_of_turn>` → `<turn|>`
3. [ ] **System 지시를 첫 user 메시지에서 분리**하여 별도 `system` role로 이동
4. [ ] Thinking 워크로드: 시스템 프롬프트 맨 앞에 `<|think|>` 추가
5. [ ] Thinking 비활성화 시: 빈 `<|channel>thought ... <channel|>` 블록 strip 후처리 추가
6. [ ] **Multi-turn 히스토리에서 직전 model 턴의 thought 블록 제거** (단, 함수 호출 중에는 유지)
7. [ ] 장기 에이전트: thought 요약본을 일반 텍스트로 주입 (reasoning loop 방지)
8. [ ] Multimodal 입력 순서를 image/audio → text로 재배치
9. [ ] Vision token budget을 작업 유형별로 명시 (분류 70-140, OCR 1120)
10. [ ] Function calling: `<|"|>` delimiter 포맷 채택, `tool_responses` 구조 사용
11. [ ] vLLM에 `--reasoning-parser gemma4 --tool-call-parser gemma4` 추가
12. [ ] 샘플링 디폴트를 `temperature=1.0, top_p=0.95, top_k=64`로 정렬
13. [ ] Context를 32K부터 시작 → 필요 시 증가 (무조건 256K 금지)
14. [ ] Audio 워크로드: E2B/E4B 사용 (대형 2종은 audio 미지원)
15. [ ] 라이선스 변경: Gemma Terms → **Apache 2.0** (상업 배포 자유)

---

## 참고

- [Gemma 4 풀 가이드 (한국어)](../../../../reference/google-prompt-guide/gemma-4-prompt-guide.md) — 16섹션 + 외부 노하우 + 솔직한 빈칸
- [Gemma 4 공식 모델 카드](https://ai.google.dev/gemma/docs/core/model_card_4)
- [Prompt formatting 공식](https://ai.google.dev/gemma/docs/core/prompt-formatting-gemma4)
- [Function calling 공식](https://ai.google.dev/gemma/docs/capabilities/text/function-calling-gemma4)
- [HuggingFace 모델 카드 (31B-it)](https://huggingface.co/google/gemma-4-31B-it)
- [HuggingFace Blog — Gemma 4 출시](https://huggingface.co/blog/gemma4)
- [vLLM Gemma 4 Recipe](https://docs.vllm.ai/projects/recipes/en/latest/Google/Gemma4.html)
- [Simon Willison — Gemma 4 출시일 분석](https://simonwillison.net/2026/Apr/2/gemma-4/)
- [Sebastian Raschka — LLM Architecture Comparison](https://magazine.sebastianraschka.com/p/the-big-llm-architecture-comparison)
- [Unsloth Gemma 4 가이드](https://unsloth.ai/docs/models/gemma-4)
