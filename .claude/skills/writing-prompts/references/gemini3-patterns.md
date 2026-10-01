# Gemini 3.x 프롬프트 패턴

대상 모델: `gemini-3.8-flash` · `gemini-3.7-flash` · `gemini-3.6-flash` · `gemini-3.5-flash-lite` · `gemini-3.1-flash-lite` · `gemini-3.1-pro-preview`

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [1. 모델별 계약](#1-모델별-계약)
- [2. 공통 프롬프팅 원칙](#2-공통-프롬프팅-원칙)
- [3. 사고 수준과 출력 한도](#3-사고-수준과-출력-한도)
- [4. API 방식별 계약](#4-api-방식별-계약)
- [5. 함수 호출·구조화 출력](#5-함수-호출구조화-출력)
- [6. 미디어 해상도](#6-미디어-해상도)
- [7. 주의](#7-주의)
- [참고](#참고)

> 여섯 모델은 공통 프롬프팅 원칙을 공유하지만 사고 수준·기본값·일부 도구 지원이 모델마다 다르고, 같은 모델도 API 방식(Interactions·GenerateContent·OpenAI 호환)에 따라 필드 경로와 이력 처리가 다르다. 공통 절과 대상 모델의 행만 적용한다. Gemma(오픈웨이트)는 별개 제품군이므로 [gemma4-patterns.md](gemma4-patterns.md)를 쓴다.
>
> 본 문서는 패턴 요약. 풀 가이드: [`reference/google-prompt-guide/gemini-3-prompt-guide.md`](../../../../reference/google-prompt-guide/gemini-3-prompt-guide.md)

---

## 작성 체크리스트

- [ ] **모델 ID와 API 방식 확정**: 정확한 ID를 [§1](#1-모델별-계약) 표에서 찾는다. `-tts`·`-image`·`-customtools` 변형은 텍스트 모델과 같은 대상으로 보지 않는다. OpenAI SDK로 호출해도(`base_url`이 Google) Gemini 규칙을 적용한다
- [ ] **간결·직접 지시**: 구모델용 장황한 기법과 추론 강제 CoT 문구는 빼고, 사고량은 `thinking_level`로 조절한다
- [ ] **구조 표기 하나로 일관**: XML식 태그나 Markdown 헤더 중 하나만 쓴다. 핵심 제약·역할·출력 형식은 시스템 지시나 프롬프트 맨 앞에 둔다
- [ ] **긴 자료는 앞, 질문은 끝**: 자료 뒤에 "Based on the preceding information..." 같은 전환 문구로 질문을 잇는다
- [ ] **출력 길이 명시**: 기본이 간결하므로 대화체·상세 답이 필요하면 명시적으로 요청한다
- [ ] **사고 수준은 모델이 받는 값만**: `minimal`은 3.6 Flash·두 Flash-Lite만 받는다. `minimal`을 사고 끄기로 설명하지 않는다(Gemini 3는 사고를 끌 수 없음)
- [ ] **sampling 제거**: `temperature`·`top_p`·`top_k`를 넣지 않는다. 결정성이 필요하면 시스템 지시에 명시적 규칙을 쓴다
- [ ] **미리 채운 model 턴을 쓰지 않음**: 형식 강제는 구조화 출력으로 한다. 기존 프롬프트에서 지우라는 명시적 권고는 3.8 체크리스트와 Cloud 3.7 가이드에 있다
- [ ] **도구 직전 구조화 텍스트 강제 금지**: `<UPDATE>` 같은 XML·JSON을 도구 호출 바로 앞에 내게 하지 않는다 → 메모는 `update()` 함수나 Markdown 헤더로
- [ ] **함수 결과 계약**: 선택한 API의 호출 식별자와 `name`을 결과에 그대로 대응시키고 호출 하나에 결과 하나(GenerateContent는 `FunctionResponse`의 `id`, Interactions는 `function_result`의 `call_id`) → [§4](#4-api-방식별-계약)·[§5](#5-함수-호출구조화-출력). 멀티모달은 결과 안에, 추가 지시는 결과 텍스트 끝에 `\n\n`으로
- [ ] **이력 보존**: 사고 블록·서명은 받은 그대로 다시 보내고, 지시 변경을 위해 이력을 고쳐 쓰지 않는다
- [ ] **예시**: 필요 여부와 개수는 과제별 평가로 정하고, 넣으면 모든 예시의 형식을 똑같이 맞춘다

---

## 1. 모델별 계약

공통: 입력 1,048,576 / 출력 65,536 토큰, 텍스트·이미지·영상·음성·PDF 입력 → 텍스트 출력, 함수 호출·구조화 출력 지원.

| 모델 ID | 상태 | 사고 수준 (기본값) | 특이사항 |
|------|------|------|------|
| `gemini-3.8-flash` | Stable | `low`·`medium`·`high` (`medium`) | 길고 복잡한 작업에서 설계상 토큰을 더 씀(작은 추론 단계·반복 도구 호출·중간 검증). 일상 작업은 `low`나 3.7 Flash가 공식 대안. 컴퓨터 사용 Preview |
| `gemini-3.7-flash` | Stable | `low`·`medium`·`high` (`medium`) | `minimal`은 오류 |
| `gemini-3.6-flash` | Stable | `minimal`·`low`·`medium`·`high` (`medium`) | 3.7·3.8로 옮길 때 `minimal`은 `low`로 |
| `gemini-3.5-flash-lite` | Stable | `minimal`·`low`·`medium`·`high` (`minimal`) | 서브에이전트·문서 파싱·단순 추출 등 대량 저지연 작업. 컴퓨터 사용 Preview |
| `gemini-3.1-flash-lite` | Stable | `minimal`·`low`·`medium`·`high` (`minimal`) | 고급 추론이 필요 없는 저비용 대량 작업. 컴퓨터 사용 미지원 |
| `gemini-3.1-pro-preview` | Preview | `low`·`medium`·`high` (`high`) | 기본 사고 수준이 Flash와 다름. 파일 검색은 AI Studio 전용. `-customtools` 변형은 별도 ID |

이 범위 밖의 `gemini-3.5-flash`도 공급자 기준으로는 안정판이다. 지원 목록에서 뺀 것을 폐기로 표현하지 않는다.

---

## 2. 공통 프롬프팅 원칙

[공식, whats-new-gemini-3.5 "Prompting best practices" · prompting-strategies "Gemini 3"]

- "Gemini 3.x responds best to direct, clear instructions." 구모델용 복잡한 기법은 과잉 분석을 부를 수 있다
- 구분자는 XML식 태그(`<context>`, `<task>`)나 Markdown 헤더. "Choose one format and use it consistently within a single prompt."
- 핵심 행동 제약·역할·출력 형식은 시스템 지시나 사용자 프롬프트 맨 앞
- 큰 자료(책·코드베이스·긴 영상) 뒤에 구체적 지시·질문을 두고 전환 문구로 연결
- 기본 출력이 간결하다. 대화체가 필요하면 "Explain this as a friendly, talkative assistant"처럼 명시
- 계획·추론 단계를 응답에 쓰게 할 필요는 대체로 없다. 어려운 추론에는 "Think very hard before answering" 정도가 사고 토큰을 더 쓰는 대신 성능을 올릴 수 있다

**Google 문서끼리 어긋나는 곳**: 일반 프롬프팅 문서는 few-shot 예시를 "always" 넣으라고 하고 Gemini 3 템플릿 끝에 "Remember to think step-by-step before answering."을 둔다. 그러나 이 문서의 예시는 Gemini 2.5 기준이고, 더 최근인 3.5 마이그레이션은 추론 강제 프롬프트를 단순화하라고 권한다. 모델별 가이드(3.5·3.8)를 우선한다.

---

## 3. 사고 수준과 출력 한도

| 레벨 | 용도 |
|------|------|
| `minimal` | 응답 속도. 채팅형, 빠른 사실 답변, 단순 도구 호출 (받는 모델만) |
| `low` | 지연이 중요한 작업, 단계가 적은 코드·에이전트 작업 |
| `medium` | 대부분의 작업에서 최고 품질, 복잡한 코드·에이전트 작업 권장 |
| `high` | 깊은 추론, 수학, 어려운 다단계 작업 |

- `thinking_budget`은 하위 호환일 뿐 권장하지 않는다. `thinking_level`과 함께 보내지 않는다
- `max_output_tokens`는 사고 토큰을 포함한다. 사고 중 한도에 닿으면 `"incomplete"`로 잘리거나 빈 출력이 오고 사고 토큰은 과금된다 → 비용은 `max_output_tokens`보다 `thinking_level`로 줄인다
- 불필요한 도구 호출이 많으면 사고 수준을 먼저 낮추고, 그래도 많으면 시스템 지시로 제한한다: "You have a limited action budget of <n> tool calls. Use them efficiently."

---

## 4. API 방식별 계약

| 항목 | Interactions | GenerateContent |
|------|------|------|
| 시스템 지시 | `system_instruction` | SDK `system_instruction` / REST `systemInstruction` |
| 사고 수준 | `generation_config.thinking_level` | `thinking_config.thinking_level` / REST `generationConfig.thinkingConfig.thinkingLevel` |
| 이력 | 상태 저장(`store: true` + `previous_interaction_id`) 권장, 서버가 서명 관리. 무상태면 `thought` 블록을 받은 그대로 재전송 | 사고 서명이 담긴 원래 부분을 수정 없이 재전송 (SDK 자동) |
| 함수 결과 짝 불일치 | 오류 | 대부분 빈 응답 + `finish_reason: STOP` |
| 구조화 출력 | `response_format` | `response_mime_type` + `response_json_schema` |

- 3.8 체크리스트는 멀티턴을 서버 측 `previous_interaction_id`로 표준화하고 미리 채운 model 턴을 지우라고 요구한다
- OpenAI 호환 계층: `reasoning_effort` 대응표는 3.1 Pro·3.1 Flash-Lite·3 Flash 열만 공식 문서에 있다(3.1 Pro는 `minimal`도 `low`로 대응). 3.6~3.8의 대응은 추측하지 않고, `extra_body`의 `google.thinking_config.thinking_level`로 보낸다. `reasoning_effort`와 함께 쓰지 않는다

---

## 5. 함수 호출·구조화 출력

- 도구 선택 모드: `auto`(기본)·`any`·`none`·`validated`. Claude Opus 5.5·Fable 5.1·Sonnet 5.5의 강제 `tool_choice` 금지를 옮기지 않는다
- 함수 결과: 호출 하나에 결과 하나, 같은 `name`. 식별자 필드는 API마다 다르다. GenerateContent `FunctionResponse`는 대응 호출의 `id`를 넣고, Interactions `function_result`는 호출 단계의 `id` 값을 `call_id`에 넣는다. 3.8 가이드의 GenerateContent용 "`call_id` and `name`" 문장은 자료형과 어긋나므로 두 필드를 섞지 않는다
- 멀티모달 결과는 함수 결과 안에, 추가 지시는 별도 `Part`가 아니라 결과 텍스트 끝에 `\n\n`으로. 어기면 사고 누출 같은 예기치 않은 동작이 생긴다
- 도구 호출 직전 구조화 텍스트 강제 → `Malformed_Function_Call`. 공식 권장 우회는 메모용 `update()` 함수:

```text
Before calling any other tool, in every response you MUST first call `update` with all required parameters (previous_step, plan, next_step, external).
```

- 구조화 출력 + 내장 도구 병용은 Gemini 3 전용 Preview. 문법이 맞아도 값은 애플리케이션에서 검증한다
- 결과 JSON의 작업 선택과 실제 함수 호출은 별개 평가 항목이다

---

## 6. 미디어 해상도

| 입력 | 권장 | 토큰 |
|------|------|------|
| 이미지 | `high` | 1,120 |
| PDF | `medium` (대개 여기서 포화) | 560 + 원문 텍스트 |
| 영상 일반 | `low` (`medium`과 같음) | 프레임당 70 |
| 영상 글자 많음 | `high` | 프레임당 280 |
| 음성 | 기본값 (고정) | 초당 25 |
| 세밀한 화면 | `ultra_high` (이미지만, 평가 후) | 2,240 |

---

## 7. 주의

[사용자 보고, 2차 — 풀 가이드 §12]

- 3.8 Flash에서 파일 검색을 붙이면 첫 텍스트까지 7~8초라는 재현 보고가 있다. 지연 평가에서 사고 수준·도구·API·첫 텍스트·완료 시간을 나눠 측정한다
- GenerateContent에서 사고+응답 합계가 `maxOutputTokens`의 약 2배였다는 보고가 있다(공식 명세와 미해결 불일치). 비용 상한을 `max_output_tokens`로 보장한다고 가정하지 않는다
- Gemini 앱(Gem)의 지시 무시 불만은 API 모델·설정 비교가 없어 API 프롬프트 계약을 바꿀 근거가 아니다

---

## 참고

- [Gemini 3.x 풀 가이드 (한국어)](../../../../reference/google-prompt-guide/gemini-3-prompt-guide.md)
- [Gemini 3.8 Flash — Latest model (공식)](https://ai.google.dev/gemini-api/docs/latest-model)
- [What's new in Gemini 3.5 Flash (공식)](https://ai.google.dev/gemini-api/docs/whats-new-gemini-3.5) — 3.x 공통 파라미터·프롬프팅 절
- [Models (공식)](https://ai.google.dev/gemini-api/docs/models)
- [Thinking (공식)](https://ai.google.dev/gemini-api/docs/thinking)
- [Prompt design strategies (공식)](https://ai.google.dev/gemini-api/docs/prompting-strategies)
- [Function calling (공식)](https://ai.google.dev/gemini-api/docs/function-calling)
- [Structured outputs (공식)](https://ai.google.dev/gemini-api/docs/structured-output)
- [Media resolution (공식)](https://ai.google.dev/gemini-api/docs/media-resolution)
- [OpenAI compatibility (공식)](https://ai.google.dev/gemini-api/docs/openai)
