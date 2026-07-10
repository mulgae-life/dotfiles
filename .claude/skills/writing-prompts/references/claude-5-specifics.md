# Claude 5 (Fable 5) 특화 기법

## 목차
- [핵심 특징](#핵심-특징)
- [프롬프트 작성 시 하드 제약](#프롬프트-작성-시-하드-제약)
- [De-prescribe: 4.x와 반대 방향](#de-prescribe-4x와-반대-방향)
- [권장 스니펫](#권장-스니펫)
- [Effort 상호작용](#effort-상호작용)
- [4.x 프롬프트 마이그레이션 체크리스트](#4x-프롬프트-마이그레이션-체크리스트)
- [요약](#요약)


Claude 5 세대(Fable 5 `claude-fable-5`, Mythos 5 `claude-mythos-5`) 특화 베스트 프랙티스입니다.
전체 가이드(스니펫 원문 전체 + API 변경 상세): [claude-5-fable-prompt-guide.md](../../../../reference/claude-prompt-guide/claude-5-fable-prompt-guide.md)

## 핵심 특징

Fable 5는 **지시 따르기가 매우 강해**, 4.x에서 필요했던 상세 열거식 지시가 오히려 품질을 떨어뜨립니다.

### 4.x와의 차이
- **짧은 지시로 조향**: 행동 패턴을 열거하는 대신 원칙 한 문단이면 충분
- **긴 턴 기본**: 높은 effort에서 단일 요청 수 분, 자율 런 수 시간
- **병렬 서브에이전트 신뢰 가능**: 억제 가드레일 대신 위임 기준 명시
- **Safety classifier**: 사이버보안·생물학 도메인은 `stop_reason: "refusal"` 가능 (정상 200 응답)

## 프롬프트 작성 시 하드 제약

프롬프트/요청을 설계할 때 다음은 **작동하지 않거나 400 에러**입니다:

| 4.x 기법 | Fable 5 결과 | 대체 |
|----------|-------------|------|
| Prefilling (마지막 assistant 턴) | 400 에러 | Structured Outputs (`output_config.format`) 또는 시스템 프롬프트 지시 |
| `thinking: {budget_tokens}` | 400 에러 | `output_config.effort` (`low`~`max`) |
| `thinking: {type: "disabled"}` | 400 에러 | `thinking` 파라미터 생략 (항상 adaptive) |
| `temperature`/`top_p`/`top_k` | 400 에러 | 프롬프트로 변주 유도 (예: 4개 방향 제안 후 선택) |
| "think" 단어 회피 (Opus 4.5 팁) | 불필요 | thinking 상시 on이라 무의미 |
| **"사고 과정을 답변에 옮겨 써라"** | `reasoning_extraction` refusal 유발 | `thinking` 블록(`display: "summarized"`) 읽기 |

> ⚠️ 특히 마지막 항목: 기존 프롬프트의 reflection/show-your-thinking 지시("추론 과정을 먼저 서술한 후...")는 Fable 5에서 refusal → fallback 증가로 이어집니다. 마이그레이션 시 반드시 감사(audit)하세요.

## De-prescribe: 4.x와 반대 방향

[claude-4-specifics.md](claude-4-specifics.md)의 "명시적으로 요청하면 명시적으로 수행" 원칙은 Fable 5에서 **뒤집힙니다**:

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
| `high` | 기본값 (대부분 작업) | — |
| `medium`/`low` | 루틴·저지연 | Fable 5의 low가 구모델 xhigh를 능가하기도 — 프롬프트로 깊이 보정하지 말고 effort부터 조정 |

## 4.x 프롬프트 마이그레이션 체크리스트

- [ ] Prefill 의존 제거 → Structured Outputs 또는 지시로 대체
- [ ] `budget_tokens`·sampling 파라미터 제거 (400 에러)
- [ ] "사고 과정 서술" 지시 제거 (`reasoning_extraction` refusal)
- [ ] 단계별 절차 열거 → 목표·제약·이유 서술로 재작성 후 A/B
- [ ] 서브에이전트 억제 문구 → 위임 기준 명시로 교체
- [ ] 강제 진행 보고 스캐폴딩("N번마다 요약") 제거 — 기본 동작이 이미 우수
- [ ] 잔여 토큰 카운트를 모델에 노출하는 하네스 수정 (컨텍스트 불안 유발)
- [ ] refusal 처리 + Opus 4.8 fallback 구성 (API 통합 시)

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
