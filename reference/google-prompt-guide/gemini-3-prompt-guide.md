# Gemini 3.x Prompting Guide

> **대상 모델**: Flash 3.8 · 3.7 · 3.6 / Flash-Lite 3.5 · 3.1 / Pro 3.1 Preview
>
> **출처 (공식 1차)**:
> - [Gemini 3.8 Flash — Latest model | Google AI for Developers](https://ai.google.dev/gemini-api/docs/latest-model)
> - [What's new in Gemini 3.5 Flash | Google AI for Developers](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5) (Gemini 3.x 공통 파라미터·프롬프팅 절)
> - [Models | Google AI for Developers](https://ai.google.dev/gemini-api/docs/models) 및 모델별 페이지 ([3.8 Flash](https://ai.google.dev/gemini-api/docs/models/gemini-3.8-flash) · [3.7 Flash](https://ai.google.dev/gemini-api/docs/models/gemini-3.7-flash) · [3.6 Flash](https://ai.google.dev/gemini-api/docs/models/gemini-3.6-flash) · [3.5 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.5-flash-lite) · [3.1 Flash-Lite](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-flash-lite) · [3.1 Pro Preview](https://ai.google.dev/gemini-api/docs/models/gemini-3.1-pro-preview))
> - [Thinking | Google AI for Developers](https://ai.google.dev/gemini-api/docs/thinking)
> - [Prompt design strategies | Google AI for Developers](https://ai.google.dev/gemini-api/docs/prompting-strategies)
> - [Function calling | Google AI for Developers](https://ai.google.dev/gemini-api/docs/function-calling)
> - [Structured outputs | Google AI for Developers](https://ai.google.dev/gemini-api/docs/structured-output)
> - [Media resolution | Google AI for Developers](https://ai.google.dev/gemini-api/docs/media-resolution)
> - [OpenAI compatibility | Google AI for Developers](https://ai.google.dev/gemini-api/docs/openai)
> - [GenerateContent API reference](https://ai.google.dev/api/generate-content) (`FunctionResponse`·`Part` 자료형)
> - [Gemini 3.7 Flash developer guide | Google Cloud](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-3-7-flash)
>
> **출처 (사용자 보고, 2차)**: [§12](#12-38-flash-사용자-보고) 참조. 작성자 보고이며 독립 재현하지 않았습니다.
>
> **날짜**: 2026-10-01 (모든 공식 URL을 이날 원문으로 확인)
> **자매 가이드**: [Gemma 4](./gemma-4-prompt-guide.md) (Gemini와 별개 제품군인 오픈웨이트 모델)

Gemini 3.x API 모델용 프롬프팅 가이드입니다. 여섯 모델은 공통 프롬프팅 원칙을 공유하지만, **사고 수준·기본값·일부 도구 지원·API 방식별 이력 처리가 모델마다 다릅니다.** 한 파일로 묶되 모델별 계약은 [§2 모델 개요](#2-모델-개요)와 [§4 사고 수준](#4-사고-수준-thinking_level)의 표를 기준으로 적용합니다.

**출처 선택 원칙**: Google 문서 안에도 세대가 섞여 있습니다. 예전 `gemini-3` 가이드는 "모두 프리뷰", "기본 `high`" 같은 낡은 설명이 남아 있고, 일반 프롬프팅 문서의 예시는 Gemini 2.5로 만든 것입니다. 이 가이드는 모델별 페이지·Thinking 표·3.8 가이드를 우선하고, 3.5 가이드는 "all Gemini 3.x models"라고 명시한 절만 3.x 공통으로 씁니다.

## 목차
1. [가장 먼저 알아야 할 것](#1-가장-먼저-알아야-할-것)
2. [모델 개요](#2-모델-개요)
3. [공통 프롬프팅 원칙](#3-공통-프롬프팅-원칙)
4. [사고 수준 (`thinking_level`)](#4-사고-수준-thinking_level)
5. [sampling 파라미터](#5-sampling-파라미터)
6. [API 방식별 계약 (Interactions ↔ GenerateContent)](#6-api-방식별-계약-interactions--generatecontent)
7. [함수 호출](#7-함수-호출)
8. [구조화 출력](#8-구조화-출력)
9. [미디어 해상도](#9-미디어-해상도)
10. [OpenAI 호환 계층](#10-openai-호환-계층)
11. [모델별 메모](#11-모델별-메모)
12. [3.8 Flash 사용자 보고](#12-38-flash-사용자-보고)
13. [마이그레이션 체크리스트](#13-마이그레이션-체크리스트)
14. [요약](#14-요약)

---

## 1. 가장 먼저 알아야 할 것

- **사고는 끌 수 없습니다.** Gemini 3 모델은 추론을 끌 수 없고("Reasoning cannot be turned off for Gemini 2.5 Pro or 3 models"), `minimal`도 끄기가 아닙니다("`minimal` does not guarantee that thinking is off").
- **3.8·3.7 Flash와 3.1 Pro에는 `minimal`이 없습니다.** 보내면 오류입니다. 3.6 Flash와 Flash-Lite 두 모델만 `minimal`을 받습니다.
- **`temperature`·`top_p`·`top_k`는 지웁니다.** 3.x 전체에 대한 공식 권고이고, 3.8 마이그레이션 체크리스트는 "deprecated"로 분류합니다.
- **패키지명으로 제공자를 판정하지 않습니다.** Gemini는 OpenAI 라이브러리로도 호출됩니다("Gemini models are accessible using the OpenAI libraries"). 모델 ID와 `base_url`을 봅니다.
- **API 방식이 모델보다 큰 분기입니다.** 같은 모델이라도 Interactions와 GenerateContent는 필드 경로와 대화 이력 처리 방식이 다릅니다 → [§6](#6-api-방식별-계약-interactions--generatecontent).
- **이름이 비슷한 전용 모델을 섞지 않습니다.** `gemini-3.8-flash-lite-tts`는 음성 생성 모델이고, `gemini-3.1-flash-lite-image`는 이미지 모델입니다. 텍스트 Flash-Lite의 최신판이 아닙니다.

## 2. 모델 개요

여섯 모델 모두 입력 1,048,576 토큰, 출력 65,536 토큰이며, 텍스트·이미지·영상·음성·PDF를 입력받아 텍스트를 출력합니다.

| 모델 ID | 상태 | 사고 수준 (기본값) | 공식 포지션 | 메모 |
|------|------|------|------|------|
| `gemini-3.8-flash` | Stable (2026-09) | `low`·`medium`·`high` (`medium`) | 가장 지능이 높은 Flash. 장기 소프트웨어 엔지니어링·자율 에이전트·복잡한 기업 워크플로 | 소개가 $0.75/$3.75 (2026-12-31까지), 2027-01-01부터 $1.50/$7.50. 컴퓨터 사용 Preview |
| `gemini-3.7-flash` | Stable (2026-08) | `low`·`medium`·`high` (`medium`) | 3.8 가이드가 "remains fully supported"로 명시하는 대안 | `minimal`은 오류 |
| `gemini-3.6-flash` | Stable (2026-07) | `minimal`·`low`·`medium`·`high` (`medium`) | — | 이 범위의 Flash 중 `minimal`을 받는 유일한 모델 |
| `gemini-3.5-flash-lite` | Stable (2026-07) | `minimal`·`low`·`medium`·`high` (`minimal`) | 저지연·저비용. 서브에이전트 작업·문서 파싱·대량 에이전트 워크플로·단순 추출 | 컴퓨터 사용 Preview |
| `gemini-3.1-flash-lite` | Stable (2026-05) | `minimal`·`low`·`medium`·`high` (`minimal`) | 3.5 가이드가 고급 추론이 필요 없는 저비용·대량 작업에 권하는 장기 안정 모델 | 컴퓨터 사용 미지원. Thinking 표에 텍스트 모델 행이 없어 사고 수준은 3.5 가이드의 모델별 열로 확인 |
| `gemini-3.1-pro-preview` | Preview (2026-02) | `low`·`medium`·`high` (`high`) | Gemini 3 Pro 계열의 성능·신뢰성 개선판. 소프트웨어 엔지니어링·에이전트 워크플로 | 파일 검색은 AI Studio 전용. 사용자 정의 도구 우선순위가 다른 `gemini-3.1-pro-preview-customtools` 변형이 따로 있음 |

`gemini-3.5-flash`는 이 가이드의 범위 밖이지만 공급자 기준으로는 여전히 안정판입니다. 범위에서 뺀 것을 폐기로 표현하지 않습니다.

## 3. 공통 프롬프팅 원칙

3.5 가이드는 "Gemini 3.x models are reasoning models, which changes how you should prompt"라고 전제합니다.

| 원칙 | 내용 | 원문 |
|------|------|------|
| **간결하고 직접적인 지시** | 구모델용 장황하거나 복잡한 프롬프트 기법은 과잉 분석을 부를 수 있음 | "Gemini 3.x responds best to direct, clear instructions" |
| **일관된 구조** | XML식 태그(`<context>`, `<task>`)나 Markdown 헤더로 부분을 나누되, 한 프롬프트 안에서는 한 형식만 | "Choose one format and use it consistently within a single prompt" |
| **핵심 지시는 앞에** | 행동 제약·역할·출력 형식은 시스템 지시나 사용자 프롬프트 맨 앞에 | "Place essential behavioral constraints, role definitions (persona), and output format requirements in the System Instruction or at the very beginning of the user prompt" |
| **긴 자료는 앞, 질문은 끝** | 큰 자료를 먼저 주고 구체적 지시·질문은 맨 끝에, 전환 문구로 연결 | "place your specific instructions or questions at the end of the prompt, after the data context" / "Based on the preceding information..." |
| **출력 길이** | 기본은 덜 장황하고 직접적. 대화체나 상세한 답이 필요하면 명시적으로 요청 | "Explain this as a friendly, talkative assistant" |
| **모호한 용어 정의** | 해석이 갈리는 용어·파라미터를 명시적으로 설명 | "Explicitly explain any ambiguous terms or parameters" |
| **멀티모달 동등 취급** | 텍스트·이미지·음성·영상을 동급 입력으로 보고, 지시에서 각 모달리티를 분명히 지칭 | "treat them as equal-class inputs" |

**추론을 답에 쓰게 하지 않습니다.** 모델이 내부 사고를 만들므로 계획이나 추론 단계를 응답에 쓰게 할 필요가 대체로 없습니다. 어려운 추론 문제에서는 "Think very hard before answering" 같은 짧은 요청이 사고 토큰을 더 쓰는 대신 성능을 올릴 수 있습니다. Gemini 2.5에서 추론을 강제하던 CoT 프롬프트는 단순한 프롬프트 + `thinking_level` `medium`·`high`로 바꾸는 것이 3.5 마이그레이션 권고입니다.

**Google 문서끼리 어긋나는 두 곳**:

- 일반 프롬프팅 문서는 "We recommend to always include few-shot examples in your prompts"라고 하지만, 그 문서의 예시는 Gemini 2.5로 만든 것이고 같은 문서도 예시가 너무 많으면 과적합한다고 경고합니다. 예시의 필요 여부와 개수는 과제별 평가로 정하고, 넣는다면 형식(XML 태그·공백·줄바꿈·구분자)을 모든 예시에서 똑같이 맞춥니다.
- 같은 문서의 "Gemini 3" 템플릿은 사용자 프롬프트 끝에 "Remember to think step-by-step before answering."을 넣지만, 더 최근 문서인 3.5 마이그레이션은 추론 강제 프롬프트를 단순화하라고 권합니다. 사고량은 `thinking_level`로 먼저 조절합니다.

**에이전트 행동 축**: 일반 프롬프팅 문서는 에이전트 프롬프트에서 조절할 축을 세 묶음으로 제시합니다. 추론·전략(논리 분해, 문제 진단, 정보 망라 정도), 실행·신뢰성(계획 고수와 즉시 전환, 자기 교정 끈기, 읽기와 쓰기의 위험 구분), 상호작용·출력(가정과 질문의 경계, 도구 호출 사이 설명량, 정밀도)입니다. 공식 시스템 지시 템플릿(9개 항목, 복잡한 규칙집을 따르는 에이전트 벤치마크에서 평가)은 [원문](https://ai.google.dev/gemini-api/docs/prompting-strategies#system-instruction-template)을 봅니다. 모든 에이전트에 그대로 붙이지 말고, 실패 축에 해당하는 항목만 가져다 평가합니다.

## 4. 사고 수준 (`thinking_level`)

| 모델 | 허용 값 | 기본값 |
|------|------|------|
| 3.8 Flash | `low`, `medium`, `high` | `medium` |
| 3.7 Flash | `low`, `medium`, `high` | `medium` |
| 3.6 Flash | `minimal`, `low`, `medium`, `high` | `medium` |
| 3.5 Flash-Lite | `minimal`, `low`, `medium`, `high` | `minimal` |
| 3.1 Flash-Lite | `minimal`, `low`, `medium`, `high` | `minimal` |
| 3.1 Pro Preview | `low`, `medium`, `high` | `high` |

**레벨 선택** (3.8 가이드와 3.5 가이드의 설명):

| 레벨 | 용도 |
|------|------|
| `minimal` | 응답 속도 최적화. 채팅형, 빠른 사실 답변, 단순 도구 호출 (받는 모델만) |
| `low` | 지연이 중요한 작업(사고 대응 파이프라인, 실시간 채팅, 초안 작성, 빠른 데이터 분석), 단계가 적은 코드·에이전트 작업 |
| `medium` | 대부분의 작업에서 최고 품질. 복잡한 코드·에이전트 작업에 권장 |
| `high` | 추론과 도구 오케스트레이션 최대화. 깊은 추론, 수학, 어려운 다단계 작업 |

- `thinking_budget`(숫자)은 하위 호환으로 남아 있지만 권장하지 않습니다. `thinking_level`과 한 요청에 함께 넣지 않습니다.
- `max_output_tokens`에는 사고 토큰이 포함됩니다("including thought tokens"). 사고 중에 한도에 닿으면 상태 `"incomplete"`로 멈추고 잘리거나 빈 출력을 돌려주며, 이미 생성한 사고 토큰은 과금됩니다. 비용·지연을 줄이려면 `max_output_tokens`를 작게 잡지 말고 `thinking_level`을 낮춥니다.
- 사고 요약은 실패 원인 분석과 프롬프트 개선에 씁니다(Thinking 문서의 모범 사례).

## 5. sampling 파라미터

3.5 가이드: "`temperature`, `top_p`, and `top_k` are no longer recommended for all Gemini 3.x models. Gemini 3's reasoning capabilities are optimized for the default settings. **Remove these parameters from all requests.**"

- 결정성이 필요하면 sampling 대신 사용 사례별 명시적 규칙을 시스템 지시에 씁니다(공식 권고).
- 서비스별 표현이 다릅니다. Developer API 문서는 "no longer recommended"(3.8 체크리스트는 "deprecated"), Google Cloud의 3.7 가이드는 `frequency_penalty`·`presence_penalty`·`candidate_count`·`temperature`·`top_p`·`top_k`를 "unsupported parameters"로 분류합니다. 어느 쪽이든 새 요청에서는 빼고, 400을 반환하는지는 모델·서비스별로 확인하지 않았으므로 단정하지 않습니다.
- `candidate_count`는 Gemini 3.x에서 지원하지 않습니다.

## 6. API 방식별 계약 (Interactions ↔ GenerateContent)

최신 공식 예제는 Interactions API(`client.interactions.create`)를 기본으로 씁니다. GenerateContent(`client.models.generate_content`)도 계속 지원되며, 두 방식은 필드 경로와 이력 처리가 다릅니다. 프롬프트를 쓰기 전에 대상 코드가 어느 방식인지 확인합니다.

| 항목 | Interactions | GenerateContent |
|------|------|------|
| 시스템 지시 | `system_instruction` | `system_instruction`(SDK 설정) / `systemInstruction`(REST) |
| 사고 수준 | `generation_config.thinking_level` | Python SDK `config.thinking_config.thinking_level` (`types.ThinkingConfig(thinking_level="high")`) / REST `generationConfig.thinkingConfig.thinkingLevel` |
| 대화 이력 | 상태 저장 모드 권장: `store: true` + 다음 턴에 `previous_interaction_id`. 서버가 이력·사고 블록·서명을 관리 | 전체 이력을 직접 보냄. 사고 서명(`Part.thoughtSignature`)이 담긴 원래 부분을 수정 없이 유지 (SDK가 자동 처리) |
| 직접 이력 관리 | 무상태 모드에서는 모든 `thought` 블록을 "exactly as they were received" 다시 보냄. 세션 중 모델을 바꿔도 이전 모델의 블록을 보냄. Google 검색 같은 내장 도구 결과의 서명도 보존 | 3.5 이후 모델은 서명이 있으면 이전 모든 턴의 추론 문맥을 씀 |
| 함수 결과 짝 맞추기 | 짝이 안 맞으면 오류 | 오류는 안 나지만 대부분 빈 응답 + `finish_reason: STOP` |
| 구조화 출력 | `response_format` | `response_mime_type` + `response_json_schema` |

- **사고 서명은 프롬프트로 대신할 수 없습니다.** 추론 연속성을 유지하는 암호화된 상태라서, 응답 본문에 사고 과정을 쓰게 하는 지시로 대체되지 않습니다.
- **미리 채운 model 턴은 지웁니다.** 3.8 마이그레이션 체크리스트("Remove prefilled model turns")와 Cloud 3.7 가이드가 요구합니다. 형식 강제는 구조화 출력으로 합니다.
- **멀티턴은 서버 측 이력으로 표준화하라는 것**이 3.8 체크리스트의 권고입니다("Standardize multi-turn conversations on server-side `previous_interaction_id`").

## 7. 함수 호출

**도구 선택 모드** (Interactions `generation_config.tool_choice`): `auto`(기본), `any`(항상 함수 호출), `none`(호출 금지), `validated`(스키마 준수). Claude Opus 5.5·Fable 5.1·Sonnet 5.5의 강제 `tool_choice` 금지 규칙을 Gemini로 옮기지 않습니다.

**함수 결과 계약** (3.x 전체):

| 요구 | 내용 |
|------|------|
| 호출 식별자 | API마다 필드가 다름. GenerateContent는 모든 `FunctionResponse`에 대응 `FunctionCall`의 `id`, Interactions는 `function_result`의 `call_id`에 호출 단계의 `id` 값 |
| `name` 일치 | 결과의 `name`이 호출의 `name`과 같음 |
| 개수 일치 | 받은 호출 하나마다 결과 정확히 하나 |
| 멀티모달 결과 | 이미지 등은 함수 결과 바깥이 아니라 안에 넣음. 바깥에 두면 사고 누출 같은 예기치 않은 동작과 품질 저하 |
| 추가 지시 | 별도 `Part`로 붙이지 말고 함수 결과 텍스트 끝에 빈 줄 두 개(`\n\n`)로 구분해 덧붙임 |

> ⚠️ **문서 불일치**: 3.8 가이드는 "Only if using generateContent API: Ensure all `FunctionResponse` objects include `call_id` and `name`"이라고 쓰지만, GenerateContent REST 자료형의 `FunctionResponse`는 `id`·`name`·`response`를 정의하고 3.5 가이드도 `id`라고 씁니다. Cloud 3.7 가이드는 "`id` or `call_id`"로 적습니다. GenerateContent 코드는 자료형 기준 `id`를 쓰고, Interactions의 `call_id`와 섞지 않습니다. 실제 요청으로 검증하지는 않았습니다.

**도구 호출 직전 구조화 텍스트 강제 금지**: 프롬프트가 도구 호출 바로 앞에 XML·YAML·JSON 텍스트(예: `<UPDATE>...</UPDATE>`)를 내게 하면 도구 호출이 가끔 `Malformed_Function_Call`로 실패합니다. 공식 해결책은 셋입니다.

1. **권장**: 작업 메모를 전용 `update()` 함수 호출에 담게 합니다. 공식 지시문과 함수 선언 예시:

```text
Before calling any other tool, in every response you MUST first call `update` with all required parameters (previous_step, plan, next_step, external).
```

2. 메모를 구조화 텍스트 대신 Markdown 헤더(`# UPDATE`, `## PLAN`)로 쓰게 합니다.
3. 도구 호출 전에 텍스트를 내도록 요구하지 않습니다.

XML 태그 자체를 금지할 근거는 없습니다. 문제가 되는 것은 도구 호출 직전 출력에 구조화 텍스트를 강제하는 경우입니다.

**불필요한 도구 호출 줄이기**: 먼저 사고 수준을 낮춥니다(높을수록 탐색·검증용 도구를 더 씀). 그래도 많으면 시스템 지시로 제한합니다. 공식 예시:

```text
You have a limited action budget of <n> tool calls. Use them efficiently.
```

## 8. 구조화 출력

- 여섯 모델 모두 함수 호출과 구조화 출력을 지원합니다. 최종 JSON 응답과 실제 도구 호출은 별개이므로 평가도 따로 합니다.
- 구조화 출력과 내장 도구(Google 검색, URL 컨텍스트, 코드 실행, 함수 호출)를 함께 쓰는 기능은 Gemini 3 계열 전용이고 Preview입니다.
- JSON Schema의 지원 하위 집합을 씁니다. 문법이 맞아도 값의 타당성은 애플리케이션에서 검증합니다("always validate values in your application").
- 프롬프트에는 "선택한 API의 구조화 출력 기능을 쓴다"는 원칙만 두고, 스키마를 프롬프트 본문에 중복해 설명하지 않습니다.

## 9. 미디어 해상도

Gemini 3는 콘텐츠 항목별로 해상도를 지정할 수 있습니다("Per-content-item media resolution (Gemini 3 only)").

| 입력 | 공식 권장 | 토큰 (대략) | 메모 |
|------|------|------|------|
| 이미지 | `high` | 1,120 | 대부분의 이미지 분석 |
| PDF | `medium` | 560 + 원문 텍스트 | 문서 이해는 대개 `medium`에서 포화. `high`로 올려도 일반 문서 OCR은 거의 개선되지 않음 |
| 영상 (일반) | `low`(또는 `medium`) | 프레임당 70 | 영상에서는 `low`와 `medium`이 같음 |
| 영상 (글자 많음) | `high` | 프레임당 280 | 프레임 속 조밀한 글자·작은 세부를 읽을 때만 |
| 음성 | 기본값 | 초당 25 | 해상도 설정과 무관하게 고정 |
| 세밀한 화면 | `ultra_high` (이미지만) | 2,240 | 컴퓨터 사용 등. 평가 후 항목별로 |

해상도 토큰 수는 입력 미디어 토큰화 기준입니다. 컨텍스트 전체 한도나 영상 처리 비용 전체와 혼동하지 않습니다. Gemini 2.5에서 옮겨 오면 기본값만으로도 PDF 토큰은 늘고 영상 토큰은 줄 수 있습니다.

## 10. OpenAI 호환 계층

`base_url="https://generativelanguage.googleapis.com/v1beta/openai/"`로 OpenAI 라이브러리에서 Gemini를 호출할 수 있습니다. 이 경우에도 적용할 가이드는 GPT가 아니라 Gemini입니다.

- `reasoning_effort` 대응표는 3.1 Pro·3.1 Flash-Lite·3 Flash(·2.5) 열만 공식 문서에 있습니다. 3.1 Pro는 `minimal`·`low`가 모두 `low`로, 3.1 Flash-Lite는 같은 이름으로 대응합니다. 3.6~3.8 Flash의 대응은 문서에 없으므로 추측하지 않습니다.
- 사고 수준은 `extra_body`의 `google.thinking_config.thinking_level`로도 보낼 수 있고(공식 예제는 `gemini-3.8-flash`), `reasoning_effort`와 `thinking_level`은 기능이 겹쳐 한 요청에 함께 쓸 수 없습니다.
- `reasoning_effort: "none"`으로 사고를 끄는 것은 2.5 모델만 됩니다. Gemini 3는 끌 수 없습니다.

## 11. 모델별 메모

**3.8 Flash**: 길고 복잡한 작업에서 설계상 토큰을 더 씁니다. 공식 설명은 "the model takes smaller reasoning steps, calls tools iteratively, and verifies its work along the way"이고, 모든 워크플로에 이 수준의 검증이 필요하지는 않으니 일상 작업은 사고 수준을 낮추거나 3.7 Flash를 쓰라고 권합니다. 모든 작업에 `high`를 줄 근거는 없습니다. Gemini Managed Agents의 기본 에이전트(Antigravity)와 Antigravity SDK의 기본 모델입니다.

**3.7 Flash**: 3.8과 같은 사고 수준 체계(`minimal` 없음, 기본 `medium`)입니다. 3.8의 토큰 증가가 부담인 일상 워크플로의 공식 대안입니다.

**3.6 Flash**: 이 범위의 Flash 중 `minimal`을 받는 유일한 모델입니다. 3.6용 설정을 3.7·3.8로 옮길 때 `minimal`을 `low`로 바꿉니다.

**3.5 Flash-Lite**: 기본 사고 수준이 `minimal`입니다. 서브에이전트, 문서 파싱, 단순 추출처럼 지연과 비용이 우선인 대량 작업용입니다. Flash 프롬프트를 그대로 옮기면 사고량이 크게 다르므로, 품질이 부족하면 `low`부터 올려 봅니다.

**3.1 Flash-Lite**: 고급 추론이 필요 없는 저비용·대량 작업용 장기 안정 모델입니다. 컴퓨터 사용을 지원하지 않습니다. 공식 용도 설명을 독립 성능 평가로 쓰지 않습니다.

**3.1 Pro Preview**: 기본 사고 수준이 `high`로 Flash 계열과 다르고 `minimal`이 없습니다. 프리뷰라서 안정판 수준의 유지 보장을 가정하지 않습니다. 사용자 정의 도구를 주로 쓰는 에이전트는 `gemini-3.1-pro-preview-customtools` 변형("better at prioritizing your custom tools")이 따로 있으니, 이 변형을 쓰면 별도 ID로 다룹니다.

## 12. 3.8 Flash 사용자 보고

아래는 작성자 본인의 관찰·설정·재현 절차가 있는 게시글만 골랐습니다. 대표 표본이 아니므로 전체 사용자 경험이나 보편적 회귀로 일반화하지 않고, 프롬프트 계약을 바꾸는 근거로 쓰지 않습니다. 포럼 글 세 건은 2026-10-01에 원문을 다시 대조했습니다.

| 보고 | 조건 | 적용 판단 |
|------|------|------|
| [기본 `medium`이 대부분의 에이전트 워크플로에 적합](https://www.reddit.com/r/GeminiAI/comments/1w7bldp/you_should_probably_set_gemini_38_flash_thinking/) ("3.8 Flash Medium is the clear sweet spot") | 일상 작업에서 `high`의 추가 탐색이 비용·지연을 늘린다는 평가 | 공식 기본값과 방향이 같다는 정도로만 활용 |
| [짧은 작업에서 성능 향상이 뚜렷](https://www.reddit.com/r/google_antigravity/comments/1w5i29e/review_of_gemini_38_flash_from_a_person_who/) ("Shorter tasks get a really visible capability bump") | 약 한 시간, `high`, 명세가 불충분한 저장소 작업. 장기 완전 자율 작업에는 주의가 필요하다고 함 | 통제 실험이 아님. "3.8은 과잉 사고로 나빠졌다"는 단일 결론의 반례일 뿐 |
| [파일 검색을 붙이면 첫 텍스트까지 7~8초](https://discuss.ai.google.dev/t/gemini-3-8-flash-file-search-7-8s-ttft-with-low-thinking-timing-breakdown/185764) (2026-09-28) | Interactions 스트리밍, `low`, 파일 검색. 첫 텍스트 7,317·7,078·7,231ms, 조건별 5회 중앙값은 도구 없음 2.195초·파일 검색 6.874초 | 완료 시간이 아니라 첫 텍스트까지의 시간. 지연 평가에서 사고 수준·도구·API·첫 텍스트·완료 시간을 나눠 측정 |
| [1인칭 회상 문맥이 있으면 저장 선택이 줄어듦](https://discuss.ai.google.dev/t/gemini-3-8-flash-tool-calls-are-suppressed-when-the-prompt-contains-reflective-first-person-text-regression-vs-3-5/180934) (2026-09-05) | 재현이 `response_json_schema`의 필드로 저장 여부를 고르게 한 것이고 "no tools / function calling in the repro" | 실제 함수 호출이 망가진다는 근거가 아님. 결과 JSON의 작업 선택과 실제 함수 호출을 별개 평가 항목으로 |
| [사고+응답 합계가 `maxOutputTokens`의 약 2배](https://discuss.ai.google.dev/t/gemini-3-8-flash-high-does-maxoutputtokens-include-thinking-tokens/181077/4) (2026-09-25 후속 댓글) | GenerateContent, `low`, `maxOutputTokens=512`, 도구·시스템 지시 없음. 3.8은 5회 모두 997~1,003, 3.7은 5회 중 2회 초과 | 공식 명세("including thought tokens")와 구현 보고의 미해결 불일치. 비용 상한을 `max_output_tokens`로 보장한다고 가정하지 않음 |
| [사용자 지정 Gem이 지시를 무시](https://www.reddit.com/r/GeminiAI/comments/1wr2elg/gemini_38_flash_feels_a_bit_off/) | Gemini 앱. API 모델 ID·설정·비교 입력 없음 | 앱과 API를 구분해야 한다는 사례로만 |

## 13. 마이그레이션 체크리스트

**3.7·3.6 Flash → 3.8 Flash** (3.8 가이드)
- [ ] 모델 ID를 `gemini-3.8-flash`로
- [ ] `temperature`·`top_p`·`top_k` 제거, `thinking_budget` → `thinking_level` (`minimal`은 오류이므로 3.6에서 쓰던 값은 `low`로)
- [ ] `candidate_count` 제거
- [ ] 멀티턴은 서버 측 `previous_interaction_id`로 표준화, 미리 채운 model 턴 제거
- [ ] 함수 호출 감사: 멀티모달은 결과 안에, 추가 지시는 `\n\n`으로, 도구 전 텍스트로 `Malformed_Function_Call`이 나면 [§7](#7-함수-호출)의 우회책
- [ ] 토큰 사용 재측정: 길고 복잡한 작업에서 설계상 더 씀. 일상 작업은 `low`나 3.7 Flash 검토
- [ ] SDK 갱신과 사고 서명 보존은 3.5 마이그레이션 체크리스트가 기준 (Python은 `google-genai` v2.0.0 이상 권장, Interactions API 파괴적 변경 포함)

**Flash → Flash-Lite로 내릴 때**
- [ ] 기본 사고 수준이 `minimal`로 바뀜을 인지하고 품질 평가
- [ ] 3.1 Flash-Lite는 컴퓨터 사용 미지원

**Gemini 2.5 → 3.x** (3.5 가이드, 위 항목에 더해)
- [ ] 추론 강제 CoT 프롬프트를 단순화하고 `thinking_level`로 조절
- [ ] PDF·미디어 워크로드 재시험 (해상도 기본값이 바뀌어 PDF 토큰 증가·영상 토큰 감소 가능)
- [ ] 이미지 분할(segmentation)은 3.x 미지원

## 14. 요약

| 축 | 처방 |
|------|------|
| **확정할 것** | 정확한 모델 ID + API 방식(Interactions·GenerateContent·OpenAI 호환) |
| **프롬프트** | 간결·직접, 형식 하나로 일관, 핵심 지시는 앞, 긴 자료 뒤에 질문 |
| **사고** | 끌 수 없음. 모델별 허용 값 확인(`minimal`은 3.6 Flash·Flash-Lite만), 비용은 `max_output_tokens`보다 `thinking_level`로 |
| **sampling** | 3.x 전체에서 제거 |
| **이력** | 사고 서명·블록을 받은 그대로 유지, 미리 채운 model 턴은 새 프롬프트에서 쓰지 않음(제거 권고는 3.8·Cloud 3.7) |
| **도구** | 호출 식별자(GenerateContent `id`, Interactions `call_id`)·`name`·개수 일치, 도구 직전 구조화 텍스트 강제 금지 → `update()` 함수 |
| **미디어** | 이미지 `high`, PDF `medium`, 영상 `low`(글자 많으면 `high`) |
