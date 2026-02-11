# Self-Correction Chains 가이드

LLM의 출력 품질을 높이는 자기수정(Self-Correction) 체인 패턴입니다.

## TL;DR

| 단계 | 목적 | 프롬프트 예시 |
|------|------|-------------|
| 1. 생성 | 초안 작성 | "분석해 주세요" |
| 2. 검토 | 오류 식별 | "검토하고 문제점을 지적해 주세요" |
| 3. 개선 | 수정 적용 | "피드백을 반영하여 재작성해 주세요" |

---

## 1. 자기수정 체인 패턴

### 1.1 기본 3단계

```
[입력] → [1. 생성] → [2. 검토] → [3. 개선] → [최종 출력]
```

**단계별 프롬프트**:

```yaml
# 1단계: 생성
step1_prompt: |
  다음 요구사항에 맞게 코드를 작성해 주세요.

  <requirements>
  {{REQUIREMENTS}}
  </requirements>

  초안을 작성하세요. 완벽하지 않아도 됩니다.

# 2단계: 검토
step2_prompt: |
  다음 코드를 검토하고 문제점을 찾아주세요.

  <code>
  {{GENERATED_CODE}}
  </code>

  <review_criteria>
  - 정확성: 요구사항을 충족하는가?
  - 효율성: 불필요한 연산이 있는가?
  - 가독성: 이해하기 쉬운가?
  - 예외처리: edge case를 다루는가?
  </review_criteria>

  문제점을 구체적으로 나열하세요.

# 3단계: 개선
step3_prompt: |
  다음 코드와 피드백을 바탕으로 개선된 버전을 작성해 주세요.

  <original_code>
  {{GENERATED_CODE}}
  </original_code>

  <feedback>
  {{REVIEW_FEEDBACK}}
  </feedback>

  모든 피드백을 반영한 최종 코드를 작성하세요.
```

### 1.2 반복 개선 루프

품질 기준을 충족할 때까지 반복:

```
[생성] → [검토] → [기준 충족?]
                      ↓ No
                  [개선] → [검토] → [기준 충족?]
                                        ↓ No
                                    [개선] → ...
                      ↓ Yes
                  [최종 출력]
```

**Python 구현**:
```python
MAX_ITERATIONS = 3
QUALITY_THRESHOLD = 0.8

def self_correction_loop(initial_input: str) -> str:
    # 1. 초기 생성
    draft = generate(initial_input)

    for i in range(MAX_ITERATIONS):
        # 2. 검토
        review = evaluate(draft)

        # 3. 품질 확인
        if review["score"] >= QUALITY_THRESHOLD:
            return draft

        # 4. 개선
        draft = improve(draft, review["feedback"])

    return draft  # 최대 반복 후 반환
```

### 1.3 품질 평가 기준

```yaml
evaluation_prompt: |
  다음 출력물을 평가해 주세요.

  <output>
  {{GENERATED_OUTPUT}}
  </output>

  <criteria>
  각 항목을 1-5점으로 평가하세요:
  - 정확성: 사실적으로 올바른가?
  - 완전성: 요구사항을 모두 충족하는가?
  - 명확성: 이해하기 쉽게 작성되었는가?
  - 일관성: 내부적으로 모순이 없는가?
  </criteria>

  <output_format>
  {
    "scores": {
      "accuracy": 1-5,
      "completeness": 1-5,
      "clarity": 1-5,
      "consistency": 1-5
    },
    "average": 1.0-5.0,
    "issues": ["문제점 1", "문제점 2"],
    "suggestions": ["개선안 1", "개선안 2"]
  }
  </output_format>
```

---

## 2. 실전 예시

### 2.1 코드 리뷰 체인

```yaml
# 전체 프롬프트 (단일 호출)
system_prompt: |
  당신은 시니어 개발자입니다. 코드를 작성하고 스스로 리뷰합니다.

  <workflow>
  1. 먼저 요구사항에 맞는 코드를 작성하세요
  2. 작성한 코드를 검토하고 문제점을 찾으세요
  3. 문제점을 수정한 최종 코드를 제출하세요
  </workflow>

  <output_format>
  ## 초안
  ```python
  [초안 코드]
  ```

  ## 리뷰
  - [발견된 문제 1]
  - [발견된 문제 2]

  ## 최종 코드
  ```python
  [개선된 코드]
  ```
  </output_format>
```

### 2.2 문서 작성 체인

```yaml
system_prompt: |
  당신은 기술 문서 작성자입니다.

  <workflow>
  1. 초안 작성: 주어진 주제에 대해 문서 초안을 작성합니다
  2. 자체 검토: 다음 관점에서 검토합니다
     - 기술적 정확성
     - 독자 이해도
     - 구조의 논리성
     - 누락된 정보
  3. 최종본 작성: 검토 결과를 반영한 최종 문서를 작성합니다
  </workflow>

  <constraints>
  - 초안에서 발견한 문제를 명시적으로 언급하세요
  - 최종본에서 어떤 부분을 개선했는지 설명하세요
  </constraints>
```

### 2.3 데이터 분석 체인

```yaml
system_prompt: |
  당신은 데이터 분석가입니다.

  <analysis_workflow>
  ## 1단계: 초기 분석
  - 데이터를 분석하고 주요 인사이트를 도출합니다

  ## 2단계: 검증
  다음을 확인합니다:
  - 통계적 오류 여부
  - 상관관계와 인과관계 구분
  - 샘플 크기의 적절성
  - 편향 가능성

  ## 3단계: 최종 보고서
  검증된 인사이트만 포함한 보고서를 작성합니다
  </analysis_workflow>
```

---

## 3. 2단계 디버깅 (Metaprompting)

OpenAI 가이드에서 권장하는 패턴으로, 근본 원인 분석 후 수정합니다.

### 3.1 패턴

```
[오류 발생] → [근본 원인 분석] → [수정 방안 도출] → [수정 적용]
```

### 3.2 프롬프트

```yaml
debugging_prompt: |
  <bug_report>
  {{ERROR_DESCRIPTION}}
  </bug_report>

  <code>
  {{BUGGY_CODE}}
  </code>

  <workflow>
  ## Step 1: 근본 원인 분석
  - 오류의 직접적 원인이 아닌 **근본 원인**을 찾으세요
  - 왜 이 버그가 발생했는지 설명하세요

  ## Step 2: 수정 방안
  - 근본 원인을 해결하는 방안을 제시하세요
  - 표면적 패치가 아닌 올바른 수정이어야 합니다

  ## Step 3: 수정된 코드
  - 수정 방안을 적용한 코드를 작성하세요
  </workflow>
```

---

## 4. 안티패턴

### 4.1 무한 루프 방지

```yaml
# ❌ 위험: 종료 조건 없음
loop:
  while True:
    review()
    improve()

# ✅ 안전: 최대 반복 횟수 설정
loop:
  max_iterations: 3
  while iterations < max:
    review()
    if quality >= threshold:
      break
    improve()
```

### 4.2 과잉 수정 방지

```yaml
correction_rules: |
  <limits>
  - 한 번의 개선에서 최대 3가지 문제만 수정하세요
  - 원래 의도를 유지하면서 수정하세요
  - 불필요한 변경을 피하세요
  </limits>

  <stop_conditions>
  - 더 이상 명확한 문제가 없으면 중단하세요
  - 사소한 스타일 문제는 무시하세요
  </stop_conditions>
```

### 4.3 Self-Correction 오용

```yaml
# ❌ 불필요한 경우 (단순 작업)
task: "Hello를 한국어로 번역"
# Self-correction 불필요 - 직접 번역하면 됨

# ✅ 필요한 경우 (복잡한 작업)
task: "이 알고리즘의 시간 복잡도를 O(n²)에서 O(n log n)으로 개선"
# Self-correction 유용 - 검토와 개선이 품질을 높임
```

---

## 5. 고급 패턴

### 5.1 Multi-Agent 검토

여러 "전문가" 관점에서 검토:

```yaml
multi_agent_review: |
  <reviewers>
  다음 관점에서 각각 검토하세요:

  ## 보안 전문가
  - 보안 취약점이 있는가?
  - 입력 검증이 충분한가?

  ## 성능 전문가
  - 비효율적인 부분이 있는가?
  - 최적화 가능한 부분이 있는가?

  ## 사용성 전문가
  - API가 직관적인가?
  - 에러 메시지가 명확한가?
  </reviewers>

  각 전문가의 피드백을 종합하여 개선하세요.
```

### 5.2 Confidence-Based Correction

확신도에 따른 선택적 수정:

```yaml
confidence_based: |
  각 답변에 확신도(0-100%)를 표시하세요.

  <rules>
  - 확신도 90% 이상: 그대로 유지
  - 확신도 70-90%: 추가 검증 후 유지 또는 수정
  - 확신도 70% 미만: 반드시 재검토 및 수정
  </rules>
```

---

## 6. 모델별 팁

### OpenAI

- **Metaprompting**: 2단계 디버깅 패턴 활용 (근본원인 → 수정)
- **reasoning_effort: high**: 복잡한 검토 작업에 적합
- **Function calling**: 구조화된 검토 결과 출력

### Anthropic (Claude)

- **XML 태그**: `<draft>`, `<review>`, `<final>` 로 단계 분리
  ```xml
  <draft>
  [초안 내용]
  </draft>

  <review>
  [검토 내용]
  </review>

  <final>
  [최종 결과]
  </final>
  ```
- **Extended thinking**: 내부 추론으로 자연스러운 자기 검토
- **Prefilling**: 단계 시작 강제
  ```python
  messages=[
      {"role": "user", "content": "코드를 작성하고 검토해 주세요"},
      {"role": "assistant", "content": "## 초안\n```python\n"}
  ]
  ```

---

## 7. 구현 템플릿

### 단일 호출 (In-context Self-Correction)

```yaml
system_prompt: |
  # Identity
  당신은 품질 관리를 중시하는 전문가입니다.

  # Workflow
  모든 작업에서 다음 절차를 따르세요:

  <step name="draft">
  먼저 초안을 작성합니다.
  </step>

  <step name="review">
  초안을 비판적으로 검토합니다:
  - 정확성 확인
  - 누락 사항 확인
  - 개선점 식별
  </step>

  <step name="improve">
  검토 결과를 반영하여 최종본을 작성합니다.
  </step>

  # Output Format
  ## 초안
  [초안 내용]

  ## 검토
  - [문제점/개선점]

  ## 최종
  [개선된 최종 결과]
```

### 다중 호출 (Chain)

```python
def self_correction_chain(task: str) -> str:
    # Step 1: Generate
    draft = call_llm(
        system="초안을 작성하세요.",
        user=task
    )

    # Step 2: Review
    review = call_llm(
        system="다음을 검토하고 문제점을 찾으세요.",
        user=f"<draft>{draft}</draft>"
    )

    # Step 3: Improve
    final = call_llm(
        system="피드백을 반영하여 개선하세요.",
        user=f"""
        <draft>{draft}</draft>
        <feedback>{review}</feedback>
        """
    )

    return final
```

---

## 8. 적용 가이드

### Self-Correction이 효과적인 경우

- ✅ 복잡한 추론이 필요한 작업
- ✅ 코드 작성 및 디버깅
- ✅ 기술 문서 작성
- ✅ 데이터 분석 및 해석
- ✅ 다단계 문제 해결

### Self-Correction이 불필요한 경우

- ❌ 단순 분류/번역
- ❌ 사실 기반 질의응답
- ❌ 형식 변환 (JSON → CSV)
- ❌ 짧은 텍스트 생성
