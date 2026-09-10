# Anthropic Messages API 상세 가이드

## 목차
- [기본 사용법](#기본-사용법)
- [Message 구조](#message-구조)
- [Thinking (추론 제어)](#thinking-추론-제어)
- [대화 이력 관리](#대화-이력-관리)
- [Tool Use (Function Calling)](#tool-use-function-calling)
- [스트리밍](#스트리밍)
- [Vision (이미지 분석)](#vision-이미지-분석)
- [에러 핸들링](#에러-핸들링)
- [모델 선택](#모델-선택)
- [Fable 5.1 주의사항](#fable-51-주의사항)
- [Opus 5 주의사항](#opus-5-주의사항)
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
    model="claude-opus-5",
    messages=[
        {"role": "user", "content": "Hello, world!"}
    ],
    max_tokens=1024
)

# text 블록만 추출 — content[0]을 직접 읽지 않기: thinking이 켜진 모델
# (Sonnet 5는 기본 on, Fable 5·5.1은 상시 on)은 첫 블록이 thinking입니다
print("".join(b.text for b in response.content if b.type == "text"))
```

### System Prompt 사용

```python
response = client.messages.create(
    model="claude-opus-5",
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

### 현행 모델 (Fable 5·5.1, Opus 5, Sonnet 5): Adaptive Thinking

```python
response = client.messages.create(
    model="claude-opus-5",
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
- **Fable 5·5.1**: thinking이 항상 켜져 있음 — `thinking` 파라미터를 **생략** (`enabled`·`disabled`·`budget_tokens` 모두 400). thinking 텍스트가 필요하면 `thinking={"type": "adaptive", "display": "summarized"}` (기본 `"omitted"`은 빈 문자열). Fable 5.1은 `disabled`가 **어떤 effort에서도** 400이므로, Opus 5에서 옮겨올 때 이 필드를 제거하고 effort를 낮춰 토큰을 제어합니다
- **Opus 5**: thinking **기본 켜짐** — 생략 시 adaptive로 실행 (사고 없이 실행되던 Opus 4.8과 다름, `max_tokens`는 사고+응답 합산 리밋이라 재검토 필요). `disabled`는 effort `high` 이하에서만 허용 — `xhigh`/`max` 조합은 400
- **Opus 5·Sonnet 5**: `budget_tokens`는 400 에러

### effort 가이드

| effort | 용도 |
|--------|------|
| `low` / `medium` | 루틴·저지연 작업, 서브에이전트 |
| `high` | 기본값 — 대부분 작업의 균형점 |
| `xhigh` | 코딩·에이전트 고난도 작업 |
| `max` | 비용보다 정확성이 중요할 때 |

> **Opus 5는 `high`에서 시작**해 `low`/`medium`을 비용·지연 제어의 1차 수단으로 적극 활용합니다. 다른 모델에서 가져온 effort 설정은 재사용하지 말고 스윕을 다시 돌립니다.
>
> **Fable 5.1도 `high`에서 시작하되 전 레벨을 다시 측정합니다.** effort 이름이 모델 간 같은 사고량을 뜻하지 않기 때문이며, 5.1의 `medium`이 Fable 5 성능에 근접합니다. 시스템 카드의 FrontierCode 평가에서는 `medium`이 정점이고 `high` 이상은 요청 범위 밖 파일까지 고치면서 점수가 떨어졌습니다. `xhigh`/`max`는 긴 산출물을 사고 안에서 먼저 초안 작성해 지연·토큰이 늘어나므로, 측정된 이득이 있을 때만 씁니다.

---

## 대화 이력 관리

Anthropic은 `previous_response_id`가 없으므로 수동으로 관리:

```python
messages = []

# 첫 요청
messages.append({"role": "user", "content": "안녕하세요"})
response1 = client.messages.create(
    model="claude-opus-5",
    system="격식체로 응답하세요",
    messages=messages,
    max_tokens=1024
)
messages.append({"role": "assistant", "content": response1.content})  # 블록 전체 보존 (thinking 포함)

# 후속 요청
messages.append({"role": "user", "content": "이전 대화를 요약해주세요"})
response2 = client.messages.create(
    model="claude-opus-5",
    system="격식체로 응답하세요",  # 매번 재전송
    messages=messages,
    max_tokens=1024
)
```

### 대화 이력 클래스

이력은 **append-only**로 다룹니다. Fable 5.1은 사고 블록 앞의 `system`·`tools`·이전 메시지가 바뀌면 다음 요청을 400으로 거절합니다([주의사항](#fable-51-주의사항) 3번).

```python
class ConversationManager:
    def __init__(self, client: Anthropic, model: str, system: str):
        self.client = client
        self.model = model
        # system·tools는 세션 시작 시 동결 — 중간에 바꾸면 사고 블록 바인딩이 깨집니다
        self.system = system
        self.messages = []

    def send(self, user_message: str) -> str:
        # 기존 메시지는 수정·삭제하지 않고 추가만 합니다.
        # 턴별 리마인더가 필요하면 이력을 고치지 말고, user 턴 뒤에
        # 턴 한정 시스템 메시지({"role": "system", "clear_at": "next_user_message", ...},
        # beta 헤더 mid-conversation-system-clear-at-2026-08-21)를 덧붙입니다.
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
conv = ConversationManager(client, "claude-opus-5", "격식체로 응답하세요")
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
    model="claude-opus-5",
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
    model="claude-opus-5",
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

> ⚠️ **강제 `tool_choice`(`any`·`tool`)는 Fable 5.1·Mythos 5.1에서 400 `invalid_request_error`입니다.** Messages·Batches·토큰 카운트 엔드포인트 모두 해당합니다. 대안은 `auto` + 프롬프트에 쓸 도구를 명시 + 도구 정의에 `strict: true`이고, 스키마 준수 JSON만 필요하면 JSON outputs(`output_config.format`)를 씁니다. CMEK 조직은 structured outputs를 못 쓰므로 지시문만 사용합니다. 특정 턴에만 도구 호출이 필수라면 최신 user 턴 뒤에 턴 한정 시스템 메시지로 요구하세요. `{"type": "none"}`은 5.1에서도 유효합니다.

```python
# 특정 도구 강제 — Fable 5.1·Mythos 5.1은 400, 구모델 전용
response = client.messages.create(
    model="claude-opus-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "tool", "name": "get_weather"},
    max_tokens=1024
)

# 도구 사용 필수 — Fable 5.1·Mythos 5.1은 400, 구모델 전용
response = client.messages.create(
    model="claude-opus-5",
    messages=[...],
    tools=tools,
    tool_choice={"type": "any"},  # 아무 도구나 사용해야 함
    max_tokens=1024
)

# 자동 (기본값) — 최신 모델에서 도구 사용을 유도하는 유일한 방법
response = client.messages.create(
    model="claude-fable-5-1",
    system="날씨를 물으면 get_weather 도구를 호출해 답하세요.",  # 쓸 도구를 지시문에 명시
    messages=[...],
    tools=tools,                            # 각 도구 정의에 "strict": True를 넣어 스키마 준수 강제
    tool_choice={"type": "auto"},
    max_tokens=1024
)

# 도구 사용 금지 — 5.1에서도 유효
response = client.messages.create(
    model="claude-fable-5-1",
    messages=[...],
    tools=tools,
    tool_choice={"type": "none"},
    max_tokens=1024
)
```

---

## 스트리밍

### 동기 스트리밍

```python
with client.messages.stream(
    model="claude-opus-5",
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
        model="claude-opus-5",
        messages=[{"role": "user", "content": "Hello"}],
        max_tokens=1024
    ) as stream:
        async for text in stream.text_stream:
            print(text, end="", flush=True)
```

### 이벤트 기반 스트리밍

```python
with client.messages.stream(
    model="claude-opus-5",
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

## Vision (이미지 분석)

### Base64 이미지

```python
import base64

with open("image.png", "rb") as f:
    image_data = base64.standard_b64encode(f.read()).decode("utf-8")

response = client.messages.create(
    model="claude-opus-5",
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
    model="claude-opus-5",
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
| `claude-fable-5-1` | $10 / $50 | 최상위 — 최고 난도 추론·장기 자율 작업. 캐시 읽기 $0.25, 컨텍스트 1M / 출력 128K, 컷오프 2026-06, 은퇴 하한 2027-09-01 ([주의사항](#fable-51-주의사항) 필독) |
| `claude-fable-5` | $10 / $50 | 레거시 — 5.1로 대체됨. 캐시 읽기는 $1로 4배 |
| `claude-opus-5` | $5 / $25 | 기본 선택 — 에이전틱 코딩·엔터프라이즈. Fable 5 근접 지능을 절반 가격에 ([주의사항](#opus-5-주의사항) 참조) |
| `claude-sonnet-5` | $2 / $10 | 균형 — 도입가였으나 정가로 확정 (2026-08 확인, $3/$15 인상 미시행) |
| `claude-haiku-4-5` | $1 / $5 | 빠르고 저렴, 단순 작업 |

> 신규 코드는 위 표 기준. Opus 5는 Opus 4.x와 **별도 레이트리밋 버킷**을 씁니다.

---

## Fable 5.1 주의사항

`claude-fable-5-1`은 API 동작이 Opus 계열과 다르고, Fable 5에서 옮겨올 때 깨지는 지점도 있습니다. 아래를 반드시 처리하세요.

### 1. thinking 파라미터 생략 (항상 켜짐)

```python
# ❌ 400 에러
thinking={"type": "disabled"}
thinking={"type": "enabled", "budget_tokens": 10000}

# ✅ 생략(기본 adaptive) 또는 명시적 adaptive + effort로 깊이 제어
response = client.messages.create(
    model="claude-fable-5-1",
    output_config={"effort": "high"},
    messages=[...],
    max_tokens=16000
)
```

`temperature`/`top_p`/`top_k`도 400 — 프롬프트로 제어합니다.

### 2. 강제 tool_choice 400 (Fable 5 → 5.1 파괴적 변경)

`tool_choice={"type": "any"}`와 `{"type": "tool", "name": ...}`은 400 `invalid_request_error`입니다. `auto` + 지시문 + `strict: true` 또는 JSON outputs(`output_config.format`)로 대체하세요. 자세한 내용은 [Tool Choice](#tool-choice) 절에 있습니다.

### 3. 사고 블록 바인딩 (Fable 5 → 5.1 파괴적 변경)

- **하위 호환 없음**: 사고 블록은 그것을 생성한 모델 또는 그 이후 모델만 읽습니다. 5.1은 Opus 5·Fable 5·Mythos 5와 그 이전 모델의 블록을 읽지만, 구모델에 5.1 블록을 넘기는 역방향은 안 됩니다. 못 읽는 블록은 API가 조용히 드롭하고 과금하지 않습니다.
- **이력 편집 금지**: 사고 블록 앞의 `system`·`tools`·이전 메시지를 바꾸면 다음 요청이 400 `The block is bound to a different conversation`입니다. 2026-08-31 이후 생성된 계정은 기본으로 강제되고, 그 이전 계정은 `thinking.block_binding.prefix_mismatch_behavior`를 설정했을 때만 적용됩니다.
- 허용되는 조작은 선두 사고 블록 연속 제거, 서버측 compaction·context editing, `cache_control` 이동, effort 변경입니다.
- 실무 요건은 [대화 이력 관리](#대화-이력-관리)의 append-only 원칙입니다. 사고 블록은 받은 그대로(빈 블록 포함) 되돌려 보내세요.

### 4. refusal 처리 + fallback 구성

Safety classifier가 요청을 거절할 수 있습니다(HTTP 200 + `stop_reason: "refusal"`). `response.content[0]`를 무조건 읽는 코드는 깨집니다. `fallbacks="default"`로 거절 카테고리별 권장 모델 자동 재실행을 구성하세요. 폴백 대상은 **Opus 4.8과 Opus 5**입니다.

```python
response = client.beta.messages.create(
    model="claude-fable-5-1",
    max_tokens=16000,
    betas=["server-side-fallback-2026-07-01"],
    fallbacks="default",       # 거절 시 같은 호출 내 자동 재시도 (Opus 5)
    messages=[...],
)

if response.stop_reason == "refusal":
    handle_refusal()          # 체인 전체가 거절한 경우
else:
    print("".join(b.text for b in response.content if b.type == "text"))
```

출력 전 거부는 과금되지 않고, 폴백 크레딧이 캐시 전환 비용을 환불합니다.

### 5. 데이터 보존 요건

30일 데이터 보존 필수 — ZDR(zero data retention) 조직은 **모든 요청이 400**. 요청 본문에 문제가 없는데 400이 나면 조직의 보존 설정부터 확인.

### 6. 미지원 기능

- **Priority Tier 미지원** (Fable 5는 지원)
- **Fast mode 미지원** — Opus 5 전용
- **300K 출력 배치 베타 미지원** — `output-300k-2026-03-24` 헤더의 지원 모델 목록에 없음

### 7. 신규 베타

| 기능 | 베타 헤더 | 용도 |
|------|----------|------|
| 메시지별 effort | `mid-conversation-output-config-2026-07-01` | `messages` 안 `role: "system"` 항목에 `output_config: {effort}`만 실어 보내면 다음 user 턴부터 적용. 프롬프트 캐시 유지 |
| 턴 한정 시스템 메시지 | `mid-conversation-system-clear-at-2026-08-21` | `role: "system"` + `clear_at: "next_user_message"`. 다음 user 메시지가 생기면 렌더링을 멈추되 배열에는 남겨 그대로 재전송 — 토큰 비용 0, 캐시·사고 블록 유지. 이력을 고치지 않고 턴별 리마인더를 주는 공식 수단 |
| 진행 업데이트 수신 | `thinking-display-updates-2026-08-18` | `thinking={"display": "updates"}` — 추론은 숨기고 도구 호출 직전 진행 업데이트만 텍스트로 받음 |

### 기타

- 마지막 assistant 턴 prefill 400
- raw chain of thought는 절대 반환 안 됨 — `display: "summarized"`로 요약만 수신
- 프롬프트 캐시 최소 512 토큰, 캐시 읽기 $0.25/MTok (기본 입력의 0.025배)
- 도구 호출 사이의 사용자 대상 텍스트는 Opus 5에서 `text` 블록이었으나 5.1은 진행 업데이트 `thinking` 블록으로 옵니다. 기본값 `omitted`이면 빈 블록입니다
- 프롬프트 작성 요령은 [Fable 5.1 풀 가이드](../../../../reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md) 참조

---

## Opus 5 주의사항

`claude-opus-5`(2026-07 GA)는 Opus 4.8의 요청 형태를 대부분 유지하지만, 다음을 확인하세요.

### 1. thinking 기본값 변경 (파괴적)

`thinking` 생략 시 Opus 4.8은 사고 없이 실행됐지만 **Opus 5는 adaptive thinking으로 실행**됩니다. `max_tokens`는 사고+응답 합산 하드 리밋이므로, 사고 없이 돌던 워크로드는 응답이 잘릴 수 있어 재검토가 필요합니다. `thinking: {"type": "disabled"}`는 effort `high` 이하에서만 허용되고 `xhigh`/`max` 조합은 400입니다(요청 단위 검증). 공식 권고는 끄는 대신 thinking을 켠 채 effort를 낮추는 것 — 끄면 도구 호출이 평문으로 유출되거나 `<thinking>` 태그가 새는 결함이 있습니다.

### 2. refusal 처리 + 기본 폴백

사이버보안 분류기가 탑재되어 거절 시 HTTP 200 + `stop_reason: "refusal"`이 반환됩니다. `fallbacks: "default"`(beta `server-side-fallback-2026-07-01`)를 쓰면 거절 카테고리별 권장 폴백 모델로 자동 재실행됩니다 — 모델 목록을 직접 유지하는 구형 배열(`server-side-fallback-2026-06-01`)보다 권장:

```python
response = client.beta.messages.create(
    model="claude-opus-5",
    max_tokens=16000,
    betas=["server-side-fallback-2026-07-01"],
    fallbacks="default",
    messages=[...],
)
```

### 3. 미지원 기능

- **web fetch 도구 미지원** — 사용 중이면 대안 필요 (web search는 지원)
- **Priority Tier 미지원**

### 기타

- 프롬프트 캐시 최소 512 토큰 (4.8은 1,024) — 짧은 프롬프트도 캐시 가능해짐
- 대화 중 도구 변경: beta `mid-conversation-tool-changes-2026-07-01` (`tool_addition`/`tool_removal` 블록 + `defer_loading`, 캐시 보존)
- 프롬프팅 요령(검증 지시 삭제, 위임 상한, 장황함 대응)은 [Opus 5 풀 가이드](../../../../reference/claude-prompt-guide/claude-opus-5-prompt-guide.md) 참조

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
- [What's new in Claude Fable 5.1](https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1)
- [Fable 5.1 Migration Guide](https://platform.claude.com/docs/en/models/fable-5-1/migration-guide)
- [Introducing Claude Fable 5](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5)
- [What's new in Claude Opus 5](https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5)
- [Refusals and Fallback](https://platform.claude.com/docs/en/build-with-claude/refusals-and-fallback)
- [Tool Use Guide](https://platform.claude.com/docs/en/agents-and-tools/tool-use/overview)
- [Vision Guide](https://platform.claude.com/docs/en/build-with-claude/vision)
