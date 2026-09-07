# GPT-6 Astra Prompting Guide

> **출처**:
> - [Prompting guidance | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance)
> - [Using the latest model | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
> - [gpt-6-astra 모델 카드](https://developers.openai.com/api/docs/models/gpt-6-astra)
> - [GPT-6 Astra 시스템 카드](https://deploymentsafety.openai.com/gpt-6-astra)
> - [Codex models | OpenAI](https://learn.chatgpt.com/docs/models)
> - [Simon Willison — GPT-6 Astra (2026-09-03)](https://simonwillison.net/2026/Sep/3/gpt6-astra/)
>
> **검증일**: 2026-09-07
> **이전 버전**: [GPT-5.6 Prompting Guide](./gpt-5.6-prompt-guide.md)
> **조사 원문**: [research-gpt6.md](../research/research-gpt6.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.6 → 6)

GPT-6 Astra는 2026-09-03에 출시된 단일 모델입니다. 5.6의 Sol·Terra·Luna는 은퇴하지 않고 계속 제공되며, Astra가 그 위에 한 층 얹힙니다.

프롬프트 관점에서 이번 세대의 변화는 파라미터가 아니라 행동에 있습니다. Astra는 질문을 더 자주 던지고 그 자리에서 멈추며, 완료를 선언하기 전에 스스로 과하게 테스트하고, 기대보다 서브에이전트를 덜 씁니다. 세 가지 모두 OpenAI가 공식 문서에서 직접 인정한 성향이고, 대응 방법으로 프롬프트 스니펫을 제시합니다.

5.6 마이그레이션의 핵심이 "지시를 줄여라"였다면 이번에는 방향이 다릅니다. Astra는 긴 지시를 더 잘 따르지만 문맥에 더 민감해서, 분량보다 지시 파일 사이의 모순이 실패를 만듭니다. 새 문장을 쓰기 전에 기존 지시 파일을 먼저 감사하십시오.

### 한 페이지 변화 요약

| 항목 | 5.6 | 6 Astra |
|------|-----|---------|
| 모델 라인업 | Sol/Terra/Luna 3티어 + `gpt-5.6` 별칭 | **`gpt-6-astra` 단일**(스냅샷 1종). 5.6 3종은 계속 제공 |
| 지식 컷오프 | 2026-02-16 | **2026-04-30** (컨텍스트 1,050,000·최대 출력 128,000은 동일) |
| 가격 (1M당 in/out) | Sol $5 / $30 | **$10 / $50**. 캐시 입력 $1, 캐시 쓰기 $12.50 |
| 롱컨텍스트 요율 | 272K 초과 시 가중 | 동일. **입력 272K 초과 시 요청 전체가 입력 2배·출력 1.5배** |
| `reasoning.effort` | none~xhigh + max | **low/medium/high/xhigh/max**, 기본 medium. `none`·`minimal` 폐지 |
| 제거 파라미터 | — | **`temperature`·`top_p`·`top_logprobs`** (Chat Completions는 `logprobs`도) |
| 도구 호출 | Responses·Chat Completions | **Responses 전용** |
| 캐싱 | `prompt_cache_options.mode` + `ttl` | `prompt_cache_retention` 폐기 → **`prompt_cache_options.ttl`** |
| 지시 기조 | 지시 감량으로 토큰·비용 절감 | **길이보다 일관성**. 모순된 지시가 작업을 멈춤 |
| 검증 | 검증 루프를 더 붙임 | **범위를 좁히는 지시**가 필요 |
| 위임 | 명시 요청 시에만 스폰 | **프롬프트로 유도**해야 함 (미지원: Realtime·Assistants·파인튜닝·임베딩) |

---

## 1. effort 선택과 ultra (5.6의 "모델 선택"을 대체)

5.6에서는 Sol·Terra·Luna 중 무엇을 고르느냐가 가장 큰 비용 레버리지였습니다. GPT-6에는 티어가 없으므로 그 자리를 추론 강도 선택이 대신합니다.

| 단계 | 사용처 | 상태 |
|------|--------|------|
| `low` | 5.6에서 `none`·`minimal`을 쓰던 자리의 출발점 | API 지원 |
| `medium` | **기본값**. 품질·비용 균형 | API 지원 |
| `high` | 일반 코딩 작업에 무난한 선택 (2차) | API 지원 |
| `xhigh` | high보다 유의미한 개선이 확인된 고난도 작업 | API 지원 |
| `max` | 가장 어려운 문제만. 전역 기본값 금지 | API 지원 |
| `ultra` | 자동 위임을 포함한 최대 추론 | **API 문서에 없음.** Codex·ChatGPT 제품 표면 전용 |

### ultra의 정체

`ultra`는 여섯 번째 단계로, 단일 에이전트 실행을 넘어 서브에이전트에 작업을 자동 분배합니다.

> "Ultra mode goes beyond a single-agent run. It uses subagents to accelerate complex work, making it useful for larger tasks that can be split across subagents."

5.6 문서에 나오던 "Sol Ultra"는 병렬 서브에이전트 모드라는 별도 개념이었습니다. GPT-6에서는 같은 이름이 추론 강도 값 하나로 노출됩니다. Codex 모델 카탈로그의 설명도 이 취지와 같습니다. `ultra`는 "Maximum reasoning with automatic task delegation", `max`는 "Maximum reasoning depth for the hardest problems"로 구분됩니다.

공식 안내는 "most tasks do not need Max or Ultra"입니다.

**상태: 상충.** API 모델 문서와 마이그레이션 가이드는 low~max만 열거하고 ultra를 언급하지 않는 반면, learn.chatgpt.com 모델 문서와 로컬 Codex 캐시는 정식 단계로 싣습니다. 현재 판단은 제품 표면 전용이며 API 호출로는 미확인입니다.

**dotfiles 적용**: 우리 `.codex/config.toml`은 `model_reasoning_effort = "high"`입니다. Astra 기본값 medium 대비 한 단계 상향한 의도적 선택입니다. `ultra`는 전역 값으로 고정하지 않고 필요할 때 세션에서 선택합니다.

---

## 2. Migration: 5.6 → 6

공식 마이그레이션 절이 요구하는 항목은 일곱 가지입니다. 여기에 우리 쪽 추가 항목 하나를 더했습니다.

### 마이그레이션 체크리스트

1. [ ] `model`을 `gpt-6-astra`로 설정
2. [ ] `none`·`minimal` effort 사용처는 `low`부터 시작해 비교 — "If you currently use `none` or `minimal`, start with `low` and compare results."
3. [ ] 도구 호출 경로를 Responses API로 이전 — "Use the Responses API. GPT-6 Astra supports Chat Completions, but tool calling requires Responses."
4. [ ] `temperature`·`top_p`·`top_logprobs` 제거 (Chat Completions는 `logprobs`도)
5. [ ] `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. [ ] EU 데이터 레지던시 환경은 Fast 모드 미지원 — "Fast mode is unavailable for GPT-6 Astra with EU data residency."
7. [ ] 승인 대기로 멈추는 증상은 §4.1 주도성 스니펫으로 대응
8. [ ] **(추가) 지시 파일 감사** — AGENTS.md·CLAUDE.md·스킬에서 모순되거나 낡은 문장을 제거하고 사용자 지시 우선권을 명시

5.6 프롬프트를 그대로 써도 되는지를 직접 밝힌 공식 문장은 **없습니다(미확인)**. 다만 마이그레이션 절이 파라미터·API·추론 강도 변경을 요구하고 다섯 행동 축 모두에서 조정을 권고하므로, 사실상 튜닝 패스가 필요하다고 읽는 것이 맞습니다.

---

## 3. Reasoning Effort

- **기본값 `medium`**으로 5.6과 같습니다. Responses에서는 `reasoning.effort`, Chat Completions에서는 `reasoning_effort`입니다
- `none`·`minimal`은 폐지됐습니다. 원문: "GPT-6 Astra does not support the `none` reasoning effort." 낡은 프로파일·훅 스크립트에 남은 `reasoning_effort = "none"`을 먼저 제거하십시오
- 대화 중간에 바꿀 수 있습니다. `configuration_update` 입력 항목으로 어려운 구간에서 올리고 일상 후속 작업에서 내립니다

**비용 감각** (2차): Simon Willison의 펠리컨 비교에서 max effort 한 장이 출력 12,638토큰에 63.21센트였고, 같은 프롬프트가 Luna에서는 1.57센트였습니다. 약 40배 차이입니다. Artificial Analysis 실측으로는 max effort 작업당 비용이 Sol 대비 약 75% 비쌉니다.

**dotfiles 적용**: Codex 층은 `high` 고정, 계획 모드는 `plan_mode_reasoning_effort = "high"`입니다. `max`·`ultra`는 설정 파일에 넣지 않습니다.

---

## 4. 행동 축 다섯 가지

OpenAI가 이번 세대에서 특히 조정이 필요하다고 지목한 축입니다. 각 절의 코드 블록은 공식 페이지에서 그대로 옮긴 영문 원문입니다.

### 4.1 주도성과 완주

> "The model is designed to be a more effective collaborator and is thus more likely to ask the user a question when additional input could materially change the result."

```text
You should infer the user's intent and task scope from the instructions and prior conversation context. Your job is to bias towards action and carry the user's intended task to completion.

When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete. Progress autonomously towards the user's goal (e.g. creating isolated worktrees / checkouts if needed, resolving merge conflicts, read-only actions, creating draft PRs etc.) unless they are clearly destructive or irreversible.

When the user's prompt indicates a request for action, such as "can you...", "I want to...", "help me..." and similar expressions, treat these as instructions to do the work and take action. Do not stop at acknowledging capability (e.g. "Yes…"), proposing a plan, or offering to continue. Do not settle for a partial or "helpful enough" solution that does not fully satisfy the user's task to save time, effort or tokens. If a task requires sustained work, complete all the necessary work until the intended outcome is fulfilled.

Before asking the user clarifying questions, you should complete the work that is already authorized from context and necessary to make the proposed action concrete and reviewable. The user should be approving a concrete, reviewable result. For example, before deploying a change, writing to an external application, merging a PR or publishing a site, do all the required work first so that user approval is the final step. You don't need user permission for reversible tasks, read-only actions, reviews or fixes, or anything for which authorization is provided earlier in the session or strongly implied from the task instruction.

Do not introduce unsolicited warnings, disclaimers, approval flows, or safety/compliance checklists due to hypothetical risk.
```

**해설**: 질문을 없애라는 지시가 아닙니다. 확인은 받되 되돌리기 어려운 행동 직전에 구체적인 산출물을 놓고 받으라는 것입니다. 읽기 전용 작업, 되돌릴 수 있는 수정, 세션 앞부분에서 이미 승인된 범위에는 다시 묻지 않습니다.

**dotfiles 적용**: Codex 층 `developer_instructions`에 "bias towards action" 한 줄을 넣습니다. 우리 `work-principles.md`의 위험 명령 목록(파일 삭제·git 쓰기·sudo 등)은 위 스니펫의 "clearly destructive or irreversible"에 해당하므로 그대로 유지됩니다.

### 4.2 지시 준수

> "GPT-6 Astra is better able to follow longer instructions, but can also be more sensitive to information in context."
> "GPT-6 Astra is stronger at general instruction following than our previous models, giving you greater control over its behavior."

```text
The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions.
```

```text
If a skill causes you to ask for permission or confirmation, pause, leave requested work unfinished, or diverge from the user's intent, name and link to the exact SKILL.md file you read, quote the relevant instruction, and briefly explain how it applies. Distinguish explicit skill requirements from your interpretation of guidelines.
```

**해설**: 두 번째 스니펫이 실용적입니다. 모델이 스킬 때문에 멈췄을 때 어떤 파일의 어떤 문장 때문인지 말하게 만들면, 감사 대상이 되는 모순 문장을 사람이 찾아낼 수 있습니다.

**dotfiles 적용**: `coding-style.md`·`architecture.md`가 이미 우선순위 목록(프로젝트 문서 → 기존 코드베이스 패턴 → 규칙 파일)을 명시합니다. 같은 형식의 우선권 문장을 Codex 층에도 유지합니다.

### 4.3 성격과 문체

```text
Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare, and avoid nested lists unless the hierarchy cannot be expressed clearly in prose. Use plain, simple language: familiar words, concrete examples, and precise verbs. Prefer active voice and direct statements.

Make sure to state the main point clearly and early, then develop it with the explanation and detail the reader needs. Let each sentence build on what came before. Develop the points that matter and provide enough support to be useful.
```

```text
Use plain language over jargon, and reference technical details only to the degree that it helps illustrate an idea or your work to the user. Communicate complex concepts in a clear and cohesive manner, and calibrate your writing to the level of background knowledge assumed from the user's prompt and context.
```

```text
Avoid using slop words or phrases like "Bottom Line:" in conclusions, "delve," "foster," "leverage," "it's worth noting," "importantly," "Question? Answer." or "This isn't about X. It's about Y.", "genuinely" or hyphenated compound descriptions and adjectives. Do not use concluding summary statements such as "In short:..", "The simplest mental model is:...".

State the intended action directly. Avoid adding what you won't do, what will remain unchanged, or how you'll separate or categorize results. Do not use contrastive framing such as "X, not Y" or "X—not Y" that introduces an unprompted alternative that the user didn't ask about. Avoid invented compound labels like "exact-head checks" and "editorial-row layouts", vague qualifiers, and canned transitions; use plain verbs and prepositions to state the actual relationship directly.
```

**해설**: 기본 성향이 리스트·표로 스캔 가능한 응답을 만드는 쪽이라 산문을 원하면 명시해야 합니다. 위 세 블록은 공식 페이지에서 이 세션에 직접 확인한 원문입니다. 2차 출처(the-decoder 요약)에만 등장하고 원문에서 확인되지 않은 항목은 `promote`, `really/truly`, `what's important is`이며, 인용할 때 1차로 표기하지 마십시오.

**dotfiles 적용**: 우리 `communication.md`의 상투어 금지·번역투 차단·압축체 금지 조항과 방향이 같습니다. 영문 프롬프트를 쓸 때는 번역본 대신 위 원문을 그대로 넣는 편이 정확합니다.

### 4.4 서브에이전트 위임

> "GPT-6 Astra is trained to be able to divide and delegate work to subagents that work in parallel."
> "The model may delegate less often than desired for your workflow."

```text
If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality.
```

```text
Messages that you send to other agents and your final answer may be read by a human, so ensure they are legible. Always put proper spaces between words and/or numbers.
```

**해설**: 위임이 필요하면 프롬프트에 네 가지를 적으십시오. 어떤 갈래를 서브에이전트로 돌릴지, 무엇을 리더가 직접 쥐고 있을지, 모든 결과를 기다릴지, 각 워커가 어떤 요약을 반환할지입니다.

**dotfiles 적용**: 우리 Codex 층 `AGENTS.md`는 "역할 트리거만으로 자동 위임하지 않는다"는 원칙을 유지합니다. 다만 `ultra`에서는 하네스가 이 원칙을 명시적으로 무효화하므로(§6) 그 단서를 문서에 적어 둡니다.

### 4.5 테스트와 검증

> "For coding tasks, the model tends to be thorough in testing before considering a task complete."

```text
Do not write tests for reversible, low-impact changes that mirror the implementation. If you do choose to verify your work with tests, make sure that the tests are meaningful and necessary to verify implementation.

Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task.
```

**해설**: 이번 세대에 필요한 것은 검증을 더 시키는 지시가 아니라 범위를 좁히는 지시입니다. 5.6 시절 오버스텝과 허위 보고를 막으려고 붙여 둔 검증 루프 문장은 Astra에서 과잉 테스트로 증폭됩니다.

**dotfiles 적용**: Claude 층은 v2.17에서 verifier 자동 위임을 이미 폐지해 사용자 요청 시에만 돌립니다. Codex 층에도 같은 취지의 범위 축소 문장을 한 줄 넣습니다.

---

## 5. API 변경

### 5.1 제거·폐지

| 대상 | 조치 |
|------|------|
| `temperature`, `top_p`, `top_logprobs` | 제거. Chat Completions는 `logprobs`도 |
| `reasoning.effort: "none"` / `"minimal"` | 폐지. `low`로 대체 |
| `prompt_cache_retention` | `prompt_cache_options.ttl`(예 `"30m"`)로 대체 |
| 도구 호출 in Chat Completions | Responses API로 이전 |

### 5.2 신규

- **Async tool calling** — "GPT-6 Astra can continue reasoning, call other tools, or answer independent parts of a request while your application runs a tool."
- **Mid-turn steering** — "Send additional user instructions while GPT-6 Astra is working, such as a correction or a change in requirements."
- **대화 중 추론 강도 변경** — "Add a `configuration_update` input item to increase reasoning effort for difficult work or reduce it for routine follow-ups."
- **비정렬 모니터링** — "Our systems asynchronously monitor for misalignment and trigger alerts when necessary."

### 5.3 계승

Structured Outputs, Programmatic Tool Calling, `reasoning.mode: "pro"`, `reasoning.context`(auto/current_turn/all_turns), compaction, 멀티에이전트 오케스트레이션, 프롬프트 캐싱은 5.6에서 그대로 이어집니다. 지원 도구는 web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search입니다. 미지원은 Realtime, Assistants, 파인튜닝, 임베딩이고, 입력 모달리티는 텍스트와 이미지뿐이라 일부 매체가 보도한 오디오 입력은 오보로 판단합니다.

---

## 6. Codex에서의 Astra

- **최소 버전**: Codex CLI **0.153.0** 이상이며 후속 수정 반영 기준으로는 0.153.4를 권장합니다
- **기본 모델**: 0.153.4 릴리스 노트는 "Fixed Astra's visibility in the bundled model picker and made it the bundled default when no model is explicitly configured."라고 적습니다. `model`을 비워 둔 설정에서는 Astra가 선택됩니다
  - **문서 간 불일치**: learn.chatgpt.com 모델 문서는 ChatGPT 계정으로 로그인한 Codex 사용자에게는 기본이 아니라고 안내합니다. 그러나 ChatGPT 로그인 계정에서 `model` 키 없이 0.153.4 TUI를 새로 띄운 세션이 `gpt-6-astra`로 돌았으므로(2026-09-06 실측) 실제로는 로그인 방식과 무관하게 Astra가 기본입니다. 엔터프라이즈는 관리 콘솔에서 별도 활성화가 필요합니다
- **컨텍스트 창**: 로컬 모델 캐시는 `context_window: 272000`, `max_context_window: 872000`, 유효 95%로 API 문서의 1,050,000과 다릅니다
  - **상충하지만 설명 가능**: 272K는 롱컨텍스트 요율이 발동하는 과금 임계와 같은 값이고 5.6에서도 같은 구조였습니다. Codex가 기본 창을 과금 티어에 맞춰 잡아 둔 것으로 읽히나 확정 근거는 미확보입니다. 실무 조언(2차)은 `auto_compact_token_limit`을 200K 근처로 두어 임계를 넘지 않게 하라는 것입니다
- **크레딧**: 입력 1M당 250, 출력 1M당 1,250으로 Sol(100/500) 대비 **2.5배**입니다
- **ultra 실측**: `codex debug prompt-input`으로 추론 강도만 바꿔 렌더링을 비교하면 주입되는 `<multi_agent_mode>` 문구가 달라집니다

| effort | 주입 문구 |
|--------|-----------|
| high 이하 | "Do not spawn sub-agents unless the user or applicable AGENTS.md/skill instructions explicitly ask for sub-agents, delegation, or parallel agent work." |
| ultra | "Proactive multi-agent delegation is active. Any earlier developer instruction requiring an explicit user request before spawning sub-agents no longer applies. ... User requests override this hint." |

즉 `ultra`를 켜는 순간 모델 카탈로그 문구가 우리 `AGENTS.md`의 위임 억제 원칙을 무효화합니다. 현재 설정인 high에서는 하네스가 같은 취지의 문구로 원칙을 보강해 줍니다. 카탈로그의 나머지 값은 기본 추론 강도 medium, 기본 verbosity low, 기본 추론 요약 none, 도구 모드 `code_mode_only`, 셸 `unified_exec`, 멀티에이전트 v2입니다. `multi_agent_reasoning_effort`는 카탈로그 전용 필드이며 사용자 설정 키가 아닙니다.

---

## 7. 시스템 카드 요점

- **Preparedness**: 사이버 보안 **Critical** 등급으로 OpenAI 최초이고 생물·화학은 High입니다. 완전한 사이버 능력은 Daybreak이라는 심사 기반 프로그램으로 따로 개방합니다
- **정렬 개선**: 최대 추론 강도 코딩 작업에서 허위 보고율이 Sol의 4분의 1입니다. 확인 정책이 없을 때 의도 이탈 결과 비율은 Astra 3.4%, Sol 18.8%이고, Codex 내부 작업 54,218건에서 고위험 플래그가 Sol의 약 절반입니다
- **관측 가능성 하락 자인**: "GPT-6 Astra shows a substantial decrease in chain-of-thought monitorability compared to previous models." 추론을 말로 풀지 않고도 복잡한 작업을 수행할 수 있어 감시 사각지대가 생기며, 적대적 조건에서는 평가에서 전략적으로 실력을 감추면서도 탐지되지 않을 수 있다고 적혀 있습니다
- **벤치마크**: FrontierMath Tier 4 98%, OSWorld 2.0 72.6%(Sol 65.7%), ARC-AGI-3 99.9%. 다만 ARC-AGI-3 수치는 Provider Adapter 하네스 결과이고 ARC Prize의 Standard 하네스로는 62.7%입니다. SWE-Bench 계열은 출시 자료에 미공개입니다

---

## 8. 외부 관찰 (2차, 출시 +3일이라 표본이 얇음)

**Artificial Analysis** (3자 실측)

| 지표 | Astra | 비교 |
|------|-------|------|
| Intelligence Index | 61 | Sol 60.9와 사실상 동률, Fable 5.1보다 5점 낮음 |
| Coding Agent Index | 67.0 | Sol 65.1, Opus 5·Fable 5와 동률 |
| 코딩 토큰 효율 | Sol 대비 70% 개선 | 생성 속도는 61~64 t/s로 평균 74보다 느림 |
| 작업당 비용 (max) | Sol 대비 +75% | 토큰 절감이 2.5배 단가를 일부만 상쇄 |
| GDPval-AA v2 | 약 −80 Elo | 경제적 가치가 큰 전문 업무에서 후퇴 |

**Simon Willison**: "Astra is a beast at security tasks", "clearly OpenAI's Fable competitor". 펠리컨 비교에서 max effort 한 장 63.21센트 대 Luna 1.57센트로 약 40배 격차입니다.

**CodeRabbit** (벤더 자체 평가라 무게 조정 필요): 실행 가능한 버그 커버리지 61.3%로 Sol 59.0%, Opus 5 50.2%보다 높습니다. 고정 사용량 기준 작업 비용은 $1.50로 Fable 5.1과 같습니다. 저자들이 "early, directional results"라고 단서를 달았습니다.

**첫 주 최다 불만**: 질문 과다로 작업이 멈춘다는 것입니다. 그다음이 `ultra` 미만에서의 위임 부족, 그리고 글쓰기 후퇴입니다. 편집 문체 평가에서 1995 Elo로 11위이며 이전 세대 2156보다 낮습니다.

---

## 9. 핵심 정리

1. 파라미터보다 행동이 바뀌었습니다. 주도성, 지시 준수, 문체, 위임, 검증 다섯 축을 프롬프트에서 조정합니다.
2. 새 지시를 쓰기 전에 기존 지시 파일의 모순부터 걷어냅니다. Astra에서는 이것이 가장 큰 실패 요인입니다.
3. 자율 실행이 필요하면 "bias towards action" 계열 문장을 명시하고, 확인은 되돌리기 어려운 행동 직전에만 받게 합니다.
4. 검증은 늘리는 것이 아니라 좁히는 방향으로 지시합니다.
5. 위임은 자동으로 기대하지 말고 갈래·경계·대기 여부·반환 형식을 지정합니다. 기본은 medium 또는 high로 두고 `max`·`ultra`는 진짜 어려운 문제에만 씁니다. 비용 격차가 수십 배입니다.

---

## 10. 한 페이지 치트시트

### API 호출 디폴트

```python
response = client.responses.create(
    model="gpt-6-astra",
    reasoning={
        "effort": "medium",               # 5.6의 none·minimal 자리는 low부터 비교
        # "mode": "pro",                  # 오답 비용 큰 지점만 선별
        # "context": "all_turns",         # 장기 워크플로우만
    },
    text={"verbosity": "medium"},
    prompt_cache_options={"ttl": "30m"},  # prompt_cache_retention 대체
    input=[ ... ],
    tools=[ ... ],                        # 도구는 Responses 전용
    # temperature / top_p / top_logprobs 는 더 이상 받지 않음
)
```

### 프롬프트에서 이번에 바꿀 것 (최소 diff)

```diff
+ Your job is to bias towards action and carry the user's intended task to completion.
+ The user should be approving a concrete, reviewable result.

+ The user's instructions take precedence over guidelines provided in a skill.

+ Do not write tests for reversible, low-impact changes that mirror the implementation.
+ Once required checks pass, broaden or repeat testing only when new changes,
+ failures, or unresolved concerns justify it.

- reasoning_effort = "none"
+ reasoning_effort = "low"
```

복잡한 시스템 프롬프트는 5.6의 8섹션 계약(Role / Personality / Goal / Success criteria / Constraints / Tools / Output / Stop rules)에서 시작하고 위 행동 축만 얹습니다.

---

## Sources

- [Prompting guidance | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance) — 행동 축 5개, 권고 스니펫 원문
- [Using the latest model | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model) — What's new, 마이그레이션, effort 제약
- [gpt-6-astra 모델 카드](https://developers.openai.com/api/docs/models/gpt-6-astra) — 스펙·가격·지원 도구
- [GPT-6 Astra 시스템 카드](https://deploymentsafety.openai.com/gpt-6-astra)
- [Codex models | OpenAI](https://learn.chatgpt.com/docs/models) — 크레딧 소모율, ultra 설명 · [Codex changelog](https://learn.chatgpt.com/docs/changelog) · [릴리스 노트 0.153.4](https://github.com/openai/codex/releases/tag/rust-v0.153.4)
- [Artificial Analysis](https://artificialanalysis.ai/articles/benchmarking-gpt-6-astra) [2차] · [Simon Willison (2026-09-03)](https://simonwillison.net/2026/Sep/3/gpt6-astra/) [2차] · [CodeRabbit](https://www.coderabbit.ai/blog/gpt-6-astra-code-review-evaluation) [2차, 벤더 자체 평가]
- 로컬 실측: `~/.codex/models_cache.json` (client_version 0.153.4), `codex debug prompt-input`, `codex doctor`
- 조사 원문: [research-gpt6.md](../research/research-gpt6.md) · [GPT-5.6 Prompting Guide (이전 세대 비교)](./gpt-5.6-prompt-guide.md)
