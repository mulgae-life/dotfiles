# GPT-4.1 Prompting Guide

> **출처**: [OpenAI Cookbook - GPT-4.1 Prompting Guide](https://cookbook.openai.com/examples/gpt4-1_prompting_guide)
> **작성자**: Noah MacCallum, Julian Lee
> **날짜**: 2025-04-14

---

## 개요

GPT-4.1 패밀리는 코딩, 지시 따르기, 긴 컨텍스트 처리에서 GPT-4o 대비 큰 발전을 이룸. SWE-bench Verified에서 55% 달성.

---

## 1. Agentic Workflows (에이전트 워크플로우)

GPT-4.1은 에이전트 기반 문제 해결에 탁월함. 시스템 프롬프트에 세 가지 핵심 리마인더 권장:

### 필수 리마인더

| 항목 | 설명 |
|------|------|
| **Persistence** | 문제가 해결될 때까지 계속 진행 |
| **Tool-calling** | 추측하지 말고 도구 사용 |
| **Planning** | 행동 전에 먼저 생각 |

### 도구 정의 권장사항

```python
# ✓ 권장: API의 tools 필드 사용
response = client.chat.completions.create(
    model="gpt-4.1",
    messages=messages,
    tools=[{
        "type": "function",
        "function": {
            "name": "search_codebase",
            "description": "코드베이스에서 관련 파일 검색",
            "parameters": {...}
        }
    }]
)

# ✗ 비권장: 수동으로 도구 설명 주입
system_prompt = "You have access to the following tools: ..."
```

---

## 2. Long Context (긴 컨텍스트)

### 성능 특성

- **지원**: 1M 토큰까지 효과적 처리
- **한계**: 전체 컨텍스트에 걸친 복잡한 추론 시 성능 저하

### 최적화 전략

```markdown
# 지시사항 배치
- 긴 문서의 시작과 끝 양쪽에 지시사항 배치

# 포맷 선택
✓ XML 또는 파이프 구분자 사용
✗ JSON은 문서 포맷팅에 비권장
```

### 문서 포맷 예시

```xml
<!-- 권장: XML 포맷 -->
<documents>
  <document id="1">
    <title>보고서 A</title>
    <content>...</content>
  </document>
  <document id="2">
    <title>보고서 B</title>
    <content>...</content>
  </document>
</documents>
```

---

## 3. Chain of Thought (사고 사슬)

GPT-4.1은 추론 모델은 아니지만 단계별 프롬프팅으로 출력 개선 가능.

### 효과적인 프롬프트

```markdown
# 간단한 지시
"Think carefully step by step about this problem."

# 명시적 계획 요청
"Before answering, outline your approach:
1. Identify the key components
2. Analyze each component
3. Synthesize the findings"
```

---

## 4. Instruction Following (지시 따르기)

GPT-4.1은 이전 모델보다 **더 문자 그대로** 지시를 따름.

### 권장 워크플로우

```
1. 고수준 "Response Rules" 작성
   ↓
2. 특정 동작 섹션 추가
   ↓
3. 순서가 있는 단계 포함
   ↓
4. 충돌 디버그 + 예시 추가
```

### 프롬프트 구조화

```markdown
## Role
당신은 코드 리뷰 전문가입니다.

## Instructions
1. 먼저 전체 코드를 분석합니다
2. 보안 취약점을 식별합니다
3. 개선 제안을 제공합니다

## Reasoning Steps
- 각 함수의 목적 파악
- 입력 검증 확인
- 에러 처리 검토

## Output Format
```json
{
  "issues": [...],
  "suggestions": [...],
  "score": 0-10
}
```

## Examples
[예시 코드 및 출력]
```

---

## 5. 프롬프트 구조화 일반 조언

### 섹션 구분

- **마크다운** 또는 **XML 구분자** 사용
- JSON은 문서 목록에 비권장

### 필수 섹션

| 섹션 | 목적 |
|------|------|
| Role | 모델의 역할 정의 |
| Instructions | 구체적인 지시사항 |
| Reasoning Steps | 사고 과정 가이드 |
| Output Format | 출력 형식 지정 |
| Examples | 참조 예시 |

---

## 6. apply_patch 도구 (Diff 포맷)

코드 편집을 위한 V4A diff 포맷 사용. 라인 번호 대신 컨텍스트 기반 식별.

### 형식

```diff
*** Begin Patch
*** Update File: src/utils.py
@@@ Context line before change
- line to remove
+ line to add
@@@ Another context line
*** End Patch
```

### 핵심 원칙

1. **변경 사항 철저히 검증**
2. **숨겨진 테스트의 엣지 케이스 처리**
3. **컨텍스트 라인으로 결정론적 패칭**

---

## 7. 핵심 요약

| 영역 | 핵심 포인트 |
|------|------------|
| Agentic | 지속성 + 도구 사용 + 계획 리마인더 |
| Long Context | 시작/끝에 지시, XML/파이프 포맷 |
| CoT | "step by step" 프롬프트 |
| Instruction | 문자 그대로 해석, 충돌 제거 필수 |
| Tool Use | API tools 필드 사용 권장 |
| Diff | apply_patch + V4A 포맷 |

---

## 참고 자료

- [OpenAI Cookbook 원문](https://cookbook.openai.com/examples/gpt4-1_prompting_guide)
- [OpenAI API 문서](https://platform.openai.com/docs)
