# GPT-5.2 Prompting Guide

> **출처**: [OpenAI Cookbook - GPT-5.2 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5-2_prompting_guide)
> **날짜**: 2025-12-11

---

## 개요

GPT-5.2는 엔터프라이즈 및 에이전트 워크로드를 위해 설계된 플래그십 모델. **높은 정확도, 강한 지시 따르기, 더 규율 있는 실행** 강조.

### 핵심 특성

- **더 신중한 스캐폴딩**: 명확한 중간 구조
- **낮은 장황함**: 프롬프트에 민감하게 반응하면서도 간결
- **강한 지시 준수**: 개선된 포맷팅
- **보수적 그라운딩 편향**: 추측보다 정확성 우선

---

## 1. Key Behavioral Differences (주요 동작 차이)

GPT-5/5.1 대비 GPT-5.2의 차이:

| 특성 | GPT-5/5.1 | GPT-5.2 |
|------|-----------|---------|
| 스캐폴딩 | 자유로운 구조 | 더 신중하고 명확한 중간 구조 |
| 장황함 | 상대적으로 높음 | 낮지만 프롬프트 반응적 |
| 지시 준수 | 좋음 | 더 강함 |
| 그라운딩 | 유연 | 보수적 (정확성 우선) |

---

## 2. Prompting Patterns

### Controlling Verbosity (장황함 제어)

명시적 길이 제약으로 출력 사양 정의.

```markdown
# 간단한 질문
"Answer in ≤2 sentences."

# 복잡한 다단계 작업
"Provide a short overview paragraph with tagged bullets:
- What changed
- Where
- Risks
- Next steps"
```

### Preventing Scope Drift (범위 이탈 방지)

UI 컴포넌트나 문서 작성 시 중요.

```markdown
"Implement EXACTLY and ONLY what the user requests.

PROHIBITED:
- Unintended features
- Styling embellishments
- UI inventions (unless explicitly requested)

Enforce design system compliance strictly."
```

### Long-Context Handling (긴 컨텍스트 처리)

~10k 토큰 초과 입력 시 요약 강제.

```markdown
# 권장 접근법
1. 관련 섹션의 내부 개요 생성
2. 답변 전 사용자 제약 명시적 재진술
3. 주장을 특정 소스 위치에 앵커링
```

### Handling Ambiguity (모호함 처리)

쿼리가 불명확하거나 외부 사실이 변경됐을 수 있을 때:

```markdown
"Present 2–3 plausible interpretations with clearly labeled assumptions
rather than fabricating details."

# 민감한 컨텍스트에서
"Perform self-check steps to identify:
- Unstated assumptions
- Overly strong language"
```

---

## 3. Compaction (컨텍스트 확장)

### 개요

`/responses/compact` 엔드포인트로 손실 인식 압축된 대화 상태 생성.

### 언제 사용

- 컨텍스트 윈도우를 초과하는 다단계 에이전트 플로우

### 주요 속성

| 속성 | 설명 |
|------|------|
| 형식 | 불투명한 암호화된 항목 생성 |
| 용도 | 검사가 아닌 계속을 위해 설계 |
| 호환성 | GPT-5.2 및 Responses API와 호환 |

### 모범 사례

```markdown
1. 매 턴이 아닌 주요 마일스톤 후에 압축
2. 컨텍스트 사용량 사전 모니터링
3. 재개 시 프롬프트를 기능적으로 동일하게 유지
```

### API 사용 예시

```python
# 압축 요청
compact_response = client.responses.compact(
    response_id=previous_response_id
)

# 압축된 컨텍스트로 계속
response = client.responses.create(
    model="gpt-5.2",
    input=new_messages,
    previous_response_id=compact_response.id
)
```

---

## 4. Agentic Steerability & User Updates

업데이트 장황함 제한 및 범위 규율 적용으로 성능 향상.

```markdown
# 권장 사항
- 주요 단계 전환에서만 간단한 업데이트 (1-2문장)
- 각 업데이트에 구체적인 결과 포함
- 일상적인 도구 호출 나레이션 피하기
- 사용자 요청 범위를 넘어 작업 확장하지 않기
```

---

## 5. Tool-Calling and Parallelism

### 도구 통합 모범 사례

| 항목 | 권장 사항 |
|------|----------|
| 도구 설명 | 1-2문장으로 간결하게 |
| 병렬화 | 독립 작업에 권장 (파일 읽기, DB 쿼리, 문서 검색) |
| 검증 | 고영향 작업에 검증 단계 필수 |
| 도구 vs 내부 지식 | 최신 데이터 필요 시 도구 선호 |

---

## 6. Structured Extraction & PDF Workflows

GPT-5.2는 추출 작업에 탁월함.

### 최적화 방법

```markdown
1. 필수/선택 필드 구분이 있는 JSON 스키마 항상 제공
2. 누락된 값은 추측 대신 null로 설정
3. 누락 항목 포착을 위한 추출 후 재스캔 수행
4. 다중 문서 결과는 안정적 식별자로 별도 직렬화
```

### JSON 스키마 예시

```json
{
  "type": "object",
  "properties": {
    "invoice_number": {"type": "string"},
    "date": {"type": "string", "format": "date"},
    "total_amount": {"type": "number"},
    "vendor_name": {"type": "string"},
    "line_items": {
      "type": "array",
      "items": {
        "type": "object",
        "properties": {
          "description": {"type": "string"},
          "quantity": {"type": "integer"},
          "unit_price": {"type": "number"}
        },
        "required": ["description"]
      }
    }
  },
  "required": ["invoice_number", "date"]
}
```

---

## 7. Prompt Migration Guide

### 마이그레이션 매핑

| 현재 모델 | 타겟 | Reasoning Effort | 노트 |
|-----------|------|------------------|------|
| GPT-4o/4.1 | GPT-5.2 | none | 빠른 동작 유지 |
| GPT-5 | GPT-5.2 | 동일 (minimal→none) | 지연/품질 일관성 유지 |
| GPT-5.1 | GPT-5.2 | 동일 | 평가 회귀 후에만 조정 |

### 마이그레이션 단계

```markdown
1. 프롬프트 변경 없이 모델만 전환 (모델 차이 격리)
2. reasoning_effort를 이전 지연 프로필에 맞게 고정
3. 기준선으로 평가 실행
4. 회귀 발생 시 점진적으로 프롬프트 튜닝
5. 각 변경 후 재테스트
```

---

## 8. Web Search and Research

### 포괄적인 리서치 워크플로우

```markdown
# 리서치 기준 사전 지정
- 검색이 얼마나 철저해야 하는지 정의
- 2차 리드 따라갈지 여부
- 모순 해결 방법

# 지시로 모호함 제한
- 명확화 질문 대신 모든 가능한 의도 커버 지시

# 출력 형태 지정
- Markdown 포맷팅, 헤더, 테이블
- 약어 정의
- 구체적 예시
```

### Web Search 규칙

```markdown
1. 종합적인 답변을 기본으로 하는 전문 리서치 어시스턴트로 행동
2. 불확실하거나 불완전한 사실에 대해 인용과 함께 웹 리서치 선호
3. 모든 쿼리 구성요소 리서치, 모순 해결, 함의 따라가기
4. 명확화 질문 피하기; 대신 모든 가능한 의도 커버
5. Markdown으로 명확하게 작성, 약어 정의, 구체적 예시 포함
```

---

## 9. High-Risk Self-Check Pattern

법률, 금융, 안전 민감 컨텍스트용:

```markdown
Before finalizing responses, briefly re-scan for:

1. Unstated assumptions
2. Specific numbers not grounded in provided context
3. Overly absolute language ("always," "guaranteed")

When issues arise:
- Soften or qualify findings
- Explicitly state assumptions
```

---

## 10. 핵심 요약

| 영역 | 핵심 포인트 |
|------|------------|
| Verbosity | 명시적 길이 제약, 태그된 불릿 |
| Scope Drift | "EXACTLY and ONLY", 디자인 시스템 준수 |
| Long Context | 내부 개요, 제약 재진술, 소스 앵커링 |
| Ambiguity | 2-3 해석 제시, 명확한 가정 라벨 |
| Compaction | 마일스톤 후 압축, 기능적 동일 프롬프트 유지 |
| Tool Parallelism | 독립 작업 병렬화, 고영향 작업 검증 |
| Extraction | JSON 스키마, null 사용, 추출 후 재스캔 |
| Migration | 모델 전환 → 평가 → 튜닝 (순서 중요) |
| Web Search | 철저함 정의, 모든 의도 커버, Markdown 출력 |
| Self-Check | 가정, 미그라운드 숫자, 절대적 언어 점검 |

---

## 참고 자료

- [OpenAI Cookbook 원문](https://cookbook.openai.com/examples/gpt-5/gpt-5-2_prompting_guide)
- [Compaction API 문서](https://platform.openai.com/docs/api-reference/responses/compact)
- [Migration Guide](https://platform.openai.com/docs/guides/migration)
