# 플랫폼별 차이점 비교

OpenAI GPT와 Anthropic Claude의 프롬프트 엔지니어링 주요 차이점입니다.

## 빠른 비교표

| 항목 | OpenAI (GPT-5) | Anthropic (Claude) | 공통 |
|------|----------------|-------------------|------|
| **Message Roles** | `developer` (최고 우선순위)<br/>`user`, `assistant` | `system` 파라미터<br/>`user`, `assistant` | `user`, `assistant` |
| **파라미터** | `reasoning_effort`<br/>`verbosity` | (없음) | - |
| **Prefilling** | ❌ 없음 | ✅ `assistant` message prefill | - |
| **Long Context** | 일반적 사용 | ✅ 200K 토큰 최적화<br/>(문서 맨 위 배치 → 30%↑) | - |
| **CoT** | "Think step-by-step" | "Let Claude think"<br/>3단계 (Basic/Guided/Structured) | ✅ 공통 개념 |
| **Examples** | Few-shot | Multishot | ✅ 동일 개념 (3-5개 권장) |
| **XML Tags** | ✅ 권장 | ✅ 권장 | ✅ 공통 |
| **Extended Thinking** | ❌ 없음 | ✅ Claude 4.x 특화 | - |

## 상세 비교

### 1. Message Roles (시스템 지침)

#### OpenAI
```python
# developer role (최고 우선순위)
response = client.responses.create(
    model="gpt-5",
    input=[
        {"role": "developer", "content": "반드시 격식체 사용"},
        {"role": "user", "content": "안녕하세요"}
    ]
)

# 또는 instructions 파라미터
response = client.responses.create(
    model="gpt-5",
    instructions="반드시 격식체 사용",
    input="안녕하세요"
)
```

#### Anthropic
```python
# system 파라미터
response = client.messages.create(
    model="claude-sonnet-4-5",
    system="반드시 격식체 사용",  # system prompt
    messages=[
        {"role": "user", "content": "안녕하세요"}
    ]
)
```

**차이점**:
- OpenAI: `developer` role이 `user`보다 높은 우선순위
- Anthropic: `system` 파라미터로 역할 설정

### 2. Prefilling (응답 사전 채우기)

#### OpenAI
- ❌ 지원하지 않음

#### Anthropic ⭐
```python
# JSON 강제 출력
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "데이터를 JSON으로 추출해줘"},
        {"role": "assistant", "content": "{"}  # Prefill
    ]
)
# 출력: { "name": "...", "age": ... } (프리앰블 없이 바로 JSON)

# 캐릭터 유지
response = client.messages.create(
    model="claude-sonnet-4-5",
    messages=[
        {"role": "user", "content": "이 사건을 분석해봐"},
        {"role": "assistant", "content": "[Sherlock Holmes]"}  # Prefill
    ]
)
# 출력: Sherlock 캐릭터로 응답 시작
```

**용도**:
- JSON/XML 출력 강제
- 프리앰블 건너뛰기
- 역할극 캐릭터 유지

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
# 간단한 지시
- "Think step-by-step"
- "Explain your reasoning"
```

#### Anthropic
3단계 구분:
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

**공통점**: 사고 과정 출력 필수

### 5. Extended Thinking

#### OpenAI
- ❌ 없음

#### Anthropic (Claude 4.x) ⭐
```python
# Extended thinking 모드
response = client.messages.create(
    model="claude-opus-4-5",
    thinking={
        "type": "enabled",
        "budget_tokens": 10000
    },
    messages=[...]
)
```

**특징**:
- 복잡한 추론 강화
- Context awareness (token budget 추적)
- Multi-window workflows

### 6. GPT-5 특화 파라미터

#### OpenAI ⭐
```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},  # 추론 깊이
    text={"verbosity": "low"},     # 응답 길이
    instructions="...",
    input="..."
)
```

**파라미터**:
- `reasoning_effort`: low/medium/high (추론 깊이)
- `verbosity`: low/medium/high (응답 길이)

#### Anthropic
- ❌ 해당 파라미터 없음
- 대신 프롬프트로 제어:
  ```
  "간결하게 답변하세요" (verbosity low 대신)
  "Think step-by-step" (reasoning 대신)
  ```

## 플랫폼 선택 가이드

### OpenAI GPT-5를 선택하는 경우
- `reasoning_effort`, `verbosity` 파라미터로 세밀한 제어 필요
- `developer` role로 강력한 시스템 규칙 우선순위 필요
- OpenAI 생태계 (Assistants API, GPTs 등) 통합

### Anthropic Claude를 선택하는 경우
- Prefilling으로 출력 형식 강제 필요
- 200K 토큰 long context 활용 (30% 성능 향상)
- Extended thinking으로 복잡한 추론 작업
- Claude 4.x의 우수한 코딩/비전 능력

### 공통 사용 가능
- XML 태그 구조화
- Few-shot/Multishot (3-5개 예시)
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
    model="gpt-5",
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
    model="claude-sonnet-4-5",
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
    ]
)
```

## 요약

| 선택 기준 | OpenAI | Anthropic |
|----------|--------|-----------|
| **세밀한 파라미터 제어** | ✅ reasoning_effort, verbosity | ❌ |
| **Prefilling** | ❌ | ✅ |
| **Long Context 최적화** | - | ✅ (30%↑) |
| **Extended Thinking** | ❌ | ✅ |
| **공통 기법** | ✅ XML, Few-shot, CoT | ✅ XML, Multishot, CoT |

**추천**:
- 두 플랫폼의 **공통 기법**(XML, Examples, CoT, 명확한 지시)을 먼저 적용
- 각 플랫폼 **특화 기능**은 필요 시 추가
