# Claude Fable 5.2·Gemini 4 Carbon 조사 — 공식 자료, Claude Code 적용, Argon 문서 정정, dotfiles 판단 (2026-11-12, Fable 5.2 출시 3일·Carbon GA 2일)

> 조사 방식: Claude와 Codex(tmux `dot-codex` 세션)가 같은 주제를 따로 조사한 뒤 메모를 주고받으며 대조했습니다. Claude는 Anthropic 공식 문서를 URL 끝에 `.md`를 붙인 사본으로, Google 문서는 ai.google.dev의 `.md.txt` 사본과 Cloud 문서 HTML로 읽었고, JS로 그리는 AI Studio 개발 가이드는 헤드리스 Chromium으로 펼쳐 읽었습니다. Codex는 같은 공식 문서와 DeepMind 모델 카드, Antigravity 문서·변경 기록, Claude 지원 문서를 읽었습니다. 독립 조사 뒤 메모를 주고받아 쟁점을 닫았고, 반영 뒤 Codex가 변경분 전체를 최종 점검했습니다. 이 문서는 Claude가 통합했습니다.
> 문서 역할: 두 신모델의 사실, 같은 기간 공급자 변경 가운데 레포 서술에 닿는 것, dotfiles 판단을 기록합니다. 모델별 사용 계약과 프롬프트 선택은 `reference/claude-prompt-guide/claude-fable-5-2-prompt-guide.md`와 `reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`가 맡습니다.
> 시점: 2026-11-12에 수집하고 대조했습니다. 모델 API 실호출과 사용자 후기 수집은 하지 않았습니다.
> 선행 조사: `research-fable51.md`, `research-gemini4-argon.md`, `research-claude-api-20261021.md`, `research-gpt61-terra.md`. 과거 조사는 시점 기록이라 고치지 않고, 달라진 사실은 이 문서에 적습니다.

## 0. 요약

**결론**: 설정·훅·권한 규칙은 그대로 둡니다. Fable 5.2는 전용 가이드를 새로 쓰고, Carbon은 기존 Gemini 4 Argon 문서에 형제 모델로 더했습니다. 같은 문서를 고치면서 Argon 문서의 낡은 서술(Cloud 캐시 최소 길이, Interactions 장문 출력, Cloud 장문 출력 범위, 컴퓨터 사용 상태, `latest-model` 주소)도 바로잡았습니다. Claude 문서에서는 2026-08-31 이전 계정의 이력 검사, Mythos 5.1의 검사 여부, CMEK 조직의 Opus 5.5 서술을 바로잡았습니다(3절).

1. **Fable 5.2는 5.1보다 싸고, 5.1에서 모델 ID만 바꾸면 깨지는 API 계약이 네 가지입니다.** 이력 편집 400이 계정 나이와 무관하게 적용되고, 5.2 사고 블록은 5.2끼리만 읽으며, `computer_20251124`가 400이고, advisor 조언자가 5.2로 제한됩니다.
2. **effort 기본값은 API `high`, Claude Code `medium`입니다.** 공식 프롬프팅 가이드는 `high`에서 시작해 다시 측정하라고 하고, `medium` 이상에서 생각을 줄이라는 지시가 듣지 않는다고 적습니다.
3. **5.2 공식 가이드는 새 증상 네 가지를 다룹니다.** 코드 소유권을 밝히지 않으면 덧붙이기만 하는 것, 서브에이전트 위임량이 하네스에 따라 크게 갈리는 것, 쌓인 경고를 그대로 따르는 것, 문체 규칙을 지나치게 충실히 따르는 것입니다. 5.1 가이드의 반서식·산문 밀도 처방은 다시 나오지 않습니다.
4. **서브에이전트 Opus 강제는 유지합니다.** 근거 문장만 공식 구독 문서의 표현("use them faster than other Claude models", Fable 주간 상한 50%)에 맞게 고쳤습니다.
5. **Gemini 4 Carbon은 Argon 기반의 같은 Gemini 4 계열 모델입니다.** 창·도구·토큰 단가가 같고 턴당 사고 토큰을 더 씁니다. 공식 선택 기준은 대부분의 작업은 Argon, 깊은 탐색과 검증은 Carbon입니다.

## 1. Claude Fable 5.2

### 1.1 출시와 위치

| 항목 | 내용 | 근거 |
|---|---|---|
| 출시 | 2026-11-09. `claude-fable-5-2`, 검증 조직용 `claude-mythos-5-2` | Release notes Nov 9 |
| Mythos와의 관계 | 기저 모델이 같고 Fable에 오용 방지 장치가 붙습니다 | 발표문 "the same underlying model" (Codex 열람) |
| 위치 | 5.1과 같은 문장: "For most workloads, start with the latest Claude Opus model ... and move to Claude Fable 5.2 when your evals on a Claude Opus model at higher effort still don't meet your requirements." | What's new in Claude Fable 5.2 |
| 속도 | 발표문의 "최대 30% 빠름"은 출력 생성 속도입니다. 작업 완료 시간이 그만큼 준다는 뜻은 아닙니다 | 발표문 (Codex 열람) |
| 플랫폼 | Claude API, Claude Platform on AWS, Bedrock(`global.`·`us.anthropic.claude-fable-5-2`, `bedrock-runtime`만), Google Cloud(Anthropic managed·Google managed), Microsoft Foundry(Anthropic 인프라) | Models overview, Migration guide |
| 수명 | 5.2 Active, 은퇴 하한 2027-11-09. 5.1 Active, 2027-09-01. Fable 5 Active, 2027-06-09. 폐기 공지 없음 | Model deprecations |

### 1.2 API 계약

| 항목 | 값 | 근거 |
|---|---|---|
| 가격 ($/MTok) | 입력 $8, 출력 $40, 5분 캐시 쓰기 $10, 1시간 $16, 캐시 읽기 $0.20(0.025배), Batch $4 / $20. 5.1은 $10 / $50·캐시 읽기 $0.25 | Pricing, Models overview "2.5% on Claude Fable 5.2 and Claude Fable 5.1" |
| 창·출력 | 1M(기본이자 최대, 길이 할증 없음), 최대 출력 128K | Models overview |
| 입출력 | 텍스트·이미지 입력, 텍스트 출력 | Models overview |
| 지식 컷오프 | 2026-06 | Models overview |
| 캐시 최소 | 512 토큰 | Migration guide |
| thinking | adaptive 상시. `enabled`·`disabled` 400 | What's new |
| effort | `low`~`max`, API 기본 `high`. "Start there, because most of the gain in capability is already present at `high`." | Effort, Prompting guide |
| 요청 한도 | "Claude Fable 5.2 has its own rate limit, separate from the combined limit that Claude Fable 5.1 and Claude Fable 5 share." Mythos 5.2는 Mythos 5.1·5와 공유 | Migration guide |
| Priority Tier | 미지원(Fable 5는 지원) | Migration guide |
| 데이터 보존 | 30일 필수, ZDR 불가(명시 승인 예외), Covered Model | Migration guide |
| CMEK | structured outputs 불가 | What's new |
| 지역 | Anthropic 운영 서비스의 `inference_geo: "us"` 1.1배 | Release notes, Pricing |
| 고속 모드 | 정식 제공, `speed: "fast"`, $16 / $80, 최대 2.5배. Claude API·Google Cloud 두 운영형·Foundry(Anthropic 호스팅, `claude-fable-5-2-fast` 배포에 `speed` 생략). Bedrock 없음, Batch·Priority Tier 병용 불가, Managed Agents에서는 `speed`를 뺌 | Fast mode |
| 거절·폴백 | 범주(`cyber`·`bio`·`frontier_llm`·`reasoning_extraction`·`general_harms`·`null`)와 폴백 대상(Opus 4.8·Opus 5)은 5.1과 같음 | Refusals and fallback |

5.1 대비 파괴적 변경 네 가지는 다음과 같습니다(What's new "Breaking changes").

| 변경 | 내용 |
|---|---|
| 이력 편집 400 | "a request that sends back an invalid thinking block and leaves `prefix_mismatch_behavior` unset gets a 400 error, whatever the account's age". 5.1은 2026-08-31 이후 생성 계정은 기본 400, 이전 계정은 계정마다 다름("Enforcement varies by account", Preserved thinking) |
| 사고 블록 단방향 | 5.2는 5.1·Opus 5.5·Sonnet 5.5·Haiku 5.5 등의 블록을 읽지만(Claude API·Google managed), 5.2 블록은 5.2·Mythos 5.2만 읽습니다. 다른 모델로 옮기면 블록이 버려지고 요청은 성공, 미과금 |
| `computer_20251124` | Bedrock 외 400 → `computer_toolset_20260801` |
| advisor | 5.2 실행자의 조언자는 5.2·Mythos 5.2만. 조언은 암호화된 `advisor_redacted_result` 블록 |

5.2 사고 블록은 계정에도 묶입니다. 만든 계정이나 연결된 계정이 아닌 계정이 보내면 오류 없이 버려지고, Claude API와 Google Cloud(Google managed)에서 `thinking-binding-controls-2026-08-01` 헤더를 쓰면 `input_transformations`에 `organization_binding_mismatch`로 남습니다. 이력 편집 400, 모델 변경에 따른 드롭, 계정 불일치에 따른 드롭은 서로 다른 원인입니다.

### 1.3 프롬프팅

공식 가이드(Prompting Claude Fable 5.2)의 항목을 5.1 가이드와 대조했습니다.

| 항목 | 5.2 공식 서술 |
|---|---|
| effort | `high` 시작, `medium`·`xhigh`도 측정. "rerun your effort sweep rather than carrying over a setting you tuned on Claude Fable 5.1 or Claude Opus 5.5" |
| 생각 줄이기 지시 | "an instruction to answer directly without deliberating didn't stop the model from thinking at `medium` and above". 작은 `max_tokens`는 텍스트 없이 끝날 수 있음 |
| 작업 완주 | `low`·`medium`에서 조기 종료가 잦음. 공식 "Finishing work" 블록, 재생 시험에서 미완료 종료 약 절반, 출력 토큰 약 30% 증가 |
| 코드 소유권 (신규) | 소유권 문장으로 중복 통합 10% 미만 → 약 75%, 출력 토큰 70~80% 증가, 요청 밖 변경 발생. 범위 제한 규칙이 있어도 절반 이상 통합 |
| 진행 업데이트 | 진행 업데이트 `thinking` 블록 수신 확인 → 하네스의 턴 한정 리마인더 → 시스템 프롬프트 문장 순 |
| 서브에이전트 (신규) | `xhigh`·`max`에서 자기 검토 서브에이전트를 띄움. "check which model your subagents use by default" |
| 쌓인 신중함 (신규) | "The model treats an instruction that contains 'never' as absolute" |
| 문체 규칙 | 경직된 상한은 글을 끊기게 함. 공식 "Communicating clearly" 블록 |
| 구모델용 지시 | Opus 5.5의 "treat that answer as done" 두 문장은 자기 실수 지적을 크게 줄임. 모델에게 보이는 큰 토큰 예산은 지출을 늘림 |

5.1 가이드의 반서식 규칙 교체, "mannered prose" 정의문, 요청 밖 수정·과다 테스트 억제, 병렬 호출 리마인더는 5.2 가이드에 다시 나오지 않습니다. 무효라고 밝힌 것은 아니므로 증상이 있을 때만 시험하는 선택지로 남겼습니다. 5.1의 "`medium`이 정점" 측정은 5.1 기록으로만 둡니다.

### 1.4 Claude Code와 구독

| 항목 | 내용 | 근거 |
|---|---|---|
| 최소 버전 | 2.1.321 | Claude Code model-config |
| 별칭 | `fable`은 5.2. Claude apps gateway 세션은 Fable 5가 기본 | 같은 문서 |
| 저장된 5.1 | 사용자 설정의 5.1은 Pro·Max·Ultra에서 첫 실행 때 `fable`로 이동, Team·Enterprise는 조직 설정에 따름. 콘솔·타사 제공자와 프로젝트·로컬·관리 설정은 그대로 | 같은 문서 |
| 기본 effort | "Fable 5.2, Opus 5.5, Sonnet 5.5, and Haiku 5.5 default to `medium`" | 같은 문서 |
| 구독 한도 | "They draw from your plan's regular weekly usage limits and use them faster than other Claude models." Fable 포함 요금제도 주간 한도의 50%까지 | Claude Fable models on your plan |
| 출시 행사 | Pro·Team 표준 좌석은 11/16 23:59 PT까지 Fable 포함과 초기화 1회(같은 시각 만료). Max·Ultra·프리미엄 좌석은 구독 기간별 초기화 1~3회, 2027-03-08 만료. 초기화의 일반 지급 기준은 11/9 10:00 PT 이전 유료 결제(Team·Enterprise는 좌석 사용자의 조직 가입 포함)이며 체험판 예외는 공식 안내 참조 | Claude Fable 5.2 launch offers |
| 로컬 확인 | 2.1.322에서 `claude -p --model fable --effort medium`으로 메인 Fable 5.2 `medium`, 서브에이전트 2건 Opus 5.5 `high` | 트랜스크립트 `model`·effort 필드 |

## 2. Gemini 4 Carbon

### 2.1 출시와 위치

| 항목 | 내용 | 근거 |
|---|---|---|
| 일정 | 10/28 발표와 Fairwind 프로그램 선공개, 11/10 GA | Gemini API changelog, Carbon 개발 가이드 |
| 계열 | "Gemini 4 Carbon is based on Gemini 4 Argon." | DeepMind 모델 카드 (Codex 열람) |
| Argon과의 차이 | "share the same 1M unified context window, built-in tools, and per-token pricing. The main difference is how many thinking tokens each model spends per turn" | What's new in Gemini 4 Carbon |
| 선택 기준 | Argon은 "ideal for most advanced software engineering and knowledge work tasks", Carbon은 깊은 탐색·장시간 검증용 | 같은 문서, GA 발표 |
| 이행 | "requires no request schema changes" (Argon에서) | 같은 문서 |
| 모델 ID | `gemini-4-carbon`(Stable). Cloud에 `gemini-4-carbon-cyber-permissive`(기본 `HIGH`) | 모델 페이지, Cloud 개발 가이드 |

### 2.2 계약과 가격

- 입력·사고·출력은 1,048,576토큰 창을 공유합니다. 사고를 포함한 총 출력 기본 한도는 65,536토큰이며, 장문 출력으로 입력을 뺀 나머지까지 늘립니다. 이어 쓰기 한 구간의 상한은 백그라운드·스트리밍에서 65,536토큰, 비스트리밍에서 32,768토큰입니다. `thinking_level`은 `low`·`medium`(기본)·`high`입니다.
- 명시 캐싱 없음, 암시 캐싱 4,096토큰 이상·적중 입력 95% 할인. Cloud는 내구 캐싱이 기본입니다.
- `thinking_budget`은 Gemini API GenerateContent에서 경고 후 가까운 수준으로 바뀌고 Cloud에서는 400입니다. Cloud는 `MINIMAL`, `frequency_penalty`·`presence_penalty`, `candidate_count > 1`도 400입니다. 샘플링 인자는 무시됩니다.
- 가격(Gemini Developer API): 11/30까지 $2 / $10(캐시 $0.10), 12/1부터 $4 / $20(캐시 $0.20). Argon도 같은 일정입니다. 무료 등급은 없습니다. Cloud 요율은 따로 대조하지 않았습니다.
- 공식 개발 가이드는 Argon과 같은 다섯 운용 팁에 더해 역할 분담을 적습니다: "Assign gemini-4-carbon to roles that benefit most from deep reasoning, such as upfront architecture, task coordination, and final verification (including in Google Antigravity's /swarm preview), while delegating parallel implementation slices to gemini-4-argon or gemini-3.8-flash." 레포에는 위임 의무가 아닌 선택지로 옮겼습니다.

### 2.3 agy 이용 조건

- 11/10 발표와 Antigravity 모델 표는 Google AI Ultra 구독자(Free·Plus·Pro 미지원)와 Enterprise에서 Carbon을 엽니다. agy 1.5.5 변경 기록은 ADC 로그인(`AGY_ADC_AUTH`)에 Carbon Low·Medium·High를 더했다고 적습니다.
- 이 장비의 `agy models`(Google 계정 로그인)에는 Carbon이 없습니다. 계정 자격과 Carbon 전용 쿼터 버킷은 확인하지 못해 상태줄은 바꾸지 않았습니다.

## 3. 기존 문서에서 바로잡은 서술

Codex 최종 점검의 이력 검사·CMEK 지적을 반영하면서, 같은 원문을 대조해 Mythos 5.1 서술도 함께 정정했습니다. 같은 서술이 있던 다른 모델 가이드도 함께 고쳤습니다.

| 기존 서술 | 현재 원문 |
|---|---|
| 2026-08-31 이전 계정은 `prefix_mismatch_behavior`를 설정해야만 검사 (Fable 5.1·Opus 5.5·Sonnet 5.5·Haiku 5.5) | 필드를 비우면 "Enforcement varies by account". 설정하면 어느 계정이든 그 설정대로 (Preserved thinking) |
| Mythos 5.1은 이 검사를 하지 않음 | Claude API 기준으로 계정 생성일과 관계없이 "Enforced (400 error)" (같은 문서). Bedrock에서는 5.1이 이력 편집 요청을 받아들이고 5.2부터 400 (Migration guide) |
| CMEK 조직은 structured outputs 불가 (Opus 5.5를 포함한 강제 `tool_choice` 문단) | "Claude Opus 5.5 supports structured outputs and Claude Fable 5.2 doesn't" (Migration guide) |
| Cloud 암시 캐시 최소 6,144 | "Implicit caching applies automatically to shared prompt prefixes of 4,096 tokens or more" (Cloud Argon 개발 가이드) |
| Interactions `background=False`에서 65,536 초과는 400 | 전경 이어 쓰기 지원. `automatic_continuation: true`(SDK 기본, Python 2.34.0+·JS 2.32.0+)이면 요청한 길이까지 (Long decode) |
| Cloud 장문 출력은 GenerateContent만 | "on both the Interactions API and GenerateContent (`v1beta1`)" |
| 컴퓨터 사용 Preview | 10/30 GA (Gemini API changelog) |
| `latest-model`이 Argon 문서 | 지금은 "Latest Gemini models" 개요. Argon 원문은 `whats-new-gemini-4-argon` |

## 4. 같은 기간 다른 변경

| 공급자·날짜 | 변경 | 레포 판단 |
|---|---|---|
| Anthropic 10/28 | Messages·Token Counting 최대 요청 32MB → 128MB | 낡은 32MB 서술이 없어 변경 없음 |
| Anthropic 10/29 | 사용량·비용 분석 API 베타 | 범위 밖 |
| Anthropic 11/2 | 메시지 스레드 베타(`message-threads-2026-08-12`). 5분 무요청 시 만료, 마지막 사용 후 1시간 안에 삭제, "Your application stays the source of truth" | `llm-api-guide`에 선택지로 한 줄 |
| Anthropic 11/3 | 텍스트 워터마크 | 범위 밖 |
| Google 10/26 | GenerateContent 신규 유료 프로젝트 `store=true` 기본 | 범위 밖 |
| Google 11/2 | Gemini 2.5 Pro·Flash 폐기, 12/1부터 3.8 Flash·3.5 Flash-Lite로 자동 연결 (Gemini Developer API) | 2.5 전용 현행 자료 없음. LangChain 예제의 Vertex `gemini-2.5-flash`는 Cloud 경로라 그대로 둠 |
| Google 11/11 | Gemini Decision(판정 전용 API) | 일반 텍스트 계열 세대로 세지 않음 |
| OpenAI 11/2~11/5 | 발신 SIP, GPT-Image-2.6, GPT-6-Cyber | GPT-6 문서 변경 근거 없음 |
| Gemma·Qwen | 확인한 공식 자료에서 후속 일반 세대 출시를 찾지 못함 | Gemma 4·Qwen 3.8 유지 |

## 5. dotfiles 판단

### 5.1 반영한 변경

| 파일 | 변경 |
|---|---|
| `reference/claude-prompt-guide/claude-fable-5-2-prompt-guide.md` | 신설. 공식 스니펫 원문 수록 |
| `writing-prompts/references/claude-5-specifics.md` | 5.1 본문 유지, Fable 5.2를 체크리스트·하드 제약·effort 단서에 추가, "Fable 5.1 → 5.2 델타" 절 신설 |
| `writing-prompts/SKILL.md` | 라우팅에 `claude-fable-5-2`와 `gemini-4-carbon`, 요약 표와 참조 목록 |
| `writing-prompts/references/` `platform-differences.md`·`reasoning-params.md`·`prompt-trends-2026.md`·`sources.md`·`chain-of-thought.md`·`self-correction.md` | 상시 사고 모델 목록과 기본 effort에 5.2, Carbon 선택 기준, 출처 |
| `writing-prompts/references/gemini4-argon-patterns.md`, `gemini3-patterns.md` | 두 모델 계약 표와 Carbon 차이, 3절의 정정 (Codex 담당) |
| `reference/google-prompt-guide/gemini-4-argon-prompt-guide.md`, `gemini-3-prompt-guide.md` | 같은 구조로 Carbon 추가와 3절 정정, `latest-model` 설명 (Codex 담당) |
| `llm-api-guide/SKILL.md`, `references/anthropic-messages-api.md`, `references/common-patterns.md` | 5.2 모델 표 행과 주의사항 절, 강제 `tool_choice` 대상, 캐시 배수, 메시지 스레드. Opus 5.5 블록을 읽는 모델의 배타 문장과 Fable 5 "레거시" 표기, Opus 4.8 고속 모드 상태 정정 |
| `reference/claude-prompt-guide/` `README.md`·`claude-fable-5-1-prompt-guide.md`·`claude-opus-5-5-prompt-guide.md` | 5.2 진입점, 5.1의 "전 계정 확대 전망"을 5.2 사실로, 5.5 블록을 읽는 모델에 5.2 |
| 위 Claude 문서와 `claude-haiku-5-5-prompt-guide.md` | 3절의 이전 계정 검사·Mythos 5.1·CMEK 서술 정정 |
| `.antigravity/README.md` | Carbon 이용 조건과 쿼터 버킷 미확인 (Codex 담당) |
| `docs/DECISIONS.md`, `reference/archive/README.md` | 서브에이전트 Opus 강제의 근거 문장, Gemini 계열 표기 |

### 5.2 유지 판단과 도입하지 않은 안

- **설정·훅·상태줄 변경 없음**: 서브에이전트 Opus 강제와 effort `high` 훅은 5.2에서도 근거가 유지되고, Carbon 쿼터 버킷은 실측 근거가 없습니다.
- **전역 규칙 변경 없음**: `communication.md`의 압축체 금지와 작업 중 만든 용어 금지는 5.2 "Communicating clearly"와 방향이 같고, 길이 상한 같은 경직 규칙이 없습니다. 위험 명령 조항은 예외와 이유를 이미 적었습니다.
- **코드 소유권 문장을 레포에 넣지 않음**: 이 레포의 최소 변경 원칙과 반대 방향이고, 공식 가이드도 사용자가 소유한 코드에는 넣지 말라고 합니다.
- **Carbon 전용 파일을 만들지 않음**: 계약이 같아 파일을 나누면 대부분이 복제되고, 같은 계열 형제 모델을 한 문서의 모델별 표로 나누는 레포 선례(GPT-6, Gemini 3.x)가 있습니다.
- **보관 이동 없음**: Fable은 5.2·5.1·5 세 세대가 모두 Active이고, Carbon은 Gemini 4 계열의 형제 모델이라 세대 수를 늘리지 않습니다.

### 5.3 협의로 바뀐 판단

- Codex의 첫 제안은 Carbon 전용 가이드와 체크리스트를 새로 만드는 것이었습니다. Claude가 레포 선례와 계약 동일성을 근거로 통합을 제안했고, Claude가 확보한 Carbon 개발 가이드 원문으로 공통 처방의 근거가 확인되자 Codex가 통합에 동의했습니다.
- Claude는 Claude Code의 Fable 5.2 기본 effort를 "미확인"으로 두었으나, Codex가 찾은 model-config 원문으로 `medium`을 확정했습니다.
- `CHANGELOG.md` v2.68의 "다시 클론해야 한다"는 단정을 지우되, 기존 사본을 맞추는 방법이 옛 Git 기록까지 지운다는 뜻은 넣지 않기로 했습니다.

## 6. 미확인·상충

1. Fable 5.2의 실제 거절 빈도·속도·비용, 고속 모드의 Vertex 거부 빈도.
2. Carbon의 이 계정 노출 여부와 agy 상태줄 쿼터 버킷 이름.
3. Carbon의 Cloud 요율. Gemini Developer API 가격표만 대조했습니다.
4. Carbon 개발 가이드에 "Interactions 클라이언트 이어 쓰기가 곧 제공된다"는 예전 문장이 남아 있습니다. 전용 장문 출력 문서가 전경 이어 쓰기를 명시하므로 계약은 전용 문서를 따랐습니다.

## 7. 출처

- Anthropic: [Fable·Mythos 5.2 발표](https://www.anthropic.com/claude-fable-and-mythos-5-2) (Codex 열람) · [What's new in Claude Fable 5.2](https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2) · [Migration guide](https://platform.claude.com/docs/en/models/fable-5-2/migration-guide) · [Prompting Claude Fable 5.2](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2) · [Models overview](https://platform.claude.com/docs/en/about-claude/models/overview) · [Pricing](https://platform.claude.com/docs/en/about-claude/pricing) · [Fast mode](https://platform.claude.com/docs/en/build-with-claude/fast-mode) · [Effort](https://platform.claude.com/docs/en/build-with-claude/effort) · [Model deprecations](https://platform.claude.com/docs/en/about-claude/model-deprecations) · [Message threads](https://platform.claude.com/docs/en/build-with-claude/message-threads) · [Release notes](https://platform.claude.com/docs/en/release-notes/overview)
- Claude Code·구독: [Model configuration](https://code.claude.com/docs/en/model-config) · [Claude Fable models on your plan](https://support.claude.com/en/articles/15424964-claude-fable-models-on-your-plan) · [Claude Fable 5.2 launch offers](https://support.claude.com/en/articles/17506494-claude-fable-5-2-launch-offers) · [Claude Code CHANGELOG](https://raw.githubusercontent.com/anthropics/claude-code/main/CHANGELOG.md)
- Google: [What's new in Gemini 4 Carbon](https://ai.google.dev/gemini-api/docs/whats-new-gemini-4-carbon) · [Gemini 4 Carbon 모델 페이지](https://ai.google.dev/gemini-api/docs/models/gemini-4-carbon) · [Gemini 4 Carbon: Developer Guide](https://aistudio.google.com/learn/gemini-4-carbon-developer-guide) · [Long decode](https://ai.google.dev/gemini-api/docs/long-decode) · [Pricing](https://ai.google.dev/gemini-api/docs/pricing) · [Changelog](https://ai.google.dev/gemini-api/docs/changelog) · [Cloud Carbon 개발 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-carbon) · [Cloud Argon 개발 가이드](https://docs.cloud.google.com/gemini-enterprise-agent-platform/models/guides/gemini-4-argon) · [DeepMind 모델 카드](https://deepmind.google/models/model-cards/gemini-4-carbon/) (Codex 열람) · [GA 발표](https://blog.google/innovation-and-ai/models-and-research/gemini-models/gemini-4-carbon-now-available/)
- Antigravity: [모델 표](https://antigravity.google/docs/models/) · [Carbon과 swarm](https://antigravity.google/blog/gemini-4-carbon-in-google-antigravity) · [변경 기록](https://antigravity.google/docs/changelog/) (Codex 열람)
- 로컬 실측: `agy models`, Claude Code 2.1.322 서브에이전트 트랜스크립트
