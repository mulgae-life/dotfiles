# Claude 5 세대 (Opus 5.5 · Fable 5.1 · Opus 5) 특화 기법

## 목차
- [핵심 특징](#핵심-특징)
- [프롬프트 작성 시 하드 제약](#프롬프트-작성-시-하드-제약)
- [De-prescribe: 4.x와 반대 방향](#de-prescribe-4x와-반대-방향)
- [권장 스니펫](#권장-스니펫)
- [Effort 상호작용](#effort-상호작용)
- [Opus 5 차이점](#opus-5-차이점)
- [4.x 프롬프트 마이그레이션 체크리스트](#4x-프롬프트-마이그레이션-체크리스트)
- [Fable 5 → 5.1 델타 체크리스트](#fable-5--51-델타-체크리스트)
- [Opus 5 → 5.5 델타 체크리스트](#opus-5--55-델타-체크리스트)
- [요약](#요약)


Claude 5 세대(Fable 5.1 `claude-fable-5-1`, Mythos 5.1 `claude-mythos-5-1`, Fable 5 `claude-fable-5`, Mythos 5 `claude-mythos-5`, Opus 5.5 `claude-opus-5-5`, Opus 5 `claude-opus-5`) 특화 베스트 프랙티스입니다. 본문은 Fable 5.1 기준이고, Fable 5에도 그대로 적용됩니다(5.1 전용 항목은 그때마다 표기). Opus 5만 다른 지점은 [Opus 5 차이점](#opus-5-차이점)에, Opus 5에서 5.5로 옮길 때 확인할 지점은 [Opus 5 → 5.5 델타 체크리스트](#opus-5--55-델타-체크리스트)에 정리했습니다.
전체 가이드: [Opus 5.5](../../../../reference/claude-prompt-guide/claude-opus-5-5-prompt-guide.md) · [Fable 5.1](../../../../reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md) · [Fable 5](../../../../reference/claude-prompt-guide/claude-5-fable-prompt-guide.md) · [Opus 5](../../../../reference/claude-prompt-guide/claude-opus-5-prompt-guide.md)

## 핵심 특징

Fable 5·5.1은 **지시 따르기가 매우 강해**, 4.x에서 필요했던 상세 열거식 지시가 오히려 품질을 떨어뜨립니다. 공식 가이드의 전제도 "기존 Fable 5 프롬프트는 수정 없이 5.1에서 잘 동작한다"입니다.

### 4.x와의 차이
- **짧은 지시로 조향**: 행동 패턴을 열거하는 대신 원칙 한 문단이면 충분
- **긴 턴 기본**: 높은 effort에서 단일 요청 수 분, 자율 런 수 시간
- **병렬 서브에이전트 신뢰 가능**: 억제 가드레일 대신 위임 기준 명시
- **Safety classifier**: 사이버보안·생물학 도메인은 `stop_reason: "refusal"` 가능 (정상 200 응답)

## 프롬프트 작성 시 하드 제약

프롬프트/요청을 설계할 때 다음은 **작동하지 않거나 400 에러**입니다:

| 4.x 기법 | Fable 5·5.1 결과 | 대체 |
|----------|-------------|------|
| Prefilling (마지막 assistant 턴) | 400 에러 | Structured Outputs (`output_config.format`) 또는 시스템 프롬프트 지시 |
| `thinking: {budget_tokens}` | 400 에러 | `output_config.effort` (`low`~`max`) |
| `thinking: {type: "disabled"}` | 400 에러 (Opus 5.5도 동일, Opus 5만 effort `high` 이하에서 허용) | `thinking` 파라미터 생략 (항상 adaptive) |
| `temperature`/`top_p`/`top_k` | 400 에러 | 프롬프트로 변주 유도 (예: 4개 방향 제안 후 선택) |
| "think" 단어 회피 (Opus 4.5 팁) | 불필요 | thinking 상시 on이라 무의미 |
| **"사고 과정을 답변에 옮겨 써라"** | `reasoning_extraction` refusal 유발 | `thinking` 블록(`display: "summarized"`) 읽기 |
| 강제 `tool_choice` (`any`/`tool`) | Opus 5.5·Fable 5.1·Mythos 5.1에서 400 (`{"type":"none"}`은 유효) | `auto` + 지시문에 도구 명시 + 도구 정의 `strict: true`, 또는 JSON outputs(`output_config.format`) |

> ⚠️ 특히 마지막 항목: 기존 프롬프트의 reflection/show-your-thinking 지시("추론 과정을 먼저 서술한 후...")는 Fable 5에서 refusal → fallback 증가로 이어집니다. 마이그레이션 시 반드시 감사(audit)하세요.

## De-prescribe: 4.x와 반대 방향

Claude 4.x의 "명시적으로 요청하면 명시적으로 수행" 원칙은 Fable 5에서 **뒤집힙니다**:

❌ **4.x식 (Fable 5에서 품질 저하)**:
```
Step 1: Read the file. Step 2: Identify the bug. Step 3: Write a failing test.
Step 4: Fix the bug. Step 5: Run the test. Step 6: Summarize with sections
"Root Cause", "Fix", "Verification"...
```

✅ **Fable 5식 (목표 + 제약 + 이유)**:
```
Fix the login timeout bug. Users are getting logged out mid-checkout, which is
blocking the release. Verify the fix with a test before reporting done.
```

- 절차 열거 → 목표·성공 기준·제약 서술
- 구모델용 스캐폴딩("after every 3 tool calls, summarize...")은 제거 후 A/B 비교
- "왜"를 제공하면 스스로 관련 정보에 연결: `I'm working on [larger task] for [who]. They need [what it enables]. With that in mind: [request].`

## 권장 스니펫

공식 가이드 원문 스니펫(영문 verbatim). 상황별로 골라 시스템 프롬프트에 추가합니다. 전문은 [풀 가이드](../../../../reference/claude-prompt-guide/claude-5-fable-prompt-guide.md) 참조.

### 과잉계획 방지 (모호한 작업)
```text
When you have enough information to act, act. Do not re-derive facts already established in the conversation, re-litigate a decision the user has already made, or narrate options you will not pursue in user-facing messages. If you are weighing a choice, give a recommendation, not an exhaustive survey. This does not apply to thinking blocks.
```

### 과잉 리팩토링 방지 (높은 effort)
```text
Don't add features, refactor, or introduce abstractions beyond what the task requires. A bug fix doesn't need surrounding cleanup and a one-shot operation usually doesn't need a helper. Don't design for hypothetical future requirements: do the simplest thing that works well.
```

### 브레비티 (결론 우선)
```text
Lead with the outcome. Your first sentence after finishing should answer "what happened" or "what did you find". Supporting detail and reasoning come after. The way to keep output short is to be selective about what you include, not to compress the writing into fragments, abbreviations, arrow chains like A → B → fails, or jargon.
```

### 진행 보고 근거화 (장기 자율 런)
```text
Before reporting progress, audit each claim against a tool result from this session. Only report work you can point to evidence for; if something is not yet verified, say so explicitly.
```

### 경계 명시 (무단 행동 방지)
```text
When the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one.
```

### 자율 파이프라인 (조기 종료 방지)
```text
You are operating autonomously. For reversible actions that follow from the original request, proceed without asking. Before ending your turn, check your last paragraph. If it is a plan, a question, or a promise about work you have not done, do that work now with tool calls. End your turn only when the task is complete or you are blocked on input only the user can provide.
```

### 서브에이전트 위임
```text
Delegate independent subtasks to subagents and keep working while they run. Intervene if a subagent goes off track or is missing relevant context.
```

### 메모리 파일
```text
Store one lesson per file with a one-line summary at the top. Record corrections and confirmed approaches alike, including why they mattered. Don't save what the repo or chat history already records; update an existing note rather than creating a duplicate; delete notes that turn out to be wrong.
```

## Effort 상호작용

프롬프트와 `output_config.effort`는 함께 튜닝합니다:

| effort | 용도 | 프롬프트 주의 |
|--------|------|--------------|
| `xhigh` | 최고 난도 코딩·에이전트 | 과잉 리팩토링 방지 스니펫 권장, `max_tokens` 넉넉히 |
| `high` | Fable 5·5.1·Opus 5의 기본값 (대부분 작업) | — |
| `medium`/`low` | 루틴·저지연 | Fable 5의 low가 구모델 xhigh를 능가하기도 — 프롬프트로 깊이 보정하지 말고 effort부터 조정 |

**Fable 5.1 단서**: 기본값 `high`에서 시작하되 `low`~`max` 전 레벨을 자체 eval로 다시 측정하세요. effort 레벨 이름이 모델 간 같은 사고량을 뜻하지 않아, Fable 5에서 정한 값을 그대로 옮기면 안 됩니다(5.1의 `medium`이 Fable 5 성능에 근접).
`xhigh`/`max`는 긴 산출물을 사고 안에서 먼저 초안 작성한 뒤 답변으로 다시 쓰는 경향이 있어 지연과 출력 토큰이 늘어납니다. 측정된 품질 이득이 있을 때만 쓰고, 쓸 때는 `max_tokens`를 사고 몫까지 잡으세요.

**Opus 5.5 단서**: 기본값이 `medium`입니다(Opus 5는 `high`). `medium`에서 시작해 값을 명시하고 여러 레벨을 자체 eval로 측정하세요. 공식 테스트에서 5.5의 `medium`은 코딩·지식 작업 평가에서 Opus 5의 `high`와 같거나 앞섰고, 여러 코딩 평가에서는 `low`도 그에 근접했습니다. 같은 레벨에서도 턴당 사고가 Opus 5보다 많으므로(`xhigh`·`max`에서 특히) `max_tokens`를 사고 몫까지 잡고(에이전틱 코딩은 최대치 128K), 사고를 줄이려면 프롬프트 지시보다 effort를 먼저 낮추세요. 요청마다 최상위 `effort`를 바꾸면 프롬프트 캐시가 깨지므로, 턴별로 다른 레벨이 필요하면 메시지별 effort(beta)를 씁니다.

## Opus 5 차이점

Opus 5(2026-07 GA, $5/$25 — Fable 5 절반 가격)는 Claude 5 세대 공통 원칙(de-prescribe, 스캐폴딩 삭제)을 공유하되, 다음이 Fable 5와 다릅니다.

| 축 | Fable 5 | Opus 5 |
|----|---------|--------|
| **thinking** | 항상 켜짐, `disabled` 400 | 기본 켜짐, `disabled`는 effort `high` 이하에서만 허용 (`xhigh`/`max` 조합 400) |
| **effort 전략** | `high` 기본, low도 구모델 xhigh급 | **`high` 시작 + `low`/`medium` 적극** — 4.7/4.8의 `xhigh` 권고 역전. 구모델 설정 재사용 금지 |
| **서브에이전트** | 억제 대신 적극 활용 + 위임 기준 | **과잉 위임 모델 — 상한 명시** ("Do not delegate work you can finish yourself in a handful of tool calls") |
| **검증 지시** | 자기검증 서브에이전트 권장 | **검증·자기점검 지시 삭제** — 스스로 검증하므로 지시가 과잉 검증 유발. "자기 검증을 요청하라" 통념의 예외 |
| **거부율** | 생물학·사이버 오탐 잦음 | 낮음 (사이버 분류기만) — Fable 오탐 주제의 우회 경로로 활용됨 |
| **분업 기준** | 열린 작업 (아키텍처·불분명한 조사·수일 자율 런) | 제약 있는 작업 (스펙·버그 수정·범위 정해진 리팩토링) |

**Opus 5 추가 주의**: 장황함은 effort로 안 줄어듦(사고량만 조절) — 응답·산출물 길이는 프롬프트로 별도 지시. 요청 범위 확장 경향 — 범위 규율 스니펫 권장. 기존 프롬프트는 기본 동작에 **누적**되므로 레거시 워크어라운드는 삭제가 기본. 스니펫 원문은 [Opus 5 풀 가이드](../../../../reference/claude-prompt-guide/claude-opus-5-prompt-guide.md) 참조.

## 4.x 프롬프트 마이그레이션 체크리스트

- [ ] Prefill 의존 제거 → Structured Outputs 또는 지시로 대체
- [ ] `budget_tokens`·sampling 파라미터 제거 (400 에러)
- [ ] "사고 과정 서술" 지시 제거 (`reasoning_extraction` refusal)
- [ ] 단계별 절차 열거 → 목표·제약·이유 서술로 재작성 후 A/B
- [ ] 서브에이전트 억제 문구 → 위임 기준 명시로 교체
- [ ] 강제 진행 보고 스캐폴딩("N번마다 요약") 제거 — 기본 동작이 이미 우수
- [ ] 잔여 토큰 카운트를 모델에 노출하는 하네스 수정 (컨텍스트 불안 유발)
- [ ] refusal 처리 + fallback 구성 (API 통합 시 — `fallbacks: "default"` 허용 대상은 Opus 4.8·Opus 5)

## Fable 5 → 5.1 델타 체크리스트

Fable 5 프롬프트는 그대로 동작하지만, 아래 4건은 5.1에서 새로 확인해야 합니다.

- [ ] **강제 `tool_choice` 제거**: `any`/`tool`은 400 → `auto` + 지시문 + `strict: true`. 특정 턴에만 도구 호출이 필요하면 최신 user 턴 뒤 mid-conversation 시스템 메시지로 요구
- [ ] **대화 이력 append-only**: 사고 블록은 그 대화에서만 유효합니다. 턴별 리마인더 주입·삭제, 이력 요약 덮어쓰기, 세션 중 system·tools 변경은 다음 요청을 400으로 만듭니다. assistant 턴은 반환된 그대로(빈 블록 포함) 다시 보내고, 턴별 리마인더는 턴 한정 시스템 메시지(`clear_at: "next_user_message"`)로 붙이세요
- [ ] **effort 재측정**: `high` 시작 + 전 레벨 재스윕 → [Effort 상호작용](#effort-상호작용)
- [ ] **진행 업데이트 수신 설정**: 5.1은 도구 호출 사이 사용자 대상 텍스트를 덜 씁니다. 짧은 메모는 진행 업데이트 `thinking` 블록으로 오므로 `thinking.display`를 `"updates"`(또는 `"summarized"`)로 두고, "결과는 최종 응답에 모아라" 같은 억제 지시를 먼저 제거하세요

5.1 전용 대응 스니펫(산문 밀도, 채팅 서식, 인용 표시, 작업 완주, 범위·테스트 제한, 파일 전체 재작성 억제)의 영문 원문은 [Fable 5.1 풀 가이드](../../../../reference/claude-prompt-guide/claude-fable-5-1-prompt-guide.md)를 참조하세요.

## Opus 5 → 5.5 델타 체크리스트

공식 전제는 "기존 Opus 5 프롬프트는 수정 없이 잘 동작하고, Opus 5 가이드의 패턴은 여전히 합리적인 출발점"입니다. 아래 항목은 실행 환경이나 관찰된 문제에 해당할 때만 적용하고, 모든 프롬프트에 기본으로 넣지 않습니다.

- [ ] **effort 재보정** (모든 통합): `medium` 시작 + 여러 레벨 측정 → [Effort 상호작용](#effort-상호작용)
- [ ] **thinking을 끄고 쓰던 통합**: `disabled`는 400입니다. `low`에서 시작해 측정하고 품질이 떨어지면 `medium`으로 올립니다. 사고 대신 응답에 추론을 쓰게 하던 지시는 `reasoning_extraction` 거절을 부르므로 지우고 `display: "summarized"` thinking 블록에서 읽습니다. Opus 5에서 thinking을 끌 때만 필요했던 보완 지시는 여전히 필요한지 다시 확인하고, "생각하지 마라" 규칙은 어느 경우든 삭제합니다
- [ ] **강제 `tool_choice`·대화 이력**: Fable 5.1과 같습니다 → 위 [Fable 5 → 5.1 델타](#fable-5--51-델타-체크리스트)의 첫 두 항목
- [ ] **진행 업데이트가 안 보임**: 도구 사이 메모가 `text`가 아니라 `thinking` 블록으로 오고 기본값에서는 비어 있으므로 `display: "updates"`로 받습니다. 더 잦은 업데이트가 필요하면 시스템 프롬프트에 명시하고(사람이 보는 작업에서 효과가 큼), 그래도 무음이 길면 하네스가 턴 한정 시스템 메시지로 짧은 리마인더를 붙이되 2~3회에서 멈춥니다
- [ ] **무인 에이전트가 중간에 멈춤** (무인 실행만): 진행 보고로 턴을 끝내는 경우가 있습니다. 텍스트만 있는 `end_turn`을 완료로 보지 말고, 체크리스트를 유지하며 남은 항목을 짧은 user 메시지로 알려 이어가되 같은 작업에서 2~3회 뒤에는 멈춥니다. 공식 시스템 프롬프트 추가문은 세션 첫 요청부터 넣어야 하고, 사람이 응답하는 환경에서는 빼라고 명시합니다
- [ ] **사용자가 붙여넣은 텍스트 속 지시를 따름** (붙여넣기를 받는 앱): 붙여넣은 블록을 같은 랜덤 ID의 `<pasted_content>` 여닫는 태그로 감싸고 시스템 프롬프트에 안내문을 넣습니다. 태그는 흉내 낼 수 있으므로 다른 주입 방어와 함께 씁니다
- [ ] **채팅 응답 시작이 느림**: "답하기 전에 신중히 생각하라"류 지시를 제거하는 것을 검토합니다. 이전 답을 다시 검토하지 말라는 두 문장은 긴 분석이나 에이전트 작업에는 넣지 않습니다
- [ ] **여러 앱을 오가는 자동화가 과제에 명시되지 않은 정보를 놓침**: 행동 전에 관련 자료를 넓게 훑으라는 한 문장을 넣고, 검색 대상에 신뢰할 수 없는 내용이 섞이지 않게 합니다
- [ ] **다중 에이전트 팀을 더 빨리 끝내고 싶음**: 하네스가 `elapsed 340s / 1200s` 같은 경과/예산 줄을 붙이면 모델이 속도를 조절합니다. 예산은 권고이므로 강제 종료는 자체 타임아웃으로 합니다
- [ ] **시각 입력·프런트엔드**: 구모델용 시각 입력 보조 장치는 다시 시험하고, 가장 조밀한 입력에는 자르기·확대 도구가 여전히 효과가 있습니다. 프런트엔드는 "AI 느낌을 피하라" 대신 피할 패턴을 이름으로 나열합니다
- [ ] **refusal 범주 추가** (API 통합): `bio`와 `reasoning_extraction`이 새로 생겼습니다. `reasoning_extraction` 거절은 서버 폴백이 재시도하지 않고 그대로 돌려줍니다

영문 원문 스니펫은 [Opus 5.5 풀 가이드](../../../../reference/claude-prompt-guide/claude-opus-5-5-prompt-guide.md)를 참조하세요.

## 요약

| 특징 | 설명 |
|------|------|
| **De-prescribe** | 지시 열거 대신 목표·제약·이유 — 과잉 지시는 품질 저하 |
| **하드 제약** | prefill·budget_tokens·sampling·thinking off 전부 400 |
| **추론 노출 금지** | show-your-thinking 지시 → refusal. `thinking` 블록으로 대체 |
| **긴 턴** | 수 분~수 시간 기본. 타임아웃·비동기 구조 선행 |
| **서브에이전트** | 억제 대신 적극 활용 + 위임 기준 |
| **메모리** | 교훈 파일 제공 시 성능 향상 |

**핵심**: "지시를 늘리지 말고, 목표와 이유를 주고, 검증을 시켜라"
