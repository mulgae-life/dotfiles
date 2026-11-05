# GPT-5.5 Prompting Guide

> **출처**:
> - [Using GPT-5.5 | OpenAI API (5.5 전용 원문)](https://developers.openai.com/api/docs/guides/latest-model/gpt-5.5.md) — 버전 없는 `prompt-guidance/`·`latest-model` 주소는 이제 최신 모델(GPT-6) 문서를 보여준다
> - [GPT-5.5 모델 페이지 | OpenAI API](https://developers.openai.com/api/docs/models/gpt-5.5)
> - [Prompt Personalities | OpenAI Cookbook](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
> - [GPT-5.5 prompting guide | Simon Willison (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
>
> **날짜**: 2026-04-26 (2026-10-01 공식 원문 대조로 API 예시·날짜 예외·과도한 의무 표현 정정)
> **이전 버전**: [GPT-5.4 Prompting Guide](../archive/openai-prompt-guide/gpt-5.4-prompt-guide.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.4 → 5.5 핵심 변화)

GPT-5.5는 **5.2·5.4의 단순 교체가 아니라 새로 맞춰야 할 모델 패밀리**로 다뤄야 한다. 공식 권고:

> "treat it as a new model family to tune for, not a drop-in replacement for `gpt-5.2` or `gpt-5.4`."
> "Begin migration with a fresh baseline instead of carrying over every instruction from an older prompt stack."
> "Start with the smallest prompt that preserves the product contract, then tune reasoning effort, verbosity, tool descriptions, and output format against representative examples."

기존 5.4 프롬프트를 그대로 가져오면 5.5의 효율 향상을 활용하지 못하고, 오히려 과도한 절차 지시 때문에 추론 토큰을 낭비할 수 있다. 옛 프롬프트의 효과성은 5.5에서 보장되지 않으므로 검증 없이 호환을 가정하지 않는다.

### 한 페이지 변화 요약

| 항목 | 5.4까지 | 5.5 |
|------|---------|------|
| 프롬프트 철학 | Output contract + 단계별 절차 명시 | **Outcome-first**, 목표·성공 기준 정의 후 경로는 모델이 선택 |
| Reasoning effort 기본 | 작업 형태별 매트릭스 | **`medium` 권장 출발점**, 많은 워크로드는 `low`도 충분 |
| Verbosity | 별도 권장 없음 | API 기본 `medium`, **간결한 응답에는 `low`가 나은 출발점** |
| Personality 정의 | 통합 personality 블록 | **Personality + Collaboration Style 분리** (둘 다 짧게) |
| Markdown | 절제 권고 | **일반 대화·설명은 평문 단락 기본**, 헤더·불릿 sparingly |
| Retrieval | research_mode 3-pass | **명시적 stopping conditions** (`<retrieval_budget>`) |
| 출력 스키마 | 프롬프트 + 검증 | **가능하면 Structured Outputs** |
| 이미지 `detail` 미지정·`auto` | `high` 동작 | **`original` 동작** (computer use 정확도 향상) |
| 마이그레이션 | 5.2 → 5.4 단순 교체 | **검증 없는 단순 교체를 가정하지 않음**, 최소 프롬프트로 새 기준선 |
| Anti-pattern | - | 불필요한 `ALWAYS`/`NEVER`, "First A then B" 단계 명령, 옛 프롬프트 이월 |

---

## 개요

GPT-5.5는 동일 reasoning effort에서 **이전 모델보다 적은 reasoning 토큰**으로 동등하거나 더 나은 결과를 내는 효율 모델. 대규모 도구 환경에서의 도구 선택 정확도, 더 정제된 응답 톤, outcome-first 프롬프트에서의 강한 성능이 특징.

### 핵심 강점

- 효율적 추론 (동일 effort에서 토큰 사용 감소)
- Outcome-first 프롬프트에서 강한 성능
- 대규모 도구 환경에서 정확한 도구 선택 + 인자 사용
- 다단계 실행이 필요한 코딩 작업
- 장문맥 검색 안정성
- 더 가독성 높은 응답 (스캐폴딩 감소)

### 명시적 프롬프팅이 여전히 필요한 영역

- Personality와 Collaboration Style의 명확한 분리
- Retrieval Budget / Stopping Conditions
- 출력 검증을 위한 도구 호출 권한
- 의존성 인식 워크플로우의 prerequisite 확인
- 마이그레이션 시 fresh baseline 재구성

---

## 1. Reasoning Effort 선택 (5.5 권장 변경)

5.4의 작업 형태별 매트릭스에서 **`medium`을 권장 출발점**으로 정렬됨. 동일 effort에서 5.5가 더 적은 토큰을 쓰므로 5.4의 분류가 그대로 들어맞지 않는다.

| 설정 | 5.5 권장 사용 |
|------|--------------|
| `none` | latency-critical 작업 (음성 턴, 빠른 정보 검색, 분류). **도구 사용·계획·다단계 결정이 의미 있다면 `low` 먼저 평가** |
| `low` | 많은 워크로드의 새 출발점. tool use, 가벼운 계획, 다단계 결정 |
| `medium` | **공식 권장 출발점**. 품질·신뢰성·지연시간·비용의 균형 |
| `high` | 강한 추론 필요, eval에서 medium 대비 명확한 이점 확인 후 |
| `xhigh` | 장기 에이전트 추론 작업, 명확한 eval 이점 확인 후 |

> "Treat `medium` as the recommended balanced starting point for quality, reliability, latency, and cost."

**이전 매트릭스(5.4)와의 차이**: 5.4는 `none`을 실행 중심, `medium`을 연구 중심으로 작업 형태로 분류했지만, 5.5는 `medium`을 디폴트로 두고 거기서 작업 형태에 따라 위아래로 조정하는 접근. 5.5는 효율 향상 덕에 `low` 평가가 먼저 와야 한다.

공식 문서는 effort가 높다고 자동으로 나아지지 않는다고 경고한다. 지시가 충돌하거나 중단 기준이 약하거나 도구 접근이 열려 있으면 높은 effort가 과잉 사고, 불필요한 검색, 출력 품질 저하로 이어질 수 있다("Higher reasoning effort isn't automatically better.").

그래서 effort를 올리기 전에 관찰된 실패에 맞는 지시만 보완하고 비교한다. 블록을 한꺼번에 넣지 않는다. 후보:
1. `<completeness_contract>` (완성도 계약) — 항목 누락이 보일 때
2. `<verification_loop>` (검증 루프) — 검증 없이 끝낼 때
3. `<tool_persistence_rules>` (도구 지속성 규칙) — 도구 호출을 일찍 멈출 때
4. `<retrieval_budget>` (검색 예산) — 검색이 과하거나 부족할 때 (5.5 신규)

---

## 2. Verbosity 권장 (5.5 신규)

5.5는 `text.verbosity` 파라미터를 의도적으로 사용할 것을 권장.

- **API 기본값**: `medium`
- **간결한 응답의 출발점**: `low`가 나은 경우가 많다("`low` is often a better starting point for concise responses"). 5.5의 `low`는 5.4의 `low`보다 비례적으로 더 짧다
- 최종 답 길이는 추론 품질과 별개로 다룬다. 단어 수, 섹션 수, 표 너비, JSON 전용 출력처럼 필요한 길이 조건을 명시
- 응답이 짧아도 핵심 추론·증거·완료 체크는 누락시키지 말 것

```xml
<verbosity_controls>
- Prefer concise, information-dense writing.
- Avoid repeating the user's request.
- Keep progress updates brief.
- Do not shorten the answer so aggressively that required evidence,
  reasoning, or completion checks are omitted.
</verbosity_controls>
```

---

## 3. Outcome-First Prompting (5.5 핵심 신규)

5.5의 가장 큰 변화. **절차를 미세하게 명령하는 대신 목표·성공 기준·제약을 정의하고 경로 선택은 모델에 맡긴다.**

> "GPT-5.5 works best when prompts define the outcome and leave room for the model to choose an efficient solution path. Compared with earlier models, you can often use shorter, more outcome-oriented prompts"

정확한 경로 자체가 제품 요구이면 단계를 지시해도 된다("Avoid step-by-step process guidance unless the exact path matters.").

### 3.1 시스템 프롬프트 권장 구조

```
Role → Personality → Goal → Success criteria →
Constraints → Output shape → Stop rules
```

각 섹션은 짧게. **"Add detail only where it changes behavior."**

### 3.2 Outcome-First 예시

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

### 3.3 Anti-Pattern (피할 것)

```xml
<!-- ❌ 5.4 이전 스타일의 단계별 명령 -->
First inspect file A. Then inspect file B. Then write your plan in
section 1. Then list pros and cons in section 2.
```

```xml
<!-- ❌ 절대 규칙 남용 -->
ALWAYS do X. NEVER do Y. ALWAYS verify Z. ALWAYS cite sources. NEVER
make up information. ALWAYS use bullet lists. ...
```

> "Avoid carrying over every instruction from an older prompt stack."

`ALWAYS`·`NEVER`·`must`·`only`는 진짜 불변 조건에 쓴다. 공식 예시는 안전 규칙, 필수 출력 필드, 절대 일어나면 안 되는 행동이다("Use those words for true invariants, such as safety rules, required output fields, or actions that should never happen."). 언제 검색할지, 언제 되물을지, 도구를 쓸지, 계속 반복할지 같은 판단에는 결정 규칙을 쓴다.

---

## 4. Personality + Collaboration Style 분리 (5.5 신규)

5.5는 **personality**(어떻게 들리는가)와 **collaboration style**(어떻게 일하는가)을 명시적으로 분리할 것을 권장. 공식 권고는 "Keep both short."이고, 어느 쪽도 목표·성공 기준·도구 규칙·중단 조건을 대신하지 않는다. 기본 문체가 효율적·직접적이므로 고객 대면·지원·코칭·대화형 제품에서 특히 필요하다.

### 4.1 Personality 분류 (Cookbook prompt_personalities 4종)

| 패턴 | 사용처 | 핵심 표현 |
|------|--------|----------|
| **Professional** | 비즈니스 커뮤니케이션, 엔터프라이즈 워크플로우 | "focused, formal, and exacting that strives for comprehensiveness" |
| **Efficient** | 개발자 도구, 자동화, CLI | "direct, complete, and easy to parse... DO NOT add extra features" |
| **Fact-Based** | 디버깅, 위험 분석, 리서치 어시스턴트 | "Do not guess or fill gaps with fabricated details. If you are unsure, say so" |
| **Exploratory** | 학습, 기술 지식 공유, 내부 enablement | "Aim to make learning enjoyable and useful by balancing depth with approachability" |

### 4.2 Personality 블록 예시 (Steady Task-Focused)

공식 예시 원문:

```text
# Personality
You are a capable collaborator: approachable, steady, and direct. Assume the user is competent and acting in good faith, and respond with patience, respect, and practical helpfulness.

Prefer making progress over stopping for clarification when the request is already clear enough to attempt. Use context and reasonable assumptions to move forward. Ask for clarification only when the missing information would materially change the answer or create meaningful risk, and keep any question narrow.

Stay concise without becoming curt. Give enough context for the user to understand and trust the answer, then stop. Use examples, comparisons, or simple analogies when they make the point easier to grasp. When correcting the user or disagreeing, be candid but constructive. When an error is pointed out, acknowledge it plainly and focus on fixing it.

Match the user's tone within professional bounds. Avoid emojis and profanity by default, unless the user explicitly asks for that style or has clearly established it as appropriate for the conversation.
```

공식 문서에는 표현력 있는 협업형 예시("Adopt a vivid conversational presence...")도 있다. 표현력을 더할 때도 블록은 짧게 두고, 불분명한 목표를 personality로 메우지 않는다.

### 4.3 Collaboration Style 블록 예시

레포 적용 예시(공식 원문 아님):

```xml
<collaboration_style>
- Ask a clarifying question only when the next step is genuinely
  ambiguous and proceeding would waste effort or cause harm.
- For everything else, choose the most reasonable interpretation,
  state your assumption in one line, and proceed.
- Run the most relevant validation available before declaring done.
- Surface blockers early; do not silently swap to a worse approach.
</collaboration_style>
```

### 4.4 Anti-Pattern

- Personality에 task logic / domain rules 혼합 ("Professional이면서 SQL 쿼리는 항상 PostgreSQL로 작성" → 분리)
- 과도한 친근함이나 헤징(hedging)으로 신뢰성 훼손
- Personality를 요청된 artifact(이메일·코드·메모)에 강제 적용
- 미확인 정보로 빈틈 채우기 (특히 fact-based 시나리오)

---

## 5. Retrieval Budget / Stopping Conditions (5.5 강조)

5.5는 너무 많이 검색하거나 너무 일찍 멈추는 양극단을 모두 피하기 위해 **명시적 retrieval budget**을 권장. 공식 문서는 이를 "검색의 중단 규칙"으로 설명한다("Retrieval budgets are stopping rules for search."). 공식 예시 원문:

```text
For ordinary Q&A, start with one broad search using short, discriminative keywords. If the top results contain enough citable support for the core request, answer from those results instead of searching again.

Make another retrieval call only when:
- The top results do not answer the core question.
- A required fact, parameter, owner, date, ID, or source is missing.
- The user asked for exhaustive coverage, a comparison, or a comprehensive list.
- A specific document, URL, email, meeting, record, or code artifact must be read.
- The answer would otherwise contain an important unsupported factual claim.

Do not search again to improve phrasing, add examples, cite nonessential details, or support wording that can safely be made more generic.
```

**원칙**: "Resolve the user query in the fewest useful tool loops, but do not let loop minimization outrank correctness, accessible fallback evidence, calculations, or required citation tags for factual claims."

각 결과 뒤에 묻게 한다: "After each result, ask: 'Can I answer the user's core request now with useful evidence and citations for the factual claims?' If yes, answer." 증거가 없다는 사실을 곧바로 "아니다"라는 사실 판단으로 바꾸지 않는다("Absence of evidence shouldn't automatically become a factual 'no.'"). 증거 부족 시 동작: "Use the minimum evidence sufficient to answer correctly, cite it precisely, then stop."

창작형 초안(슬라이드, 출시 문구, 고객 요약 등)은 출처로 뒷받침할 사실과 자유롭게 써도 되는 표현을 구분하게 한다. 근거가 부족하면 지어낸 구체 수치 대신 자리표시자나 가정을 밝힌 일반 초안을 쓰게 한다(공식 "Creative drafting guardrails").

---

## 6. Core Prompt Patterns (5.4에서 유지, outcome-first 프레임 안에 배치)

5.4 가이드의 패턴은 5.5에서도 쓸 수 있다. 단 **outcome-first 프레임 안에 들어가야** 하며, 단계별 명령으로 변질되어선 안 된다. 이 절과 §7.2~§12의 블록은 5.4 세대 적용 예시이고 5.5 공식 문서의 권장문이 아니므로, 관찰된 실패에 맞는 것만 골라 쓴다.

### 6.1 Output Contract

```xml
<output_contract>
- Return exactly the sections requested, in the requested order.
- If the prompt defines a preamble, analysis block, or working section,
  do not treat it as extra output.
- Apply length limits only to the section they are intended for.
- If a format is required (JSON, Markdown, SQL, XML), output only that format.
</output_contract>
```

### 6.2 Default Follow-Through Policy

```xml
<default_follow_through_policy>
- If the user's intent is clear and the next step is reversible and
  low-risk, proceed without asking.
- Ask permission only if the next step is:
  (a) irreversible,
  (b) has external side effects, or
  (c) requires missing sensitive information or material choices.
- If proceeding, briefly state what you did and what remains optional.
</default_follow_through_policy>
```

### 6.3 Instruction Priority

```xml
<instruction_priority>
- User instructions override default style, tone, formatting, and
  initiative preferences.
- Safety, honesty, privacy, and permission constraints do not yield.
- If a newer user instruction conflicts with an earlier one, follow
  the newer instruction.
- Preserve earlier instructions that do not conflict.
</instruction_priority>
```

### 6.4 Mid-Conversation Updates

```xml
<task_update>
For the next response only:
- Do not complete the task.
- Only produce a plan.
- Keep it to 5 bullets.
All earlier instructions still apply unless they conflict with this update.
</task_update>
```

---

## 7. Tool Use Patterns

5.4 가이드의 패턴은 그대로 유효. 5.5에서 더 강조되는 점:

### 7.1 출력 검증을 도구로 (5.5 강조)

> "Give GPT-5.5 access to tools that let it check outputs when validation is possible."

모든 검사를 매번 강제하지 않고 변경과 관련된 검증을 고르게 한다. 공식 예시 원문(코딩 에이전트):

```text
After making changes, run the most relevant validation available:
- targeted unit tests for changed behavior
- type checks or lint checks when applicable
- build checks for affected packages
- a minimal smoke test when full validation is too expensive

If validation cannot be run, explain why and describe the next best check.
```

시각 산출물:

```text
Render the artifact before finalizing. Inspect the rendered output for layout, clipping, spacing, missing content, and visual consistency. Revise until the rendered output matches the requirements.
```

구현 계획은 요구사항별 반영 위치, 관련 파일·API, 상태 전이, 검증 명령, 실패 동작, 개인정보·보안 고려, 구현에 영향을 주는 열린 질문을 담게 하면 추적하기 쉽다(공식 예시).

도구별 지침은 대부분 도구 설명 자체에 둔다(무엇을 하는지, 언제 쓰는지, 필수 입력, 부작용, 재시도 안전성, 흔한 오류). 시스템 지시에는 여러 도구에 걸치거나 운영 정책을 바꾸는 내용만 넣는다.

### 7.2 Tool Persistence Rules

```xml
<tool_persistence_rules>
- Use tools whenever they materially improve correctness, completeness,
  or grounding.
- Do not stop early when another tool call is likely to materially improve
  correctness or completeness.
- Keep calling tools until:
  (1) the task is complete, and
  (2) verification passes.
- If a tool returns empty or partial results, retry with a different strategy.
</tool_persistence_rules>

<dependency_checks>
- Before taking an action, check whether prerequisite discovery, lookup,
  or memory retrieval steps are required.
- Do not skip prerequisite steps just because the final action seems obvious.
- If the task depends on the output of a prior step, resolve that
  dependency first.
</dependency_checks>
```

### 7.3 Parallel vs Sequential

```xml
<parallel_tool_calling>
- When multiple retrieval or lookup steps are independent, prefer parallel
  tool calls to reduce wall-clock time.
- Do not parallelize steps that have prerequisite dependencies.
- After parallel retrieval, pause to synthesize before making more calls.
- Prefer selective parallelism: parallelize independent evidence gathering,
  not speculative or redundant tool use.
</parallel_tool_calling>
```

### 7.4 Completeness Contract

```xml
<completeness_contract>
- Treat the task as incomplete until all requested items are covered or
  explicitly marked [blocked].
- Keep an internal checklist of required deliverables.
- For lists, batches, or paginated results:
  - determine expected scope when possible,
  - track processed items or pages,
  - confirm coverage before finalizing.
- If any item is blocked by missing data, mark it [blocked] and state
  exactly what is missing.
</completeness_contract>
```

### 7.5 Empty Result Recovery

```xml
<empty_result_recovery>
If a lookup returns empty, partial, or suspiciously narrow results:
- do not immediately conclude that no results exist,
- try at least one or two fallback strategies
  (alternate query wording, broader filters, prerequisite lookup,
   alternate source or tool),
- Only then report no results found, along with what you tried.
</empty_result_recovery>
```

---

## 8. Verification Loop

```xml
<verification_loop>
Before finalizing:
- Check correctness: does the output satisfy every requirement?
- Check grounding: are factual claims backed by provided context or
  tool outputs?
- Check formatting: does the output match the requested schema or style?
- Check safety and irreversibility: if the next step has external side
  effects, ask permission first.
</verification_loop>

<missing_context_gating>
- If required context is missing, do NOT guess.
- Prefer the appropriate lookup tool when the missing context is
  retrievable; ask a minimal clarifying question only when it is not.
- If you must proceed, label assumptions explicitly and choose a
  reversible action.
</missing_context_gating>
```

고영향 액션:

```xml
<action_safety>
- Pre-flight: summarize the intended action and parameters in 1-2 lines.
- Execute via tool.
- Post-flight: confirm the outcome and any validation that was performed.
</action_safety>
```

---

## 9. Specialized Workflows

### 9.1 Vision and Computer Use (5.5 변경)

`detail`은 최상위 파라미터가 아니라 **이미지 입력 항목마다** 지정한다(`{"type": "input_image", "image_url": ..., "detail": "high"}`). 생략하면 `auto`다. 5.4에서는 `auto`가 `high`와 같은 크기 처리였고, 5.5에서는 **`original`과 같은 크기 처리**로 바뀌었다(computer use 정확도 향상 목적).

| 값 | 5.5 크기 처리 | 사용처 |
|-----|--------|----------|
| `original` (미지정·`auto` 포함) | 최대 10,240,000픽셀 또는 한 변 6,000픽셀까지 축소 없이 | 컴퓨터 사용, OCR, 좌표가 중요한 작업, 대형·밀집 이미지 |
| `high` | 최대 2,500,000픽셀 또는 한 변 2,048픽셀까지 축소 없이 | 원본 좌표가 필요 없는 표준 고충실도 이해 |
| `low` | 한 변 512픽셀을 넘으면 이전 모델보다 강하게 축소 | 대략적인 이해, 컨텍스트 효율 |

> `original` 동작은 토큰 사용을 늘릴 수 있다. 일반 차트·문서에서 `high`나 `low`로 낮출지는 그 이미지에서 품질과 토큰을 비교해 정한다. 공식 문서는 `low`가 모델에 따라 항상 `high`보다 토큰을 적게 쓰지는 않는다고 적는다. 컴퓨터 사용 워크플로는 그대로 둔다.

### 9.2 Research and Citations

```xml
<citation_rules>
- Only cite sources retrieved in the current workflow.
- Never fabricate citations, URLs, IDs, or quote spans.
- Use exactly the citation format required by the host application.
- Attach citations to the specific claims they support, not only at the end.
</citation_rules>

<grounding_rules>
- Base claims only on provided context or tool outputs.
- If sources conflict, state the conflict explicitly and attribute each side.
- If the context is insufficient, narrow the answer or say you cannot
  support the claim.
- If a statement is an inference rather than a directly supported fact,
  label it as an inference.
</grounding_rules>

<research_mode>
- Do research in 3 passes:
  1) Plan: list 3-6 sub-questions to answer.
  2) Retrieve: search each sub-question and follow 1-2 second-order leads.
  3) Synthesize: resolve contradictions and write the final answer with
     citations.
- Stop only when more searching is unlikely to change the conclusion.
</research_mode>
```

### 9.3 Structured Output (5.5 강조)

공식 권고는 **가능하면 출력 스키마 정의를 프롬프트에서 빼고 Structured Outputs를 쓰는 것**이다("Remove output schema definitions from the prompt where possible."). 스키마 없이 형식만 지켜야 하는 경우의 보조 지시:

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

스키마는 API로 지정한다. Responses API는 `text.format`(`text={"format": {"type": "json_schema", "name": ..., "strict": True, "schema": {...}}}`), Chat Completions는 `response_format`이다. Responses 요청에 `response_format`을 넣는 것은 흔한 이전 실수다.

> 지원하는 스키마로 정상 완료된 출력은 형식이 강제된다. 다만 "Structured Outputs can still contain mistakes."이므로 거절과 불완전 응답(최대 토큰 도달)을 따로 처리하고, 값의 의미와 업무 조건은 별도로 검증한다. 프롬프트의 중복 스키마 설명은 줄일 수 있지만 총 입력 토큰 절약을 보장하지는 않는다.

### 9.4 Bounding Box Extraction

```xml
<bbox_extraction_spec>
- Use the specified coordinate format exactly, e.g. [x1,y1,x2,y2]
  normalized to 0..1.
- For each box, include page, label, text snippet, and confidence.
- Add a vertical-drift sanity check for line alignment.
- If the layout is dense, process page by page with a second pass.
</bbox_extraction_spec>
```

---

## 10. Markdown / Formatting (5.5 강조)

5.5는 출력 형식·구조 지시를 잘 따른다("GPT-5.5 is highly steerable on output format and structure."). 그 통제력은 이해나 제품 적합성을 높일 때 쓰고, 무거운 구조는 이해를 돕거나 UI가 안정된 산출물을 요구할 때만 쓴다. 공식 예시 원문(평문 대화형 형식):

```text
Let formatting serve comprehension. Use plain paragraphs as the default format for normal conversation, explanations, reports, documentation, and technical writeups. Keep the presentation clean and readable without making the structure feel heavier than the content.

Use headers, bold text, bullets, and numbered lists sparingly. Reach for them when the user requests them, when the answer needs clear comparison or ranking, or when the information would be harder to scan as prose. Otherwise, favor short paragraphs and natural transitions.

Respect formatting preferences from the user. If they ask for a terse answer, minimal formatting, no bullets, no headers, or a specific structure, follow that preference unless there is a strong reason not to.
```

독자·길이 지시 예: "Write for a senior business audience. Keep the answer under 400 words. Use short paragraphs and only include bullets when they improve scannability. Prioritize the conclusion first, then the reasoning, then caveats."

편집·요약·고객 메시지는 문체를 고치라고 하기 전에 보존할 것을 먼저 말한다: "Preserve the requested artifact, length, structure, and genre first. Quietly improve clarity, flow, and correctness. Do not add new claims, extra sections, or a more promotional tone unless explicitly requested."

---

## 11. Coding and Agentic Tasks

### 11.1 Autonomy and Persistence

```xml
<autonomy_and_persistence>
Persist until the task is fully handled end-to-end within the current turn
whenever feasible: do not stop at analysis or partial fixes; carry changes
through implementation, verification, and a clear explanation of outcomes
unless the user explicitly pauses or redirects you.

Unless the user explicitly asks for a plan, asks a question about the code,
is brainstorming, or some other intent that makes it clear that code should
not be written, assume the user wants you to make code changes or run tools
to solve the user's problem.
</autonomy_and_persistence>
```

### 11.2 User Updates

```xml
<user_updates_spec>
- Intermediary updates go to the commentary channel.
- Use 1-2 sentence updates to communicate progress.
- Do not begin responses with conversational interjections.
- Before exploring, explain your understanding and first step.
- Provide updates roughly every 30 seconds while working.
- Before file edits, explain what you are about to change.
- Keep tone consistent with the assistant's personality.
</user_updates_spec>
```

### 11.3 Long-Task User-Visible Updates (5.5 신규)

스트리밍 앱에서 5.5는 보이는 텍스트를 내기 전에 추론·계획·도구 준비에 시간을 쓸 수 있다. 여러 단계이거나 도구 호출이 필요하거나 장기 에이전트 작업이면 짧은 서두(preamble)로 시작하게 한다. 공식 예시 원문:

```text
Before any tool calls for a multi-step task, send a short user-visible update that acknowledges the request and states the first step. Keep it to one or two sentences.
```

메시지 단계를 따로 노출하는 코딩 에이전트용:

```text
You must always start with an intermediary update before any content in the analysis channel if the task will require calling tools. The user update should acknowledge the request and explain your first step.
```

#### 수동 이력 재생과 `phase`

`previous_response_id`를 쓰면 API가 이전 assistant 상태를 자동으로 보존한다. 애플리케이션이 assistant 출력 항목을 직접 다음 요청에 재생하면 각 항목의 원래 `phase` 값을 그대로 돌려보낸다. 공식 예시 원문:

```text
If manually replaying assistant items:
- Preserve assistant `phase` values exactly.
- Use `phase: "commentary"` for intermediate user-visible updates.
- Use `phase: "final_answer"` for the completed answer.
- Do not add `phase` to user messages.
```

서두, 반복 도구 호출, 중간 업데이트 뒤의 최종 답이 섞인 응답에서 특히 중요하다. Stateless·Zero Data Retention 흐름은 반환된 출력 항목을 매 턴 돌려보낸다.

### 11.4 Terminal Tool Hygiene

```xml
<terminal_tool_hygiene>
- Only run shell commands via the terminal tool.
- Never "run" tool names as shell commands.
- If a patch or edit tool exists, use it directly.
- After changes, run a lightweight verification step before declaring done.
</terminal_tool_hygiene>
```

---

## 12. Personality and Writing Controls (5.4 호환 + §4 우선)

5.4의 통합 personality 컨트롤은 5.5에서도 유효하지만, 우선은 위 §4 (Personality + Collaboration 분리)를 사용. 통합 블록이 필요한 경우:

```xml
<personality_and_writing_controls>
- Persona: <one sentence>
- Channel: <Slack | email | memo | PRD | blog>
- Emotional register: <direct/calm/energized/etc.> + "not <overdo this>"
- Formatting: <ban bullets/headers/markdown if you want prose>
- Length: <hard limit, e.g. <=150 words or 3-5 sentences>
- Default follow-through: if the request is clear and low-risk, proceed
  without asking permission.
</personality_and_writing_controls>
```

### Professional Memo Mode

```xml
<memo_mode>
- Write in a polished, professional memo style.
- Use exact names, dates, entities, and authorities.
- Prefer precise conclusions over generic hedging.
- When uncertainty is real, tie it to the exact missing fact or source.
- Synthesize across documents rather than summarizing each one.
</memo_mode>
```

---

## 13. Migration Strategy: 5.4 → 5.5

시작 설정 예시이며 평가로 조정한다.

| 현재 설정 | GPT-5.5 시작 예시 | 주의 |
|----------|------------------|------|
| `gpt-5.4` (일반) | **최소 프롬프트로 새 기준선** + `medium` effort, 짧은 응답이면 `low` verbosity | 검증 없는 단순 교체를 가정하지 않음 |
| `gpt-5.4` (코딩 에이전트) | `medium` effort 유지 + outcome-first로 재구조화 + 관련 검증 지시 | preambles + phase 처리 유지 |
| `gpt-5.4` (리서치 어시스턴트) | `medium` effort + retrieval budget 추가 + 단계별 절차 → outcome-first | citation 룰 유지 |
| `gpt-5.4` (장기 에이전트) | `medium` 또는 `high` + tool persistence + completeness | xhigh는 eval로 검증 후 |

GPT-4.1이나 o3 같은 이전 추론 모델에서 옮길 때도 Responses API, 추론 설정, verbosity, Structured Outputs, 프롬프트 캐싱, 도구 설계, 상태 관리를 함께 점검하라는 것이 공식 안내다.

### 마이그레이션 체크리스트

1. [ ] 모델명 `gpt-5.5`로 변경
2. [ ] **최소 프롬프트로 새 기준선** (옛 프롬프트를 통째로 옮기지 않음)
3. [ ] `reasoning.effort` 디폴트 `medium`으로 시작 → eval 보고 `low`로 내릴지, `high`로 올릴지 결정
4. [ ] `text.verbosity = "low"` 평가
5. [ ] 출력 스키마 → Structured Outputs로 이전 (Responses는 `text.format`, Chat Completions는 `response_format`)
6. [ ] 단계별 절차("First A then B") → outcome-first goal/success_criteria로 재작성
7. [ ] Personality + Collaboration Style 분리 (둘 다 짧게)
8. [ ] Retrieval Budget / Stop Rules 명시화
9. [ ] 형식 지시 정리 (평문 단락 기본, 필요한 구조만)
10. [ ] 프롬프트 캐싱: 정적 내용은 앞, 동적 내용은 뒤, 공유 접두부에 고정 `prompt_cache_key`
11. [ ] 현재 UTC 날짜를 알리는 중복 지시만 제거. 업무 시간대·정책 발효일·사용자 현지 날짜처럼 작업 의미를 정하는 날짜는 유지
12. [ ] `phase` 처리 검증: `previous_response_id`를 쓰면 API가 상태를 보존, assistant 항목을 직접 재생하면 원래 `phase`(`commentary`·`final_answer`)를 그대로 돌려보내고 user 메시지에는 넣지 않음
13. [ ] 이미지 `detail` 미지정·`auto`가 `original` 동작으로 바뀐 영향 평가, 필요하면 항목별로 `high` 지정
14. [ ] Chat Completions에서 도구를 호출하면 `reasoning_effort: "none"`이어야 함(GPT-5.4부터). 추론·도구·다중 턴은 Responses로

### 자동 마이그레이션 도구

> Codex CLI 사용자: `$openai-docs migrate this project to gpt-5.5` 명령으로 자동 마이그레이션 가능 (OpenAI Docs Skill).

### 마이그레이션 순서 (권장)

리서치 어시스턴트:
1. `<research_mode>` 유지
2. `<citation_rules>` 유지
3. `<empty_result_recovery>` 유지
4. `<retrieval_budget>` 추가 (5.5 신규)
5. 단계별 절차 → outcome-first goal/success_criteria 재작성
6. 프롬프트 정리 후에만 `reasoning.effort` 조정

코딩 에이전트:
1. outcome-first goal 정의
2. `<tool_validation>` 추가 (5.5 강조)
3. `<tool_persistence_rules>` 유지
4. `<completeness_contract>` 유지
5. Personality + Collaboration 분리
6. Markdown 절제 정책 추가

---

## 14. Key Takeaways

GPT-5.5는 다음일 때 최적 성능:

1. **Outcome-first**: 절차가 아닌 목표·성공 기준·제약·중단 조건으로 정의
2. **Personality + Collaboration Style 분리**, 둘 다 짧게
3. **Reasoning effort `medium` 기본**, eval 보고 조정
4. **간결한 응답이면 Verbosity `low`** (API 기본 `medium`)
5. **출력 검증 도구** 활용 (변경과 관련된 검증을 고르게)
6. **Retrieval budget** 명시화로 eagerness 양극단 회피
7. **형식은 이해를 돕는 만큼**, 일반 대화·설명은 평문 단락 기본
8. **가능하면 Structured Outputs**로 스키마 지정 (Responses는 `text.format`)
9. **최소 프롬프트로 새 기준선**, 5.4 프롬프트를 검증 없이 그대로 쓰지 않음
10. **이미지 `detail` 미지정·`auto`는 5.5에서 `original` 동작**, 컴퓨터 사용이 아니면 항목별 `high` 비교

**가장 높은 레버리지 변경**: outcome-first 재구조화, personality/collaboration 분리, 최소 프롬프트 기준선 마이그레이션.

---

## 15. 외부 노하우 (Simon Willison, 2026-04-25)

Simon Willison이 5.5 출시 직후(2026-04-25) 공식 가이드를 분석하며 강조한 점:

- 핵심 메시지는 OpenAI 공식 권고와 일치:
  > "Treat it as a new model family to tune for, not a drop-in replacement."
  > "Begin migration with a fresh baseline instead of carrying over every instruction from an older prompt stack."

- **실무 함의**: 옛 프롬프트의 효과성을 5.5가 보장하지 않는다. 처음부터 다시 짜는 것을 두려워하지 말 것. 옛 프롬프트의 단계별 절차나 절대 규칙은 5.5에서 추론 토큰 낭비로 이어질 수 있다.

- **Codex CLI 자동 마이그레이션**: `$openai-docs migrate this project to gpt-5.5` 명령으로 OpenAI Docs Skill이 프로젝트의 프롬프트 스택을 5.5 권장에 맞게 자동 변환.

- **벤치마크 관찰**: Simon의 "pelicans on a bicycle" SVG 벤치마크에서 5.5의 디폴트 출력은 5.4보다 약간 뒤처졌으나, `reasoning_effort: xhigh`를 주면 5.4를 능가. 단 토큰·지연시간 비용 증가. 즉 **effort 조정의 비용-품질 곡선이 5.4보다 가파를 수 있다**.

---

## 16. 한 페이지 치트시트

### 시스템 프롬프트 골격 (Outcome-First, 5.5 권장)

```xml
<role>
You are <one sentence role>.
</role>

<personality>
<1-2 sentences: tone, warmth, directness, humor>
</personality>

<collaboration_style>
<1-2 sentences: when to ask vs assume, validation policy, escalation>
</collaboration_style>

<goal>
<one sentence: the outcome to achieve>
</goal>

<success_criteria>
- <verifiable criterion 1>
- <verifiable criterion 2>
- <verifiable criterion 3>
</success_criteria>

<constraints>
- <hard constraint 1>
- <hard constraint 2>
</constraints>

<output_shape>
<format / length / sections>
</output_shape>

<stop_rules>
- Stop when success criteria are met.
- Resolve in the fewest useful tool loops, but do not let loop
  minimization outrank correctness.
</stop_rules>
```

### API 호출 디폴트 (5.5)

```python
response = client.responses.create(
    model="gpt-5.5",
    reasoning={"effort": "medium"},      # 출발점
    text={
        "verbosity": "low",              # 짧은 응답이 필요할 때 (API 기본 medium)
        "format": {                      # 스키마는 프롬프트가 아닌 API로 (Responses는 text.format)
            "type": "json_schema",
            "name": "<schema_name>",
            "strict": True,
            "schema": { ... },
        },
    },
    input=[ ... ],
    tools=[ ... ],
)
```

---

## Sources

- [Using GPT-5.5 | OpenAI API (5.5 전용 원문)](https://developers.openai.com/api/docs/guides/latest-model/gpt-5.5.md)
- [GPT-5.5 모델 페이지 | OpenAI API](https://developers.openai.com/api/docs/models/gpt-5.5)
- [Structured Outputs | OpenAI API](https://developers.openai.com/api/docs/guides/structured-outputs)
- [Migrate to the Responses API | OpenAI API](https://developers.openai.com/api/docs/guides/migrate-to-responses)
- [Images and vision | OpenAI API](https://developers.openai.com/api/docs/guides/images-vision)
- [Prompt Personalities | OpenAI Cookbook](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [GPT-5.5 prompting guide | Simon Willison (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
- [GPT-5.4 Prompting Guide (이전 버전 비교)](../archive/openai-prompt-guide/gpt-5.4-prompt-guide.md)
