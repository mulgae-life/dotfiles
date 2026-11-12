# Gemini 4 (Argon·Carbon) 프롬프팅 가이드

> **대상 모델**: `gemini-4-argon` · `gemini-4-carbon`. Cloud 전용 `-cyber-permissive` 변형은 [§2](#2-모델-개요)에서 구분합니다. 기존 링크를 유지하기 위해 파일명은 바꾸지 않았습니다.
>
> **출처 (공식 1차)**:
> - [Argon 새 기능](https://aistudio.google.com/docs/whats-new-gemini-4-argon) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-argon?generate-content=true)
> - [Carbon 새 기능](https://aistudio.google.com/docs/whats-new-gemini-4-carbon) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-carbon?generate-content=true)
> - [Argon 모델 페이지](https://aistudio.google.com/docs/models/gemini-4-argon) · [Carbon 모델 페이지](https://aistudio.google.com/docs/models/gemini-4-carbon) · [Carbon 모델 카드](https://deepmind.google/models/model-cards/gemini-4-carbon/)
> - AI Studio 개발 가이드: [Argon](https://aistudio.google.com/learn/gemini-4-argon-developer-guide) (2026-10-13) · [Carbon](https://aistudio.google.com/learn/gemini-4-carbon-developer-guide) (2026-11-10)
> - [Thinking](https://aistudio.google.com/docs/thinking) · [Long decode](https://aistudio.google.com/docs/long-decode) · [GenerateContent판](https://aistudio.google.com/docs/long-decode?generate-content=true) · [Pricing](https://aistudio.google.com/docs/pricing) · [Changelog](https://aistudio.google.com/docs/changelog)
> - [Media resolution](https://ai.google.dev/gemini-api/docs/media-resolution) · [Structured outputs (GenerateContent)](https://ai.google.dev/gemini-api/docs/generate-content/structured-output) · [Prompt design strategies](https://ai.google.dev/gemini-api/docs/prompting-strategies)
> - Cloud 개발 가이드: [Argon](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon) · [Carbon](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-carbon) · [Cloud 이행 문서](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/migrate)
> - 출시 글: [Argon](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-argon/) · [Carbon 일반 제공](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-4-carbon-now-available/)
> - Antigravity: [Argon](https://antigravity.google/blog/gemini-4-argon-in-google-antigravity) · [Carbon](https://antigravity.google/blog/gemini-4-carbon-in-google-antigravity) · [모델 표](https://antigravity.google/docs/models/) · [CLI 변경 기록](https://antigravity.google/docs/changelog/)
>
> **최초 정리**: 2026-10-16. 당시 조사 기록은 [research-gemini4-argon.md](../research/research-gemini4-argon.md)입니다.
> **갱신**: 2026-11-12. Carbon 원문과 두 모델의 장문 출력·캐시·제공 조건을 대조했습니다.
> **자매 가이드**: [Gemini 3.x](./gemini-3-prompt-guide.md) · [Gemma 4](./gemma-4-prompt-guide.md)

같은 Gemini 4 계열인 Argon과 Carbon을 함께 다룹니다. **적용 순서**는 모델별 계약 표 → Carbon 차이 → 두 모델 공통 본문입니다. Argon 전용 성향은 별도로 표시합니다. 공식 문서가 적용을 확인한 계약과 권고만 공유하며, Gemini 3 전용 처방은 자동 적용하지 않습니다. 나머지는 `writing-prompts` 스킬의 범용 원칙을 적용합니다.

## 목차
1. [가장 먼저 알아야 할 것](#1-가장-먼저-알아야-할-것)
2. [모델 개요](#2-모델-개요)
   - [Carbon 차이](#21-carbon-차이)
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
- **Gemini API와 Cloud의 계약을 구분합니다.** `thinking_budget` 처리와 API 버전·저장 조건이 다릅니다. 암시 캐시 최소 길이는 현재 두 서비스 모두 4,096토큰입니다.
- **API 모델 ID와 agy의 사고 강도 변형을 구분합니다.** API에는 `gemini-4-argon` 또는 `gemini-4-carbon`을 씁니다. agy 목록의 `-low`·`-medium`·`-high` 접미사는 API 모델 ID가 아닙니다.

## 2. 모델 개요

| 항목 | Argon | Carbon |
|------|------|------|
| 안정 버전 ID | `gemini-4-argon` | `gemini-4-carbon` |
| 출시 | 2026-09-30 Fairwind 선공개, 10-13 일반 제공(GA) | 2026-10-28 Fairwind 선공개 발표, 11-10 GA |
| 선택 기준 | 대부분의 고급 개발·지식 작업, 대화형 코딩과 빠른 반복 | 가장 어려운 다단계 개발, 원인 분석, 설계·감사, 수학·과학 연구 |
| 일반 모델 사고 강도 | `low`·`medium`·`high`, 기본 `medium` | `low`·`medium`·`high`, 기본 `medium` |
| Cloud 사이버 변형 | `gemini-4-argon-cyber-permissive`, 기본 `HIGH` | `gemini-4-carbon-cyber-permissive`, 기본 `HIGH` |
| Developer API 일반 입력 / 출력 요율 | 11-30까지 `$2 / $10`, 12-01부터 `$4 / $20` | 11-30까지 `$2 / $10`, 12-01부터 `$4 / $20` |
| 제공 경로 | 유료 Gemini API·AI Studio, Cloud, Antigravity | 유료 Gemini API·AI Studio, Cloud, Antigravity |
| Antigravity 자격 | 유료 Pro·일부 적격 기기 체험판, Ultra·적격 Enterprise | Ultra·적격 Enterprise; ADC는 프로젝트 접근 권한 필요 |

사이버 변형은 Fairwind 승인 등 별도 접근 조건을 따릅니다. 일반 모델의 기본값과 섞지 않습니다. Cloud의 별도 요율은 해당 서비스 가격표를 확인합니다.

### 2.1 Carbon 차이

- **Argon 기반의 같은 계열**입니다. [모델 카드](https://deepmind.google/models/model-cards/gemini-4-carbon/)는 기반 모델을 Argon으로 명시합니다. [이행 안내](https://aistudio.google.com/docs/whats-new-gemini-4-carbon#migrate-from-gemini-4-argon)는 Argon에서 요청 스키마를 바꿀 필요가 없다고 설명합니다.
- **복잡한 과제에서 사고·탐색·검증에 더 많은 토큰과 시간을 씁니다.** 토큰 단가가 같아도 작업 비용은 같지 않습니다. 일반적인 빠른 반복은 Argon에 남기고 Carbon은 난도가 높은 부분부터 평가합니다.
- **역할 분담은 선택지입니다.** [Carbon 개발 가이드](https://aistudio.google.com/learn/gemini-4-carbon-developer-guide)는 Carbon `medium`·`high`가 설계·조율·최종 검증을 맡고 Argon·3.8 Flash가 독립적인 구현 부분을 맡는 구성을 제시합니다. `/swarm`은 미리보기이며 모든 작업의 위임을 요구하지 않습니다.
- **추가 자료**로 공식 `gemini-frontend-design` 스킬과 회고 후 시각 설명 생성을 소개합니다. 스킬은 [google-gemini/demolab](https://github.com/google-gemini/demolab)에 있습니다. 기존 프로젝트의 디자인 체계를 확인한 뒤 선택하며, 이 가이드를 읽었다는 이유로 설치하거나 `AGENTS.md`를 자동 수정하지 않습니다.

### 2.2 두 모델 공통 계약

| 항목 | 내용 |
|------|------|
| 입력 / 출력 | 텍스트·이미지·영상·음성·PDF / 텍스트 |
| 창 | 통합 1,048,576 (입력 + 사고 + 출력) |
| 출력 한도 | 총 출력 예산 기본 65,536. Interactions·GenerateContent의 전경 한 구간은 직접 비스트리밍 HTTP 32,768, 스트리밍 65,536. 최신 SDK는 자동 이어 쓰기로 전체 결과를 합침. 최대 출력은 1,048,576에서 입력을 뺀 값이며 [§5](#5-출력-한도와-장문-출력)의 설정 필요 |
| 지원 도구 | 코드 실행, 함수 호출, 구조화 출력, 검색·지도 그라운딩, URL 컨텍스트, 파일 검색. 컴퓨터 사용은 2026-10-30 GA |
| 미지원 | 이미지·음성 생성, Live API, 명시 캐싱 |
| 처리 옵션 | Batch, Flex, Priority |

**가격** (Gemini Developer API 유료 등급, 100만 토큰당 USD. 도입가는 2026-11-30까지, 12-01부터 두 배):

| 처리 | 입력 | 출력 (사고 포함) | 캐시 적중 입력 |
|------|------|------|------|
| Standard | $2.00 → $4.00 | $10.00 → $20.00 | $0.10 → $0.20 |
| Batch·Flex | $1.00 → $2.00 | $5.00 → $10.00 | $0.05 → $0.10 |
| Priority | $3.60 → $7.20 | $18.00 → $36.00 | $0.18 → $0.36 |

- Developer API 무료 등급에는 제공하지 않습니다. Google AI Pro 구독만으로 AI Studio의 두 모델 이용 자격을 얻는 것은 아니며, 유료 API 등급 또는 Ultra 조건을 확인합니다. Antigravity 이용 조건은 [§8](#8-agyantigravity-cli에서-쓸-때)과 다릅니다.
- 그라운딩을 쓰면 내부 도구 지시와 함수 선언까지 토큰으로 과금되고, 검색은 요청 단위 과금이 따로 붙습니다. 장문 출력은 이어 쓰기마다 앞부분을 다시 입력으로 처리하므로 결과 글자 수만으로 비용을 추정하지 않습니다.

## 3. 프롬프팅 권고

### 3.1 장시간 작업 운용 (AI Studio 개발 가이드 "5 practical tips")

Argon과 Carbon의 AI Studio 개발 가이드가 각각 제시한 공통 운용 축입니다. 3.x에 없던 능력이라는 검증은 아닙니다. 역할 분담의 모델 선택은 구분합니다.

| 권고 | 내용 | 원문 |
|------|------|------|
| **착수 전에 의도를 맞춘다** | 측정 가능한 목표와 이정표를 먼저 합의하고, 경계 사례·성공 조건에 대한 질문을 먼저 끌어낸다. 시작 전에 필요한 도구·문서 접근을 확인시키고, 합의한 뒤에는 턴마다 끼어들지 말고 끝까지 실행하게 한다. 되돌릴 수 없는 단계 앞에서는 멈춰 확인받는다 | "Align on intent before long runs" / "Run a quick pre-flight check" |
| **검증 수단을 준다** | "고쳐졌는지 추측"하게 두지 말고 테스트 스위트, 실행 로그, 브라우저 스크린샷 같은 기존 신호를 준다. 그것으로 부족하면 재현 가능한 검증 스크립트와 기준 점수를 마련해 변경마다 확인하게 하는 방식을 원문이 더 나은 선택으로 권한다. 잴 것이 아예 없으면 기준 측정부터 같이 만든다 | "Give the model a way to verify its work" |
| **멀티모달 참조를 쓴다** | 시각 목표는 1~2개의 구체적 참조 이미지나, 서체·색·레이아웃 규칙을 정리한 `DESIGN.md`로 준다. 화면 녹화와 음성 설명을 함께 넣는 방식도 권한다 | "Use multimodal references" |
| **조율자로 쓴다** | Argon 가이드는 Argon + 3.8 Flash를, Carbon 가이드는 Carbon(`medium`·`high`) + Argon·3.8 Flash를 제시한다. 조율자는 설계·리뷰를, 다른 모델은 범위가 분명한 병렬 구현을 맡는다. 위임 의무는 아니다 | 두 가이드의 조율자 절 |
| **지난 작업을 회고시킨다** | 긴 작업 끝이나 막힌 시점에 경로를 돌아보게 하고, 저장소의 함정과 재사용할 절차를 `AGENTS.md`나 스킬로 남기자고 제안하게 한다. 매번 파일을 고치라는 규칙으로 넓히지 않는다 | 두 가이드의 회고 절 |

### 3.2 Argon 전용 응답 성향 (Google 주장)

Argon 출시 글이 밝힌 성향입니다. Carbon에 자동 적용하지 않으며, 독립 실측이 아니므로 프롬프트를 줄이는 근거로 쓰기 전에 과제별로 확인합니다.

- 문체 지시를 이전 Gemini보다 잘 따른다("follows style instructions better than any of our previous Gemini models").
- 얼버무림이 적고, 필요 이상 반복하지 않으며, 상투어를 덜 쓴다("answers questions more directly with less hedging, doesn't repeat itself more than necessary, and skips clichés").
- 긴 작업에서 진행 상황을 더 자주 알린다("keeps you in the loop by sharing its progress more often"). 이 문장은 [Gemini 앱 출시 글](https://blog.google/innovation-and-ai/products/gemini-app/gemini-4-argon-availability/)이 앱에서의 성향으로 설명한 것입니다.
- 시스템 경계를 지키고, 부정적 결과도 정직하게 보고하며, 되돌릴 수 없는 단계 전에 확인을 구하도록 훈련됐다("respect system boundaries, report negative findings honestly, and pause for human confirmation before taking irreversible steps").

### 3.3 그 밖의 공식 문장

- **길이 목표는 따르지 않습니다.** Cloud 가이드의 장문 출력 표: "Requests for a fixed length, such as "write a 700,000-word book" | No | The model does not follow length targets." 장문 출력은 답을 길게 만드는 기능이 아니라 사고할 여지를 주는 기능입니다. 깊이는 `thinking_level`로 조절합니다.
- **고정 내용은 앞에 둡니다.** 암시 캐싱이 공통 접두부에 적용되므로 "put static content at the start of your prompt"(Cloud).
- **도구 호출 직전에 구조 없는 텍스트를 두지 않습니다.** 두 모델의 Cloud 가이드는 지시를 `\n\n`으로 구분하고 중간 메모가 필요하면 전용 함수(`update`: `previous_step`·`plan`·`next_step`)로 남기도록 권합니다.

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

`max_output_tokens`는 사고와 함수 호출·응답을 합친 상한입니다(장문 출력이면 이어 쓰기 전체 합계). Carbon은 복잡한 과제에서 Argon보다 사고에 더 많은 토큰을 쓰므로 답변 몫을 남겨야 합니다.

| 상황 | 공식 출발점 |
|------|------|
| 일반 작업·대부분의 코딩 | 기본값 65,536 유지 |
| 기존 앱의 한도가 32K 미만 | 32,768 이상으로 올림. 토큰을 줄이려면 한도가 아니라 사고 수준을 낮춤 |
| 어려운 수학·과학·증명 등 긴 추론 | 전용 장문 출력 문서는 262,144부터 평가하도록 권고. 최대 1,048,576 − 입력 토큰 |

**API 방식별 장문 출력**:

| 방식 | 켜는 법 | 주의 |
|------|------|------|
| Interactions 백그라운드 | `background=True` + `max_output_tokens > 65536` | `store=True` 필요. 한도를 안 주면 총 예산은 64K. 서버가 이어 쓴 구간의 모든 `model_output` 텍스트를 합침 |
| Interactions 전경 + 최신 SDK | `max_output_tokens`를 구간 한도보다 크게 | Python `google-genai` 2.34.0+, JS `@google/genai` 2.32.0+에서 자동 이어 쓰기가 기본. `background=False`도 64K 초과 전체 결과를 생성 |
| Interactions 직접 루프 | `status="requires_continuation"`이면 `continuation_token`으로 재개 | 저장형은 토큰을 만든 구간의 `previous_interaction_id`와 토큰을 보내고 `input` 생략. 무상태는 원래 `input`과 토큰을 보내고 이전 ID 생략. 총 예산을 소진한 `incomplete`에서 재개하려면 예산을 올려야 함 |
| GenerateContent + 최신 SDK | `max_output_tokens`를 요청당 한도보다 크게 | Python `google-genai` 2.30.1+, JS `@google/genai` 2.29.1+에서 자동 이어 쓰기가 기본. 구 SDK와 REST는 요청당 한도에서 멈춤 |
| GenerateContent 직접 루프 | 원래 요청 전체(`contents`·`system_instruction`·`tools`)를 최신 `continuation_token`과 함께 다시 보냄 | `finish_reason=CONTINUATION`이고 `continuation_token`이 있으면 원래 요청으로 이어 가고, 다른 종료 사유에서는 멈춤("Stop on any other finish reason"). `MAX_TOKENS`는 설정한 총 한도에 닿은 상태이므로 멈추고, 더 생성하기로 정한 경우에만 한도를 올려 최신 토큰으로 재개(같은 한도로 재개하면 400). 부분 출력을 `contents`에 붙이거나 "계속해"라고 묻지 않음. 한 구간이 전부 사고라 빈 텍스트가 와도 정상 |
| Cloud | Interactions와 GenerateContent 모두 지원 | 장문 출력은 `v1beta1` 필요(`v1` 미지원). Interactions는 백그라운드 또는 전경 이어 쓰기, GenerateContent는 SDK 자동 이어 쓰기 또는 직접 루프 |

- OpenAI 호환 계층과 구 SDK는 장문 출력을 받을 수 없습니다("Older SDK versions and the OpenAI compatibility layer cannot retrieve long completions").
- 어려운 프롬프트는 몇 분 걸립니다. GenerateContent·Cloud 가이드의 구간별 HTTP 시간 제한은 20분 이상을 기준으로 잡고, Interactions SDK의 구간별 `http_options` 제한과 호출 전체 `timeout`을 구분합니다. 긴 작업은 백그라운드 실행도 선택할 수 있습니다.
- Interactions 전경 SDK의 `create` 결과에는 구간별 텍스트·사용량이 합쳐집니다. 이후 `get`은 마지막 구간만 반환하므로 합쳐진 생성 결과를 보존합니다.
- 압축 판단에 누적 입력 토큰을 쓰지 않습니다. Interactions는 최초 입력량을, GenerateContent는 `initial_prompt_token_count`를 확인합니다. 압축은 이어 쓰기가 끝난 뒤에 하며, 도중에 모델·지시·도구·사고 강도를 바꾸지 않습니다.
- **출처 간 시차**: 11/10 Carbon AI Studio 개발 가이드에는 Interactions 전경 이어 쓰기가 곧 제공된다는 설명이 남아 있습니다. 현재 계약은 [전용 장문 출력 문서](https://aistudio.google.com/docs/long-decode)의 전경 지원·SDK 표를 따릅니다.
- 장문 출력이 필요 없는 경우(공식 표): 채팅·질의응답·요약·분류·추출, 짧은 턴을 많이 도는 도구 에이전트, 1M에 가까운 입력, 지연에 민감한 요청.

## 6. 3.x와 달라진 API 계약

| 항목 | 두 모델 공통 | 비고 |
|------|------|------|
| 명시 캐싱 | 미지원. 생성하거나 `cached_content`를 전달하는 코드는 제거 | 암시 캐싱이 기본, 적중 입력 95% 할인. 최소 길이는 Gemini API·Cloud 모두 4,096토큰이며 Cloud는 내구 캐싱이 기본 |
| 통합 창·요청당 한도 | [§5](#5-출력-한도와-장문-출력) | 입력·출력 한도를 따로 계산하던 코드는 수정 |
| `thinking_budget`·`minimal` | [§4](#4-사고-수준-thinking_level) | Cloud의 두 모델은 400. Developer API GenerateContent의 호환 처리는 별도 |
| sampling | 사용자 지정 `temperature`·`top_p`·`top_k`는 무시하므로 제거 | 현재 무시되는 계약과 향후 오류 예고를 구분하며, Anthropic의 400 규칙을 옮기지 않음 |
| 기타 생성 인자 | `candidate_count`는 Gemini API에서도 제거 권고. Cloud는 `frequency_penalty`·`presence_penalty`·`candidate_count > 1`을 400으로 명시 | Gemini API에서 penalty 인자가 400인지는 확인하지 않음 |
| 대화 이력 | 미리 채운 model 턴 미지원, 이력이 model 턴으로 끝나면 안 됨(Cloud) | 형식 강제는 구조화 출력으로 |
| 동영상 | 에이전트형 동영상 이해 GA. 업로드 영상 기본은 `media_processing="static"`, 켜려면 `"agentic"` | 해상도 설정과 별개 |

## 7. 3.x와 공유하는 계약

공식 문서가 Gemini 4와 3을 함께 명시했거나, Argon·Carbon 문서가 같은 요구를 다시 적은 항목만 3.x 가이드 절로 연결합니다.

| 항목 | 공유 근거 | 세부 |
|------|------|------|
| 사고 서명·이력 보존 | 두 모델의 GenerateContent 체크리스트가 서명 보존을 요구. 저장형 Interactions는 `previous_interaction_id`로 서버가 관리 | [3.x §6](./gemini-3-prompt-guide.md#6-api-방식별-계약-interactions--generatecontent) |
| 함수 결과 짝 | 두 모델의 Cloud 가이드는 `FunctionResponse`의 ID·이름·순서를 호출과 맞추고, 다단계 도구 루프의 순차 실행을 권고 | [3.x §7](./gemini-3-prompt-guide.md#7-함수-호출). 의존 관계 없는 조회까지 모두 직렬화하라는 뜻은 아님 |
| 구조화 출력 + 내장 도구 | Gemini 4·3 계열 지원을 명시한 Preview | [3.x §8](./gemini-3-prompt-guide.md#8-구조화-출력). Cloud GenerateContent는 `response_mime_type`·`response_schema` 예제가 있음. Developer API의 구 필드 호환 여부는 미확인 |
| 미디어 해상도 | "Per-content-item media resolution (Gemini 4 and Gemini 3 models)", 같은 토큰 표 | [3.x §9](./gemini-3-prompt-guide.md#9-미디어-해상도) |

## 8. agy(Antigravity CLI)에서 쓸 때

| 항목 | 내용 |
|------|------|
| 제공 범위 | 두 모델 모두 Antigravity App·CLI·IDE 확장. 구 Antigravity IDE의 지원과 구분 |
| Argon 요금제 | 유료 Google AI Pro 및 적격 프리미엄 기기 체험판, Ultra·적격 Enterprise. 일반 Pro 체험판 전체를 지원하는 것은 아님 |
| Carbon 요금제 | 2026-11-10부터 Ultra·적격 Enterprise. Free·Plus·Pro는 미지원. Enterprise는 라이선스와 관리자 허용 모델 목록을 확인 |
| ADC | CLI 1.5.5부터 `AGY_ADC_AUTH` 로그인에서 Carbon Low·Medium·High를 제공. 프로젝트의 모델 접근 권한은 별도 조건 |
| 사고 강도 | API의 두 일반 모델은 세 수준. Argon의 CLI 세 변형은 2026-10-16 `agy models`(1.3.6)에서 관측했고, Carbon 세 수준은 1.5.5 변경 기록 기준. 실제 전송값은 미실측 |
| Argon 쿼터 | 작업량에 비례. 유료 Pro는 Argon 전용 주간 버킷(`gemini-argon-wtu-weekly`, 5시간 한도 없음), Ultra는 Gemini 버킷에 포함. 기존 `/usage` 관측이며 Carbon으로 확대하지 않음 |
| 미확인 | 출고 기본 모델·변형, CLI 창 크기, Carbon의 이 장비 노출 여부와 전용 쿼터 버킷·상태줄 페이로드 |

dotfiles의 agy 상태줄(`.antigravity/cli/statusline-command.sh`)은 Argon을 고르면 `gemini-argon`으로 시작하는 주간 버킷과 Flash가 쓰는 Gemini 버킷(5시간·주간)을 나란히 표시하고, Argon 버킷이 없으면(Ultra) `gemini-5h`·`gemini-weekly`를 읽습니다. 상태줄 페이로드의 키가 `/usage`의 버킷 ID와 같다는 전제이며, Argon 버킷이 실제로 실리는지는 아직 실측하지 않았습니다.

Carbon의 표시명은 현재 일반 Gemini 경로로 처리하지만, 그 버킷이 실제 Carbon 사용량을 나타내는지는 미확인입니다. 전용 키를 추측해 상태줄에 추가하지 않습니다. 공식 제공 조건과 개별 계정의 모델 목록 관측도 구분합니다.

## 9. 마이그레이션 체크리스트

**3.1 Pro Preview·3.8 Flash → 4 Argon·Carbon**
- [ ] 작업에 맞는 `gemini-4-argon` 또는 `gemini-4-carbon` 선택 (Cloud 사이버 변형은 승인된 경우에만)
- [ ] SDK 갱신: 전경 자동 이어 쓰기는 Interactions Python 2.34.0+·JS 2.32.0+, GenerateContent Python 2.30.1+·JS 2.29.1+. Cloud 장문 출력은 두 API 모두 `v1beta1`
- [ ] `max_output_tokens`: 32K 미만이면 32,768 이상으로. 64K 초과가 필요하면 [§5](#5-출력-한도와-장문-출력)의 API별 방식으로
- [ ] `thinking_budget`·`minimal` → `thinking_level`(`low`·`medium`·`high`). 세 수준을 모두 평가
- [ ] 명시 캐싱 호출 제거, 고정 내용을 프롬프트 앞으로(암시 캐싱)
- [ ] `temperature`·`top_p`·`top_k`·`candidate_count` 제거. Cloud면 `frequency_penalty`·`presence_penalty`도
- [ ] 미리 채운 model 턴 제거, 멀티턴은 `previous_interaction_id` 또는 서명 포함 전체 이력
- [ ] 구간별 HTTP 시간 제한과 전체 작업 시간 제한을 확인하거나 백그라운드 실행
- [ ] 3.x용 프롬프트 처방을 그대로 옮기지 말고 [§3](#3-프롬프팅-권고)의 공통 권고와 모델별 차이로 다시 점검

**Argon → Carbon**: 요청 스키마는 유지하고 모델 ID를 바꿉니다. 복잡한 과제에서 사고량·지연이 늘 수 있으므로 출력 예산·시간 제한·작업 비용을 다시 평가합니다. API 모델을 바꾼다고 agy 구독 자격이 바뀌지는 않습니다.

## 10. 미확인 항목

- 두 모델의 지식 마감일
- Gemini API에서 `frequency_penalty`·`presence_penalty`가 400인지 (Cloud만 명시)
- Developer API 구조화 출력의 구 필드(`response_mime_type`·`response_schema`) 호환성
- agy의 기본 변형·창 크기, 변형과 API `thinking_level`의 실제 대응, Carbon 쿼터 버킷
- 두 모델의 실제 성능·지연·비용 비교. 위 운용 권고는 공식 자료에 근거하며 자체 측정이 아님

## 11. 요약

| 축 | 처방 |
|------|------|
| **확정할 것** | `gemini-4-argon` 또는 `gemini-4-carbon` + 서비스 + API 방식. 사이버 변형은 별도 ID·접근 조건 |
| **프롬프트** | 목표·성공 조건 합의, 검증 수단과 시각 참조 제공, 큰 작업은 모델별 역할 분담을 선택지로 검토, 끝나면 회고 제안. 3.x 처방 자동 승계 금지 |
| **사고** | `low`·`medium`(기본)·`high`. 세 수준 평가 후 가장 낮은 합격 수준. 비용은 `max_output_tokens`보다 `thinking_level`로 |
| **출력** | 창 1M 공유, 총 출력 기본 64K. 전경 한 구간은 비스트리밍 32K·스트리밍 64K. 전체 결과는 SDK 이어 쓰기 또는 백그라운드 실행으로 확장. Cloud 두 API는 `v1beta1` |
| **제거** | 명시 캐싱, `thinking_budget`·`minimal`, sampling, `candidate_count`, 미리 채운 model 턴 |
| **공유** | 사고 서명·함수 결과 짝·구조화 출력·미디어 해상도는 3.x 가이드 절을 따름 |
