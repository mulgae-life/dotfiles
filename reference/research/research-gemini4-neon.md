# Gemini 4 Neon 조사 — 공식 자료, agy 1.5.12 실측, dotfiles 판단 (2026-11-19, 출시 다음 날)

> 조사 방식: Google 공식 문서 30여 쪽을 헤드리스 Chromium으로 받아 본문을 직접 읽고 인용 문장을 대조했습니다. AI Studio 가격표는 원본 HTML로, 평가 방법 문서는 PDF로 확인했습니다. agy 쪽은 이 장비의 CLI 1.5.12(Google AI Pro 계정)에서 실측했습니다. Codex가 같은 주제를 따로 조사했고 두 결과를 대조했습니다.
> 문서 역할: Neon에 관해 확인한 사실, agy에서 달라진 점, dotfiles 판단을 기록합니다. 모델 사용 계약과 프롬프트 선택은 `reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`가 정본입니다.
> 시점: 2026-11-19에 수집하고 대조했습니다. Gemini API 실호출은 하지 않았습니다.
> 선행 조사: `research-gemini4-argon.md`, `research-fable52-carbon.md`, `research-gemini4-hydrogen.md`. 과거 조사는 시점 기록이라 고치지 않고, 달라진 사실은 이 문서에 적습니다.

## 0. 요약

**결론**: 설정·훅·권한 규칙·상태줄 로직은 그대로 두고 문서와 주석만 고쳤습니다. Neon은 별도 파일을 만들지 않고 Gemini 4 문서 두 개에 네 번째 모델로 더했습니다. 보관소로 옮긴 문서는 없습니다.

1. **Neon은 Carbon에서 파생한 중간 모델입니다.** Hydrogen과 Carbon 사이에 놓이고, 복잡하면서 자주 실행하는 작업이 대상입니다.
2. **API 계약은 Hydrogen과 같습니다.** 기본 사고 수준 `high`, `xhigh`, 비스트리밍 한 구간 65,536입니다. 다른 점은 요율(`$3 / $15`), 유료 등급 전용, Cloud 제공 조건입니다.
3. **Google 문서의 권장 구성에서 Argon이 빠졌습니다.** Cloud 개발 가이드는 Neon을 Argon의 일반 코딩·기업 추론 작업이 옮겨 갈 모델로 적습니다. Argon의 종료일은 공지되지 않았습니다.
4. **agy 1.5.12의 Pro 계정에서 Neon과 `Orchestrator (Neon)`을 확인했습니다.** Neon을 지원하는 요금제에서 모델을 고른 적이 없으면 새 대화가 Neon으로 시작합니다. Pro 계정의 `/usage`에서 Neon은 Gemini 버킷에, Argon은 전용 주간 버킷에 속합니다.
5. **차단 규칙은 Neon에서도 지켜졌습니다.** 기본 모델과 `gemini-4-neon-low`에서 여섯 건씩 통과했습니다.
6. **대화 기록에 남은 호출별 압축 한도는 Neon과 `Orchestrator (Neon)` 모두 512,000입니다.**
7. **Cloud 개발 가이드에서 `prefix_mismatch_behavior` 서술이 빠졌습니다.** 현행 문서는 이력을 고치면 요청을 처리하되 맞지 않는 사고를 컨텍스트에서 뺀다고 적습니다.
8. **Neon 전용 프롬프트 작성 가이드는 찾지 못했습니다.** 2026-11-19까지 조사한 공식·제3자 자료 기준입니다. 공식 권고는 API 마이그레이션 안내와 Cloud 개발 가이드에 있고, 그 문장만 가이드에 모았습니다.
9. **제3자 시험 하나(Plotly 데이터 분석)에서는 Hydrogen이 Neon과 같은 점수를 더 싸고 빠르게 냈습니다.**

## 1. Gemini 4 Neon

### 1.1 출시와 위치

| 항목 | 내용 | 근거 |
|------|------|------|
| 모델 ID | `gemini-4-neon` (안정 버전) | AI Studio 모델 페이지 "Stable: gemini-4-neon" |
| 출시 | 2026-11-18 GA | 모델 카드 "Published 18 November 2026", API 변경 기록 |
| 기반 | Carbon | 모델 카드 "Gemini 4 Neon is adapted from Gemini 4 Carbon." |
| 지식 마감일 | 2026년 3월 | 모델 카드 |
| 위치 | Hydrogen과 Carbon 사이 | 새 기능 문서 "It sits between Gemini 4 Hydrogen and Gemini 4 Carbon for high-frequency complex tasks." |
| 권장 구성 | 기본 출발점은 Hydrogen, 복잡하면서 자주 실행하는 작업은 Neon, 가장 어려운 문제는 Carbon | 모델 선택 문서 "Default to gemini-4-hydrogen", "Use gemini-4-neon for complex, high-frequency tasks" |
| Neon으로 옮길 범위 | 3.1 Pro Preview, Argon의 일반 코딩·기업 추론 작업, 3.8 Flash나 그 이전 Gemini 3 Flash 모델에서 하던 복잡한 코딩·과학 작업 | Cloud 개발 가이드 "the target upgrade for Gemini 3.1 Pro … and for general coding and enterprise reasoning workloads on Gemini 4 Argon" |
| 수명 | Gemini API 폐기 문서는 네 모델 모두 종료일 미공지. Cloud 수명 주기 문서는 Argon을 12개월 보장 표(종료는 2027-10-13 이후)에, Neon·Hydrogen·Carbon을 단기 제공 표에 둠 | Deprecations, Model versions and lifecycle |
| 사이버 변형 | Cloud 문서에 Neon 변형 ID 없음 | 출시 글 "Gemini 4 Neon for cyber is rolling out to trusted defenders in the coming days as part of the Fairwind Program." |

- 모델 선택 문서와 Carbon·Hydrogen 새 기능 문서의 선택 절은 Carbon·Neon·Hydrogen만 비교합니다. Argon 문서는 "Other models" 아래에 남아 있습니다.
- Carbon 마이그레이션 안내의 문장이 "Use Neon or Hydrogen where speed matters"로 바뀌었습니다.

### 1.2 계약

| 항목 | 내용 |
|------|------|
| 창 | 입력·사고·출력 통합 1,048,576 |
| 출력 | 포그라운드 한 구간 65,536(스트리밍·비스트리밍). 장문 출력은 1,048,576에서 입력을 뺀 값까지 |
| 사고 수준 | `low`·`medium`·`high`(기본)·`xhigh`. `minimal`은 오류. `thinking_budget`은 Developer API GenerateContent에서 경고 후 변환, Cloud에서 400 |
| 캐싱 | 암시 캐싱만. 최소 4,096토큰, 적중 95% 할인. Cloud는 지속형 캐싱(durable caching) 기본 |
| sampling | 범위 안의 `temperature`·`top_p`·`top_k`는 무시, 범위 밖은 400(Developer API) |
| 도구 | 함수 호출, 코드 실행, 구조화 출력, 검색·지도 그라운딩, URL 컨텍스트, 파일 검색, 컴퓨터 사용 |
| 미지원 | 이미지·음성 생성, Live API, 명시 캐싱 |
| 처리 옵션 | Batch, Flex, Priority |
| 입력 | 텍스트·이미지·영상·음성·PDF. Microsoft Office·OpenDocument 파일도 받음(Cloud의 Neon·Hydrogen 가이드에 명시. Developer API의 11-18 변경 기록은 직접 입력을 안내하며 대상 모델을 적지 않음. PPT·ODP·ODS 입력은 11-05 기록에서 추가) |
| 마이그레이션 | 다른 Gemini 4 모델에서 "requires no request schema changes" |

**요율** (100만 토큰당 USD, 출력은 사고 포함):

| 처리 | Developer API 입력 / 캐시 / 출력 | Cloud 전역 | Cloud 비전역 |
|------|------|------|------|
| Standard | 3.00 / 0.15 / 15.00 | 3.00 / 0.15 / 15.00 | 3.30 / 0.165 / 16.50 |
| Batch | 1.50 / 0.075 / 7.50 | 1.50 / 0.075 / 7.50 | 1.65 / 0.0825 / 8.25 |
| Flex | 1.50 / 0.075 / 7.50 | 가격표에 없음 | 가격표에 없음 |
| Priority | 5.40 / 0.27 / 27.00 | 5.40 / 0.27 / 27.00 | 5.94 / 0.297 / 29.70 |

- Developer API에서는 유료 등급 전용이고 출시 할인가가 없습니다.
- Argon·Carbon은 2026-11-30까지 `$2 / $10`, 12-01부터 `$4 / $20`입니다. 12-01부터는 Neon의 단가가 더 낮습니다.
- 2027-01-12부터 Cloud에서 Hydrogen 이후 모델의 캐시 보존 시간(TTL)을 지정할 수 있습니다. 그날부터 해당 모델의 기본 캐시 쓰기 요금은 표준 입력 요율의 1.25배이며, 보존 시간을 늘리면 요금이 올라갑니다.

### 1.3 Cloud

- 약관: "Gemini 4 Neon is a Google Frontier Model subject to Section 34 of the Service Specific Terms"
- 제공 조건: "available to verified enterprise customers in select regions". 위치는 `global`·`us`·`eu`이고, Argon을 `europe-west2`·`asia-southeast1`에서 쓰던 경우 위치를 바꿉니다.
- 장문 출력은 두 API 모두 `v1beta1`에서 지원합니다. SDK 자동 이어 쓰기의 최소 버전은 Interactions가 Python 2.34.0·JS 2.32.0, GenerateContent가 Python 2.30.1·JS 2.29.1입니다.
- 사고 수준 값은 GenerateContent가 대문자(`HIGH`), Interactions가 소문자(`high`)입니다.
- 다중 모델 구성: Neon이 계획하고 검증하며 `previous_interaction_id`로 Hydrogen 서브에이전트에 넘깁니다.

### 1.4 사고 서명 서술의 변경

- 2026-11-16에 받은 Hydrogen Cloud 개발 가이드에는 `prefix_mismatch_behavior` 절이 있었습니다. 기본값에서 앞 턴을 고쳐 보내면 400이고 `"DROP"`으로 바꾸라는 내용이었습니다.
- 2026-11-18 개정본(Neon·Hydrogen·Carbon·Argon 개발 가이드, 사고 서명 문서)에는 이 필드가 나오지 않습니다. Cloud와 Developer API의 공개 API 스키마에도 없습니다.
- 현행 사고 서명 문서: "Modifying earlier turns in contents, changing system instructions or tool declarations mid-conversation, or passing signatures across incompatible models or projects causes the service to omit mismatched thoughts from the model's context rather than failing the request."
- 400이 남는 경우: 서명이 잘리거나 손상된 경우, 현재 턴 각 단계의 첫 `functionCall`에서 서명을 뺀 경우, 병렬 호출에서 첫 `functionCall`의 서명을 다른 호출에 복사한 경우입니다.
- 서버가 예전 옵션 값을 받는지는 확인하지 않았습니다.

### 1.5 프롬프팅

- Neon용 개발 가이드는 AI Studio Learn 목록에 없습니다. `learn/gemini-4-neon-developer-guide` 주소는 "Page Not Found"이고, 목록의 Gemini 4 계열 개발 가이드는 Argon·Carbon 두 편입니다. API 마이그레이션 안내와 Cloud 개발 가이드는 공개돼 있습니다.
- 공식 [프롬프트 설계 전략 문서](https://aistudio.google.com/docs/prompting-strategies)에는 Neon 전용 절이 없습니다. Gemini 4 언급은 sampling 인자를 무시한다는 문장 하나입니다.
- 공식 예제 저장소 `google-gemini/cookbook`에서 `gemini-4-neon`을 쓰는 예제는 찾지 못했습니다(코드 검색 0건). README가 소개하는 Gemini 4 모델은 Hydrogen·Carbon·Argon입니다.
- 문서가 직접 적은 권고
  - `high`로 시작하고 `xhigh`는 `high`로 부족할 때만 씁니다.
  - 네 수준을 높은 `max_output_tokens`로 평가합니다.
  - 도구는 함수 호출로 선언합니다.
  - 고정 내용을 프롬프트 앞에 둡니다.
  - 도구 호출 직전에 구조 없는 텍스트를 두지 않습니다.
- 문서가 적은 제한: 모델은 길이 목표를 따르지 않습니다.
- 클라이언트 시간 제한 권고: Interactions 마이그레이션 안내는 백그라운드 실행 또는 15분 이상, GenerateContent 마이그레이션 안내는 호출당 20분 이상입니다.
- Cloud 포그라운드 장문 출력의 서버 한도는 구간당 20분입니다.
- Google은 같은 파일을 다시 읽는 일과 작업을 건너뛰는 편법·지어낸 주장이 줄었고, 모델이 진행 상황을 알리며 컨텍스트 압축 뒤에도 작업을 이어 간다고 설명합니다. 독립 실측은 아닙니다.

### 1.6 평가 수치

| 출처 | 조건 | 결과 |
|------|------|------|
| Artificial Analysis(AA) 지능 지수 v5.0.1 (2026-11-19 조회) | Google API, 사고 수준별 | `low` 44점·과제당 3.7분·출력 2,830만 토큰, `medium` 55점·8.3분·6,290만, `high` 60점·14.8분·1억 2,300만, `xhigh` 61점·21.5분·2억 8,300만. `xhigh`의 과제당 비용 `$6.44` |
| Vals Index 2.2 (2026-11-18 기준) | 모델 페이지의 기본 설정은 `xhigh`·최대 출력 1,048,576. 시험별 설정은 다를 수 있음 | 42개 중 2위, 70.87%, 시험당 `$7.40`. 1위 Fable 5.2 71.31%(`$17.94`), 3위 Sonnet 5.5 70.85%, 4위 Carbon 70.45%(`$10.51`) |
| Agent Arena 종합 (2026-11-18) | `high`, 실제 사용자 세션 기반 | 3위, 지수 1,333, 과제당 비용 중앙값 `$2.66` |
| Google 평가 방법 문서 | 따로 적지 않으면 Neon은 최고 사고 수준, 타사는 제공사 자체 보고값. 비교 대상은 Opus 5.5·GPT-6.2 Sol | AA 지수 61, Terminal-Bench 4.1 65.2%(Antigravity CLI 1.5.9 하네스), FrontierCode 2.0 46.2%(`high`), SWE-sweep 39.0%(Antigravity CLI 하네스)·12.8%(mini-SWE 하네스) |

- `high`에서 `xhigh`로 올리면 AA 지수는 1점 오르고 출력 토큰은 2.3배입니다.
- AA의 과제당 시간은 출력 토큰 수와 출력 속도로 계산한 가중 추정치이고, 출력 토큰 수는 지수 평가 전체를 실행하는 데 쓴 합계입니다.
- "Carbon보다 과제당 비용이 32% 낮다"는 Google 출시 글이 AA의 과제당 비용(기본 `high`)으로 제시한 수치입니다.
- SWE-sweep은 Google이 타사 모델까지 직접 실행한 시험입니다. 두 수치 차이는 서브에이전트가 코드베이스를 나눠 훑는 도구를 갖춘 하네스의 효과가 섞인 것이라 모델만의 차이로 읽지 않습니다.

### 1.7 사용자 반응과 제3자 실사용 자료

출시 다음 날이라 표본이 적습니다. Neon 전용 프롬프트 작성법을 다룬 제3자 가이드는 찾지 못했습니다.

| 출처 (조건) | 내용 |
|------|------|
| Plotly 데이터 분석 시험 (43문항, 모델당 1회, 출시일 OpenRouter 경유) | Neon 43점(만점)·`$17.03`·문항당 중앙값 46초, Hydrogen 43점(만점)·`$6.36`·32초, Carbon 42점·`$11.55`·93초, Argon 41점·`$13.47`·23초. Neon은 Carbon보다 토큰을 덜 썼고(2,010만 대 2,950만) 단가 때문에 비용이 높음. 원문은 다른 모델을 반복 시험했을 때 3점까지 차이가 났으므로 1~2점 차이를 사실상 동률로 보라고 설명 |
| Plotly의 문체 비교 (같은 글) | 답이 명확하고 구조가 잡혀 있으나 짧지는 않음. 비교에 쓴 모호한 질문 한 건에서는 어떤 지표를 쓰느냐에 따라 답이 달라진다고 먼저 설명함. 원문 "it tends to be thorough rather than terse" |
| 9to5Google (2026-11-18) | Google AI Pro·Ultra 구독자의 Gemini 앱에서 Neon이 Argon을 대체하고 3.1 Pro가 빠졌다고 보도. "Neon also replaces Argon." |
| Hacker News 스레드 (수집 시점 댓글 382개) | 이름 체계가 혼란스럽다는 반응과 권장 모델 목록에서 Argon이 빠졌다는 지적이 있음 |

Hacker News의 개별 사용자 보고(미검증):

- 데모 생성 용도에서는 Argon의 토큰 효율이 가장 좋고 Carbon·Hydrogen·Neon은 3~4배를 쓴다는 보고
- Gemini 4 모델이 자기 질문에 스스로 답하는 일이 잦다는 보고
- Neon이 과제를 적극적으로 끝까지 처리한다는 호평("super eager and runs down tasks really well")
- OpenRouter 기준 출력 속도가 Neon 초당 127토큰, Carbon 46토큰이라는 보고
- 학생용 Pro 요금제에서는 agy의 Gemini 4 모델이 잠겨 있다는 보고 두 건
- AA 직원 댓글: Neon의 종합 지수는 Carbon보다 높지만 연구 수준 추론 시험(CritPt)은 Carbon이 높음

확인하지 못한 자료: VentureBeat 기사(봇 확인 화면으로 열람 실패). Simon Willison 블로그에서는 "Gemini 4 Neon" 검색 결과가 없었습니다.

## 2. agy 1.5.12

### 2.1 변경 기록

- Neon 네 수준(Low·Medium·High·XHigh)을 `/model`과 `--model`에 추가. 변경 기록은 `GEMINI_API_KEY`로 연결한 경우만 적었지만, Pro 계정 로그인에서도 목록에 나옵니다.
- Auto 모드에서 Hydrogen으로 샌드박스 이탈 명령을 검토할 때의 사고 수준을 high에서 medium으로 낮춤.
- 연결 오류 자동 재시도, Markdown 제목 표시, 스크롤 위치 표시, `/fork` 개선, Remote Control 수정.
- 레포의 차단 규칙과 사용자 지정 상태줄의 페이로드에 영향을 주는 변경은 찾지 못했습니다.

### 2.2 실측

| 항목 | 결과 | 방법 |
|------|------|------|
| 모델 목록 | `gemini-4-neon-{low,medium,high,xhigh}`, `gemini-pro-orchestrator-neon`. Argon 세 수준과 `gemini-pro-orchestrator-g1-pro`도 유지 | `agy models` |
| 쿼터 | Neon·Hydrogen·`Orchestrator (Neon)`·3.8 Flash가 `gemini-5h`·`gemini-weekly`. Argon은 `gemini-argon-wtu-weekly` | `agy -p "/usage" --output-format json` |
| 상태줄 페이로드 | Neon은 표시명 "Gemini 4 Neon (High)"와 `effort`, `Orchestrator (Neon)`·`Orchestrator (Argon)`은 `effort` 없음. 모두 창 1,048,576 | 임시 세션에서 페이로드 수집, 모델 호출 없음 |
| 상태줄 출력 | 기존 스크립트가 Neon과 `Orchestrator (Neon)`에 Gemini 버킷을, `Orchestrator (Argon)`에 Argon 주간과 Gemini 버킷을 표시 | 수집한 페이로드를 스크립트에 입력 |
| 정책 검사 | 87건 통과(Codex 엔진 69건, agy 정적 18건) | `scripts/verify-policies.sh` |
| 차단 규칙 | 기본 모델 6건, `gemini-4-neon-low` 6건 모두 통과 | `scripts/agy-live-check.sh` |
| 압축 한도 | Neon 512,000, `Orchestrator (Neon)` 512,000 | 실측 호출이 남긴 대화 기록의 호출별 한도 |
| Orchestrator 응답 | 간단한 질문 한 건에 계획 모델이 바로 답하고 끝남 | `Orchestrator (Neon)` 실측 호출 한 번 |

### 2.3 공식 문서

| 항목 | 내용 |
|------|------|
| 기본 모델 | "It's the default model for new conversations if you haven't chosen a model; if you've already selected one, Antigravity keeps your selection." |
| 창 | "Context window: Up to 512K tokens." |
| 사고 수준 | Low·Medium·High(기본)·Extra. CLI에서는 `-xhigh`·`--effort xhigh` |
| Neon 요금제 | 유료 Pro와 적격 프리미엄 기기 체험판, Ultra, Enterprise. Free·Plus 없음 |
| Hydrogen 요금제 | 유료 Pro(체험판 제외), Ultra, Enterprise. Free·Plus 없음 |
| Orchestrator | Neon·Carbon·Argon 세 종류. 이름에 적힌 모델이 계획과 검토를, Hydrogen이 구현을 맡음. `Orchestrator (Neon)`과 `Orchestrator (Argon)`은 Ultra와 유료 Pro(적격 프리미엄 기기 체험판 포함), `Orchestrator (Carbon)`은 Ultra. 모델 표의 Enterprise 칸은 모두 미지원. 구성 고정 |

- 간단한 질문은 계획 모델이 바로 답합니다("the planner answers it directly").

## 3. dotfiles 판단

| 항목 | 판단 | 이유 |
|------|------|------|
| Neon 문서 | Gemini 4 두 문서에 통합 | 계약이 Hydrogen과 같고 차이가 요율과 제공 조건뿐 |
| 파일명 | `gemini-4-argon-*` 유지 | Carbon·Hydrogen 때와 같은 이유로 기존 링크 유지 |
| 모델 자료 유지 기준 | Neon을 Argon·Carbon과 한 세대로 셈. 보관 대상 없음 | Carbon에서 파생한 Gemini 4 모델이고 요청 스키마가 같음. 3.1 Pro Preview에서 하던 작업과 Argon의 일반 코딩·기업 추론 작업을 옮길 모델이지만 Argon은 종료일 미공지 |
| 사고 서명 서술 | `prefix_mismatch_behavior` 문장을 현행 문서 내용으로 교체 | 11-16 Cloud 가이드에는 있었으나 현행 가이드와 공개 API 스키마에는 없음 |
| Hydrogen 요금제 표기 | 현행 모델 표로 교체 | 11-16의 문서 간 불일치가 정리됨 |
| `reasoning-params.md` | "중간 = 기본값"을 "기본값은 모델마다 다름"으로 | Hydrogen·Neon의 기본이 `high` |
| 가이드의 기존 문장 정정 | 지식 마감을 네 모델 모두 2026년 3월로, Cloud 사고 수준 표기와 낮은 출력 한도 권고·시간 제한을 API·모델별로 구분 | Argon·Carbon 모델 카드와 Neon 마이그레이션 안내에서 확인 |
| agy 상태줄 | 주석만 수정 | 페이로드 실측에서 Neon 표시와 버킷 선택이 맞음 |
| agy 설정·지침 | 변경 없음 | 모델은 레포가 고정하지 않음. 조사 범위에서 지침을 더할 근거를 찾지 못함 |
| 실측 스크립트 기본 모델 | `gemini-3.8-flash-low` 유지 | 정책 검사는 가장 싼 모델로 충분. Neon은 `AGY_CHECK_MODEL`로 지정 |
| agy README | 사실만 기재 | 모델 선택 기준은 프롬프트 가이드에 둠 |

## 4. 출처 사이의 불일치와 미확인

- **agy의 창 표기**: Antigravity 모델 문서는 Neon을 "Up to 512K tokens"로 적고, 상태줄 페이로드의 `context_window_size`는 1,048,576입니다. 대화 기록에 남은 호출별 압축 한도는 512,000입니다.
- **Orchestrator의 Enterprise 지원**: 현행 Enterprise 표는 세 조합 모두 미지원입니다. CLI 1.5.10 변경 기록은 Enterprise 또는 ADC 로그인에서 Carbon과 Hydrogen을 모두 고를 수 있으면 `Orchestrator (Carbon)`을 제공한다고 적습니다. 해당 계정의 현재 동작은 확인하지 않았습니다. `Orchestrator (Neon)`은 포럼 공지의 요금제 표도 Enterprise 미포함입니다.
- **AA 순위**: Google 발표는 지능 지수 3위이고, AA 모델 페이지의 요약 표기는 "#6 / 96"입니다. 집계 대상의 차이는 확인하지 않았습니다.
- **포럼 사용자 보고(미검증)**: Ultra 사용자 한 명이 공지 글의 답글에서 Neon XHigh의 첫 요청이 `THINKING_LEVEL_XHIGH` 400으로 실패한다고 보고했습니다. 같은 글의 품질 저하와 긴 대화 잘림은 Neon이 아니라 Carbon·Argon·Hydrogen의 증상으로 적혀 있습니다.
- **미확인**: 압축이 실제로 512,000 근처에서 일어나는지, Orchestrator의 쿼터 차감 방식, Neon 사이버 변형의 Cloud ID, Developer API의 `frequency_penalty`·`presence_penalty` 처리, `prefix_mismatch_behavior` 값을 서버가 받는지.

## 출처

- [What's new in Gemini 4 Neon](https://aistudio.google.com/docs/whats-new-gemini-4-neon) · [GenerateContent판](https://aistudio.google.com/docs/whats-new-gemini-4-neon?generate-content=true)
- [AI Studio 모델 페이지](https://aistudio.google.com/docs/models/gemini-4-neon) · [Choosing a model](https://aistudio.google.com/docs/choosing-a-model) · [Pricing](https://aistudio.google.com/docs/pricing) · [Thinking](https://aistudio.google.com/docs/thinking) · [Long decode](https://aistudio.google.com/docs/long-decode) · [Caching](https://aistudio.google.com/docs/caching) · [Deprecations](https://aistudio.google.com/docs/deprecations) · [Changelog](https://aistudio.google.com/docs/changelog)
- [모델 카드](https://deepmind.google/models/model-cards/gemini-4-neon/) · [평가 방법](https://storage.googleapis.com/deepmind-media/gemini/gemini_4_neon_model_evaluation.pdf) · [출시 글](https://blog.google/innovation-and-ai/models-and-research/gemini-models/introducing-gemini-4-neon/)
- [Cloud 개발 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-neon) · [Cloud 모델 페이지](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/gemini/4-neon) · [Get started with Gemini 4](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/start/get-started-with-gemini-4) · [Thought signatures](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/thinking/thought-signatures) · [Model versions and lifecycle](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/model-versions) · [Cloud 가격표](https://cloud.google.com/model-garden/pricing)
- [Antigravity 모델 문서](https://antigravity.google/docs/models/) · [Gemini 4 Neon in Google Antigravity](https://antigravity.google/blog/gemini-4-neon-in-google-antigravity) · [요금제](https://antigravity.google/docs/plans/) · [포럼 공지](https://discuss.ai.google.dev/t/gemini-4-neon-and-orchestrator-neon-are-now-available-in-google-antigravity/202301)
- [Artificial Analysis](https://artificialanalysis.ai/models/gemini-4-neon) · [Vals Index](https://www.vals.ai/benchmarks/vals_index) · [Agent Arena](https://arena.ai/leaderboard/agent?stream=top)
- 사용자 반응 [2차]: [Plotly 시험](https://plotly.com/blog/gemini-4-neon-plotly-data-analytics-bench/) · [9to5Google](https://9to5google.com/2026/11/18/gemini-4-neon-announcement/) · [Hacker News 스레드](https://news.ycombinator.com/item?id=50552424)
- 공식 자료에서 Neon 전용 내용이 없음을 확인한 곳: [Prompt design strategies](https://aistudio.google.com/docs/prompting-strategies) · [google-gemini/cookbook](https://github.com/google-gemini/cookbook)
- 모델 카드: [Argon](https://deepmind.google/models/model-cards/gemini-4-argon/) · [Carbon](https://deepmind.google/models/model-cards/gemini-4-carbon/) (지식 마감 2026년 3월)
