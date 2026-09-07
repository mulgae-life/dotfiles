# GPT-5.5 Prompting Guide

> **출처**:
> - [Prompt guidance for GPT-5.5 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance/)
> - [Using GPT-5.5 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
> - [Prompt Personalities | OpenAI Cookbook](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
> - [GPT-5.5 prompting guide | Simon Willison (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
>
> **날짜**: 2026-04-26
> **이전 버전**: [GPT-5.4 Prompting Guide](./gpt-5.4-prompt-guide.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.4 → 5.5 핵심 변화)

GPT-5.5는 **5.4의 드롭인 교체가 아닌 새 모델 패밀리**로 다뤄야 한다. 공식 권고:

> "Treat it as a new model family to tune for, not a drop-in replacement."
> "Begin migration with a fresh baseline instead of carrying over every instruction from an older prompt stack."

기존 5.4 프롬프트를 그대로 가져오면 5.5의 효율 향상을 활용하지 못하고, 오히려 과도한 절차 지시 때문에 추론 토큰을 낭비한다. 옛 프롬프트의 효과성은 5.5에서 보장되지 않는다.

### 한 페이지 변화 요약

| 항목 | 5.4까지 | 5.5 |
|------|---------|------|
| 프롬프트 철학 | Output contract + 단계별 절차 명시 | **Outcome-first**, 목표·성공 기준 정의 후 경로는 모델이 선택 |
| Reasoning effort 기본 | 작업 형태별 매트릭스 | **`medium` 권장 출발점**, 많은 워크로드는 `low`도 충분 |
| Verbosity | 별도 권장 없음 | **`text.verbosity = "low"` 권장** |
| Personality 정의 | 통합 personality 블록 | **Personality + Collaboration Style 분리** (각 1-2문단) |
| Markdown | 절제 권고 | **plain prose 기본**, 헤더·불릿 sparingly |
| Retrieval | research_mode 3-pass | **명시적 stopping conditions** (`<retrieval_budget>`) |
| 출력 스키마 | 프롬프트 + 검증 | **Structured Outputs API로 강제** 권장 |
| Image detail 기본 | `high` | **`original`** (computer use 정확도 향상) |
| 마이그레이션 | 5.2 → 5.4 드롭인 가능 | **❌ 드롭인 금지**, fresh baseline 재구성 |
| Anti-pattern | - | `ALWAYS`/`NEVER` 남용, "First A then B" 단계 명령, 옛 프롬프트 이월 |

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

Reasoning effort를 올리기 전에 먼저 추가할 것 (5.4에서 유지):
1. `<completeness_contract>` (완성도 계약)
2. `<verification_loop>` (검증 루프)
3. `<tool_persistence_rules>` (도구 지속성 규칙)
4. `<retrieval_budget>` (검색 예산) — 5.5 신규

---

## 2. Verbosity 권장 (5.5 신규)

5.5는 `text.verbosity` 파라미터를 의도적으로 사용할 것을 권장.

- **API 기본값**: `medium`
- **권장 출발점**: `low` (대부분의 응답 시나리오에서 더 적합)
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

> "Shorter, outcome-first prompts usually work better than process-heavy prompt stacks."

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
> 진정한 불변(safety/honesty/privacy)에만 `ALWAYS`/`NEVER` 사용. 형식·스타일에는 사용하지 말 것.

---

## 4. Personality + Collaboration Style 분리 (5.5 신규)

5.5는 **personality**(어떻게 들리는가)와 **collaboration style**(어떻게 일하는가)을 명시적으로 분리할 것을 권장. 각각 1-2문단 이내.

### 4.1 Personality 분류 (Cookbook prompt_personalities 4종)

| 패턴 | 사용처 | 핵심 표현 |
|------|--------|----------|
| **Professional** | 비즈니스 커뮤니케이션, 엔터프라이즈 워크플로우 | "focused, formal, and exacting that strives for comprehensiveness" |
| **Efficient** | 개발자 도구, 자동화, CLI | "direct, complete, and easy to parse... DO NOT add extra features" |
| **Fact-Based** | 디버깅, 위험 분석, 리서치 어시스턴트 | "Do not guess or fill gaps with fabricated details. If you are unsure, say so" |
| **Exploratory** | 학습, 기술 지식 공유, 내부 enablement | "Aim to make learning enjoyable and useful by balancing depth with approachability" |

### 4.2 Personality 블록 예시 (Steady Task-Focused)

```xml
<personality>
You are a capable collaborator: approachable, steady, and direct.
Assume the user is competent and acting in good faith. Stay concise
without becoming curt. Use mild warmth, no flattery, no apology spam.
</personality>
```

### 4.3 Collaboration Style 블록 예시

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

### 4.4 Anti-Pattern

- Personality에 task logic / domain rules 혼합 ("Professional이면서 SQL 쿼리는 항상 PostgreSQL로 작성" → 분리)
- 과도한 친근함이나 헤징(hedging)으로 신뢰성 훼손
- Personality를 요청된 artifact(이메일·코드·메모)에 강제 적용
- 미확인 정보로 빈틈 채우기 (특히 fact-based 시나리오)

---

## 5. Retrieval Budget / Stopping Conditions (5.5 강조)

5.5는 너무 많이 검색하거나 너무 일찍 멈추는 양극단을 모두 피하기 위해 **명시적 retrieval budget**을 권장.

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

## 6. Core Prompt Patterns (5.4에서 유지, outcome-first 프레임 안에 배치)

5.4 가이드의 패턴은 5.5에서도 유효하다. 단 **outcome-first 프레임 안에 들어가야** 하며, 단계별 명령으로 변질되어선 안 된다.

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

```xml
<tool_validation>
- Use tools that let you check your own outputs whenever possible.
- For coding agents: run unit tests, lint, build checks before declaring done.
- For visual artifacts: render and inspect for layout, clipping, spacing.
- For numeric outputs: re-derive or sanity-check via calculation tool.
</tool_validation>
```

> "Give GPT-5.5 access to tools that let it check outputs."

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

이미지 상세도 기본값이 `high` → **`original`**로 변경 (computer use 정확도 향상 목적).

| 값 | 사용처 | 토큰 영향 |
|-----|--------|----------|
| `original` | **5.5 기본값**. 컴퓨터 사용, OCR, 클릭 정확도, 대형/밀집 이미지 | 많음 |
| `high` | 표준 고충실도 이해 (일반 차트·문서 분석) | 중간 |
| `low` | 속도/비용이 상세도보다 중요할 때만 | 적음 |

> 5.5에서 `original` 디폴트는 토큰 사용이 늘어날 수 있다. **단순 차트·문서 분석에서는 `high` 명시 권장.** 컴퓨터 사용 워크플로우는 그대로 두면 됨.

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

5.5는 **출력 스키마를 프롬프트로 지시하지 말고 Structured Outputs API로 강제**할 것을 강력 권장.

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

> 가능하면 시스템 프롬프트에서 스키마 지시를 빼고 `response_format: { type: "json_schema", json_schema: { ... } }`로 강제. 프롬프트 토큰 절약 + 정확도 향상 + 검증 자동화.

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

5.5는 markdown 절제를 강하게 권장.

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

**원칙**:
- 모든 응답을 자동으로 헤더+불릿으로 구조화하지 말 것
- 사용자가 평문 산문체를 원하면 그대로 따를 것
- 편집/요약 작업은 입력 artifact의 형식을 보존

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

```xml
<long_task_updates>
- For tasks that may take significant thinking time before producing a
  user-visible response, send a short user-visible update that
  acknowledges the request and names the first step.
- Keep it to one or two sentences.
</long_task_updates>
```

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

| 현재 설정 | 권장 GPT-5.5 시작 | 주의 |
|----------|------------------|------|
| `gpt-5.4` (일반) | **fresh baseline 재구성** + `medium` effort + `low` verbosity | 드롭인 교체 금지 |
| `gpt-5.4` (코딩 에이전트) | `medium` effort 유지 + outcome-first로 재구조화 + 출력 검증 도구 추가 | preambles + phase 처리 유지 |
| `gpt-5.4` (리서치 어시스턴트) | `medium` effort + retrieval budget 추가 + 단계별 절차 → outcome-first | citation 룰 유지 |
| `gpt-5.4` (장기 에이전트) | `medium` 또는 `high` + tool persistence + completeness | xhigh는 eval로 검증 후 |
| `gpt-4.1` / `gpt-4o` | `low` 시작, eval 퇴보 시 `medium` | 빠른 응답 유지 우선 |

### 마이그레이션 체크리스트

1. [ ] 모델명 `gpt-5.5`로 변경
2. [ ] **fresh baseline 재구성** (옛 프롬프트 통째 이월 금지)
3. [ ] `reasoning.effort` 디폴트 `medium`으로 시작 → eval 보고 `low`로 내릴지, `high`로 올릴지 결정
4. [ ] `text.verbosity = "low"` 평가
5. [ ] 출력 스키마 → Structured Outputs API로 이전
6. [ ] 단계별 절차("First A then B") → outcome-first goal/success_criteria로 재작성
7. [ ] Personality + Collaboration Style 분리 (각 1-2문단)
8. [ ] Retrieval Budget / Stop Rules 명시화
9. [ ] Markdown 절제 정책 추가
10. [ ] 프롬프트 캐싱 prefix/suffix 분리 검토
11. [ ] 시스템 프롬프트에서 현재 날짜 제거 (모델이 인식)
12. [ ] `phase` 파라미터 처리 검증
13. [ ] Image detail 기본값(`original`)의 토큰 영향 평가, 필요 시 `high` 명시

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
2. **Personality + Collaboration Style 분리**, 각 1-2문단
3. **Reasoning effort `medium` 기본**, eval 보고 조정
4. **Verbosity `low`** 시작, 응답 컴팩트하게
5. **출력 검증 도구** 적극 활용 (테스트·린트·렌더링·재계산)
6. **Retrieval budget** 명시화로 eagerness 양극단 회피
7. **Markdown 절제**, 평문 기본
8. **Structured Outputs API**로 스키마 강제
9. **Fresh baseline에서 마이그레이션**, 5.4 프롬프트 그대로 사용 금지
10. **Image detail은 5.5 기본 `original`**, 컴퓨터 사용이 아니면 `high` 명시 검토

**가장 높은 레버리지 변경**: outcome-first 재구조화, personality/collaboration 분리, fresh baseline 마이그레이션.

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
    text={"verbosity": "low"},           # 출발점
    response_format={                    # 스키마는 프롬프트가 아닌 API로
        "type": "json_schema",
        "json_schema": { ... }
    },
    input=[ ... ],
    tools=[ ... ],
)
```

---

## Sources

- [Prompt guidance for GPT-5.5 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Using GPT-5.5 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
- [Prompt Personalities | OpenAI Cookbook](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [GPT-5.5 prompting guide | Simon Willison (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
- [GPT-5.4 Prompting Guide (이전 버전 비교)](./gpt-5.4-prompt-guide.md)
