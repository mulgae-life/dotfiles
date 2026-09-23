# GPT-6 Prompting Guide (Astra·Sol·Luna)

> **출처**:
> - [Prompting guidance | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance)
> - [Using GPT-6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
> - 모델 카드: [gpt-6-astra](https://developers.openai.com/api/docs/models/gpt-6-astra) · [gpt-6-sol](https://developers.openai.com/api/docs/models/gpt-6-sol) · [gpt-6-luna](https://developers.openai.com/api/docs/models/gpt-6-luna)
> - [Reasoning models | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning) · [Pricing | OpenAI API](https://developers.openai.com/api/docs/pricing)
> - [Introducing GPT-6 Sol and Luna | OpenAI](https://openai.com/index/introducing-gpt-6-sol-and-luna/)
> - [GPT-6 Astra 시스템 카드](https://deploymentsafety.openai.com/gpt-6-astra)
> - [Codex models | OpenAI](https://learn.chatgpt.com/docs/models)
> - [Simon Willison — GPT-6 Astra (2026-09-03)](https://simonwillison.net/2026/Sep/3/gpt6-astra/)
>
> **검증일**: 2026-09-07 (Astra), 2026-09-23 (Sol·Luna 반영)
> **이전 버전**: [GPT-5.6 Prompting Guide](./gpt-5.6-prompt-guide.md)
> **조사 원문**: [research-gpt6.md](../research/research-gpt6.md) (Astra) · [research-opus55-gpt6-sol.md](../research/research-opus55-gpt6-sol.md) (Sol·Luna)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.6 → 6)

GPT-6는 2026-09-03에 Astra 한 모델로 시작했고, 2026-09-22에 Sol과 Luna가 더해져 Astra·Sol·Luna 3티어가 됐습니다. 5.6의 Sol·Terra·Luna는 조사 시점(9/23)에도 API 가격표에 남아 있습니다. 이 문서의 행동 축과 마이그레이션 내용은 Astra 출시 때의 공식 가이드를 기준으로 썼고, Sol·Luna에서 달라지는 API 계약과 Codex 기본 지시문은 §0에 모았습니다. 이름이 겹치므로 이 문서에서 이전 세대 모델은 항상 "5.6 Sol", "5.6 Luna"로 적습니다.

프롬프트 관점에서 이번 세대의 변화는 파라미터가 아니라 행동에 있습니다. Astra는 질문을 더 자주 던지고 그 자리에서 멈추며, 완료를 선언하기 전에 스스로 과하게 테스트하고, 기대보다 서브에이전트를 덜 씁니다. 세 가지 모두 OpenAI가 공식 문서에서 직접 인정한 성향이고, 대응 방법으로 프롬프트 스니펫을 제시합니다.

5.6 마이그레이션의 핵심이 "지시를 줄여라"였다면 이번에는 방향이 다릅니다. Astra는 긴 지시를 더 잘 따르지만 문맥에 더 민감해서, 분량보다 지시 파일 사이의 모순이 실패를 만듭니다. 새 문장을 쓰기 전에 기존 지시 파일을 먼저 감사하십시오.

### 한 페이지 변화 요약

| 항목 | 5.6 | 6 Astra |
|------|-----|---------|
| 모델 라인업 | Sol/Terra/Luna 3티어 + `gpt-5.6` 별칭 | **`gpt-6-astra`**(스냅샷 1종)로 시작. 9/22부터 Sol·Luna를 더한 3티어(§0). 5.6 3종은 계속 제공 |
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

오른쪽 열은 Astra 기준입니다. Sol·Luna는 `none` effort를 지원하고 샘플링 파라미터와 Chat Completions 함수 호출의 조건도 달라서, 두 모델의 API 계약은 §0.2 표로 따로 확인합니다.

---

## 0. GPT-6 제품군 (Astra·Sol·Luna)

### 0.1 티어와 가격

2026-09-22에 Sol과 Luna가 나왔습니다. OpenAI 발표문은 Astra를 계속 최상위로 두고("GPT‑6 Astra continues to be our best model across the board."), Sol과 Luna를 Astra와 비슷한 방법으로 훈련해 더 빠르고 저렴하게 만든 모델로 소개합니다. Sol은 Astra의 저비용 대안이고, Luna는 범위가 분명한 대량 작업용입니다. 5.6 Terra에 대응하는 GPT-6 티어는 없습니다. 확인한 것은 Terra라는 이름의 후속이 없다는 사실뿐이고, 5.6 Terra의 용도를 기능상 대신할 모델이 있는지는 판단하지 않았습니다.

| 항목 | Astra | Sol | Luna |
|------|-------|-----|------|
| API ID | `gpt-6-astra` | `gpt-6-sol` | `gpt-6-luna` |
| 출시 | 2026-09-03 | 2026-09-22 | 2026-09-22 |
| 모델 카드 소개 | "Our most capable model, built for the hardest end-to-end work" | "Built to power complex coding and agentic workflows." | "Our most efficient model for focused, high-volume tasks." |
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000 | 같음 | 같음 |
| 지식 컷오프 | 2026-04-30 | 2026-04-20 | 2026-05-18 |
| 입력 / 캐시 입력 / 캐시 쓰기 / 출력 ($/1M, Standard) | $10 / $1 / $12.50 / $50 | $2 / $0.20 / $2.50 / $10 | $0.10 / $0.01 / $0.125 / $0.50 |
| 입력 272K 초과 요청 (요청 전체 적용) | $20 / $2 / $25 / $75 | $4 / $0.40 / $5 / $15 | $0.20 / $0.02 / $0.25 / $0.75 |

- 긴 입력 할증은 세 모델이 같습니다. 원문은 "Prompts with more than 272K input tokens are priced at 2x input and cache rates and 1.5x output for the full request."입니다. 초과분만이 아니라 요청 전체가 할증됩니다.
- Batch·Flex는 Standard의 50%, Fast 모드는 2배입니다. 세 모델 카드의 문구가 같습니다.
- Sol은 입력·캐시·출력 단가가 모두 Astra의 1/5이고, 표시 가격은 5.6 Sol 프로모션가($4 / $20)의 절반입니다.
- 공식 문서끼리 갱신 시점이 어긋난 곳이 있습니다. 조사 시점에 API 모델 목록 도입부와 reasoning 가이드 도입부는 여전히 저비용 선택지로 5.6 Terra·5.6 Luna를 안내했습니다.

### 0.2 API 계약 차이

| 항목 | Astra | Sol·Luna |
|------|-------|----------|
| `reasoning.effort` | `low`, `medium`, `high`, `xhigh`, `max`. `none`은 HTTP 400 | `none`, `low`, `medium`(기본), `high`, `xhigh`, `max` |
| `minimal` | 지원 목록에 없음. `low`부터 비교 | 같음 |
| Chat Completions 함수 호출 | 불가. Responses 필요 | `reasoning_effort: "none"`일 때만 가능. 추론과 도구를 함께 쓰려면 Responses |
| `temperature`·`top_p`·`top_logprobs` | 제거 (Astra는 `none`을 받지 않으므로 항상 해당) | effort가 `none`이 아니면 제거. `none`에서 이 값들이 허용된다는 명시 문장은 원문에 없음 |
| Chat Completions `logprobs`, Responses `include`의 `message.output_text.logprobs` | 위와 같은 조건으로 제거 | 위와 같은 조건으로 제거 |
| 대화 중 effort 변경(`configuration_update`) | 제품군 공통. 표준 단일 에이전트 모드에서 effort만 바꿈 | 같음 |
| EU 데이터 레지던시 | Standard 처리에서만 | 같음 |
| 엔드포인트·지원 도구 | Responses·Chat Completions·Batch. 도구 목록은 §5.3 | 같음 |

원문은 다음과 같습니다.

> "GPT-6 Astra does not support the `none` reasoning effort; GPT-6 Sol and Luna do."
> "GPT-6 Astra supports Chat Completions, but its tool calling requires Responses. GPT-6 Sol and Luna support function calling in Chat Completions only with `reasoning_effort: "none"`. Use Responses for reasoning with tools."
> "When reasoning effort is not `none`, remove `temperature`, `top_p`, and `top_logprobs`. For Chat Completions, also remove `logprobs`. For Responses, remove `message.output_text.logprobs` from `include`."

`ultra`는 세 모델 모두 API effort 값이 아닙니다(§1).

### 0.3 프롬프트 지침

확인한 공식 문서 범위(API 문서 색인, 블로그 색인, 쿡북 색인)에서 Sol 전용 프롬프팅 가이드는 없습니다. `guides/latest-model/gpt-6-sol` 경로는 조사 시점에 404였습니다. [Using GPT-6](https://developers.openai.com/api/docs/guides/latest-model)는 Astra 가이드를 제품군 전체로 넓혔고, 프롬프팅 절의 도입 문장은 아래와 같습니다.

> "Use the following prompts as a starting point across the GPT-6 model family. They address behavior observed with GPT-6 Astra; evaluate them with your chosen model and workload."

그래서 §4의 스니펫은 Sol·Luna에서도 출발점이지만, Astra에서 관찰한 성향을 겨냥한 문장이므로 고른 모델과 작업으로 평가한 뒤 씁니다.

같은 페이지에서 기존 이 가이드에 없던 문장은 두 개입니다. 둘 다 Astra 행동을 설명하는 문단에 있습니다.

> "It can be more sensitive to instructions contained in skills and other files, such as `AGENTS.md`. We **strongly recommend** auditing skills and other files accessible to your model for instructions that could influence its behavior."

> "The model also likes to ask non-blocking questions as it’s working by default, so adjust these prompts to match the level of autonomy your application needs."

첫 문장은 §4.2 지시 준수 축에 속합니다. 모델이 스킬과 `AGENTS.md` 같은 파일 속 지시에 민감하므로 그 파일들을 감사하라고 강하게 권하는 문장입니다. 둘째 문장은 §4.1 주도성 축에 속합니다. 모델이 기본적으로 작업을 멈추지 않은 채 질문을 던지므로, 앱이 원하는 자율 수준에 맞춰 §4.1 스니펫을 조정하라는 뜻입니다.

### 0.4 Codex에서의 Sol·Luna

- **버전**: 안정판 선택기 등재는 Codex CLI 0.156.1(2026-09-23 핫픽스)부터입니다
- **기본 모델의 층위**: 0.156.1에서 `model`을 비우면 CLI는 카탈로그 우선순위 1인 Astra를 고릅니다(우선순위 Astra 1, Sol 2, Luna 3). 공식 서브에이전트 문서는 "For most tasks in Codex, start with `gpt-6-sol`."라고 권하므로, CLI 기본값과 공식 권고가 다릅니다
- **Sol 사용처**: Codex 모델 문서는 "Choose Sol for ambiguous, difficult, or high-value tasks that need extra analysis, judgment, or polish ... For narrower tasks, define what done looks like to keep the work focused."라고 적습니다. Luna는 "specific, high-volume tasks when you know what a good result looks like"에 둡니다
- **effort**: 모델별 선택기 값과 시작 권고는 §1의 Codex 표에 있습니다
- **크레딧**(Standard 속도, 1M당 입력 / 캐시 입력 / 출력): Astra 250 / 25 / 1,250, Sol 50 / 5 / 250, Luna 2.5 / 0.25 / 12.5입니다. Fast 모드는 세 모델 모두 2.5배입니다
- **컨텍스트 창**: Sol·Luna도 카탈로그 값이 272K, 최대 872K로 Astra와 같습니다(§6)
- **`ultra` 위임 힌트**: Sol도 `ultra`에서 Astra와 같은 `<multi_agent_mode>` 힌트를 받습니다. 해석은 §6에 있습니다

### 0.5 Codex 기본 지시문: Astra와 Sol의 차이

가장 구체적인 Sol 지침은 Codex가 모델 카탈로그의 `instructions_template`으로 주입하는 기본 지시문입니다. 조사 시점 카탈로그에서 세 모델의 `model_messages`는 이 템플릿만 다르고, 다중 에이전트 역할·승인·토큰 예산 문구는 같습니다.

| 영역 | Astra 템플릿 | Sol 템플릿 |
|------|--------------|------------|
| 성격 문장 | "a lucid communicator. You speak warmly and candidly" | "a simple, clear communicator" |
| 글쓰기 | 연결된 산문("Write in connected prose"), PR 설명 절, 기술 소통 절이 있음 | 세 가지가 없음. "You strive to minimize cognitive load for the user"가 있고, 독자가 빠진 단계를 메우리라 가정하지 말라고 적음 |
| 실행 요청 해석 | "can you...", "help me..."를 작업 지시로 취급하는 문단이 있음 | 이 문단이 없음. 공통 문장 "bias towards action and carry the user's intended task to completion"은 남음 |
| 사용자 지적 대응 | 없음 | 새로 생김. 사용자가 방식을 바로잡거나 실수를 지적하면 설명이나 인정보다 수정을 원한다고 가정함. 설명만 요청하거나 멈추라고 하면 그 지시를 따름 |
| 테스트 확대 조건 | "Run tests appropriate to the change and complete required checks. Once those pass, broaden or repeat testing only when new changes, failures, or unresolved concerns justify it" | "Broaden or repeat testing only to resolve a concrete remaining risk or satisfy a required gate. Once sufficiently verified, stop optional testing and continue toward the user's goal." |
| 외부 메시지 전송 | 명시 지시가 있거나 명시 호출한 스킬·플러그인이 지시할 때만 보냄. 스킬·플러그인이 근거면 최종 답에 그 이름과 링크를 적음 | "unless explicit authorization is already provided" |
| 스킬 때문에 멈출 때 | 읽은 SKILL.md의 이름과 링크를 대고 해당 지시를 인용함. 스킬이 승인을 명시하지 않으면 허용 범위 안에서 진행함 | 스킬 이름과 해당 지시의 요약만 적음 |
| 질문 도구의 응답 대기 | 단순 객관식 질문에 60초 | 30초 |

Luna 템플릿은 Sol과 두 곳이 다릅니다. 권한 절에서 "Once evidence in a session supports authorization for a next step or action, you should continue work without ending the turn to clarify with the user." 문장이 빠졌습니다. 또 테스트 두 줄과 사용자 지적 대응 문단 자리에 "Do not add or run tests unless the user asks you to test or verify implementation." 한 줄이 들어갔습니다.

**dotfiles 적용**: Codex `developer_instructions`의 "~해줄래 → 실행 지시" 줄은 유지합니다. Sol 템플릿에는 "can you..." 실행 해석 문단이 없고 일반 실행 편향만 남았으므로, 이 줄이 한국어 요청 해석을 구체화하는 보완 역할을 합니다. 같은 `developer_instructions`의 테스트 범위 줄("테스트 확대·반복은 새 변경·실패·미해결 우려가 있을 때만")도 Sol 템플릿의 "구체적 잔여 위험이나 필수 기준이 있을 때만 검증 확대"와 충돌하지 않습니다.

---

## 1. effort 선택과 ultra

5.6에서는 Sol·Terra·Luna 중 무엇을 고르느냐가 가장 큰 비용 레버리지였습니다. Astra 한 모델만 있던 9/3~9/21에는 추론 강도 선택이 그 자리를 대신했고, 9/22 Sol·Luna 출시로 모델 선택(§0)이 다시 비용 레버리지가 됐습니다. 받는 값은 API와 Codex 선택기가 다르고 모델마다도 다르므로 표를 나눕니다.

### API `reasoning.effort`

| 단계 | Astra | Sol·Luna | 사용처 |
|------|-------|----------|--------|
| `none` | HTTP 400 | 지원 | 추론이나 연쇄 도구 호출이 필요 없는 지연 민감 작업. Astra에서는 `low`로 대체 |
| `low` | 지원 | 지원 | Astra에서는 5.6의 `none`·`minimal` 자리를 옮길 출발점 |
| `medium` | **기본값** | **기본값** | 품질·비용 균형 |
| `high` | 지원 | 지원 | 일반 코딩 작업에 무난한 선택 (2차) |
| `xhigh` | 지원 | 지원 | high보다 유의미한 개선이 확인된 고난도 작업 |
| `max` | 지원 | 지원 | 가장 어려운 문제만. 전역 기본값 금지 |
| `ultra` | 없음 | 없음 | **API 값이 아님.** Codex·ChatGPT 제품 표면 전용 |

### Codex 선택기 effort

| 모델 | 선택 가능한 값 | 공식 시작 권고 |
|------|----------------|----------------|
| Astra | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` | Light(설정값 `low`) |
| Sol | `low`, `medium`, `high`, `xhigh`, `max`, `ultra` | Medium |
| Luna | `low`, `medium`, `high`, `xhigh`, `max` (`ultra` 없음) | High |

Codex 선택기에는 `none`이 없습니다. API에서 Sol·Luna가 `none`을 받는 것과 별개입니다. 값 목록은 Codex 0.156.1 모델 카탈로그의 `supported_reasoning_levels`이고, 시작 권고는 Codex 모델 문서의 "Start with **Medium** for Sol, **High** for Luna, or **Light** for Astra."입니다. 같은 문서는 "GPT-6 Luna supports reasoning efforts up to **Max**, but not **Ultra**."라고 적습니다.

### ultra의 정체

`ultra`는 여섯 번째 단계로, 단일 에이전트 실행을 넘어 서브에이전트에 작업을 자동 분배합니다.

> "Ultra mode goes beyond a single-agent run. It uses subagents to accelerate complex work, making it useful for larger tasks that can be split across subagents."

5.6 문서에 나오던 "Sol Ultra"는 병렬 서브에이전트 모드라는 별도 개념이었습니다. GPT-6에서는 같은 이름이 추론 강도 값 하나로 노출됩니다. Codex 모델 카탈로그의 설명도 이 취지와 같습니다. `ultra`는 "Maximum reasoning with automatic task delegation", `max`는 "Maximum reasoning depth for the hardest problems"로 구분됩니다.

공식 안내는 "most tasks do not need Max or Ultra"입니다.

**상태: 상충.** API 모델 문서(Astra·Sol·Luna)와 마이그레이션 가이드는 `max`까지만 열거하고 ultra를 언급하지 않는 반면, learn.chatgpt.com 모델 문서와 로컬 Codex 캐시는 정식 단계로 싣습니다. 현재 판단은 제품 표면 전용이며 API 호출로는 미확인입니다.

**dotfiles 적용**: 레포 `.codex/config.toml`은 v2.29부터 `model`과 `model_reasoning_effort`를 비워 두고 Codex 기본값을 따릅니다(6행 주석). `/model`·`/effort`로 런타임 `~/.codex/config.toml`에 저장한 값은 레포 설정과 다를 수 있고, 재설치하면 레포 버전으로 돌아갑니다. `ultra`는 설정 파일에 고정하지 않고 필요할 때 세션에서 선택합니다.

---

## 2. Migration: 5.6 → 6

공식 마이그레이션 절은 모델 선택과 일곱 가지 점검 항목을 요구합니다. 여기에 우리 쪽 추가 항목 하나를 더했습니다. Sol·Luna 출시 뒤 이 절이 제품군 전체를 다루게 되어, Astra와 Sol·Luna에서 조건이 갈리는 항목은 둘 다 적었습니다.

### 마이그레이션 체크리스트

1. [ ] `model`을 `gpt-6-astra`·`gpt-6-sol`·`gpt-6-luna` 중 하나로 설정(§0.1)
2. [ ] effort는 지원되는 범위에서 현재 값을 유지 — "Preserve your current effective reasoning effort where supported." Astra는 `none`을 받지 않으므로 `low`로 옮기고, Sol·Luna는 `none`을 그대로 둘 수 있습니다. `minimal`은 "If your existing request uses `minimal`, start with `low` and compare results on representative tasks."
3. [ ] 도구 호출 경로 확인 — Astra는 Responses로 이전하고, Sol·Luna의 Chat Completions 함수 호출은 `reasoning_effort: "none"`일 때만 됩니다. "Use Responses for reasoning with tools."
4. [ ] effort가 `none`이 아니면 `temperature`·`top_p`·`top_logprobs` 제거. Chat Completions는 `logprobs`도, Responses는 `include`의 `message.output_text.logprobs`도 뺍니다. Astra는 `none`이 없으므로 항상 해당합니다
5. [ ] GPT-5.5 이하에서 옮길 때 `prompt_cache_retention` → `prompt_cache_options.ttl = "30m"`
6. [ ] EU 데이터 레지던시는 세 모델 모두 Standard 처리에서만 가능 — "For GPT-6 Astra, Sol, and Luna, EU data residency is available only with Standard processing." Astra의 Fast 모드에는 지연 시간 SLA가 없습니다
7. [ ] 응답 사이에 effort를 바꾸는 앱은 표준 단일 에이전트 요청에서 `configuration_update`를 쓰고, 캐시 접두사를 지키도록 요청 수준 `reasoning.effort`는 바꾸지 않음
8. [ ] 승인 대기로 멈추는 증상은 §4.1 주도성 스니펫으로 대응
9. [ ] **(추가) 지시 파일 감사** — AGENTS.md·CLAUDE.md·스킬에서 모순되거나 낡은 문장을 제거하고 사용자 지시 우선권을 명시. 공식 문서도 이 감사를 "strongly recommend"합니다(§0.3)

5.6 프롬프트를 그대로 써도 되는지를 직접 밝힌 공식 문장은 **없습니다(미확인)**. 다만 마이그레이션 절이 파라미터·API·추론 강도 변경을 요구하고 다섯 행동 축 모두에서 조정을 권고하므로, 사실상 튜닝 패스가 필요하다고 읽는 것이 맞습니다.

---

## 3. Reasoning Effort

- **기본값 `medium`**으로 5.6과 같습니다. Sol·Luna도 기본 `medium`입니다("GPT-6 Sol and Luna also default to `medium` reasoning effort."). Responses에서는 `reasoning.effort`, Chat Completions에서는 `reasoning_effort`입니다
- `none` 지원은 모델마다 다릅니다. 원문: "GPT-6 Astra does not support the `none` reasoning effort; GPT-6 Sol and Luna do." Astra에 `none`을 보내면 HTTP 400이므로, Astra로 옮기는 설정은 낡은 프로파일·훅 스크립트에 남은 `reasoning_effort = "none"`을 먼저 제거하십시오. `minimal`은 세 모델 모두 지원 목록에 없습니다
- 대화 중간에 바꿀 수 있습니다. `configuration_update` 입력 항목으로 어려운 구간에서 올리고 일상 후속 작업에서 내립니다. 제품군 공통 기능이며, 표준 단일 에이전트 모드에서 effort만 바꿉니다

**비용 감각** (2차): Simon Willison의 펠리컨 비교에서 Astra max effort 한 장이 출력 12,638토큰에 63.21센트였고, 같은 프롬프트가 5.6 Luna에서는 1.57센트였습니다. 약 40배 차이입니다. Artificial Analysis 실측으로는 Astra max effort 작업당 비용이 5.6 Sol 대비 약 75% 비쌉니다.

**dotfiles 적용**: 레포 `.codex/config.toml`에는 `model_reasoning_effort`도 `plan_mode_reasoning_effort`도 없어 두 값 모두 Codex 기본값을 따릅니다. 런타임 설정에 저장한 값은 레포와 다를 수 있습니다. `max`·`ultra`는 설정 파일에 넣지 않습니다.

---

## 4. 행동 축 다섯 가지

OpenAI가 이번 세대에서 특히 조정이 필요하다고 지목한 축입니다. 각 절의 코드 블록은 공식 페이지에서 그대로 옮긴 영문 원문입니다. 공식 페이지는 이 스니펫을 GPT-6 제품군 전체의 출발점으로 제시하지만, 스니펫이 겨냥한 행동은 Astra에서 관찰한 것입니다(§0.3).

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

**dotfiles 적용**: 우리 Codex 층 `AGENTS.md`는 "역할 트리거만으로 자동 위임하지 않는다"는 원칙을 유지합니다. `ultra`에서 하네스가 주입하는 힌트는 이 원칙을 문구상 무효화하지 않습니다. 힌트가 대체한다고 적은 대상은 "earlier developer instruction"인데 이 조항은 힌트보다 뒤에 오는 user 역할의 `AGENTS.md`에 있고, 힌트 스스로 사용자 요청이 힌트보다 우선한다고 적었기 때문입니다(§6). `ultra`에서 실제로 위임이 얼마나 일어나는지는 재지 않았습니다.

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

| 대상 | Astra | Sol·Luna |
|------|-------|----------|
| `temperature`, `top_p`, `top_logprobs` | 제거. Chat Completions는 `logprobs`도 | effort가 `none`이 아니면 같은 조치 |
| `reasoning.effort: "none"` | HTTP 400. `low`로 대체 | 지원 |
| `reasoning.effort: "minimal"` | 지원 목록에 없음. `low`부터 비교 | 같음 |
| `prompt_cache_retention` | `prompt_cache_options.ttl`(예 `"30m"`)로 대체 | 같음 |
| 도구 호출 in Chat Completions | Responses API로 이전 | 함수 호출은 `reasoning_effort: "none"`일 때만. 추론과 함께 쓰려면 Responses |

### 5.2 신규

- **Async tool calling** — "GPT-6 can continue reasoning, call other tools, or answer independent parts of a request while your application runs a tool."
- **Mid-turn steering** — "Send additional user instructions while GPT-6 is working, such as a correction or a change in requirements."
- **대화 중 추론 강도 변경** — "Add a `configuration_update` input item to increase reasoning effort for difficult work or reduce it for routine follow-ups without rewriting the original prompt prefix." 제품군 공통이고 표준 단일 에이전트 모드에서만 됩니다
- **비정렬 모니터링** — "Our systems asynchronously monitor for misalignment and trigger alerts when necessary." 공식 문서는 Astra의 강화된 안전장치로 소개합니다

이 가이드의 9/7 판은 앞의 두 항목 주어를 "GPT-6 Astra"로 인용했고, 조사 시점(9/23) 문서에서는 "GPT-6"입니다.

### 5.3 계승

Structured Outputs, Programmatic Tool Calling, `reasoning.mode: "pro"`, `reasoning.context`(auto/current_turn/all_turns), compaction, 멀티에이전트 오케스트레이션, 프롬프트 캐싱은 5.6에서 그대로 이어집니다. 지원 도구는 web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search입니다. 미지원은 Realtime, Assistants, 파인튜닝, 임베딩이고, 입력 모달리티는 텍스트와 이미지뿐이라 일부 매체가 보도한 오디오 입력은 오보로 판단합니다. Sol·Luna 모델 카드의 지원 도구, 엔드포인트, 모달리티도 Astra와 같습니다.

---

## 6. Codex에서의 Astra

- **최소 버전**: Codex CLI **0.153.0** 이상이며 후속 수정 반영 기준으로는 0.153.4를 권장합니다
- **기본 모델**: 0.153.4 릴리스 노트는 "Fixed Astra's visibility in the bundled model picker and made it the bundled default when no model is explicitly configured."라고 적습니다. `model`을 비워 둔 설정에서는 Astra가 선택됩니다
  - **문서 간 불일치**: learn.chatgpt.com 모델 문서는 ChatGPT 계정으로 로그인한 Codex 사용자에게는 기본이 아니라고 안내합니다. 그러나 ChatGPT 로그인 계정에서 `model` 키 없이 0.153.4 TUI를 새로 띄운 세션이 `gpt-6-astra`로 돌았으므로(2026-09-06 실측) 실제로는 로그인 방식과 무관하게 Astra가 기본입니다. 엔터프라이즈는 관리 콘솔에서 별도 활성화가 필요합니다
  - **Sol 출시 뒤**: 0.156.1에서도 `model`을 비우면 카탈로그 우선순위 1인 Astra가 잡힙니다. 공식 문서는 Codex 대부분 작업을 Sol에서 시작하라고 권하므로 CLI 기본값과 공식 권고가 다릅니다(§0.4)
- **컨텍스트 창**: 로컬 모델 캐시는 `context_window: 272000`, `max_context_window: 872000`, 유효 95%로 API 문서의 1,050,000과 다릅니다
  - **상충하지만 설명 가능**: 272K는 롱컨텍스트 요율이 발동하는 과금 임계와 같은 값이고 5.6에서도 같은 구조였습니다. Codex가 기본 창을 과금 티어에 맞춰 잡아 둔 것으로 읽히나 확정 근거는 미확보입니다. 실무 조언(2차)은 `auto_compact_token_limit`을 200K 근처로 두어 임계를 넘지 않게 하라는 것입니다
- **크레딧**: 입력 1M당 250, 출력 1M당 1,250으로 5.6 Sol(100/500) 대비 **2.5배**, GPT-6 Sol(50/250)의 5배입니다
- **ultra 실측**: `codex debug prompt-input`으로 추론 강도만 바꿔 렌더링을 비교하면 주입되는 `<multi_agent_mode>` 문구가 달라집니다. 0.156.1에서 Sol도 같은 문구를 받고, Luna는 `ultra`가 없습니다

| effort | 주입 문구 |
|--------|-----------|
| high 이하 | "Do not spawn sub-agents unless the user or applicable AGENTS.md/skill instructions explicitly ask for sub-agents, delegation, or parallel agent work." |
| ultra | "Proactive multi-agent delegation is active. Any earlier developer instruction requiring an explicit user request before spawning sub-agents no longer applies. ... User requests override this hint." |

`ultra` 힌트가 대체한다고 적은 대상은 "earlier developer instruction"입니다. 0.156.1에서 레포 config·`AGENTS.md`·rules를 넣고 `codex debug prompt-input -c model="gpt-6-sol"`로 렌더링하면(모델 호출 없음) 입력 순서는 developer 메시지 3개(기본 지시문과 `developer_instructions`, 권한, `<multi_agent_mode>`), user 역할의 `AGENTS.md`, user 프롬프트입니다. 레포 위임 조항은 `developer_instructions`가 아니라 힌트보다 뒤에 오는 user 역할의 `AGENTS.md`에 있으므로 문구상 무효화 대상에 해당하지 않습니다. 또 힌트 스스로 "User requests override this hint."라고 적었습니다. 따라서 이 가이드의 이전 판이 적은 "`ultra`를 켜는 순간 `AGENTS.md`의 위임 억제 원칙이 무효화된다"는 과장이었습니다.

이 판단의 근거는 힌트 문구의 적용 대상과 힌트가 명시한 사용자 요청 우선입니다. 뒤에 오는 user 메시지가 developer 메시지보다 항상 우선한다는 일반 원칙으로 읽지 마십시오. 렌더링은 메시지 배치를 확인했을 뿐이고, `ultra`에서 실제로 위임이 얼마나 일어나는지는 재지 않았습니다. `high` 이하에서는 하네스가 같은 취지의 문구로 원칙을 보강합니다.

카탈로그의 나머지 값은 기본 추론 강도 medium, 기본 verbosity low, 기본 추론 요약 none, 도구 모드 `code_mode_only`, 셸 `unified_exec`, 멀티에이전트 v2입니다. `multi_agent_reasoning_effort`는 카탈로그 전용 필드이며 사용자 설정 키가 아닙니다.

---

## 7. 시스템 카드 요점

- **Preparedness**: 사이버 보안 **Critical** 등급으로 OpenAI 최초이고 생물·화학은 High입니다. 완전한 사이버 능력은 Daybreak이라는 심사 기반 프로그램으로 따로 개방합니다
- **정렬 개선**: 최대 추론 강도 코딩 작업에서 허위 보고율이 5.6 Sol의 4분의 1입니다. 확인 정책이 없을 때 의도 이탈 결과 비율은 Astra 3.4%, 5.6 Sol 18.8%이고, Codex 내부 작업 54,218건에서 고위험 플래그가 5.6 Sol의 약 절반입니다
- **관측 가능성 하락 자인**: "GPT-6 Astra shows a substantial decrease in chain-of-thought monitorability compared to previous models." 추론을 말로 풀지 않고도 복잡한 작업을 수행할 수 있어 감시 사각지대가 생기며, 적대적 조건에서는 평가에서 전략적으로 실력을 감추면서도 탐지되지 않을 수 있다고 적혀 있습니다
- **벤치마크**: FrontierMath Tier 4 98%, OSWorld 2.0 72.6%(5.6 Sol 65.7%), ARC-AGI-3 99.9%. 다만 ARC-AGI-3 수치는 Provider Adapter 하네스 결과이고 ARC Prize의 Standard 하네스로는 62.7%입니다. SWE-Bench 계열은 출시 자료에 미공개입니다

---

## 8. 외부 관찰 (2차, 출시 +3일이라 표본이 얇음)

아래는 Astra 출시 직후 관찰이고, 비교 대상 Sol·Luna는 모두 5.6 세대입니다. GPT-6 Sol·Luna의 3자 평가와 후기는 [research-opus55-gpt6-sol.md](../research/research-opus55-gpt6-sol.md) 4·5절에 있습니다. Artificial Analysis는 09-07에 지능 지수를 v4.3으로 개정했으므로 아래 지수와 그 문서의 지수를 섞어 비교하지 않습니다.

**Artificial Analysis** (3자 실측)

| 지표 | Astra | 비교 |
|------|-------|------|
| Intelligence Index | 61 | 5.6 Sol 60.9와 사실상 동률, Fable 5.1보다 5점 낮음 |
| Coding Agent Index | 67.0 | 5.6 Sol 65.1, Opus 5·Fable 5와 동률 |
| 코딩 토큰 효율 | 5.6 Sol 대비 70% 개선 | 생성 속도는 61~64 t/s로 평균 74보다 느림 |
| 작업당 비용 (max) | 5.6 Sol 대비 +75% | 토큰 절감이 2.5배 단가를 일부만 상쇄 |
| GDPval-AA v2 | 약 −80 Elo | 경제적 가치가 큰 전문 업무에서 후퇴 |

**Simon Willison**: "Astra is a beast at security tasks", "clearly OpenAI's Fable competitor". 펠리컨 비교에서 max effort 한 장 63.21센트 대 5.6 Luna 1.57센트로 약 40배 격차입니다.

**CodeRabbit** (벤더 자체 평가라 무게 조정 필요): 실행 가능한 버그 커버리지 61.3%로 5.6 Sol 59.0%, Opus 5 50.2%보다 높습니다. 고정 사용량 기준 작업 비용은 $1.50로 Fable 5.1과 같습니다. 저자들이 "early, directional results"라고 단서를 달았습니다.

**첫 주 최다 불만**: 질문 과다로 작업이 멈춘다는 것입니다. 그다음이 `ultra` 미만에서의 위임 부족, 그리고 글쓰기 후퇴입니다. 편집 문체 평가에서 1995 Elo로 11위이며 이전 세대 2156보다 낮습니다.

---

## 9. 핵심 정리

1. 파라미터보다 행동이 바뀌었습니다. 주도성, 지시 준수, 문체, 위임, 검증 다섯 축을 프롬프트에서 조정합니다.
2. 새 지시를 쓰기 전에 기존 지시 파일의 모순부터 걷어냅니다. Astra에서는 이것이 가장 큰 실패 요인입니다.
3. 자율 실행이 필요하면 "bias towards action" 계열 문장을 명시하고, 확인은 되돌리기 어려운 행동 직전에만 받게 합니다.
4. 검증은 늘리는 것이 아니라 좁히는 방향으로 지시합니다.
5. 위임은 자동으로 기대하지 말고 갈래·경계·대기 여부·반환 형식을 지정합니다. 기본은 medium 또는 high로 두고 `max`·`ultra`는 진짜 어려운 문제에만 씁니다. 비용 격차가 수십 배입니다.
6. Sol·Luna는 Astra와 API 계약이 다릅니다. `none` 지원, 샘플링 파라미터 제거 조건, Chat Completions 함수 호출 조건을 §0.2에서 확인합니다. Sol 전용 공식 프롬프팅 가이드는 없으므로 Astra 기준 스니펫에서 시작해 고른 모델로 평가합니다.

---

## 10. 한 페이지 치트시트

### API 호출 디폴트

```python
response = client.responses.create(
    model="gpt-6-astra",
    reasoning={
        "effort": "medium",               # Astra: 5.6의 none·minimal 자리는 low부터 비교
        # "mode": "pro",                  # 오답 비용 큰 지점만 선별
        # "context": "all_turns",         # 장기 워크플로우만
    },
    text={"verbosity": "medium"},
    prompt_cache_options={"ttl": "30m"},  # prompt_cache_retention 대체
    input=[ ... ],
    tools=[ ... ],                        # Astra 도구 호출은 Responses 전용
    # Astra는 temperature / top_p / top_logprobs 를 받지 않음
    # (Sol·Luna도 effort가 none이 아니면 제거)
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

마지막 두 줄은 Astra로 옮길 때만 해당합니다. Sol·Luna는 `none`을 받습니다.

복잡한 시스템 프롬프트는 5.6의 8섹션 계약(Role / Personality / Goal / Success criteria / Constraints / Tools / Output / Stop rules)에서 시작하고 위 행동 축만 얹습니다.

---

## Sources

- [Prompting guidance | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance) — 행동 축 5개, 권고 스니펫 원문
- [Using GPT-6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model) — What's new, 제품군 소개, 마이그레이션, effort 제약, 제품군 공통 프롬프트 출발점
- 모델 카드 [gpt-6-astra](https://developers.openai.com/api/docs/models/gpt-6-astra) · [gpt-6-sol](https://developers.openai.com/api/docs/models/gpt-6-sol) · [gpt-6-luna](https://developers.openai.com/api/docs/models/gpt-6-luna) — 스펙·가격·지원 도구·effort 값
- [Reasoning models | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning) — `none` 400, Sol·Luna 기본 effort, `configuration_update` 제약 · [Pricing](https://developers.openai.com/api/docs/pricing) — 긴 입력 요율 · [API changelog](https://developers.openai.com/api/docs/changelog)
- [Introducing GPT-6 Sol and Luna | OpenAI](https://openai.com/index/introducing-gpt-6-sol-and-luna/) — 티어 포지셔닝
- [GPT-6 Astra 시스템 카드](https://deploymentsafety.openai.com/gpt-6-astra)
- [Codex models | OpenAI](https://learn.chatgpt.com/docs/models) — 크레딧 소모율, ultra 설명, 모델별 시작 effort · [Codex pricing](https://learn.chatgpt.com/docs/pricing) · [Codex subagents](https://learn.chatgpt.com/docs/agent-configuration/subagents) · [Codex changelog](https://learn.chatgpt.com/docs/changelog) · [릴리스 노트 0.153.4](https://github.com/openai/codex/releases/tag/rust-v0.153.4)
- [Artificial Analysis](https://artificialanalysis.ai/articles/benchmarking-gpt-6-astra) [2차] · [Simon Willison (2026-09-03)](https://simonwillison.net/2026/Sep/3/gpt6-astra/) [2차] · [CodeRabbit](https://www.coderabbit.ai/blog/gpt-6-astra-code-review-evaluation) [2차, 벤더 자체 평가]
- 로컬 실측: `~/.codex/models_cache.json` (client_version 0.153.4, 0.156.1), Codex 0.156.1 모델 카탈로그의 `instructions_template`, `codex debug prompt-input`, `codex doctor`
- 조사 원문: [research-gpt6.md](../research/research-gpt6.md) · [research-opus55-gpt6-sol.md](../research/research-opus55-gpt6-sol.md) · [GPT-5.6 Prompting Guide (이전 세대 비교)](./gpt-5.6-prompt-guide.md)
