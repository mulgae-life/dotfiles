# GPT-5 파라미터

GPT-5 모델의 핵심 파라미터 상세 가이드.

## reasoning_effort

추론 깊이를 제어합니다.

### 값과 용도

| 값 | 용도 | 예시 작업 |
|------|------|-----------|
| `low` | 빠른 응답, 간단한 작업 | 분류, 번역, 간단한 질의응답 |
| `medium` | 기본값, 대부분의 작업 | 일반 대화, 요약, 검색 |
| `high` | 복잡한 작업, 깊은 추론 | 코딩, Agentic 워크플로우, 멀티스텝 추론 |

### 사용 예시

```python
# 간단한 분류 작업
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "low"},
    instructions="리뷰를 긍정/부정으로 분류하세요.",
    input="이 제품은 정말 좋습니다!"
)

# 복잡한 코딩 작업
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},
    instructions="이 버그를 수정하세요.",
    input="login.py의 인증 로직에 문제가 있습니다."
)
```

### 선택 가이드

```
작업 복잡도 평가:
- 단일 단계? → low
- 2-3 단계? → medium
- 멀티스텝/Agentic? → high
```

## verbosity

응답 길이를 제어합니다.

### 값과 용도

| 값 | 용도 | 예시 |
|------|------|------|
| `low` | 간결한 응답 | "네", "긍정", 1-2문장 |
| `medium` | 기본값 | 1-2문단 |
| `high` | 상세한 응답 | 여러 문단, 상세 설명 |

### 사용 예시

```python
# 간결한 응답
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "low"},
    instructions="이 리뷰가 긍정인지 부정인지만 답하세요.",
    input="좋은 제품입니다!"
)
# 응답: "긍정"

# 상세한 응답
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "high"},
    instructions="이 리뷰를 분석하세요.",
    input="좋은 제품입니다!"
)
# 응답: "이 리뷰는 긍정적입니다. '좋은'이라는 형용사를 사용하여..."
```

## 자연어 Verbosity 오버라이드

프롬프트에서 특정 컨텍스트만 verbosity를 변경할 수 있습니다.

### 전역 low, 코드만 high

```python
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "low"},  # 전역: 간결
    instructions="""
    # Instructions
    <code_writing>
    - 코드 작성 시에는 높은 verbosity를 사용하세요
    - 변수명을 명확하게 하고 필요 시 주석을 추가하세요
    - 단일 문자 변수명 금지 (i, j 제외)
    </code_writing>

    <text_response>
    - 텍스트 응답은 간결하게 유지하세요
    </text_response>
    """,
    input="Python으로 피보나치 수열을 구현해줘"
)
```

**결과**:
- 텍스트 응답: 간결 (low)
- 코드: 상세 (high - 명확한 변수명, 주석)

### Cursor 사례

Cursor는 전역 `low` + 코드 도구에만 `high`를 사용:

```python
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "low"},
    instructions="""
    코드 작성 시:
    - 명확성 우선. 읽기 쉽고 유지보수 가능한 솔루션 선호
    - 명확한 변수명, 필요 시 주석, 직관적 제어 흐름
    - 코드 골프나 과도하게 영리한 원라이너 금지
    - 코드 작성 및 코드 도구에 높은 verbosity 사용

    텍스트 응답:
    - 간결한 상태 업데이트와 최종 작업 요약
    """,
    input="..."
)
```

**효과**: 효율적인 텍스트 + 읽기 쉬운 코드

## 조합 패턴

### 빠르고 간결 (분류/번역)

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "low"},
    text={"verbosity": "low"},
    instructions="...",
    input="..."
)
```

### 깊고 상세 (코딩/분석)

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},
    text={"verbosity": "high"},
    instructions="...",
    input="..."
)
```

### 깊지만 간결 (Agentic, 상태 업데이트)

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},
    text={"verbosity": "low"},  # 상태 업데이트만
    instructions="...",
    input="..."
)
```

## 권장 조합

| 작업 유형 | reasoning_effort | verbosity |
|----------|------------------|-----------|
| 분류 | low | low |
| 번역 | low | medium |
| 질의응답 | medium | medium |
| 요약 | medium | low |
| 코딩 | high | medium/high* |
| Agentic 워크플로우 | high | low (텍스트), high (코드)* |
| 분석 | high | high |

*자연어 오버라이드 사용

## 성능 vs 비용

```
낮은 비용/빠름 ←──────────────────→ 높은 비용/느림
low + low                            high + high
```

최적 조합: **작업에 맞는 최소 수준**

## 출처

- GPT-5 Prompting Guide
- Cursor GPT-5 Integration
