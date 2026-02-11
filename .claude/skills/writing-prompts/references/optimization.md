# GPT-5 최적화 팁

GPT-5 성능을 극대화하는 고급 최적화 기법입니다.

## 1. 모순 제거 (Critical)

GPT-5는 모순된 지시에 민감합니다. 충돌하는 지시는 추론 토큰을 낭비하고 성능을 저하시킵니다.

### ❌ 나쁜 예: 모순

```yaml
# 모순 1: 길이
- 간결하게 답변하세요
- 상세하게 설명하세요

# 모순 2: 동의
- 사용자 동의 없이는 절대 일정을 예약하지 마세요
- 긴급한 경우 사용자에게 연락하지 말고 가장 빠른 슬롯을 자동으로 할당하세요

# 모순 3: 우선순위
- 항상 파일을 먼저 읽으세요
- 긴급한 경우 즉시 911에 전화하도록 안내하세요
```

### ✅ 좋은 예: 명확

```yaml
# 명확 1: 길이
- 핵심을 1-2문단으로 간결하게 답변하세요
- 필요한 경우에만 추가 설명을 제공하세요

# 명확 2: 조건부 동의
- 차트에 명시적 환자 동의가 기록된 경우에만 일정을 예약하세요
- 긴급한 경우(빨간색 우선순위) 환자에게 즉시 911에 전화하도록 안내하세요
  - 긴급 상황에서는 파일 조회를 건너뛰고 즉시 911 안내로 진행하세요

# 명확 3: 우선순위
- 기본적으로 파일을 먼저 읽으세요
- 단, 긴급 상황에서는 파일 조회를 건너뛰고 즉시 911 안내로 진행하세요
```

## 2. Instruction Hierarchy

충돌 시 우선순위는 프롬프트 **끝부분** 지시가 높습니다.

### 원칙

```
프롬프트 시작 ───────────────→ 프롬프트 끝
낮은 우선순위              높은 우선순위
```

### ❌ 나쁜 예

```yaml
<rule_1>
- 항상 간결하게 답변하세요 (1-2문장)
</rule_1>

<rule_2>
- 상세하게 설명하세요
</rule_2>

# → rule_2가 우선 적용됨 (끝부분)
```

### ✅ 좋은 예

```yaml
<rules>
- 핵심을 1-2문장으로 간결하게 답변하세요
- 필요한 경우에만 추가 설명을 제공하세요
</rules>

# 또는 우선순위를 명시

<rules priority="1">
- 항상 간결하게 답변하세요 (1-2문장)
</rules>

<rules priority="2">
- 필요한 경우에만 추가 설명을 제공하세요
</rules>
```

## 3. 출력 형식 명시

### ❌ 나쁜 예: 모호함

```yaml
- JSON으로 답변하세요
```

**문제**: 어떤 JSON? 필드는? 다른 텍스트는?

### ✅ 좋은 예: 명확함

```yaml
<output_format>
다음 JSON 형식으로만 응답하세요:
{
  "sentiment": "긍정|중립|부정",
  "confidence": 0.0-1.0,
  "keywords": ["단어1", "단어2"]
}

JSON 외부에 다른 텍스트를 포함하지 마세요.
설명이나 주석을 추가하지 마세요.
</output_format>
```

## 4. Markdown 포맷

기본적으로 GPT-5는 Markdown을 사용하지 않습니다.

### 활성화 방법

```yaml
<markdown>
- Markdown은 의미상 올바를 때만 사용하세요
  - `inline code` - 파일명, 함수명, 클래스명
  - ```code fences``` - 코드 블록
  - 리스트, 표 - 구조화된 정보
- 파일, 디렉토리, 함수, 클래스 이름은 백틱(`)으로 포맷하세요
- 수식: 인라인 \( \), 블록 \[ \]
</markdown>
```

### 장시간 대화 시 주의

Markdown 지침이 대화 중 희석될 수 있습니다.

**해결책**: 3-5 메시지마다 Markdown 지침 재전송

```python
# 메시지 카운터
message_count = 0

def send_message(content):
    global message_count
    message_count += 1

    # 5 메시지마다 Markdown 지침 추가
    if message_count % 5 == 0:
        content += "\n\n참고: Markdown 형식을 유지하세요 (`inline code`, ```code blocks```)"

    return client.responses.create(...)
```

## 5. 프롬프트 캐싱 최적화

Context를 마지막에 배치하여 캐싱 효율 향상.

### 구조

```yaml
# Identity (항상 동일)
당신은 [역할]입니다.

# Instructions (항상 동일)
<rules>...</rules>

# Examples (항상 동일)
<examples>...</examples>

# Context (요청마다 변경) ← 마지막
[외부 데이터]
```

**효과**: Identity, Instructions, Examples는 캐시되어 재사용.

## 6. Metaprompting

GPT-5로 프롬프트 자체를 개선합니다.

### 템플릿

```
프롬프트를 최적화하도록 요청받으면, 자신의 관점에서 답변하세요 -
이 프롬프트에 어떤 구체적인 문구를 추가하거나 삭제하면 원하는 동작을
더 일관되게 유도하거나 원하지 않는 동작을 방지할 수 있는지 설명하세요.

현재 프롬프트: [PROMPT]

이 프롬프트의 원하는 동작은 에이전트가 [원하는 동작]을 하는 것이지만,
대신 [원하지 않는 동작]을 합니다. 기존 프롬프트를 최대한 유지하면서,
이러한 단점을 더 일관되게 해결하기 위해 어떤 최소한의 편집/추가를 하시겠습니까?
```

### 예시

```
프롬프트: "간결하게 답변하세요."

원하는 동작: 1-2문장으로 답변
원하지 않는 동작: 여러 문단으로 답변

GPT-5 제안:
"핵심을 1-2문장으로 간결하게 답변하세요. 3문장 이상 사용하지 마세요."
```

## 7. OpenAI Prompt Optimizer (사용자 도구)

공식 웹 도구로 프롬프트 자동 최적화. 사용자가 직접 실행해야 합니다.

### 사용 방법

1. https://platform.openai.com/chat/edit?optimize=true 접속
2. Developer Message에 프롬프트 붙여넣기
3. "Optimize" 버튼 클릭
4. 변경 사항 검토 및 적용
5. 개선된 프롬프트를 프로젝트에 반영

### 최적화 항목

- 모순 제거
- 명확성 향상
- 출력 형식 명시
- 제약 조건 강화

## 8. Verbosity 자연어 오버라이드

전역 verbosity와 다르게 특정 컨텍스트만 변경.

### 패턴: 전역 low, 코드만 high

```python
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "low"},  # 전역: 간결
    instructions="""
    <code_writing>
    - 코드 작성 시에는 높은 verbosity를 사용하세요
    - 변수명을 명확하게 하고 주석을 추가하세요
    - 단일 문자 변수명 금지 (i, j 제외)
    </code_writing>

    <text_response>
    - 텍스트 응답은 간결하게 유지하세요
    </text_response>
    """,
    input="..."
)
```

**효과**: 간결한 텍스트 + 읽기 쉬운 코드

## 9. 체크리스트

### 자동 검증 가능
- [ ] 모순 제거 (충돌하는 지시 없음)
- [ ] Instruction Hierarchy 확인 (우선순위 명확)
- [ ] 출력 형식 명시 (JSON/Markdown 상세 정의)
- [ ] Context 배치 최적화 (마지막에 배치)
- [ ] Markdown 지침 추가 (필요 시)
- [ ] Metaprompting으로 검증
- [ ] 실전 테스트 (A/B)

### 사용자 직접 실행
- OpenAI Prompt Optimizer: https://platform.openai.com/chat/edit?optimize=true

## 출처

- GPT-5 Prompting Guide
- OpenAI Prompt Engineering Guide
- Prompt Optimizer
