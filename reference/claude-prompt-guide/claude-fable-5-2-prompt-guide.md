# Claude Fable 5.2 Prompting Guide

> **출처**:
> - [Prompting Claude Fable 5.2 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-fable-5-2)
> - [What's new in Claude Fable 5.2 | Anthropic](https://platform.claude.com/docs/en/models/fable-5-2/whats-new-fable-5-2)
> - [Claude Fable 5.2 and Claude Mythos 5.2 migration guide | Anthropic](https://platform.claude.com/docs/en/models/fable-5-2/migration-guide)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
>
> **날짜**: 2026-11-12
> **관련 조사**: [research-fable52-carbon.md](../research/research-fable52-carbon.md) · **자매 가이드**: [Claude Fable 5.1](./claude-fable-5-1-prompt-guide.md) · [Claude Opus 5.5](./claude-opus-5-5-prompt-guide.md)

Claude Fable 5.2 / Mythos 5.2 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 수록했습니다. 시스템 프롬프트에 바로 붙여 쓰는 용도이므로 번역하지 않습니다.

## 목차
- [모델 개요](#모델-개요)
- [API 변경 요약 (Fable 5.1 대비)](#api-변경-요약-fable-51-대비)
- [effort 전략: high에서 시작해 다시 측정](#effort-전략-high에서-시작해-다시-측정)
- [Claude Code와 구독에서 쓸 때](#claude-code와-구독에서-쓸-때)
- [행동 변화와 처방](#행동-변화와-처방)
- [구모델용 프롬프트·하네스 재검토](#구모델용-프롬프트하네스-재검토)
- [Fable 5.1 가이드에서 빠진 항목](#fable-51-가이드에서-빠진-항목)
- [마이그레이션 체크리스트](#마이그레이션-체크리스트)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-fable-5-2` (2026-11-09 출시) / `claude-mythos-5-2` (기저 모델이 같고, Fable에는 사이버·생물 분야 오용 방지 장치가 붙습니다. Mythos는 Cyber Verification Program 등 검증 프로그램을 통과한 조직 한정) |
| **포지션** | 높은 난도의 추론과 장시간 에이전트 작업. 공식 권고는 5.1과 같습니다: 대부분의 작업은 최신 Opus(Opus 5.5)로 시작하고, Opus의 높은 effort로도 평가 기준에 못 미치면 Fable 5.2로 옮깁니다. 발표문의 "최대 30% 빠름"은 출력 생성 속도이며 작업 완료 시간이 그만큼 준다는 뜻은 아닙니다 |
| **플랫폼** | Claude API, Claude Platform on AWS, Amazon Bedrock(`global.`·`us.anthropic.claude-fable-5-2`, `bedrock-runtime`만), Google Cloud(Anthropic managed·Google managed, 두 서비스의 기능과 요율은 따로 확인), Microsoft Foundry(Anthropic 인프라 호스팅) |
| **입출력** | 텍스트·이미지 입력, 텍스트 출력. 1M 토큰 창(기본이자 최대, 길이 할증 없음), 최대 128K 출력(`max_tokens`에 사고 포함) |
| **가격** | $8 / $40 per MTok (5.1은 $10 / $50). 5분 캐시 쓰기 $10, 1시간 $16, 캐시 읽기 $0.20(기본 입력가의 0.025배, 5.1과 같은 배수). Batch $4 / $20. Anthropic 운영 서비스에서 `inference_geo: "us"`는 1.1배 |
| **고속 모드** | Messages API에서 정식 제공(`speed: "fast"`, 베타 헤더 없음), $16 / $80, 출력 속도 최대 2.5배. Claude API, Google Cloud(Anthropic managed·Google managed, Google managed 요율은 Google이 정함), Microsoft Foundry(Anthropic 호스팅, 모델 ID `claude-fable-5-2-fast`, `speed` 생략). Bedrock에는 없고, 배치·Priority Tier와 함께 쓸 수 없습니다. Managed Agents에서는 `speed`를 뺍니다 |
| **요청 한도** | 5.2 전용 한도. Fable 5.1·Fable 5가 함께 쓰는 한도와 별개입니다(Mythos 5.2는 Mythos 5.1·5와 공유). Priority Tier 미지원 |
| **캐시 최소** | 512 토큰 |
| **지식 컷오프** | 2026-06 |
| **Thinking** | adaptive 상시 켜짐. `enabled`(`budget_tokens`)·`disabled` 모두 400 |
| **effort 기본값** | API `high`. Claude Code에서는 `medium` ([effort 전략](#effort-전략-high에서-시작해-다시-측정)) |
| **토크나이저** | Opus 4.7에서 도입된 것 (5.1과 같음) |
| **데이터 보존** | 30일 보존 필수. ZDR 불가(Anthropic 명시 승인 예외), Covered Model 지정 |
| **은퇴 하한** | 2027-11-09 이후 (5.1은 2027-09-01 이후, 두 모델 모두 Active). 하한이지 예정일이 아닙니다 |

## API 변경 요약 (Fable 5.1 대비)

### 파괴적 변경 4건

| 변경 | 5.1 | 5.2 | 대응 |
|------|-----|-----|------|
| **prefix check** | 2026-08-31 이후 생성 계정은 기본 400, 이전 계정은 계정마다 다름 | **계정 나이와 무관하게 400** (`The block is bound to a different conversation`) | 이력을 append-only로 유지합니다. 임시방편은 `thinking-binding-controls-2026-08-01` + `thinking.block_binding.prefix_mismatch_behavior: "drop_block"`인데, 버려진 사고를 다시 하느라 출력 토큰이 늘어납니다 |
| **사고 블록 읽기** | — | 5.2 블록은 5.2와 Mythos 5.2만 읽습니다 | 5.2에서 Opus 5.5·Fable 5.1·폴백 모델(Opus 4.8·Opus 5)로 옮기면 그 턴부터 5.2의 추론이 빠집니다. 요청은 성공하고 버려진 블록은 과금되지 않습니다. 반대 방향(다른 모델 → 5.2)은 Claude API와 Google managed에서 추론이 이어집니다 |
| **`computer_20251124`** | 베타 헤더로 허용 | 400 (Amazon Bedrock만 예외) | `computer_toolset_20260801`로 옮깁니다 |
| **advisor 도구(베타)** | 여러 조언자 허용 | 5.2 실행자는 5.2·Mythos 5.2 조언자만 허용 | 실행자를 바꿀 때 조언자 `model`도 같은 변경에서 바꿉니다. 도구 정의가 바뀌므로 새 대화에서 적용합니다. 모든 실행자는 5.2를 조언자로 받고, 5.2 조언은 암호화된 `advisor_redacted_result` 블록으로 오므로 조언 평문을 읽던 코드는 고칩니다 |

Claude Code, claude.ai, Managed Agents, Agent SDK가 요청을 만든다면 prefix check 변경은 신경 쓸 필요가 없습니다. 직접 요청을 만드는 코드는 `system`과 `tools`를 대화 내내 그대로 두고, `messages`에는 덧붙이기만 하며, assistant 턴을 받은 그대로 돌려보내면 영향이 없습니다.

**사고 블록은 계정에도 묶입니다.** 5.2·Mythos 5.2의 사고 블록은 만든 계정이나 연결된 계정에서만 쓰입니다. 다른 계정이 보내면 API가 오류 없이 블록을 버리고, Claude API와 Google Cloud(Google managed)에서 `thinking-binding-controls-2026-08-01` 베타 헤더를 쓰면 `input_transformations`에 `reason: "organization_binding_mismatch"`로 남습니다. 그래서 문제를 볼 때 세 경우를 나눕니다: 이력을 고쳐서 나는 400, 다른 모델로 옮겨서 버려지는 블록, 다른 계정이 보내서 버려지는 블록입니다.

### 5.1·Opus 5.5에서 오면 바뀌지 않는 규칙

- adaptive thinking 상시: `thinking`을 생략하거나 `{"type": "adaptive"}`를 보내고, 사고량은 effort로 정합니다.
- 강제 `tool_choice`(`any`·`tool`)는 400입니다. 스키마가 맞는 JSON이 필요하면 `auto` + `strict: true` 또는 JSON outputs를 씁니다.

### Opus 5.5에서 옮길 때 추가로 볼 것

- **effort 기본값이 `high`입니다.** Opus 5.5 기본은 `medium`이라, effort를 생략한 요청이 한 단계 높게 돕니다. 오류 없이 비용과 지연만 달라지므로 effort를 명시합니다.
- 30일 보존이 필수입니다. Opus 5.5를 ZDR로 쓰던 조직·워크스페이스는 옮기기 전에 워크스페이스에 30일 보존을 켜거나 Anthropic 계정 팀에 자격을 확인합니다. 그러지 않으면 Claude API에서 5.2 요청이 모두 400입니다.
- CMEK(고객 관리 암호화 키) 조직에서 Opus 5.5는 structured outputs를 지원하지만 5.2는 5.1처럼 지원하지 않습니다. 옮기는 요청에서 `strict`와 `output_config.format`을 빼고 코드에서 검증합니다.
- 단가는 Opus 5.5($4 / $20)의 두 배이고, 캐시 읽기는 둘 다 $0.20입니다.

### 함께 쓰기 좋은 베타

- **Compaction on demand** (`compact-2026-09-04`): 오래된 턴을 요약으로 바꾸는 시점을 직접 고릅니다.
- **대화 중 도구 변경**: `tools`를 고치지 않고 `role: "system"` 메시지로 도구를 더하거나 뺍니다. Claude API·Claude Platform on AWS·Google Cloud(Anthropic managed)는 `inline-tools-2026-09-15`, 이름으로 지정하는 변경은 `mid-conversation-tool-changes-2026-07-01`.
- 두 기능 모두 이력을 append-only로 유지하는 데 도움이 됩니다.

## effort 전략: high에서 시작해 다시 측정

API 기본값은 `high`이고 Claude Code의 기본값은 `medium`입니다. 같은 모델이라도 어느 쪽에서 부르느냐에 따라 출발점이 다르므로, 비교할 때는 effort를 명시합니다.

공식 가이드는 `high`에서 시작하라고 합니다. "most of the gain in capability is already present at `high`" — `medium`에서 `high`로 올리면 Anthropic이 추적하는 코딩·지식 작업 평가 대부분이 올랐고, `high` 위의 이득은 과제마다 고르지 않습니다. 레벨 이름은 모델끼리 같은 순서지만 레벨별 사고량은 다르므로, 5.1이나 Opus 5.5에서 맞춘 값을 옮겨 쓰지 말고 다시 측정합니다.

| 레벨 | 공식 용도 |
|------|-----------|
| `low` | 빠른 주고받기, 명세가 분명한 작업, 대량 처리(빠르고 똑똑한 서브에이전트 등). 코딩 평가에서 과거 모델의 `low`보다 낫고, 5.1의 더 높은 effort 점수에 가깝습니다 |
| `medium` | 대화형 코딩, 채팅, 일상 지식 작업 |
| `high` | 어려운 코딩, 조사, 에이전트 작업, 사람 없이 오래 도는 작업. `medium`보다 턴이 눈에 띄게 길어집니다 |
| `xhigh` | 이득을 측정한 가장 어려운 장시간 작업. 내부 코딩 평가에서 점수가 조금 오르고 토큰은 훨씬 많이 씁니다 |
| `max` | 모델의 상한을 재거나 시간과 토큰이 상관없는 드문 작업(과학적 발견, 수학 같은 열린 문제) |

알아 둘 점:
- `high` 이상에서는 인사에도 거의 매번 생각합니다. 쉬운 요청이 느리거나 비싸면 그 턴의 effort를 낮춥니다.
- effort는 답변 길이에 거의 영향이 없습니다. 길이와 어조는 프롬프트로 정합니다.
- 한 워크플로 안에서 섞어 쓸 수 있습니다. 계획과 반복은 `medium`, 사람 없이 오래 도는 부분은 높게 둡니다. 캐시를 유지하며 바꾸려면 메시지별 effort(`mid-conversation-output-config-2026-07-01`)를 씁니다.
- `low`·`medium`의 에이전트 작업에는 아래 [작업 완주](#2-작업을-끝내기-전에-턴을-마침) 지시문을 함께 넣습니다.

## Claude Code와 구독에서 쓸 때

- Claude Code 2.1.321 이상이 필요합니다. `fable` 별칭은 5.2를 가리킵니다(Claude apps gateway 세션은 Fable 5가 기본이라 `/model claude-fable-5-2`로 고릅니다).
- 사용자 설정에 저장된 5.1 선택은 Pro·Max·Ultra에서 2.1.321 이상 첫 실행 때 `fable`로 옮겨지고, Team·Enterprise에서는 조직 설정에 따라 나중에 옮겨지거나 옮겨지지 않습니다. 옮겨진 뒤에는 5.2용으로 저장한 effort가 없으면 5.2 기본 effort로 시작합니다. 콘솔 계정·타사 제공자와 프로젝트·로컬·관리 설정에 적힌 5.1은 그대로입니다. 되돌리려면 `/model claude-fable-5-1`을 씁니다.
- Fable 계열은 구독의 주간 한도를 다른 Claude 모델보다 빨리 쓰고, Fable을 포함하는 요금제도 주간 한도의 50%까지만 Fable에 씁니다. 서브에이전트가 Fable을 물려받지 않게 하려면 서브에이전트 모델을 따로 정합니다([5](#5-서브에이전트-위임량이-하네스에-따라-크게-갈림)).
- 출시 행사(2026-11-09 시작, [안내 문서](https://support.claude.com/en/articles/17506494-claude-fable-5-2-launch-offers)): Pro와 Team 표준 좌석은 11월 16일 23:59 PT까지 Fable 모델을 주간 한도의 50% 안에서 쓰고, 같은 시각에 만료되는 한도 초기화 1회를 받습니다. Max·Ultra와 Team·기존 좌석제 Enterprise의 프리미엄 좌석은 첫 유료 결제부터 잰 구독 기간에 따라 초기화를 1~3회 받고, 이 초기화는 2027-03-08 23:59 PT에 만료됩니다. 초기화의 일반 지급 기준은 2026-11-09 10:00 PT 이전 유료 결제 설정입니다. 무료 체험의 유료 전환과 셀프서비스 Team 체험은 공식 안내의 별도 규정을 따릅니다. Team·Enterprise는 조직의 결제와 좌석 사용자의 조직 가입이 모두 그 전이어야 하고, HIPAA 대응 Enterprise는 받지 못합니다.

## 행동 변화와 처방

공식 가이드의 처방은 증상을 관찰했을 때 하나씩 넣고 효과와 토큰 비용을 측정하는 방식입니다. 미리 전부 넣지 않습니다.

### 1. 생각을 줄이라는 지시가 듣지 않음

5.1은 "answer directly without deliberating" 같은 줄을 대체로 따랐지만, 5.2는 `medium` 이상에서 이 줄이 있어도 생각합니다. 이런 줄을 지우고 effort를 낮춥니다.

같은 이유로 **작은 `max_tokens`가 사고만 쓰고 텍스트 없이 끝날 수 있습니다**(`stop_reason: "max_tokens"`). 5.1에서 생각 줄이기 지시로 작은 `max_tokens` 안에 맞추던 요청은 `max_tokens`를 올리거나 effort를 낮춥니다.

### 2. 작업을 끝내기 전에 턴을 마침

긴 다단계 작업에서 남은 일 목록을 적거나, 계속할지 묻거나, 평범한 장애물(타임아웃 등)에서 멈추며 턴을 끝냅니다. `low`·`medium`에서 더 잦습니다. 이 증상이 보이면 다음을 시스템 프롬프트에 넣습니다.

```text
# Finishing work
Please avoid stopping while you still owe work the user asked for. Be persistent and do not stop unless needed.

While status notes are welcome, as is clarifying with the user on open decisions, carry on with work that does not depend on the user's answer without unnecessary stops.

If you notice yourself inviting the user to redirect you or offering to wait, instead proceed on the next part of the task. You may meet ordinary obstacles like errors, timeouts, locked files, empty results or failing tools. Diagnose them first, and when they are not real blockers, work through them with the access you have (wait and retry, fix the request, use another tool or source) rather than stopping unnecessarily.

If someone clearly decided something is a hard blocker, such as a file marked not to be touched, access that was intentionally withheld, or a safety guardrail, leave it alone, say plainly what you found, and look for another safe way to finish the task. Stopping before the task is complete is very rarely merited, as in when the task can't move forward without user input, or where the blocker is deliberate and should not be worked past. This does not override the need for confirmation on risky or destructive actions.
```

Anthropic이 에이전트 코딩 제품의 기록된 세션을 `medium`으로 재생했을 때, 이어서 할 수 있었던 일을 남긴 채 끝난 세션이 약 절반으로 줄었습니다. 허락을 구하거나 계속하겠다고 제안하는 종료는 대부분 사라졌지만, 남은 일을 나열하고 멈추는 종료는 남았습니다. 출력 토큰은 약 30% 늘었습니다. 모델이 덜 묻게 되므로 위험하거나 되돌릴 수 없는 작업의 확인 단계는 하네스에 따로 둡니다.

**승인 요청에 답할 때**는 "continue"나 엄지 대신 무엇을 할지 정확히 씁니다(예: "Yes, run the migration on the staging database"). 시스템 프롬프트에 승인 규칙을 쓸 때도 확인할 동작을 구체적으로 적습니다. 승인 대상에 "sending messages to people outside this conversation"을 넣은 시험에서는, 승인할 사람이 없는 상황이라 동료·다른 팀에 보내는 일상 요청의 약 절반을 보류했습니다.

### 3. 코드 소유권을 말하지 않으면 덧붙이기만 함 (신규)

5.2는 코드를 누가 소유하는지에 민감합니다. 소유를 밝히지 않거나 남의 코드로 소개하면, 중복이 생기더라도 기존 구조에 덧붙이고 주변 문제는 보고만 합니다. 모델의 코드라고 하면 중복을 합치고 요청하지 않은 관련 수정도 합니다. 구조 개선을 원하면 다음 문장을 넣습니다.

```text
You are the owner and long-term maintainer of this codebase, and its design is up to you.
```

작은 코딩 과제에서 중복 통합 비율이 10% 미만에서 약 75%로 올랐습니다. 대가로 출력 토큰이 70~80% 늘었고, 요청하지 않은 변경(주로 새 테스트와 문서, 때로는 기존 기능 동작)이 생겼으며, 마무리 PR 요약이 작은 변경을 빠뜨리는 일이 잦았습니다. 보고된 diff와 요약을 함께 검토합니다.

**사용자가 소유하고 변경을 최소화하길 원하는 코드에는 이 문장을 넣지 않습니다.** 범위 제한 규칙이 이 문장을 상쇄하지 못합니다. 같은 프롬프트 앞부분에 "No drive-by refactors, renames or cleanups"가 있어도 절반 이상의 실행에서 중복을 합쳤습니다.

### 4. 긴 턴에서 말이 없음

도구 호출이 길게 이어지는 동안 사용자에게 보이는 글이 적고, 첫 도구 호출 전에 무엇을 할지 말하지 않기도 합니다.

먼저 클라이언트가 업데이트를 받는지 확인합니다. 5.2가 도구 호출 사이에 쓰는 업데이트는 5.1처럼 진행 업데이트 `thinking` 블록으로 오고, 기본값 `display: "omitted"`에서는 텍스트가 비어 있습니다. `display: "updates"`(베타 `thinking-display-updates-2026-08-18`)나 `"summarized"`로 받아 도구 호출 사이의 비어 있지 않은 `thinking` 블록을 보여 줍니다.

대화형 환경이라면 다음을 시도합니다.

**하네스에서 리마인더 넣기**: 사용자가 읽을 것(텍스트 블록이나 텍스트가 있는 `thinking` 블록)이 없는 도구 단계를 연속으로 세다가, 여러 번 이어지면 최신 도구 결과 뒤에 턴 한정 시스템 메시지(`clear_at: "next_user_message"`, 베타 `mid-conversation-system-clear-at-2026-08-21`)로 다음을 덧붙입니다. 다중 턴 코딩 과제에서 가장 긴 침묵 구간이 약 절반으로 줄었고 토큰과 시간은 눈에 띄게 늘지 않았습니다. 넣은 리마인더는 이후 요청에서도 지우거나 고치지 않습니다(이력 편집이 됩니다).

```text
The user hasn't heard from you in a while: say in a few words what you're doing, then continue.
```

**시작 한 줄과 마무리 요약 받기** (사람이 직접 보고 있을 때): 모든 코딩 과제 실행에서 첫 도구 호출 전에 메시지를 썼고, 과제당 출력 토큰이 약 20% 늘었습니다. 위 리마인더와 함께 쓰면 업데이트가 더 늘어납니다.

```text
Before you start, say in a line what you're about to do; brief updates while you work help the user follow along. Close with a short recap that stands on its own (what you found, what you did, and what's next), so a reader who only sees the last message has the full picture.
```

**리마인더를 넣을 수 없을 때**: 시스템 프롬프트에 다음 한 문장을 넣습니다. 워크플로 자동화 과제에서 긴 침묵 구간 대부분이 사라졌습니다.

```text
Every few tool calls, give the user a one-line update on where things stand.
```

5.2는 오래 도는 비동기 작업에 잘 맞으므로, Anthropic은 잦은 업데이트가 필요 없는 일에 이 모델을 권합니다.

### 5. 서브에이전트 위임량이 하네스에 따라 크게 갈림

최소한의 서브에이전트 도구만 준 짧은 과제에서는 거의 위임하지 않았고, 프롬프트가 위임을 권하는 에이전트 코딩 제품에서는 쉽게 위임했습니다. `xhigh`·`max`에서는 자기 작업을 검토하는 서브에이전트를 띄웠는데, 5.1은 같은 과제에서 그러지 않았습니다. 초기 사용자는 5.2를 다른 모델의 계획자·조율자로 써서 좋은 결과를 얻었습니다.

서브에이전트가 세션 비용의 큰 몫을 차지할 수 있으니 **서브에이전트가 기본으로 어떤 모델을 쓰는지 확인합니다.** 위임이 과하면 시스템 프롬프트·스킬·에이전트 파일에서 위임을 권하는 줄부터 점검하고, 그다음에 서브에이전트 도구 설명을 고칩니다. 새 설명에는 서브에이전트가 세션 비용에 더하는 몫, 위임할 가치가 있을 때와 없을 때, 띄운 서브에이전트에게 무엇을 알려 줄지를 적습니다. `high`에서 비용을 강조한 긴 설명이 짧은 설명보다 서브에이전트 수를 약 절반으로 줄였습니다. 도구 설명이 평범하고 위임을 권하는 지시가 없다면 고칠 필요가 대개 없습니다.

### 6. 쌓인 신중함을 그대로 따름

메모리·노트·지침 파일에 쌓인 경고(모델이 직접 쓴 것 포함)를 충실히 따라 불필요한 승인을 구합니다. 여러 에이전트가 함께 일할 때 주로 보였습니다.

- 더는 필요 없는 노트를 지웁니다. "never retry" 같은 낡은 지시를 계속 따릅니다.
- 승인 없이 해도 되는 일상 단계를 이름으로 나열합니다. "더 자유롭게 행동하라"는 너무 모호합니다.
- "첫 오류에서 멈추고 검토하라" 같은 정지 조건을 필요한 만큼으로 좁힙니다.
- **"never"가 든 지시는 절대 규칙으로 취급합니다.** 책임을 모델에게 남기려면 "never delete files" 대신 "ask for approval before deleting files"처럼 예외를 밝혀 씁니다.

위험하거나 되돌릴 수 없는 작업의 확인 단계는 그대로 둡니다.

### 7. 문체 규칙을 매우 충실히 따름

"한 문장에 지시 하나, 20단어 이하" 같은 경직된 상한은 글을 끊기게 만듭니다. 필요 없는 문체 규칙을 지운 뒤, 긴 작업의 최종 보고서나 인계 글을 쓰게 한다면 다음을 넣고 독자와 제품에 맞게 고칩니다. 에이전트 과제에서 최종 보고서가 덜 조밀해지고 세미콜론이 줄었으며, 워크플로 자동화 과제에서는 문장도 짧아졌습니다.

```text
# Communicating clearly
Write for an intelligent but low-context reader. The person reading has not seen your tool calls, your reasoning or the files you opened, and may be switching in from other work. Messages should generally be self-contained: the reader should understand what you mean without having to dig for other context. Put the key points in the first few sentences. Practice progressive disclosure in your sentence order, and do not use undefined references and ideas in line 1 that won't make sense until the reader reaches line 12.

Use plain words, and write in clear, understandable full sentences. Do not use a term or abbreviation that you made up during the work. Say what the thing is in a way any reader would understand. Write mostly in the style of ASD-STE100 Simplified Technical English: short sentences, one idea per sentence, active voice, and consistently using the same word for the same thing. Use a paragraph of flowing prose where ideas connect, and keep bullets for lists of separate items. Leave out unnecessary details unless the reader asks and practice concision, but do ensure that your messages have the key context. Aim to make your user-facing text as human-readable and clear as possible.
```

초기 사용자는 5.2의 글을 5.1보다 높게, 명료함은 Opus 5.5와 비슷하게 평가했습니다.

## 구모델용 프롬프트·하네스 재검토

5.1이나 Opus 5.5용으로 만든 지시와 장치 가운데 비용을 올리거나 부작용을 내거나 효과가 없어진 것들입니다.

| 다시 볼 것 | 5.2에서 생긴 일 | 처방 |
|-----------|----------------|------|
| 위임을 권하는 상시 지시 | 위임이 과해질 수 있음 | 시험에서 과하면 지움 ([5](#5-서브에이전트-위임량이-하네스에-따라-크게-갈림)) |
| 모델에게 보이는 토큰 예산 | 예산 크기에 따라 지출이 달라짐. 큰 예산을 지우니 `high`·`xhigh`에서 비용이 줄고 성능은 같음 | 예산 없이 시험. API의 task budgets(베타)와는 별개 |
| 이전 턴을 고치는 하네스 코드 | prefix check로 400(Batches API는 블록을 버림) | context editing이나 이전 턴을 남기지 않는 compaction만 쓰고 나머지는 append-only. `drop_block`은 출력 토큰을 측정한 뒤에 |
| Opus 5.5 가이드의 "treat that answer as done" 두 문장 | 후속 질문의 사고가 줄고, 이전 답의 실수를 지적하는 일이 크게 줄어듦 | 이전 답을 다시 따져 보길 원하면 넣지 않음. 다른 곳은 자기 실수를 지적하는지 시험한 뒤 채택 |
| 생각 줄이기 지시 | `medium` 이상에서 무효 | 지우고 effort를 낮춤 ([1](#1-생각을-줄이라는-지시가-듣지-않음)) |
| 문체 규칙 | 충실히 따라 글이 끊김 | 필요 없는 규칙을 지우고 보고서 블록 추가 ([7](#7-문체-규칙을-매우-충실히-따름)) |
| 쌓인 규칙·노트·메모리 | 이유가 사라진 경고까지 따름 | 이유가 사라진 경고는 지우고, 절대 규칙은 범위와 이유를 붙여 다시 씀. 이미 막힌 시스템은 메모리와 노트를 줄여 다시 시작 ([6](#6-쌓인-신중함을-그대로-따름)) |

**사고 과정을 답변에 쓰라는 지시**는 5.1처럼 `reasoning_extraction` 거절을 부릅니다. 프롬프트·스킬·도구 설명에서 지우고, 추론은 `display: "summarized"`의 `thinking` 블록에서 읽습니다. 거절 범주(`cyber`·`bio`·`frontier_llm`·`reasoning_extraction`·`general_harms`·`null`)와 폴백 대상(Opus 4.8·Opus 5)도 5.1과 같습니다.

**지시를 바꿀 때는 새 대화에서 바꿉니다.** prefix check가 모든 계정에 적용되므로, 저장된 대화를 새 시스템 프롬프트로 이어 가면 400이 날 수 있습니다. 대화 중에 지시를 바꾸려면 최신 턴에 넣거나, 지원하는 플랫폼에서는 시스템 메시지를 덧붙입니다.

## Fable 5.1 가이드에서 빠진 항목

5.2 가이드에는 아래 5.1 항목이 다시 나오지 않습니다. 무효라고 밝힌 것은 아니므로, 5.2에서 같은 증상이 보일 때만 [5.1 가이드](./claude-fable-5-1-prompt-guide.md)의 처방을 시험합니다.

- 병렬 도구 호출이 1턴 1호출로 줄어드는 문제
- 길고 조밀한 산문("mannered prose" 정의문), 채팅 서식 규칙의 방향 반전
- 요약 시 표시 없는 인용, 소규모 수정에도 파일 전체를 다시 쓰는 문제
- 범위·테스트 제한 지시, `low` effort의 검색 유도, compaction 요약 보존 항목, 비전 crop·zoom 도구

5.2에서 새로 생긴 것은 코드 소유권, 서브에이전트 위임, 신중함 누적, 구모델용 하네스 재검토, 보고서 블록입니다.

## 마이그레이션 체크리스트

공식 "Where to start" 순서입니다.

1. `effort`를 `high`로 명시하고, `medium`·`xhigh`에서도 평가를 돌립니다.
2. 옮겨 오는 시스템 프롬프트·스킬·에이전트 파일·메모리 파일·노트·하네스 문구를 읽고, [재검토 표](#구모델용-프롬프트하네스-재검토)의 항목을 지우거나 시험합니다.
3. 가장 긴 에이전트 과제를 돌려 조기 종료, 불필요한 승인 요청, 침묵, 과한 위임, 구조 개선 대신 덧붙이기가 어디서 나오는지 기록합니다.
4. 관찰한 행동마다 지시문이나 조언을 하나씩 넣고, 효과와 토큰 비용을 측정합니다.

API 쪽은 다음을 확인합니다.

- [ ] 모델 ID `claude-fable-5-2` (Claude Code에서는 `/claude-api migrate this project to claude-fable-5-2`)
- [ ] `messages` 배열을 직접 만드는 코드라면, 5.1에서 오류가 난 적이 없어도 prefix check 시험
- [ ] 라우터·폴백이 대화를 다른 모델로 옮기면 5.2 사고 블록이 버려지는 것을 예상 (Mythos 5.2 제외)
- [ ] `computer_20251124` → `computer_toolset_20260801` (Bedrock 제외)
- [ ] advisor 도구의 조언자 `model`을 `claude-fable-5-2`·`claude-mythos-5-2`로, 조언 평문을 읽던 코드는 `advisor_redacted_result`에 맞게
- [ ] 작은 `max_tokens`를 쓰던 요청은 사고 몫을 남기도록 올림
- [ ] CMEK 조직은 structured outputs 제거 후 코드에서 검증
- [ ] 운영 트래픽을 옮기기 전에 5.2 전용 요청 한도 확인, Priority Tier 약정이 있으면 용량 따로 계획
- [ ] Opus 5.5에서 오면 ZDR 여부, effort 기본값 차이, 두 배 단가 확인

## 요약

5.2는 5.1보다 싸고(입력·출력 20% 인하) 같은 1M 창과 128K 출력을 가집니다. 요청 계약에서는 prefix check가 모든 계정에 적용되는 것이 가장 큰 변화이고, 프롬프트에서는 "생각을 줄이라"는 줄이 더는 듣지 않는다는 점과 코드 소유권·위임·쌓인 경고에 민감하다는 점이 새롭습니다. 처방은 미리 다 넣지 말고, 증상을 관찰한 뒤 하나씩 넣어 측정합니다.
