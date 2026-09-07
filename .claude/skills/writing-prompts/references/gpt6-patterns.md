# GPT-6 Astra 프롬프트 패턴

## 목차
- [개요 (5.6 → 6 핵심 변화)](#개요-56--6-핵심-변화)
- [1. 주도성과 완주 (신규)](#1-주도성과-완주-신규)
- [2. 지시 준수 — 감량이 아니라 일관성 (변경)](#2-지시-준수--감량이-아니라-일관성-변경)
- [3. 문체 — 문단 기본, 리스트는 조건부 (변경)](#3-문체--문단-기본-리스트는-조건부-변경)
- [4. 서브에이전트 위임 (신규)](#4-서브에이전트-위임-신규)
- [5. 테스트·검증 범위 축소 (신규)](#5-테스트검증-범위-축소-신규)
- [6. Reasoning Effort (변경)](#6-reasoning-effort-변경)
- [7. 5.6 패턴 호환](#7-56-패턴-호환)
- [8. 마이그레이션 체크리스트 (5.6 → 6)](#8-마이그레이션-체크리스트-56--6)
- [주의 (커뮤니티 관찰, 2차)](#주의-커뮤니티-관찰-2차)
- [참고](#참고)


GPT-6 Astra는 2026-09-03에 나온 단일 모델이며, 5.6의 Sol·Terra·Luna는 계속 제공된다. 프롬프트 관점의 변화는 파라미터가 아니라 행동에 있고, 공식 가이드가 조정을 권고하는 축은 주도성, 지시 준수, 문체, 서브에이전트 위임, 테스트·검증 다섯 가지다. 5.6에서 통하던 "지시를 줄여라" 기조가 여기서 뒤집힌다. Astra는 긴 지시를 더 잘 따르는 대신 문맥에 더 민감해서, 분량보다 지시 파일 사이의 모순이 문제를 일으킨다.

---

## 개요 (5.6 → 6 핵심 변화)

| 항목 | 5.6 | 6 Astra |
|------|-----|---------|
| 모델 라인업 | Sol/Terra/Luna 3티어 | **`gpt-6-astra` 단일** (5.6 3종은 계속 제공) |
| `reasoning.effort` | none~xhigh + max | **low/medium/high/xhigh/max, 기본 medium**. `none`·`minimal` 폐지 |
| 제거 파라미터 | — | **`temperature`·`top_p`·`top_logprobs`** (Chat Completions는 `logprobs`도) |
| 도구 호출 | Responses·Chat Completions | **Responses 전용** |
| 캐싱 | `prompt_cache_options.mode` + `ttl` | `prompt_cache_retention` 폐기 → **`prompt_cache_options.ttl`**(예 `"30m"`) |
| 지시 기조 | 지시 감량 → 토큰·비용 절감 | **길이보다 일관성**. 모순된 지시가 작업을 멈춤 |
| 검증 | 검증 루프를 더 붙이는 방향 | **범위를 좁히는 지시**가 필요 (기본 성향이 과잉 테스트) |
| 위임 | 명시 요청 시에만 스폰 | **프롬프트로 유도**. 공식 자인 "may delegate less often than desired" |
| 컨텍스트·요율 | 1.05M | 1.05M. **입력 272K 초과 시 요청 전체가 입력 2배·출력 1.5배** |

> 상세 가이드: [`reference/openai-prompt-guide/gpt-6-prompt-guide.md`](../../../../reference/openai-prompt-guide/gpt-6-prompt-guide.md)

---

## 1. 주도성과 완주 (신규)

Astra는 이전 세대보다 질문을 더 자주 던지고 그 자리에서 멈춘다. 공식 설명은 협업자로 설계했기 때문이라는 것이다.

> "The model is designed to be a more effective collaborator and is thus more likely to ask the user a question when additional input could materially change the result."

자율 실행이 필요하면 프롬프트에 아래 계열 문장을 직접 넣으라는 것이 공식 권고다(원문 그대로 인용).

```text
Your job is to bias towards action and carry the user's intended task to completion.

When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete. Progress autonomously towards the user's goal unless they are clearly destructive or irreversible.

When the user's prompt indicates a request for action, such as "can you...", "I want to...", "help me..." and similar expressions, treat these as instructions to do the work and take action. Do not stop at acknowledging capability (e.g. "Yes…"), proposing a plan, or offering to continue.
```

확인을 아예 없애라는 뜻은 아니다. 확인은 받되 되돌리기 어려운 행동 직전에 **구체적이고 검토 가능한 결과물**을 놓고 받으라는 것이 원칙이다. 원문은 "The user should be approving a concrete, reviewable result."이며, 읽기 전용 작업이나 세션 앞부분에서 이미 승인된 범위에는 다시 묻지 않는다.

---

## 2. 지시 준수 — 감량이 아니라 일관성 (변경)

> "GPT-6 Astra is better able to follow longer instructions, but can also be more sensitive to information in context."

5.6 마이그레이션의 핵심이 지시 축소였다면, Astra에서는 모순 제거가 핵심이다. 길이 자체는 문제가 아니다. 우선순위는 문장으로 못 박는다.

```text
The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions.
```

```text
If a skill causes you to ask for permission or confirmation, pause, leave requested work unfinished, or diverge from the user's intent, name and link to the exact SKILL.md file you read, quote the relevant instruction, and briefly explain how it applies.
```

두 번째 스니펫은 진단용이다. 모델이 스킬 때문에 멈췄을 때 어떤 파일의 어떤 문장 때문인지 말하게 만들면 감사 대상을 사람이 찾아낼 수 있다. 새 지시를 쓰기 전에 접근 가능한 지시 파일(AGENTS.md·CLAUDE.md·스킬)을 먼저 감사해 어긋나는 문장과 낡은 손잡아주기 지시를 걷어낸다.

---

## 3. 문체 — 문단 기본, 리스트는 조건부 (변경)

기본 성향이 리스트·표·마크다운으로 스캔 가능한 응답을 만드는 쪽이라, 산문을 원하면 명시해야 한다.

```text
Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.
```

**피할 표현** — 아래 블록은 공식 페이지에서 이 세션에 직접 확인한 1차 원문이다.

```text
Avoid using slop words or phrases like "Bottom Line:" in conclusions, "delve," "foster," "leverage," "it's worth noting," "importantly," "Question? Answer." or "This isn't about X. It's about Y.", "genuinely" or hyphenated compound descriptions and adjectives. Do not use concluding summary statements such as "In short:..", "The simplest mental model is:...". Do not use contrastive framing such as "X, not Y" or "X—not Y". Avoid invented compound labels like "exact-head checks", vague qualifiers, and canned transitions.
```

2차 출처(the-decoder 요약)에만 있고 위 원문에서 확인되지 않은 항목은 `promote`, `really/truly`, `what's important is`이므로 1차로 표기하지 않는다. 우리 한국어 문체 규칙([`communication.md`](../../../rules/communication.md))의 상투어·번역투 금지 조항과 방향이 같고, 영문 프롬프트에는 번역본 대신 위 원문을 그대로 넣는 편이 정확하다.

---

## 4. 서브에이전트 위임 (신규)

> "GPT-6 Astra is trained to be able to divide and delegate work to subagents that work in parallel." / "The model may delegate less often than desired for your workflow."

```text
If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality.
```

프롬프트에는 네 가지를 명시한다. **갈래**(어떤 작업을 서브에이전트로 돌릴지, 편집 충돌이 없는 독립 갈래), **리더 보유 범위**(무엇을 리더가 직접 쥐고 있을지), **대기 여부**(모든 결과를 기다릴지 먼저 온 것부터 진행할지), **반환 형식**(각 워커가 어떤 요약을 어떤 구조로 돌려줄지)이다.

Codex의 effort `ultra`는 자동 위임 모드다. 5.6 문서에 나오던 "Sol Ultra"(병렬 서브에이전트 모드)와 이름이 같지만, 이제는 별도 모드가 아니라 추론 강도 값 하나로 노출되며 API 문서에는 없는 제품 표면 전용 단계다.

---

## 5. 테스트·검증 범위 축소 (신규)

Astra는 완료를 선언하기 전에 스스로 과하게 테스트한다. 검증을 더 시키는 지시가 아니라 범위를 좁히는 지시가 필요하다.

```text
Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.
```

5.6 시절에 오버스텝·허위 보고를 막으려고 붙여 둔 검증 루프 지시는 Astra에서 과잉 테스트로 증폭된다. 마이그레이션 시 함께 재평가한다.

---

## 6. Reasoning Effort (변경)

| 설정 | 사용처 |
|------|--------|
| `low` | 5.6에서 `none`·`minimal`을 쓰던 자리의 출발점 |
| `medium` | **기본값**. 품질·비용 균형 |
| `high` | 일반 코딩 작업에 무난한 선택 [2차] |
| `xhigh` | high보다 유의미한 개선이 확인된 고난도 작업 |
| `max` | 가장 어려운 문제만. 전역 기본값으로 쓰지 않음 |

- `none`·`minimal`은 폐지됐다. 원문은 "GPT-6 Astra does not support the `none` reasoning effort."이며, 공식 지침은 해당 사용처를 `low`부터 시작해 비교하라는 것이다. 낡은 설정에 남은 `reasoning_effort = "none"`을 먼저 제거한다
- 비용 격차가 크다. Simon Willison의 펠리컨 비교에서 max effort 한 장이 63센트, 같은 프롬프트가 Luna에서는 1.6센트로 약 40배 차이였다 [2차]. Codex의 `ultra`는 여섯 번째 단계로 제품 표면에만 있고 API 파라미터로는 받지 않는다

---

## 7. 5.6 패턴 호환

5.6의 8섹션 프롬프트 계약(Role / Personality / Goal / Success criteria / Constraints / Tools / Output / Stop rules)은 그대로 유효하다. 이 골격에서 시작하고 §1~§5의 행동 축만 얹는다. 계승되는 기능은 `reasoning.mode: "pro"`(오답 비용이 큰 지점에만 선별 적용), `reasoning.context`(auto/current_turn/all_turns), Programmatic Tool Calling, Structured Outputs, compaction, 멀티에이전트 오케스트레이션이다. 프롬프트 캐싱도 이어지며 키 이름만 `prompt_cache_options.ttl`로 바뀌었다. 상세는 [`gpt56-patterns.md`](./gpt56-patterns.md) 참조.

---

## 8. 마이그레이션 체크리스트 (5.6 → 6)

공식 마이그레이션 7항에 지시 파일 감사를 더한 것이다.

1. [ ] `model`을 `gpt-6-astra`로 설정
2. [ ] `none`·`minimal` effort 사용처는 `low`부터 시작해 비교 — "If you currently use `none` or `minimal`, start with `low` and compare results."
3. [ ] 도구 호출 경로를 Responses API로 이전 — "GPT-6 Astra supports Chat Completions, but tool calling requires Responses."
4. [ ] `temperature`·`top_p`·`top_logprobs` 제거
5. [ ] `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. [ ] EU 데이터 레지던시 환경은 Fast 모드 미지원이므로 호환 확인
7. [ ] 승인 대기로 멈추는 증상은 §1의 주도성 스니펫으로 대응
8. [ ] **지시 파일 감사** — AGENTS.md·CLAUDE.md·스킬에서 모순되거나 낡은 문장을 제거하고 사용자 지시 우선권을 명시 (공식 7항 밖, 우리 추가 항목)

5.6 프롬프트를 그대로 재사용해도 되는지를 명시한 공식 문장은 없다(미확인). 다만 파라미터 변경과 다섯 행동 축 권고를 합치면 사실상 튜닝 패스가 필요하다.

---

## 주의 (커뮤니티 관찰, 2차)

출시 +3일 시점의 관찰이라 표본이 얇다. 설정 기본값의 근거로 쓰지 않는다.

- **질문 과다로 작업이 멈춘다** — 첫 주 최다 불만이며, 프롬프트를 조정하지 않은 사용자는 확인 질문에 답하며 시간을 보냈다는 보고가 반복됐다
- **위임 부족** — `ultra` 미만에서는 기대보다 서브에이전트를 덜 쓴다. OpenAI 자인과 커뮤니티 관측이 일치한다
- **글쓰기 후퇴** — 편집 문체 평가에서 1995 Elo로 11위, 이전 세대 2156보다 낮다. 창작·편집 작업에는 권하지 않는다는 평이 다수다
- **토큰 효율과 비용** — Artificial Analysis 실측에서 코딩 토큰 효율이 Sol 대비 70% 개선됐고 Coding Agent Index는 67.0으로 Sol 65.1보다 높다. 다만 max effort 작업당 비용은 Sol 대비 약 75% 비싸다

---

## 참고

- [GPT-6 Astra Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-6-prompt-guide.md) — 전체 가이드 + 외부 관찰
- [Prompting guidance | OpenAI API (공식)](https://developers.openai.com/api/docs/guides/prompt-guidance)
- [Using the latest model | OpenAI API (공식)](https://developers.openai.com/api/docs/guides/latest-model)
- [gpt-6-astra 모델 카드 (공식)](https://developers.openai.com/api/docs/models/gpt-6-astra)
- [Simon Willison — GPT-6 Astra (2026-09-03)](https://simonwillison.net/2026/Sep/3/gpt6-astra/) [2차]
- [Artificial Analysis — Benchmarking GPT-6 Astra](https://artificialanalysis.ai/articles/benchmarking-gpt-6-astra) [2차]
- [GPT-5.6 패턴 (이전 세대)](./gpt56-patterns.md)
