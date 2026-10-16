# Gemini 4 Argon Prompting Guide

> **대상 모델**: `gemini-4-argon` (Stable, 2026-10-13 GA). Cloud 전용 변형 `gemini-4-argon-cyber-permissive`는 [§2](#2-모델-개요)에서 구분만 합니다.
>
> **출처 (공식 1차)**:
> - [What's new in Gemini 4 Argon (Interactions)](https://ai.google.dev/gemini-api/docs/latest-model) · [GenerateContent판](https://ai.google.dev/gemini-api/docs/generate-content/latest-model)
> - [Gemini 4 Argon 모델 페이지](https://ai.google.dev/gemini-api/docs/models/gemini-4-argon)
> - [Gemini 4 Argon: Developer Guide | Google AI Studio](https://aistudio.google.com/learn/gemini-4-argon-developer-guide) (2026-10-13, "5 practical tips")
> - [Thinking](https://ai.google.dev/gemini-api/docs/thinking) · [Long decode](https://ai.google.dev/gemini-api/docs/long-decode) · [Long decode (GenerateContent)](https://ai.google.dev/gemini-api/docs/generate-content/long-decode) · [Pricing](https://ai.google.dev/gemini-api/docs/pricing) · [Changelog](https://ai.google.dev/gemini-api/docs/changelog)
> - [Media resolution](https://ai.google.dev/gemini-api/docs/media-resolution) · [Structured outputs (GenerateContent)](https://ai.google.dev/gemini-api/docs/generate-content/structured-output) · [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies)
> - [Developer's guide to Gemini 4 Argon | Google Cloud](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon) · [Cloud 이행 문서](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/migrate)
> - [Google 블로그 출시 글](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-argon/) · [Antigravity 블로그](https://antigravity.google/blog/gemini-4-argon-in-google-antigravity) · [Antigravity 모델 표](https://antigravity.google/docs/models/)
>
> **날짜**: 2026-10-16 (모든 공식 URL을 이날 원문으로 확인. 조사 기록은 [research-gemini4-argon.md](../research/research-gemini4-argon.md))
> **자매 가이드**: [Gemini 3.x](./gemini-3-prompt-guide.md) · [Gemma 4](./gemma-4-prompt-guide.md)

Gemini 4 계열의 첫 모델인 Argon용 가이드입니다. Google은 Argon 전용 운용 권고와 API 계약을 따로 냈고, 그 상당 부분이 3.x와 다릅니다. **적용 순서**: Argon 전용 권고와, 공식 문서가 Gemini 4에도 적용한다고 명시한 공통 계약을 우선합니다. 나머지는 `writing-prompts` 스킬의 범용 원칙을 적용합니다. Gemini 3 전용 처방은 자동 적용하지 않으며, 참고할 때에는 적용 근거와 검증 필요 여부를 구분합니다.

## 목차
1. [가장 먼저 알아야 할 것](#1-가장-먼저-알아야-할-것)
2. [모델 개요](#2-모델-개요)
3. [프롬프팅 권고](#3-프롬프팅-권고)
4. [사고 수준 (`thinking_level`)](#4-사고-수준-thinking_level)
5. [출력 한도와 장문 출력](#5-출력-한도와-장문-출력)
6. [3.x와 달라진 API 계약](#6-3x와-달라진-api-계약)
7. [3.x와 공유하는 계약](#7-3x와-공유하는-계약)
8. [agy(Antigravity CLI)에서 쓸 때](#8-agyantigravity-cli에서-쓸-때)
9. [마이그레이션 체크리스트](#9-마이그레이션-체크리스트)
10. [미확인 항목](#10-미확인-항목)
11. [요약](#11-요약)

---

## 1. 가장 먼저 알아야 할 것

- **창은 입력·사고·출력이 함께 쓰는 1,048,576 토큰입니다.** 출력 1M이 입력 1M에 더해지는 것이 아닙니다("Input, thinking, and output share one window of 1,048,576 tokens").
- **64K를 넘는 출력은 장문 출력(long decode)을 따로 켜야 합니다.** 전체 생성, SDK 호출, 개별 HTTP 요청의 한도가 각각 다르므로 API 방식별로 확인합니다 → [§5](#5-출력-한도와-장문-출력).
- **사고 수준은 `low`·`medium`(기본)·`high` 셋뿐입니다.** `minimal`은 없습니다.
- **명시 캐싱이 없습니다.** `cachedContents`·`caches.create`·`cached_content`를 쓰는 코드는 고쳐야 합니다. 암시 캐싱이 기본으로 켜져 있습니다.
- **Gemini API와 Cloud의 계약이 다릅니다.** `thinking_budget` 처리, 암시 캐싱 최소 길이, 장문 출력 방식이 서비스마다 달라서, 문장을 쓸 때 서비스와 API 방식(Interactions·GenerateContent)을 밝힙니다.
- **agy의 모델 ID를 API에 쓰지 않습니다.** agy 목록의 `gemini-4-argon-low`·`-medium`·`-high`는 CLI의 노력 수준 변형이고, API 모델 ID는 `gemini-4-argon` 하나입니다.

## 2. 모델 개요

| 항목 | 내용 |
|------|------|
| 모델 ID | `gemini-4-argon` (Stable). Cloud에는 Fairwind 승인 사이버 보안 작업용 `gemini-4-argon-cyber-permissive`가 따로 있고 기본 사고 수준이 `HIGH`입니다. 일반 모델과 섞어 축약하지 않습니다 |
| 출시 | 2026-09-30 Fairwind 파트너 선공개, 2026-10-13 일반 공개(GA) |
| 공식 포지션 | "Our flagship reasoning model". 복잡한 소프트웨어 엔지니어링, 수학·과학 문제, 자율 다단계 에이전트, 1M 장문 출력 |
| 입력 / 출력 | 텍스트·이미지·영상·음성·PDF / 텍스트 |
| 창 | 통합 1,048,576 (입력 + 사고 + 출력) |
| 출력 한도 | Interactions는 `background=False`에서 최대 65,536이며 넘기면 400. GenerateContent는 직접 비스트리밍 REST의 요청당 한도가 32,768(3.x의 65,536에서 줄어듦), 스트리밍은 65,536. 최신 SDK 호출은 기본 65,536이고 자동 이어 쓰기로 더 큰 전체 출력을 돌려줌 |
| 지원 도구 | 코드 실행, 함수 호출, 구조화 출력, 검색·지도 그라운딩, URL 컨텍스트, 파일 검색. 컴퓨터 사용은 Preview |
| 미지원 | 이미지·음성 생성, Live API, 명시 캐싱 |
| 처리 옵션 | Batch, Flex, Priority |

**가격** (Gemini Developer API 유료 등급, 100만 토큰당 USD. 도입가는 2026-11-30까지, 12-01부터 두 배):

| 처리 | 입력 | 출력 (사고 포함) | 캐시 적중 입력 |
|------|------|------|------|
| Standard | $2.00 → $4.00 | $10.00 → $20.00 | $0.10 → $0.20 |
| Batch·Flex | $1.00 → $2.00 | $5.00 → $10.00 | $0.05 → $0.10 |
| Priority | $3.60 → $7.20 | $18.00 → $36.00 | $0.18 → $0.36 |

- Developer API의 무료 등급과 Google AI Pro 플랜에서는 쓸 수 없습니다("not available on the Free tier or on the Google AI Pro plan"). 이 문장은 Developer API·AI Studio 조건이고, Antigravity 이용 조건은 [§8](#8-agyantigravity-cli에서-쓸-때)을 따릅니다.
- 그라운딩을 쓰면 내부 도구 지시와 함수 선언까지 토큰으로 과금되고, 검색은 요청 단위 과금이 따로 붙습니다. 장문 출력은 이어 쓰기마다 앞부분을 다시 입력으로 처리하므로 결과 글자 수만으로 비용을 추정하지 않습니다.

## 3. 프롬프팅 권고

### 3.1 장시간 작업 운용 (AI Studio 개발 가이드 "5 practical tips")

Google이 "Gemini 4 Argon can work on a task independently for a long time"을 전제로 정리한 다섯 가지입니다. 3.x에 없던 능력이라는 검증이 아니라, Argon 문서가 따로 강조하는 운용 방식입니다.

| 권고 | 내용 | 원문 |
|------|------|------|
| **착수 전에 의도를 맞춘다** | 측정 가능한 목표와 이정표를 먼저 합의하고, 경계 사례·성공 조건에 대한 질문을 먼저 끌어낸다. 시작 전에 필요한 도구·문서 접근을 확인시키고, 합의한 뒤에는 턴마다 끼어들지 말고 끝까지 실행하게 한다. 되돌릴 수 없는 단계 앞에서는 멈춰 확인받는다 | "Align on intent before long runs" / "Run a quick pre-flight check" |
| **검증 수단을 준다** | "고쳐졌는지 추측"하게 두지 말고 테스트 스위트, 실행 로그, 브라우저 스크린샷 같은 기존 신호를 준다. 그것으로 부족하면 재현 가능한 검증 스크립트와 기준 점수를 마련해 변경마다 확인하게 하는 방식을 원문이 더 나은 선택으로 권한다. 잴 것이 아예 없으면 기준 측정부터 같이 만든다 | "Give the model a way to verify its work" |
| **멀티모달 참조를 쓴다** | 시각 목표는 1~2개의 구체적 참조 이미지나, 서체·색·레이아웃 규칙을 정리한 `DESIGN.md`로 준다. 화면 녹화와 음성 설명을 함께 넣는 방식도 권한다 | "Use multimodal references" |
| **조율자로 쓴다** | Argon(`medium`·`high`)이 문제 분해·인터페이스 설계·최종 리뷰를 맡고, 범위가 분명한 병렬 작업(탐색, 보일러플레이트 테스트, 말단 모듈 이전)은 3.8 Flash 하위 에이전트에 맡기는 조합을 공식 사례로 든다. 모든 작업의 위임 의무는 아니다 | "Use Argon as an orchestrator" |
| **지난 작업을 회고시킨다** | 긴 작업 끝이나 막힌 시점에 경로를 돌아보게 하고, 저장소의 함정과 재사용할 절차를 `AGENTS.md`나 스킬로 남기자고 제안하게 한다. 매번 파일을 고치라는 규칙으로 넓히지 않는다 | "Have Argon reflect on past work" |

### 3.2 응답 성향 (Google 주장)

출시 글이 밝힌 성향입니다. 독립 실측이 아니므로 프롬프트를 줄이는 근거로 쓰기 전에 과제별로 확인합니다.

- 문체 지시를 이전 Gemini보다 잘 따른다("follows style instructions better than any of our previous Gemini models").
- 얼버무림이 적고, 필요 이상 반복하지 않으며, 상투어를 덜 쓴다("answers questions more directly with less hedging, doesn't repeat itself more than necessary, and skips clichés").
- 긴 작업에서 진행 상황을 더 자주 알린다("keeps you in the loop by sharing its progress more often"). 이 문장은 [Gemini 앱 출시 글](https://blog.google/innovation-and-ai/products/gemini-app/gemini-4-argon-availability/)이 앱에서의 성향으로 설명한 것입니다.
- 시스템 경계를 지키고, 부정적 결과도 정직하게 보고하며, 되돌릴 수 없는 단계 전에 확인을 구하도록 훈련됐다("respect system boundaries, report negative findings honestly, and pause for human confirmation before taking irreversible steps").

### 3.3 그 밖의 공식 문장

- **길이 목표는 따르지 않습니다.** Cloud 가이드의 장문 출력 표: "Requests for a fixed length, such as "write a 700,000-word book" | No | The model does not follow length targets." 장문 출력은 답을 길게 만드는 기능이 아니라 사고할 여지를 주는 기능입니다. 깊이는 `thinking_level`로 조절합니다.
- **고정 내용은 앞에 둡니다.** 암시 캐싱이 공통 접두부에 적용되므로 "put static content at the start of your prompt"(Cloud).
- **도구 호출 직전에 구조 없는 텍스트를 두지 않습니다.** Cloud 가이드의 Argon 관례: "Separate inline instructions with \n\n and avoid unstructured text before tool calls." 중간 메모가 필요하면 전용 함수(`update`: `previous_step`·`plan`·`next_step`)로 남깁니다.

## 4. 사고 수준 (`thinking_level`)

| 레벨 | 토큰·지연 | 공식 용도 |
|------|------|------|
| `low` | 가장 적음, 지연 최저 | 단순 작업과 비용 민감 작업, 가벼운 사고가 필요한 분석·글쓰기. 분류·라우팅·추출. 어려운 작업에서는 품질이 떨어질 수 있음 |
| `medium` (기본) | 균형 | 복잡한 코드와 에이전트 작업을 포함한 대부분의 작업에 권장 |
| `high` | 가장 많음, 첫 토큰이 가장 느림 | 복잡한 추론, 어려운 수학·과학, 가장 어려운 코드·에이전트 작업. 다중 파일 원인 분석, 취약점 패치, 초기 설계. 장문 출력과 잘 맞음 |

- 공식 권고: 세 수준을 모두 평가하고 품질 기준을 넘는 가장 낮은 수준을 고릅니다("Run your evaluations at all three levels, then pick the lowest level that meets your quality bar"). 평가할 때는 `max_output_tokens`를 넉넉히 둬 한도 때문에 답이 잘리지 않게 합니다.
- `minimal`과 사고 끄기는 없습니다. Cloud는 `MINIMAL`을 400 오류로 명시합니다.
- `thinking_budget`은 서비스마다 다릅니다. **Gemini Developer API의 GenerateContent**에서는 "still works and maps to the nearest thinking_level, but it returns a warning"이고, **Cloud**에서는 HTTP 400입니다. 어느 쪽이든 새 코드는 `thinking_level`만 씁니다.
- 필드 경로: Interactions `generation_config.thinking_level` / GenerateContent Python SDK `config.thinking_config.thinking_level` / REST `generationConfig.thinkingConfig.thinkingLevel`. Cloud 값은 대문자(`LOW`·`MEDIUM`·`HIGH`)로 적혀 있습니다.

## 5. 출력 한도와 장문 출력

`max_output_tokens`는 사고와 응답을 합친 상한입니다(장문 출력이면 이어 쓰기 전체 합계). Argon은 이전 모델보다 이 한도를 사고에 더 많이 씁니다.

| 상황 | 공식 출발점 |
|------|------|
| 일반 작업 | 기본값 유지 |
| 기존 앱의 한도가 32K 미만 | 32,768 이상으로 올림. 토큰을 줄이려면 한도가 아니라 사고 수준을 낮춤 |
| 복잡한 추론·코드 | 131,072 또는 262,144, 최대 1,048,576 − 입력 토큰 (장문 출력 필요) |

**API 방식별 장문 출력**:

| 방식 | 켜는 법 | 주의 |
|------|------|------|
| Interactions (Gemini API) | `background=True` **그리고** `max_output_tokens > 65536` | `background`만 켜고 한도를 안 주면 64K에서 멈춤. 동기 요청(`background=False`)에서 65,536 초과는 400. 이어 쓴 구간마다 `model_output` 단계가 생기므로 완료 후 모든 단계의 텍스트를 합침 |
| GenerateContent + 최신 SDK | `max_output_tokens`를 요청당 한도보다 크게 | Python `google-genai` 2.30.1+, JS `@google/genai` 2.29.1+에서 자동 이어 쓰기가 기본. 구 SDK와 REST는 요청당 한도에서 멈춤 |
| GenerateContent 직접 루프 | 원래 요청 전체(`contents`·`system_instruction`·`tools`)를 최신 `continuation_token`과 함께 다시 보냄 | `finish_reason=CONTINUATION`이고 `continuation_token`이 있으면 원래 요청으로 이어 가고, 다른 종료 사유에서는 멈춤("Stop on any other finish reason"). `MAX_TOKENS`는 설정한 총 한도에 닿은 상태이므로 멈추고, 더 생성하기로 정한 경우에만 한도를 올려 최신 토큰으로 재개(같은 한도로 재개하면 400). 부분 출력을 `contents`에 붙이거나 "계속해"라고 묻지 않음. 한 구간이 전부 사고라 빈 텍스트가 와도 정상 |
| Cloud | GenerateContent의 `continuation_token`만 | v1beta1 필요(v1 미지원). Cloud 문서는 "Long decode isn't supported on the Interactions API"라고 적음 |

- OpenAI 호환 계층과 구 SDK는 장문 출력을 받을 수 없습니다("Older SDK versions and the OpenAI compatibility layer cannot retrieve long completions").
- 어려운 프롬프트는 몇 분 걸립니다. 동기 호출이면 HTTP 타임아웃을 Interactions 기준 15분, GenerateContent 기준 20분 이상으로 잡거나 백그라운드 실행을 씁니다.
- 에이전트 하네스에서 압축 시점을 정할 때, 이어 쓰기 중에는 `prompt_token_count`가 구간마다 누적되므로 `initial_prompt_token_count`로 문맥 크기를 봅니다. 압축은 이어 쓰기가 끝나 `continuation_token`이 더 오지 않은 뒤에 합니다. 도중에 원래 입력을 줄이면 같은 요청을 다시 보내야 하는 이어 쓰기 계약과 어긋납니다.
- 장문 출력이 필요 없는 경우(공식 표): 채팅·질의응답·요약·분류·추출, 짧은 턴을 많이 도는 도구 에이전트, 1M에 가까운 입력, 지연에 민감한 요청.

## 6. 3.x와 달라진 API 계약

| 항목 | Argon | 비고 |
|------|------|------|
| 명시 캐싱 | 미지원. GenerateContent 문서는 "returns an error" | 암시 캐싱이 기본, 적중 입력 95% 할인. 최소 길이는 Gemini API 4,096 토큰, Cloud 6,144 토큰(내구 캐싱 기본)으로 서비스마다 다름 |
| 통합 창·요청당 한도 | [§5](#5-출력-한도와-장문-출력) | 입력·출력 한도를 따로 계산하던 코드는 수정 |
| `thinking_budget`·`minimal` | [§4](#4-사고-수준-thinking_level) | 3.1 Pro에서는 budget이 수준으로 조용히 바뀌었지만 Cloud의 Argon은 400 |
| sampling | `temperature`·`top_p`·`top_k`는 무시되고 사용 중단 경고("Custom sampling values are ignored by `gemini-4-argon` and return a deprecation warning") | 제거 권고 자체는 3.x에도 있었음. 일반 프롬프팅 문서는 Gemini 4와 3.6+가 향후 400을 낼 것이라고 예고 |
| 기타 생성 인자 | `candidate_count`는 Gemini API에서도 제거 대상. Cloud는 `frequency_penalty`·`presence_penalty`·`candidate_count`를 400으로 명시 | Gemini API에서 penalty 인자가 400인지는 확인하지 않음 |
| 대화 이력 | 미리 채운 model 턴 미지원, 이력이 model 턴으로 끝나면 안 됨(Cloud) | 형식 강제는 구조화 출력으로 |
| 동영상 | 에이전트형 동영상 이해 GA. 업로드 영상 기본은 `media_processing="static"`, 켜려면 `"agentic"` | 해상도 설정과 별개 |

## 7. 3.x와 공유하는 계약

공식 문서가 Gemini 4와 3을 함께 명시했거나, Argon 문서가 같은 요구를 다시 적은 항목만 3.x 가이드 절로 연결합니다.

| 항목 | 공유 근거 | 세부 |
|------|------|------|
| 사고 서명·이력 보존 | Argon GenerateContent 체크리스트 "Preserve thought signatures", Interactions는 `previous_interaction_id`로 서버가 관리 | [3.x §6](./gemini-3-prompt-guide.md#6-api-방식별-계약-interactions--generatecontent) |
| 함수 결과 짝 | Cloud Argon 관례 "Each FunctionResponse must match the id, name, and order of the preceding FunctionCall", "Prefer sequential tool execution turns" | [3.x §7](./gemini-3-prompt-guide.md#7-함수-호출) (`id`·`call_id` 문서 불일치 설명 포함) |
| 구조화 출력 + 내장 도구 | "available only to Gemini 4 and Gemini 3 series models, such as gemini-4-argon and gemini-3.8-flash" (Preview) | [3.x §8](./gemini-3-prompt-guide.md#8-구조화-출력). 새 예제의 `response_format` 형식과 구 `response_mime_type`·`response_schema` 필드의 Argon 호환 여부는 확인하지 않음 |
| 미디어 해상도 | "Per-content-item media resolution (Gemini 4 and Gemini 3 models)", 같은 토큰 표 | [3.x §9](./gemini-3-prompt-guide.md#9-미디어-해상도) |

## 8. agy(Antigravity CLI)에서 쓸 때

| 항목 | 내용 |
|------|------|
| 제공 범위 | Antigravity App·CLI·IDE 확장. 구 Antigravity IDE에는 없음("Not available in Antigravity IDE") |
| 요금제 | 유료 Google AI Pro(체험판 제외, "non-trial subscriptions only")·Ultra·적격 Enterprise. Google 출시 글과 AI Studio 가이드는 Ultra만 적었지만, Antigravity 자체 발표와 모델 표가 유료 Pro 지원을 명시하므로 해당 서비스의 조건을 따름 |
| 노력 수준 | `/effort`·`--effort`가 모델 변형(`gemini-4-argon-low`·`-medium`·`-high`)을 바꿈. `xhigh`·`max`는 그 변형을 낸 모델에만 있고, 2026-10-16 `agy models`(1.3.6) 목록의 Argon은 세 변형뿐 |
| 쿼터 | 고정 횟수가 아니라 작업량에 비례("the rate limits correlate with the amount of work done by the agent"). 유료 Pro는 Argon 전용 주간 버킷(`gemini-argon-wtu-weekly`)이 따로 있고 5시간 한도는 없음. Ultra는 Argon 몫이 Gemini 버킷에 포함됨("For paid Pro plans, Argon quota is separate. Higher Argon quota (included as part of the larger Gemini quota bucket) is available on Ultra plans.", `agy -p "/usage"`) |
| 미확인 | 출고 기본 모델·변형, CLI에서 쓸 수 있는 창 크기, 변형이 API `thinking_level`로 그대로 전달되는지 |

dotfiles의 agy 상태줄(`.antigravity/cli/statusline-command.sh`)은 Argon을 고르면 `gemini-argon`으로 시작하는 주간 버킷과 Flash가 쓰는 Gemini 버킷(5시간·주간)을 나란히 표시하고, Argon 버킷이 없으면(Ultra) `gemini-5h`·`gemini-weekly`를 읽습니다. 상태줄 페이로드의 키가 `/usage`의 버킷 ID와 같다는 전제이며, Argon 버킷이 실제로 실리는지는 아직 실측하지 않았습니다.

## 9. 마이그레이션 체크리스트

**3.1 Pro Preview·3.8 Flash → 4 Argon**
- [ ] 모델 ID를 `gemini-4-argon`으로 (Cloud 사이버 작업은 승인된 경우에만 `-cyber-permissive`)
- [ ] SDK 갱신: 장문 출력이 필요하면 Python `google-genai` 2.30.1+, JS `@google/genai` 2.29.1+
- [ ] `max_output_tokens`: 32K 미만이면 32,768 이상으로. 64K 초과가 필요하면 [§5](#5-출력-한도와-장문-출력)의 API별 방식으로
- [ ] `thinking_budget`·`minimal` → `thinking_level`(`low`·`medium`·`high`). 세 수준을 모두 평가
- [ ] 명시 캐싱 호출 제거, 고정 내용을 프롬프트 앞으로(암시 캐싱)
- [ ] `temperature`·`top_p`·`top_k`·`candidate_count` 제거. Cloud면 `frequency_penalty`·`presence_penalty`도
- [ ] 미리 채운 model 턴 제거, 멀티턴은 `previous_interaction_id` 또는 서명 포함 전체 이력
- [ ] HTTP 타임아웃 15~20분 이상 또는 백그라운드 실행
- [ ] 3.x용 프롬프트 처방을 그대로 옮기지 말고 [§3](#3-프롬프팅-권고)의 Argon 권고와 범용 원칙으로 다시 점검

## 10. 미확인 항목

- Argon 지식 마감일 (모델 페이지에 없음)
- Gemini API에서 `frequency_penalty`·`presence_penalty`가 400인지 (Cloud만 명시)
- 구조화 출력의 구 필드(`response_mime_type`·`response_schema`) 호환성
- agy의 기본 변형·창 크기, 변형과 API `thinking_level`의 실제 대응
- Gemini 4 계열의 다른 모델 이름과 Pro·Flash 체계의 존폐 ("We're looking forward to bringing you the rest of the Gemini 4 family"만 확인)

## 11. 요약

| 축 | 처방 |
|------|------|
| **확정할 것** | 모델 ID `gemini-4-argon` + 서비스(Gemini API·Cloud) + API 방식(Interactions·GenerateContent) |
| **프롬프트** | 착수 전 목표·성공 조건 합의, 기존 검증 수단 제공(부족하면 재현 가능한 검사 마련), 시각 목표는 참조로, 나눌 수 있는 큰 작업은 조율자 + 3.8 Flash 하위 에이전트를 선택지로, 끝나면 회고. 3.x 처방 자동 승계 금지 |
| **사고** | `low`·`medium`(기본)·`high`. 세 수준 평가 후 가장 낮은 합격 수준. 비용은 `max_output_tokens`보다 `thinking_level`로 |
| **출력** | 창 1M 공유. Interactions 동기 최대 64K, GenerateContent 직접 비스트리밍 REST 32K·스트리밍 64K, 최신 SDK는 자동 이어 쓰기. 그 이상은 API별 장문 출력 |
| **제거** | 명시 캐싱, `thinking_budget`·`minimal`, sampling, `candidate_count`, 미리 채운 model 턴 |
| **공유** | 사고 서명·함수 결과 짝·구조화 출력·미디어 해상도는 3.x 가이드 절을 따름 |
