# GPT-5.1 Prompting Guide

> **출처**: [OpenAI Cookbook - GPT-5.1 Prompting Guide](https://cookbook.openai.com/examples/gpt-5/gpt-5-1_prompting_guide)
> **날짜**: 2025-11-13

---

## 개요

GPT-5.1은 에이전트 및 코딩 작업에서 지능과 속도의 균형을 위해 설계된 최신 플래그십 모델.

### 핵심 특징

- **`none` reasoning mode**: 저지연 상호작용을 위한 새로운 모드
- **프롬프트 난이도 보정**: 쉬운 입력에 훨씬 적은 토큰 소비
- **높은 조종성**: 에이전트 동작, 성격, 통신 빈도에 대한 강력한 제어

---

## 1. GPT-5에서 마이그레이션 포인트

| 영역 | 초점 |
|------|------|
| **Persistence** | 지나치게 간결한 응답 방지를 위해 완전성 강조 |
| **Output Formatting** | 원하는 장황함 수준 명시 |
| **Coding Agents** | `apply_patch` 같은 새로운 명명된 도구 구현으로 마이그레이션 |
| **Instruction Following** | 명확하고 충돌 없는 지시로 동작 형성 |

---

## 2. Agentic Steerability (에이전트 조종성)

### Personality 설정

고객 대면 시스템에서 명확한 에이전트 페르소나 정의.

```markdown
# 효과적인 성격 지침

"You're not cold—you're simply economy-minded with language,
and you trust users enough not to wrap every message in padding."

# 권장 특성
- 언어에 경제적인 접근
- 사용자 톤과 대화 중요도에 맞춘 적응적 정중함
- 효율성을 존중하는 직접적이고 모멘텀 중심 커뮤니케이션
```

### User Updates (Preambles) 설정

진행 상황 공유 빈도와 상세도 구성.

```markdown
# 빈도
- 의미 있는 변화가 있을 때마다 짧은 업데이트 (1-2문장)
- 몇 번의 도구 호출마다

# 내용
- 초기 계획
- 발견 사항
- 구체적인 결과
- 긴 실행의 종합

# 구조
- 턴 종료 전 상태 체크리스트와 함께 간단한 요약 포함
```

### Immediacy 패턴

긴 실행에서 인지된 지연 감소:

```markdown
"Always explain what you're doing in a commentary message FIRST,
BEFORE sampling an analysis thinking message."
```

---

## 3. Optimizing Intelligence and Instruction-Following

### 완전한 솔루션 독려

모델이 긴 작업에서 조기 종료할 수 있음. 대응책:

```markdown
"You are an autonomous senior pair-programmer that persists through:
- Implementation
- Verification
- Refinement

WITHOUT waiting for intermediate prompts."
```

### Tool-Calling 모범 사례

| 항목 | 권장 사항 |
|------|----------|
| 도구 정의 | 기능을 간결하게 설명 |
| 사용 시점 | 프롬프트에서 언제/어떻게 사용할지 명시 |
| 예시 | 명확한 도구 사용 패턴 제공 |
| 병렬화 | 가능할 때 병렬 도구 호출 명시적 권장 |

### `none` Reasoning Mode 효율성

추론 토큰 사용을 완전히 방지하는 새로운 모드 (GPT-4.1과 유사).

```markdown
# 권장 가이드라인
- 함수 호출 전에 광범위하게 계획
- 이전 결과를 반영하여 완전한 해결 보장
- 실행 전에 출력이 사용자 제약 충족하는지 검증
```

---

## 4. Maximizing Coding Performance

### Plan Tool 구현

중간/대형 작업에서 2-5개 마일스톤 항목으로 경량 계획 생성 및 유지.

```json
{
  "name": "update_plan",
  "arguments": {
    "merge": true,
    "todos": [
      {
        "content": "실패한 테스트 조사",
        "status": "in_progress",
        "id": "step-1"
      },
      {
        "content": "에러 핸들러 구현",
        "status": "pending",
        "id": "step-2"
      },
      {
        "content": "테스트 통과 확인",
        "status": "pending",
        "id": "step-3"
      }
    ]
  }
}
```

#### 계획 관리 규칙

```markdown
- 한 번에 정확히 하나의 항목만 `in_progress` 표시
- 최대 ~8번의 도구 호출 후 상태 업데이트
- 종료 전 모든 항목 완료 또는 명시적 취소
```

### Design System 적용

프론트엔드 작업에서 하드코딩된 색상 대신 디자인 토큰 적용.

```markdown
# 권장 접근법
- CSS 변수에 연결된 Tailwind 유틸리티 사용
- globals.css에서 디자인 토큰 관리
- 일관된 브랜드 구현 보장

# 예시
✓ className="bg-primary text-primary-foreground"
✗ className="bg-blue-500 text-white"
```

---

## 5. New Tool Types (새로운 도구 유형)

### apply_patch 도구

diff를 사용한 구조화된 파일 편집. Responses API로 관리.

```python
response = client.responses.create(
    model="gpt-5.1",
    input=RESPONSE_INPUT,
    tools=[{"type": "apply_patch"}]
)

# 모델은 apply_patch_call 이벤트 수신
# 작업 유형: create, update, delete
# diff 구현
```

#### 성능 향상

```markdown
명명된 구현 (apply_patch)이 이전 접근법 대비
실패율 35% 감소
```

### shell 도구

명령줄 인터페이스와의 모델 상호작용 허용.

```python
response = client.responses.create(
    model="gpt-5.1",
    input=messages,
    tools=[{"type": "shell"}]
)

# shell_call 객체 반환
# - commands: 실행할 명령
# - timeout: 타임아웃 설정
# - max_output_length: 최대 출력 길이

# 시스템이 명령 실행 후 반환
# - stdout
# - stderr
# - exit_codes
```

---

## 6. Metaprompting Effectively

### 2단계 디버깅 프로세스

**Step 1 - 근본 원인 분석**:
```markdown
시스템 프롬프트, 실패 예시 제공 후:

"Identify specific prompt sections driving these failures.
Don't propose solutions yet—just point to the problems."
```

**Step 2 - 수술적 수정**:
```markdown
분석 기반으로:

"Based on the analysis, request small, explicit edits
that clarify conflicting rules without full redesign."
```

### 이 접근법의 장점

- 모델이 지시의 모순과 중복을 직접 지적
- 수동 추측보다 효과적
- 전체 재설계 없이 정밀한 수정 가능

### 실용적 예시 구조 (이벤트 플래닝 에이전트)

```markdown
1. 간결한 핵심 목표로 시작
2. 명확한 범위와 톤 가이드라인 정의
3. 도구 사용 계층 지정 (도구 vs 내부 지식 선호 시점)
4. 데이터셋에서 긍정(해야 할 것)과 부정(하지 말아야 할 것) 분리
5. 세밀한 평가를 위한 정확한 태깅 사용
```

---

## 7. 구현 하이라이트

| 영역 | 핵심 포인트 |
|------|------------|
| Verbosity | 전용 컨트롤 + 프롬프트에 구체적 길이 지침 |
| Personality | 경제적 언어, 사용자 신뢰, 패딩 없음 |
| Tool Reliability | apply_patch로 실패율 35% 감소 |
| Parallel Efficiency | GPT-5.1은 병렬 도구 호출 더 효율적 실행 |

---

## 8. 핵심 요약

| 영역 | 핵심 포인트 |
|------|------------|
| none mode | 추론 토큰 0, GPT-4.1과 유사, 계획 + 검증 필수 |
| Personality | economy-minded, 적응적 정중함, 모멘텀 중심 |
| User Updates | 1-2문장, 주요 전환점에서, 상태 체크리스트 |
| Plan Tool | 2-5 마일스톤, 하나씩 in_progress, 8호출마다 업데이트 |
| apply_patch | Responses API로 관리, 35% 실패율 감소 |
| shell | 명령 실행 + stdout/stderr/exit_codes 반환 |
| Metaprompt | 2단계: 근본 원인 분석 → 수술적 수정 |

---

## 참고 자료

- [OpenAI Cookbook 원문](https://cookbook.openai.com/examples/gpt-5/gpt-5-1_prompting_guide)
- [GPT-5.1 블로그 포스트](https://openai.com/blog)
- [Responses API 문서](https://platform.openai.com/docs/api-reference/responses)
