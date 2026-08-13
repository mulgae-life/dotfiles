# Claude Opus 5 Prompting Guide

> **출처**:
> - [Prompting Claude Opus 5 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-5)
> - [What's new in Claude Opus 5 | Anthropic](https://platform.claude.com/docs/en/about-claude/models/whats-new-opus-5)
> - [Migration Guide | Anthropic](https://platform.claude.com/docs/en/about-claude/models/migration-guide)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
> - [The new rules of context engineering for Claude 5 generation models | Anthropic](https://claude.com/blog/the-new-rules-of-context-engineering-for-claude-5-generation-models)
>
> **날짜**: 2026-08-13
> **관련 조사**: [research-opus5.md](../research/research-opus5.md) · **자매 가이드**: [Claude Fable 5](./claude-5-fable-prompt-guide.md)

Claude Opus 5 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 수록했습니다 — 시스템 프롬프트에 바로 붙여 쓰는 용도이므로 번역하지 않습니다.

## 목차
- [모델 개요](#모델-개요)
- [API 변경 요약 (Opus 4.8 대비)](#api-변경-요약-opus-48-대비)
- [effort 전략: high에서 시작해 아래로](#effort-전략-high에서-시작해-아래로)
- [핵심 원칙: 스캐폴딩은 추가가 아니라 삭제](#핵심-원칙-스캐폴딩은-추가가-아니라-삭제)
- [행동 특성과 프롬프트 패턴](#행동-특성과-프롬프트-패턴)
- [thinking 비활성화 시 결함 2종](#thinking-비활성화-시-결함-2종)
- [Fable 5와의 분업](#fable-5와의-분업)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-opus-5` (GA 2026-07-24, 날짜 접미사 없음) |
| **포지션** | 복잡한 에이전틱 코딩·엔터프라이즈 작업용. Opus 4.8 대비 "step-change", Fable 5 프런티어 지능에 근접하면서 **가격 절반** |
| **컨텍스트/출력** | 1M 토큰(기본=최대), 최대 128K 출력 (Batch API는 `output-300k-2026-03-24` 베타로 300K) |
| **가격** | $5 / $25 per MTok — Opus 4.8과 동일. Fast mode $10/$50 (Claude API 전용) |
| **지식 컷오프** | 2026-05 (Opus 4.8은 2026-01) |
| **레이트리밋** | Opus 4.x 합산 풀과 **별도 버킷** |
| **캐시 최소** | 512 토큰 (4.8은 1,024) |

전제: 공식 가이드는 "It performs well out of the box on existing Claude Opus 4.8 prompts"라고 명시합니다. 아래 조정은 자주 필요한 행동에 한정됩니다.

**미지원 주의**: web fetch 도구 미지원(대안 필요), Priority Tier 미지원.

## API 변경 요약 (Opus 4.8 대비)

| 항목 | Opus 5 동작 |
|------|-------------|
| **Thinking 기본값** | `thinking` 생략 시 **adaptive로 실행** (4.8은 사고 없음). `max_tokens`는 사고+응답 합산 하드 리밋 — 사고 없이 돌던 워크로드는 재검토 필수 |
| **Thinking 비활성화** | `{"type": "disabled"}`는 effort `high` 이하에서만. `xhigh`/`max` 조합은 400 (요청 단위 검증) |
| **Sampling / Prefill** | 4.7 이후와 동일하게 400 (신규 변경 없음) |
| **Fallbacks** | `fallbacks: "default"` (beta `server-side-fallback-2026-07-01`) — 거절 카테고리별 권장 폴백 자동. 사이버 거절은 Opus 4.8로 라우팅 |
| **도구 변경** | beta `mid-conversation-tool-changes-2026-07-01` — `tool_addition`/`tool_removal` 블록 + `defer_loading`으로 턴 사이 도구 변경, 캐시 보존 |
| **Refusal** | 사이버 분류기 탑재. HTTP 200 + `stop_reason: "refusal"` — content 읽기 전 확인 |

## effort 전략: high에서 시작해 아래로

Opus 4.7/4.8의 "코딩엔 `xhigh`" 권고가 **역전**됐습니다. 공식 원문:

> Start with `high`, the default, and adjust based on your evals: step up to `xhigh` for demanding coding and agentic work, or to `max` when a task justifies unconstrained token spending, and use `low` and `medium` liberally as your primary control for token cost and response time wherever your evals show quality holds. If you carried effort settings over from an earlier model, run a fresh effort sweep on your evals rather than reusing them.

- `low`/`medium`에서도 품질이 강하게 유지됨 — 비용·지연 통제의 1차 수단으로 적극 사용
- 구모델에서 가져온 effort 설정 재사용 금지, 스윕 재실행
- `xhigh`/`max` 운영 시 `max_tokens` 64K 이상
- **effort는 사고량만 조절합니다.** 가시적 응답 길이는 줄지 않으므로 길이는 프롬프트로 통제 (아래 참조)
- Claude Code: v2.1.219+에서 `opus` 별칭·fast mode 기본 모델. 구모델과 달리 최초 실행 시 effort 강제 적용(hold)이 없어 **이전 세션 설정이 그대로 승계** — 구식 고정값을 확인할 것

## 핵심 원칙: 스캐폴딩은 추가가 아니라 삭제

Claude 5 세대 공통 원칙("de-prescribe")이 Opus 5에서 가장 구체화된 형태입니다. Anthropic은 Opus 5·Fable 5용 Claude Code 시스템 프롬프트를 80% 이상 삭제하고도 코딩 평가에서 손실이 없었다고 밝혔습니다("unhobbling"). 처방은 "얇은 프롬프트, 두꺼운 아티팩트와 컨텍스트, 얇은 스킬"입니다.

**삭제 대상 (유지하면 과잉 행동 유발):**

1. **검증 지시** — "include a final verification step", "use a subagent to verify", "double-check your answer" 류. Opus 5는 지시 없이 스스로 검증하므로 이런 지시는 과잉 검증만 유발합니다. 고쳐 쓰지 말고 삭제하세요. 하네스 레벨의 별도 검증 단계도 동일합니다. **"자기 검증을 요청하라"는 일반 프롬프팅 통념을 뒤집는 지점**이므로 프롬프트 라이브러리의 일괄 규칙에는 예외가 필요합니다.
   - 단, 모델 외부의 구체적 검증(테스트 스위트, 결정론적 검사, 사람 승인 게이트)은 유지합니다.
2. **위임 장려 지시** — Opus 4.8용 "더 위임하라" 지침. Opus 5는 반대로 과잉 위임하는 모델입니다.
3. **레거시 워크어라운드 누적분** — 기존 프롬프트는 Opus 5의 기본 동작을 덮어쓰는 게 아니라 **거기에 누적**됩니다. 모델이 이미 하는 검증·서술을 한 번 더 시키면 증상이 2배가 됩니다. 커뮤니티 다수가 "백지 프롬프트가 레거시 누적보다 낫다"는 결론에 독립적으로 도달했습니다.

## 행동 특성과 프롬프트 패턴

### 1. 응답이 길다 — effort가 아니라 프롬프트로

기본 사용자 대면 응답이 이전 Opus보다 깁니다. 커뮤니티 최다 불만이기도 합니다("Claude Slop").

```text
Keep responses focused, brief, and concise. Keep disclaimers and caveats short, and spend most of the response on the main answer. When asked to explain something, give a high-level summary unless an in-depth explanation is specifically requested.
```

긴 시스템 프롬프트에서는 끝부분에 짧은 리마인더를 함께 배치:

```text
<tone_preference>
Keep outputs reasonably concise.
</tone_preference>
```

### 2. 산출물 문서도 길다 — 별도 제약 필요

채팅 응답을 줄여도 디스크에 쓰는 파일(리포트·마크다운·요약)은 여전히 비대해질 수 있습니다.

```text
Match the length of written documents to what the task needs: cover the substance, but do not pad with filler sections, redundant summaries, or boilerplate.
```

### 3. 진행 내레이션 — 원하는 리듬을 명시

에이전트 작업 중 무엇을 할지 미리 알리는 경향이 강합니다. 부정 나열보다 원하는 방식의 긍정 예시가 효과적입니다.

```text
Before your first tool call, say in one sentence what you're about to do. While working, give a brief update only when you find something important or change direction. When you finish, lead with the outcome: your first sentence should answer "what happened" or "what did you find," with supporting detail after it for readers who want it.
```

### 4. 범위 확장 — 요청한 것만

요청되지 않은 단계를 추가하거나 과제를 자체 판단으로 변형하는 경우가 있습니다. 커뮤니티 최다 보고 이슈("paranoid over-engineering")이기도 합니다.

```text
Deliver what was asked, at the scope intended. Make routine judgment calls yourself, and check in only when different readings of the request would lead to materially different work. If the request seems mistaken or a better approach exists, say so in a sentence and continue with the task as asked rather than quietly narrowing, widening, or transforming it. Finish the whole task, and stop short of actions that are clearly beyond what was asked.
```

### 5. 서브에이전트 과잉 위임 — 상한 명시 (4.8과 정반대)

```text
Delegate to a subagent only for large tasks that are genuinely independent and parallelizable, such as a wide multi-file investigation. Do not delegate work you can finish yourself in a handful of tool calls, and do not use subagents to verify or double-check your own work. If one subagent can complete the task, use one rather than several, and keep spawn counts low.
```

### 6. 자기 수정 내레이션 축소

정정을 장황하게 서술하고 과잉 사과하는 경향이 있습니다.

```text
Only correct an earlier statement when the error would change the user's code, conclusions, or decisions. State corrections plainly and briefly, then continue the task. For slips that change nothing for the user, make the fix and move on without noting it.
```

### 7. 코드 리뷰 — 필터는 별도 패스로

"only report high-severity issues", "be conservative"를 문자 그대로 따르므로, 실제 탐지력이 올라갔는데도 측정 recall이 떨어질 수 있습니다. 전부 보고받고 필터링은 별도 단계로 분리하세요.

### 8. 역량별 메모

- **에이전트 코딩**: 전체 작업 명세를 처음에 한 번에 주고 실행하게 둘 때 성능이 최고. stub·placeholder를 남기지 않고 완주함
- **비전**: 반복 분석·크롭·시각 검증할 **도구를 주는 것**이 사고량을 늘리는 것보다 비용 효율적. 구모델용 비전 우회 프롬프트는 재검증
- **오피스 문서**: 다중 시트 스프레드시트·슬라이드 강함. 따라야 할 스타일·템플릿은 명시적으로 지시

## thinking 비활성화 시 결함 2종

`thinking: {"type": "disabled"}` 사용 시에만 해당합니다 (기본은 켜짐).

1. **도구 호출 평문 유출**: 구조화된 `tool_use` 블록 대신 사용자 대면 텍스트에 도구 호출을 씁니다. 턴은 정상 종료되고 호출은 실행되지 않으며 에러도 없습니다. 에이전트 루프에서는 그 텍스트가 히스토리에 남아 이후 턴을 오염시킵니다.
2. **내부 XML 태그 유출**: `<thinking>` 등 내부 태그가 가시 응답에 섞입니다. "사고하지 마라 / 추론하지 마라" 규칙이 있으면 **오히려 유출이 늘어나므로 삭제**해야 합니다.

1차 완화책은 thinking을 켠 채 effort를 낮추는 것입니다. 공식: "for most tasks, thinking enabled at `low` effort performs better than thinking disabled at similar cost". 불가피하게 꺼야 하면:

```text
When you use a tool, you may say a brief sentence first. If no tool can express what the user asked for, say so instead of guessing. Do not include internal or system XML tags in your response.
```

사고 태그를 이름으로 지목하는 지시는 이 일반형보다 효과가 떨어집니다.

## Fable 5와의 분업

커뮤니티 컨센서스 기준은 **"제약의 유무"**입니다.

| | Opus 5 | Fable 5 |
|---|---|---|
| 잘 맞는 작업 | 제약 있는 작업 — 스펙 구현, 버그 수정, 범위 정해진 리팩토링, 잘 정의된 퍼즐 | 열린 작업 — 아키텍처 설계, 대규모 마이그레이션, 불분명한 조사, 수 시간~수일 자율 실행 |
| 가격 | $5/$25 | $10/$50 (2배) |
| 거부율 | 낮음 (GPQA 거부율 0% 측정) | 오탐 잦음 (동일 측정 42%) — 생물학·보안 인접 주제는 Opus 5가 우회 경로 |
| 판단 한 줄 | 실행 비용 대비 효율이 중요할 때 | **초기 계획의 품질이 실행 비용보다 중요할 때만** |

두 모델은 같은 Claude 5 세대 컨텍스트 엔지니어링 규칙(프롬프트 감량·검증 스캐폴딩 삭제·위임 절제)을 공유합니다. 단 effort 세부(`high` 초과에서 thinking 비활성화 불가)는 Opus 5 기준 문서이므로 Fable 5에 그대로 옮기기 전에 확인이 필요합니다.

## 요약

| 할 일 | 내용 |
|-------|------|
| **effort** | `high`에서 시작, `low`/`medium`을 비용 통제 1차 수단으로. 구모델 설정 재사용 금지 |
| **삭제** | 검증·자기 점검 지시, 위임 장려 지시, 레거시 워크어라운드 — 추가가 아니라 삭제가 기본 동작 |
| **추가** | 간결성 지시(응답·산출물 별도), 범위 규율, 위임 상한, 수정 내레이션 축소 |
| **thinking** | 켜 둔 채 effort로 조절. 끄면 도구 호출 유출·태그 유출 결함 |
| **max_tokens** | 사고+응답 합산 리밋 — `thinking` 생략하던 워크로드 재검토, `xhigh`/`max`는 64K+ |
| **refusal** | `stop_reason` 확인 + `fallbacks: "default"` 베타 |
| **미지원** | web fetch, Priority Tier |
