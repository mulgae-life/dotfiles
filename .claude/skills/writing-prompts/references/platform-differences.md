# 플랫폼별 차이점 비교

OpenAI GPT, Anthropic Claude, Google Gemini의 프롬프트 엔지니어링 주요 차이점입니다. 오픈웨이트(Gemma 4·Qwen 3.8)는 각 패턴 문서를 봅니다. 어느 모델 문서를 적용할지는 [SKILL.md의 대상 모델 확정](../SKILL.md#대상-모델-확정)을 먼저 따릅니다. 아래 표는 플랫폼 경향이고, 같은 플랫폼 안에서도 모델마다 계약이 다릅니다.

## 빠른 비교표

| 항목 | OpenAI (GPT-5.x / 6) | Anthropic (Claude) | Google (Gemini 3.x) | 공통 |
|------|----------------|-------------------|------|------|
| **Message Roles** | `developer` (최고 우선순위)<br/>`user`, `assistant` | `system` 파라미터<br/>`user`, `assistant` | `system_instruction`<br/>`user`, `model` | 사용자 입력과 지시 분리 |
| **파라미터** | `reasoning_effort`<br/>`verbosity` | `output_config.effort` (Haiku 4.5는 `budget_tokens`) | `thinking_level` (sampling 제거) | - |
| **Prefilling** | ❌ 없음 | ❌ 4.6 이후 400 → Structured Outputs (Haiku 4.5만 사고를 끈 요청에서 허용) | ❌ 새 프롬프트에서 쓰지 않음 (제거 권고는 3.8·Cloud 3.7 문서) | 형식 강제는 구조화 출력 |
| **Long Context** | 일반적 사용 | ✅ 최대 1M (Haiku 4.5는 200K)<br/>(문서 맨 위 배치 → 30%↑) | 입력 1,048,576 / 출력 65,536 (사고 포함)<br/>긴 자료 앞, 질문 끝 | - |
| **CoT** | "Think step-by-step" (GPT 추론 모델은 추가 추론 유도 문구 생략) | thinking이 켜져 있으면 일반 지시 우선<br/>끈 경우 3단계 (Basic/Guided/Structured) | 추론 단계를 답에 쓰게 할 필요는 대체로 없음, `thinking_level`로 조절 | ⚠️ 모델·설정별 분기 |
| **Examples** | Few-shot. 행동을 바꾸지 않는 예시는 줄임(5.6) | Multishot. 공식 모범 사례는 다양한 예시 3~5개 | 공식 문서는 예시 포함 권장. 수는 과제별 평가 | 개수는 대상 모델 문서와 과제별 평가로 |
| **XML Tags** | ✅ 권장 | ✅ 권장 | 구조 표기(XML 또는 Markdown) 하나로 일관 | 구분자 일관성 |
| **Extended Thinking** | 같은 이름의 기능 없음. 추론 모델은 추론 강도 파라미터로 조절 → 6절 | Claude 5 세대는 기본 켜짐(Opus 5.5·Fable은 끌 수 없음, Sonnet 5.5는 `between_tools`까지), Opus 4.8·Sonnet 4.6은 기본 꺼짐, Haiku 4.5는 확장 사고만 | 끌 수 없음. `minimal`도 끄기가 아님 | - |

## 상세 비교

### 1. Message Roles (시스템 지침)

#### OpenAI
```python
# developer role (최고 우선순위)
response = client.responses.create(
    model="gpt-6-astra",
    input=[
        {"role": "developer", "content": "반드시 격식체 사용"},
        {"role": "user", "content": "안녕하세요"}
    ]
)

# 또는 instructions 파라미터
response = client.responses.create(
    model="gpt-6-astra",
    instructions="반드시 격식체 사용",
    input="안녕하세요"
)
```

#### Anthropic
```python
# system 파라미터
response = client.messages.create(
    model="claude-opus-5-5",
    system="반드시 격식체 사용",  # system prompt
    messages=[
        {"role": "user", "content": "안녕하세요"}
    ],
    max_tokens=1024  # 필수 인자
)
```

#### Google Gemini
```python
# Interactions API (최신 공식 예제의 기본)
interaction = client.interactions.create(
    model="gemini-3.8-flash",
    system_instruction="반드시 격식체 사용",
    input="안녕하세요"
)
```

**차이점**:
- OpenAI: `developer` role이 `user`보다 높은 우선순위
- Anthropic: `system` 파라미터로 역할 설정
- Gemini: `system_instruction`. GenerateContent는 SDK 설정 `system_instruction`, REST `systemInstruction` → [gemini3-patterns.md](gemini3-patterns.md)

### 2. Prefilling (응답 사전 채우기)

새 프롬프트에서는 세 플랫폼 모두 쓰지 않습니다. Claude는 4.6 세대부터 마지막 assistant 턴 prefill이 **400 에러**입니다. JSON/XML 형식 강제는 Structured Outputs(`output_config.format`), 프리앰블 생략·캐릭터 유지는 시스템 프롬프트 지시로 처리합니다 → [claude-5-specifics.md](claude-5-specifics.md). 예외는 Haiku 4.5로, 사고를 끈 요청에서만 prefill을 받습니다 → [claude-4-specifics.md](claude-4-specifics.md). Gemini는 3.8 마이그레이션 체크리스트가 미리 채운 model 턴을 지우라고 요구합니다 → [gemini3-patterns.md](gemini3-patterns.md).

### 3. Long Context 최적화

#### OpenAI
- 특별한 가이드 없음

#### Anthropic ⭐
- **긴 문서는 맨 위에 배치** → 성능 30% 향상
- `<document>`, `<document_content>`, `<source>` 태그 구조화
- 인용 기반 grounding (답변 전에 인용 먼저 추출)

```python
# Anthropic 권장 구조
prompt = """
<documents>
  <document index="1">
    <source>report_2024.pdf</source>
    <document_content>
      {{LONG_DOCUMENT}}
    </document_content>
  </document>
</documents>

위 문서에서 핵심 내용을 요약하세요.
"""
```

### 4. Chain of Thought

#### OpenAI
```yaml
# 간단한 지시 (비추론 모델 기준)
# GPT 추론 모델에는 추론 유도용으로 덧붙이는 아래 문구가 불필요. 결과의 근거 설명 요청은 별개 → reasoning-params.md
- "Think step-by-step"
- "Explain your reasoning"
```

#### Anthropic
thinking을 끈 경우의 수동 CoT 대안입니다. Opus 5는 낮은 effort로 thinking을 켜 두기를 우선합니다. 3단계 구분:
```yaml
# Basic
- "Think step-by-step"

# Guided
- "먼저 A를 고려하고, 그 다음 B를 분석한 후, 최종 답변"

# Structured (권장)
<thinking>
[추론 과정]
</thinking>

<answer>
[최종 답변]
</answer>
```

**공통점**: 출력 방식은 모델과 thinking 설정에 따라 다르며, 결과의 근거 설명과 내부 추론 재현을 구분합니다

### 5. Extended Thinking

#### OpenAI
- 같은 이름의 기능은 없습니다. GPT 추론 모델의 내장 추론은 추론 강도 파라미터로 조절합니다 → 아래 6절

#### Anthropic (Claude 5 세대) ⭐
```python
# adaptive thinking 상시 — effort로만 깊이 제어
response = client.messages.create(
    model="claude-fable-5-1",
    max_tokens=16000,
    output_config={"effort": "high"},  # low, medium, high, xhigh, max
    messages=[...]
)
```

**특징**:
- Fable 5.1·Opus 5.5는 thinking이 상시 adaptive로 켜져 있어 `thinking` 파라미터를 보낼 필요가 없습니다 (Opus 5는 effort `high` 이하에서 `disabled`로 끌 수 있음)
- 깊이는 `output_config.effort` 한 축으로만 제어 → [claude-5-specifics.md](claude-5-specifics.md)
- Fable 5.1·Opus 5.5에서 `thinking: {type: "enabled", budget_tokens: N}`과 `thinking: {type: "disabled"}`는 **400 에러**입니다. Opus 5의 `disabled` 예외는 첫 항목을 따릅니다
- Sonnet 5는 `disabled`를 받고, Sonnet 5.5의 가장 낮은 설정은 응답 전 사고만 끄는 `between_tools`(effort `high` 이하)입니다 → [claude-5-specifics.md](claude-5-specifics.md#sonnet-55--sonnet-5-차이점)

#### Anthropic (Claude 4.x)
- Opus 4.8·Sonnet 4.6은 `thinking`을 생략하면 사고 없이 실행됩니다. 켜려면 `{"type": "adaptive"}`
- Haiku 4.5는 확장 사고(`{"type": "enabled", "budget_tokens": N}`)만 받고 effort를 지원하지 않습니다 → [claude-4-specifics.md](claude-4-specifics.md)

#### Google Gemini 3.x
```python
interaction = client.interactions.create(
    model="gemini-3.8-flash",
    input="...",
    generation_config={"thinking_level": "low"}  # 모델이 받는 값만
)
```
- 사고는 끌 수 없고 `minimal`도 끄기가 아닙니다. 허용 값과 기본값은 모델마다 다릅니다(3.8·3.7 Flash는 `low`·`medium`·`high`, 3.6 Flash·Flash-Lite는 `minimal` 포함)
- `max_output_tokens`에 사고 토큰이 포함됩니다
- 사고 서명·블록은 받은 그대로 이력에 유지합니다 → [gemini3-patterns.md](gemini3-patterns.md)

### 6. GPT-5.x / 6 특화 파라미터

#### OpenAI ⭐
```python
response = client.responses.create(
    model="gpt-6-astra",
    reasoning={"effort": "high"},  # 추론 깊이
    text={"verbosity": "low"},     # 응답 길이
    instructions="...",
    input="..."
)
```

**파라미터**:
- `reasoning_effort`: 추론 깊이 — GPT-5.x·GPT-6 Sol·Luna: none/low/medium/high/xhigh/max · GPT-6 Astra·6.1 Sol: low~max(`none` 미지원)
- `verbosity`: low/medium/high (응답 길이)

Responses API는 `reasoning.effort`·`text.verbosity`, Chat Completions API는 `reasoning_effort`·`verbosity`를 사용합니다 (위 예제는 Responses API).

#### Anthropic
- `output_config.effort` (`low`~`max`)로 추론 깊이 제어 → [claude-5-specifics.md](claude-5-specifics.md). 지원 레벨은 모델마다 다름(Sonnet 4.6은 `xhigh` 없음, Haiku 4.5는 effort 미지원 → [claude-4-specifics.md](claude-4-specifics.md))
- 응답 길이는 프롬프트로 제어:
  ```
  "간결하게 답변하세요" (verbosity low 대신)
  ```

#### Google Gemini
- `thinking_level`로 사고량 조절, `temperature`·`top_p`·`top_k`는 새 요청에서 제거
- OpenAI 라이브러리로 호출해도(`base_url`이 Google 호환 계층) 적용할 가이드는 Gemini입니다. `reasoning_effort`와 `thinking_level`은 한 요청에 함께 쓰지 않습니다 → [gemini3-patterns.md](gemini3-patterns.md)

## 플랫폼 선택 가이드

### OpenAI GPT-5.x / 6을 선택하는 경우
- `reasoning_effort`, `verbosity` 파라미터로 세밀한 제어 필요
- `developer` role로 강력한 시스템 규칙 우선순위 필요
- OpenAI 생태계 (Assistants API, GPTs 등) 통합

### Anthropic Claude를 선택하는 경우
- Long context 활용 (1M, 출력 128K — 문서 맨 위 배치로 30% 성능 향상)
- adaptive thinking으로 복잡한 추론 작업

### 공통 사용 가능
- 구조화 표기 (XML 태그 등, 하나로 일관)
- Few-shot/Multishot (개수는 대상 모델 문서와 과제별 평가로)
- Chain of Thought
- 명확한 지시와 제약
- 모순 제거

## 실전 적용

### 프로젝트 판단 기준

패키지 이름은 공급자 판단 근거가 아닙니다. `openai` 라이브러리로 Gemini를 호출할 수 있고(`base_url`이 Google 호환 계층), 같은 SDK 안에서도 모델마다 계약이 다릅니다. 실제 호출 경로의 모델 ID와 API 방식을 확인하는 절차는 [SKILL.md의 대상 모델 확정](../SKILL.md#대상-모델-확정)을 따릅니다.

### 통합 템플릿 예시

OpenAI 버전:
```python
response = client.responses.create(
    model="gpt-6-astra",
    reasoning={"effort": "high"},
    text={"verbosity": "low"},
    instructions="""
    당신은 데이터 분석가입니다.

    <rules>
    - 반드시 격식체 사용
    - 데이터 기반 답변
    </rules>

    <examples>
    <example id="1">
    <input>매출 추이는?</input>
    <output>Q1 대비 Q2 매출이 15% 증가했습니다.</output>
    </example>
    </examples>
    """,
    input="최근 분기 실적은?"
)
```

Anthropic 버전:
```python
response = client.messages.create(
    model="claude-opus-5-5",
    system="""
    당신은 데이터 분석가입니다.

    <rules>
    - 반드시 격식체 사용
    - 데이터 기반 답변
    </rules>

    <examples>
    <example id="1">
    <input>매출 추이는?</input>
    <output>Q1 대비 Q2 매출이 15% 증가했습니다.</output>
    </example>
    </examples>
    """,
    messages=[
        {"role": "user", "content": "최근 분기 실적은?"}
    ],
    max_tokens=1024
)
```

Gemini 버전:
```python
interaction = client.interactions.create(
    model="gemini-3.8-flash",
    system_instruction="""
    당신은 데이터 분석가입니다.

    <rules>
    - 반드시 격식체 사용
    - 데이터 기반 답변
    </rules>

    <examples>
    <example id="1">
    <input>매출 추이는?</input>
    <output>Q1 대비 Q2 매출이 15% 증가했습니다.</output>
    </example>
    </examples>
    """,
    input="최근 분기 실적은?",
    generation_config={"thinking_level": "low"}
)
```

## 요약

| 선택 기준 | OpenAI | Anthropic | Google Gemini |
|----------|--------|-----------|------|
| **세밀한 파라미터 제어** | ✅ reasoning_effort, verbosity | ✅ output_config.effort | ✅ thinking_level |
| **Prefilling** | ❌ | ❌ (400 → Structured Outputs, Haiku 4.5만 예외) | ❌ (새 프롬프트에서 쓰지 않음) |
| **Long Context 최적화** | - | ✅ 최대 1M (30%↑) | ✅ 입력 1M급, 긴 자료 앞·질문 끝 |
| **Extended Thinking** | 같은 이름 없음 (내장 추론은 추론 강도로 조절 → 6절) | ✅ (모델별 기본값·끄기 가능 여부 다름) | 끌 수 없음, 사고 수준으로 조절 |
| **공통 기법** | ✅ XML, Few-shot, CoT | ✅ XML, Multishot, CoT | ✅ 일관된 구조 표기, 예시, 간결한 직접 지시 |

**추천**:
- 두 플랫폼의 **공통 기법**(XML, Examples, CoT, 명확한 지시)을 먼저 적용
- 각 플랫폼 **특화 기능**은 필요 시 추가
