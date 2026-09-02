# Claude Fable 5.1 Prompting Guide

> **출처**:
> - [Prompting Claude Fable 5.1 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-1)
> - [What's new in Claude Fable 5.1 | Anthropic](https://platform.claude.com/docs/en/models/fable-5-1/whats-new-fable-5-1)
> - [Migrating to Claude Fable 5.1 and Claude Mythos 5.1 | Anthropic](https://platform.claude.com/docs/en/models/fable-5-1/migration-guide)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
>
> **날짜**: 2026-09-02
> **관련 조사**: [research-fable51.md](../research/research-fable51.md) · **자매 가이드**: [Claude Fable 5](./claude-5-fable-prompt-guide.md) · [Claude Opus 5](./claude-opus-5-prompt-guide.md)

Claude Fable 5.1 / Mythos 5.1 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 수록했습니다 — 시스템 프롬프트에 바로 붙여 쓰는 용도이므로 번역하지 않습니다.

## 목차
- [모델 개요](#모델-개요)
- [API 변경 요약 (Fable 5 대비)](#api-변경-요약-fable-5-대비)
- [effort 전략: high에서 시작해 전 레벨 재측정](#effort-전략-high에서-시작해-전-레벨-재측정)
- [행동 변화 7건과 처방](#행동-변화-7건과-처방)
- [작업 완주·범위·테스트 제한](#작업-완주범위테스트-제한)
- [에이전트 운영 항목](#에이전트-운영-항목)
- [Fable 5 가이드에서 빠진 항목](#fable-5-가이드에서-빠진-항목)
- [마이그레이션 체크리스트](#마이그레이션-체크리스트)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-fable-5-1` (GA 2026-09-01) / `claude-mythos-5-1` (Project Glasswing 한정, 동일 가중치 + 완화된 안전장치) |
| **포지션** | 장시간 에이전틱 코딩·지식 작업·다단계 리서치. 공식 권고는 "대부분 워크로드는 Opus 5로 시작, 고난도 추론·장기 자율 작업이거나 Opus 5 고effort 평가가 부족할 때 Fable 5.1" |
| **컨텍스트/출력** | 1M 토큰(기본이자 최대, 전 구간 표준 단가), 최대 128K 출력 |
| **가격** | $10 / $50 per MTok — Fable 5와 동일. **캐시 읽기만 $1 → $0.25** (기본 입력가의 0.025배, 다른 모델은 0.1배) |
| **캐시 최소** | 512 토큰 (Fable 5와 동일) |
| **지식 컷오프** | 2026-06 |
| **Thinking** | adaptive 상시 켜짐. `enabled`(`budget_tokens`)·`disabled` 모두 400 |
| **토크나이저** | Fable 5와 동일 (Opus 4.7 도입분). Opus 4.7 이전 세대 대비 같은 텍스트가 약 30% 더 많은 토큰 |
| **데이터 보존** | 30일 보존 필수. ZDR 불가(Anthropic 명시 승인 예외), Covered Model 지정 |

전제: 공식 가이드는 "Your existing Claude Fable 5 prompts should perform well on Claude Fable 5.1 without changes"라고 명시합니다. 아래 처방은 관찰된 증상에 대응할 때만 추가합니다.

**미지원 주의**: Fast mode 미지원(Opus 5·4.8 전용), Priority Tier 미지원(Fable 5는 지원), 300K 출력 배치 베타(`output-300k-2026-03-24`) 지원 목록에 없음.

**Claude Code**: 2.1.255 이상 필요하고 2.1.257부터 `fable` 별칭이 5.1을 가리킵니다. Claude apps 게이트웨이 세션에서는 당분간 `fable`이 Fable 5로 유지되므로 `/model`에서 직접 선택합니다. 기본 effort는 Claude Code가 `high`, Claude Cowork와 claude.ai가 `medium`입니다.

## API 변경 요약 (Fable 5 대비)

### 파괴적 변경 3건

| 항목 | Fable 5.1 동작 |
|------|----------------|
| **강제 도구 호출 금지** | `tool_choice`가 `{"type": "any"}` 또는 `{"type": "tool", "name": ...}`이면 400 `invalid_request_error`. 토큰 카운트 엔드포인트에도 동일 적용. 사고가 상시 켜져 있어 강제 호출이 사고를 건너뛰고 모델이 도구 인자에 작업 내용을 쓰게 되는 것이 이유. 대안은 `auto` + 프롬프트에 도구 적용 시점 명시 + `strict: true`, 또는 structured outputs |
| **사고 블록 단방향 호환** | 사고 블록은 생성 모델과 그 이후 모델만 읽습니다. 5.1은 Opus 5·Fable 5·Mythos 5·이전 모델의 블록을 읽지만 역방향은 불가. 읽을 수 없는 블록은 API가 드롭하고 과금하지 않으며, `thinking-binding-controls-2026-08-01` 베타 헤더를 붙이면 `input_transformations`에 보고 |
| **이전 턴 편집 시 사고 블록 무효화** | 사고 블록 앞의 `system`·`tools`·이전 메시지를 바꾸면 다음 요청이 400(`The block is bound to a different conversation`), 옵트인 시 드롭. 2026-08-31 이후 생성 계정은 기본 강제, 이전 계정은 `thinking.block_binding.prefix_mismatch_behavior` 설정 시에만 동작. Mythos 5.1은 이 검사를 하지 않음 |

무효화를 유발하는 패턴: 이전 턴을 편집·재정렬·삭제하고 이후 턴을 남기기, 턴별 리마인더를 이전 턴에 주입했다가 다음 요청에서 제거하기, 세션 중 `system`·`tools` 배열 재구성, 같은 URL이 다른 바이트를 반환하는 이미지·문서.

허용되는 조작: 선두 사고 블록을 오래된 것부터 연속으로 제거, 서버측 compaction·context editing, `cache_control` 마커 이동, 요청 간 `effort` 변경.

### 추가 기능 5건

| 기능 | 베타 헤더 | 내용 |
|------|-----------|------|
| **메시지별 effort** | `mid-conversation-output-config-2026-07-01` | `messages` 안 `role: "system"` 메시지에 `output_config: {effort}`만 실어 보내면 다음 user 턴부터 적용. 프롬프트 캐시 유지. Fable 5.1·Mythos 5.1·Opus 5 지원 |
| **턴 한정 시스템 메시지** | `mid-conversation-system-clear-at-2026-08-21` | `role: "system"` + `clear_at: "next_user_message"`. 현재 턴에는 시스템 프롬프트 권한을 갖고, 이후 user 메시지가 생기면 렌더링이 멈춤. 배열에는 그대로 남겨 재전송하며 토큰 비용 0, 캐시·사고 블록 유지 |
| **진행 업데이트 표시** | `thinking-display-updates-2026-08-18` | `thinking.display: "updates"`로 추론은 숨긴 채 도구 호출 직전 진행 업데이트만 텍스트로 수신. `"summarized"`는 요약 추론과 함께 반환 |
| **캐시 읽기 인하** | — | $1 → $0.25/MTok. 캐시 쓰기와 512토큰 최소 길이는 그대로 |
| **콘텐츠 출처 표시** | — | 모든 플랫폼의 텍스트에 통계적 워터마크(토큰·숨은 문자 추가 없음), Files API로 받는 이미지·비디오에 C2PA 서명 |

### 변경 없음 · 폴백

Fable 5에서 그대로 이어지는 항목: adaptive 상시 켜짐, `thinking.display` 기본 `"omitted"`, 도구 호출 사이 추론은 텍스트가 아니라 사고 블록에 담기고 interleaved thinking은 헤더 없이 자동, 프리필 400, 비기본 `temperature`·`top_p`·`top_k` 400, 캐시 최소 512토큰, mid-conversation 시스템 메시지·도구 변경 지원.

거부는 HTTP 200 + `stop_reason: "refusal"` + `stop_details.category`(`cyber`·`bio`·`reasoning_extraction` 등)로 옵니다. `fallbacks: "default"`(베타)의 5.1 허용 대상은 **Opus 4.8과 Opus 5**입니다. 출력 전에 도착한 거부는 과금하지 않고, 폴백 크레딧이 모델 전환에 따른 프롬프트 캐시 비용을 환불합니다.

## effort 전략: high에서 시작해 전 레벨 재측정

공식 원문:

> Start at the default effort level, `high`, then test the other levels (`low`, `medium`, `xhigh`, and `max`) against your own evals. Effort is the primary control for trading off intelligence, latency, and cost on Claude Fable 5.1. Re-run the sweep even if you already ran one on Claude Fable 5: effort level names don't correspond to the same amount of thinking across models.

- 5.1의 역량 향상은 전 레벨에 걸쳐 나타나고 높은 레벨일수록 격차가 큽니다.
- `medium`은 Fable 5 수준의 결과를 더 낮은 비용으로 냅니다. 평가에서 품질이 유지되면 `medium`·`low`로 내려가세요.
- `low`는 작업당 비용에서 Opus·Sonnet과 경쟁하면서 점수는 더 높은 경우가 많으므로, 원래 작은 모델을 높은 effort로 돌리려던 자리에 후보로 넣으세요.
- Fable 5에서 스윕을 이미 돌렸더라도 다시 돌립니다. 레벨 이름이 모델 간 같은 사고량을 뜻하지 않기 때문입니다.
- 시스템 카드 FrontierCode 측정에서 5.1은 **`medium`이 정점**이고 `high` 이상에서는 요청 범위 밖 파일 수정(인접 파일 주석, 문서, 불필요한 CI 잡)으로 점수가 오히려 낮아졌습니다. 간결성 지시를 더하면 완화됩니다.
- effort 전용 행동 2건은 별도 절에 있습니다. `low`에서는 검색·검색증강 도구 호출이 줄고, `xhigh`·`max`에서는 긴 산출물을 쓰기 전에 오래 생각합니다.

## 행동 변화 7건과 처방

### 1. 진행 업데이트가 줄어듦

5.1은 긴 도구 호출 턴 동안 Fable 5보다 사용자 대상 텍스트를 덜 씁니다. effort가 높고 도구 체인이 길수록 두드러져, 사용자가 보기에 에이전트가 몇 분씩 조용해지거나 최종 메시지가 마지막 단계만 다루게 됩니다.

먼저 클라이언트가 진행 업데이트를 받고 있는지 확인하세요. 모델이 도구 호출 사이에 쓰는 짧은 메모는 진행 업데이트 `thinking` 블록으로 오고, 기본 `display: "omitted"`에서는 그 블록이 비어 있습니다. `display: "updates"`(베타 `thinking-display-updates-2026-08-18`)를 설정하고 비어 있지 않은 `thinking` 블록을 상태 줄로 렌더링하거나, `"summarized"`로 요약 추론과 함께 받으세요.

다음으로 내레이션을 억제하는 지시를 감사하세요. 구모델이 업데이트를 과하게 쓰던 탓에 생긴 "hold all findings for the final response" 같은 줄을 먼저 제거하고, 그래도 부족하면 추가합니다.

```text
Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own — what you found, what you did, and what's next — so a reader who only sees the last message has the full picture.
```

제품이 도구 출력을 접거나 숨긴다면 그 사실을 모델에게 알리세요. 그러지 않으면 사용자에게 보여주겠다며 UI가 표시하지 않는 명령을 실행합니다. 턴 한정 시스템 메시지(`clear_at: "next_user_message"`, 베타)로 전달합니다.

```text
Only you see that command's output — the user's terminal shows at most a few lines of it. If the user needs to read any of it, put it in your reply.
```

### 2. 병렬 도구 호출이 1턴 1호출로 퇴화

요청이 가져올 대상을 여러 개 지목하면 5.1도 병렬로 호출합니다. 예외는 다음 독립 호출이 명시되지 않고 작업에서 암시되기만 하는 코딩·컴퓨터 사용 루프(커스텀 코딩 에이전트, bash·에디터 하네스, 컴퓨터 사용)입니다. 답변 품질은 떨어지지 않지만 턴마다 토큰·왕복·실제 시간이 듭니다. 현재 요청 끝에 한 문장이면 해결됩니다.

```text
First privately list what you need next; then request every item that doesn't depend on another's result in this one response.
```

도구 결과를 돌려보낼 때마다 그 user 메시지 뒤에 턴 한정 시스템 메시지로 이 문장의 새 사본을 붙입니다. 이후 user 메시지가 생기면 API가 이전 사본을 렌더링에서 제외하므로 모델은 최신 것만 읽습니다. 베타를 쓰지 않으면 같은 user 메시지의 `tool_result` 블록 뒤에 텍스트 블록으로 넣습니다.

**이전 사본은 바이트 단위로 그대로 두세요.** 배열에 남아 있어도 렌더링이 멈춘 뒤에는 모델이 보지 않고 입력 토큰도 들지 않습니다. 삭제하거나 고쳐 쓰는 것은 이전 턴 편집이므로 프롬프트 캐시가 그 지점부터 다시 시작되고 이후 사고 블록이 무효화됩니다.

### 3. 대화 이력은 append-only

각 assistant 턴을 API가 반환한 그대로(사고 블록 포함) 이력에 덧붙이고, 요청 사이에 이전 턴을 편집하지 마세요. 2026-08-31 이후 생성된 계정에서는 5.1의 사고 블록이 그것을 만든 대화에서만 유효합니다. 접두부(시스템 프롬프트·도구 목록·이전 메시지)가 바뀐 뒤 사고 블록을 재전송하면 400이 반환되고, `thinking.block_binding.prefix_mismatch_behavior: "drop_block"`(베타 `thinking-binding-controls-2026-08-01`)을 설정하면 해당 블록이 드롭됩니다. 이후 모델에서는 전 계정으로 확대될 전망이므로 지금 도입하는 편이 낫습니다.

검사에 걸리는 편집은 프롬프트 캐시를 재시작시키는 편집과 같습니다. 턴별 리마인더를 주입했다 제거하기, 이전 턴을 제자리에서 요약하기, 세션 중 시스템 프롬프트 바꾸기입니다. 대신 턴별 리마인더는 턴 한정 시스템 메시지로 보내고, 지시·도구 변경은 `system`·`tools`를 다시 쓰는 대신 mid-conversation 시스템 메시지로 하고, 이력 정리는 서버측 compaction이나 context editing에 맡기세요.

클라이언트에서 compaction을 한다면 가장 단순한 형태는 이력 전체를 요약 메시지 하나와 새 user 턴으로 교체하고 나머지는 재전송하지 않는 것입니다. 사고 블록이 넘어가지 않으므로 실패할 것이 없고 모델은 압축된 대화 위에서 새로 생각합니다. 캐시 읽기가 싸졌으므로 **비용을 아끼려고 일찍 압축하는 것이 더 이상 최적이 아닐 수 있습니다.** 압축 시점을 뒤로 미뤄 실험하세요.

하네스가 이미 하고 있는 편집을 찾으려면 `prefix_mismatch_behavior: "drop_block"`으로 세션을 돌려 `input_transformations`를 로그하거나, 정상 턴 몇 번의 요청을 캡처해 연속 요청이 덧붙은 턴을 제외하고 바이트 단위로 동일한지 확인하세요.

### 4. 산문이 길고 조밀함

5.1의 글은 상투구가 적고 설명 없는 전문용어도 줄어 전반적으로 개선됐지만, 경우에 따라 Fable 5보다 조밀합니다. 문장이 길어지고 단락 구분이 줄어듭니다. 안티패턴을 정의하는 지시가 효과적입니다. user 메시지(권장) 또는 시스템 프롬프트에 넣습니다.

```text
Mannered prose substitutes metaphor and flourish for direct statement. Instead of "a parameter worth varying," the mannered writer produces "a dial worth turning." Instead of "this point still matters," they write "this point earns its keep." The phrases exist to display the writer, not to convey the idea, and readers can tell. That is why mannered prose irritates: it makes the reader work harder so the writer can perform. It is also imprecise. Metaphors drag in connotations the writer did not choose and cannot control. The fix is to say what you mean. When a literal phrase is available, use it.
```

짧은 판도 대체로 통합니다.

```text
Please remove all mannered prose.
```

### 5. 채팅 서식 규칙은 방향이 반대

구모델은 채팅에서 불릿과 볼드를 과하게 썼고, 많은 프롬프트가 그것을 누르는 반서식 규칙을 그대로 안고 있습니다. 5.1은 반대쪽으로 기울어 볼드를 덜 쓰고 헤더·목록·인용부호도 덜 꺼냅니다. **프롬프트에 반서식 문구가 있으면 제거하거나, 어떤 서식이 언제 적절한지 말하는 규칙으로 교체하세요.**

```text
Use lists and bullet points when asked to, or when the content is multifaceted enough that they help with clarity. If the person explicitly requests minimal formatting, always format your responses without bullet points, headers, lists, or bold emphasis, as requested. In conversational, personal, or emotional exchanges, keep to plain prose.
```

### 6. 요약 시 무표시 인용

문서를 요약할 때 5.1은 Fable 5보다 원문 구절을 인용 표시 없이 재현하는 경향이 큽니다. 대응은 올바른 응답의 완전한 예시 하나를 시스템 프롬프트에 넣는 것입니다. 사용자 요청, 응답, 그 응답이 옳은 이유를 한 문장으로 함께 담습니다.

```text
<example>
<user>look up how the Riverton Ledger and the Coast Dispatch each covered the Harbor Bridge closure and compare their reporting</user>
<response>
[web_search: Harbor Bridge closure Riverton Ledger]
[web_search: Harbor Bridge closure Coast Dispatch]
Both outlets agree on the basics: the bridge closed on March 3 after inspectors found cracked welds, and the state expects repairs to take about eight months. Where they differ is emphasis. The Ledger treats it as a local-economy story. The Dispatch frames it as a funding failure; its editorial calls the closure "entirely foreseeable." Read together, the Ledger explains who is affected now and the Dispatch explains how it came to this — neither account alone gives the whole picture.
</response>
<rationale>CORRECT: The response is organized around where the two outlets agree and differ, not as a walk through either article. Each outlet's reporting is conveyed in one or two sentences of the assistant's own indirect speech. One short marked phrase from one source; every other claim is reworded. The response is still specific and complete.</rationale>
</example>
```

두 개의 `[web_search: ...]` 줄은 자기 도구 이름으로 바꾸세요. 그래야 모델이 그대로 출력할 텍스트가 아니라 템플릿화된 도구 출력으로 읽습니다.

### 7. 소규모 수정에도 파일 전체 재작성

5.1은 Fable 5보다 텍스트 파일 전체를 다시 쓰는 경향이 큽니다. 결과 파일은 대개 같지만, 파일이 짧거나 대부분이 바뀌는 경우가 아니면 재작성은 출력 토큰과 시간을 더 씁니다. 아래 지시를 시스템 프롬프트나 첫 user 메시지 끝에 붙이면 소·중 규모 수정에서 Fable 5 수준으로 돌아옵니다.

```text
The number of tokens used to edit files is best minimized, all else being equal. Therefore, when it will not affect the end result, try to surgically edit a file rather than rewrite the entire thing.
```

## 작업 완주·범위·테스트 제한

### 작업 완주

5.1은 목표가 분명하면 방법론을 크게 일러주지 않아도 아주 긴 작업을 수행합니다. 다만 복잡한 비동기 워크로드에서는 일이 끝나기 전에 턴을 끝내지 않도록 밀어줄 필요가 있습니다. 그러지 않으면 다음에 할 일을 하는 대신 서술하거나("Next, I'll ..."), 원래 요청에 이미 포함된 단계를 두고 허락을 구합니다("Shall I apply this?"). 사용자가 "continue"를 입력해야 하는 방식은 페어 프로그래밍에는 맞지만 장기 자율 역량을 쓰지 못합니다.

시스템 프롬프트 블록 2개를 함께 씁니다. 프롬프트 길이를 줄여야 하면 첫 번째만 써도 효과 대부분이 남습니다.

```text
You are operating autonomously. The user is not watching in real time and cannot answer questions mid-task, so asking 'Want me to…?' or 'Shall I…?' will block the work. For reversible actions that follow from the original request, proceed without asking. Stop only for destructive actions or genuine scope changes the user must decide. Offering follow-ups after the task is done is fine; asking permission before doing the work is not.

Exception: when the user is describing a problem, asking a question, or thinking out loud rather than requesting a change, the deliverable is your assessment. Report your findings and stop. Don't apply a fix until they ask for one.

Before ending your turn, check your last paragraph. If it is a plan, an analysis, a question, a list of next steps, or a promise about work you have not done ('I'll…', 'let me know when…'), do that work now with tool calls. That includes retrying after errors and gathering missing information yourself. Do not stop because the context or session is long. End your turn only when the task is complete or you are blocked on input only the user can provide.

Before running a command that changes system state (such as restarts, deletes, or config edits), check that the evidence actually supports that specific action. A signal that pattern-matches to a known failure may have a different cause.
```

사용자가 지켜보고 있지 않다고 알리는 첫 문장이 효과의 큰 부분을 담당하므로 그대로 두세요. 제품이 특정 확인을 위해 멈춰야 한다면 그 뒤에 목록 문장을 덧붙이면 됩니다. 이 블록은 모호한 요청에 대해서도 덜 묻게 만들 수 있으니 자기 작업에서 그 절충을 확인하세요.

두 번째 블록은 사용자의 요청을 산출물의 범위로 정의합니다.

```text
# Delivering work
The user's request — or the plan they approved — sets the scope, and the scope is the deliverable: don't quietly narrow, widen, or swap it. Read ambiguity the way a careful colleague would: make routine judgment calls yourself, and check in only when different readings would lead to materially different work. If you see a real problem with the task as specified, say so in a sentence or two and keep building under stated assumptions; if the user hears the concern and reaffirms, that is their decision, so deliver the full request.

If a question comes up partway, first do everything that doesn't depend on the answer; then state the assumption you made, or — when going ahead on a wrong guess would be unsafe or would make the work useless — put the question at the end of a turn that also delivers that progress. If one part turns out to be blocked, complete every other part in full and say exactly what you left out and why — the whole task is the deliverable, and scaling it down is the user's call, not yours. A step you have decided on is something to run, not to announce: describing the next step and ending the turn leaves it undone until the user replies.

Keep changes to what the request needs. Something else you notice worth doing — cleanup or documentation the task didn't call for, a change to a file the task didn't require — is a suggestion to make at the end, not a change to make; actions clearly beyond what the ask implies, and risky or destructive ones, still need the user's go-ahead.
```

### 범위·테스트 제한

열린 기능 구현을 맡기면 5.1은 요청받은 것에 더해 인접 코드를 고치거나, 언급되지 않은 동작을 확장하거나, 변경 규모에 비해 많은 테스트 파일을 커밋하기도 합니다. 무엇을 빼야 하는지 명시하면 잘 따릅니다. 공식 문서는 아래 지시로 **요청 밖 추가와 커밋된 테스트 코드가 크게 줄었고 작업 성공률에는 측정 가능한 변화가 없었다**고 밝힙니다.

```text
If, while working or testing, you find a pre-existing bug, a performance concern, or behavior the task doesn't mention, don't fix, optimize or extend it in this change unless the requested behavior cannot work without it; report it as a follow-up in your summary. Where the task is ambiguous, implement the reading its wording and the surrounding code most directly support, state that assumption in your summary, and don't build for the other readings as well. Verify your work however you like; scratch scripts and quick checks need not be kept. Commit tests only where the task asks for them or this repository already keeps tests for this kind of change, sized like the neighboring test files — roughly one focused test per stated behavior — and don't turn scratch checks into additional permanent test files. This is about extras only: implement every behavior the task asks for, completely.
```

## 에이전트 운영 항목

### low effort에서 검색 유도

`low`에서 5.1은 Fable 5보다 검색·검색증강 도구를 덜 부르고 기억으로 답하는 경우가 많습니다. 가장 단순한 해법은 대화 전체가 아니라 **해당 턴만 effort를 올리는 것**입니다(메시지별 effort 베타).

프롬프트로 밀어야 하는 경우, 이름을 알아본다고 그 현재 상태를 아는 것은 아니며 그런 이름은 사용자가 쓴 표기 그대로 검색해야 한다고 시스템 프롬프트에 씁니다.

```text
When a query centers on a name you do not confidently recognize, or recognize from a fast-moving area like AI models and developer tools where the landscape shifts within months, the name itself is the thing to verify: search before answering, and include the name as the user wrote it in at least one query alongside any reformulations. This holds even when you have some background on it — partial background is exactly what makes an out-of-date answer sound authoritative, so familiarity is not a reason to skip the search.
```

### 안전장치 오탐 회피

5.1의 안전 분류기는 Fable 5 출시 시점보다 오탐이 적고, **소스 코드에서 취약점을 찾는 작업은 허용**됩니다. 그래도 오탐은 발생하며 차단된 요청은 `stop_reason: "refusal"`을 반환합니다. 오탐 확률을 높이는 상황 3가지입니다.

- **컴파일 확인 어법**: "Does this program compile without errors?" 대신 "Are there any bugs in this program?"으로 묻습니다.
- **비주류 프로그래밍 언어**: 그 언어가 무엇이고 어떻게 동작하는지 맥락을 주세요. 언어 공식 문서에 접근시키는 방법이 있습니다.
- **도구 출력의 base64**: base64로 인코딩된 데이터를 모델 컨텍스트로 반환하는 도구가 오탐을 유발합니다. 권장 해법은 제거입니다.

### compaction 요약 보존 항목 명시

5.1은 긴 대화를 압축할 때 요약이 무엇을 남겨야 하는지 명시적으로 알려주면 잘 따릅니다. 서버측 compaction은 이미 이 처리를 합니다. 클라이언트에서 압축한다면 아래 요약 지시를 쓰세요.

```text
Summarize the transcript inside <summary></summary> tags. Include relevant information in the summary such that this conversation will be continued by a new context window without needing to redo work or be reprovided with relevant constraints or context. Be sure to preserve: (1) any difficulties or problems that came up, and how they were handled or resolved; (2) any possibilities, options, or approaches that were raised, tried, or set aside, and why; (3) anything that was asked for, decided, agreed, ruled out, or established as a preference, constraint, or boundary — stated exactly; (4) exactly where things stand now — what has been covered, settled, or completed so far; (5) anything still open, unresolved, promised, or expected to happen next; (6) specific details that would be hard to reconstruct — names, numbers, dates, exact wording, links or references — kept exactly. Be complete on these even at the cost of length; keep everything else concise. Weight the two voices differently: keep what the user said, asked for, shared, or established carefully and close to their own words; your own explanations and reasoning can be condensed much further, to what they concluded or produced — as long as nothing in the six items above is dropped.
```

### xhigh·max에서 긴 산출물 여유 확보

`xhigh`, 특히 `max`에서 5.1은 답을 쓰기 시작하기 전에 더 오래 생각합니다. 한 요청이 긴 산출물(긴 문서 전면 재작성 등)을 요구하면 그 산출물 상당 부분을 사고 안에서 초안으로 쓴 뒤 응답으로 다시 쓰기도 합니다. 대기 시간과 출력 토큰이 함께 늘어납니다.

가장 단순한 접근은 이런 요청을 권장 시작점인 `high`에서 돌리고, 품질 이득을 측정한 자리에서만 `xhigh`·`max`로 올리는 것입니다. 그래도 높은 레벨로 돌린다면 `max_tokens`를 응답 길이만이 아니라 사고와 응답을 합쳐 잡고, 아래 노트를 user 메시지 끝에 붙이세요. 산문·코드 요청에서 사고가 크게 짧아집니다. `[max_tokens]`는 그 요청의 실제 값(예: 64,000)으로 바꿉니다.

```text
Everything produced in one reply, including any reasoning or drafting it does before the reply, counts toward a single limit of about [max_tokens] tokens. If that limit is reached before the reply is finished, the person receives a cut-off response and has to start over. Composing an entire output or deliverable in full as reasoning and then again as a reply would double the length of the turn without improving the result, so don't do that.

Instead, when the person has asked for a long or effort-intensive deliverable such as a multi-section document, a large table or dataset, or a complete code file, spend extra effort on understanding the request, checking the inputs the answer depends on, settling the structure and other difficult decisions, and otherwise using the reasoning space to reason and the output space to write an output. Usually it is not needed to draft an output multiple times.
```

### 서브에이전트 실행 중 리드 비차단

코딩 에이전트가 5.1에게 서브에이전트 위임을 허용한다면, 리드 에이전트가 매번 멈춰 기다리게 하지 마세요. 코딩 작업에서 리드가 계속 일하게 두면 품질·토큰 사용량·비용이 비슷한 채로 평균 완료 시간이 줄어듭니다. 구성은 세 가지입니다.

- 서브에이전트를 시작하는 도구가 즉시 반환하게 합니다.
- 각 서브에이전트의 결과는 준비되면 이후 `user` 메시지로 리드에게 전달합니다.
- 결과를 기다리고 싶을 때 부를 수 있는 별도 도구를 리드에게 줍니다.

모델은 여전히 기다리기를 선택하는 경우가 많습니다. 시간 절감은 계속 진행하는 실행 회차에서 나옵니다.

### 비전 crop·zoom 도구

5.1은 기본 비전 역량이 개선됐고, 조밀한 차트 같은 복잡한 시각 입력에서는 반복 분석·크롭·시각 검증이 가능할 때 최고 성능을 냅니다. 온전한 이득을 보려면 원본 이미지·비디오를 담고 PIL·OpenCV 같은 기본 이미지 처리 라이브러리가 설치된 컨테이너에 접근시켜 에이전트로 돌리세요. 컨테이너가 부담이면 **이미지 크롭 도구 하나만으로도 향상분 대부분을 얻습니다.** 선택한 영역을 잘라 확대해 반환하는 도구는 모델이 세부를 더 깊이 살피게 하고 이미지 토큰만큼 테스트 타임 연산을 늘려줍니다. 동작하는 정의는 공식 [crop tool recipe](https://platform.claude.com/cookbook/multimodal-crop-tool)에 있습니다.

## Fable 5 가이드에서 빠진 항목

아래는 [Fable 5 가이드](./claude-5-fable-prompt-guide.md)에 있었으나 5.1 전용 가이드에는 나오지 않는 항목입니다. 5.1 가이드가 이들을 폐기했다고 명시하지는 않았고, 범용 원칙은 [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) 페이지로 통합되어 있습니다.

- 메모리 시스템 구축(교훈 파일 1건 1파일, 과거 세션에서 부트스트랩)
- "요청이 아니라 이유를 제공"(`I'm working on [the larger task] for [who it's for]...`)
- 컨텍스트 예산 카운트다운 숨기기와 불안 완화 문구
- 진행 주장 근거화(각 주장을 이번 세션의 도구 결과와 대조)
- 경계 명시(요청 없는 인접 행동 억제) — 5.1에서는 작업 완주 블록의 예외 문단에 흡수
- `send_to_user` 도구 — `thinking.display: "updates"`가 대체
- "더 어려운 작업부터 시작" 스캐폴딩 권고

방향이 바뀐 항목도 있습니다. Fable 5 가이드는 화살표 체인·축약 표기 억제가 문체 처방의 초점이었지만 5.1은 반대로 산문이 조밀해지는 쪽이고, 서식은 반서식 규칙을 **제거**하라는 쪽으로 뒤집혔습니다. 서브에이전트는 Fable 5의 "억제 대신 활용"에서 5.1의 "리드를 차단하지 않는 비동기 구성"으로 구체화됐습니다.

## 마이그레이션 체크리스트

Fable 5 → 5.1 공식 체크리스트입니다.

1. 모델명을 `claude-fable-5`에서 `claude-fable-5-1`로(Mythos는 `claude-mythos-5-1`로) 변경합니다.
2. 강제 `tool_choice`(`any`·`tool`)를 제거합니다. 400이 반환됩니다. `auto` + 명시적 지시 + `strict: true` 도구, 또는 JSON outputs로 바꾸고, 지시는 `user` 턴이나 호출이 반드시 필요한 경우 mid-conversation `role: "system"` 메시지에 둡니다.
3. 매 턴 `thinking` 블록을 빈 블록까지 포함해 수정 없이 되돌려 보냅니다. 5.1은 Opus 5·Fable 5·Mythos 5·이전 모델의 블록을 읽습니다. 5.1에서 이전 모델로 대화를 옮기면 블록이 드롭됩니다(Mythos 5.1은 읽습니다).
4. `messages` 배열을 직접 구성하는 코드라면 이전 턴 편집 여부를 점검합니다. `thinking-binding-controls-2026-08-01` 헤더 + `prefix_mismatch_behavior: "drop_block"`으로 세션을 돌려 `input_transformations`를 로그하고 `prefix_binding_mismatch`를 전부 고칩니다. 모델 전환 뒤의 `model_binding_mismatch`는 정상입니다.
5. 이력을 append-only로 유지합니다. `system`·`tools`를 세션 시작 시 동결하고, 세션 중 변경은 `role: "system"` 메시지와 `tool_addition`·`tool_removal` 블록으로 하며, 턴별 리마인더는 제거하지 않는 턴 한정 시스템 메시지로 보내고, 이력 정리는 서버측으로 하거나 클라이언트 요약을 넘어 가져가는 턴에서는 사고 블록을 떼어내고, 턴을 넘는 파일 참조는 `file_id`로 합니다.
6. 운영용 `prefix_mismatch_behavior`를 정하고(기본 `"error"`, 또는 `"drop_block"`) 모니터링합니다. 남들이 각자 API 키로 돌리는 도구를 유지보수한다면 이 필드를 설정해 테스트하세요. 신규 계정은 내 계정이 아니어도 기본 강제 대상입니다.
7. 에이전트 루프에서 1턴 1호출 동작을 점검하고 배칭 지시를 추가합니다.
8. 도구 호출 사이 진행 텍스트를 렌더링하는 인터페이스라면 `thinking.display`를 `"updates"`(베타) 또는 `"summarized"`로 설정하고 업데이트를 프롬프트로 요청합니다.
9. 요청마다 effort를 바꾸고 있다면 캐시 적중을 유지하도록 메시지별 effort `role: "system"` 메시지(베타)로 옮깁니다.
10. `stop_reason: "refusal"`을 처리하고 `stop_details.category`를 읽습니다. `fallbacks: "default"`(베타)를 검토합니다.
11. `high`에서 시작하는 새 effort 스윕을 돌리고 자기 워크로드에서 비용·지연을 다시 기준화합니다. 토큰 수는 거의 그대로이고, 프롬프트 캐시 읽기는 Fable 5의 4분의 1입니다.

**Opus 5 → 5.1 추가분**: ZDR 조직은 자격부터 확인(기본 불가), `thinking: {type: "disabled"}` 제거(5.1은 어떤 effort에서도 400 — 토큰은 낮은 effort로 통제하고 `max_tokens` 재검토), 도구 호출 사이 텍스트가 `text` 블록이 아니라 진행 업데이트 `thinking` 블록으로 온다는 점 반영, 안전 분류기 범주가 `cyber` 하나에서 `bio`·`reasoning_extraction` 등으로 넓어짐, 가격 2배(캐시 읽기는 절반).

**Opus 4.8 이하에서 올 때**: Fable 5 마이그레이션 가이드를 먼저 적용한 뒤 5.1 델타를 적용합니다.

Claude Code에서는 `/claude-api migrate this project to claude-fable-5-1`로 모델 ID 교체와 파괴적 파라미터 변경, effort 보정을 자동 적용하고 수동 확인 항목 체크리스트를 받을 수 있습니다.

## 요약

| 할 일 | 내용 |
|-------|------|
| **effort** | `high`에서 시작해 전 레벨 재측정. `medium`이 Fable 5 수준을 더 싸게, `low`는 작은 모델 자리의 후보. 코딩 벤치마크에서는 `medium`이 정점 |
| **제거** | "결과는 최종 응답에 모아라" 류 내레이션 억제 지시, 구모델용 반서식 규칙 |
| **추가** | 진행 업데이트 요청, 병렬 호출 배칭 한 줄, mannered prose 정의, 인용 예시 1건, 외과적 편집 지시, 작업 완주·범위 블록 2개, 범위·테스트 제한 지시 |
| **이력** | append-only. 턴별 리마인더는 턴 한정 시스템 메시지, 정리는 서버측 compaction. 캐시가 싸졌으니 조기 압축 재검토 |
| **파괴적 변경** | 강제 `tool_choice` 400, 사고 블록 단방향 호환, 이전 턴 편집 시 사고 블록 무효화 |
| **베타 3종** | 메시지별 effort, 턴 한정 시스템 메시지, `thinking.display: "updates"` |
| **refusal** | `stop_reason` 확인 + `fallbacks: "default"`(대상은 Opus 4.8·Opus 5). 오탐은 어법·언어 문서·base64 제거로 완화 |
| **미지원** | Fast mode, Priority Tier, 300K 출력 배치 베타. thinking 끄기(어떤 effort에서도 400) |
