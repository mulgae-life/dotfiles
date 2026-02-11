# 추론 파라미터 가이드

LLM의 추론 깊이와 응답 길이를 제어하는 범용 가이드입니다.

## TL;DR

| 파라미터 | 목적 | 낮음 | 중간 | 높음 |
|---------|------|------|------|------|
| **추론 깊이** | 복잡한 사고 제어 | 빠른 응답 | 기본값 | 깊은 추론 |
| **응답 길이** | 출력 분량 제어 | 간결 | 1-2문단 | 상세 |

---

## 1. 추론 깊이 (Reasoning Depth)

### 범용 원칙

LLM의 "생각하는 정도"를 제어합니다. 작업 복잡도에 맞게 조절하세요.

| 수준 | 용도 | 예시 작업 |
|------|------|-----------|
| **낮음** | 빠른 응답, 간단한 작업 | 분류, 번역, 간단한 Q&A |
| **중간** | 기본값, 대부분의 작업 | 일반 대화, 요약, 검색 |
| **높음** | 복잡한 작업, 깊은 추론 | 코딩, 멀티스텝 추론, 분석 |

### 선택 가이드

```
작업 복잡도 평가:
- 단일 단계 작업? → 낮음
- 2-3 단계 작업? → 중간
- 멀티스텝/Agentic? → 높음
```

### 프롬프트로 제어 (범용)

```yaml
# 깊은 추론 유도
system_prompt: |
  <thinking_style>
  - 답변하기 전에 문제를 단계별로 분석하세요
  - 여러 관점을 고려하세요
  - 결론에 도달한 과정을 설명하세요
  </thinking_style>

# 빠른 응답 유도
system_prompt: |
  <response_style>
  - 바로 핵심 답변을 제공하세요
  - 불필요한 설명을 생략하세요
  - 간결하게 응답하세요
  </response_style>
```

---

## 2. 응답 길이 (Verbosity)

### 범용 원칙

출력 분량을 제어합니다.

| 수준 | 용도 | 예시 출력 |
|------|------|----------|
| **낮음** | 간결한 응답 | "네", "긍정", 1-2문장 |
| **중간** | 기본값 | 1-2문단 |
| **높음** | 상세한 응답 | 여러 문단, 상세 설명 |

### 프롬프트로 제어 (범용)

```yaml
# 간결한 응답
system_prompt: |
  <output_rules>
  - 한 문장으로 답변하세요
  - 부가 설명을 포함하지 마세요
  </output_rules>

# 상세한 응답
system_prompt: |
  <output_rules>
  - 각 포인트를 상세히 설명하세요
  - 예시를 포함하세요
  - 근거를 제시하세요
  </output_rules>
```

---

## 3. 조합 패턴

### 빠르고 간결 (분류/번역)

```yaml
system_prompt: |
  <rules>
  - 바로 답변만 제공하세요
  - 설명을 포함하지 마세요
  - 한 단어 또는 한 문장으로 응답하세요
  </rules>
```

### 깊지만 간결 (Agentic, 상태 업데이트)

```yaml
system_prompt: |
  <rules>
  - 문제를 철저히 분석하세요
  - 하지만 응답은 핵심 결론만 간결하게
  - 진행 상황은 짧은 상태 업데이트로
  </rules>
```

### 깊고 상세 (코딩/분석)

```yaml
system_prompt: |
  <rules>
  - 문제를 단계별로 분석하세요
  - 각 단계의 근거를 설명하세요
  - 코드에는 주석을 포함하세요
  </rules>
```

---

## 4. 컨텍스트별 다른 수준 적용

한 프롬프트 내에서 컨텍스트에 따라 다른 수준을 지정할 수 있습니다.

### 예시: 텍스트는 간결, 코드는 상세

```yaml
system_prompt: |
  <code_writing>
  코드 작성 시:
  - 명확한 변수명 사용
  - 필요 시 주석 추가
  - 읽기 쉬운 구조 유지
  </code_writing>

  <text_response>
  텍스트 응답 시:
  - 간결하게 유지
  - 불필요한 설명 생략
  </text_response>
```

### 예시: 분석은 상세, 요약은 간결

```yaml
system_prompt: |
  <analysis_section>
  분석 부분:
  - 데이터를 상세히 검토
  - 여러 관점 고려
  - 근거 제시
  </analysis_section>

  <summary_section>
  요약 부분:
  - 핵심 결론만 1-2문장
  - 불릿 포인트 최소화
  </summary_section>
```

---

## 5. 권장 조합

| 작업 유형 | 추론 깊이 | 응답 길이 |
|----------|----------|----------|
| 분류 | 낮음 | 낮음 |
| 번역 | 낮음 | 중간 |
| 질의응답 | 중간 | 중간 |
| 요약 | 중간 | 낮음 |
| 코딩 | 높음 | 중간~높음* |
| Agentic 워크플로우 | 높음 | 낮음 (텍스트), 높음 (코드)* |
| 분석 | 높음 | 높음 |

*컨텍스트별 다른 수준 적용

---

## 6. 모델별 팁

### OpenAI (GPT-5)

**API 파라미터로 직접 제어**:

```python
response = client.responses.create(
    model="gpt-5",
    reasoning={"effort": "high"},  # low, medium, high
    text={"verbosity": "low"},      # low, medium, high
    instructions="...",
    input="..."
)
```

**파라미터 설명**:
- `reasoning.effort`: 추론 깊이
  - `low`: 빠른 응답
  - `medium`: 기본값
  - `high`: 깊은 추론 (코딩, Agentic에 적합)
- `text.verbosity`: 응답 길이
  - `low`: 간결
  - `medium`: 기본값
  - `high`: 상세

**자연어 오버라이드**: 전역 설정을 프롬프트에서 컨텍스트별로 재정의 가능

```python
response = client.responses.create(
    model="gpt-5",
    text={"verbosity": "low"},  # 전역: 간결
    instructions="""
    코드 작성 시에는 높은 verbosity를 사용하세요.
    명확한 변수명과 주석을 포함하세요.
    텍스트 응답은 간결하게 유지하세요.
    """,
    input="..."
)
```

### Anthropic (Claude)

**Extended Thinking 모드**:

```python
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=16000,
    thinking={
        "type": "enabled",
        "budget_tokens": 10000  # 추론에 할당할 토큰
    },
    messages=[...]
)
```

**특징**:
- 복잡한 작업에서 품질 향상
- `budget_tokens`로 추론 깊이 간접 제어
- 추론 과정이 별도로 반환됨

**프롬프트로 제어**:

```xml
<thinking_instructions>
- 답변 전에 단계별로 분석하세요
- 여러 접근 방식을 비교하세요
</thinking_instructions>
```

**주의**: Extended thinking 모드에서는 prefilling 사용 불가

### 공통 팁

```yaml
# 복잡한 작업에서 품질 높이기
- 단계별 사고 요청 ("step by step")
- 근거 제시 요청 ("explain your reasoning")
- 자기 검토 요청 ("verify your answer")

# 간결한 응답 얻기
- 길이 제한 명시 ("in one sentence")
- 형식 지정 ("answer only yes or no")
- 설명 제외 ("without explanation")
```

---

## 7. 성능 vs 비용/속도

```
낮은 비용/빠름 ←──────────────────→ 높은 비용/느림
낮은 추론 + 낮은 길이              높은 추론 + 높은 길이
```

**원칙**: 작업에 맞는 최소 수준 선택

| 상황 | 권장 |
|------|------|
| 대량 처리 | 낮은 추론, 낮은 길이 |
| 실시간 응답 | 낮은~중간 추론, 낮은 길이 |
| 품질 중시 | 높은 추론, 적절한 길이 |
| 비용 민감 | 낮은 추론, 낮은 길이 |

---

## 8. 프롬프트 템플릿

### 간결한 분류기

```yaml
system_prompt: |
  당신은 분류기입니다.

  <rules>
  - 분류 결과만 출력하세요
  - 설명을 포함하지 마세요
  </rules>

  <categories>
  - 긍정
  - 부정
  - 중립
  </categories>
```

### 상세한 분석가

```yaml
system_prompt: |
  당신은 데이터 분석가입니다.

  <analysis_approach>
  - 데이터를 다각도로 검토하세요
  - 패턴과 이상치를 식별하세요
  - 통계적 근거를 제시하세요
  </analysis_approach>

  <output_format>
  ## 분석 결과
  [상세 분석]

  ## 주요 인사이트
  [핵심 발견]

  ## 권장사항
  [조치 제안]
  </output_format>
```

### Agentic 워크플로우

```yaml
system_prompt: |
  당신은 자율 에이전트입니다.

  <thinking>
  - 문제를 철저히 분석하세요
  - 여러 접근 방식을 고려하세요
  - 최적의 방법을 선택하세요
  </thinking>

  <communication>
  - 상태 업데이트는 간결하게
  - 코드는 읽기 쉽게 상세히
  - 최종 결과만 요약하여 보고
  </communication>
```
