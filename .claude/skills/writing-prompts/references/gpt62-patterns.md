# GPT-6.2 프롬프트 패턴 (Astra·Sol)

대상 모델: `gpt-6.2-astra` · `gpt-6.2-sol`

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [개요 (6 → 6.2 핵심 변화)](#개요-6--62-핵심-변화)
- [0. 두 모델과 API 계약](#0-두-모델과-api-계약)
- [1. 문체 — 기본이 간결 (반전)](#1-문체--기본이-간결-반전)
- [2. 작업 완주 (변경)](#2-작업-완주-변경)
- [3. 코딩 스타일 (신규)](#3-코딩-스타일-신규)
- [4. 프런트엔드 디자인 (신규)](#4-프런트엔드-디자인-신규)
- [5. 막힌 일과 가정 공개 (신규)](#5-막힌-일과-가정-공개-신규)
- [6. 접두사 유지 (신규)](#6-접두사-유지-신규)
- [7. Reasoning Effort](#7-reasoning-effort)
- [8. 6 패턴 호환](#8-6-패턴-호환)
- [9. 마이그레이션 체크리스트 (6 → 6.2)](#9-마이그레이션-체크리스트-6--62)
- [주의 (커뮤니티 관찰, 2차)](#주의-커뮤니티-관찰-2차)
- [참고](#참고)


GPT-6.2는 2026-11-17에 Astra와 Sol 두 모델로 나왔다. 6.2 Astra는 6 Astra의, 6.2 Sol은 6.1 Sol의 후속이고, Terra와 Luna에는 6.2가 없어 공식 대표 목록은 6.2 Astra·6.2 Sol·6.1 Terra·6 Luna다. 이 문서에서 "Astra"와 "Sol"은 6.2 모델을 가리키고 이전 모델은 "6 Astra", "6.1 Sol"처럼 버전을 붙여 적는다. 6.1 Terra와 6 Luna는 [gpt6-patterns.md](gpt6-patterns.md)를 본다. API 계약은 6 Astra·6.1 Sol과 거의 같고, 프롬프트 쪽에서 방향이 바뀐 곳이 있다. 6 Astra는 장황함과 과잉 테스트를 눌러야 했는데 6.2는 기본이 간결해서, 이전 세대용 간결화 지시를 그대로 가져오면 필요한 단서와 막힌 일 보고까지 깎일 수 있다.

---

## 작성 체크리스트

- [ ] **모델 선택**: `gpt-6.2-astra`(가장 어려운 작업, 1M당 $8 / $40)/`gpt-6.2-sol`(일상 작업과 대규모 에이전트, 비용 우선, $2 / $10). 시각 이해·화면 조작 위주면 `gpt-6.1-terra`, 반복 대량 작업이면 `gpt-6-luna`
- [ ] 아래 행동 항목은 6.2 Astra와 Sol에서 관찰된 성향이 출처. 공식 사용법은 "If you recognize one in your own application, try the prompt in that section."이므로 증상이 보일 때 넣는다
- [ ] **간결화 지시 재검토**: 기본 문체가 간결하고 직접적 → "be concise"·분량 상한 지시를 지우거나 "반드시 남길 것" 목록으로 바꿈
- [ ] **누락 방지**: 막힌 일, 하지 못한 일, 세운 가정을 최종 답변에 적게 함. API 직접 호출에는 Codex의 개발자 프롬프트가 적용되지 않으므로 넣기를 권한다(이 문서의 권고, §5)
- [ ] **완주**: 다음 단계 제안이나 계획으로 턴을 끝내지 않게 하고, 멈춰도 되는 경우(범위가 크게 바뀜, 실제로 막힘, 사용자가 정할 결정, 되돌릴 수 없는 행동 직전)만 남김
- [ ] **코딩**: 저장소 관례(기존 로직 재사용, 변경 범위, 테스트를 더하는 조건)를 적음. 새 테스트는 요청·저장소 규칙·특정 회귀가 있을 때만
- [ ] **프런트엔드**: 쓸 이미지 종류와 서체를 지정하고 장식용 번호·배지·중복 제목을 빼게 함
- [ ] `reasoning.effort`: 새 통합은 `medium`에서 시작, `none`·`minimal`을 쓰던 자리는 `low`. `none`은 거부된다. `ultra`는 Codex·ChatGPT 전용(API 값 아님)
- [ ] **API**: 도구 호출은 Responses API, `temperature`·`top_p`·`top_logprobs` 제거, 캐시는 `prompt_cache_options.ttl`. 입력 272K 초과 시 요청 전체에 입력·캐시 2배, 출력 1.5배 요율
- [ ] **접두사 유지**: 응답 사이에 `tools`·`instructions`·`text.format`·`reasoning.effort`와 지난 이력을 바꾸지 않고 덧붙임. `safety_identifier`는 한 대화 내내 같게
- [ ] 6 가이드의 지시 파일 감사·위임 스니펫은 6.2 가이드에 없음 → 증상이 있을 때만 [gpt6-patterns.md](gpt6-patterns.md)에서 가져옴

---

## 개요 (6 → 6.2 핵심 변화)

| 항목 | 6 Astra · 6.1 Sol | 6.2 Astra · 6.2 Sol |
|------|-------------------|---------------------|
| 모델 ID | `gpt-6-astra` · `gpt-6.1-sol` | **`gpt-6.2-astra` · `gpt-6.2-sol`** |
| 가격 (1M당 in/캐시/out) | $10 / $1 / $50 · $2 / $0.10 / $10 | **$8 / $0.40 / $40** · $2 / $0.10 / $10 |
| `reasoning.effort` | `low`~`max`, `none` 미지원 | `none` 거부. 새 통합의 시작 권고가 **`medium`**으로 명시됨 |
| 도구 호출·샘플링 파라미터 | Responses 전용, `temperature`·`top_p`·`top_logprobs` 제거 | 같음 |
| 추론 항목이 입력에서 빠지는 조건 | 모델 계열 변경·하향, 조직·사용자 변경 | 여기에 **접두사 편집과 `safety_identifier` 변경** 추가 |
| 기본 문체 | 자세하고 서식이 많음 → 산문 유도·피할 표현 목록 | **간결하고 직접적** → 간결화 지시 재검토, 독자 맥락 보강 |
| 멈추는 모양 | 질문을 던지고 멈춤 | **다음 단계를 제안하고 확인을 기다림** |
| 테스트 | 과잉 테스트 → 두 문단짜리 범위 축소 지시 | 코딩 스타일의 한 줄 "Skip new tests unless requested, …" |
| 새 축 | — | **코딩 스타일, 프런트엔드 디자인** |
| 가이드에서 빠진 축 | — | 지시 준수, 서브에이전트 위임 |
| 시스템 카드 시험에서 늘어난 것 | — | **막힌 일을 보고에서 빠뜨림**, 확인되지 않은 세부를 사실처럼 다룸 |

> 상세 가이드: [`reference/openai-prompt-guide/gpt-6.2-prompt-guide.md`](../../../../reference/openai-prompt-guide/gpt-6.2-prompt-guide.md)

---

## 0. 두 모델과 API 계약

| 항목 | 6.2 Astra | 6.2 Sol |
|------|-----------|---------|
| 모델 카드 소개 | "Our most capable model for your hardest projects, from start to finish." | "Our go-to model for everyday work, from coding to powering agents at scale." |
| 가격 (1M당 in / 캐시 in / out) | $8 / $0.40 / $40 | $2 / $0.10 / $10 |
| 컨텍스트 / 최대 출력 | 1,050,000 / 128,000 | 같음 |
| 지식 컷오프 | 2026-05-18 | 2026-06-01 |
| 입력 | 텍스트, 이미지 | 같음 |
| `reasoning.effort`의 `none` | 거부 | 거부 |
| Chat Completions 도구 호출 | 불가 (Responses 필요) | 불가 (Responses 필요) |
| `temperature`·`top_p`·`top_logprobs` | 제거 | 제거 |

- 두 모델의 계약은 서로 같고 6 Astra·6.1 Sol과도 거의 같다. 6 Astra·6.1 Sol에서 옮길 때 요청 형식에서 고칠 것은 모델 ID뿐이다. 단, 이력을 고치지 않는 단발 요청이고 두 세대가 함께 지원하는 옵션만 쓸 때 그렇다. Ultrafast의 EU 레지던시처럼 옵션이 갈리는 곳은 따로 확인한다. 6.1 Terra·6 Sol·Luna에서 옮기면 `none` 요청이 거절되고, 6 Sol·Luna에서는 `none`일 때만 되던 Chat Completions 함수 호출도 사라진다(6.1 Terra는 이미 불가였다)
- Astra는 6 Astra보다 입력·출력이 20%, 캐시 입력이 60% 싸다. Sol은 6.1 Sol 요율 그대로다. 긴 입력 할증(입력 272K 초과 시 요청 전체가 입력·캐시 2배, 출력 1.5배)도 그대로다
- 공식 모델 선택 가이드는 작업 유형 여섯 가지 모두에서 적합도 순서를 6.2 Astra, 6.2 Sol, 6.1 Terra, Luna로 둔다. 기존 코드베이스의 버그 수정과 기능 추가, 검토받을 초안은 Sol·Medium이 예시다
- Sol 전용 프롬프팅 가이드는 없다. "Using GPT-6.2"는 두 모델을 함께 다루고 스니펫을 "a starting point across the GPT-6.2 model family"로 제시한다
- 가이드의 스니펫은 Codex가 6.2에 주입하는 기본 지시문과 문장을 공유한다. 코딩 절은 API 가이드가 네 항목, Codex 지시문이 일곱 항목이다. API로 Codex와 비슷한 행동을 내려면 아래 스니펫이 출발점이다

---

## 1. 문체 — 기본이 간결 (반전)

> "The model's writing tends to be more concise and direct by default. When migrating, revisit instructions like "be concise" in your system prompt."

6 Astra에서는 장황함과 서식을 눌렀고, 6.2에서는 정밀함과 독자 맥락을 채운다. 6 가이드의 산문 유도 스니펫과 피할 표현 목록은 6.2 가이드에 없다. 이전 세대용 프롬프트에 남은 "짧게" 계열 지시는 근거와 단서까지 깎을 수 있으므로 지우거나, 분량 대신 반드시 남길 내용을 적는 문장으로 바꾼다.

협업 상대로 쓸 때(원문 그대로 인용):

```text
Write using terminology the user and sources use. Keep technical details and use domain-specific language when they make the explanation more precise. Use the active voice and keep closely related details together. Cover the key points up front, and avoid references that the reader can only make sense of later in the response. Give the user enough context to follow your reasoning.
```

사용자를 대신해 밖으로 나갈 글을 쓸 때:

```text
When drafting a message or any other material on behalf of the user to be sent to an external audience, consider who will read it and tailor the content to that intended audience. The intended audience likely does not have the same context as the user, so ensure that you provide the background information or reasoning required for the audience to understand the content. When reviewing or editing existing content, preserve the author's content and wording, and follow the user's instruction carefully for what edits they want.
```

긴 작업 뒤 최종 답변에 작업 중 약어가 섞일 때:

```text
Treat your final answer as the user's first look at your work, and not as a continuation of intermediate commentary. The final answer must always be fully self-contained: users should never need to read earlier commentary updates for context, since they are collapsed when the final answer is shown to the user.

Write the final answer and all other human-facing material anew for the intended reader. Do not copy or closely paraphrase your reasoning or adopt its writing style. Do not carry over working shorthand, jargon, or abbreviations from your reasoning, tool calls, or instructions to subagents and automations.
```

---

## 2. 작업 완주 (변경)

> "When the user's intent is unclear, the model may propose a next step and wait for confirmation. For longer tasks, give it room to make reasonable assumptions and keep working."

6 Astra의 증상은 질문하고 멈추는 것이었고, 6.2의 증상은 다음 단계를 제안하고 확인을 기다리는 것이다. 감독 없이 진행해도 되는 작업에는 끝낼 결과와 사용자가 정해야 할 결정을 적는다.

```text
Avoid stopping to end the turn while the task is incomplete or if there is an authorized next step you can take, and instead take the next steps within task scope to progress the user's request. If your final response before ending the turn is a suggested next step, a plan, a request to the user for a routine decision, instructions for a task to execute, or similar handoff to the user, take these steps yourself to make progress towards what the user asked for. Make sure that you have authorization to do so, and flag any assumptions or decisions you make to the user.

Only stop to clarify with the user if there is significant change in task scope, you are concretely blocked, have a decision that the user needs to resolve, or before irreversible or destructive actions.
```

세부가 불분명할 때 가정을 밝히고 계속하게 하는 문장:

```text
Make reasonable, reversible assumptions to carry work forward and state them if it progresses the task within scope. Do not second guess yourself, stop after describing what you could do, offer to do the work, or provide a partial answer unless there is no way you can proceed.
```

끝내기 전 자기 점검은 "Before ending a turn or calling your work complete, check that your work fully satisfies what the user asked for. If any steps remain or any part of the result still needs verification, follow through on this work before finishing."로 건다. 높은 effort가 긴 작업의 마지막 점검까지 끌고 가는 데 도움이 된다는 것이 공식 설명이다. 앱에 비동기 질문 도구(`request_user_input_async`처럼 `async: true`로 정의한 함수)를 두면 모델이 질문을 던져 놓고 답과 무관한 일을 계속한다.

가정을 세우고 계속하게 할 때는 스니펫의 "state them", "flag any assumptions"를 빼지 않는다. 6.2는 확인되지 않은 세부를 사실처럼 다루는 일이 늘었다(§5).

---

## 3. 코딩 스타일 (신규)

> "The model tends to write more efficient, high-quality code than its predecessors. Describe any project conventions that should guide how it writes or edits code."

프롬프트에 적을 것은 저장소의 관례다. 기존 로직을 언제 재사용할지, 변경 범위를 얼마나 좁힐지, 기존 테스트가 못 잡는 동작에 언제 테스트를 더할지를 적는다.

```text
Above all, be thorough in producing high-quality, correct code that completely fulfills the user's task. Keep the code easy to read and verify that the user-requested outcome works as they intend. Follow these instructions when coding:

(a) Reuse existing logic in the user's repo when you can. You should reuse existing classes, methods, representations, and APIs in the codebase as long as they preserve correctness. Before consolidating or removing code, preserve the behavior its callers rely on unless the task requires changing it.
(b) Skip new tests unless requested, required by the repo, or needed to catch a specific regression existing tests would miss.
(c) Make sure that code is human readable. Do not use fewer lines, shorter variable names, minified formatting, or dense one-liners as substitutes for simplicity. Ensure that comments and variable names are readable and understandable to a human. Code-golfed expressions count as overly complex when they encode many branches, conditions, or hidden assumptions.
(d) Avoid unnecessary indirection and abstraction. Helper functions, utility functions, and class abstractions can add cognitive complexity even when they do not add branches.
```

(b)가 6 Astra 가이드의 테스트 범위 축소 스니펫을 대신한다. (c)는 "단순하게"라는 지시가 줄 수 줄이기나 한 줄 압축으로 번지는 것을 막는다.

---

## 4. 프런트엔드 디자인 (신규)

> "If the interface needs a particular look, specify the imagery and typography it should use."

```text
When generating webpages or apps with a frontend user interface, follow these instructions:

- When choosing visuals, generally prefer realistic images from ImageGen or image search that suit the project's style and purpose. Use SVGs when the user specifically asks for them.
- Include a text element only when it provides information the user needs, helps them navigate or act, or fulfills an explicit content request. Remove decorative numbering, filler badges, redundant headings, and explanatory copy that merely restates what the surrounding interface already makes clear, while preserving necessary labels, instructions, and status feedback.
```

말로 설명하기 어려운 모습은 참조 이미지로 준다. 디자인 도구에서 가져오거나 이미지 생성 도구를 열어 주고 만들게 한 뒤, 그 이미지와 대조해 만들고 렌더링하고 다듬게 한다.

---

## 5. 막힌 일과 가정 공개 (신규)

공식 프롬프팅 가이드에는 없고 시스템 카드와 발표문에 있는 축이다. 시스템 카드의 두 시험에서 6.2는 막힌 일을 최종 답변에서 빠뜨린 비율이 이전 모델보다 높았다.

| 평가 (시스템 카드) | 6 Astra · 6.1 Sol | 6.2 Astra · 6.2 Sol | Codex 개발자 프롬프트를 넣은 6.2 |
|------|-------|-------|-------|
| 작업을 막은 장애물을 최종 답변에서 빠뜨린 비율 | 11.09% · 14.00% | **22.28% · 24.08%** | 8.04% · 8.88% |
| 검색 도구가 꺼져 있는데 알리지 않은 비율 | 7.58% · 2.75% | **23.00% · 9.33%** | 8.50% · 3.92% |
| 738개 준수 사례의 전체 통과율 | 90.2% (6 Astra) | 87.8% · 87.1% | — |

- 두 시험은 문제 행동을 끌어내도록 설계된 것이라 실제 사용에서의 빈도가 아니다. 셋째 줄의 하락은 상당 부분 요구된 단서를 빠뜨리거나 미확인 세부를 사실로 다룬 응답에서 나왔다
- OpenAI가 든 원인은 가설이다("our efforts to make responses concise and avoid excessive caveats may be related to the model omitting important obstacles"). 짧게 쓰라는 지시 하나의 효과를 잰 실험은 아니다
- Codex에는 누락을 줄이는 개발자 프롬프트가 들어갔지만 "The Codex developer prompt used in these evaluations is not applied to direct API requests."다. API로 에이전트를 돌릴 때 같은 취지의 문장을 넣는 것은 이 문서의 권고다
- 시스템 카드는 그 프롬프트의 문구를 밝히지 않았다. Codex의 6.2 기본 지시문에서 이 축에 해당하는 문장은 아래와 같다. 시험에 쓰인 문구가 이것이라는 대응은 추정이므로, 그대로 옮겨야 하는 검증된 문구가 아니라 API 프롬프트의 출발점으로 쓴다

```text
In your final answer back to the user, mention any relevant flaws in your work or any decisions you made without explicit guidance from the user, so that the user can verify your approach and work. Disclosure in commentary alone is not enough. You MUST repeat any such disclosures in the final answer.

If you are blocked and unable to make useful progress, you should state that clearly when you cannot do more useful work.

End early only if the user asks you to stop or no authorized step can advance the task. In that case, state what remains and the specific blocker.
```

분량 상한을 둘 때는 "못 한 일, 없던 파일이나 실패한 도구, 세운 가정은 분량과 무관하게 적는다"처럼 예외를 함께 적는다.

---

## 6. 접두사 유지 (신규)

> "Starting with GPT-6.2, the API will drop reasoning items when it detects mid-conversation changes to the conversation history (prefix edits), model downgrade, end user, or organization. When the model loses access to reasoning items, answer quality can decline and the model may use more tokens to repeat earlier work."

프롬프트 문장이 아니라 프롬프트를 싣는 방식의 문제다. 추론 항목보다 앞에 있는 이력이나 요청 파라미터를 바꾸면 API가 그 추론 항목을 입력에서 빼고, 모델은 앞선 추론을 다시 해야 할 수 있다. 시스템 프롬프트를 턴마다 고쳐 쓰거나 도구 목록을 요청마다 바꾸는 설계가 여기에 걸린다.

| 하려는 일 | 접두사를 지키는 방법 |
|-----------|----------------------|
| effort·출력 스키마 변경 | 요청의 `reasoning.effort`·`text.format`은 그대로 두고 `configuration_update` 항목을 덧붙임 |
| 도구 추가·제한 | `tools`는 그대로 두고 `additional_tools` 항목으로 추가, 제한은 `tool_choice`의 `allowed_tools` |
| 지시 갱신 | 원래 개발자 메시지를 고치지 않고 새 `developer` 메시지를 덧붙임 |
| 압축 | OpenAI 압축을 쓰거나, 자체 압축이면 압축 항목을 문맥 끝에 둠 |
| 도구 출력 줄이기 | 나중에 줄이지 않고 처음 보낼 때 줄임 |

`configuration_update`는 표준 단일 에이전트 Responses 요청에서만 쓰고 다음 사용자 메시지 앞에 넣는다. 이 항목이 든 이력은 독립 압축 엔드포인트(`/responses/compact`)가 거부하므로 자동 압축(`context_management`)을 쓰거나 [공식 절차](https://developers.openai.com/api/docs/guides/compaction#continue-with-configuration-updates-and-tools)를 따른다.

`safety_identifier`도 조건이다. 항목을 만든 요청과 다시 쓰는 요청의 값이 다르면, 한쪽에만 넣은 경우까지 포함해 추론 항목이 입력에서 빠진다. 무엇이 왜 빠졌는지는 응답의 `input_transformations`(`prefix_mismatch`, `end_user_mismatch`)로 본다. 코드 쪽 구현은 `llm-api-guide` 스킬이 맡는다.

---

## 7. Reasoning Effort

**API `reasoning.effort`**

| 설정 | 6.2 Astra·6.2 Sol | 사용처 |
|------|-------------------|--------|
| `none` | 거부 | — |
| `low` | 지원 | `none`·`minimal`을 쓰던 자리의 출발점. 분명한 지시서를 다듬는 일 |
| `medium` | 새 통합의 시작 권고 | 품질·비용 균형 |
| `high` | 지원 | 긴 작업의 마지막 점검까지 끌고 가야 할 때 |
| `xhigh` | 지원 | 시험과 수정이 반복되는 작업, 열린 문제 |
| `max` | 지원 | 가장 어려운 문제만 |

- 시작 권고 원문은 "Start with `medium` for a new integration. If you currently use `none` or `minimal`, use `low` instead."다. 6 가이드의 "현재 값을 유지하라"는 문장은 없다
- 6.2 모델 카드와 추론 가이드는 `none` 거부만 적고 허용 값 목록과 기본값을 싣지 않는다. 위 표의 다섯 단계는 ARC Prize가 6.2 두 모델을 단계별로 측정한 결과와 Codex 카탈로그에서 확인한 값이다. 기본값이 문서에 없으므로 값을 생략하지 않고 명시한다
- 6.2는 같은 effort에서 이전 모델보다 추론 토큰을 덜 쓴다(시스템 카드). 이전 모델에서 맞춘 effort를 그대로 옮기지 말고 다시 잰다

**Codex 선택기 effort** (API 값과 별개)

| 모델 | 선택 가능한 값 | 공식 시작 권고 | 카탈로그 기본값 |
|------|----------------|----------------|-----------------|
| 6.2 Sol | `low`~`max`, `ultra` | 클라이언트가 고른 값에서 시작 | `low` |
| 6.2 Astra | `low`~`max`, `ultra` | 클라이언트가 고른 값에서 시작 | `low` |

- Codex 가이드의 조합 예시는 빠른 조사 Medium, 의심 원인 하나를 여러 시스템에 걸쳐 추적 High, 여러 원인이 얽힌 조사 Extra High다
- `ultra`는 요청에 `xhigh`로 실리고 적극 위임 힌트가 붙는 선택기 값이다. `max`보다 높은 단계가 아니다

---

## 8. 6 패턴 호환

5.6의 프롬프트 계약 골격(Role / Personality / Goal / Success criteria / Constraints / Tools / Output / Stop rules)은 그대로 쓴다. Structured Outputs와 압축도 그대로다. `reasoning.context`는 예외로 둔다. 추론 가이드의 `all_turns` 지원 목록이 6.1 Sol에서 끝나고 6.2는 캐싱 예시에만 나오므로, 6.2에서는 값을 생략하거나 `auto`로 두고 응답에 찍힌 실제 `reasoning.context`를 확인한다. 6 Astra용 행동 스니펫은 아래처럼 다룬다.

| 6 가이드의 축 | 6.2에서 |
|---------------|---------|
| 주도성 ("bias towards action", "can you..." 실행 해석) | §2의 6.2판 스니펫으로 교체 |
| 문체 (산문 유도, 피할 표현 목록) | 기본이 간결하므로 뺀다. 필요하면 §1 |
| 테스트 범위 축소 | §3의 (b) 한 줄로 교체 |
| 지시 준수 (지시 파일 감사, 사용자 > 스킬) | 6.2 가이드에 없음. 시스템 카드의 내부 Codex 평가에서 지시 위반 표시가 이전 모델보다 늘었으므로(6.2 Astra 2.87%, 6 Astra 1.96%) 감사는 계속 유효 |
| 서브에이전트 위임 | 6.2 가이드에 없음. Codex 가이드는 "use subagents as needed"로 허락하라고 권함. 증상이 있을 때만 [gpt6-patterns.md](gpt6-patterns.md) §4 |

---

## 9. 마이그레이션 체크리스트 (6 → 6.2)

1. [ ] `model`을 `gpt-6.2-astra` 또는 `gpt-6.2-sol`로 설정
2. [ ] effort — 새 통합은 `medium`, `none`·`minimal`은 `low`로
3. [ ] 도구 호출은 Responses API로("GPT-6.2 Astra and GPT-6.2 Sol support Chat Completions, but tool calling requires Responses.")
4. [ ] `temperature`·`top_p`·`top_logprobs` 제거 (Chat Completions는 `logprobs`도, Responses는 `include`의 `message.output_text.logprobs`도)
5. [ ] GPT-5.5 이하에서 옮길 때 `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. [ ] 접두사 감사 — 응답 사이에 요청 파라미터와 지난 이력을 바꾸는 곳을 §6 방식으로 고치고 `safety_identifier`를 일관되게 (공식 마이그레이션 항목 밖, 같은 가이드의 접두사 절에서 가져온 항목)
7. [ ] ZDR을 쓰면 여러 턴 작업에서 이전 출력 항목을 암호화된 추론 항목까지 순서대로 다시 보냄
8. [ ] EU 데이터 레지던시에서는 Ultrafast 불가 (Standard·Fast·Batch는 가능)
9. [ ] **프롬프트 재검토** — 간결화 지시, 6 Astra용 테스트 축소·산문 유도 스니펫을 걷어내고 §5의 공개 문장을 넣음 (공식 마이그레이션 항목 밖, 시스템 카드에서 가져온 우리 추가 항목)

---

## 주의 (커뮤니티 관찰, 2차)

출시 다음 날의 관찰이라 표본이 얇다. 설정 기본값의 근거로 쓰지 않는다. 비교하려고 함께 인용한 LifeVal은 OpenAI 자체 평가다.

- **지나친 압축** — 사전 사용자들의 공통 불만이다. "its writing is hard to understand, and it gives short answers when long answers would be appropriate"(Dan Shipper), "the most unparsable outputs of any llm I've used this year"(Theo Browne). §1의 독자 맥락 스니펫과 §5의 공개 문장이 대응이다
- **일찍 멈춤** — 실제 코딩 작업에서 자주 일찍 멈춘다는 보고와, 사용자가 답할 수 없는 내부 세부를 물으며 스스로 막힌다는 보고가 있다. 반대로 이전 OpenAI 모델보다 끝까지 반복한다는 후기도 있어 평가가 갈린다
- **코딩 에이전트 지표는 제자리** — Artificial Analysis Coding Agent Index(Codex 하네스, max)에서 Astra 53.5(6 Astra 53.1), Sol 48.6(6.1 Sol 52.2)이다. Sol 하락의 원인은 저장소 질의응답에서 핵심 사실을 빠뜨린 것("more likely than its predecessor to omit key facts in its responses")이다. 종합 지능 지수는 Astra 62.1, Sol 57.3으로 올랐다
- **`max`가 늘 최선은 아니고 `low`는 약해진 곳이 있다** — 같은 측정에서 Sol은 xhigh(49.8)가 max(48.6)보다 높다. OpenAI 발표 차트의 LifeVal에서 Sol low는 25.3%로 6.1 Sol low(66.8%)보다 크게 낮다. 같은 effort끼리 견주면 Astra는 medium부터, Sol은 high부터 전작을 앞선다
- **실행 조건이 점수를 크게 바꾼다** — ARC Prize의 ARC-AGI-3 검증 점수에서 Astra는 메모만 넘기는 하네스에서 70.3%(max), 추론 상태를 보존하고 압축을 쓰는 하네스에서 100.0%(xhigh)·99.8%(max)다. 여러 조건이 함께 달라지므로 §6의 접두사 유지 하나의 효과로 읽지 않는다

---

## 참고

- [GPT-6.2 Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-6.2-prompt-guide.md) — 전체 가이드, API 계약, Codex 기본 지시문 차이표, 시스템 카드 요점
- [Using GPT-6.2 | OpenAI API (공식, 버전 고정 주소)](https://developers.openai.com/api/docs/guides/latest-model/gpt-6.2-astra)
- [Keep the prefix unchanged | OpenAI API (공식)](https://developers.openai.com/api/docs/guides/keep-prefix-unchanged)
- 모델 카드 (공식): [gpt-6.2-astra](https://developers.openai.com/api/docs/models/gpt-6.2-astra) · [gpt-6.2-sol](https://developers.openai.com/api/docs/models/gpt-6.2-sol)
- [GPT-6.2 Astra and Sol 시스템 카드 (공식)](https://deploymentsafety.openai.com/gpt-6-2-astra-sol)
- [GPT-6.2 Astra·Sol 조사](../../../../reference/research/research-gpt62.md) — 출시 근거, 발표 수치, Codex 카탈로그와 기본 지시문, 3자 평가와 후기 [2차 포함]
- [GPT-6 패턴 (이전 세대, 6.1 Terra·6 Luna 현행)](./gpt6-patterns.md)
