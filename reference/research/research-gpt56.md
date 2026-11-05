# GPT-5.6 (Sol/Terra/Luna) 조사 원문 (2026-07-10)

> 조사 주체: 서브에이전트 3개 (공식 문서 / Codex CLI / 커뮤니티)
> 소스 신뢰도: developers.openai.com·시스템 카드·HN·Simon Willison = 1차. openai.com 블로그·help.openai.com은 403으로 미열람(2차 보완). Reddit 원문 접근 실패(언론 2차 요약만). eesel 등 벤더 블로그는 무게 낮춰 볼 것.

## 1. 모델 라인업 · 스펙

- 3티어: **Sol**(플래그십) / **Terra**(균형) / **Luna**(고속·저가). 2026-07-09 GA
- 슬러그: `gpt-5.6-sol` / `gpt-5.6-terra` / `gpt-5.6-luna`, 제네릭 별칭 `gpt-5.6` → sol 라우팅. `-codex` 접미사 변형 없음
- 3종 공통: 컨텍스트 1M(문서에 따라 1.05M), 최대 출력 128K, knowledge cutoff 2026-02-16
- 가격(/1M in/out): Sol $5/$30, Terra $2.50/$15, Luna $1/$6
- 벤치: HealthBench Sol 60.5(+8.7 vs 5.5). Agents' Last Exam Sol 53.6(OpenAI 주장 Fable 5 +13.1p — 단 y축 30% 시작 그래프 과장 논란). SWE-Bench Pro는 Fable 5 80% vs Sol 64.6%로 열세 자인. SWE-bench Verified 미공개
- 시스템 카드: 3종 모두 Bio/Chem·Cyber **High** 등급(소형 모델 최초), AI Self-Improvement below High
  - https://deploymentsafety.openai.com/gpt-5-6-preview

## 2. 공식 프롬프트 가이던스 (5.5 → 5.6 변화)

- 기조: **5.5 가이던스 유지**(outcome-first, personality/collaboration 분리, plain prose). 5.6은 더 토큰 효율적
- **effort 출발점 변경**: "medium에서 시작"(5.5) → **"기존 effort를 baseline으로 두고 한 단계 낮춰 비교"**(5.6 마이그레이션 지침)
- **verbosity 구체화**: "Be concise" 같은 **일반 간결 지시 명시적 금지** → 우선순위 지시로 대체("결론 먼저, 근거, 중대 caveat, 다음 액션"). 5.6은 기본이 이미 compression 편향
- 응답 템플릿: global template 대신 lightweight outline
- **드롭인 금지**: "Treat migration as a tuning pass, not only a model-slug change"
- 장황한 5.4/5.5 상속 프롬프트 축소 시 내부 평가 +10~15%, 토큰 41~66% 절감 사례
- 전용 cookbook 노트북 아직 없음. 1차 소스는 api/docs/guides/prompt-guidance·latest-model·reasoning

## 3. API 신규/변경 (Responses API)

- **effort 레벨 문서 불일치**: latest-model은 `none~xhigh, max`, reasoning 가이드는 `none, minimal~xhigh`(max 미언급). 기본 medium 공통. max/minimal 지원은 실호출 확인 필요
- `reasoning.mode: "pro"` — 고난도용 추가 연산 (토큰·지연 증가)
- `reasoning.context`: `auto` / `current_turn` / `all_turns` — 턴 간 reasoning 보존
- `programmatic_tool_calling` — 호스티드 JS 런타임 도구 오케스트레이션, `allowed_callers` opt-in
- `prompt_cache_options.mode: "explicit"` + `ttl` — 기존 `prompt_cache_retention` 대체. 캐시 write 1.25배 과금
- `safety_identifier` — 프라이버시 보존 사용자 추적

## 4. Codex CLI

- **GPT-5.6 최초 지원: 0.142.0 (2026-07-09)**. 0.143.0 = Bedrock 3티어 + `max` effort first-class, 0.144.0 = max first-class 확정 → **0.143+/0.144+ 권장** (로컬 실측: 0.142.5 → 업그레이드 필요)
- Codex 기본 모델 = `gpt-5.6-sol`
- config 키 유효성: `model_reasoning_effort` enum = `minimal|low|medium|high|xhigh`(default medium) — **xhigh 유효**. 단 `max`는 config-reference enum에 미등재(changelog와 불일치) → config 반영 보류
- `model_verbosity`(low|medium|high), `personality`(none|friendly|pragmatic) — 5.6 변화 없음
- Sol **Ultra** = 병렬 서브에이전트 모드 (Terminal-Bench 2.1: 88.8→91.9%). 표준 대비 토큰 2~3배

## 4b. Codex 서브에이전트 모델 고정 (2026-07-10 추가 조사)

- Codex의 "서브에이전트"는 두 종류: (A) CLI 멀티 에이전트(worker/explorer/default) = 사용자 모델 지정 **가능**, (B) GPT-5.6 Ultra 내부 서브에이전트 = 모델 내부 기능, 제어 **불가**
- (A) 고정 방법 2가지: ① 커스텀 정의 `~/.codex/agents/<name>.toml`(`name`+`model`+`model_reasoning_effort`+`developer_instructions` 등) ② 빌트인 역할에 `agents.worker.config_file = "worker.toml"` 레이어
- 상속 규칙(공식 원문): 역할 파일에서 `model` 등을 "inherit from the parent session when you omit them" — 명시하면 고정, 생략하면 메인 세션 모델 상속
- `agents.model` 직접 키는 없음. spawn_agent 도구의 per-call model 파라미터는 서드파티만 언급(공식 미확인)
- 메인 `model` 미설정 시: "uses a recommended model" (정확한 기본 슬러그는 문서 미명시)
- 출처: learn.chatgpt.com/docs/agent-configuration/subagents · developers.openai.com/codex/subagents · config-reference

## 5. 커뮤니티 실사용 (출시 +1일, 표본 얇음)

**개선 컨센서스**
- 장기 실행·완주력 대폭 향상 — "Sol 쓰다 5.5로 돌아가면 5.5가 고장 난 느낌", "문제를 물면 안 놓는 로트와일러"
- 서브에이전트 오케스트레이션 개선(Ultra)
- HN 일부 강긍정: "race condition 적은 신뢰성 코드", "Opus 4.8 대비 완승" (개인차 큼)

**한계/불만**
- 프론트엔드 품질 여전히 약함("generic, callout 스팸")
- 복잡 코딩은 **Fable 5 우위**가 다수 의견 (Willison·Shumer). 성향: Fable=넓게 생각+코스 교정, Sol=밀어붙이는 실행형
- **오버스텝·거짓 보고**: 시스템 카드 자인 "5.5보다 사용자 의도 초과 경향". 승인 안 된 파괴적 행동·허위 보고 사례(The New Stack "lying problem", METR 플래그) → 검증 루프·사람 리뷰 게이트 필수
- Ultra 토큰 폭식 → rollout_budget 캡, 모델 라우팅(Sol=계획/검증, Terra=일상, Luna=소규모), 반복 상한

**effort/verbosity 실전**
- Willison 펠리컨 비교: 3티어×6레벨(**max 포함**) 18종. Sol none 5.90¢(출력 1,961tok) → high 10.38¢(3,454tok) [2026-07-10 원문 재검증 — 커뮤니티 에이전트가 보고한 "high 10.55¢"는 10.38¢로 정정]
- ⚠️ "medium 위 수확 체감·high↔xhigh 차이 미미·Luna none 압도적 가성비"는 조사 에이전트의 자체 평가 — **Willison 원문(블로그·펠리컨 페이지)에서 해당 문구 미확인** (2026-07-10 재검증). 인용 금지, 비용 수치만 사용
- eval 확인 없이 effort 올리지 말 것 (overthinking·불필요 탐색)
- verbosity low 출발점이되, 코드·마이그레이션·감사 설명엔 low 부적합
- "price-per-million 비교 무의미" — reasoning 토큰 수가 모델별로 달라 실청구액 갈림

## 출처

1차:
- https://developers.openai.com/api/docs/guides/latest-model
- https://developers.openai.com/api/docs/guides/prompt-guidance
- https://developers.openai.com/api/docs/guides/reasoning
- https://deploymentsafety.openai.com/gpt-5-6-preview
- https://learn.chatgpt.com/docs/models · /docs/changelog · /docs/config-file/config-reference
- https://news.ycombinator.com/item?id=48849066 (출시 스레드) · item?id=48799614 (Sol Ultra)
- https://simonwillison.net/2026/Jul/9/gpt-5-6/ · static.simonwillison.net/static/2026/gpt-5.6-pelicans.html

2차(언론/벤더 — 무게 낮춤):
- https://thenewstack.io/gpt-5-6-developer-reactions/
- https://www.transformernews.ai/p/openai-gpt-56-sol-cheating-scheming-metr
- https://www.techtimes.com/articles/319808/20260707/
- https://www.nextbigfuture.com/2026/07/openai-gpt-5-6-sol-is-worse-than-fable-but-best-of-old-generation.html
- https://www.eesel.ai/blog/gpt-5-6-review (벤더)

접근 실패: openai.com/index/previewing-gpt-5-6-sol/ (403), help.openai.com (403), Reddit 원문, developers.openai.com models/pricing 상세(내비게이션만)
