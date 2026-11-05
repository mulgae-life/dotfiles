# GPT-5 Prompting Guide

> **출처**: [OpenAI Cookbook - GPT-5 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
> **날짜**: 2025-08-07

---

## 개요

GPT-5는 에이전트 작업 성능, 코딩 능력, 원시 지능, 조종성(steerability)에서 상당한 도약을 이룸.

### 핵심 발전

- **에이전트 작업**: 더 예측 가능한 워크플로우
- **코딩**: 프론트엔드 + 소프트웨어 엔지니어링 최적화
- **조종성**: 프롬프트 지시에 매우 민감하게 반응
- **Responses API**: 추론 컨텍스트 유지로 성능 향상

---

## 1. Agentic Workflow Predictability

### Eagerness 스펙트럼

GPT-5는 완전 위임부터 엄격한 프로그래매틱 분기까지 조절 가능.

#### Less Eagerness (덜 적극적)

```markdown
# 방법
- reasoning_effort 파라미터 낮추기
- 탐색 공간 기준 명확히 정의
- 고정 도구 호출 예산 설정
- 불확실해도 진행할 수 있는 탈출구 제공

# 예시 프롬프트
"If you cannot find the exact information after 3 search attempts,
proceed with your best assessment and note the uncertainty."
```

#### More Eagerness (더 적극적)

```markdown
# 방법
- reasoning_effort 높이기
- 지속성 프롬프트로 완전 해결까지 진행
- 명시적 중단 조건 정의
- 안전/위험 동작 구분

# 도구별 불확실성 임계값 차별화
- 검색 도구: 낮은 확인 필요
- 결제 도구: 높은 사용자 확인 필요
```

### Tool Preambles (도구 서문)

GPT-5는 도구 호출 전 명확한 계획과 진행 업데이트 생성.

```markdown
# 권장 패턴
1. 사용자 목표 재진술
2. 구조화된 단계별 계획 개요
3. 실행 진행 상황 순차적 서술
4. 완료된 작업을 초기 계획과 구분하여 요약
```

### Responses API 활용

`previous_response_id`로 도구 호출 간 추론 컨텍스트 유지.

```python
# Responses API 사용 예시
response = client.responses.create(
    model="gpt-5",
    input=messages,
    previous_response_id=previous_id,  # 컨텍스트 유지
    reasoning_effort="medium"
)

# 성능 향상 사례
# Tau-Bench Retail: 73.9% → 78.2% (API 전환 + previous_response_id)
```

---

## 2. Maximizing Coding Performance

### 프론트엔드 앱 개발

GPT-5는 우수한 기본 미학 감각 + 엄격한 구현력 보유.

#### 권장 스택

| 카테고리 | 권장 도구 |
|----------|-----------|
| Frameworks | Next.js (TypeScript), React, HTML |
| Styling | Tailwind CSS, shadcn/ui, Radix Themes |
| Icons | Material Symbols, Heroicons, Lucide |
| Animation | Motion |

### Zero-to-One 앱 생성

```markdown
# 자기 성찰 프롬프트
"Before implementing, spend time thinking of a rubric until you are confident.
Develop a 5-7 category excellence rubric internally, then proceed."

# 예시 루브릭 카테고리
1. 코드 구조 및 모듈성
2. 에러 처리
3. 성능 최적화
4. 접근성
5. 테스트 가능성
6. 보안
7. 유지보수성
```

### 코드베이스 디자인 표준 매칭

GPT-5는 이미 코드베이스에서 참조 컨텍스트를 검색하지만, 명시적 지시로 개선 가능.

```markdown
## Guiding Principles
- 명확성, 재사용, 일관성, 단순성, 데모 지향 구조

## Frontend Stack Defaults
- 특정 도구 선택, 디렉토리 구조, 컨벤션

## UI/UX Best Practices
- 시각적 계층, 색상 사용, 간격, 상태 처리, 접근성
```

### Cursor 사례 연구

AI 코드 에디터 Cursor의 GPT-5 프롬프트 최적화 접근법:

| 문제 | 해결책 |
|------|--------|
| 장황한 출력 | `verbosity`를 low로 설정, 코딩 도구에서만 verbose |
| 과도한 사용자 확인 | 제품 동작 상세 + 기능 스펙 포함 |
| 불필요한 도구 사용 | 최대 철저함 강조 프롬프트 조정 |
| 지시 준수 개선 | `<[instruction]_spec>` 같은 구조화된 XML 스펙 사용 |

---

## 3. Optimizing Intelligence and Instruction-Following

### Verbosity 파라미터

새로운 API 파라미터로 최종 답변 길이 조절 (추론 길이와 별개).

```python
response = client.responses.create(
    model="gpt-5",
    input=messages,
    verbosity="low"  # low, medium, high
)
```

**컨텍스트별 조정**:
```markdown
# Cursor 접근법
- 전역: verbosity=low
- 코딩 도구에서만: "provide verbose, detailed code explanations"
```

### Instruction Following

GPT-5는 **"surgical precision"**으로 지시를 따름. 모순이 있으면 추론 토큰을 소모하며 조정 시도.

#### 문제가 있는 프롬프트 예시

```markdown
# 의료 보조 프롬프트의 모순

❌ 모순 1:
- "Never schedule without explicit patient consent"
- "Auto-assign the earliest same-day slot without contacting the patient"

❌ 모순 2:
- "Always look up the patient profile first"
- "Escalate as EMERGENCY...before any scheduling step"

✓ 해결:
- 지시 계층 명확화
- 자동 할당은 "환자에게 알린 후"로 변경
- 응급 상황에서는 예외 명시적 허용
```

### Minimal Reasoning

가장 빠른 옵션. 추론 모델 이점 유지하면서 속도 최적화.

```markdown
# 권장 사항
1. 답변 시작에 사고 과정 요약하는 간단한 설명 요청
2. 진행 업데이트 제공하는 철저한 도구 호출 서문 요청
3. 도구 지시 명확화 + 에이전트 지속성 리마인더 삽입
4. 프롬프트된 계획 사용 (내부 계획 토큰 적음)
```

### Markdown 포맷팅

기본적으로 GPT-5 API 응답은 Markdown 미사용 (개발자 호환성).

```markdown
# Markdown 유도 지시
"Use Markdown **only where semantically correct**:
- Headers for sections (## or ###)
- Code blocks for code (```language)
- Bold for emphasis (**text**)
- Lists for enumerations"

# 주의: 긴 대화에서 Markdown 준수 저하 가능
# 해결: 3-5 사용자 메시지마다 지시 재첨부
```

---

## 4. Metaprompting

GPT-5를 사용해 자체 프롬프트 최적화 가능.

### 메타프롬프트 템플릿

```markdown
When asked to optimize prompts, give answers from your own perspective:

- Explain what specific phrases could be added to, or deleted from,
  this prompt to more consistently elicit the desired behavior
  or prevent the undesired one.

- Focus on concrete, actionable changes rather than general advice.

- Point out contradictions or redundancies in the current instructions.
```

---

## 5. Appendix: 주요 프롬프트 예시

### SWE-Bench Verified 개발자 지시

```markdown
## apply_patch 사용 지침

V4A diff 포맷으로 코드 편집:
- 라인 번호 대신 컨텍스트 기반 식별
- 변경 사항 철저히 검증
- 숨겨진 테스트의 엣지 케이스 처리
- 결정론적 패칭을 위한 컨텍스트 라인 사용
```

### Tau-Bench Retail 에이전트 지시

```markdown
## 워크플로우 단계

1. 어떤 동작 전에 사용자 신원 인증
2. 인증 후에만 정보 제공
3. DB 업데이트 전 작업 상세 목록 + 명시적 사용자 확인 획득
4. 한 번에 최대 하나의 도구 호출
5. 에이전트 범위 초과 요청만 사람에게 전달
```

### Terminal-Bench 프롬프트

```markdown
## 코딩 에이전트 지침 (컨테이너 환경)

- 표면적 패치 대신 근본 원인 수정
- 기존 코드베이스 스타일과 일관성 유지
- 최소한의 집중된 변경
- 핸드오프 전 정리 (스크래치 파일 복원, 인라인 주석 제거)
```

---

## 6. 핵심 요약

| 영역 | 핵심 포인트 |
|------|------------|
| Eagerness | reasoning_effort + 탈출구 + 도구 예산 |
| Tool Preambles | 계획 → 실행 → 요약 패턴 |
| Responses API | previous_response_id로 컨텍스트 유지 |
| Coding | Cursor 사례: verbosity 분리, XML 스펙 |
| Instruction | 모순 제거 필수, surgical precision |
| Minimal Reasoning | 간단한 설명 + 도구 서문 + 프롬프트 계획 |
| Metaprompting | GPT-5로 자체 프롬프트 최적화 |

---

## 참고 자료

- [OpenAI Cookbook 원문](https://cookbook.openai.com/examples/gpt-5/gpt-5_prompting_guide)
- [Responses API 문서](https://platform.openai.com/docs/api-reference/responses)
