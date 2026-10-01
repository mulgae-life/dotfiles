# 플랫폼별 차이점 비교

OpenAI GPT와 Anthropic Claude의 프롬프트 엔지니어링 주요 차이점입니다.

## 빠른 비교표

| 항목 | OpenAI (GPT-5.x / 6) | Anthropic (Claude) | 공통 |
|------|----------------|-------------------|------|
| **Message Roles** | `developer` (최고 우선순위)<br/>`user`, `assistant` | `system` 파라미터<br/>`user`, `assistant` | `user`, `assistant` |
| **파라미터** | `reasoning_effort`<br/>`verbosity` | `output_config.effort` | - |
| **Prefilling** | ❌ 없음 | ❌ 400 에러 → Structured Outputs | - |
| **Long Context** | 일반적 사용 | ✅ 1M(출력 128K)<br/>(문서 맨 위 배치 → 30%↑) | - |
| **CoT** | "Think step-by-step" (GPT 추론 모델은 추가 추론 유도 문구 생략) | thinking이 켜져 있으면 일반 지시 우선<br/>끈 경우 3단계 (Basic/Guided/Structured) | ⚠️ 모델·설정별 분기 |
| **Examples** | Few-shot | Multishot | ✅ 동일 개념 (Frontier 0~2개, 소형 3-5개) |
| **XML Tags** | ✅ 권장 | ✅ 권장 | ✅ 공통 |
| **Extended Thinking** | 같은 이름의 기능 없음. 추론 모델은 추론 강도 파라미터로 조절 → 6절 | ✅ adaptive thinking 기본 켜짐(Opus 5.5·Fable 5.1은 끌 수 없음), `effort`로 깊이 제어 | - |

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

**차이점**:
- OpenAI: `developer` role이 `user`보다 높은 우선순위
- Anthropic: `system` 파라미터로 역할 설정

### 2. Prefilling (응답 사전 채우기)

두 플랫폼 모두 지원하지 않습니다. Claude 5 세대는 마지막 assistant 턴 prefill이 **400 에러**입니다. JSON/XML 형식 강제는 Structured Outputs(`output_config.format`), 프리앰블 생략·캐릭터 유지는 시스템 프롬프트 지시로 처리합니다 → [claude-5-specifics.md](claude-5-specifics.md).

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
- `output_config.effort` (`low`~`max`)로 추론 깊이 제어 → [claude-5-specifics.md](claude-5-specifics.md)
- 응답 길이는 프롬프트로 제어:
  ```
  "간결하게 답변하세요" (verbosity low 대신)
  ```

## 플랫폼 선택 가이드

### OpenAI GPT-5.x / 6을 선택하는 경우
- `reasoning_effort`, `verbosity` 파라미터로 세밀한 제어 필요
- `developer` role로 강력한 시스템 규칙 우선순위 필요
- OpenAI 생태계 (Assistants API, GPTs 등) 통합

### Anthropic Claude를 선택하는 경우
- Long context 활용 (1M, 출력 128K — 문서 맨 위 배치로 30% 성능 향상)
- adaptive thinking으로 복잡한 추론 작업

### 공통 사용 가능
- XML 태그 구조화
- Few-shot/Multishot (Frontier 0~2개 포맷 정렬, 소형 3-5개)
- Chain of Thought
- 명확한 지시와 제약
- 모순 제거

## 실전 적용

### 프로젝트 판단 기준
```
프로젝트에서 사용 중인 API 확인:
- `openai` 패키지 사용? → OpenAI 섹션 적용
- `anthropic` 패키지 사용? → Anthropic 섹션 적용
- 둘 다 사용? → 공통 섹션 + 각 API별 특화 기능 혼용
```

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

## 요약

| 선택 기준 | OpenAI | Anthropic |
|----------|--------|-----------|
| **세밀한 파라미터 제어** | ✅ reasoning_effort, verbosity | ✅ output_config.effort |
| **Prefilling** | ❌ | ❌ (400 → Structured Outputs) |
| **Long Context 최적화** | - | ✅ 1M (30%↑) |
| **Extended Thinking** | 같은 이름 없음 (내장 추론은 추론 강도로 조절 → 6절) | ✅ |
| **공통 기법** | ✅ XML, Few-shot, CoT | ✅ XML, Multishot, CoT |

**추천**:
- 두 플랫폼의 **공통 기법**(XML, Examples, CoT, 명확한 지시)을 먼저 적용
- 각 플랫폼 **특화 기능**은 필요 시 추가
