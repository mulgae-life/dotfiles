# OpenAI Responses API 상세 가이드

Responses API는 OpenAI의 최신 API로, Reasoning 모델과 Tool Calling에 최적화되어 있습니다.
Chat Completions API 대비 CoT(Chain of Thought) 유지, 더 나은 성능을 제공합니다.

---

## API 선택

| API | 용도 | 권장 |
|-----|------|------|
| **Responses API** | Reasoning 모델, Tool Calling, Agentic 워크플로우 | ⭐ 권장 |
| Chat Completions API | 레거시, 단순 대화 | 유지보수만 |

---

## 기본 사용법

### 단순 호출

```python
from openai import OpenAI

client = OpenAI()

response = client.responses.create(
    model="gpt-5",
    input="Hello, world!"
)

print(response.output_text)
```

### Instructions 사용

```python
response = client.responses.create(
    model="gpt-5",
    instructions="You are a helpful assistant that speaks Korean formally.",
    input="What is the capital of Korea?"
)
```

---

## Message Roles

### 우선순위

```
developer (최고) > instructions > user
```

### developer role 사용

```python
response = client.responses.create(
    model="gpt-5",
    input=[
        {
            "role": "developer",
            "content": """
            당신은 고객 서비스 에이전트입니다.

            <rules>
            - 반드시 격식체를 사용하세요
            - 정확하지 않은 정보는 제공하지 마세요
            </rules>
            """
        },
        {
            "role": "user",
            "content": "환불 정책이 어떻게 되나요?"
        }
    ]
)
```

### instructions vs developer

| 방식 | 장점 | 단점 |
|------|------|------|
| `instructions` | 간결함 | 매 요청마다 재전송 필요 |
| `developer` role | 대화 이력에 포함 | 더 많은 토큰 사용 |

---

## Reasoning 파라미터

### effort 레벨

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},
    input="복잡한 수학 문제를 풀어주세요..."
)
```

| effort | 설명 | 사용 사례 |
|--------|------|-----------|
| `none` | 추론 없음 | 단순 질문, 빠른 응답 |
| `low` | 최소 추론 | 간단한 작업 |
| `medium` | 균형 (기본값) | 일반적인 작업 |
| `high` | 깊은 추론 | 복잡한 문제 |
| `xhigh` | 최대 추론 | 매우 어려운 문제 |

### Reasoning Summary (GPT-5.2+)

```python
response = client.responses.create(
    model="gpt-5.2",
    reasoning={
        "effort": "high",
        "summary": "auto"  # 또는 "detailed", "concise"
    },
    input="..."
)

# 추론 요약 접근
for item in response.output:
    if item.type == "reasoning":
        print(item.summary)
```

---

## Verbosity (GPT-5.2+)

```python
response = client.responses.create(
    model="gpt-5.2",
    text={"verbosity": "low"},  # low, medium, high
    input="..."
)
```

| verbosity | 용도 |
|-----------|------|
| `low` | 간결한 답변, SQL 쿼리 등 |
| `medium` | 균형 (기본값) |
| `high` | 상세 설명, 코드 리팩토링 |

---

## 대화 이력 관리

### previous_response_id 사용

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
    instructions="격식체 사용",  # 매번 재전송 필요!
    input="이전 내용을 요약해주세요"
)
```

**주의**: `instructions`는 자동으로 유지되지 않음. 매 요청마다 재전송 필요.

### 수동 이력 관리

```python
response = client.responses.create(
    model="gpt-5",
    input=[
        {"role": "developer", "content": "격식체 사용"},
        {"role": "user", "content": "안녕하세요"},
        {"role": "assistant", "content": "안녕하세요. 무엇을 도와드릴까요?"},
        {"role": "user", "content": "이전 내용을 요약해주세요"}
    ]
)
```

---

## Tool Calling (Function Calling)

### 기본 사용법

```python
tools = [
    {
        "type": "function",
        "name": "get_weather",
        "description": "Get the current weather for a location",
        "parameters": {
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

response = client.responses.create(
    model="gpt-5",
    input="서울 날씨 알려줘",
    tools=tools
)

# Tool call 처리
for item in response.output:
    if item.type == "function_call":
        func_name = item.name
        func_args = json.loads(item.arguments)

        # 함수 실행
        result = get_weather(**func_args)

        # 결과 전달
        response2 = client.responses.create(
            model="gpt-5",
            previous_response_id=response.id,
            input=[
                {
                    "type": "function_call_output",
                    "call_id": item.call_id,
                    "output": json.dumps(result)
                }
            ]
        )
```

### Custom Tools (GPT-5.2+)

Freeform 입력 지원:

```python
tools = [
    {
        "type": "custom",
        "name": "code_exec",
        "description": "Executes arbitrary Python code"
    }
]

response = client.responses.create(
    model="gpt-5.2",
    input="Calculate the area of a circle with radius 5",
    tools=tools
)
```

### Allowed Tools

사용 가능한 도구 제한:

```python
response = client.responses.create(
    model="gpt-5.2",
    input="...",
    tools=[...],  # 모든 도구 정의
    tool_choice={
        "type": "allowed_tools",
        "mode": "auto",  # 또는 "required"
        "tools": [
            {"type": "function", "name": "get_weather"}
        ]
    }
)
```

---

## 스트리밍

### 동기 스트리밍

```python
stream = client.responses.create(
    model="gpt-5",
    input="Hello",
    stream=True
)

for event in stream:
    if event.type == "response.output_text.delta":
        print(event.delta, end="", flush=True)
    elif event.type == "response.completed":
        print("\n--- Done ---")
```

### 비동기 스트리밍

```python
async with client.responses.stream(
    model="gpt-5",
    input="Hello"
) as stream:
    async for text in stream.text_stream:
        print(text, end="", flush=True)
```

---

## Incomplete Response 처리

```python
response = client.responses.create(
    model="gpt-5",
    input="...",
    max_output_tokens=1000
)

if response.status == "incomplete":
    reason = response.incomplete_details.reason

    if reason == "max_output_tokens":
        # 토큰 부족
        if response.output_text:
            print("Partial:", response.output_text)
        else:
            print("Reasoning 중 토큰 소진")
    elif reason == "content_filter":
        # 콘텐츠 필터
        print("Content filtered")
```

**권장**: reasoning 모델 사용 시 `max_output_tokens`를 최소 25,000으로 설정.

---

## Usage 정보

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},
    input="..."
)

usage = response.usage
print(f"Input tokens: {usage.input_tokens}")
print(f"Output tokens: {usage.output_tokens}")
print(f"Reasoning tokens: {usage.output_tokens_details.reasoning_tokens}")
print(f"Total: {usage.total_tokens}")
```

---

## GPT-5.2 특화 기능

### Apply Patch Tool

코드 편집을 위한 내장 도구:

```python
response = client.responses.create(
    model="gpt-5.2",
    input="Add error handling to this function...",
    tools=[{"type": "apply_patch"}]
)
```

### Shell Tool

로컬 명령 실행:

```python
response = client.responses.create(
    model="gpt-5.2",
    input="List files in the current directory",
    tools=[{"type": "shell"}]
)
```

### Preambles

도구 호출 전 설명 생성:

```python
response = client.responses.create(
    model="gpt-5.2",
    instructions="Before calling any tool, explain why you are calling it.",
    input="...",
    tools=[...]
)
```

---

## 마이그레이션 가이드

### Chat Completions → Responses API

| Chat Completions | Responses API |
|------------------|---------------|
| `messages` | `input` |
| `system` role | `instructions` 또는 `developer` role |
| `reasoning_effort` | `reasoning: {effort: ...}` |
| `verbosity` | `text: {verbosity: ...}` |

```python
# Chat Completions (레거시)
response = client.chat.completions.create(
    model="gpt-5",
    messages=[
        {"role": "system", "content": "..."},
        {"role": "user", "content": "..."}
    ],
    reasoning_effort="medium"
)

# Responses API (권장)
response = client.responses.create(
    model="gpt-5",
    instructions="...",
    input="...",
    reasoning={"effort": "medium"}
)
```

---

## 참고 자료

- [Responses API Reference](https://platform.openai.com/docs/api-reference/responses)
- [Reasoning Models Guide](https://platform.openai.com/docs/guides/reasoning)
- [GPT-5.2 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5-2_prompting_guide)
- [Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)
