# GPT-5 Prompt Optimizer

> **출처**: [OpenAI Cookbook - GPT-5 Prompt Migration and Improvement Using the New Optimizer](https://cookbook.openai.com/examples/gpt-5/prompt-optimization-cookbook)
> **날짜**: 2025-10

---

## 개요

OpenAI Playground에 도입된 **GPT-5 Prompt Optimizer** 도구. 기존 프롬프트 개선 및 GPT-5 등 모델로 마이그레이션 지원.

### 핵심 해결 문제

| 문제 | 설명 |
|------|------|
| **지시 모순** | 성능을 저하시키는 상충되는 지시 |
| **불명확한 포맷 사양** | 일관성 없는 출력 유발 |
| **프롬프트-예시 불일치** | 프롬프트와 예시 간의 정합성 부족 |

### 도메인별 특화

- 에이전트 워크플로우
- 코딩 작업
- 멀티모달 작업

---

## 1. Case Study: 코딩 벤치마크 (Top-K Frequent Words)

### 기준선 프롬프트 문제점

```markdown
# 원본 프롬프트의 혼합 신호
"Prefer the standard library; use external packages if they make things simpler."

# 문제점
- 외부 의존성에 대한 모호한 허용이 이식성 저해
- 싱글패스 스트리밍 권장하면서 재읽기도 허용 → 메모리 제약 모호
```

### 식별된 주요 모순

| # | 모순 | 설명 |
|---|------|------|
| 1 | Stdlib vs External | 의존성 사용에 대한 상충되는 가이드 |
| 2 | Streaming vs Caching | 불명확한 메모리 최적화 전략 |
| 3 | Exact vs Approximate | 경계 근처 휴리스틱에 대한 모호한 허용 |
| 4 | Global State | 인터페이스 계약 혼합 (반환값 vs 전역변수) |
| 5 | Documentation Style | 모순되는 간결성 가이드 |

### 최적화 결과 (30회 실행)

| 메트릭 | 기준선 | 최적화 후 | 변화 |
|--------|--------|----------|------|
| 실행 성공률 | ~87% | ~100% | **+13%** |
| 평균 런타임 (초) | 7.91 | 6.98 | -0.93 |
| 피크 메모리 (KB) | 3626 | 578 | **-84%** |
| 정확성 | 100% | 100% | — |
| 코드 품질 점수 | 4.73/5 | 4.90/5 | +0.17 |
| 준수 점수 | 4.40/5 | 4.90/5 | **+0.50** |

### 최적화된 프롬프트 구조

```markdown
## Hard Requirements (필수 요구사항)
- 표준 라이브러리만 사용
- 싱글패스 스트리밍 필수
- 정확한 결과만 (근사치 불허)
- 반환값으로만 결과 전달 (전역변수 금지)

## Performance Constraints (성능 제약)
- 힙 기반 Top-K 선택 지정
- O(n) 시간 복잡도 목표

## Guidance (가이드)
- heapq.nsmallest() 사용 권장
- 메모리 경계 유지

## Example Code (예시 코드)
[올바른 토큰화 및 정렬 패턴 데모]
```

---

## 2. Case Study: 금융 QA 벤치마크 (FailSafeQA)

### 작업 설명

FailSafeQA는 의도적으로 불완전한 입력으로 견고성 테스트:

| 노이즈 유형 | 예시 |
|------------|------|
| **쿼리 노이즈** | 오타, 불완전한 문장, 도메인 외 언어 |
| **컨텍스트 손상** | OCR 아티팩트, 누락된 문서, 무관한 패시지 |

### 평가 메트릭

- Robustness (견고성)
- Context Grounding (컨텍스트 그라운딩)
- Compliance (준수)

### 기준선 프롬프트

```markdown
"Answer ONLY using the provided context.
If context is missing or irrelevant, politely refuse
and state that you need the relevant document."
```

**문제점**: 노이즈 처리 및 증거 검증에 대한 구체성 부족.

### 최적화된 프롬프트 접근법

#### 동작 우선순위 설정

```markdown
1. Grounding: 제공된 텍스트에만 의존
2. Evidence Verification: 답변 전 명시적 확인
3. Query Noise Robustness: 노이즈 질문에서 의도 추론
4. OCR Handling: 아티팩트에도 의미 재구성
```

#### 거부 정책 (Refusal Policy)

```markdown
# 거부 케이스 구분

1. Empty or Insufficient Context
   → "제공된 컨텍스트에 이 질문에 답할 정보가 부족합니다."

2. Out-of-Scope Questions
   → "이 질문은 제공된 문서의 범위를 벗어납니다."

3. Incomplete but Inferrable Questions
   → 가능한 범위 내에서 추론하여 답변
```

#### 출력 포맷 사양

```markdown
# 답변 가능한 질문
FINAL: <정확한 답변>
(선택) EVIDENCE: '<컨텍스트에서 인용한 스팬>'

# 거부
FINAL: Insufficient information in the provided context to answer this question.
```

---

## 3. Optimization Workflow

### Playground 도구 사용법

```markdown
1. 최적화 활성화된 OpenAI Playground로 이동
2. Developer Message 섹션에 기존 프롬프트 붙여넣기
3. **Optimize** 버튼 클릭
4. 인라인 설명과 함께 제안된 변경 검토
5. 필요 시 추가 수정 요청
6. **Prompt Object**로 저장 (버전 관리 및 재사용)
```

### 반복적 정제

```markdown
# 지원 기능
- 자동 생성된 개선 수락
- 특정 조정 요청 (예: 싱글패스 스트리밍 강제)
- 상세 변경 설명 보기
- 최종 프롬프트를 버전화된 객체로 내보내기
```

---

## 4. Prompt Optimization Principles

### 핵심 원칙

| 원칙 | 설명 |
|------|------|
| **구체성 > 유연성** | 부드러운 제안보다 명확한 제약 |
| **알고리즘 가이드** | 목표가 아닌 구체적 접근법 권장 |
| **예시 중심 명확성** | 작동하는 코드 샘플 제공 |
| **모순 제거** | 상충되는 지시 제거 |
| **경계 명확성** | 정확한 타이브레이킹 규칙 및 출력 포맷 정의 |

### Before vs After 비교

```markdown
# Before (모호함)
"Prefer the standard library; use external packages if they make things simpler."

# After (명확함)
"Use ONLY Python standard library. External packages are PROHIBITED."
```

```markdown
# Before (모호함)
"Process the file efficiently."

# After (명확함)
"Use single-pass streaming with heapq.nsmallest() for bounded memory.
Maximum heap size: K elements."
```

---

## 5. 비교 방법론

두 벤치마크 모두 다음 사용:

| 항목 | 방법 |
|------|------|
| **다중 실행** | 코딩 30회, QA 다양 (패턴 확립) |
| **정량적 메트릭** | 런타임, 메모리, 정확성, 품질 점수 |
| **LLM-as-Judge 평가** | 준수 및 코드 품질 평가 |
| **Before/After 분석** | 최적화의 격리된 영향 측정 |

---

## 6. 핵심 교훈

### 프롬프트 최적화의 효과

```markdown
Top-K 벤치마크:
- 메모리 84% 감소 (3626KB → 578KB)
- 정확성 유지
- 실행 성공률 +13%

FailSafeQA 벤치마크:
- 노이즈 입력에 대한 견고성 향상
- 거부 정책 준수 개선
```

### 핵심 교훈

```markdown
1. 명시적 제약이 성능 일관성을 크게 향상
2. 구체적 알고리즘 권장이 목표만 제시하는 것보다 효과적
3. 명확한 예시가 모호함을 제거
4. 모순 제거가 추론 토큰 낭비 방지
```

---

## 7. 핵심 요약

| 영역 | 핵심 포인트 |
|------|------------|
| 코딩 벤치마크 | 모순 제거 → 메모리 84% 감소, 성공률 +13% |
| 금융 QA | 동작 우선순위 + 거부 정책 → 견고성 향상 |
| Optimizer 사용 | Playground에서 Optimize → 검토 → 저장 |
| 원칙 | 구체성 > 유연성, 알고리즘 가이드, 예시 중심 |
| 비교 방법 | 다중 실행, LLM-as-Judge, Before/After 분석 |

---

## 참고 자료

- [OpenAI Cookbook 원문](https://cookbook.openai.com/examples/gpt-5/prompt-optimization-cookbook)
- [OpenAI Playground](https://platform.openai.com/playground)
- [Prompt Engineering Guide](https://platform.openai.com/docs/guides/prompt-engineering)
