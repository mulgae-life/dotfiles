# Anthropic Messages API 상세 가이드

## 목차
- [기본 사용법](#기본-사용법)
- [Message 구조](#message-구조)
- [Thinking (추론 제어)](#thinking-추론-제어)
- [대화 이력 관리](#대화-이력-관리)
- [Tool Use (Function Calling)](#tool-use-function-calling)
- [스트리밍](#스트리밍)
- [Prefilling](#prefilling)
- [Vision (이미지 분석)](#vision-이미지-분석)
- [에러 핸들링](#에러-핸들링)
- [모델 선택](#모델-선택)
- [Fable 5 주의사항](#fable-5-주의사항)
- [Usage 정보](#usage-정보)
- [참고 자료](#참고-자료)


Anthropic의 유일한 API로, Claude 모델과 상호작용합니다.

---

## 기본 사용법

### 단순 호출

```python
from anthropic import Anthropic

client = Anthropic()

response = client.messages.create(
    model="claude-sonnet-5",
    messages=[
        {"role": "user", "content": "Hello, world!"}
    ],
    max_tokens=1024
)

# text 블록만 추출 — content[0]을 직접 읽지 않기: thinking이 켜진 모델
# (Sonnet 5는 기본 on, Fable 5는 상시 on)은 첫 블록이 thinking입니다
print("".join(b.text for b in response.content if b.type == "text"))
```

### System Prompt 사용

```python
response = client.messages.create(
    model="claude-sonnet-5",
    system="You are a helpful assistant that speaks Korean formally.",
    messages=[
        {"role": "user", "content": "What is the capital of Korea?"}
    ],
    max_tokens=1024
)
```

---

## Message 구조

### 역할

| Role | 용도 |
|------|------|
| `user` | 사용자 입력 |
| `assistant` | 모델 응답 (대화 이력용) |

**참고**: OpenAI의 `developer` role에 해당하는 것은 `system` 파라미터.

### 메시지 형식

```python
messages = [
    {
        "role": "user",
        "content": "텍스트 또는 content blocks"
    }
]

# 또는 content blocks 사용
messages = [
    {
        "role": "user",
        "content": [
            {"type": "text", "text": "이 이미지를 분석해주세요"},
            {"type": "image", "source": {"type": "base64", "media_type": "image/png", "data": "..."}}
        ]
    }
]
```

---

## Thinking (추론 제어)

Claude의 추론 기능 (OpenAI의 reasoning과 유사). **모델 세대에 따라 설정 방법이 다릅니다.**

### 현행 모델 (4.6+, Sonnet 5, Fable 5): Adaptive Thinking

```python
response = client.messages.create(
    model="claude-sonnet-5",
    thinking={"type": "adaptive"},          # Claude가 사고 시점·깊이를 스스로 결정
    output_config={"effort": "high"},       # low | medium | high | xhigh | max
    messages=[
        {"role": "user", "content": "복잡한 수학 문제..."}
    ],
    max_tokens=16000
)

# thinking 결과 접근
for block in response.content:
    if block.type == "thinking":
        print("Thinking:", block.thinking)
    elif block.type == "text":
        print("Output:", block.text)
```

- 추론 깊이는 `budget_tokens`가 아니라 **`output_config.effort`** 로 제어
- **Fable 5**: thinking이 항상 켜져 있음 — `thinking` 파라미터를 **생략** (`disabled`·`budget_tokens` 모두 400). thinking 텍스트가 필요하면 `thinking={"type": "adaptive", "display": "summarized"}` (기본 `"omitted"`은 빈 문자열)
- **Opus 4.7+/Sonnet 5**: `budget_tokens`는 400 에러

### effort 가이드

| effort | 용도 |
|--------|------|
| `low` / `medium` | 루틴·저지연 작업, 서브에이전트 |
| `high` | 기본값 — 대부분 작업의 균형점 |
| `xhigh` | 코딩·에이전트 고난도 작업 |
| `max` | 비용보다 정확성이 중요할 때 |

### 구모델 (Sonnet 4.5 이하): Extended Thinking + budget_tokens

```python
response = client.messages.create(
    model="claude-sonnet-4-5",              # 구모델 전용 — 4.7+에서는 400
    thinking={
        "type": "enabled",
        "budget_tokens": 10000              # 추론에 할당할 토큰 수 (< max_tokens, 최소 1024)
    },
    messages=[{"role": "user", "content": "복잡한 수학 문제..."}],
    max_tokens=16000                        # thinking + output 합계
)
```

| 작업 복잡도 | 권장 budget_tokens (구모델) |
|-------------|---------------------------|
| 간단한 질문 | 5,000 ~ 10,000 |
| 복잡한 문제 | 10,000 ~ 50,000 |
| 매우 어려운 문제 | 50,000+ |

---

## 대화 이력 관리

Anthropic은 `previous_response_id`가 없으므로 수동으로 관리:

```python
messages = []

# 첫 요청
messages.append({"role": "user", "content": "안녕하세요"})
response1 = client.messages.create(
    model="claude-sonnet-5",
    system="격식체로 응답하세요",
    messages=messages,
    max_tokens=1024
)
messages.append({"role": "assistant", "content": response1.content})  # 블록 전체 보존 (thinking 포함)

# 후속 요청
messages.append({"role": "user", "content": "이전 대화를 요약해주세요"})
response2 = client.messages.create(
    model="claude-sonnet-5",
    system="격식체로 응답하세요",  # 매번 재전송
    messages=messages,
    max_tokens=1024
)
```

### 대화 이력 클래스

```python
class ConversationManager:
    def __init__(self, client: Anthropic, model: str, system: str):
        self.client = client
        self.model = model
        self.system = system
        self.messages = []

    def send(self, user_message: str) -> str:
        self.messages.append({"role": "user", "content": user_message})

        response = self.client.messages.create(
            model=self.model,
            system=self.system,
            messages=self.messages,
            max_tokens=1024
        )

        self.messages.append({"role": "assistant", "content": response.content})
        return "".join(b.text for b in response.content if b.type == "text")

# 사용
conv = ConversationManager(client, "claude-sonnet-5", "격식체로 응답하세요")
print(conv.send("안녕하세요"))
print(conv.send("이전 대화를 요약해주세요"))
```

---

## Tool Use (Function Calling)

### 도구 정의

```python
tools = [
    {
        "name": "get_weather",
        "description": "Get the current weather for a location",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {
                    "type": "string",
                    "description": "City name"
                },
                "unit": {
                    "type": "string",
                    "enum": ["celsius", "fahrenheit"],
                    "description": "Temperature unit"
                }
            },
            "required": ["location"]
        }
    }
]
```

### 기본 사용

```python
response = client.messages.create(
    model="claude-sonnet-5",
    messages=[{"role": "user", "content": "서울 날씨 알려줘"}],
    tools=tools,
    max_tokens=1024
)

# Tool use 처리
# 한 assistant 턴에 tool_use 블록이 여러 개일 수 있다(병렬 도구 호출).
# Anthropic 계약: 모든 tool_use의 결과(tool_result)를 '하나의 user 메시지'에 모아
# 후속 호출을 1회만 한다. 블록마다 호출을 나누면 결과 누락으로 400이 난다.
tool_results = []
for block in response.content:
    if block.type == "tool_use":
        # 도구가 여러 개면 block.name으로 분기
        result = get_weather(**block.input)
        tool_results.append({
            "type": "tool_result",
            "tool_use_id": block.id,
            "content": json.dumps(result)
        })

# 모든 tool_result를 하나의 user 메시지로 묶어 후속 호출 1회
response2 = client.messages.create(
    model="claude-sonnet-5",
    messages=[
        {"role": "user", "content": "서울 날씨 알려줘"},
        {"role": "assistant", "content": response.content},
        {"role": "user", "content": tool_results}
    ],
    tools=tools,
    max_tokens=1024
)
```

### Tool Choice

```python
# 특정 도구 강제
response = client.messages.create(
    model="claude-sonnet-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "tool", "name": "get_weather"},
    max_tokens=1024
)

# 도구 사용 필수
response = client.messages.create(
    model="claude-sonnet-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "any"},  # 아무 도구나 사용해야 함
    max_tokens=1024
)

# 자동 (기본값)
response = client.messages.create(
    model="claude-sonnet-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "auto"},
    max_tokens=1024
)
```

---

## 스트리밍

### 동기 스트리밍

```python
with client.messages.stream(
    model="claude-sonnet-5",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

### 비동기 스트리밍

```python
from anthropic import AsyncAnthropic

client = AsyncAnthropic()

async def stream_response():
    async with client.messages.stream(
        model="claude-sonnet-5",
        messages=[{"role": "user", "content": "Hello"}],
        max_tokens=1024
    ) as stream:
        async for text in stream.text_stream:
            print(text, end="", flush=True)
```

### 이벤트 기반 스트리밍

```python
with client.messages.stream(
    model="claude-sonnet-5",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024
) as stream:
    for event in stream:
        if event.type == "content_block_delta":
            if event.delta.type == "text_delta":
                print(event.delta.text, end="", flush=True)
        elif event.type == "message_stop":
            print("\n--- Done ---")
```

---

## Prefilling

Assistant 응답을 미리 채워 출력 형식을 강제:

> ⚠️ **Claude 4.5 이하 전용.** Fable 5·Opus 4.6/4.7/4.8·Sonnet 4.6/5에서는 마지막 assistant 턴 prefill이 **400 에러**입니다. 최신 모델에서는 Structured Outputs(`output_config.format`)를 사용하세요. 아래 예시가 `claude-sonnet-4-5`인 이유입니다.

### JSON 출력 강제

```python
response = client.messages.create(
    model="claude-sonnet-4-5",  # prefill은 구모델 전용
    messages=[
        {"role": "user", "content": "Extract name and age from: John is 30 years old."},
        {"role": "assistant", "content": "{"}  # JSON 시작 강제
    ],
    max_tokens=1024
)

# 결과: {"name": "John", "age": 30}
```

### 캐릭터 강제

```python
response = client.messages.create(
    model="claude-sonnet-4-5",  # prefill은 구모델 전용
    system="You are a pirate. Always speak like a pirate.",
    messages=[
        {"role": "user", "content": "Hello!"},
        {"role": "assistant", "content": "Arrr,"}  # 해적 말투 시작
    ],
    max_tokens=1024
)
```

### 주의사항

- **Fable 5·4.6+ 계열에서는 400 에러** — Structured Outputs로 대체
- Prefilling은 stop reason을 `end_turn`에서 `stop_sequence`로 변경할 수 있음
- Extended thinking과 함께 사용 시 제한이 있을 수 있음

---

## Vision (이미지 분석)

### Base64 이미지

```python
import base64

with open("image.png", "rb") as f:
    image_data = base64.standard_b64encode(f.read()).decode("utf-8")

response = client.messages.create(
    model="claude-sonnet-5",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "이 이미지를 설명해주세요"},
                {
                    "type": "image",
                    "source": {
                        "type": "base64",
                        "media_type": "image/png",
                        "data": image_data
                    }
                }
            ]
        }
    ],
    max_tokens=1024
)
```

### URL 이미지

```python
response = client.messages.create(
    model="claude-sonnet-5",
    messages=[
        {
            "role": "user",
            "content": [
                {"type": "text", "text": "이 이미지를 설명해주세요"},
                {
                    "type": "image",
                    "source": {
                        "type": "url",
                        "url": "https://example.com/image.png"
                    }
                }
            ]
        }
    ],
    max_tokens=1024
)
```

---

## 에러 핸들링

```python
from anthropic import (
    APIError,
    RateLimitError,
    APIConnectionError,
    AuthenticationError
)

try:
    response = client.messages.create(...)
except RateLimitError as e:
    # 재시도 로직
    logger.warning(f"Rate limited: {e}")
    raise
except AuthenticationError as e:
    # API 키 문제
    logger.error(f"Auth failed: {e}")
    raise
except APIConnectionError as e:
    # 네트워크 문제
    logger.error(f"Connection failed: {e}")
    raise
except APIError as e:
    # 기타 API 에러
    logger.error(f"API error: {e.status_code} - {e.message}")
    raise
```

---

## 모델 선택

| 모델 | 가격 (입력/출력, MTok) | 용도 |
|------|----------------------|------|
| `claude-fable-5` | $10 / $50 | 최상위 — 최고 난도 추론·장기 자율 작업 ([주의사항](#fable-5-주의사항) 필독) |
| `claude-opus-4-8` | $5 / $25 | 고지능, 복잡한 작업 |
| `claude-sonnet-5` | $3 / $15 | 균형 (권장 기본값) |
| `claude-haiku-4-5` | $1 / $5 | 빠르고 저렴, 단순 작업 |

> 구모델(`claude-opus-4-5`, `claude-sonnet-4-5` 등)도 여전히 서비스 중이지만, 신규 코드는 위 표 기준. prefill·`budget_tokens` 등 구모델 전용 기법이 필요한 경우에만 구모델 지정.

---

## Fable 5 주의사항

`claude-fable-5`는 API 동작이 Opus 계열과 다릅니다. 3가지를 반드시 처리하세요.

### 1. thinking 파라미터 생략 (항상 켜짐)

```python
# ❌ 400 에러
thinking={"type": "disabled"}
thinking={"type": "enabled", "budget_tokens": 10000}

# ✅ 생략(기본 adaptive) 또는 명시적 adaptive + effort로 깊이 제어
response = client.messages.create(
    model="claude-fable-5",
    output_config={"effort": "high"},
    messages=[...],
    max_tokens=16000
)
```

`temperature`/`top_p`/`top_k`도 400 — 프롬프트로 제어합니다.

### 2. refusal 처리 + fallback 구성

Safety classifier가 요청을 거절할 수 있습니다(HTTP 200 + `stop_reason: "refusal"`). `response.content[0]`를 무조건 읽는 코드는 깨집니다. `fallbacks` 파라미터로 Opus 4.8 자동 재시도를 기본 구성하세요:

```python
response = client.beta.messages.create(
    model="claude-fable-5",
    max_tokens=16000,
    betas=["server-side-fallback-2026-06-01"],
    fallbacks=[{"model": "claude-opus-4-8"}],   # 거절 시 같은 호출 내 자동 재시도
    messages=[...],
)

if response.stop_reason == "refusal":
    handle_refusal()          # 체인 전체가 거절한 경우
else:
    print("".join(b.text for b in response.content if b.type == "text"))
```

### 3. 데이터 보존 요건

30일 데이터 보존 필수 — ZDR(zero data retention) 조직은 **모든 요청이 400**. 요청 본문에 문제가 없는데 400이 나면 조직의 보존 설정부터 확인.

### 기타

- 마지막 assistant 턴 prefill 400 (4.6+ 공통)
- raw chain of thought는 절대 반환 안 됨 — `display: "summarized"`로 요약만 수신
- 프롬프트 작성 요령은 writing-prompts 스킬의 `claude-5-specifics.md` 참조

---

## Usage 정보

```python
response = client.messages.create(...)

usage = response.usage
print(f"Input tokens: {usage.input_tokens}")
print(f"Output tokens: {usage.output_tokens}")
```

---

## 참고 자료

- [Messages API Reference](https://platform.claude.com/docs/en/api/messages)
- [Adaptive Thinking Guide](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)
- [Effort Parameter](https://platform.claude.com/docs/en/build-with-claude/effort)
- [Introducing Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5)
- [Refusals and Fallback](https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback)
- [Tool Use Guide](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview)
- [Vision Guide](https://platform.claude.com/docs/en/build-with-claude/vision)
