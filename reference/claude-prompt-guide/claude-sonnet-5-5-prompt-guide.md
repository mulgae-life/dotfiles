# Claude Sonnet 5.5 Prompting Guide

> **출처**:
> - [Prompting Claude Sonnet 5.5 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5-5)
> - [What's new in Claude Sonnet 5.5 | Anthropic](https://platform.claude.com/docs/en/models/sonnet-5-5/whats-new-sonnet-5-5)
> - [Migrating to Claude Sonnet 5.5 | Anthropic](https://platform.claude.com/docs/en/models/sonnet-5-5/migration-guide)
> - [Claude Sonnet 5.5 | Anthropic](https://platform.claude.com/docs/en/models/sonnet-5-5/overview)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
> - [Thinking troubleshooting | Anthropic](https://platform.claude.com/docs/en/build-with-claude/thinking-troubleshooting)
>
> **날짜**: 2026-10-01
> **자매 가이드**: [Claude Sonnet 5](./claude-sonnet-5-prompt-guide.md) · [Claude Opus 5.5](./claude-opus-5-5-prompt-guide.md)

Claude Sonnet 5.5 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 실었습니다. 시스템 프롬프트에 바로 붙여 쓰는 용도입니다.

**전제**: 공식 가이드는 다음 문장으로 시작합니다.

> Existing Claude Sonnet 5 prompts should perform well without changes, and the patterns in Prompting Claude Sonnet 5 remain a reasonable starting point. For the hardest long-horizon work, an Opus model is the better choice.

기존 Sonnet 5 프롬프트는 고치지 않아도 잘 동작하고, [Sonnet 5 가이드](./claude-sonnet-5-prompt-guide.md)의 패턴도 출발점으로 유효합니다. 아래 처방은 관찰된 증상이 있을 때만 넣습니다. 예외는 [API 파괴적 변경 5건](#api-파괴적-변경-5건)입니다. 프롬프트가 아니라 요청 계약이 바뀐 것이라, 해당 설정을 쓰는 코드는 반드시 고쳐야 합니다.

## 목차
- [모델 개요](#모델-개요)
- [증상별 찾아가기](#증상별-찾아가기)
- [API 파괴적 변경 5건](#api-파괴적-변경-5건)
- [effort 보정](#effort-보정)
- [주도성과 작업 범위](#주도성과-작업-범위)
- [응답 전 사고 끄기 (`between_tools`)](#응답-전-사고-끄기-between_tools)
- [JSON으로 답하는 추론 작업](#json으로-답하는-추론-작업)
- [진행 업데이트](#진행-업데이트)
- [채팅·지식 작업의 도구 사용](#채팅지식-작업의-도구-사용)
- [작업 중 사용자 메시지](#작업-중-사용자-메시지)
- [코딩 작업 검증](#코딩-작업-검증)
- [도구 호출 관용 처리](#도구-호출-관용-처리)
- [조밀한 시각 입력](#조밀한-시각-입력)
- [안전장치 거절](#안전장치-거절)
- [마이그레이션 체크리스트](#마이그레이션-체크리스트)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-sonnet-5-5` (2026-09-28 출시, 날짜 접미사 없음). Amazon Bedrock은 `anthropic.claude-sonnet-5-5` |
| **포지션** | 공식 표현은 "The best combination of speed and intelligence". 가장 어려운 장기 작업은 Opus를 권합니다 |
| **컨텍스트/출력** | 1M 토큰, 최대 128K 출력 (Batch API는 `output-300k-2026-03-24` 베타로 300K) |
| **가격** | $2 / $10 per MTok (Sonnet 5와 같음), 캐시 읽기 $0.10 (2026-10-07 Haiku 5.5 출시와 함께 입력가의 0.1배에서 0.05배로 인하) |
| **캐시 최소** | 512 토큰 (Sonnet 5·4.6은 1,024) |
| **지식 컷오프** | 2026-06 |
| **토크나이저** | Sonnet 5와 같음. Sonnet 4.6·Haiku 4.5보다 같은 텍스트에서 약 30% 많은 토큰 |
| **Thinking** | 적응형 사고(adaptive thinking)가 기본으로 켜짐. 가장 낮은 설정은 `between_tools`(effort `high` 이하). `disabled`와 `enabled`(`budget_tokens`)는 400 |
| **기본 effort** | `high` (Claude API). 5단계 `low`~`max` 모두 지원 |
| **sampling** | `temperature`·`top_p`·`top_k`를 기본값이 아닌 값으로 보내면 400 |
| **이미지** | 고해상도 티어: 긴 변 2576px, 이미지당 최대 4,784 토큰 (Sonnet 4.6·Haiku 4.5는 1568px·1,568 토큰) |
| **은퇴** | 2027-09-28 이전에는 은퇴하지 않음 |

## 증상별 찾아가기

공식 가이드의 증상 목록입니다.

| 관찰된 증상 | 갈 곳 |
|------|------|
| effort 레벨을 모르겠거나, 턴이 Sonnet 5보다 길거나 짧다 | [effort 보정](#effort-보정) |
| 코딩 작업이 끝나기 전에 멈춰서 확인을 구하거나, 요청보다 많이 한다 | [주도성과 작업 범위](#주도성과-작업-범위) |
| 지금 통합이 thinking을 끄고 돈다 | [응답 전 사고 끄기](#응답-전-사고-끄기-between_tools) |
| 몇 단계 계산이 필요한 작업의 JSON 답이 틀리거나 파싱이 안 된다 | [JSON으로 답하는 추론 작업](#json으로-답하는-추론-작업) |
| 긴 에이전트 턴이 조용하다 | [진행 업데이트](#진행-업데이트) |
| 검색하면 바뀐 내용을 잡을 수 있는데 학습 지식으로 답한다 | [채팅·지식 작업의 도구 사용](#채팅지식-작업의-도구-사용) |
| 작업 중 사용자가 보낸 메시지를 무시하거나 주입된 텍스트로 취급한다 | [작업 중 사용자 메시지](#작업-중-사용자-메시지) |
| 테스트나 빌드 없이 코드 변경을 완료로 보고한다 | [코딩 작업 검증](#코딩-작업-검증) |
| 도구 이름의 대소문자가 틀리거나 파라미터 이름을 조금 다르게 보낸다 | [도구 호출 관용 처리](#도구-호출-관용-처리) |
| 조밀한 차트·기술 도면의 세부를 놓친다 | [조밀한 시각 입력](#조밀한-시각-입력) |
| `stop_reason: "refusal"`이 온다 | [안전장치 거절](#안전장치-거절) |

## API 파괴적 변경 5건

Sonnet 5에서 모델 ID만 바꾸면 실패하는 변경입니다.

1. **응답 전 사고 끄기는 `between_tools`로**: `thinking: {"type": "disabled"}`는 400입니다. `thinking: {"type": "between_tools"}`를 보내되 effort `low`·`medium`·`high`에서만 됩니다. `xhigh`·`max`에서는 400이므로 그 레벨은 적응형 사고로 돌립니다(`thinking` 생략 또는 `{"type": "adaptive"}`). `between_tools`에는 `display`·`budget_tokens`·`block_binding`을 같이 보낼 수 없습니다. 수동 사고 예산(`enabled` + `budget_tokens`)도 400입니다.
2. **강제 도구 사용 불가**: `tool_choice`의 `{"type": "any"}`와 `{"type": "tool", ...}`는 400입니다. `auto`(기본)와 `none`은 됩니다. 스키마에 맞는 도구 입력이 필요하면 `auto`를 유지하고 도구 정의에 `strict: true`를 겁니다.
3. **사고 블록은 모델과 대화에 묶임**: Sonnet 5.5는 Sonnet 5·Opus 4.8·Haiku 4.5와 그 이전 모델의 사고 블록, 그리고 Claude API·Google Cloud에서는 Haiku 5.5의 블록을 읽지만, Opus 5·Opus 5.5·Fable·Mythos의 블록은 읽지 않습니다(Claude API·Google Cloud에서는 Opus 5.5가 Sonnet 5.5 블록을 읽음). 또 사고 블록 앞의 `system`·`tools`·이전 메시지가 바뀌었는지 검사합니다. 2026-08-31 00:00 UTC 이후 만든 계정은 Claude API·Amazon Bedrock·Google Cloud에서 이 검사가 기본으로 켜져 있어, 이력을 고친 뒤 블록을 다시 보내면 400입니다. 대화를 append-only로 유지하고, 지시나 도구는 대화 중 시스템 메시지(mid-conversation system message)로 바꿉니다.
4. **`computer_20251124` 거부** (Claude API·Google Cloud): `computer_toolset_20260801` 툴셋만 받습니다. Amazon Bedrock은 이전 도구를 받습니다.
5. **advisor 도구 조합 축소** (베타): Sonnet 5.5 실행자의 advisor로 Opus 4.8·Opus 4.7·Sonnet 5는 쓸 수 없습니다.

요청은 성공하지만 응답 모양이 바뀌는 변경도 하나 있습니다. 도구 호출 사이에 쓰는 한두 문장보다 긴 메모가 `text`가 아니라 진행 업데이트 `thinking` 블록으로 옵니다. 기본값(`display: "omitted"`)에서는 이 블록의 텍스트가 비어 있으므로, 그 텍스트를 사용자에게 스트리밍하던 앱은 조용해집니다 → [진행 업데이트](#진행-업데이트).

## effort 보정

effort가 사고량, 그리고 품질·지연·비용을 정하는 주된 조절 장치입니다. 레벨이 재보정돼서 같은 이름의 레벨이 Sonnet 5와 같은 사고량을 뜻하지 않습니다. Sonnet 5에서 쓰던 값을 옮기지 말고 자체 평가로 다시 측정합니다.

| 작업 | 시작 레벨 |
|------|------|
| 일반 | `high` (API 기본값) |
| 에이전트 코딩·다단계 도구 사용 | 명세가 분명하면 `medium`, 어렵거나 긴 작업은 `high` |
| 채팅 등 지연에 민감한 작업 | `medium` 또는 `low` (effort가 높을수록 첫 응답까지 오래 기다림) |

- `low`에서는 사고를 짧게 하고 변경 검증을 건너뛸 수 있습니다. `low`·`medium`의 긴 에이전트 작업에서는 끝내기 전에 멈춰 사용자에게 확인을 구하는 일이 늘어납니다.
- `max_tokens`는 사고와 예상 답변을 함께 담을 만큼 잡습니다. 사고 내용이 돌아오지 않아도 사고는 `max_tokens`에 포함됩니다. 에이전트 코딩은 최대치인 128,000으로 잡고 스트리밍합니다.
- `xhigh`·`max`는 측정된 품질 이득이 있을 때만 씁니다. 사고와 답변이 훨씬 길어지고, 이 레벨에서는 `between_tools`를 받지 않습니다.
- 사고를 줄이려면 effort를 낮춥니다. `medium` 이상에서는 인사말에도 짧게 생각하고, 시스템 프롬프트로 덜 생각하라고 해도 안정적으로 줄지 않습니다. `low`에서는 단순한 요청 대부분에서 사고를 건너뜁니다.
- 요청마다 최상위 `effort`를 바꾸면 프롬프트 캐시가 깨집니다. 턴별로 레벨을 바꾸려면 메시지별 effort(per-message effort, 베타)를 씁니다. 적응형 사고가 필요하고, `between_tools`와 함께 쓰면 400입니다.

## 주도성과 작업 범위

얼마나 스스로 나아가는지는 effort와 요청에 따라 달라집니다. 낮은 effort에서는 코딩 작업이 끝나기 전에 확인을 구하고, 높은 effort나 열린 요청에서는 요청보다 많이 합니다.

**끝까지 진행시키기** (`low`·`medium`의 에이전트 코딩): 계획 확인을 위해 멈추거나, 스스로 답할 수 있는 질문을 하거나, 여러 부분 중 하나만 끝내고 계속할지 묻는 경우입니다. 먼저 effort를 올려 보고, effort를 유지하려면 아래를 시스템 프롬프트에 넣습니다. 이 프롬프트를 넣으면 세션이 길어지고 비용이 늘어나며, 위험하거나 되돌릴 수 없는 행동에 대한 자체 규칙을 대신하지 않습니다.

```text
Keep working until everything the user asked for is done, and only stop to ask when you can't go on without the user or before a risky step.

When the work the user asked for is done and checked, stop and report. Don't add features, tests, files, docs or refactors that weren't asked for. If you think one would help, mention it at the end instead of doing it.
```

**요청하지 않은 추가물**: 모든 effort에서 저장소 관례에 맞는 테스트·문서·작은 보조 파일을 요청 없이 더하고, effort가 높을수록 많이 더합니다. 요청한 변경 자체는 요청에 가깝게 유지됩니다. 명시적으로 요청한 것만 바꾸게 하려면 위 프롬프트의 둘째 문단("When the work the user asked for is done"으로 시작)만 넣습니다. `xhigh`·`max`에서는 이 문단이 추가물을 줄이고 변경 전체를 작게 만듭니다.

**`xhigh`·`max`의 과잉 점검**: 작업을 끝낸 뒤 스스로 검토·검증 라운드를 시작하고, 하네스가 제공하면 서브에이전트까지 띄우며, 지나가며 본 관련 수정도 합니다. 일상 작업은 `high` 이하에서 돌리고, 높은 레벨의 꼼꼼함을 작업 자체에만 쓰게 하려면 아래를 넣습니다. 공식 테스트에서 `max` 코딩 작업의 리뷰 서브에이전트 실행이 멈췄고 세션 비용이 약 3분의 1 줄었으며 품질 변화는 없었습니다. 메인 에이전트가 스스로 시작하는 검토 라운드는 줄지만 완전히 없어지지는 않습니다.

```text
When the work the user asked for is done and its checks pass, stop and report. Don't start extra rounds of review or hardening on your own, and don't launch reviewer sub-agents unless the user asked for a review. If you think a deeper review is worth doing, say so at the end.
```

**열린 요청**: "이걸로 뭘 할 수 있는지 보여줘" 같은 요청에 아이디어만 원했는데 발표 자료·보고서·영상을 만들기 시작할 수 있습니다. 아이디어나 계획을 먼저 원하면 요청에 그렇게 쓰거나 아래를 넣습니다.

```text
When the user asks for ideas, options or a plan, give them that and stop. Don't start building or changing anything until they say to go ahead.
```

## 응답 전 사고 끄기 (`between_tools`)

지금 통합이 thinking을 끄고 돈다면 `thinking: {"type": "between_tools"}`로 바꾸고 다음을 확인합니다.

- **effort `high` 이하에서만 보냅니다.** `between_tools`에서는 대화 중 effort도 바꿀 수 없어, 적용 중인 레벨과 다른 메시지별 `output_config.effort`는 400입니다. 턴마다 effort를 바꾸려면 적응형 사고를 씁니다.
- **"생각하지 마라" 지시를 지웁니다.** `between_tools`에서 이런 지시는 모델이 내부 XML 태그를 보이는 출력에 쓸 가능성을 높입니다.
- **응답을 블록 타입별로 읽습니다.** 적응형 사고에서는 응답이 `thinking` 블록으로 시작할 수 있고(기본 `display: "omitted"`에서는 내용이 비어 있음), `between_tools`에서는 진행 업데이트 `thinking` 블록으로 시작할 수 있습니다. 첫 블록이 텍스트라고 가정하지 않습니다.
- **`thinking` 블록을 그대로 돌려보냅니다.** `between_tools`에서도 도구 호출 사이 메모가 한두 문장보다 길면 요약이 붙은 `thinking` 블록으로 옵니다. 나머지 assistant 턴과 함께 수정 없이 보내면 모델은 요약이 아닌 원래 메모 전체를 받습니다.
- **도구 없는 추론 작업은 적응형 사고로 돌립니다.** 도구가 없는 요청에서 `between_tools`는 생각 없이 바로 답한다는 뜻입니다.

## JSON으로 답하는 추론 작업

문서 속 수치 합산, 규칙 적용, 항목 순위 매기기처럼 몇 단계 계산이 필요한 작업에 JSON 답을 요청하는 경우입니다. 특히 `low`·`medium`에서 생각 없이 바로 답하는 일이 많습니다. 가능하면 구조화 출력(structured outputs)을 써서 응답이 스키마에 맞는 JSON만 담게 합니다. 이때 모델은 사고 안에서만 문제를 풀 수 있으므로, 사고를 건너뛰면 정확도가 떨어집니다.

**먼저 생각하게 하기** (적응형 사고): 시스템 프롬프트 끝에 아래 한 줄을 넣습니다. `high`에서는 출력 토큰이 조금 늘고 정확도가 `xhigh`에 가까워집니다. `low`·`medium`에서는 정확도가 오르지만 `high` 수준에는 못 미치고 토큰 증가가 더 큽니다.

```text
Think the problem through before you answer.
```

- 이 줄 없이도 적응형 사고의 `xhigh`가 이런 작업에서 가장 정확합니다. 출력 토큰은 `high`보다 많습니다.
- `between_tools`에서는 도구가 없으면 생각하지 않으므로 이 줄이 효과가 없습니다. 이런 요청은 적응형 사고로 보냅니다. 답 요청과 JSON 요청을 둘로 나누면 정확도와 JSON 준수가 모두 높았지만 비용과 지연이 매우 컸습니다.
- 구조화 출력을 `low`·`medium`에서 쓰면 가끔 `max_tokens`까지 생각만 하다 끝납니다(`high` 이상에서는 거의 없음). 텍스트에 유효한 JSON이 있어도 `stop_reason`이 `"max_tokens"`면 실패로 보고 재시도합니다.

구조화 출력을 쓸 수 없어 프롬프트로 JSON을 요청하면, 모델이 응답 텍스트에서 문제를 푼 뒤 끝에 JSON을 쓰는 경우가 많습니다. 답은 대개 맞지만 응답 전체를 JSON으로 기대하는 파서는 실패합니다.

- **응답의 마지막 JSON 값을 파싱합니다.** `text` 블록만 읽고 `"max_tokens"` 종료는 실패로 봅니다. 각 `{`·`[`에서 JSON 파싱을 시도하고, 성공하면 그 값의 끝부터 이어서 찾아 중첩된 값을 따로 세지 않으며, 마지막 값을 씁니다. 첫 `{`부터 마지막 `}`까지 통째로 자르지 않습니다(최종 JSON 앞에 초안을 쓰는 경우가 있음). 필드를 확인하고, 없으면 한 번 재시도합니다. 공식 테스트에서 정확도 변화 없이 거의 모든 응답을 쓸 수 있게 됐습니다.
- **적응형 사고의 `xhigh`도 고려합니다.** 사고 안에서 문제를 풀고 거의 항상 JSON만 돌려주며, 풀이가 응답에서 사고로 옮겨 가 총 출력 토큰은 `high`와 비슷합니다.

## 진행 업데이트

도구 호출 사이에 무엇을 찾았고 다음에 무엇을 할지 사용자용 메모를 씁니다. 한두 문장보다 긴 메모는 진행 업데이트 `thinking` 블록으로, 짧은 말은 `text`로 옵니다. 기본 `thinking.display`에서는 이 블록의 텍스트가 비어 있어서, `text`만 그리는 클라이언트는 긴 에이전트 턴 동안 조용해 보입니다.

- 메모를 보여주려면 `display: "updates"`(베타, `thinking-display-updates-2026-08-18` 헤더)를 설정합니다. `between_tools`에서는 요약 텍스트가 함께 오므로 `display`가 필요 없습니다.
- 긴 턴 중간에 코드 조각이나 답이 필요한 질문처럼 정확한 텍스트를 보여줘야 한다면, 사용자에게 메시지를 보내는 단순한 도구를 주고 그런 내용에만 쓰라고 지시합니다. `tools` 목록이 나중에 바뀌지 않도록 세션 첫 요청에서 선언합니다.
- "결과는 최종 응답에 모아라" 같은 예전 지시를 지웁니다. 첫 도구 호출 전 할 일 한 줄, 끝에 짧은 요약처럼 정해진 지점의 업데이트를 원하면 시스템 프롬프트에 그렇게 씁니다. 사람이 함께 보는 작업에서 효과가 큽니다.
- 그래도 도구 호출만 이어지며 조용하면, 하네스가 텍스트도 업데이트도 없이 이어진 도구 호출 단계를 세어 예를 들어 다섯 번째 뒤에 턴 한정 시스템 메시지(turn-scoped system message, 베타)로 아래 리마인더를 붙입니다. 두세 번째 뒤에도 조용하면 그만 보냅니다. 도구 결과 뒤에 하네스 텍스트가 잦으면 모델이 프롬프트 주입을 의심합니다. 리마인더는 이후 요청에서도 `messages`에 남겨 둡니다(덧붙이기만 하므로 프롬프트 캐시와 보존된 사고가 유지됨). `high`에서 메시지 전송 도구와 함께 쓰면 업데이트가 잦아지고 가장 긴 무음 구간이 짧아졌으며 작업 품질 변화는 측정되지 않았습니다.

```text
The user hasn't heard from you in a while — say in a few words what you're doing, then continue.
```

## 채팅·지식 작업의 도구 사용

허용·요건·요금처럼 바뀌었을 수 있는 내용을 웹 검색 없이 학습 지식으로 답하는 경우가 있습니다. 먼저 "꼭 필요할 때만 도구를 써라", "도구 호출을 최소화하라" 같은 문구를 지웁니다. 제품이 검색 도구를 제공하면 아래를 넣습니다. 현재 정보에 답이 달린 리서치·지원 제품에서 가장 중요합니다.

```text
Use the search tool to check specifics that may have changed since your training, such as what is allowed, required or charged, even when you feel confident. For researched work such as a report or a comparison, gather current sources rather than writing from your training knowledge.
```

## 작업 중 사용자 메시지

Sonnet 5.5는 도구 결과 등으로 들어오는 간접 프롬프트 주입에 저항하도록 훈련돼서, 진짜 사용자 메시지를 주입으로 의심할 때가 있습니다. 사용자가 작업 중 보낸 메시지가 도구 결과 바로 뒤의 대화 중 시스템 메시지나 `tool_result` 블록 안으로 들어오면, 도구 결과에 사용자를 사칭한 텍스트가 있다고 말하며 무시하거나 확인을 구합니다. 도구 결과마다 붙는 토큰 카운트다운, 다단계 턴 중의 사용자 입력, 매 단계 하네스 지시가 원인이 됩니다.

- 사용자 텍스트를 `tool_result` 블록 안에 넣지 않습니다. 가장 자주 오해하는 배치입니다.
- 작업 중 사용자 입력은 user 턴으로 전달합니다. `tool_result` 블록들을 담은 user 메시지 안에서 마지막 `tool_result` 뒤에 텍스트 블록으로 붙입니다.
- 리마인더 같은 하네스 안내는 사용자 말 뒤의 별도 대화 중 시스템 메시지로 둡니다. 안내와 사용자 말을 한 블록에 섞지 않습니다.
- 사용자가 턴 중간에 입력할 수 있는 대화형 세션에서는 도구 결과 뒤에 자체 토큰·예산 카운트다운을 붙이지 않습니다. 태스크 예산(task budgets, 베타)은 이 오해를 일으키는 것이 관찰되지 않았습니다.

## 코딩 작업 검증

에이전트 코딩에서는 대체로 완료 보고 전에 작업을 확인하지만, `low`에서는 변경을 실제로 실행하는 확인 없이 완료로 보고하기도 합니다(예: 의존성이 설치되지 않았다며 테스트를 건너뜀). 대화 기록에 테스트·빌드 출력 없이 완료 보고가 보이면 아래 문단을 넣습니다. `low`에서 건너뛰거나 형식적인 확인이 드물어졌고, 작업 품질 변화 없이 작업당 비용만 조금 올랐습니다.

```text
When you change code that can be run, built, or type-checked, run a real check that exercises the change before reporting it done: the project's tests, type-checker, or build, or the changed command itself. A syntax-only check, or a check command that failed to start, does not count; if all that is missing is the project's declared dependencies, install them with its own package manager and lockfile (e.g. npm install, pip install -r requirements.txt), never via sudo or the system package manager, unless told not to. Only if no real check can run here, say which one you did not run and why instead of reporting the change as done.
```

## 도구 호출 관용 처리

선언된 도구를 대소문자만 다른 이름(`Bash` 대신 `bash`)으로 부르거나, 알려진 파라미터를 조금 다른 이름으로 보낼 때가 있습니다. 치명적 오류로 처리하지 말고 하네스에서 둘 중 하나로 다룹니다.

- 대소문자가 틀려도 대응이 하나로 분명하면 호출을 받아들입니다.
- 정확한 이름을 적은 `tool_result`를 `is_error: true`로 돌려줍니다. 모델은 대개 다음 턴에 고칩니다.

## 조밀한 시각 입력

조밀한 차트와 기술 도면에는 이미지를 자르고 확대하거나 코드를 실행할 수단을 줍니다. 도구가 있으면 훨씬 정확하게 읽습니다. 차트는 모든 effort에서, 기술 도면은 `high` 이상(특히 `xhigh`·`max`)에서 도움이 됩니다. 차트는 effort를 올리는 것보다 도구를 주는 편이 낫습니다. 공식 테스트에서 도구가 있는 `high`가 도구 없는 `max`보다 정확했고 비용은 일부였습니다. 작동하는 도구 정의는 [crop tool recipe](https://platform.claude.com/cookbook/multimodal-crop-tool)에 있습니다.

## 안전장치 거절

안전 분류기가 요청을 거절하면 정상 응답으로 `stop_reason: "refusal"`이 오고 `stop_details.category`가 범주를 알려줍니다. Sonnet 5보다 범주가 많습니다.

| 범주 | 뜻 |
|------|------|
| `cyber` | 악성코드·익스플로잇 개발처럼 사이버 피해를 도울 수 있음. 소스 코드 취약점 찾기는 허용, 고위험 이중 용도 보안 작업은 불허 |
| `bio` | 위험한 실험 방법처럼 생물학적 피해를 도울 수 있음. 일상 건강·교육 질문은 영향 없음 |
| `frontier_llm` | 경쟁 AI 모델 개발을 도울 수 있음 |
| `reasoning_extraction` | 내부 추론을 응답 텍스트에 재현하라는 요청 |
| `general_harms` | 그 밖의 이용 정책 영역. 무해한 작업도 걸릴 수 있음 |

- 서버 측 폴백(`fallbacks: "default"`, 베타, Claude API 전용)은 `cyber`·`frontier_llm` 거절을 Sonnet 5로 재시도하고, `bio`·`reasoning_extraction`·`general_harms`는 재시도하지 않습니다.
- 프롬프트가 추론을 응답에 포함하라고 요구하면 `reasoning_extraction` 거절을 부르므로 지웁니다. 추론은 적응형 사고의 요약 블록(`display: "summarized"`)에서 읽습니다.
- `bio` 분류기가 조직의 생명과학 작업을 막으면 Life Sciences Verification Program에, 정당한 보안 작업은 Cyber Verification Program에 신청합니다. Sonnet 4.6·4.5·Haiku 4.5에서 넘어오는 코드는 실시간 사이버 안전장치가 새로 적용됩니다.

## 마이그레이션 체크리스트

공식 체크리스트를 출발 모델별로 줄였습니다. 위에서부터 내려가며 자기 모델이 나오는 그룹까지 적용합니다. 전체 단계는 [공식 마이그레이션 가이드](https://platform.claude.com/docs/en/models/sonnet-5-5/migration-guide)를 봅니다.

**모든 출발 모델**
- [ ] 모델 ID를 `claude-sonnet-5-5`로 바꾸고, 응답을 블록 타입별로 읽으며 `thinking` 블록은 그대로 돌려보냄
- [ ] 사고를 끄던 통합은 응답 전 사고만 끄는 `between_tools`(effort `high` 이하)로, 강제 도구 사용은 `auto` + strict 도구로 교체
- [ ] 대화 append-only 유지, 컴퓨터 사용은 툴셋으로(Claude API·Google Cloud), advisor는 지원 조합으로
- [ ] 도구 호출 사이 텍스트를 `thinking` 블록에서 읽기, 거절 처리와 폴백 구성
- [ ] effort 재측정과 비용 기준선 재설정

**Sonnet 4.6 이하에서**
- [ ] `thinking` 필드 없는 요청도 사고가 돌므로 `max_tokens` 재검토, 사고 예산은 effort로 교체(예산과 effort의 고정 대응은 없어 두세 레벨을 평가)
- [ ] 기본값이 아닌 `temperature`·`top_p`·`top_k` 제거, 사고 텍스트를 보여주면 `display: "summarized"`
- [ ] 토큰 재계산(약 30% 증가), 이미지 토큰 예산 재설정

**Sonnet 4.5·Haiku 4.5에서** (위 그룹에 더해)
- [ ] assistant prefill 제거(400) → 형식은 구조화 출력, 서두 생략은 시스템 프롬프트, 이어 쓰기는 user 메시지로
- [ ] effort 명시, 컨텍스트 창 베타 헤더와 `interleaved-thinking-2025-05-14` 제거, `output_format` → `output_config.format`
- [ ] Haiku 4.5에서 올 때: 토큰 단가와 토큰 수가 모두 늘어 비용 재산정, 캐시 최소가 4,096 → 512 토큰

## 요약

| 축 | 처방 |
|------|------|
| **출발점** | Sonnet 5 프롬프트 그대로. 처방은 증상이 있을 때만 |
| **effort** | 재보정됨. 일반 `high`, 명세가 분명한 에이전트 코딩 `medium`, 채팅 `medium`·`low`. 사고를 줄이려면 지시가 아니라 effort |
| **사고 끄기** | `disabled`는 400 → 응답 전 사고만 끄는 `between_tools` (effort `high` 이하, 도구 없는 추론 작업은 적응형) |
| **범위** | 낮은 effort는 중간 확인, 높은 effort는 추가물·과잉 점검 → 공식 스니펫 3종 |
| **도구 계약** | 강제 `tool_choice` 400, 대화 append-only, 진행 메모는 `thinking` 블록 |
| **거절** | 범주 5종. 추론을 답에 쓰라는 지시는 삭제 |
