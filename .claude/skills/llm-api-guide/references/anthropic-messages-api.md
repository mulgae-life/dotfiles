# Anthropic Messages API 상세 가이드

Anthropic의 유일한 API로, Claude 모델과 상호작용합니다.

---

## 기본 사용법

### 단순 호출

```python
from anthropic import Anthropic

client = Anthropic()

response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "Hello, world!"}
    ],
    max_tokens=1024
)

print(response.content[0].text)
```

### System Prompt 사용

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
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

## Extended Thinking

Claude의 추론 기능 (OpenAI의 reasoning과 유사):

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    thinking={
        "type": "enabled",
        "budget_tokens": 10000  # 추론에 할당할 토큰 수
    },
    messages=[
        {"role": "user", "content": "복잡한 수학 문제..."}
    ],
    max_tokens=16000  # thinking + output 합계
)

# thinking 결과 접근
for block in response.content:
    if block.type == "thinking":
        print("Thinking:", block.thinking)
    elif block.type == "text":
        print("Output:", block.text)
```

### budget_tokens 가이드

| 작업 복잡도 | 권장 budget_tokens |
|-------------|-------------------|
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
    model="claude-sonnet-4-5",
    system="격식체로 응답하세요",
    messages=messages,
    max_tokens=1024
)
messages.append({"role": "assistant", "content": response1.content[0].text})

# 후속 요청
messages.append({"role": "user", "content": "이전 대화를 요약해주세요"})
response2 = client.messages.create(
    model="claude-sonnet-4-5",
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

        assistant_message = response.content[0].text
        self.messages.append({"role": "assistant", "content": assistant_message})

        return assistant_message

# 사용
conv = ConversationManager(client, "claude-sonnet-4-5", "격식체로 응답하세요")
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
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "서울 날씨 알려줘"}],
    tools=tools,
    max_tokens=1024
)

# Tool use 처리
for block in response.content:
    if block.type == "tool_use":
        tool_name = block.name
        tool_input = block.input
        tool_use_id = block.id

        # 함수 실행
        result = get_weather(**tool_input)

        # 결과 전달
        response2 = client.messages.create(
            model="claude-sonnet-4-5",
            messages=[
                {"role": "user", "content": "서울 날씨 알려줘"},
                {"role": "assistant", "content": response.content},
                {
                    "role": "user",
                    "content": [
                        {
                            "type": "tool_result",
                            "tool_use_id": tool_use_id,
                            "content": json.dumps(result)
                        }
                    ]
                }
            ],
            tools=tools,
            max_tokens=1024
        )
```

### Tool Choice

```python
# 특정 도구 강제
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "tool", "name": "get_weather"},
    max_tokens=1024
)

# 도구 사용 필수
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "any"},  # 아무 도구나 사용해야 함
    max_tokens=1024
)

# 자동 (기본값)
response = client.messages.create(
    model="claude-sonnet-4-5",
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
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024
) as stream:
    for text in stream.text_stream:
        print(text, end="", flush=True)
```

### 비동기 스트리밍

```python
async with client.messages.stream(
    model="claude-sonnet-4-5",
    messages=[{"role": "user", "content": "Hello"}],
    max_tokens=1024
) as stream:
    async for text in stream.text_stream:
        print(text, end="", flush=True)
```

### 이벤트 기반 스트리밍

```python
with client.messages.stream(
    model="claude-sonnet-4-5",
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

### JSON 출력 강제

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
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
    model="claude-sonnet-4-5",
    system="You are a pirate. Always speak like a pirate.",
    messages=[
        {"role": "user", "content": "Hello!"},
        {"role": "assistant", "content": "Arrr,"}  # 해적 말투 시작
    ],
    max_tokens=1024
)
```

### 주의사항

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
    model="claude-sonnet-4-5",
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
    model="claude-sonnet-4-5",
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

| 모델 | 용도 |
|------|------|
| `claude-opus-4-5` | 가장 지능적, 복잡한 작업 |
| `claude-sonnet-4-5` | 균형 (권장) |
| `claude-haiku-4` | 빠르고 저렴, 단순 작업 |

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

- [Messages API Reference](https://docs.anthropic.com/en/api/messages)
- [Extended Thinking Guide](https://docs.anthropic.com/en/docs/build-with-claude/extended-thinking)
- [Tool Use Guide](https://docs.anthropic.com/en/docs/build-with-claude/tool-use)
- [Vision Guide](https://docs.anthropic.com/en/docs/build-with-claude/vision)
