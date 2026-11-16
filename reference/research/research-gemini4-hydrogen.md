# Gemini 4 Hydrogen 조사 — 공식 자료, agy 반영과 압축 한도 기록, dotfiles 판단 (2026-11-16, 출시 4일)

> 조사 방식: Google 공식 문서 13쪽을 헤드리스 Chromium으로 받아 본문을 직접 읽고 인용 문장을 대조했습니다. AI Studio 가격표는 탭 뒤 내용이 렌더링된 화면에 없어 원본 HTML로 확인했습니다. agy 쪽은 이 장비의 CLI 1.5.9(Google AI Pro 계정)에서 실측했습니다.
> 문서 역할: Hydrogen의 사실, agy에서 달라진 점, dotfiles 판단을 기록합니다. 모델 사용 계약과 프롬프트 선택은 `reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`가 정본입니다.
> 시점: 2026-11-16에 수집하고 대조했습니다. Gemini API 실호출과 사용자 후기 수집은 하지 않았습니다.
> 선행 조사: `research-gemini4-argon.md`, `research-fable52-carbon.md`. 과거 조사는 시점 기록이라 고치지 않고, 달라진 사실은 이 문서에 적습니다.

## 0. 요약

**결론**: 설정·훅·권한 규칙은 그대로 두고 agy 상태줄만 고쳤습니다. Hydrogen은 별도 파일을 만들지 않고 Gemini 4 문서 두 개에 세 번째 모델로 더했습니다. Hydrogen을 Flash 계열의 최신 세대로 세어 3.6 Flash를 보관소로 옮겼습니다.

1. **Hydrogen은 Carbon에서 파생한 빠른 실행용 Gemini 4 모델입니다.** 3.8 Flash의 권장 업그레이드로 소개되지만 이름과 계약은 Gemini 4 계열을 따릅니다. Argon·Carbon에서 옮길 때 요청 스키마가 같습니다.
2. **Argon·Carbon과 다른 계약은 세 가지입니다.** 기본 사고 수준이 `high`이고 `xhigh`가 있으며, 비스트리밍 한 구간 한도가 65,536이고, Developer API 무료 등급에서도 제공합니다.
3. **Hydrogen용 AI Studio 개발 가이드는 없습니다.** Argon·Carbon의 다섯 운용 축을 Hydrogen에 그대로 옮길 근거가 없어, Hydrogen 문서가 직접 적은 권고만 따로 모았습니다.
4. **agy에는 Hydrogen과 Orchestrator가 함께 들어왔습니다.** Orchestrator는 Carbon이나 Argon이 계획하고 Hydrogen이 구현하는 고정 구성입니다.
5. **agy 호출 기록의 자동 압축 한도가 Argon·Hydrogen·Orchestrator에서 512,000입니다(11-16, Pro 계정).** 공식 답변은 기본값이 256,000이라는 것이고 상향 공지는 없습니다. 같은 계정의 Orchestrator는 전날 다른 작업 환경의 기록에서 256,000이었습니다. 값이 달라진 원인과 압축이 실제로 일어나는 시점은 확인하지 않았습니다.

## 1. Gemini 4 Hydrogen

### 1.1 출시와 위치

| 항목 | 내용 | 근거 |
|------|------|------|
| 모델 ID | `gemini-4-hydrogen` (안정 버전) | AI Studio 모델 페이지 "Stable: gemini-4-hydrogen" |
| 출시 | 2026-11-12 | 출시 글 날짜, 모델 카드 "Published 12 November 2026" |
| Cloud 단계 | 단기 GA, 폐기 45일 전 통지 | Cloud 개발 가이드 "short-term generally available (GA) release subject to a minimum 45-day retirement notice policy" |
| 기반 | Carbon | 모델 카드 "Gemini 4 Hydrogen is adapted from Gemini 4 Carbon." |
| 지식 마감일 | 2026년 3월 | 모델 카드 |
| 위치 | 3.8 Flash와 그 이전 Gemini 3·2.5의 권장 업그레이드 | 새 기능 문서 "Recommended upgrade from Gemini 3.8 Flash and earlier Gemini 3 and 2.5 models." |
| 용도 | 일상 코딩, 대화형 웹 앱, 도구를 쓰는 에이전트, 멀티모달 문서 작업, 병렬 서브에이전트 실행 | 새 기능 문서 |
| 제공 | Gemini API·AI Studio 무료·유료 등급, Cloud, Antigravity, Gemini 앱·검색 | 새 기능 문서, 출시 글 |

### 1.2 계약

| 항목 | 내용 |
|------|------|
| 창 | 입력·사고·출력 통합 1,048,576 |
| 출력 | 기본 65,536. 전경 한 구간은 스트리밍·비스트리밍 모두 65,536. 장문 출력으로 1,048,576 − 입력까지 |
| 사고 수준 | `low`·`medium`·`high`(기본)·`xhigh`. `minimal`은 오류 |
| `thinking_budget` | Developer API GenerateContent는 경고 후 가까운 수준으로 변환, Cloud는 400 |
| sampling | `temperature`·`top_p`·`top_k`는 범위 안 값이면 무시, 범위 밖이면 400(Developer API). Cloud는 `frequency_penalty`·`presence_penalty`·`candidate_count > 1`이 400 |
| 캐싱 | 암시 캐싱만, 최소 4,096토큰, 적중 95% 할인. Cloud는 내구 캐싱 기본 |
| 도구 | 함수 호출, 코드 실행, 구조화 출력, 검색·지도 그라운딩, URL 컨텍스트, 파일 검색, 컴퓨터 사용 |
| 미지원 | 이미지·음성 생성, Live API, 명시 캐싱 |
| 처리 옵션 | Batch, Flex, Priority |

가격(Developer API, 100만 토큰당 USD)은 Standard `$1.50 / $7.50`, 캐시 적중 `$0.075`입니다. Batch·Flex는 `$0.75 / $3.75`, Priority는 `$2.70 / $13.50`입니다. Argon·Carbon과 달리 기간 한정 표기가 없습니다.

### 1.3 Cloud 개발 가이드가 더 적은 것

- **사고 서명의 묶임**: 서명이 시스템 지시·도구·이전 턴에 묶여 있어, 같은 모델로 앞 턴을 고쳐 다시 보내면 기본 설정(`prefix_mismatch_behavior="ERROR"`)에서 400입니다. 이력을 압축하거나 고치는 하네스는 GenerateContent에서 `ThinkingConfig`의 `prefix_mismatch_behavior="DROP"`을, Interactions에서 `generation_config.prefix_mismatch_behavior="drop"`을 쓰라고 적혀 있습니다. 다른 모델이 만든 서명은 자동으로 버려집니다.
- **병렬 함수 호출**: 첫 `functionCall`에만 서명이 있습니다. 빼거나 다른 호출에 복사하거나 호출과 응답을 섞으면 400입니다.
- **사고 토큰 누적**: `high`·`xhigh`의 사고 토큰은 출력 한도에 포함되고 서명을 보존하면 다중 턴 맥락에 쌓입니다. 코딩 하네스의 압축 임계값을 너무 낮게 잡지 말라는 문장이 있습니다.
- **3.8 Flash 대비**: 암시 캐시 최소 길이가 6,144에서 4,096으로 줄었습니다.
- **2027-01-12 예고**: Hydrogen과 이후 모델이 TTL 설정이 있는 캐시 제어를 지원하고 캐시 쓰기를 입력 단가의 1.25배로 과금한다고 Cloud 모델 페이지가 적습니다.

### 1.4 프롬프팅 관련 문장

- Carbon이 인터페이스 설계와 막힌 문제를 맡고 코드 수정·병렬 서브에이전트 작업·테스트 실행을 Hydrogen에 넘기는 구성을 예로 듭니다.
- 도구를 선언하지 않고 원시 텍스트 JSON 도구 호출을 내게 하면 `MALFORMED_FUNCTION_CALL`이 날 수 있습니다.
- 읽기·검색 호출을 병렬로 묶고 맥락이 부족하면 추측하지 않고 알린다는 설명은 Google 주장입니다.
- 길이 목표를 따르지 않는 점, 고정 내용을 앞에 두는 점, 도구 직전 텍스트 규칙은 Argon·Carbon 가이드와 같은 문장이 Hydrogen의 Cloud 가이드에 있습니다.

## 2. agy(Antigravity CLI)

| 항목 | 내용 | 근거 |
|------|------|------|
| Hydrogen 변형 | `-low`·`-medium`·`-high`·`-xhigh`, 기본 High | 모델 문서, `agy models`(1.5.9) |
| Orchestrator | `Orchestrator (Carbon)`은 Ultra, `Orchestrator (Argon)`은 Ultra와 유료 Pro. 사고 강도 고정 | 모델 문서 "Orchestrator runs with a fixed configuration" |
| 쿼터 | Hydrogen은 3.8 Flash와 같은 Gemini 묶음, Argon은 Pro에서 전용 주간 묶음 | `/usage`(1.5.9, Pro) |
| 상태줄 페이로드 | Orchestrator는 표시명이 `Orchestrator (Argon)`이고 `effort`가 없음. 쿼터 키는 `/usage`의 버킷 ID와 같음 | 실측 |
| 창 크기 | Gemini 계열 1,048,576, Claude 1,000,000, GPT-OSS 131,072 | 상태줄 페이로드 |
| 모델 정리 | Claude Sonnet 4.6·Opus 4.6, GPT-OSS-120b는 2026-11-18 제거 예정 | 모델 문서 |

## 3. agy 자동 압축 한도

### 3.1 공식 입장

- 문서와 변경 기록에는 한도를 올렸다는 안내가 없습니다. CLI 내장 변경 기록 1.5.0~1.5.9에도 없습니다.
- [antigravity-cli #1432](https://github.com/google-antigravity/antigravity-cli/issues/1432)에서 Collaborator가 2026-11-05에 답했습니다: "Antigravity CLI intentionally sets the default automatic compaction threshold to 256,000 tokens."
- 사용자 보고는 256K보다 큰 선택지(512K·900K)가 바이너리에 있지만 Argon에만 열려 있고 적용되지 않는다는 내용이었습니다.

### 3.2 실측

agy는 대화마다 SQLite 파일을 남기고, 호출 기록에 그 호출의 컨텍스트 한도가 들어 있습니다. 대화 본문을 읽지 않고 그 값만 세었습니다.

| 시각 | 환경 | CLI | 모델 | 기록된 한도 |
|------|------|------|------|------|
| 11-13 | 다른 작업 환경 | 1.5.7 | Gemini 4 Argon (`gemini-4-argon-trial`, 계정 미확인) | 256,000 |
| 11-15 16:30 | 다른 작업 환경 | 1.5.9 | Orchestrator (Argon) | 256,000 |
| 11-16 14:27 | 실측 환경 | 1.5.9 | Orchestrator (Argon) | 512,000 |
| 11-16 | 실측 환경 | 1.5.9 | Gemini 4 Argon | 512,000 |
| 11-16 | 실측 환경 | 1.5.9 | Gemini 4 Hydrogen | 512,000 |
| 11-16 | 실측 환경 | 1.5.9 | Gemini 3.8 Flash | 256,000 |
| 11-16 | 실측 환경 | 1.5.9 | Claude Sonnet 5.5 | 840,000 |

- 다른 작업 환경은 같은 서버에 있고 설정 파일과 대화 기록을 따로 씁니다. 11-15 대화는 로그의 로그인 시각과 대화 파일 생성 시각을 대조해 11-16 실측과 같은 계정으로 만든 것임을 확인했습니다. 두 환경의 CLI 바이너리는 해시가 같고, `AGY_`로 시작하는 환경 변수는 양쪽 다 없습니다.
- 같은 계정·같은 바이너리·같은 모델에서 값이 다르므로 서버가 내려주는 설정이 그 사이에 바뀌었을 가능성이 있습니다. 같은 환경에서 전후를 잰 것이 아니어서 원인을 확정하지 못했습니다. 1.5.9 바이너리의 기본 프로필에는 256,000, 512,000, 840,000이 모두 들어 있습니다.
- 전후 값이 있는 모델은 Orchestrator뿐입니다. Argon의 이전 기록은 계정을 확인하지 못한 체험판 모델 ID의 것이고, Hydrogen은 이전 기록이 없습니다.
- Pro 계정 하나의 관측입니다. 다른 요금제나 체험판 계정에도 같은 값이 내려오는지는 확인하지 못했습니다.
- 모델 선택 화면과 설정 화면에는 창 크기를 고르는 항목이 보이지 않았습니다. `/config` 출력의 `contextWindow` 키는 비어 있습니다.
- 압축이 실제로 512,000 근처에서 일어나는지는 실측하지 않았습니다. 26만 토큰을 넘는 대화가 필요해 쿼터를 많이 씁니다. 상태줄의 `ctx`가 25%(262,144토큰)를 넘겨도 압축 표시가 없으면 256,000에서는 압축하지 않는다는 근거가 됩니다.

## 4. dotfiles 판단

| 항목 | 판단 | 이유 |
|------|------|------|
| Hydrogen 문서 | Gemini 4 두 문서에 통합 | Carbon 때와 같은 방식. 요청 스키마가 같고 차이가 세 가지뿐 |
| Flash 계열 문서 | 3.6 Flash를 보관소로 | Hydrogen을 Flash 계열의 최신 세대로 세면 현행은 Hydrogen·3.8·3.7. 3.6 Flash는 Gemini API에서 계속 제공되지만 Cloud에서는 2026-11-19 종료 예정 |
| agy 상태줄 | Orchestrator를 Gemini 계열로 처리하고 표시명의 괄호를 남김 | 모델 구분에 Orchestrator가 없어 Claude·GPT 한도를 보였고, 괄호를 떼면서 Argon 한도 표시도 잃었음 |
| agy 설정 | 변경 없음 | 압축 한도를 조절하는 공개 설정이 없음 |
| agy 규칙 예산 | 변경 없음 | 압축 한도가 올라도 규칙 파일 한도(파일당 24,000바이트)와는 별개 |

## 5. 출처 사이의 불일치와 미확인

- **Hydrogen의 Antigravity 요금제**: 모델 문서의 표는 Free·Plus를 포함한 전 요금제를 지원으로 적고, 출시 글은 유료 Pro·Ultra에 순차 제공한다고 적습니다.
- **Orchestrator의 Enterprise 지원**: 모델 문서의 표는 미지원, 출시 글은 "Enterprises can access both in Gemini for business"입니다.
- **장문 출력 문서의 기본값 문장**: "Use medium (the default) for most coding and agentic work"는 Argon·Carbon 기준이고 Hydrogen의 기본 `high`와 맞지 않습니다.
- **사고 문서의 일반 권고**: "Use minimal thinking for fact retrieval or classification"은 Gemini 4에서 쓸 수 없습니다.
- **미확인**: Developer API에 `prefix_mismatch_behavior`가 있는지, Orchestrator의 쿼터 차감 방식, Carbon의 agy 쿼터 버킷, 요금제별 압축 한도.

## 출처

- [What's new in Gemini 4 Hydrogen](https://aistudio.google.com/docs/whats-new-gemini-4-hydrogen) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-hydrogen?generate-content=true)
- [AI Studio 모델 페이지](https://aistudio.google.com/docs/models/gemini-4-hydrogen) · [Pricing](https://aistudio.google.com/docs/pricing) · [Thinking](https://aistudio.google.com/docs/thinking) · [Long decode](https://aistudio.google.com/docs/long-decode)
- [모델 카드](https://deepmind.google/models/model-cards/gemini-4-hydrogen/) · [출시 글](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-hydrogen/)
- [Cloud 개발 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-hydrogen) · [Cloud 모델 페이지](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/4-hydrogen) · [Get started with Gemini 4](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/start/get-started-with-gemini-4)
- [Antigravity 모델 문서](https://antigravity.google/docs/models/) · [Gemini 4 Hydrogen and Orchestrator](https://antigravity.google/blog/gemini-4-hydrogen-in-google-antigravity)
- [antigravity-cli #1432](https://github.com/google-antigravity/antigravity-cli/issues/1432) (압축 한도에 대한 Collaborator 답변)
