# GPT-6.1 Terra 조사와 같은 기간 모델 변경 — 공식 자료, Codex 카탈로그, Anthropic 고속 모드, dotfiles 판단 (2026-11-02, 6.1 Terra 출시 7일)

> 조사 방식: Claude와 Codex(tmux `dot-codex` 세션)가 같은 주제를 따로 조사한 뒤 메모를 주고받으며 대조했습니다. Claude는 OpenAI·Anthropic 공식 문서를 URL 끝에 `.md`를 붙인 사본으로 받아 읽었고, openai.com 발표문은 자동 수집 차단(HTTP 403)으로 열지 못했습니다. 발표문은 Codex가 원문을 열람했으며, 아래 발표문 인용은 Codex가 원문에서 확인한 문장입니다. Codex는 공식 문서, Codex 공개 소스(태그 `rust-v0.164.0`~`rust-v0.166.0`), 로컬 서버 카탈로그 캐시를 읽었습니다. 독립 조사 뒤 메모를 세 번 주고받아 쟁점을 닫았고, 합의한 문장은 메모에서 양쪽이 동의한 표현을 그대로 썼습니다. 반영 뒤 Codex가 레포 변경분 전체를 최종 점검했고, 그 지적(서버 선행 배포 단정 축소, 위임 힌트 근거 분리, 발표문 미확인 수치의 원문 대조)을 반영했습니다. 이 문서는 Claude가 통합했습니다.
> 문서 역할: 10/1 조사 이후 달라진 GPT-6 제품군 사실(6.1 Terra 출시, Codex 카탈로그 변경, 같은 기간 API 변경), Anthropic 고속 모드(fast mode) 변경, dotfiles 판단을 기록합니다. 모델별 사용 계약과 프롬프트 선택은 `reference/openai-prompt-guide/gpt-6-prompt-guide.md`와 `reference/claude-prompt-guide/` 가이드가 맡습니다.
> 시점: 2026-11-02 01:20~02:00 UTC에 수집하고 대조했습니다. 3자 평가와 사용자 후기는 이번 범위에서 수집하지 않았습니다.
> 선행 조사: `research-opus55-sol61.md`(10/1, 이 문서의 기준선), `research-opus55-gpt6-sol.md`, `research-gpt6.md`. 과거 조사는 시점 기록이라 고치지 않고, 달라진 사실은 이 문서에 적습니다.
> 이름 구분: "6.1 Terra"는 GPT-6.1 Terra(`gpt-6.1-terra`, 2026-10-26), "5.6 Terra"는 GPT-5.6 Terra입니다. "6.1 Sol"과 "6 Sol"의 구분은 선행 조사와 같습니다.

## 0. 요약

**결론**: 설정·훅·권한 규칙은 그대로 둡니다. 모델 문서만 고쳤습니다. 6.1 Terra는 별도 가이드를 만들지 않고 기존 GPT-6 문서의 표·목록에 한 열·한 항목으로 더했습니다. 같은 표를 고치면서, 지금 문서대로 따르면 틀리는 서술(EU 데이터 레지던시의 고속 모드, 6.1 Sol 초고속 모드 누락, Codex 기본 창 272K 일반화, Anthropic 고속 모드 상태)도 바로잡았습니다(5.1절).

1. **6.1 Terra는 5.6 Terra의 후속이고 API로 제공됩니다.** 공식 소개는 시각 이해, 정밀한 화면 조작, 자연스러운 글쓰기용의 빠르고 효율적인 모델입니다. 가격은 $1 / $5이고 캐시 입력은 입력의 5%인 $0.05입니다. 공식 대표 목록은 Astra·6.1 Sol·6.1 Terra·Luna 네 모델이 됐습니다.
2. **API 계약에서 `none` 지원과 Chat Completions 도구 호출이 처음으로 갈립니다.** 6.1 Terra는 `none`~`max`를 받지만, Chat Completions에서 도구를 부를 수 없습니다. 6 Sol·Luna의 "`none`이면 Chat Completions 함수 호출 가능" 예외를 Terra에 적용하면 도구 요청이 깨집니다.
3. **Codex에서는 번들 카탈로그와 서버 카탈로그 값이 다릅니다.** 서버 캐시에서 Terra는 우선순위 3, 기본 추론 수준 `low`, 기본 창 500K이고, 0.166.0 번들에서는 우선순위 7입니다. 6.1 Sol의 기본 창도 서버 캐시와 공식 문서에서는 500K이지만 0.166.0 번들에는 272K가 남아 있습니다. 그래서 레포의 "Codex 기본 창 272K는 과금 티어에 맞춘 값" 추정을 지웠습니다.
4. **6.1 Terra의 Codex 기본 지시문은 Astra와 글자 단위로 같습니다.** 지시문이 같다는 뜻일 뿐 행동이 같다는 뜻은 아니므로, Astra에서 나온 행동 지침은 Terra에서도 측정한 뒤 채택합니다.
5. **같은 기간 OpenAI 변경 가운데 세 건이 레포 서술에 닿았습니다.** EU 데이터 레지던시에서 고속 모드를 쓸 수 있는 모델이 6.1 Sol·6.1 Terra·Luna로 바뀌었고, 6.1 Sol 초고속 모드(10/8)와 12시간 프롬프트 캐싱(10/20)이 나왔습니다.
6. **Anthropic 고속 모드는 Opus 5.5에서 정식 제공(10/15)되고, Opus 4.8에서는 폐기 예고(10/30, 11/30 제거)됐습니다.** Opus 4.8 모델 자체는 Active이며 은퇴가 아닙니다.

## 1. GPT-6.1 Terra

### 1.1 출시와 위치

| 항목 | 내용 | 근거 |
|---|---|---|
| 출시 | 2026-10-26 | API 변경 기록 Oct 26: "Released GPT-6.1 Terra, a fast, efficient model for visual reasoning, precise computer use, and clear, natural writing." |
| 제공 경로 | API, ChatGPT Work, Codex. Chat에서는 제공하지 않습니다 | 모델 페이지의 모델 ID와 엔드포인트. Codex 가격 문서 "It isn't available in Chat." |
| 모델 ID | `gpt-6.1-terra` 하나. 날짜 스냅샷 없음 | 모델 페이지 "Default snapshot: `gpt-6.1-terra`" |
| 제품군 위치 | Using GPT-6 대표 목록이 Astra("Highest intelligence"), 6.1 Sol("Balanced speed, cost, and intelligence"), 6.1 Terra("Fast and efficient"), Luna("Fastest and most cost-effective") 네 개가 됐습니다. 6 Sol은 이 목록에 없습니다 | [Using GPT-6](https://developers.openai.com/api/docs/guides/latest-model) |
| 5.6 Terra와의 관계 | 공식 가이드가 5.6 Terra에서 옮기는 절차를 따로 둡니다: "When migrating from GPT-5.6 Terra, compare both models on representative images and workflows using the same reasoning effort. If your application calls tools through Chat Completions, migrate those requests to the Responses API." 5.6 Terra 폐기 공지는 없고 가격표에 남아 있습니다 | 같은 가이드, Deprecations, Pricing |
| 용도 | "match product photos to catalog entries, compare technical drawings, act on application screens, or draft and revise text" | 같은 가이드의 GPT-6.1 Terra 절 |

5.6 Terra 대비 표준 단가 인하율은 토큰 종류마다 다릅니다. 입력은 $2→$1로 50%, 캐시 입력은 $0.20→$0.05로 75%, 출력은 $12→$5로 약 58.3% 낮습니다(가격표에서 각각 계산). 6.1 Sol과 비교하면 입력·출력이 절반이고 캐시 입력 비율(5%)은 같습니다.

### 1.2 API 계약

| 항목 | 값 | 원문 |
|---|---|---|
| 컨텍스트 / 최대 입력 / 최대 출력 | 1,050,000 / 922,000 / 128,000 | 모델 페이지 Model details |
| 지식 컷오프 | 2026-06-01 (Astra·6.1 Sol은 2026-04-30) | "Jun 01, 2026 knowledge cutoff" |
| 모달리티 | 텍스트·이미지 입력, 텍스트 출력 | 같은 페이지 |
| 표준 가격 ($/1M, 입력 272K 이하) | 입력 $1, 캐시 입력 $0.05, 30분 캐시 쓰기 $1.25, 12시간 캐시 쓰기 $2.50, 출력 $5 | "Standard cache writes cost $1.25 per million tokens for 30-minute retention and $2.50 for 12-hour retention, before long-context adjustments." |
| 입력 272K 초과 | 요청 전체가 입력 $2, 캐시 입력 $0.10, 30분 캐시 쓰기 $2.50, 출력 $7.50 | "Prompts with more than 272K input tokens are priced at 2x input and cache rates and 1.5x output for the full request." |
| 처리 방식 | Batch·Flex 50%, Fast 2배, 지역 처리 10% 가산. 초고속 모드는 가격표에 없음 | "Batch and Flex prices are 50% lower than Standard." "Fast mode prices are 2x Standard." |
| `reasoning.effort` | `none`, `low`, `medium`(기본), `high`, `xhigh`, `max` | 모델 페이지. 가이드 "Start with `medium` and increase it if the improvement in quality is worth the added time and tokens." |
| 도구 호출 | Responses 필요 | "Tool calling requires the Responses API." 가이드 "GPT-6 Astra, GPT-6.1 Sol, and GPT-6.1 Terra support Chat Completions, but tool calling requires Responses." |
| 샘플링 파라미터 | effort가 `none`이 아니면 `temperature`·`top_p`·`top_logprobs` 제거. Terra 전용 문장은 없고 제품군 공통 규칙이 적용됩니다 | "When reasoning effort is not `none`, remove `temperature`, `top_p`, and `top_logprobs`." |
| 엔드포인트 | Responses·Chat Completions·Batch. Realtime·Assistants·파인튜닝·임베딩 미지원 | 모델 페이지 Endpoints |
| Responses 도구 | web_search, file_search, image_generation, code_interpreter, hosted_shell, apply_patch, skills, computer_use, mcp, tool_search (다른 GPT-6 모델과 같음) | 모델 페이지 |
| EU 데이터 레지던시 | 고속 모드 지원 | "Fast mode supports EU data residency for GPT-6.1 Sol, GPT-6.1 Terra, and GPT-6 Luna, but not GPT-6 Astra or GPT-6 Sol." |
| 레이트 리밋 | Build 5,000 RPM·1M TPM, Launch 10,000·4M, Grow 15,000·40M | 모델 페이지 (사용 등급은 10/6에 세 단계로 재편) |

모델별 조건을 나누면 다음과 같습니다.

| 조건 | Astra·6.1 Sol | 6.1 Terra | 6 Sol·Luna |
|---|---|---|---|
| API `none` | 미지원 | 지원 | 지원 |
| API 기본 effort | `medium` | `medium` | `medium` |
| Chat Completions 함수 호출 | 불가 | 불가 | `reasoning_effort: "none"`일 때만 |
| 추론과 도구를 함께 쓸 때 | Responses | Responses | Responses |

### 1.3 OpenAI 발표 수치

아래는 OpenAI의 자체 평가이며 독립 재측정이 아닙니다. 스킬 본문에는 넣지 않고 이 기록에만 둡니다. 출처는 [Introducing GPT-6.1 Terra](https://openai.com/index/introducing-gpt-6-1-terra/)입니다.

- 도입부는 "A significant step up from GPT‑5.6 Terra"입니다.
- Agents' Last Exam(`medium`)에서 5.6 Terra보다 15%p 높고 비용은 약 1/3입니다. 같은 문단(`From visual understanding to action` 절)에 "performs on par with GPT-6 Astra at only one-tenth its price per token"이 있습니다. 이 비교는 이 평가 문단에 한정된 것이므로 "Astra와 전반적인 성능이 같고 모든 작업 비용이 1/10"로 요약하지 않습니다.
- 같은 절에서 `max` 비교가 이어지는 문단은 Astra·6.1 Sol보다 작업을 3배 넘게 빠르게 끝낸다고 적습니다. "평균"이라는 표현은 없으므로, 모든 작업의 평균 속도나 토큰 생성 속도로 일반화하지 않습니다.
- Terminal-Bench 4.0(`max`)에서 6.1 Terra 50.3%, 5.6 Terra 21.5%입니다. 21.5%는 이전에 발표한 5.6 Terra 점수를 가져온 비교입니다.
- `A significant step up on factuality and coding` 절은 내부 오류 유도 프롬프트 평가(`low`)에서 오답률이 5.6 Terra 53.6%, 6.1 Terra 16.7%라고 적습니다(36.9%p 차이). 같은 절은 가장 복잡한 코딩에는 6.1 Sol과 Astra가 더 적합하다고 적습니다. 그래서 범용 코딩 예제나 기본 선택을 Terra로 바꿀 근거로 쓰지 않습니다.
- `Safety and alignment` 절은 OpenAI 대비 체계(Preparedness Framework)상 사이버 보안 Critical 임계에 도달했다고 적습니다. 능력 분류이며 보안 성능 점수가 아닙니다.

### 1.4 문서 상태

- Using GPT-6에 6.1 Terra 절이 생겼습니다. 이 절은 용도, effort, 5.6 Terra 이전 절차만 다루고, Terra 전용 프롬프팅 지침은 없습니다. 프롬프팅 절의 도입 문장("Use the following prompts as a starting point across the GPT-6 model family. They address behavior observed with GPT-6 Astra; evaluate them with your chosen model and workload.")은 그대로입니다.
- 공식 마이그레이션 체크리스트의 모델 선택지가 "Set `model` to `gpt-6-astra`, `gpt-6.1-sol`, `gpt-6.1-terra`, or `gpt-6-luna`"로 바뀌었고, `none` 문장도 "GPT-6.1 Terra, GPT-6 Sol, and GPT-6 Luna support `none`."이 됐습니다.

## 2. Codex 적용

### 2.1 카탈로그: 번들과 서버 캐시

`~/.codex/models_cache.json`은 Codex가 서버에서 받아 덮어쓰는 캐시입니다. 이번 조사 중에도 캐시가 갱신돼 관찰 시점에 따라 `fetched_at`과 `client_version`이 달랐으므로, 관찰마다 시각을 붙이고 섞지 않습니다.

| 관찰 | `fetched_at` (UTC) | `client_version` | 읽은 쪽 |
|---|---|---|---|
| 1 | 2026-11-02T01:25:23Z | 0.166.0 | Claude |
| 2 | 2026-11-02T01:36:19Z | 0.164.0 | Codex |
| 3 | 2026-11-02T01:38:54Z | 0.166.0 | Codex |
| 4 | 2026-11-02T01:45:20Z | 0.164.0 | Codex (`model_messages` 대조) |
| 5 | 2026-11-02T01:58:51Z | 0.164.0 | Claude (반영 중 재확인) |

다섯 관찰에서 아래 값은 같았습니다. 같은 캐시를 0.164.0과 0.166.0 클라이언트가 번갈아 갱신한 것으로 보입니다(추정). `client_version: 0.164.0` 캐시에도 Terra가 있고 0.164.0 번들에는 없으므로, 구형 클라이언트가 원격 카탈로그로 Terra를 받는 것은 확인했습니다. 다만 관찰일이 0.165.0·0.166.0 출시 뒤라, 서버 배포 시작일과 번들 등재보다 먼저 제공됐는지는 확인하지 못했습니다. Codex가 최종 점검 중 다시 읽은 캐시(`fetched_at` 2026-11-02T02:07:52Z, `client_version` 0.164.0)도 값이 같았습니다.

| 모델 | 서버 캐시 우선순위 | 캐시 기본 effort | 캐시 기본 창 | 0.166.0 번들 우선순위 | 번들 기본 effort | 번들 기본 창 |
|---|---:|---|---:|---:|---|---:|
| 6.1 Sol | 1 | `low` | 500,000 | 1 | `low` | 272,000 |
| Astra | 2 | `medium` | 272,000 | 2 | `low` | 272,000 |
| 6.1 Terra | 3 | `low` | 500,000 | 7 | `low` | 500,000 |
| 6 Sol | 4 | `medium` | 272,000 | 3 | `medium` | 272,000 |
| Luna | 5 | `medium` | 272,000 | 4 | `medium` | 272,000 |

- 다섯 모델 모두 최대 창 872,000, 유효 비율 95%입니다. API 명세의 1,050,000과 다른 카탈로그 값입니다.
- 6.1 Terra의 선택기 값은 `low`~`max`와 `ultra`이고 `none`은 없습니다. `multi_agent_reasoning_effort`가 `xhigh`라서, `ultra`를 고르면 Astra·6.1 Sol처럼 `xhigh`로 요청합니다([`resolve_reasoning_effort`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/protocol/src/openai_models/reasoning_effort.rs#L9)). 위임 힌트는 이 변환과 별개로 [`effective_multi_agent_mode`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/core/src/session/multi_agents.rs#L77)가 고릅니다. 다중 에이전트 `v2`이고 설정이나 카탈로그의 힌트 재정의가 없을 때, 고른 추론 수준이 `ultra`이면 적극적 위임 문구를 넣습니다. Terra 캐시는 `multi_agent_version: v2`, 카탈로그 힌트 `null`이라 별도 설정이 없는 기본 경로에서는 힌트가 붙습니다. 소스 대조 결과이며 요청 캡처나 Terra 렌더링은 하지 않았습니다.
- 그 밖의 Terra 값: 기본 verbosity `low`, 도구 모드 `code_mode_only`, `supported_in_api: true`. 고속 등급 설명은 Terra만 "1.5x speed"이고 Astra·6.1 Sol은 "2x speed, increased usage"입니다. 이 문구는 카탈로그 설명이며 측정한 속도나 과금 배율이 아닙니다.
- 출시와 번들 등재는 다릅니다. Codex 모델 문서는 "GPT-6.1 Terra requires Codex CLI 0.159.0 or later."라고 적고, 번들 카탈로그에는 [0.165.0](https://github.com/openai/codex/releases/tag/rust-v0.165.0)(10/27, "Added GPT-6.1 Terra to the model catalogs.", PR #57337)과 [0.166.0](https://github.com/openai/codex/releases/tag/rust-v0.166.0)(10/29, "Added GPT-6.1 Terra to the bundled, Vertex AI, and Amazon Bedrock model catalogs.", PR #57293)에서 들어갔습니다. "0.166.0부터만 Terra 사용 가능"으로 쓰면 틀립니다.
- Codex 모델 문서에서 Terra의 자리는 "GPT-6.1 Terra, for everyday writing and visual work. Choose Terra for clear communication, interpreting images and screens, and completing tasks across supported apps."입니다. 시작 effort 권고는 6.1 Sol·Luna·Astra에만 있고 Terra에는 없습니다.

### 2.2 6.1 Sol의 500K

6.1 Sol 모델 페이지는 "GPT-6.1 Sol uses a default context window of 500K tokens in Codex and ChatGPT Work. Usage drawn from your subscription has no long-context surcharge."라고 적고, Codex 가격 문서도 "GPT-6.1 Sol usage drawn from your subscription has no long-context surcharge in Codex or ChatGPT Work."라고 적습니다.

| 쟁점 | 판정 |
|---|---|
| 개인 캐시에서만 보인 값인가 | 아닙니다. 공식 문서에 있습니다 |
| CLI 번들 변경인가 | 아닙니다. 0.164.0·0.165.0·0.166.0 번들 모두 6.1 Sol은 272K입니다 |
| 서버 카탈로그 변경인가 | 번들과 캐시의 차이, 공식 문서, 원격 값을 적용하는 코드([`manager.rs`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/models-manager/src/manager.rs#L275), "applying remote overrides and config adjustments")를 종합하면 서버 갱신으로 설명됩니다. 배포 기록은 미확인입니다 |
| 적용 시작일 | 미확인. 10/1 캐시는 272K였고, 공개 변경 기록에서 직접 공지를 찾지 못했습니다 |
| Terra의 500K | 카탈로그 값만 확인했고, 설명하는 공식 문장은 찾지 못했습니다 |
| 구독 사용분의 긴 입력 할증 | 6.1 Sol에만 "없음"이 명시돼 있습니다. Terra나 Astra로 넓힐 근거는 미확인입니다 |
| API 키 사용 | API 요금표의 입력 272K 초과 할증을 따릅니다 |

레포는 9/7부터 "Codex 기본 창 272K는 롱컨텍스트 과금 임계와 같은 값이라 과금 티어에 맞춘 것으로 읽힌다"는 추정과 "`auto_compact_token_limit`을 200K 근처로" 하라는 2차 조언을 실어 왔습니다. 확정 근거가 없던 추정이고, 6.1 Sol 500K와 구독 무할증 설명이 나온 지금은 일반 규칙으로 둘 수 없습니다. Astra·6 Sol·Luna가 지금 272K라는 사실과, 개발자가 과금 때문에 그 값을 골랐다는 설계 의도는 별개입니다. 그래서 범위를 좁혀 남기지도 않고 가이드에서 지웠습니다. 당시 추정은 `research-gpt6.md`에 시점 기록으로 남아 있습니다.

### 2.3 크레딧·속도·사용량

| 표준 속도, 1M당 크레딧 | 입력 | 캐시 입력 | 출력 |
|---|---:|---:|---:|
| 6.1 Terra | 25 | 1.25 | 125 |
| 6.1 Sol | 50 | 2.5 | 250 |
| Astra | 250 | 25 | 1,250 |
| Luna | 2.5 | 0.25 | 12.5 |
| 5.6 Terra | 50 | 5 | 300 |

- 캐시 쓰기는 따로 차감하지 않습니다("Codex credit billing has no separate cache-write charge."). 크레딧 단가만으로 구독 포함 작업 수를 계산하지 말라는 설명이 있으므로 "Terra는 구독에서 정확히 두 배 작업"으로 바꾸지 않습니다.
- 속도 모드 배율(구독 포함 / 구매 크레딧·엔터프라이즈 종량제): Fast 2.5배 / 2배, Astra Ultrafast 8배 / 6배, 6.1 Sol Ultrafast 8배 / 6배. 6.1 Sol Ultrafast는 10/1 조사 때 "coming later"였습니다.
- Plus·Standard Business의 5시간 로컬 메시지 추정치는 6.1 Terra 35-285, 6.1 Sol 15-160, 6 Sol 15-150, Astra 5-45, Luna 350-3,000입니다. 문서가 "These estimates are not fixed message limits"라고 적으므로 고정 한도로 옮기지 않습니다.
- 제공 범위: "GPT-6.1 Terra is available in Work and Codex on Plus, Pro, Business, Enterprise, and Edu plans. It does not support UAE inference residency. It isn't available in Chat." 엔터프라이즈는 워크스페이스 가용성과 관리자 설정에 달려 있습니다.

### 2.4 기본 지시문

관찰 4에서 6.1 Terra의 `model_messages` 10개 항목은 `instructions_template`을 포함해 Astra와 키·값 전체가 같았습니다. 6.1 Sol과 Astra는 `instructions_template`만 다르며, 그 차이는 10/1 조사에서 적은 두 곳("or what something is not" 문구, 사과·자책 문단)과 같습니다. 그래서 가이드의 Codex 템플릿 표에서 Astra 열을 6.1 Terra에도 적용했습니다.

### 2.5 레포 설정과 컨텍스트 계산

레포 `.codex/config.toml`은 모델·추론 수준을 비워 Codex 기본값을 따르고, `model_context_window = 800000`, `model_auto_compact_token_limit = 400000`을 지정합니다(10/8 커밋 f5b41b3부터, 당시 근거는 기록되지 않음). Codex 0.166.0 소스로 계산하면 다음과 같습니다.

| 층위 | 계산 | 값 | 소스 |
|---|---|---:|---|
| 설정 적용 후 명목 창 | `min(800000, 872000)` | 800,000 | [`with_config_overrides`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/models-manager/src/model_info.rs#L19) |
| 여유분을 뺀 사용 가능 창 | `800000 × 95 / 100` | 760,000 | [`usable_context_window`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/protocol/src/openai_models.rs#L527) |
| 자동 압축 기준 | `min(400000, 800000 × 9 / 10)` | 400,000 | [`auto_compact_token_limit`](https://github.com/openai/codex/blob/rust-v0.166.0/codex-rs/protocol/src/openai_models.rs#L534) |

자동 압축의 90% 상한에는 사용 가능 창 760K가 아니라 명목 창 800K가 들어갑니다. 가이드에는 합의한 문장을 그대로 실었습니다.

> 이 저장소는 모델·추론 수준은 고정하지 않지만, 컨텍스트 창은 800,000, 자동 압축 기준은 400,000으로 지정합니다. 이 설정이 별도 재정의 없이 적용되고 카탈로그 최대 창이 872,000·유효 비율이 95%인 GPT-6 모델에서는, Codex 0.166.0 소스 기준으로 명목 창 800,000, 사용 가능 창 760,000, 자동 압축 기준 400,000이 됩니다. 이는 설정과 소스에서 계산한 값이며 현재 세션의 실효 설정을 측정한 결과는 아닙니다.

400K는 자동 압축 판단에 쓰는 기준이지 항상 정확히 400K에서 압축한다는 실행 보장이 아니고, 요금 경계도 아닙니다.

## 3. 같은 기간 OpenAI의 다른 변경 (10/1 이후)

| 날짜 | 변경 | 레포 영향 | 판단 |
|---|---|---|---|
| 10/6 | 사용 등급을 다섯 단계에서 Build·Launch·Grow 세 단계로 재편 | 스킬에 등급 서술 없음 | 반영하지 않음 |
| 10/6·10/22 | Decisions API(Luna, 베타 후 정식) | 없음 | 범위 밖 |
| 10/8 | 6.1 Sol 초고속 모드(`service_tier: "ultrafast"`, 표준의 6배 $12 / $0.60 / $15 / $60, 미국·EU 레지던시와 글로벌 처리) | 표의 6.1 Sol 칸에 빠져 있었음 | 반영 |
| 10/20 | 12시간 프롬프트 캐싱(`prompt_cache_options.ttl: "12h"`, Responses API). "These are total write rates, not surcharges on top of ordinary input." 30분은 1.25배, 12시간은 2.5배이며 캐시 읽기 단가는 같음. 최소 보존 기간이지 삭제 시한이 아님 | 캐싱 서술이 1.25배만 적음 | `openai-responses-api.md`와 `common-patterns.md`의 캐시 쓰기 서술에 반영 |
| 10/21 | 프로젝트별 서비스 티어 제한 | 없음 | 범위 밖 |
| 10/30 | GPT-6 Rosalind(생명과학, 신뢰 접근 프로그램) | 없음 | 범위 밖. 제품군 서술에 넣지 않음 |
| 날짜 미확인 | EU 데이터 레지던시에서 고속 모드 가능 모델이 6.1 Sol·6.1 Terra·Luna로 바뀜. 10/1 문구는 "Fast mode is not available with EU data residency for GPT-6 Astra, GPT-6 Sol, or GPT-6 Luna."였고 6.1 Sol 모델 페이지도 불가였음 | 레포의 EU 레지던시 서술 전부 | 반영 |

## 4. Anthropic 고속 모드

| 모델 | 2026-11-02 상태 | 근거 |
|---|---|---|
| Opus 5.5 | 10/15 정식 제공. 베타 헤더 불필요(보내도 동작). Messages API는 Claude API·Claude Models on Google Cloud(Anthropic managed, 10/22)·Microsoft Foundry(Azure 호스팅, 10/15), Managed Agents는 Claude API만. $8 / $40 | 릴리스 노트 Oct 15: "Fast mode is out of research preview for Claude Opus 5.5, and you no longer need to request access. Requests to Claude Opus 5.5 no longer require the `fast-mode-2026-02-01` beta header, and requests that still send it keep working." |
| Opus 5 | 연구 프리뷰 유지, 베타 헤더 필요, Claude API만. 접근은 계정 담당자나 대기자 명단. $10 / $50 | 고속 모드 문서 Availability |
| Opus 4.8 | 10/30 폐기 예고, 11/30 제거. 제거 뒤 `speed: "fast"` 요청은 오류이며 표준 속도로 자동 전환하지 않음. 그 전까지는 연구 프리뷰 | 릴리스 노트 Oct 30: "We've deprecated fast mode for Claude Opus 4.8, with removal on November 30, 2026. After removal, requests to `claude-opus-4-8` with `speed: "fast"` will return an error." |
| Fable 5.1 | 지원 목록에 없음 | 고속 모드 문서 `supportedModels` |

- 고속 모드는 Batch API·Priority Tier와 함께 쓸 수 없고, 프롬프트 캐싱과 데이터 레지던시 배율은 고속 모드 단가 위에 곱해집니다.
- [모델 폐기 문서](https://platform.claude.com/docs/en/about-claude/model-deprecations)는 `claude-opus-4-8`을 여전히 Active로 표시하고 2027-05-28 이전에는 은퇴하지 않는다고 적습니다. 11/30은 고속 모드 제거일입니다. 그래서 Opus 4.8 자료는 보관소로 옮기지 않습니다.
- 레포는 v2.59 조사 범위 밖이던 10/15·10/22 변경을 놓쳐, Opus 5.5 고속 모드를 "연구 프리뷰, Claude API 전용, 베타 헤더 필요"로 적고 있었습니다.

## 5. dotfiles 판단

### 5.1 반영한 변경

| 파일 | 변경 |
|---|---|
| `writing-prompts/SKILL.md` | 라우팅에 `gpt-6.1-terra`, effort 범위에서 Terra를 `none` 지원 쪽에 추가 |
| `writing-prompts/references/gpt6-patterns.md` | 제목·도입·모델 선택·§0 표(6.1 Terra 열)·§4 `ultra`·§6 effort 표·§8 마이그레이션. "5.6 Terra에 대응하는 티어는 없음" 삭제, EU 레지던시 항목 교체 |
| `writing-prompts/references/` `reasoning-params.md`·`platform-differences.md`·`prompt-trends-2026.md`·`sources.md` | `none` 지원 모델에 Terra 추가, Terra 모델 카드·발표문 링크 |
| `llm-api-guide/SKILL.md` | Reasoning 칸과 참고 자료 |
| `llm-api-guide/references/openai-responses-api.md` | GPT-6 절 표(6.1 Terra 열, 6.1 Sol 초고속 모드, 30분 캐시 쓰기 표기), `none`·엔드포인트 인용, 12시간 캐싱 문장, Codex 문단(합의 문장), 마이그레이션 체크리스트 |
| `llm-api-guide/references/common-patterns.md` | Terra 캐시 입력 5%, 12시간 캐시 쓰기 2.5배 |
| `llm-api-guide/references/anthropic-messages-api.md` | Opus 5.5 고속 모드 정식 제공, Fable 5.1 미지원 절의 지원 모델 목록 |
| `reference/openai-prompt-guide/gpt-6-prompt-guide.md` | §0~§2·§3·§5·§6·§9·§10·출처에 Terra 반영, EU 레지던시·초고속 모드 갱신, 과금 티어 추정과 200K 조언 삭제, 레포 설정의 컨텍스트 계산 추가 |
| `reference/claude-prompt-guide/claude-opus-5-5-prompt-guide.md`·`claude-fable-5-1-prompt-guide.md` | 고속 모드 상태 |
| `reference/archive/README.md`, `docs/DECISIONS.md` | 현행 GPT 목록과 조사 목록에 6.1 Terra |

### 5.2 유지 판단과 도입하지 않은 안

- **별도 Terra 가이드를 만들지 않음**: 공식 가이드도 Terra를 GPT-6 가이드 안의 절로 다루고, 전용 프롬프팅 지침이 없습니다.
- **Terra 예제를 새로 넣지 않음, 기존 예제의 모델 ID 유지**: 모델 표와 계약 설명으로 `none` 지원과 Responses 도구 경로가 드러나고, 새 모델 출시만으로 예제 선택 목적을 바꾸지 않습니다.
- **Astra 행동 지침을 Terra에 자동 승계하지 않음**: 공식 문서가 Astra 관찰에서 나온 출발점으로 제시하고 모델별 평가를 요구합니다. 기본 지시문이 같아도 같습니다.
- **Opus 4.8 가이드에 새 절을 만들지 않음**: 이 가이드에는 고속 모드 사용을 권하는 문장이 없습니다. 제거 일정은 이 기록과 고속 모드를 다루는 문서에 남깁니다.
- **설정 변경 없음**: 모델·추론 수준 기본값 추종과 `.codex/config.toml`의 800K·400K는 그대로 둡니다. 이번 조사는 그 설정을 문서화했을 뿐 바꿀 근거를 다루지 않았습니다.
- **발표문 벤치마크는 스킬 본문에 넣지 않음**: 공급자 자체 평가이고 비교 조건이 붙어 있어, 이 기록에만 둡니다.

### 5.3 협의로 바뀐 판단

- Claude의 첫 제안은 "과금 티어" 추정을 Astra·6 Sol·Luna에 한정해 남기는 것이었습니다. Codex가 범위를 좁혀도 설계 의도의 근거가 생기지 않는다고 지적했고, 추정과 200K 조언을 모두 지우는 것으로 합의했습니다.
- 레포 설정 설명은 "GPT-6 모델이 800K 창·400K 압축으로 돈다"는 단정 대신, 재정의 없이 적용될 때의 계산값으로 쓰고 명목 창(800K)과 사용 가능 창(760K)을 나누기로 했습니다.
- 12시간 캐싱은 "입력 요금에 추가로 2.5배"나 "12시간 뒤 삭제"로 읽히지 않게 총단가와 최소 보존 기간으로 적었습니다.

## 6. 미확인·상충

1. 6.1 Sol 500K의 서버 적용 시작일, 배포 범위, 플랜별 실제 창 차이.
2. 6.1 Terra 500K의 공식 설명, 그리고 Terra·Astra 구독 사용분의 긴 입력 할증 여부.
3. Terra가 `none`일 때 개별 샘플링 파라미터 조합을 받는지. 공식 문서는 조건부 제거 규칙만 적고, API 실호출은 하지 않았습니다.
4. EU 데이터 레지던시 규칙이 바뀐 날짜.
5. 실제 작업에서 Terra의 성능·지연·토큰 소비와 Codex `ultra` 위임 빈도.

Claude 1차 조사에서 검색 요약에만 있던 발표문 수치 세 건(오답률, 사이버 보안 Critical, "3배 빠름")은 Codex가 최종 점검에서 원문과 대조해 1.3절로 옮겼습니다. 2차 출처가 쓴 "평균 3배 빠름"은 원문 표현과 달라 고쳤습니다.

## 7. 출처

- OpenAI API: [GPT-6.1 Terra 모델 페이지](https://developers.openai.com/api/docs/models/gpt-6.1-terra) · [GPT-6.1 Sol 모델 페이지](https://developers.openai.com/api/docs/models/gpt-6.1-sol) · [Using GPT-6](https://developers.openai.com/api/docs/guides/latest-model) · [Pricing](https://developers.openai.com/api/docs/pricing) · [Prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching#cache-lifetime) · [Fast mode](https://developers.openai.com/api/docs/guides/fast-mode) · [Ultrafast mode](https://developers.openai.com/api/docs/guides/ultrafast-mode) · [API changelog](https://developers.openai.com/api/docs/changelog) · [Deprecations](https://developers.openai.com/api/docs/deprecations)
- OpenAI 발표: [Introducing GPT-6.1 Terra](https://openai.com/index/introducing-gpt-6-1-terra/) (Codex 열람)
- Codex: [Codex models](https://learn.chatgpt.com/docs/models) · [Codex pricing](https://learn.chatgpt.com/docs/pricing) · 릴리스 [0.165.0](https://github.com/openai/codex/releases/tag/rust-v0.165.0) · [0.166.0](https://github.com/openai/codex/releases/tag/rust-v0.166.0) · PR [#57293](https://github.com/openai/codex/pull/57293) · [#57337](https://github.com/openai/codex/pull/57337) · 번들 카탈로그 [0.164.0](https://raw.githubusercontent.com/openai/codex/rust-v0.164.0/codex-rs/models-manager/models.json) · [0.165.0](https://raw.githubusercontent.com/openai/codex/rust-v0.165.0/codex-rs/models-manager/models.json) · [0.166.0](https://raw.githubusercontent.com/openai/codex/rust-v0.166.0/codex-rs/models-manager/models.json)
- Anthropic: [Fast mode](https://platform.claude.com/docs/en/build-with-claude/fast-mode) · [Release notes](https://platform.claude.com/docs/en/release-notes/overview) · [Model deprecations](https://platform.claude.com/docs/en/about-claude/model-deprecations)
- 로컬 실측: `~/.codex/models_cache.json`(2.1절 관찰 1~5), `codex debug models --bundled`(0.166.0), `.codex/config.toml`
