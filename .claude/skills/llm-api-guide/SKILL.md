---
name: llm-api-guide
description: LLM API(OpenAI, Anthropic) 연동 코드 구현 가이드. Responses API, Message Roles, 클라이언트 초기화, 에러 핸들링, 스트리밍 처리. "OpenAI API 연동해줘", "Claude API 사용해줘", "LLM 호출 코드 작성해줘" 등의 요청에 트리거.
---

# LLM API 개발 가이드

LLM API(OpenAI, Anthropic) 연동 **코드** 구현 가이드.
프롬프트 **내용** 작성은 `writing-prompts` 스킬 참조.

---

## Quick Start

### 역할 분리

| 스킬 | 역할 | 주요 질문 |
|------|------|-----------|
| `llm-api-guide` | API **코드** 구현 | "어떤 API 사용?", "파라미터는?" |
| `writing-prompts` | 프롬프트 **내용** 작성 | "어떤 톤?", "구조는?" |

### API 선택 가이드

```
OpenAI
├── Responses API (권장) ← Reasoning 모델, Tool Calling, CoT 유지
└── Chat Completions API ← 레거시, 단순 대화

Anthropic
└── Messages API ← 유일한 선택
```

---

## TL;DR

| 항목 | OpenAI (Responses API) | Anthropic (Messages API) |
|------|------------------------|--------------------------|
| **엔드포인트** | `/v1/responses` | `/v1/messages` |
| **Instructions** | `instructions` 파라미터 또는 `developer` role | `system` 파라미터 |
| **입력** | `input` (문자열 또는 메시지 배열) | `messages` 배열 |
| **Reasoning** | `reasoning: {effort: "medium"}` | 모델 자체 기능 (extended thinking) |
| **스트리밍** | `stream: true` | `stream: True` |
| **대화 유지** | `previous_response_id` | 직접 메시지 이력 관리 |

---

## 1. 클라이언트 초기화

### 핵심 원칙

```python
# ❌ 잘못된 패턴: 요청마다 생성
async def handler(request):
    client = OpenAI()  # 매 요청마다 새 인스턴스
    response = client.responses.create(...)

# ✅ 올바른 패턴: 앱 수명주기로 관리
client = OpenAI()  # 모듈 레벨 또는 앱 시작 시 1회

async def handler(request):
    response = client.responses.create(...)
```

### OpenAI

```python
from openai import OpenAI

# 환경변수 OPENAI_API_KEY 자동 사용
client = OpenAI()

# 또는 명시적 설정
client = OpenAI(
    api_key=os.environ["OPENAI_API_KEY"],
    timeout=60.0,
    max_retries=3
)
```

### Anthropic

```python
from anthropic import Anthropic

# 환경변수 ANTHROPIC_API_KEY 자동 사용
client = Anthropic()

# 또는 명시적 설정
client = Anthropic(
    api_key=os.environ["ANTHROPIC_API_KEY"],
    timeout=60.0,
    max_retries=3
)
```

---

## 2. Message Roles

### OpenAI (Responses API)

| Role | 용도 | 우선순위 |
|------|------|----------|
| `developer` | 시스템 규칙, 비즈니스 로직 | ⭐⭐⭐ 최고 |
| `user` | 사용자 입력 | ⭐⭐ |
| `assistant` | 모델 응답 | - |

**방법 1: instructions 파라미터 (권장)**

```python
response = client.responses.create(
    model="gpt-5",
    instructions="반드시 격식체를 사용하세요.",
    input="안녕하세요"
)
```

**방법 2: developer role (대화 이력 관리)**

```python
response = client.responses.create(
    model="gpt-5",
    input=[
        {"role": "developer", "content": "반드시 격식체를 사용하세요."},
        {"role": "user", "content": "안녕하세요"}
    ]
)
```

### Anthropic (Messages API)

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    system="반드시 격식체를 사용하세요.",
    messages=[
        {"role": "user", "content": "안녕하세요"}
    ],
    max_tokens=1024
)
```

→ 상세: [openai-responses-api.md](references/openai-responses-api.md), [anthropic-messages-api.md](references/anthropic-messages-api.md)

---

## 3. Reasoning 파라미터

### OpenAI GPT-5

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "medium"},  # none, low, medium, high, xhigh
    input="복잡한 수학 문제..."
)

# GPT-5.2 추가 옵션
response = client.responses.create(
    model="gpt-5.2",
    reasoning={"effort": "high", "summary": "auto"},  # 추론 요약
    text={"verbosity": "low"},  # 응답 길이
    input="..."
)
```

| effort | 용도 |
|--------|------|
| `none` | 빠른 응답, 단순 질문 (GPT-5.2 기본값) |
| `low` | 기본적인 추론 |
| `medium` | 균형 (GPT-5 기본값) |
| `high` | 복잡한 문제 |
| `xhigh` | 최대 추론 (GPT-5.2+) |

### Anthropic Claude

Claude는 `reasoning` 파라미터 대신 extended thinking 기능 사용:

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    thinking={
        "type": "enabled",
        "budget_tokens": 10000
    },
    messages=[...],
    max_tokens=16000
)
```

---

## 4. 스트리밍

### OpenAI

```python
# 동기
stream = client.responses.create(
    model="gpt-5",
    input="Hello",
    stream=True
)

for event in stream:
    if event.type == "response.output_text.delta":
        print(event.delta, end="", flush=True)

# 비동기
async with client.responses.stream(
    model="gpt-5",
    input="Hello"
) as stream:
    async for text in stream.text_stream:
        print(text, end="", flush=True)
```

### Anthropic

```python
# 동기
with client.messages.stream(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)

# 비동기
async with client.messages.stream(...) as stream:
    async for text in stream.text_stream:
        print(text, end="", flush=True)
```

→ 상세: [common-patterns.md](references/common-patterns.md)

---

## 5. 에러 핸들링

### 공통 패턴

```python
from openai import APIError, RateLimitError, APIConnectionError

try:
    response = client.responses.create(...)
except RateLimitError as e:
    # 재시도 로직 또는 백오프
    logger.warning(f"Rate limited: {e}")
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

### Incomplete Response 처리 (OpenAI)

```python
response = client.responses.create(
    model="gpt-5",
    input="...",
    max_output_tokens=1000
)

if response.status == "incomplete":
    if response.incomplete_details.reason == "max_output_tokens":
        # 토큰 부족 - 증가 필요
        logger.warning("Token limit reached")
```

→ 상세: [common-patterns.md](references/common-patterns.md)

---

## 6. 대화 이력 관리

### OpenAI (previous_response_id)

```python
# 첫 요청
response1 = client.responses.create(
    model="gpt-5",
    instructions="격식체 사용",
    input="안녕하세요"
)

# 후속 요청 - CoT 자동 유지
response2 = client.responses.create(
    model="gpt-5",
    previous_response_id=response1.id,
    instructions="격식체 사용",  # 매번 다시 전달 필요
    input="계속 이야기해주세요"
)
```

### Anthropic (수동 이력 관리)

```python
messages = []

# 첫 요청
messages.append({"role": "user", "content": "안녕하세요"})
response1 = client.messages.create(
    model="claude-sonnet-4-5",
    system="격식체 사용",
    messages=messages,
    max_tokens=1024
)
messages.append({"role": "assistant", "content": response1.content[0].text})

# 후속 요청
messages.append({"role": "user", "content": "계속 이야기해주세요"})
response2 = client.messages.create(
    model="claude-sonnet-4-5",
    system="격식체 사용",
    messages=messages,
    max_tokens=1024
)
```

---

## 7. Tool Calling (Function Calling)

### OpenAI

```python
tools = [
    {
        "type": "function",
        "name": "get_weather",
        "description": "Get current weather",
        "parameters": {
            "type": "object",
            "properties": {
                "location": {"type": "string"}
            },
            "required": ["location"]
        }
    }
]

response = client.responses.create(
    model="gpt-5",
    input="서울 날씨 알려줘",
    tools=tools
)

# Tool call 확인
for item in response.output:
    if item.type == "function_call":
        # 함수 실행 후 결과 전달
        ...
```

### Anthropic

```python
tools = [
    {
        "name": "get_weather",
        "description": "Get current weather",
        "input_schema": {
            "type": "object",
            "properties": {
                "location": {"type": "string"}
            },
            "required": ["location"]
        }
    }
]

response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "서울 날씨 알려줘"}],
    tools=tools,
    max_tokens=1024
)

# Tool use 확인
for block in response.content:
    if block.type == "tool_use":
        # 함수 실행 후 결과 전달
        ...
```

→ 상세: [openai-responses-api.md](references/openai-responses-api.md), [anthropic-messages-api.md](references/anthropic-messages-api.md)

---

## 체크리스트

### 필수

- [ ] 클라이언트 초기화: 앱 수명주기로 관리 (요청마다 생성 금지)
- [ ] API 키: 환경변수 사용 (하드코딩 금지)
- [ ] 에러 핸들링: RateLimitError, APIError 처리
- [ ] 타임아웃 설정

### 권장

- [ ] 스트리밍: 긴 응답은 스트리밍 사용
- [ ] Reasoning effort: 작업 복잡도에 맞게 설정
- [ ] 대화 이력: `previous_response_id` (OpenAI) 또는 수동 관리 (Anthropic)

### 프롬프트 작성

- [ ] 프롬프트 내용 작성은 `writing-prompts` 스킬 참조

---

## 상세 가이드

- **[openai-responses-api.md](references/openai-responses-api.md)** - OpenAI Responses API 상세
- **[anthropic-messages-api.md](references/anthropic-messages-api.md)** - Anthropic Messages API 상세
- **[common-patterns.md](references/common-patterns.md)** - 공통 패턴 (초기화, 에러, 스트리밍, SSE)

---

## 참고 자료

### OpenAI

- [Responses API Reference](https://platform.openai.com/docs/api-reference/responses)
- [Reasoning Models Guide](https://platform.openai.com/docs/guides/reasoning)
- [Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)

### Anthropic

- [Messages API Reference](https://docs.anthropic.com/en/api/messages)
- [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)
- [Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
