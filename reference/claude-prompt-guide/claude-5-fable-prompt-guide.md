# Claude Fable 5 Prompting Guide

> **출처**:
> - [Prompting Claude Fable 5 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5)
> - [Introducing Claude Fable 5 and Claude Mythos 5 | Anthropic](https://platform.claude.com/docs/en/about-claude/models/introducing-claude-fable-5)
> - [Migration Guide — Migrating to Claude Fable 5 | Anthropic](https://platform.claude.com/docs/en/about-claude/models/migration-guide)
>
> **날짜**: 2026-07-10
> **이전 버전**: [Claude 4.x Best Practices](./claude-4-best-practices.md)

Claude 5 세대(Fable 5, Mythos 5) 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 수록했습니다 — 시스템 프롬프트에 바로 붙여 쓰는 용도이므로 번역하지 않습니다.

## 목차
- [모델 개요](#모델-개요)
- [API 변경 요약 (Opus 4.8 대비)](#api-변경-요약-opus-48-대비)
- [핵심 원칙: De-prescribe](#핵심-원칙-de-prescribe)
- [행동 특성과 프롬프트 패턴](#행동-특성과-프롬프트-패턴)
- [스캐폴딩 권장 변경](#스캐폴딩-권장-변경)
- [Claude 4.x 가이드와의 차이](#claude-4x-가이드와의-차이)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-fable-5` (GA) / `claude-mythos-5` (Project Glasswing 한정, safety classifier 없음) |
| **포지션** | Anthropic 최상위 공개 모델. 장시간·고난도 추론과 장기 자율(agentic) 작업용. Opus 4.8보다 상위 티어 |
| **컨텍스트/출력** | 1M 토큰 컨텍스트(기본값), 최대 128K 출력 |
| **가격** | $10 / $50 per MTok (입력/출력) — Opus 4.8의 2배 |
| **데이터 보존** | 30일 보존 필수. ZDR(zero data retention) 조직은 모든 요청이 400 에러 |
| **토크나이저** | Opus 4.8과 동일 (4.7에서 도입). 4.7/4.8에서 오는 경우 토큰 수 거의 동일 |

강점 (Opus 4.8 대비): 장기 자율 실행(멀티데이 런), 잘 명세된 복잡 문제의 원샷 정답률, 비전(밀도 높은 기술 이미지·왜곡 이미지 — bash/crop 도구 활용 훈련됨), 엔터프라이즈 산출물(재무 분석·스프레드시트·슬라이드·문서), 코드 리뷰·디버깅 recall, 모호한 요청 탐색, 병렬 서브에이전트 디스패치·관리.

**비대상 도메인**: 공격적 사이버보안·생물/생명과학은 safety classifier가 `stop_reason: "refusal"`을 반환할 수 있습니다(정상 HTTP 200). 인접한 정상 작업도 오탐 가능 — API 통합 시 Opus 4.8로의 fallback 구성이 권장됩니다.

## API 변경 요약 (Opus 4.8 대비)

프롬프트가 아닌 요청 파라미터 레벨의 변경입니다. 자세한 코드는 마이그레이션 가이드 참조.

| 항목 | Fable 5 동작 |
|------|-------------|
| **Thinking** | 항상 켜짐(adaptive). `thinking` 파라미터 생략이 기본. `{"type": "disabled"}`·`budget_tokens` 모두 400 |
| **Thinking 출력** | raw chain of thought는 절대 반환 안 됨. `display: "summarized"` = 요약 반환, `"omitted"`(기본) = 빈 문자열 |
| **깊이 제어** | `output_config.effort`: `low`/`medium`/`high`/`xhigh`/`max` |
| **Prefill** | 마지막 assistant 턴 prefill 400 → Structured Outputs(`output_config.format`) 사용 |
| **Sampling** | `temperature`/`top_p`/`top_k` 400 → 프롬프트로 제어 |
| **Refusal** | `stop_reason: "refusal"` + `stop_details.category` (`cyber`/`bio`/`reasoning_extraction` 등). `fallbacks` 파라미터(beta `server-side-fallback-2026-06-01`)로 Opus 4.8 자동 재시도 |

## 핵심 원칙: De-prescribe

공식 가이드의 가장 중요한 메시지: **구모델용 프롬프트·스킬은 과도하게 규범적(prescriptive)이어서 Fable 5의 출력 품질을 오히려 떨어뜨릴 수 있습니다.**

- 지시 따르기가 강해져, 행동을 하나하나 열거하는 대신 **짧은 지시 한 줄**로 대부분 조향됩니다.
- 마이그레이션 시 구모델용 단계별 스캐폴딩을 제거한 버전과 A/B 비교를 권장합니다. 절차 열거보다 **목표와 제약을 서술**하는 쪽이 낫습니다.
- Fable 5는 작업 중 배운 것으로 스킬을 즉석에서 갱신하는 데도 능합니다.

Claude 4.x 가이드의 "명시적으로 요청하면 명시적으로 수행"(지시를 늘려라)과 방향이 반대입니다. Fable 5에서는 "무엇을"은 짧게, "왜"는 충분히.

## 행동 특성과 프롬프트 패턴

### 1. 긴 턴이 기본 — 과잉계획 방지

높은 effort에서 단일 요청이 수 분(자율 런은 수 시간) 걸릴 수 있습니다. 타임아웃·스트리밍·진행 표시를 먼저 조정하고, 블로킹 대신 비동기 체크인 구조를 고려하세요. 모호한 작업에서 계획만 반복하는 것을 막으려면:

```text
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue in user-facing messages. If you are weighing a choice, give a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

### 2. Effort 전 레벨 활용

effort가 지능·지연·비용 트레이드오프의 1차 제어 수단입니다. 기본 `high`, 최고 난도는 `xhigh`, 루틴 작업은 `medium`/`low` — **Fable 5의 낮은 effort가 구모델의 `xhigh`를 능가하는 경우도 많습니다.** 높은 effort의 루틴 작업에서 요청 범위 밖 정리·리팩토링이 나오면:

```text
Don't add features, refactor, or introduce abstractions beyond what the task requires. A bug fix doesn't need surrounding cleanup and a one-shot operation usually doesn't need a helper. Don't design for hypothetical future requirements: do the simplest thing that works well. Avoid premature abstraction and half-finished implementations. Don't add error handling, fallbacks, or validation for scenarios that cannot happen. Trust internal code and framework guarantees. Only validate at system boundaries (user input, external APIs). Don't use feature flags or backwards-compatibility shims when you can just change the code.
```

### 3. 강한 지시 따르기 — 짧은 지시로 충분

과잉 설명(선택하지 않을 옵션 나열, 장황한 근본원인 설명, 다음 줄을 해설하는 주석)은 브레비티 지시 한 문단으로 잡힙니다:

```text
Lead with the outcome. Your first sentence after finishing should answer "what happened" or "what did you find": the thing the user would ask for if they said "just give me the TLDR." Supporting detail and reasoning come after. Being readable and being concise are different things, and readability matters more.

The way to keep output short is to be selective about what you include (drop details that don't change what the reader would do next), not to compress the writing into fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

체크포인트(멈춰서 물어보는 지점)도 케이스 열거 없이:

```text
Pause for the user only when the work genuinely requires them: a destructive or irreversible action, a real scope change, or input that only they can provide. If you hit one of these, ask and end the turn, rather than ending on a promise.
```

### 4. 진행 보고 근거화 (장기 런 필수)

Anthropic 테스트에서 이 지시가 조작된 상태 보고를 거의 완전히 제거했습니다:

```text
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly. Report outcomes faithfully: if tests fail, say so with the output; if a step was skipped, say that; when something is done and verified, state it plainly without hedging.
```

### 5. 경계 명시

요청하지 않은 인접 행동(요청 없는 이메일 초안 작성, 방어적 git 브랜치 백업 생성 등)을 막으려면:

```text
When the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one. Before running a command that changes system state (restarts, deletes, config edits), check that the evidence actually supports that specific action. A signal that pattern-matches to a known failure may have a different cause.
```

### 6. 병렬 서브에이전트 — 억제 대신 활용

구모델에서 흔했던 "서브에이전트 남발 억제" 가드레일은 뒤집어야 합니다. Fable 5는 병렬 서브에이전트 디스패치·유지가 신뢰할 만하므로 **자주 쓰게 하고, 언제 위임할지를 명시**하세요. 블로킹보다 비동기 통신(장수명 서브에이전트가 컨텍스트를 유지 → 캐시 절감 + 병목 제거)이 우수합니다:

```text
Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context.
```

### 7. 메모리 시스템 구축

이전 런의 교훈을 기록·참조할 수 있으면 성능이 눈에 띄게 향상됩니다. Markdown 파일 하나면 충분:

```text
Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo or chat history already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong.
```

기존 히스토리에서 부트스트랩:

```text
Reflect on the previous sessions we've had together. Use subagents to identify core themes and lessons, and store them in [X]. Make sure you know to reference [X] for future use.
```

### 8. 드문 케이스: 조기 종료

긴 세션 깊숙이에서 "I'll now run X" 같은 의도 선언만 하고 툴 호출 없이 턴을 끝내거나, 이미 진행 가능한데 허락을 구하는 경우가 드물게 있습니다. 대화형에서는 "continue"로 충분하고, 자율 파이프라인에는 시스템 리마인더를 추가:

```text
You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task, so asking "Want me to…?" or "Shall I…?" will block the work. For reversible actions that follow from the original request, proceed without asking. Offering follow-ups after the task is done is fine; asking permission after already discussing with the user before doing the work is not. Before ending your turn, check your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or a promise about work you have not done ("I'll…", "let me know when…"), do that work now with tool calls. End your turn only when the task is complete or you are blocked on input only the user can provide.
```

### 9. 드문 케이스: 컨텍스트 예산 불안

매우 긴 세션에서 새 세션 제안·작업 축소가 나올 수 있습니다. 주로 하네스가 잔여 토큰 카운트를 노출할 때 발생 — **가능하면 카운트를 노출하지 마세요.** 노출해야 한다면:

```text
You have ample context remaining. Do not stop, summarize, or suggest a new session on account of context limits. Continue the work.
```

### 10. 요청이 아니라 이유를 제공

의도를 이해하면 관련 정보에 스스로 연결합니다. 여러 워크스트림을 오가는 장기 에이전트일수록 효과가 큽니다:

```text
I'm working on [the larger task] for [who it's for]. They need [what the output enables]. With that in mind: [request].
```

### 11. 최종 요약의 가독성

긴 에이전트 세션에서 화살표 체인 축약, 과도한 구현 디테일, 사용자가 못 본 사고 참조가 나올 수 있습니다:

```text
Terse shorthand is fine between tool calls (that's you thinking out loud, and brevity there is good). Your final summary is different: it's for a reader who didn't see any of that.

If you've been working for a while without the user watching (overnight, across many tool calls, since they last spoke), your final message is their first look at any of it. Write it as a re-grounding, not a continuation of your working thread: the outcome first, then the one or two things you need from them, each explained as if new. The vocabulary you built up while working is yours, not theirs; leave it behind unless you re-introduce it.

When you write the summary at the end, drop the working shorthand. Write complete sentences. Spell out terms. Don't use arrow chains, hyphen-stacked compounds, or labels you made up earlier. When you mention files, commits, flags, or other identifiers, give each one its own plain-language clause. Open with the outcome: one sentence on what happened or what you found. Then the supporting detail. If you have to choose between short and clear, choose clear.
```

### 12. send_to_user 도구 (비동기 에이전트)

턴을 끝내지 않고 사용자에게 원문 그대로 전달해야 하는 내용(부분 산출물, 구체적 수치가 담긴 진행 보고, 루프 중 질문에 대한 직접 답변)이 있으면 클라이언트 사이드 도구를 제공하세요. 도구 입력은 요약되지 않으므로 원문이 보존됩니다:

```json
{
  "name": "send_to_user",
  "description": "Display a message directly to the user. Use this for progress updates, partial results, or content the user must see exactly as written before the task finishes.",
  "input_schema": {
    "type": "object",
    "properties": {
      "message": {
        "type": "string",
        "description": "The content to display to the user."
      }
    },
    "required": ["message"]
  }
}
```

도구 정의만으로는 거의 호출하지 않습니다 — 시스템 프롬프트에 유도 문구를 짝지으세요:

```text
Between tool calls, when you have content the user must read verbatim (a partial deliverable, a direct answer to their question), call the send_to_user tool with that content. Use send_to_user only for user-facing content, not for narration or reasoning.
```

내레이션·내부 추론을 이 도구로 보내게 하지 마세요 — 과호출은 도구의 목적을 무력화합니다.

## 스캐폴딩 권장 변경

1. **난이도 최상단부터 투입**: 구모델에 맡기던 것보다 어려운 과제를 주고, 스코핑 → 질문 → 실행을 시키세요. 쉬운 작업만 시험하면 역량 범위를 과소평가하게 됩니다.
2. **자기검증을 명시**: 장기 런에서는 `Establish a method for checking your own work at an interval of [X] as you build. Run this every [X interval], verifying your work with subagents against the specification.` — 신선한 컨텍스트의 검증 서브에이전트가 자기비판보다 우수합니다.
3. **기존 프롬프트·스킬 리팩토링**: 구모델용 지시를 제거한 버전과 비교 후 기본 성능이 낫다면 삭제.
4. **추론 재현 지시 금지**: "사고 과정을 응답에 옮겨 써라/설명하라" 류 지시는 `reasoning_extraction` refusal을 유발해 Opus 4.8 fallback을 증가시킵니다. 마이그레이션 시 기존 스킬·시스템 프롬프트에서 reflection/show-your-thinking 지시를 감사(audit)하세요. 추론 가시성이 필요하면 adaptive thinking의 `thinking` 블록(`display: "summarized"`)을 읽고, 장기 런의 진행 노출은 send_to_user 도구를 쓰세요.
5. **send_to_user 도구 추가**: 비동기 에이전트 UX가 원문 전달에 의존하면 필수. 루틴 내레이션만 필요한 에이전트는 기본 요약으로 충분.

## Claude 4.x 가이드와의 차이

| 축 | Claude 4.x ([이전 가이드](./claude-4-best-practices.md)) | Fable 5 |
|----|------------------------------------------------------|---------|
| **지시 밀도** | 명시적·상세 지시 권장 ("above and beyond"는 요청해야) | De-prescribe — 짧은 지시로 조향, 과잉 지시는 품질 저하 |
| **Thinking** | Extended Thinking + `budget_tokens` | 항상 켜진 adaptive, `effort`로만 제어 |
| **Prefilling** | Anthropic 특화 기법으로 활용 | 400 에러 — Structured Outputs로 대체 |
| **Sampling** | `temperature` 조절 가능 | 파라미터 제거 — 프롬프트로 변주 유도 |
| **서브에이전트** | 남발 억제 가이드 필요 | 적극 활용 + 위임 기준 명시 |
| **컨텍스트 인식** | 토큰 예산 추적 지시 활용 | 잔여 카운트 노출 자체를 피할 것 (불안 유발) |
| **think 단어 민감성** | "think" 변형어 회피 (Opus 4.5) | 해당 없음 (thinking 상시 on) |
| **턴 길이** | 일반적 | 수 분~수 시간 기본 — 타임아웃·비동기 구조 선행 |

## 요약

| 특징 | 대응 |
|------|------|
| **최상위 역량, 2배 가격** | 난이도 최상단 작업에 투입, 루틴은 낮은 effort 또는 하위 모델 |
| **강한 지시 따르기** | 지시를 줄이고(De-prescribe) 목표·제약·이유 중심으로 |
| **긴 턴 기본** | 타임아웃·스트리밍·비동기 체크인 선행 조정 |
| **장기 자율 런** | 진행 보고 근거화 + 자기검증 서브에이전트 + 메모리 파일 |
| **병렬 서브에이전트 강함** | 억제 대신 위임 기준 명시 |
| **Safety classifier** | refusal 처리 + Opus 4.8 fallback 구성, 추론 재현 지시 제거 |

**핵심**: "지시를 늘리지 말고, 목표와 이유를 주고, 검증을 시켜라"
