# GPT-5.5 프롬프트 패턴

## 목차
- [개요 (5.4 → 5.5 핵심 변화)](#개요-54--55-핵심-변화)
- [1. Outcome-First Prompting (신규)](#1-outcome-first-prompting-신규)
- [2. Personality + Collaboration Style 분리 (신규)](#2-personality--collaboration-style-분리-신규)
- [3. Retrieval Budget (신규/강조)](#3-retrieval-budget-신규강조)
- [4. Tool Validation (강조)](#4-tool-validation-강조)
- [5. Markdown 절제 정책 (강조)](#5-markdown-절제-정책-강조)
- [6. Structured Outputs 권장](#6-structured-outputs-권장)
- [7. Image Detail 기본값 변경](#7-image-detail-기본값-변경)
- [8. 5.4 패턴 호환](#8-54-패턴-호환)
- [9. 마이그레이션 전략 (5.4 → 5.5)](#9-마이그레이션-전략-54--55)
- [참고](#참고)


GPT-5.5는 5.4의 드롭인 교체가 아닌 **새 모델 패밀리**. fresh baseline에서 outcome-first로 재작성하는 것이 핵심.
**reasoning effort를 올리기 전에 이 패턴들을 먼저 적용**하세요.

---

## 개요 (5.4 → 5.5 핵심 변화)

| 항목 | 5.4까지 | 5.5 |
|------|---------|------|
| 프롬프트 철학 | Output contract + 단계별 절차 | **Outcome-first** (목표·성공 기준 정의) |
| Reasoning effort 기본 | 작업 형태별 매트릭스 | **`medium` 권장 출발점**, 많은 워크로드는 `low` |
| Verbosity | 별도 권장 없음 | **`text.verbosity = "low"` 권장** |
| Personality | 통합 블록 | **Personality + Collaboration Style 분리** |
| Markdown | 절제 권고 | **plain prose 기본** |
| Retrieval | research_mode 3-pass | **명시적 stopping conditions** |
| 출력 스키마 | 프롬프트 + 검증 | **Structured Outputs API로 강제** |
| Image detail 기본 | `high` | **`original`** (computer use 향상) |
| 마이그레이션 | 드롭인 가능 | **❌ 드롭인 금지**, fresh baseline |

> 상세 가이드: [`reference/openai-prompt-guide/gpt-5.5-prompt-guide.md`](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md)

---

## 1. Outcome-First Prompting (신규)

5.5의 가장 큰 변화. **절차를 미세 명령하는 대신 목표·성공 기준·제약을 정의**하고 경로 선택은 모델에 맡긴다.

> "Shorter, outcome-first prompts usually work better than process-heavy prompt stacks."

### 시스템 프롬프트 권장 구조

```
Role → Personality → Goal → Success criteria →
Constraints → Output shape → Stop rules
```

각 섹션은 짧게. **"Add detail only where it changes behavior."**

### 예시

```xml
<goal>
Resolve the customer's issue end to end. Use available tools when they
materially improve correctness or grounding.
</goal>

<success_criteria>
- The user's stated problem is fixed or a clear blocker is reported.
- Any actions taken are reversible or have been confirmed by the user.
- Output ends with a 1-2 sentence summary of what was done and what
  remains optional.
</success_criteria>

<stop_rules>
- Stop when success criteria are met.
- Resolve the user query in the fewest useful tool loops, but do not
  let loop minimization outrank correctness.
</stop_rules>
```

### Anti-Pattern

- ❌ 단계별 명령: "First inspect A. Then inspect B. Then write..."
- ❌ 절대 규칙 남용: `ALWAYS do X. NEVER do Y. ALWAYS verify Z.`
- ❌ 옛 프롬프트 통째 이월

진정한 불변(safety / honesty / privacy)에만 `ALWAYS`/`NEVER` 사용. 형식·스타일에는 제외.

---

## 2. Personality + Collaboration Style 분리 (신규)

**personality**(어떻게 들리는가)와 **collaboration style**(어떻게 일하는가)을 명시적으로 분리. 각각 1-2문단 이내.

### Personality 4종 (Cookbook prompt_personalities)

| 패턴 | 사용처 | 핵심 표현 |
|------|--------|----------|
| **Professional** | 비즈니스 커뮤니케이션, 엔터프라이즈 | "focused, formal, and exacting" |
| **Efficient** | 개발자 도구, 자동화, CLI | "direct, complete, and easy to parse... DO NOT add extra features" |
| **Fact-Based** | 디버깅, 위험 분석, 리서치 | "Do not guess or fill gaps with fabricated details" |
| **Exploratory** | 학습, 기술 지식 공유 | "Aim to make learning enjoyable and useful" |

### 예시 — Personality (Steady Task-Focused)

```xml
<personality>
You are a capable collaborator: approachable, steady, and direct.
Assume the user is competent and acting in good faith. Stay concise
without becoming curt. Use mild warmth, no flattery, no apology spam.
</personality>
```

### 예시 — Collaboration Style

```xml
<collaboration_style>
- Ask a clarifying question only when the next step is genuinely
  ambiguous and proceeding would waste effort or cause harm.
- For everything else, choose the most reasonable interpretation,
  state your assumption in one line, and proceed.
- Validate work via tools (tests, lint, build) before declaring done.
- Surface blockers early; do not silently swap to a worse approach.
</collaboration_style>
```

### Anti-Pattern

- ❌ Personality에 task logic / domain rules 혼합
- ❌ 과도한 친근함이나 헤징(hedging)으로 신뢰성 훼손
- ❌ Personality를 요청된 artifact(이메일·코드·메모)에 강제 적용

---

## 3. Retrieval Budget (신규/강조)

너무 많이 검색하거나 너무 일찍 멈추는 양극단을 모두 피하기 위한 **명시적 stopping conditions**.

```xml
<retrieval_budget>
For ordinary Q&A, start with one broad search.

Make another retrieval call only when:
- the core question is not yet answered,
- a required fact, parameter, or identifier is missing,
- the user explicitly asked for comprehensive coverage, or
- a contradiction between sources needs to be resolved.

Use the minimum evidence sufficient to answer correctly, cite it
precisely, then stop.
</retrieval_budget>
```

**원칙**: "Resolve the user query in the fewest useful tool loops, but do not let loop minimization outrank correctness."

---

## 4. Tool Validation (강조)

5.5는 **출력 검증을 도구로** 적극 활용할 것을 강조. 단순히 답을 생성하는 것을 넘어, 모델이 자신의 결과를 도구로 확인하도록 권한을 부여.

```xml
<tool_validation>
- Use tools that let you check your own outputs whenever possible.
- For coding agents: run unit tests, lint, build checks before declaring done.
- For visual artifacts: render and inspect for layout, clipping, spacing.
- For numeric outputs: re-derive or sanity-check via calculation tool.
</tool_validation>
```

> "Give GPT-5.5 access to tools that let it check outputs."

---

## 5. Markdown 절제 정책 (강조)

5.5는 markdown 절제를 강하게 권장. 모든 응답을 자동으로 헤더·불릿으로 구조화하지 말 것.

> "Let formatting serve comprehension. Use plain paragraphs as default."

```xml
<formatting_policy>
- Default to plain prose. Use headers, bullets, and bold sparingly.
- Use markdown only when it materially improves comprehension
  (true list, side-by-side comparison, hierarchical reference).
- Respect formatting preferences stated by the user.
- For editing/summarization tasks, preserve the requested artifact's
  length, structure, and genre first.
</formatting_policy>
```

---

## 6. Structured Outputs 권장

5.5에서 **출력 스키마를 프롬프트로 지시하지 말고 Structured Outputs API로 강제**할 것.

```python
response = client.responses.create(
    model="gpt-5.5",
    response_format={
        "type": "json_schema",
        "json_schema": {
            "name": "<schema_name>",
            "schema": { ... },
            "strict": True,
        }
    },
    input=[ ... ],
)
```

이점:
- 프롬프트 토큰 절약 (스키마 설명 제거)
- 정확도 향상 (모델이 스키마를 강제 준수)
- 검증 자동화 (파싱 실패 위험 제거)

프롬프트의 보조 컨트롤이 필요한 경우:

```xml
<structured_output_contract>
- Output only the requested format.
- Do not add prose or markdown fences unless they were requested.
- Validate that parentheses and brackets are balanced.
- Do not invent tables or fields.
- If required schema information is missing, ask for it or return an
  explicit error object.
</structured_output_contract>
```

---

## 7. Image Detail 기본값 변경

5.5에서 이미지 입력의 `image_detail` 기본값이 `high` → **`original`**로 변경됨 (computer use 정확도 향상 목적).

| 값 | 사용처 | 토큰 |
|-----|--------|-----|
| `original` | **5.5 기본**. 컴퓨터 사용, OCR, 클릭 정확도, 대형/밀집 이미지 | 많음 |
| `high` | 표준 고충실도 이해 (일반 차트·문서 분석) | 중간 |
| `low` | 속도/비용이 상세도보다 중요할 때만 | 적음 |

> 단순 차트·문서 분석에서는 토큰 영향 평가 후 **`high` 명시 권장**. 컴퓨터 사용 워크플로우는 그대로 두면 됨.

---

## 8. 5.4 패턴 호환

5.4의 다음 패턴은 5.5에서도 그대로 유효 (단, **outcome-first 프레임 안에 배치**):

- `<output_contract>` / `<verbosity_controls>`
- `<default_follow_through_policy>`
- `<instruction_priority>`
- `<tool_persistence_rules>` / `<dependency_checks>`
- `<parallel_tool_calling>`
- `<completeness_contract>`
- `<empty_result_recovery>`
- `<verification_loop>` / `<missing_context_gating>` / `<action_safety>`
- `<citation_rules>` / `<grounding_rules>` / `<research_mode>`
- `<autonomy_and_persistence>` / `<terminal_tool_hygiene>`

상세는 [`gpt54-patterns.md`](./gpt54-patterns.md) 참조.

5.5에서 새로 추가/강조된 것: §1~§7.

---

## 9. 마이그레이션 전략 (5.4 → 5.5)

> ⚠️ **드롭인 교체 금지**. "Treat it as a new model family, not a drop-in replacement."
> 옛 프롬프트의 효과성은 5.5가 보장하지 않는다.

### 권장 시작 설정

| 현재 | GPT-5.5 시작 |
|------|-------------|
| `gpt-5.4` (일반) | `medium` effort + `low` verbosity, fresh baseline 재구성 |
| `gpt-5.4` (코딩 에이전트) | `medium` effort 유지, outcome-first 재구조화 + tool_validation 추가 |
| `gpt-5.4` (리서치) | `medium` + retrieval_budget 추가 + 단계별 절차 → outcome 재작성 |
| `gpt-5.4` (장기 에이전트) | `medium`/`high` + tool persistence + completeness, xhigh는 eval 후 |
| `gpt-4.1`/`gpt-4o` | `low` 시작, 퇴보 시 `medium` |

### 체크리스트

1. [ ] 모델명 `gpt-5.5`로 변경
2. [ ] **Fresh baseline 재구성** (옛 프롬프트 통째 이월 금지)
3. [ ] `reasoning.effort = "medium"` 출발점
4. [ ] `text.verbosity = "low"` 평가
5. [ ] 출력 스키마 → Structured Outputs API로 이전
6. [ ] 단계별 절차 → outcome-first goal/success_criteria 재작성
7. [ ] Personality + Collaboration Style 분리 (각 1-2문단)
8. [ ] `<retrieval_budget>` 추가 (도구 사용 시)
9. [ ] `<tool_validation>` 추가 (검증 가능한 작업)
10. [ ] Markdown 절제 정책 추가
11. [ ] 시스템 프롬프트의 현재 날짜 제거 (모델이 인식)
12. [ ] Image detail 기본값(`original`) 토큰 영향 평가, 필요 시 `high` 명시

### 자동 마이그레이션 (Codex CLI)

```
$openai-docs migrate this project to gpt-5.5
```

OpenAI Docs Skill이 프로젝트 프롬프트 스택을 5.5 권장에 맞게 자동 변환.

---

## 참고

- [GPT-5.5 Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md) — 전체 가이드 + 외부 노하우
- [GPT-5.5 Prompting Guide (공식)](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Using GPT-5.5 (공식)](https://developers.openai.com/api/docs/guides/latest-model)
- [Prompt Personalities (Cookbook)](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [Simon Willison — GPT-5.5 prompting guide (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
- [GPT-5.4 패턴 (이전 버전)](./gpt54-patterns.md)
