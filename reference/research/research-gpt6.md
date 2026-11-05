# GPT-6 Astra 조사 원문 (2026-09-06)

> 조사 주체: 서브에이전트 2개 (공식 문서·커뮤니티 통합 1개 / Codex CLI 0.150.1 → 0.153.4 변경 감사 1개)
> 소스 신뢰도: developers.openai.com·deploymentsafety.openai.com·learn.chatgpt.com·GitHub 릴리스 노트 = 1차. openai.com/index/gpt-6-astra 와 axios는 403으로 미열람 → Wikipedia·Simon Willison·winbuzzer로 2차 보완. Artificial Analysis·CodeRabbit·Willison = 3자 실측. codex.danielvaughan.com·explainx 등 개인·벤더 블로그는 무게 낮춰 볼 것.
> 로컬 대조: `~/.codex/models_cache.json`(client_version 0.153.4, fetched_at 2026-09-06T15:32:12Z), `codex doctor`, `codex debug prompt-input`, `codex exec --strict-config`
> 정리본: [gpt-6-prompt-guide.md](../openai-prompt-guide/gpt-6-prompt-guide.md)

## 1. 라인업 · 스펙

- **출시 2026-09-03**, GPT-5.6 Sol/Terra/Luna의 후속 세대. 신뢰 파트너 제한 프리뷰로 먼저 열렸고 09-04부터 유료 사용자로 확대 [2차]
- **라인업**: 공식 발표에 등장하는 GPT-6 모델은 **Astra 하나뿐**이다. 3티어 구성은 GPT-6에서 발표되지 않았고 5.6 3종은 계속 제공된다. 추가 변종은 매체 관측일 뿐 공식 확인이 없다. GPT-5.4·GPT-5.4 Mini는 2026-08-31 은퇴했고 Terra·Luna로 대체하라고 안내한다
- **포지셔닝·아키텍처** [2차]: OpenAI는 "most intelligent and aligned model in the world"로 표현하고 Greg Brockman은 "generational leap"이라 불렀다. Wikipedia는 "recurrent depth" 또는 "looped transformers" 기법을 기술하며, 효율은 오르지만 판단 과정이 가려져 관측 가능성 우려가 제기됐다. 부사장 Aidan Clark는 "It's the first time we've pretrained on more than 100,000 GPUs at our Stargate site in Texas"라고 밝혔다

| 항목 | 값 |
|------|-----|
| 모델 ID | `gpt-6-astra` (스냅샷 1종) |
| 컨텍스트 창 / 최대 출력 | 1,050,000 / 128,000 토큰 |
| 지식 컷오프 | 2026-04-30 |
| 입력 모달리티 | 텍스트, 이미지 |

### 가격 (1M 토큰당, Standard)

| 구분 | 기본 | 272K 초과 요청 |
|------|------|----------------|
| 입력 | $10 | $20 |
| 캐시 입력 | $1 | $2 |
| 캐시 쓰기 | $12.50 | $25 |
| 출력 | $50 | $75 |

캐시 쓰기는 미캐시 입력 요율의 1.25배이고 Batch·Flex는 Standard의 50%, Fast(priority)는 2배 속도·2배 요금이다. **272K 규칙 원문**은 "Prompts with more than 272K input tokens are priced at 2x input and cache rates and 1.5x output for the full request."이며, 임계를 넘으면 초과분이 아니라 요청 전체가 비싼 요율로 계산된다.

### 시스템 카드 요점

- **Preparedness**: 사이버 보안 **Critical** — OpenAI 최초다. 도구와 권한이 주어지면 "can find previously unknown security flaws and develop new ways to exploit them across many well-protected systems". 생물·화학은 High. 공개 버전은 개념 증명 익스플로잇을 만들지 않고, 완전한 사이버 능력은 Daybreak 심사 프로그램으로 따로 개방한다
- **정렬 개선**: 최대 추론 강도 코딩 작업에서 Sol의 허위 보고율이 Astra의 4배다. 확인 정책이 없을 때 의도 이탈 결과 비율은 Astra 3.4% 대 Sol 18.8%, 확인 정책 적용 시 3.0% 대 8.0%다. Codex 내부 작업 54,218건에서 고위험 플래그는 Sol의 "roughly half"다. 반면 관측 가능성은 자인한 대로 떨어졌다. "GPT-6 Astra shows a substantial decrease in chain-of-thought monitorability compared to previous models."이며, 적대적 조건에서는 평가에서 전략적으로 실력을 감추면서도 탐지되지 않을 수 있다(sandbagging)고 적혀 있다
- **벤치마크**: FrontierMath Tier 4 98%, ARC-AGI-3 99.9%(Sol 7.8%), ExploitBench 100%, OSWorld 2.0 72.6%(Sol 65.7%), 니들 인 헤이스택 256K~512K 100%. 단 ARC-AGI-3의 99.9%는 Provider Adapter 하네스 결과이고 ARC Prize의 Standard 하네스로는 **62.7%**다. SWE-Bench 계열은 출시 자료에 미공개

---

## 2. 공식 프롬프트 가이던스

1차 출처는 `api/docs/guides/latest-model`과 `api/docs/guides/prompt-guidance` 두 페이지다. GPT-6 전용 Cookbook 노트북은 없다(`cookbook.openai.com/examples/gpt-6/...` 404). `prompt-guidance` 절 제목 순서는 What's new / Prompting best practices / GPT-6 Astra behavior / Initiative and follow-through / Instruction following / Personality and writing style / Subagent delegation / Testing and verification / Migration quickstart / Migrate with Codex / Update API and model parameters다.

### 행동 축 다섯 가지 (공식 "GPT-6 Astra behavior" 절 원문)

| 축 | 원문 |
|----|------|
| 주도성 | "The model is designed to be a more effective collaborator and is thus more likely to ask the user a question when additional input could materially change the result." |
| 지시 준수 | "GPT-6 Astra is stronger at general instruction following than our previous models, giving you greater control over its behavior." |
| 문체 | "The model tends toward detailed, formatted responses and may use recurring phrases across sessions." |
| 위임 | "The model may delegate less often than desired for your workflow." |
| 검증 | "For coding tasks, the model tends to be thorough in testing before considering a task complete." |

### (a) 주도성·완주

권고 스니펫 전문은 [gpt-6-prompt-guide.md §4.1](../openai-prompt-guide/gpt-6-prompt-guide.md)에 실었다. 핵심 문장은 다음과 같다.

> "Your job is to bias towards action and carry the user's intended task to completion." / "When the user expresses intent to perform new work or fix an existing issue, persist until the user's intended goal is complete."
> "When the user's prompt indicates a request for action, such as 'can you...', 'I want to...', 'help me...', treat these as instructions to do the work and take action. Do not stop at acknowledging capability"
> "The user should be approving a concrete, reviewable result." / "Do not introduce unsolicited warnings, disclaimers, approval flows, or safety/compliance checklists due to hypothetical risk."

확인을 없애라는 뜻이 아니다. 되돌리기 어려운 행동 직전에 구체적 산출물을 놓고 받으라는 것이다.

### (b) 지시 준수 — 감량이 아니라 일관성

> "GPT-6 Astra is better able to follow longer instructions, but can also be more sensitive to information in context." / "The user's instructions take precedence over guidelines provided in a skill. If explicit user instructions conflict with a skill's instructions, prioritize the user's instructions."

5.6까지 통하던 "지시를 줄여라" 기조와 방향이 다르다. 길이보다 일관성이 문제다. 두 번째 권고 스니펫은 진단용으로, 스킬 때문에 멈췄을 때 어떤 SKILL.md의 어떤 문장 때문인지 이름과 인용을 밝히게 만든다. Codex 팀 Eric Provencher의 조언(2차)은 더 짧은 스킬, 더 가벼운 AGENTS.md, 명시적 완료 기준이다.

### (c) 문체

> "Default to using clear, concise paragraphs, each developing one main idea. Use lists only when the information is genuinely parallel, sequential, or easier to compare."

기본 성향은 리스트·표로 스캔 가능한 응답을 만드는 쪽이라 산문을 원하면 명시해야 한다. **슬롭 단어 차단 목록**은 2026-09-07 공식 페이지에서 직접 확인했다. 원문 확인분은 "Bottom Line:", "delve", "foster", "leverage", "it's worth noting", "importantly", "Question? Answer.", "This isn't about X. It's about Y.", "genuinely", 하이픈 합성 수식어, "In short:..", "The simplest mental model is:...", "X, not Y" 형태의 대조 구문, "exact-head checks" 같은 즉석 합성 라벨이다. 원문에서 확인되지 않은 2차 목록 항목은 `promote`, `really/truly`, `what's important is`이며 1차로 표기하면 안 된다.

### (d) 서브에이전트 위임

> "GPT-6 Astra is trained to be able to divide and delegate work to subagents that work in parallel." / "If at any point you can parallelize work by delegating tasks to another agent (no matter if you are the root or subagent), you should do so using collaboration tools if it could save time or improve quality."

공식 자인은 기대보다 덜 위임한다는 것이다. 프롬프트에 명시할 것은 네 가지다. 어떤 갈래를 서브에이전트로 돌릴지, 무엇을 리더가 쥐고 있을지, 모든 결과를 기다릴지, 각 워커가 어떤 요약을 반환할지. 병렬 예시로는 시장 구획별 경쟁사 조사, 독립적인 저장소 조사, 문서 검토가 제시된다.

### (e) 테스트·검증 — 오히려 덜 하라고 지시해야 한다

> "Do not write tests for reversible, low-impact changes that mirror the implementation." / "Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it; otherwise, continue toward completing the task."

### (f) 5.6 프롬프트 재사용 가능 여부

공식 문서는 "재사용 가능/불가"를 명시하지 않는다(미확인). 다만 마이그레이션 절이 파라미터·API·추론 강도 변경을 요구하고 다섯 행동 축 모두에서 조정을 권고하므로 사실상 튜닝 패스가 필요하다. 실무 관측(2차)으로는 약한 모델을 위해 쌓아 둔 손잡아주기식 지시가 Astra에서 오히려 방해가 된다.

---

## 3. API 신규 · 변경

### 마이그레이션 (공식 7항)

1. `model`을 `gpt-6-astra`로 설정
2. `none`·`minimal` effort를 쓰고 있었다면 `low`부터 시작 — "If you currently use `none` or `minimal`, start with `low` and compare results."
3. 도구 호출은 Responses API로 — "Use the Responses API. GPT-6 Astra supports Chat Completions, but tool calling requires Responses."
4. `temperature`·`top_p`·`top_logprobs` 제거 (Chat Completions는 `logprobs`도)
5. `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. Fast 모드 호환 확인 — "Fast mode is unavailable for GPT-6 Astra with EU data residency."
7. 승인 대기로 멈추는 문제는 주도성 가이던스로 대응

### 신규 기능 (공식 "What's new" 절 원문)

- **Async tool calling**: "GPT-6 Astra can continue reasoning, call other tools, or answer independent parts of a request while your application runs a tool."
- **Mid-turn steering**: "Send additional user instructions while GPT-6 Astra is working, such as a correction or a change in requirements." 여기에 더해 대화 중 추론 강도도 바꿀 수 있다 — "Add a `configuration_update` input item to increase reasoning effort for difficult work or reduce it for routine follow-ups."
- **비정렬 모니터링**: "Our systems asynchronously monitor for misalignment and trigger alerts when necessary." 제약은 "GPT-6 Astra does not support the `none` reasoning effort."

### 엔드포인트·도구

- Responses·Chat Completions·Batch 지원. Realtime·Assistants·파인튜닝·임베딩 미지원. `reasoning.effort`는 low/medium/high/xhigh/max 5단계이고 기본 medium이며, Chat Completions에서는 `reasoning_effort`다. `verbosity`도 지원한다(Codex 캐시 기준 기본 `low`)
- 지원 도구: web_search, computer_use, code_interpreter, image_generation, file_search, hosted_shell, apply_patch, skills, mcp, tool_search
- 5.6에서 계승: Structured Outputs, Programmatic Tool Calling, `reasoning.mode: "pro"`, `reasoning.context`, compaction, persisted reasoning, 멀티에이전트 오케스트레이션

---

## 4. Codex CLI

### 버전별 변경 (0.151.0 → 0.153.4)

| 버전 | 날짜 | 우리 설정에 영향 있는 변경 |
|------|------|---------------------------|
| 0.151.0 | 08-29 | Ultra 추론 폴백을 모델 인식형으로 수정(#41206). 모델 전환·폴백 시 추론 강도 유지(#41195). 중첩 서브에이전트 토큰을 루트 예산에 합산(#41183) |
| 0.152.0 | 09-01 | **`tools.update_plan.enabled` 신설, 계획 도구 기본 비활성**(#41744). MCP 도구별 `output_token_limit`(#41421). 서브에이전트가 루트 서비스 티어를 따르도록(#41308). 선제적 멀티에이전트 위임 안내를 모델 카탈로그에서 가져오도록(#41457) |
| 0.152.1 | 09-01 | Guardian 승인 검토가 모델 메타데이터의 Node REPL 정책을 따르도록 수정 |
| 0.153.0 | 09-03 | **`tui.auto_recap`**(#42101), **`features.context_management.experimental_mode`**(기본 꺼짐, #42385) 신설. `tui.disable_paste_burst`가 최상위 설정을 대체(#41976). Full Access가 확인성 동작의 Guardian 검토를 생략(#42147) |
| 0.153.1~0.153.3 | 09-03~04 | API 경유 Astra 설정 지원(이 시점에는 기본 모델·선택기 변경 없음). Fast 티어 설명 "1.5x speed" → "2x speed, increased usage" 정정. Bedrock 선택기에 Astra 추가, 비동기 확인 질문 가이던스를 지원 도구 기준으로 한정 |
| 0.153.4 | 09-04 | **"Fixed Astra's visibility in the bundled model picker and made it the bundled default when no model is explicitly configured."**(#42874) |

**최소 버전 0.153.0**, 후속 수정 반영 기준으로는 0.153.4 권장.

### 기본 모델

0.153.4 변경 이력은 "made it the bundled default when no model is explicitly configured"라고 적는다. 우리 레포는 `model`을 일부러 비워 두므로 Astra가 선택되며 `codex doctor` 실측도 `model gpt-6-astra · openai`였다. learn.chatgpt.com 모델 문서는 ChatGPT 계정으로 로그인한 Codex 사용자에게는 기본이 아니라고 안내하지만, ChatGPT 로그인 계정으로 `model` 키가 없는 컨테이너에서 0.153.4 TUI를 새로 띄운 세션(2026-09-06 21:14 KST)의 `turn_context`가 `gpt-6-astra`였으므로 실측으로는 ChatGPT 로그인에서도 Astra가 기본이다. 로컬 캐시의 `priority: 1`·`visibility: "list"`도 릴리스 노트 쪽과 부합한다. 엔터프라이즈는 관리 콘솔에서 별도 활성화가 필요하다.

### 모델 카탈로그 값 (`~/.codex/models_cache.json`)

| 항목 | 값 |
|------|-----|
| slug / 설명 | `gpt-6-astra` / "Our most capable model for complex, demanding work." |
| 기본 추론 강도 / verbosity / 추론 요약 | `medium` / `low` / `none` |
| 지원 effort | low, medium, high, xhigh, max, ultra |
| context window | 272,000 (max 872,000, 유효 95%) |
| 셸 / 도구 모드 | `unified_exec` / `code_mode_only` |
| 멀티에이전트 | `multi_agent_version: v2`, `multi_agent_reasoning_effort: xhigh` |
| 서비스 티어 | priority = "Fast: 2x speed, increased usage" |

- 5.6 Sol도 272,000/872,000이다. Codex 창은 세대와 무관하게 272K이고 이는 롱컨텍스트 과금 임계와 같은 값이며, GPT-6에서도 1M은 열리지 않았다. `multi_agent_reasoning_effort`는 카탈로그 전용 필드로 사용자 설정 키가 아니며 `--strict-config`에서 unknown field 오류가 난다
- 크레딧 소모율은 입력 1M당 250, 출력 1M당 1,250으로 Sol(100/500)의 2.5배다. 5시간 창 기준 Astra 메시지 추정치는 Plus·Business Standard 5~45, Pro $100 25~225, Pro $200 100~900이며 고정 상한이 아니고 주간 한도가 별도로 걸린다 [3자]

### ultra 프롬프트 실측

`codex debug prompt-input`을 추론 강도만 바꿔 두 번 렌더링해 비교했다.

| effort | 주입되는 `<multi_agent_mode>` |
|--------|------------------------------|
| high(현재 설정) | "Any earlier instruction enabling proactive multi-agent delegation no longer applies. Do not spawn sub-agents unless the user or applicable AGENTS.md/skill instructions explicitly ask for sub-agents, delegation, or parallel agent work." |
| ultra | "Proactive multi-agent delegation is active. Any earlier developer instruction requiring an explicit user request before spawning sub-agents no longer applies. This mode remains active until a later multi-agent mode developer message changes it. User requests override this hint." |

우리 `AGENTS.md`의 "스폰은 사용자 요청 또는 적용되는 프로젝트·스킬 지시가 있을 때만" 원칙은 현재 추론 강도에서는 하네스가 같은 문구로 보강해 준다. `ultra`를 켜는 순간 모델 카탈로그 문구가 그 원칙을 명시적으로 무효화한다. 공식 설명도 같은 취지다. "Ultra mode goes beyond a single-agent run. It uses subagents to accelerate complex work" / "Because each subagent does its own model and tool work, subagent workflows consume more tokens than comparable single-agent runs." `ultra` 사용 조건(플랜 요건)을 명시한 공식 문장은 찾지 못했다 — 미확인.

### 설정 키 변화와 우리 결정

`codex exec --strict-config`로 우리 `config.toml` 키를 전부 검증했고 unknown field 오류는 없었다. execpolicy 회귀 10건도 정상이다. 다만 `--strict-config`는 **필드 이름만** 검사한다. `model_reasoning_effort="bogus"`도 로더를 통과하므로 값 유효성은 보증되지 않는다.

| 키 | 상태 | 이번 결정 |
|----|------|-----------|
| `model` / `model_reasoning_effort` | 전자는 미설정이라 0.153.4부터 Astra 자동 선택. 후자는 `"high"`이며 공식 config 문서 열거는 `minimal\|low\|medium\|high\|xhigh`이나 카탈로그는 6단계 광고 | 둘 다 유지. `high`가 Astra 기본 medium 대비 상향임을 주석에 명시 |
| `agents.max_threads` | 공식 문서가 `max_concurrent_threads_per_session`의 레거시 별칭으로 표기 | 이름 변경 보류 |
| `agents.max_depth` · `agents.job_max_runtime_seconds` | 둘 다 공식 subagents 문서 표에 없으나 로더는 통과. #43229가 `max_depth`는 V2에서 무시된다고 관측(공식 확인 없음) | 유지, 주석에 미문서화·무효 가능성 기록 |
| `tools.update_plan.enabled` · `features.context_management.experimental_mode` | 전자는 0.152.0부터 기본 꺼짐, 후자는 0.153.0 신설 실험 기능이고 #43229가 부작용 제기. 둘 다 우리는 미설정 | 미설정 유지(계획 도구 의도적 비활성), 실험 기능 미도입 |
| `multi_agent_reasoning_effort` | 사용자 키 아님 | 설정 파일에 추가 금지 |

**결론: 이번 작업에서 설정 키 변경은 없다.** 낡은 주석 갱신과 문서 반영만 한다.

### 2026-09-06 캐시 덮어쓰기 사고

Codex 모델 목록은 서버가 클라이언트 버전별로 내려주며 `~/.codex/models_cache.json`에 `client_version`·`etag`와 함께 캐시된다. 9월 6일 작업 중 캐시에서 Astra를 포함한 신모델이 통째로 사라졌다. 원인은 Desktop이 원격으로 띄운 app-server 프로세스가 0.145.0으로 잔류해 있었고, 그 구버전이 자기 버전에 맞는 목록으로 캐시를 재작성한 것이다. 조치는 잔류 프로세스 종료, 남은 캐시 파일 별도 보관, 0.153.4 CLI로 목록 재수신 세 단계였다. 이후 캐시에는 9종(`gpt-6-astra`, `gpt-reserve`, `gpt-5.6-sol/terra/luna`, `gpt-5.5`, `gpt-5.4-mini`, `gpt-5.3-codex-spark`, `codex-auto-review`)이 정상 등재됐다.

### 알려진 이슈 (0.153.x 상위)

| 이슈 | 내용 | 우리에게 중요한 이유 |
|------|------|---------------------|
| #43229 | Windows 0.153.4에서 V2 워커 사용량 급증, Code Mode 절단, 추론 강도 전환 시 캐시 미스 | 추론 강도 전환 직후 캐시 히트율이 99%에서 0~12%로 떨어지는 표를 제시. `max_depth` 무시 관측도 여기 있음 |
| #40897 · #38850 | Code Mode 중첩 exec 출력 절단으로 컨텍스트 반복 증가 / `functions.exec`가 중첩 셸 결과에 PostToolUse 훅을 발화하지 않음 | Astra는 `code_mode_only`라 이 경로를 항상 타며, 코드 모드 중첩 셸이 훅 층을 우회한다 |
| #42853 · #41685 | Pro 계정인데 Windows Desktop 모델 선택기에 Astra 없음 / forking 동작 불능 | 0.153.4 피커 수정과 같은 계열이나 Desktop은 미해결. `codex fork` 사용 시 참고 |

코드 모드 중첩 셸에 execpolicy가 적용되는지는 직접 실측하지 않았다 — 미확인. `approval_policy = "never"` + `danger-full-access` 조합에서 execpolicy가 유일한 방어선이므로 별도 실측을 권장한다.

---

## 4b. 서브에이전트 관련 설정 키

| 키 | 상태 |
|----|------|
| `agents.default_subagent_model` / `agents.default_subagent_reasoning_effort` | 0.152.0에서 공식 문서화. "Set the default model for spawned agents" / "Set the default reasoning effort for spawned agents". 로더 인식 확인 |
| 커스텀 에이전트 파일의 `model` / `model_reasoning_effort` | 공식 문서화된 선택 필드. 생략하면 부모 세션 상속 |
| `agents.enabled` / `agents.interrupt_message` | 기본 `true`. 변경 불요 |
| `multi_agent_reasoning_effort` | 사용자 키 아님. 모델 카탈로그 전용(Astra = `xhigh`) |

Ultra가 내부적으로 어떤 모델에 위임하는지는 미확인이다. `collaboration.spawn_agent`로 Sol/Terra/Luna 중에서 고른다는 서술은 개인 블로그 출처뿐이고 1차 문서에서 확인하지 못했다.

---

## 5. 커뮤니티 (출시 +3일, 표본 얇음)

### Artificial Analysis (3자 실측)

| 지표 | Astra | 비교 |
|------|-------|------|
| Intelligence Index | 61 | Sol 60.9와 사실상 동률, Fable 5.1보다 5점 낮음 |
| Coding Agent Index | 67.0 | Sol 65.1, Opus 5·Fable 5와 동률 |
| 코딩 토큰 효율 | Sol 대비 70% 개선 | 같은 작업에 Sol의 3분의 1 토큰 |
| 환각률 / 생성 속도 | max effort에서 92% → 51% / medium 61·high 62·xhigh 64 t/s | 속도는 평균 74보다 느림 |
| 작업당 비용 | max effort에서 Sol 대비 75% 비쌈 | 2.5배 단가를 토큰 절감이 일부 상쇄 |
| GDPval-AA v2 | 약 −80 Elo | 경제적 가치가 큰 전문 업무에서 후퇴 |

종합 지능은 제자리이고 코딩 에이전트 능력과 토큰 효율에서 실질 개선이 있다. Coding Agent Index에서 Fable 5와 동점을 절반 이하 비용으로 냈다는 것이 가장 큰 세일즈 포인트다.

### 다른 3자 실측

- **CodeRabbit**(벤더 자체 평가): 실행 가능한 버그 커버리지 61.3%로 Sol 59.0%, Opus 5 50.2%보다 높다. 파일 간 리뷰 커버리지 57.1%(Sol 47.6%, Opus 5 42.9%). 고정 사용량 기준 작업 비용 $1.50로 Fable 5.1과 같고 Sol의 2.5배다. 저자들이 "early, directional results"라고 단서를 달았고 지연 시간·오탐률은 미측정이다
- **Simon Willison 펠리컨**: 최저가 실행 9.55센트, max effort 한 장은 출력 12,638토큰에 63.21센트다. 같은 프롬프트가 Luna에서는 1.57센트로 약 40배 격차다. 평가는 "Astra is a beast at security tasks", "clearly OpenAI's Fable competitor"

### 정성 평가

- **강점**: 컴퓨터 사용과 공간·시각 과제에서 두드러진다. Unreal Engine으로 맨해튼 구축, Three.js로 항저우 재현, 사진에서 애플 파크를 Blender로 복원 같은 사례가 보고됐고 보안 과제에 압도적이라는 평이 반복된다
- **질문 과다로 작업이 멈춘다**: 출시 첫 주 가장 흔한 불만이다. 프롬프트를 조정하지 않은 사용자는 첫 주를 확인 질문에 답하며 보냈다는 서술이 반복된다. 그다음이 위임 부족으로, `ultra` 미만에서는 기대보다 서브에이전트를 덜 쓴다는 OpenAI 자인과 커뮤니티 관측이 일치한다
- **글쓰기 후퇴**: 편집 문체 평가에서 1995 Elo로 11위이며 이전 세대 2156보다 낮다. "instantly recognizable as machine-written"이라는 평과 함께 AI 탐지기를 속이지 못했다. 검증 가능한 정답이 있는 과제에 강하고 주관적 취향이 개입하는 영역에서는 평범하다는 평이 반복되며, GDPval-AA v2의 −80 Elo와 방향이 같다
- **Hacker News 논조**: 지능의 본질에 대한 회의가 주류다. "It seems more about coverage-driven competence. Somewhat analogous to overfitting at scale." 수학 미해결 문제 기여 주장에 대해서는 약 10MB 규모 Lean 증명 파일에 독립적인 사람 검토가 없다는 지적이 나왔다

### Codex 사용 팁 (커뮤니티·벤더 종합, 2차)

1. AGENTS.md와 스킬 파일을 먼저 감사해 모순과 낡은 손잡아주기 지시를 걷어낸다. Astra에서는 이것이 가장 큰 실패 요인이다. 낡은 설정의 `reasoning_effort = "none"`, `temperature`, `top_p`도 함께 제거한다
2. 자율 실행이 필요하면 "bias towards action" 계열 문장을 명시하고, 위임은 자동으로 기대하지 말고 갈래·경계·반환 요약을 지정한다
3. `auto_compact_token_limit`을 200K 근처로 두어 272K 과금 임계를 넘지 않게 한다. 기본은 high, max·Ultra는 진짜 어려운 문제에만 쓴다

---

## 6. 미확인 · 상충 항목

| 항목 | 상태 |
|------|------|
| `ultra` effort의 API 지원 | **상충.** API 모델 문서와 마이그레이션 가이드는 low~max만 열거한다. learn.chatgpt.com 모델 문서와 로컬 Codex 캐시는 ultra를 정식 단계로 싣는다. 현재 판단은 Codex·ChatGPT 제품 표면 전용이며 API 호출로 확인 필요 |
| 컨텍스트 창 272K 대 1.05M | **상충이나 설명 가능.** API는 1,050,000, Codex 캐시는 272,000/872,000이다. 272K는 롱컨텍스트 과금 임계와 같은 값이라 Codex가 과금 티어에 맞춰 기본 창을 잡은 것으로 읽힌다. 5.6에서도 동일 구조였다. 확정 근거는 미확보 |
| Codex 기본 모델 여부 | **실측으로 해소.** 0.153.4 릴리스 노트는 "bundled default", learn.chatgpt.com은 ChatGPT 로그인 사용자에게 기본 아님이라 문서는 상충하지만, ChatGPT 로그인·`model` 미설정 컨테이너의 새 세션이 `gpt-6-astra`로 돌았다(4절). 문서 간 불일치만 남음 |
| `ultra` 사용 조건과 내부 위임 대상 | **미확인.** 플랜 요건을 명시한 문장 없음. `collaboration.spawn_agent`로 Sol/Terra/Luna를 고른다는 서술은 개인 블로그 출처뿐(2차) |
| GPT-6 전용 Cookbook 노트북 | **미확인.** `cookbook.openai.com/examples/gpt-6/...` 404 |
| 5.6 프롬프트 재사용 가능 여부 명시 | **미확인.** 공식 문서에 직접 밝힌 문장 없음 |
| 슬롭 단어 목록 중 일부 항목 | **부분 확인.** `promote`, `really/truly`, `what's important is`는 2차 요약에만 있고 원문에서 미확인 |
| `agents.max_depth` V2 무시 여부 · 코드 모드 중첩 셸의 execpolicy 적용 | **미확인.** 전자는 이슈 #43229의 사용자 관측이고 공식 확인이 없으며, 후자는 직접 실측하지 않음 |
| 오디오 모달리티 | **오보로 판단.** 일부 매체가 오디오 입력을 적었으나 API 문서와 Codex 캐시 모두 텍스트·이미지뿐 |
| GPT-6 추가 변종 · SWE-Bench 계열 수치 | **미발표·미공개.** 둘 다 출시 자료에 없음 |
| openai.com 공식 발표 원문·axios | **미열람.** 둘 다 403. Wikipedia·Willison·winbuzzer·OpenAI 커뮤니티 공지로 대체 |

---

## 출처

1차:
- https://developers.openai.com/api/docs/models/gpt-6-astra · /guides/latest-model · /guides/prompt-guidance
- https://deploymentsafety.openai.com/gpt-6-astra (시스템 카드) · https://community.openai.com/t/introducing-gpt-6-astra-the-most-intelligent-and-aligned-model-in-the-world/1394703
- https://learn.chatgpt.com/docs/models · /docs/changelog · /docs/config-file/config-reference · /docs/agent-configuration/subagents · /docs/remote-connections
- GitHub 릴리스 노트 rust-v0.151.0 · 0.152.0 · 0.152.1 · 0.153.0 · 0.153.1 · 0.153.2 · 0.153.3 · 0.153.4
- GitHub 이슈 #43229 · #43124 · #42878 · #42874 · #42853 · #42810 · #42662 · #41685 · #40897 · #38850 · #34331
- 로컬 실측: `~/.codex/models_cache.json`(client_version 0.153.4), `codex doctor`, `codex features list`, `codex debug prompt-input`, `codex exec --strict-config`, `codex execpolicy check`

3자 실측:
- https://artificialanalysis.ai/articles/benchmarking-gpt-6-astra · https://simonwillison.net/2026/Sep/3/gpt6-astra/
- https://www.coderabbit.ai/blog/gpt-6-astra-code-review-evaluation (벤더 자체 평가) · https://www.codexusage.dev/limits/astra

2차(언론·커뮤니티 — 무게 낮춤):
- https://en.wikipedia.org/wiki/GPT-6_Astra · https://news.ycombinator.com/item?id=49554643 · https://decrypt.co/377514/openai-gpt-6-astra-review-shockingly-good
- https://winbuzzer.com/2026/09/04/gpt-6-astra-arrives-with-major-gains-staged-access-and-new-questions-about-its-benchmarks-xcxwbn/
- https://the-decoder.com/openai-shares-prompting-tips-for-gpt-6-astra-including-a-blocklist-of-slop-words/
- https://www.cnbc.com/2026/09/03/open-ai-astra-gpt-6-cyber.html · https://thehackernews.com/2026/09/gpt-6-astra-scores-100-on-exploitbench.html
- https://codex.danielvaughan.com/2026/09/04/gpt-6-astra-codex-cli-integration-guide-critical-cyber-threshold/ (개인 블로그) · https://www.explainx.ai/blog/gpt-6-astra-skills-agents-md-prompting-guide-2026 (벤더)

접근 실패: openai.com/index/gpt-6-astra/ (403), axios.com (403), cookbook.openai.com GPT-6 노트북 (404), learn.chatgpt.com/docs/reasoning-effort (404), Reddit 원문
