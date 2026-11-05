# GPT-5.4 프롬프트 패턴

## 목차
- [개요](#개요)
- [1. Output Contract (출력 계약)](#1-output-contract-출력-계약)
- [2. Default Follow-Through Policy (실행 정책)](#2-default-follow-through-policy-실행-정책)
- [3. Tool Persistence Rules (도구 지속성)](#3-tool-persistence-rules-도구-지속성)
- [4. Completeness Contract (완성도 계약)](#4-completeness-contract-완성도-계약)
- [5. Empty Result Recovery (빈 결과 복구)](#5-empty-result-recovery-빈-결과-복구)
- [6. Verification Loop (검증 루프)](#6-verification-loop-검증-루프)
- [7. Research and Citations (리서치 및 인용)](#7-research-and-citations-리서치-및-인용)
- [8. Coding and Agentic Tasks (코딩 및 에이전틱)](#8-coding-and-agentic-tasks-코딩-및-에이전틱)
- [9. Phase 파라미터](#9-phase-파라미터)
- [10. 마이그레이션 전략](#10-마이그레이션-전략)


GPT-5.4에서 성능을 극대화하는 XML 태그 기반 구조화된 계약 패턴입니다.
**reasoning effort를 올리기 전에 이 패턴들을 먼저 적용**하세요.

---

## 1. Output Contract (출력 계약)

요청된 섹션을 요청된 순서로 정확히 반환하도록 명시:

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

---

## 2. Default Follow-Through Policy (실행 정책)

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

---

## 3. Tool Persistence Rules (도구 지속성)

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

---

## 4. Completeness Contract (완성도 계약)

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

---

## 5. Empty Result Recovery (빈 결과 복구)

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

## 6. Verification Loop (검증 루프)

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

## 7. Research and Citations (리서치 및 인용)

```xml
<citation_rules>
- Only cite sources retrieved in the current workflow.
- Never fabricate citations, URLs, IDs, or quote spans.
- Use exactly the citation format required by the host application.
- Attach citations to the specific claims they support, not only at the end.
</citation_rules>

<research_mode>
- Do research in 3 passes:
  1) Plan: list 3-6 sub-questions to answer.
  2) Retrieve: search each sub-question and follow 1-2 second-order leads.
  3) Synthesize: resolve contradictions and write the final answer with
     citations.
- Stop only when more searching is unlikely to change the conclusion.
</research_mode>
```

---

## 8. Coding and Agentic Tasks (코딩 및 에이전틱)

```xml
<autonomy_and_persistence>
Persist until the task is fully handled end-to-end within the current turn
whenever feasible: do not stop at analysis or partial fixes; carry changes
through implementation, verification, and a clear explanation of outcomes
unless the user explicitly pauses or redirects you.
</autonomy_and_persistence>

<terminal_tool_hygiene>
- Only run shell commands via the terminal tool.
- Never "run" tool names as shell commands.
- If a patch or edit tool exists, use it directly.
- After changes, run a lightweight verification step before declaring done.
</terminal_tool_hygiene>
```

병렬 도구 호출:

```xml
<parallel_tool_calling>
- When multiple retrieval or lookup steps are independent, prefer parallel
  tool calls to reduce wall-clock time.
- Do not parallelize steps that have prerequisite dependencies.
- After parallel retrieval, pause to synthesize before making more calls.
</parallel_tool_calling>
```

---

## 9. Phase 파라미터

다단계 워크플로우에서 assistant 메시지에 `phase`를 지정하여 조기 종료를 방지:

| phase | 용도 |
|-------|------|
| `commentary` | 도구 호출 전 중간 업데이트 |
| `final_answer` | 완료된 최종 응답 |

**주의**: phase를 생략하면 복잡한 작업에서 조기 종료 발생 가능. user 메시지에는 사용 금지.

---

## 10. 마이그레이션 전략

reasoning effort를 올리기 전에 프롬프트 패턴 먼저 추가:

1. `<output_contract>` + `<completeness_contract>` 추가
2. `<verification_loop>` 추가
3. `<tool_persistence_rules>` 추가
4. 프롬프트 수정 후에도 부족하면 effort 증가

| 현재 설정 | GPT-5.4 시작 | 비고 |
|----------|-------------|------|
| `gpt-5.2` | 현재 effort 유지 | 드롭인 교체 |
| `gpt-4.1`/`gpt-4o` | `none` | eval 퇴보 시 증가 |
| 리서치 어시스턴트 | `medium`/`high` | research_mode + citation 추가 |
| 장기 에이전트 | `medium`/`high` | tool persistence + completeness 추가 |

---

## 참고

- [GPT-5.4 Prompting Guide](https://developers.openai.com/api/docs/guides/prompt-guidance/)
- [Using GPT-5.4](https://developers.openai.com/api/docs/guides/latest-model/)
