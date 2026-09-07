# GPT-5.4 Prompting Guide

> **출처**: [Prompt guidance for GPT-5.4 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance/)
> **날짜**: 2026-03-05

---

## 개요

GPT-5.4는 장기 실행 작업 성능과 행동 제어, 규율 있는 실행의 균형을 제공하는 플래그십 모델. **다단계 추론, 근거 기반 종합, 긴 컨텍스트 안정성**에서 특히 우수.

### 핵심 강점

- 확장된 응답에서 성격/톤 일관성 유지
- 에이전틱 워크플로우의 다단계 완료 견고성
- 긴 컨텍스트에서 근거 기반 종합
- 모듈식 스킬 기반 프롬프트의 지시 준수
- 병렬 도구 호출
- 스프레드시트/재무 워크플로우 포맷 충실도

### 명시적 프롬프팅이 필요한 영역

- 제한된 컨텍스트에서의 초기 도구 라우팅
- 전제조건 확인이 필요한 의존성 인식 워크플로우
- 규율 있는 소스 수집이 필요한 리서치 작업
- 검증이 필요한 고영향 액션
- 명확한 도구 경계가 필요한 터미널/코딩 환경

---

## 1. Reasoning Effort 선택 (가장 중요한 레버)

| 설정 | 권장 시작점 |
|------|-----------|
| `none` | 실행 중심: 워크플로우 단계, 필드 추출, 지원 분류, 짧은 변환 |
| `low` | 지연 시간 민감 + 복잡한 지시가 있는 작업 |
| `medium` | 연구 중심: 장문 종합, 다중 문서 검토, 전략 문서 |
| `high` | 강한 추론이 필요한 작업 (지연/비용 감수 가능) |
| `xhigh` | 명확한 eval 이점이 있을 때만. 긴 에이전틱 추론 작업 |

**대부분 팀은 `none`, `low`, `medium`을 기본으로 사용해야 함.**

Reasoning effort를 올리기 전에 먼저 추가할 것:
1. `<completeness_contract>` (완성도 계약)
2. `<verification_loop>` (검증 루프)
3. `<tool_persistence_rules>` (도구 지속성 규칙)

---

## 2. Core Prompt Patterns (핵심 프롬프트 패턴)

### 2.1 Output Contract (출력 계약)

정확히 요청된 섹션을 요청된 순서로 반환하도록 명시:

```xml
<output_contract>
- Return exactly the sections requested, in the requested order.
- If the prompt defines a preamble, analysis block, or working section,
  do not treat it as extra output.
- Apply length limits only to the section they are intended for.
- If a format is required (JSON, Markdown, SQL, XML), output only that format.
</output_contract>

<verbosity_controls>
- Prefer concise, information-dense writing.
- Avoid repeating the user's request.
- Keep progress updates brief.
- Do not shorten the answer so aggressively that required evidence,
  reasoning, or completion checks are omitted.
</verbosity_controls>
```

### 2.2 Default Follow-Through Policy (기본 실행 정책)

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

### 2.3 Instruction Priority (지시 우선순위)

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

### 2.4 Mid-Conversation Updates (대화 중 업데이트)

범위, 재정의, 유지할 사항을 명시하는 스코프 업데이트:

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

## 3. Tool Use Patterns (도구 사용 패턴)

### 3.1 Tool Persistence Rules (도구 지속성)

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

### 3.2 Parallel vs Sequential (병렬 vs 순차)

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

### 3.3 Completeness Contract (완성도 계약)

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

### 3.4 Empty Result Recovery (빈 결과 복구)

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

## 4. Verification Loop (검증 루프)

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

고영향 액션의 경우:

```xml
<action_safety>
- Pre-flight: summarize the intended action and parameters in 1-2 lines.
- Execute via tool.
- Post-flight: confirm the outcome and any validation that was performed.
</action_safety>
```

---

## 5. Specialized Workflows (특화 워크플로우)

### 5.1 Vision and Computer Use

이미지 상세도를 명시적으로 지정:
- `high`: 표준 고충실도 이해
- `original`: 대형/밀집 이미지, 컴퓨터 사용, OCR, 클릭 정확도
- `low`: 속도/비용이 상세도보다 중요할 때만

### 5.2 Research and Citations (리서치 및 인용)

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

### 5.3 Structured Output (구조화 출력)

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

### 5.4 Bounding Box Extraction (바운딩 박스)

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

## 6. Coding and Agentic Tasks (코딩 및 에이전틱 작업)

### 6.1 Autonomy and Persistence (자율성)

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

### 6.2 User Updates (사용자 업데이트)

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

### 6.3 Terminal Tool Hygiene (터미널 도구 위생)

```xml
<terminal_tool_hygiene>
- Only run shell commands via the terminal tool.
- Never "run" tool names as shell commands.
- If a patch or edit tool exists, use it directly.
- After changes, run a lightweight verification step before declaring done.
</terminal_tool_hygiene>
```

---

## 7. Personality and Writing Controls (성격 및 글쓰기 제어)

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

## 8. Migration Strategy (마이그레이션 전략)

한 번에 한 가지씩 변경하는 규율:

| 현재 설정 | 권장 GPT-5.4 시작 | 비고 |
|----------|------------------|------|
| `gpt-5.2` | 현재 reasoning effort 유지 | 드롭인 교체 가능 |
| `gpt-5.3-codex` | 현재 reasoning effort 유지 | 코딩 동일 유지 |
| `gpt-4.1` / `gpt-4o` | `none` | 빠르게 유지, eval 퇴보 시 증가 |
| 리서치 어시스턴트 | `medium` / `high` | research_mode + citation 추가 |
| 장기 에이전트 | `medium` / `high` | tool persistence + completeness 추가 |

리서치 마이그레이션 순서:
1. `<research_mode>` 추가
2. `<citation_rules>` 추가
3. `<empty_result_recovery>` 추가
4. 프롬프트 수정 후에만 `reasoning_effort` 증가

---

## 9. Key Takeaways (핵심 요약)

GPT-5.4는 다음일 때 최적 성능:

1. **출력 계약**이 명시적이고 구조화됨
2. **도구 사용 규칙**에 의존성 인식과 완료 기준 포함
3. **검증 루프**가 경량이지만 존재
4. **Reasoning effort**가 직관이 아닌 작업 형태에 맞춤
5. **출력 형식**과 완료 정의가 명확히 지정
6. **리서치 워크플로우**에 명시적 인용 및 소스 경계 사용
7. **긴 대화**에서 컴팩션으로 일관성 유지

**가장 높은 레버리지 변경**: reasoning effort 선택, 정확한 출력/인용 형식 정의, 의존성 인식 도구 규칙 추가, 완료 기준 명시화.

---

## Sources

- [Prompt guidance for GPT-5.4 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Using GPT-5.4 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model/)
- [Introducing GPT-5.4 | OpenAI](https://openai.com/index/introducing-gpt-5-4/)
