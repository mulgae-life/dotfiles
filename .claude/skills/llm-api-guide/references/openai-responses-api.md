# OpenAI Responses API 상세 가이드

## 목차
- [API 선택](#api-선택)
- [기본 사용법](#기본-사용법)
- [Message Roles](#message-roles)
- [Reasoning 파라미터](#reasoning-파라미터)
- [Verbosity](#verbosity)
- [대화 이력 관리](#대화-이력-관리)
- [Tool Calling (Function Calling)](#tool-calling-function-calling)
- [스트리밍](#스트리밍)
- [Incomplete Response 처리](#incomplete-response-처리)
- [Usage 정보](#usage-정보)
- [내장 도구·에이전트 기능](#내장-도구에이전트-기능)
- [GPT-5.6 특화 기능](#gpt-56-특화-기능)
- [GPT-6 특화·변경 사항 (Astra·Sol·Terra·Luna)](#gpt-6-특화변경-사항-astrasolterraluna)
- [GPT-6.2 특화·변경 사항 (Astra·Sol)](#gpt-62-특화변경-사항-astrasol)
- [마이그레이션 가이드](#마이그레이션-가이드)
- [참고 자료](#참고-자료)


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
    model="gpt-6.2-astra",  # 일상 작업·비용 우선이면 gpt-6.2-sol
    input="Hello, world!"
)

print(response.output_text)
```

### Instructions 사용

```python
response = client.responses.create(
    model="gpt-6.2-astra",
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
    model="gpt-6.2-astra",
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
    model="gpt-6.2-astra",
    reasoning={"effort": "high"},
    input="복잡한 수학 문제를 풀어주세요..."
)
```

| effort | 설명 | 사용 사례 |
|--------|------|-----------|
| `none` | 추론 없음. 5.6·GPT-6.1 Terra·GPT-6 Sol·Luna 지원. GPT-6.2 Astra·6.2 Sol·GPT-6 Astra(HTTP 400)·GPT-6.1 Sol은 미지원 | 단순 질문, 빠른 응답 |
| `low` | 최소 추론 | 간단한 작업 |
| `medium` | 균형 (5.6·GPT-6 기본값. GPT-6.2는 문서에 기본값이 없고 새 통합의 시작점으로 권함) | 일반적인 작업 |
| `high` | 깊은 추론 | 복잡한 문제 |
| `xhigh` | 매우 깊은 추론 (`max` 아래 단계) | 매우 어려운 문제 |
| `max` | 5.6 신설, GPT-6 전 모델에서도 최상위 API 값 (Codex의 `ultra`는 API 값 아님). 전역 기본값 금지 | quality-first 초고난도 |

> 5.6 → GPT-6 Astra·6.1 Sol: `none`/`minimal`은 `low`로. GPT-6.1 Terra·6 Sol·Luna는 `none`을 유지할 수 있고, `minimal`은 `low`부터 비교. GPT-6.2 Astra·6.2 Sol도 `none`/`minimal`은 `low`로 옮기고, 값을 생략하지 말고 명시

### Reasoning Summary

```python
response = client.responses.create(
    model="gpt-6.2-astra",
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

## Verbosity

```python
response = client.responses.create(
    model="gpt-6.2-astra",
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
    model="gpt-6.2-astra",
    instructions="격식체 사용",
    input="안녕하세요"
)

# 후속 요청 - 이전 응답 ID로 대화 연결 (제외 조건에 걸리지 않은 추론 항목은 재사용)
response2 = client.responses.create(
    model="gpt-6.2-astra",
    previous_response_id=response1.id,
    instructions="격식체 사용",  # 매번 재전송 필요!
    input="이전 내용을 요약해주세요"
)
```

**주의**: `instructions`는 자동으로 유지되지 않음. 매 요청마다 재전송 필요.

**GPT-6.2부터**: 앞선 대화 내용을 고치거나 끼워 넣으면 API가 그 뒤의 추론 항목을 입력에서 뺍니다. 중간에 `instructions`·`tools`·`text.format`을 바꾸거나 `safety_identifier`를 바꾸는 것도 여기에 해당합니다. 바꿔야 할 때는 [GPT-6.2 절의 덧붙이기 방식](#추론-항목-제외와-접두사-유지)을 씁니다.

### 수동 이력 관리

```python
response = client.responses.create(
    model="gpt-6.2-astra",
    input=[
        {"role": "developer", "content": "격식체 사용"},
        {"role": "user", "content": "안녕하세요"},
        {"role": "assistant", "content": "안녕하세요. 무엇을 도와드릴까요?"},
        {"role": "user", "content": "이전 내용을 요약해주세요"}
    ]
)
```

위 예시처럼 assistant 텍스트만 옮기면 추론 항목이 빠집니다. 추론을 이어 가야 하는 다중 턴·도구 작업에서는 이전 응답의 `output` 항목을 순서 그대로 덧붙여 보냅니다. 예시는 [GPT-6.2 절](#추론-항목-제외와-접두사-유지)에 있습니다.

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
    model="gpt-6.2-astra",
    input="서울 날씨 알려줘",
    tools=tools
)

# Tool call 처리 — 한 응답에 function_call이 0·1·여러 개 올 수 있으므로
# 결과를 전부 모아 후속 요청 1회로 전달 (호출마다 별도 continuation을 만들면 병렬 호출이 깨짐)
tool_outputs = []
for item in response.output:
    if item.type == "function_call":
        func_args = json.loads(item.arguments)
        result = get_weather(**func_args)
        tool_outputs.append({
            "type": "function_call_output",
            "call_id": item.call_id,
            "output": json.dumps(result)
        })

if tool_outputs:
    response2 = client.responses.create(
        model="gpt-6.2-astra",
        previous_response_id=response.id,   # reasoning item 포함 이전 맥락은 서버가 보존
        input=tool_outputs,
        tools=tools
    )
```

### Custom Tools

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
    model="gpt-6.2-astra",
    input="Calculate the area of a circle with radius 5",
    tools=tools
)
```

### Allowed Tools

사용 가능한 도구 제한:

```python
response = client.responses.create(
    model="gpt-6.2-astra",
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
    model="gpt-6.2-astra",
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
from openai import AsyncOpenAI

client = AsyncOpenAI()

async def stream_response():
    stream = await client.responses.create(
        model="gpt-6.2-astra",
        input="Hello",
        stream=True
    )

    async for event in stream:
        if event.type == "response.output_text.delta":
            print(event.delta, end="", flush=True)
        elif event.type == "response.completed":
            print("\n--- Done ---")
```

---

## Incomplete Response 처리

```python
response = client.responses.create(
    model="gpt-6.2-astra",
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
    model="gpt-6.2-astra",
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

## 내장 도구·에이전트 기능

> GPT-6.2 Astra·6.2 Sol·6 Astra·6.1 Sol·6.1 Terra·6 Sol·Luna 공통 지원 도구(Responses): web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search

### Apply Patch Tool

코드 편집을 위한 내장 도구:

```python
response = client.responses.create(
    model="gpt-6.2-astra",
    input="Add error handling to this function...",
    tools=[{"type": "apply_patch"}]
)
```

### Shell Tool

로컬 명령 실행:

```python
response = client.responses.create(
    model="gpt-6.2-astra",
    input="List files in the current directory",
    tools=[{"type": "shell"}]
)
```

### Preambles

도구 호출 전 설명 생성:

```python
response = client.responses.create(
    model="gpt-6.2-astra",
    instructions="Before calling any tool, explain why you are calling it.",
    input="...",
    tools=[...]
)
```

### Tool Search

대규모 도구 생태계에서 런타임에 필요한 스키마만 로드. `tools`에 `tool_search`를 넣고, 나중에 불러올 함수에 `defer_loading`을 건다:

```python
crm_namespace = {
    "type": "namespace",
    "name": "crm",
    "description": "CRM tools for customer lookup and order management.",
    "tools": [
        {
            "type": "function",
            "name": "list_open_orders",
            "description": "List open orders for a customer ID.",
            "defer_loading": True,  # 검색으로 찾은 뒤에 불러온다
            "parameters": {
                "type": "object",
                "properties": {"customer_id": {"type": "string"}},
                "required": ["customer_id"],
                "additionalProperties": False,
            },
        },
    ],
}

response = client.responses.create(
    model="gpt-6.2-astra",
    input="List open orders for customer CUST-12345.",
    tools=[crm_namespace, {"type": "tool_search"}],
    parallel_tool_calls=False,
)
```

### Computer Use

소프트웨어 인터페이스와 스크린샷/구조화된 액션으로 상호작용:
- `original`: 클릭 정확도, OCR에 사용
- `high`: 표준 고충실도 이해
- 격리된 환경에서 사용, 고영향 액션에는 사람 감독 필요

### Compaction

확장된 에이전트 궤적을 위한 컴팩션 지원:

```python
# 주요 마일스톤 후 컴팩션 수행
# 컴팩트된 아이템은 불투명 상태로 처리
# encrypted_content를 향후 요청에 전달
```

- 긴 멀티턴 대화에서 일관성 유지
- ZDR 호환 엔드포인트

### MCP 통합

Model Context Protocol을 Responses API에서 지원.

---

## GPT-5.6 특화 기능

> 5.6은 Sol/Terra/Luna 3티어: `gpt-5.6-sol`(플래그십, `gpt-5.6` 별칭의 라우팅 대상) / `gpt-5.6-terra`(균형) / `gpt-5.6-luna`(고속저가). 3종 공통 컨텍스트 1.05M / 최대 출력 128K.

### Pro Mode

별도 Pro 모델(5.4 시절) 대신 파라미터로 통합. 표준보다 더 많은 model work — 토큰·지연 증가, 과금은 표준 요율:

```python
response = client.responses.create(
    model="gpt-5.6-sol",
    reasoning={"mode": "pro", "effort": "medium"},
    input="..."
)
```

> 공식 선택 기준: "Use pro mode when a marginal quality improvement materially affects the outcome."

### Reasoning Context (턴 간 추론 보존)

```python
response = client.responses.create(
    model="gpt-5.6-sol",
    reasoning={"context": "all_turns"},  # auto(기본) / current_turn / all_turns
    input=[...]
)
```

- `all_turns`: 이전 턴들의 호환 reasoning 항목을 다음 컨텍스트에 포함 — 목표·가정이 안정적인 장기 워크플로우에서 연속성·캐시 효율 개선. 오래된 추론은 토큰·지연·앵커링을 늘리므로 항상 켜지 않기

### Programmatic Tool Calling

호스티드 JS 런타임이 한 턴 안에서 도구 호출을 오케스트레이션. 도구에 `allowed_callers`로 opt-in, 클라이언트는 `program`/`program_output` 아이템 처리 필요.

### 명시적 프롬프트 캐싱

`prompt_cache_retention` 대체:

```python
response = client.responses.create(
    model="gpt-5.6-sol",
    prompt_cache_options={"mode": "explicit", "ttl": "..."},
    input="..."
)
```

- Responses API의 GPT-5.6 이후 모델은 `prompt_cache_options.ttl`로 기본 `"30m"` 또는 `"12h"`를 선택하며, **캐시 쓰기 총단가는 각각 비캐시 입력 단가의 1.25배·2.5배**입니다. 이는 최소 캐시 보존 기간이며 캐시 읽기 단가는 두 값이 같습니다. → `cached_tokens`/`cache_write_tokens` 추적으로 실익 확인

### safety_identifier

요청마다 안정적인 프라이버시 보존 식별자 전송 — 사용자 단위 오남용 추적. GPT-6.2부터는 한 대화 안에서 이 값이 달라지면(한쪽 요청에만 넣는 경우 포함) 앞 요청의 추론 항목이 입력에서 빠지므로, 대화의 모든 요청에 같은 값을 넣거나 모두 생략합니다.

---

## GPT-6 특화·변경 사항 (Astra·Sol·Terra·Luna)

> GPT-6는 2026-09-03 `gpt-6-astra`로 시작했고, 2026-09-22 `gpt-6-sol`·`gpt-6-luna`가 더해졌습니다(각각 스냅샷 1종). 2026-09-29에는 6 Sol의 후속 `gpt-6.1-sol`이, 2026-10-26에는 5.6 Terra의 후속 `gpt-6.1-terra`가 나왔습니다. 6.2 출시 전까지는 Astra가 최상위였고 6.1 Sol이 Astra에 가까운 성능의 저비용 대안이었습니다. 6.1 Terra는 시각 이해·화면 조작·글쓰기용의 빠르고 효율적인 모델이고, Luna는 범위가 분명한 대량 작업용입니다. 6 Sol은 폐기 공지 없이 남아 있지만 API 계약이 6.1 Sol과 다릅니다. 5.6 Sol/Terra/Luna는 계속 제공됩니다.

| 항목 | Astra | 6.1 Sol | 6.1 Terra | 6 Sol | Luna |
|------|-------|---------|-----------|-------|------|
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000 | 같음(최대 입력 922,000은 공식 문서 도구가 돌려준 명세, 모델 페이지 HTML 사본에서는 미확인) | 같음 | 같음 | 같음 |
| 지식 컷오프 | 2026-04-30 | 2026-04-30 | 2026-06-01 | 2026-04-20 | 2026-05-18 |
| 입력 | 텍스트, 이미지 | 같음 | 같음 | 같음 | 같음 |
| 가격 (1M당, 입력 · 캐시 입력 · 30분 캐시 쓰기 · 출력) | $10 · $1 · $12.50 · $50 | $2 · $0.10 · $2.50 · $10 | $1 · $0.05 · $1.25 · $5 | $2 · $0.20 · $2.50 · $10 | $0.10 · $0.01 · $0.125 · $0.50 |
| `reasoning.effort` | `low`~`max`. `none`은 HTTP 400 | `low`~`max`, 기본 `medium`. `none`·`minimal` 미지원 | `none`~`max`, 기본 `medium` | `none`~`max`, 기본 `medium` | 6 Sol과 같음 |
| 할인·할증 | Batch·Flex 50% · Fast(priority) 2배 · Ultrafast(`service_tier: "ultrafast"`) 6배 | Batch·Flex 50% · Fast 2배 · Ultrafast 6배(2026-10-08 추가) | Batch·Flex 50% · Fast 2배 · Ultrafast 없음 | Batch·Flex 50% · Fast 2배 | 6 Sol과 같음 |

### 롱컨텍스트 요율

> "Prompts with more than 272K input tokens are priced at 2x input and cache rates and 1.5x output for the full request."

다섯 모델 공통입니다. 272K를 넘기면 초과분만이 아니라 **요청 전체**가 할증 요율로 과금됩니다. 긴 프롬프트는 272K 아래로 유지하는 것이 비용상 유리합니다.

### 제거된 파라미터

- `temperature`, `top_p`, `top_logprobs` (Chat Completions에서는 `logprobs`도, Responses에서는 `include`의 `message.output_text.logprobs`도) — 원문 "When reasoning effort is not `none`, remove `temperature`, `top_p`, and `top_logprobs`." Astra·6.1 Sol은 `none`을 받지 않으므로 항상 제거하고, 6.1 Terra·6 Sol·Luna는 effort가 `none`이 아닐 때 제거합니다. `none`에서 이 값들이 허용된다는 명시 문장은 원문에 없습니다
- `reasoning.effort`의 `none` — Astra·6.1 Sol 해당. 원문 "GPT-6 Astra and GPT-6.1 Sol do not support the `none` reasoning effort; GPT-6.1 Terra, GPT-6 Sol, and GPT-6 Luna do."
- `reasoning.effort`의 `minimal` — 다섯 모델 모두 지원 목록에 없음. `low`부터 비교

### 엔드포인트

다섯 모델 모두 Responses, Chat Completions, Batch를 지원합니다. 도구 호출 조건은 모델마다 다릅니다.

> "GPT-6 Astra, GPT-6.1 Sol, and GPT-6.1 Terra support Chat Completions, but tool calling requires Responses. GPT-6 Sol and GPT-6 Luna support function calling in Chat Completions only with `reasoning_effort: "none"`. Use Responses for reasoning with tools."

6.1 Terra는 `none`을 받지만 Chat Completions 함수 호출은 `none`에서도 안 됩니다. 5.6 Terra에서 옮길 때 공식 안내는 "If your application calls tools through Chat Completions, migrate those requests to the Responses API."입니다. 6 Sol에서 6.1 Sol로 옮길 때 모델 ID만 바꾸면 `none` 요청과 Chat Completions 함수 호출이 깨집니다. 공식 안내도 "If you already use gpt-6-sol, review the migration guidance before switching to GPT-6.1 Sol."입니다.

미지원: Realtime, Assistants, 파인튜닝, 임베딩.

### 캐싱 파라미터 변경

GPT-5.5 이하에서 옮길 때는 `prompt_cache_retention`을 `prompt_cache_options.ttl`로 바꿉니다:

```python
response = client.responses.create(
    model="gpt-6-astra",
    prompt_cache_options={"ttl": "30m"},
    input="..."
)
```

### Codex에서의 GPT-6

2026-11-02에 읽은 로컬 서버 카탈로그 캐시에서 기본 창은 Astra·6 Sol·Luna 272K, 6.1 Sol·6.1 Terra 500K이고, 이 모델들의 최대 창은 모두 872K입니다. 이는 API 명세의 1.05M과 다른 카탈로그 값이며 명시적인 설정으로 기본 창을 재정의할 수 있습니다. 6.1 Sol의 500K는 공식 문서에도 명시되어 있지만, Codex 0.166.0 번들 카탈로그에는 272K가 남아 있습니다. 확인한 공식 문서는 6.1 Sol의 구독 사용분에 긴 입력 할증이 없다고 설명하며, 이 설명을 Terra나 Astra로 확대할 근거는 미확인입니다. API 키 사용은 API 요금표의 입력 272K 초과 할증을 따릅니다.

크레딧 소모(입력 / 캐시 입력 / 출력, 1M당)는 Astra 250 / 25 / 1,250으로 5.6 Sol의 2.5배이고, 6.1 Sol은 50 / 2.5 / 250, 6.1 Terra는 25 / 1.25 / 125, 6 Sol은 50 / 5 / 250, Luna는 2.5 / 0.25 / 12.5입니다. 캐시 쓰기는 따로 차감하지 않습니다("Codex credit billing has no separate cache-write charge."). Fast는 구독 포함 사용량에서 2.5배, 구매 크레딧과 엔터프라이즈 종량제에서 2배입니다. Codex 선택기의 effort는 API 값과 별개입니다. Astra·6.1 Sol·6.1 Terra·6 Sol은 `low`~`max`와 `ultra`, Luna는 `max`까지이며 `none`은 없습니다. 6.1 Terra는 Codex CLI 0.159.0 이상이 필요합니다. 0.159.1부터 0.169.0까지 번들 카탈로그의 기본 모델은 계정에서 쓸 수 있다면 6.1 Sol이었고(0.169.1부터는 6.2 Sol), 카탈로그 기본 effort는 `low`입니다.

### 공식 마이그레이션 체크리스트 (5.6 → 6)

1. `model`을 `gpt-6-astra`·`gpt-6.1-sol`·`gpt-6.1-terra`·`gpt-6-luna` 중 하나로 교체 (공식 체크리스트의 선택지에 6 Sol은 없음)
2. effort는 지원 범위에서 현재 값을 유지 — Astra·6.1 Sol은 `none` 대신 `low`, 6.1 Terra·6 Sol·Luna는 `none` 유지 가능. `minimal`은 "start with `low` and compare results on representative tasks."
3. 도구 호출 — Astra·6.1 Sol·6.1 Terra는 Responses API로 이전, 6 Sol·Luna의 Chat Completions 함수 호출은 `reasoning_effort: "none"`일 때만
4. effort가 `none`이 아니면 `temperature`·`top_p`·`top_logprobs` 제거 (Astra·6.1 Sol은 항상)
5. GPT-5.5 이하에서 옮길 때 `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. EU 데이터 레지던시에서 Fast 모드는 6.1 Sol·6.1 Terra·Luna만 가능하고 Astra·6 Sol은 불가. Ultrafast는 6.1 Sol이 미국·EU 레지던시와 글로벌 처리, Astra는 미국 레지던시와 글로벌 처리에서만
7. 응답 사이 effort 변경은 표준 단일 에이전트 요청에서 `configuration_update`로 하고 요청 수준 `reasoning.effort`는 유지
8. 승인 대기로 멈추는 문제는 주도성 가이던스로 대응

---

## GPT-6.2 특화·변경 사항 (Astra·Sol)

> GPT-6.2는 2026-11-17에 `gpt-6.2-astra`와 `gpt-6.2-sol` 두 모델로 나왔습니다(공개된 날짜 스냅샷 ID 없음). 6.2 Terra·Luna는 없어서 그 자리는 6.1 Terra·6 Luna가 계속 맡습니다. 위 GPT-6 절에서 6 Astra·6.1 Sol에 해당하던 계약은 6.2에도 그대로입니다. `none`을 받지 않고, 도구 호출은 Responses에서만 되고, `temperature`·`top_p`·`top_logprobs`를 보내지 않고, 캐시는 `prompt_cache_options.ttl`로 지정하고, 272K를 넘는 요청은 전체가 할증됩니다. 이 절은 달라진 것만 적습니다.

| 항목 | 6.2 Astra | 6.2 Sol |
|------|-----------|---------|
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000 | 같음 |
| 지식 컷오프 | 2026-05-18 | 2026-06-01 |
| 입력 | 텍스트, 이미지 (오디오·비디오 미지원) | 같음 |
| 가격 (1M당, 입력 · 캐시 입력 · 30분 캐시 쓰기 · 12시간 캐시 쓰기 · 출력) | $8 · $0.40 · $10 · $20 · $40 | $2 · $0.10 · $2.50 · $5 · $10 |
| `reasoning.effort` | `none`은 거절("The API rejects requests that set reasoning effort to `none`."). 모델 페이지에 허용값 목록과 기본값이 없음. API 필수는 아니지만 재현성을 위해 값을 명시하고, 새 통합은 `medium`에서 시작 | 같음 |
| 할인·할증 | Batch 50% · Fast 2배 · Ultrafast 3배(2027-02-28까지, 이후 6배) | 같음 |

- Flex 단가는 미확인입니다. 모델 릴리스 노트는 두 모델이 Flex를 지원한다고 적는데, Flex 가이드가 지원 목록으로 가리키는 가격표에는 두 모델이 없습니다. 쓰기 전에 가격표를 다시 확인하고, 이전 세대의 Flex 50%를 그대로 적용하지 않습니다
- 백그라운드 요청(`background: true`)에 `background_options.completion_window`를 `2h`나 `8h`로 주면 모델 토큰 요율이 각각 30%, 40% 낮아집니다(공개 베타). Standard 처리에서만 되고 스트리밍은 쓸 수 없습니다. 대상은 6.2 Astra·6.2 Sol·6.1 Terra·6 Luna입니다. 이 창으로 만든 캐시는 할인 창 밖의 Standard 요청이 다시 쓰지 못합니다. 백그라운드 모드는 `store: false`나 ZDR에서도 응답 데이터를 일시 저장합니다
- 데이터 레지던시는 Standard·Fast·Batch가 미국과 EU를 지원하고, Ultrafast는 미국만 지원합니다
- 하위 에이전트 위임은 Responses API의 [Multi-agent 베타](https://developers.openai.com/api/docs/guides/responses-multi-agent)로 제공됩니다

### 추론 항목 제외와 접두사 유지

6.2부터 API는 대화 중간에 앞선 내용이 바뀐 것을 감지하면 그 뒤의 추론 항목을 요청 입력에서 뺍니다(저장된 응답을 없애는 것은 아닙니다). 추론이 빠지면 모델이 같은 추론을 다시 하느라 토큰과 지연이 늘고 품질이 떨어질 수 있습니다.

> "The API removes reasoning items if you switch model families, downgrade to a less capable model, or switch organizations or users mid-conversation as one of our safeguards against distillation. Starting with 6.2, reasoning items with a `safety_identifier` change or a modified conversation history (the prefix) will also be removed."

| 제외 사유 (`input_transformations`) | 조건 |
|-------------------------------------|------|
| `prefix_mismatch` (6.2 신규) | 추론 항목 앞의 내용을 끼워 넣거나 고침. 예: 앞선 도구 결과를 줄여 다시 씀. 항목을 통째로 지우거나 뒤에 덧붙이는 것만으로는 해당하지 않음 |
| `end_user_mismatch` (6.2 신규) | 항목을 만든 요청과 다시 쓰는 요청의 `safety_identifier`가 다름. 한쪽에만 넣은 경우 포함 |
| `model_mismatch` | 모델 계열을 바꾸거나 같은 계열의 낮은 모델로 내림. 같은 계열의 높은 모델로 올리면 다른 검사를 통과한 호환 추론 항목은 유지 |
| `organization_mismatch` | 다른 조직의 항목, 또는 다른 사용자의 다른 워크스페이스에서 만든 항목을 다시 씀 |
| `turn_boundary` | 이전 턴의 항목인데 모델이 현재 턴의 추론만 씀. 지원 모델에서는 `reasoning.context`가 이전 턴 항목을 쓸지 정함 |

`instructions`·`tools`·`text.format` 같은 요청 파라미터를 바꾸는 것도 접두사 변경입니다. 설정을 바꿔야 할 때는 고치지 말고 덧붙입니다.

| 바꾸려는 것 | 덧붙이는 방법 |
|-------------|---------------|
| 추론 수준, 출력 스키마 | 요청 수준 값은 그대로 두고 `configuration_update` 항목을 다음 사용자 메시지 앞에 덧붙임 (표준 단일 에이전트 요청에서만) |
| 도구 목록 | `tools`는 그대로 두고 `additional_tools` 항목으로 추가, 제한은 `tool_choice`의 `allowed_tools`로 |
| 개발자 지시 | 원래 메시지를 고치지 않고 새 `developer` 메시지를 덧붙임 |
| 긴 도구 결과·파일·이미지 | 지난 항목을 나중에 줄이지 말고 처음 보낼 때 줄여서 보냄 |
| 컨텍스트 압축 | OpenAI 압축(`/responses/compact`, `context_management`)은 접두사가 바뀌어도 뒤의 추론 항목을 유지함. 자체 요약 방식은 요약 항목을 최근 턴 앞이 아니라 컨텍스트 끝에 두거나, 그 뒤 추론 항목이 지워지는 것을 감수함 |

`configuration_update`가 든 이력은 독립 압축 엔드포인트 `/responses/compact`와 자동 잘라내기가 거부합니다. 자동 압축(`context_management`)은 최신 설정을 이어받습니다. 독립 압축을 쓰려면 [압축 가이드](https://developers.openai.com/api/docs/guides/compaction#continue-with-configuration-updates-and-tools)대로 갱신 항목을 빼고 압축한 뒤 설정과 도구를 다시 붙입니다.

서버에 응답을 저장하지 않는 구성(`store: false`나 ZDR)의 HTTP 요청에서는 응답의 `output` 항목을 암호화된 추론 항목까지 순서 그대로 다음 입력에 덧붙입니다. 응답을 저장하지 않는 구성에서도 WebSocket 모드는 같은 연결의 메모리에 남은 이전 응답을 `previous_response_id`로 이어 갑니다. 보낸 ID가 연결 메모리에 없으면 `previous_response_not_found`가 돌아오므로 `previous_response_id` 없이 전체 입력을 다시 보냅니다.

```python
from hashlib import sha256

user_hash = sha256(b"user-42").hexdigest()  # 최종 사용자를 가리키는 해시 예시
history = [{"role": "user", "content": "다음 함수에서 오류를 찾아주세요.\ndef add(a, b): return a - b"}]

first = client.responses.create(
    model="gpt-6.2-sol",
    store=False,
    reasoning={"effort": "medium"},
    safety_identifier=user_hash,
    input=history,
)

# 추론 항목을 포함한 출력 전체를 고치지 않고 덧붙인다
history.extend(item.to_dict() for item in first.output)
history.append({"role": "user", "content": "고친 함수를 적어주세요."})

second = client.responses.create(
    model="gpt-6.2-sol",
    store=False,
    reasoning={"effort": "medium"},
    safety_identifier=user_hash,   # 앞 요청과 같은 값
    input=history,
)
```

추론 항목이 빠졌는지는 응답의 `input_transformations`로 확인합니다. 캐시가 어디서 끊겼는지는 `prompt_cache_options.comparison_response_id`에 이전 응답 ID를 넣어 진단하지만, 이 진단은 모델이 이전 추론 항목을 재사용했는지까지는 알려 주지 않습니다.

### 공식 마이그레이션 체크리스트 (6 → 6.2)

1. `model`을 `gpt-6.2-astra`나 `gpt-6.2-sol`로 교체
2. effort — 새 통합은 `medium`에서 시작, `none`·`minimal`을 쓰던 곳은 `low`
3. 도구 호출은 Responses API로 ("GPT-6.2 Astra and GPT-6.2 Sol support Chat Completions, but tool calling requires Responses.")
4. Chat Completions 요청에서는 `temperature`·`top_p`·`logprobs`·`top_logprobs`를, Responses 요청에서는 `temperature`·`top_p`·`top_logprobs`를 빼고 `include`의 `message.output_text.logprobs`를 제거
5. GPT-5.5 이하에서 옮길 때 `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. 대화 중간에 요청 파라미터나 앞선 입력을 고치는 코드를 찾아 덧붙이기 방식으로 바꾸고, `safety_identifier`를 대화 전체에서 같게 유지 (공식 마이그레이션 절 밖, 같은 가이드의 접두사 절에서 가져온 항목)
7. ZDR에서는 `store`가 `false`로 처리되므로 다중 턴 작업에서 이전 출력 항목을 암호화된 추론 항목까지 순서대로 돌려보냄
8. EU 데이터 레지던시에서는 Ultrafast를 쓸 수 없음 (Standard·Fast·Batch는 가능)

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
    model="gpt-6.2-astra",
    messages=[
        {"role": "system", "content": "..."},
        {"role": "user", "content": "..."}
    ],
    reasoning_effort="medium"
)

# Responses API (권장)
response = client.responses.create(
    model="gpt-6.2-astra",
    instructions="...",
    input="...",
    reasoning={"effort": "medium"}
)
```

---

## 참고 자료

- [Responses API Reference](https://platform.openai.com/docs/api-reference/responses)
- [Reasoning Models Guide](https://platform.openai.com/docs/guides/reasoning)
- [Using GPT-6.2 (공식)](https://developers.openai.com/api/docs/guides/latest-model/gpt-6.2-astra) ⭐ 최신 — 6.2 Astra·6.2 Sol, 마이그레이션 · [Keep the prefix unchanged (공식)](https://developers.openai.com/api/docs/guides/keep-prefix-unchanged) — 접두사 변경을 덧붙이기로 바꾸는 방법
- [GPT-6.2 풀 정리 (한국어)](../../../../reference/openai-prompt-guide/gpt-6.2-prompt-guide.md) — API 계약, 추론 항목 제외와 접두사 유지, Codex 적용
- [Using GPT-6 (공식, 6·6.1 전용 원문)](https://developers.openai.com/api/docs/guides/latest-model/gpt-6-astra) — Astra·6.1 Sol·6.1 Terra·6 Sol·Luna 제품군, 마이그레이션
- [GPT-6 풀 정리 (한국어)](../../../../reference/openai-prompt-guide/gpt-6-prompt-guide.md) — 제품군 API 계약 차이, effort 표, Codex 적용
- [Using GPT-5.6 (공식)](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6) (2026-07)
- [GPT-5.6 풀 정리 (한국어)](../../../../reference/openai-api-guide/openai_api_latest_model_gpt5.6.md) — 3티어 스펙·가격·마이그레이션
- [Function Calling Guide](https://platform.openai.com/docs/guides/function-calling)
