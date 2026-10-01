# Claude Sonnet 5 Prompting Guide

> **출처**:
> - [Prompting Claude Sonnet 5 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5)
> - [Claude Sonnet 5 | Anthropic](https://platform.claude.com/docs/en/models/sonnet-5/overview)
> - [Migrating to Claude Sonnet 5.5 | Anthropic](https://platform.claude.com/docs/en/models/sonnet-5-5/migration-guide) (Sonnet 4.6 이하 → Sonnet 5 세대 변경 확인용)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
> - [Thinking troubleshooting | Anthropic](https://platform.claude.com/docs/en/build-with-claude/thinking-troubleshooting)
>
> **날짜**: 2026-10-01
> **자매 가이드**: [Claude Sonnet 5.5](./claude-sonnet-5-5-prompt-guide.md) · [Claude Opus 5](./claude-opus-5-prompt-guide.md)

Claude Sonnet 5 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 실었습니다. 시스템 프롬프트에 바로 붙여 쓰는 용도입니다.

**전제**: 공식 가이드는 "It performs well out of the box on existing Claude Sonnet 4.6 prompts"라고 밝힙니다. 아래 패턴은 조정이 가장 자주 필요한 행동에 한정됩니다. Sonnet 5는 레거시 모델이고 현행 Sonnet은 [Sonnet 5.5](./claude-sonnet-5-5-prompt-guide.md)입니다. 새로 시작하는 작업이면 5.5를 먼저 검토하되, Sonnet 5를 계속 쓰는 통합에는 이 가이드를 적용합니다.

## 목차
- [모델 개요](#모델-개요)
- [증상별 찾아가기](#증상별-찾아가기)
- [Sonnet 4.6에서 바뀐 API 계약](#sonnet-46에서-바뀐-api-계약)
- [응답 길이](#응답-길이)
- [effort와 사고 깊이](#effort와-사고-깊이)
- [도구 사용](#도구-사용)
- [진행 업데이트](#진행-업데이트)
- [문자 그대로의 지시 이행](#문자-그대로의-지시-이행)
- [어조와 문체](#어조와-문체)
- [디자인·프런트엔드 기본값](#디자인프런트엔드-기본값)
- [대화형 코딩 제품](#대화형-코딩-제품)
- [코드 리뷰 하네스](#코드-리뷰-하네스)
- [컴퓨터 사용](#컴퓨터-사용)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-sonnet-5` (2026-06-30 출시, 날짜 접미사 없음). Amazon Bedrock은 `anthropic.claude-sonnet-5` |
| **상태** | Active (legacy). 현행 Sonnet은 Sonnet 5.5 |
| **컨텍스트/출력** | 1M 토큰, 최대 128K 출력 (Batch API는 `output-300k-2026-03-24` 베타로 300K) |
| **가격** | $2 / $10 per MTok, 캐시 읽기 $0.20 |
| **캐시 최소** | 1,024 토큰 |
| **지식 컷오프** | 2026-01 |
| **토크나이저** | 새 토크나이저. Sonnet 4.6보다 같은 텍스트에서 약 30% 많은 토큰 |
| **Thinking** | 적응형 사고만. `thinking` 필드가 없어도 켜짐. `{"type": "disabled"}`로 끌 수 있음. `enabled`(`budget_tokens`)는 400 |
| **기본 effort** | `high`. 5단계 `low`~`max` 모두 지원 |
| **sampling** | `temperature`·`top_p`·`top_k`를 기본값이 아닌 값으로 보내면 400 (Sonnet 계열에서는 처음) |
| **강제 도구 사용** | `tool_choice` `any`·`tool` 허용 (Sonnet 5.5에서 400으로 바뀜) |
| **은퇴** | 2027-06-30 이전에는 은퇴하지 않음 |

## 증상별 찾아가기

공식 가이드의 절을 증상 기준으로 묶었습니다.

| 관찰된 증상 | 갈 곳 |
|------|------|
| 답이 제품이 기대하는 길이보다 길거나 짧다 | [응답 길이](#응답-길이) |
| `low`·`medium`에서 복잡한 문제를 얕게 푼다 | [effort와 사고 깊이](#effort와-사고-깊이) |
| 큰 시스템 프롬프트에서 사고 블록이 너무 자주 나온다 | [effort와 사고 깊이](#effort와-사고-깊이) |
| 사고 대부분을 쓰고 답이 잘리며 `stop_reason: "max_tokens"`가 온다 | [effort와 사고 깊이](#effort와-사고-깊이) |
| thinking을 끄자 도구를 덜 쓴다 | [도구 사용](#도구-사용) |
| 지시를 첫 항목에만 적용하고 나머지에는 적용하지 않는다 | [문자 그대로의 지시 이행](#문자-그대로의-지시-이행) |
| 열린 디자인 요청에 늘 같은 시각 스타일이 나온다 | [디자인·프런트엔드 기본값](#디자인프런트엔드-기본값) |
| 코드 리뷰에서 찾은 문제를 보고하지 않아 재현율이 떨어진다 | [코드 리뷰 하네스](#코드-리뷰-하네스) |

## Sonnet 4.6에서 바뀐 API 계약

모델 ID만 바꾸면 실패하거나 동작이 달라지는 지점입니다.

| 항목 | Sonnet 4.6 | Sonnet 5 |
|------|------|------|
| `thinking` 생략 | 사고 없이 실행 | 적응형 사고로 실행. `max_tokens`는 사고+응답 합산 상한이라 사고 없이 돌던 워크로드는 재검토 |
| 수동 사고 예산 | 폐기 예정이지만 동작 | `enabled` + `budget_tokens`는 400. 적응형 사고 + effort로 교체 |
| sampling | 허용 | 기본값이 아닌 값은 400 |
| 토큰 수 | 기준 | 같은 텍스트에서 약 30% 증가. 4.6에 맞춘 `max_tokens`는 같은 출력을 자를 수 있음 |
| 이미지 | 표준 티어(긴 변 1568px, 이미지당 최대 1,568 토큰) | 고해상도 티어(긴 변 2576px, 이미지당 최대 4,784 토큰). 같은 이미지가 최대 약 3배 토큰 |
| 실시간 사이버 안전장치 | 없음 | 적용. 정당한 보안 작업은 Cyber Verification Program |

assistant prefill은 Sonnet 4.6부터 이미 400이었으므로 새 변경이 아닙니다.

## 응답 길이

고정된 장황함 대신 작업의 복잡도에 맞춰 길이를 정합니다. 단순 조회에는 짧게, 열린 분석에는 길게 답합니다. 제품이 특정 길이나 문체에 기대고 있다면 프롬프트를 조정합니다. 장황함을 줄이는 예:

```text
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

과잉 설명처럼 특정한 종류의 장황함이 보이면 그것을 막는 지시를 더합니다. 적절한 간결함을 보여주는 긍정 예시가 "하지 마라"식 지시나 부정 예시보다 대체로 효과적입니다.

## effort와 사고 깊이

effort 기본값은 Sonnet 4.6과 같은 `high`입니다. 가장 어려운 코딩·에이전트 작업은 `xhigh`로 올립니다.

| 레벨 | 공식 설명 |
|------|------|
| `max` | 토큰 지출 제약 없는 최대 능력 |
| `xhigh` | 가장 어려운 코딩·에이전트 작업의 권장 설정 |
| `high` | 기본값. 대부분의 작업에서 토큰과 지능의 균형 |
| `medium` | 지능을 일부 내주고 토큰을 줄여야 하는 비용 민감 작업 |
| `low` | 짧고 범위가 정해진 작업, 지능이 중요하지 않은 지연 민감 워크로드 |

- **4.6 대비 대응**: Sonnet 5 `medium` ≈ Sonnet 4.6 `high`, Sonnet 5 `high` ≈ Sonnet 4.6 `max`. 벤치마크할 때는 effort 이름이 아니라 관찰된 사고 길이로 맞춥니다.
- **낮은 레벨을 엄격히 지킴**: `low`·`medium`에서는 요청한 범위 안에서만 일합니다. 지연과 비용에는 좋지만 중간 난도 작업을 `low`로 돌리면 덜 생각할 위험이 있습니다. 얕은 추론이 보이면 프롬프트로 우회하지 말고 effort를 `high`·`xhigh`로 올립니다. 지연 때문에 `low`를 유지해야 하면 아래를 더합니다.

```text
This task involves multistep reasoning. Think carefully through the problem before responding.
```

- **사고 빈도 조절**: 적응형 사고가 기본으로 켜져 있고(Sonnet 4.6은 같은 요청을 사고 없이 실행), 사고를 얼마나 자주 하는지 프롬프트로 조절할 수 있습니다. 크거나 복잡한 시스템 프롬프트에서 사고 블록이 원하는 것보다 자주 나오면 아래를 넣고 성능 변화를 측정합니다. 반대로 `medium`에서 덜 생각하면 첫 수단은 effort 상향이고, 더 세밀하게 조절하려면 프롬프트로 직접 요청합니다.

```text
Thinking adds latency and should only be used when it will meaningfully improve answer quality, typically for problems that require multistep reasoning. When in doubt, respond directly.
```

- **사고 끄기**: `thinking: {"type": "disabled"}`. Sonnet 4.6에서 사고를 끄고 쓰던 통합은 Sonnet 5에서 사고를 켜고 effort를 낮춰 보는 것이 공식 권고입니다.
- **`max_tokens` 여유**: `high`·`xhigh`·`max`에서는 사고와 도구 호출에 쓸 여유를 남깁니다. 긴 작업에서 예산이 빠듯하면 거의 사고만 하다가 답이 잘리고 `stop_reason: "max_tokens"`가 옵니다. `max_tokens`를 올리거나 `medium`으로 내리면 해결됩니다.

## 도구 사용

Sonnet 4.6보다 기본적으로 에이전트 성향이 강해서 도구를 더 쉽게 꺼내 쓰고 자체 검증 루프를 더 자주 돕니다.

- thinking을 끄면 도구 사용과 검색 고려가 줄어듭니다. 사고를 끈 채로 도구 호출에 기대고 있다면 시스템 프롬프트에 도구를 쓰라는 명시적 지시를 넣습니다.
- effort도 도구 사용을 바꿉니다. `high`·`xhigh`에서는 에이전트 검색과 코딩의 도구 사용이 크게 늘어납니다.
- 도구를 더 쓰게 하려면 언제 어떻게 쓰는지 프롬프트에 적습니다. 웹 검색 도구를 쓰지 않으면 왜, 어떻게 써야 하는지를 분명히 설명합니다.

## 진행 업데이트

긴 에이전트 작업 중 사용자에게 주기적이고 질 좋은 업데이트를 줍니다. "도구 호출 3번마다 진행 상황을 요약하라" 같은 강제 스캐폴딩을 넣어 두었다면 지워 봅니다. 업데이트의 길이나 내용이 맞지 않으면 어떤 모습이어야 하는지 프롬프트에 설명하고 예시를 줍니다.

## 문자 그대로의 지시 이행

특히 낮은 effort에서 프롬프트를 문자 그대로, 명시된 대로 해석합니다. 한 항목에 준 지시를 다른 항목으로 조용히 넓히지 않고, 하지 않은 요청을 추론하지 않습니다. 정밀함이 장점이라 세밀하게 조정한 API 프롬프트, 구조화 추출, 예측 가능한 동작이 필요한 파이프라인에서 대체로 더 좋습니다. 지시를 넓게 적용해야 하면 범위를 명시합니다(예: "Apply this formatting to every section, not just the first one").

## 어조와 문체

새 모델이 그렇듯 긴 글의 문체가 바뀔 수 있습니다. 특정 목소리에 기대는 제품은 새 기준선에서 문체 프롬프트를 다시 평가합니다. 더 따뜻하고 대화적인 목소리를 원하면 아래를 더합니다.

```text
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```

문체의 다양성을 `temperature`로 얻고 있었다면, Sonnet 5에서는 sampling 파라미터가 400이므로 지우고 시스템 프롬프트 지시로 어조와 다양성을 이끕니다.

## 디자인·프런트엔드 기본값

열린 프런트엔드·디자인 요청에서 일관된 기본 시각 스타일로 수렴할 수 있습니다. 어떤 요청에는 어울리지만 대시보드, 개발 도구, 핀테크, 의료, 기업용 앱에는 어색할 수 있습니다. "그 색은 쓰지 마", "깔끔하고 미니멀하게" 같은 일반 지시는 다양성을 만들기보다 다른 고정 팔레트로 옮겨 갈 뿐입니다. 안정적으로 통하는 방법은 둘입니다.

1. **구체적인 대안을 명세합니다.** 명시적 명세는 정확히 따릅니다. 공식 예시는 색상 hex 5개, 모서리 반경, 서체, 섹션 구성, hover 전환까지 적은 랜딩 페이지 명세입니다([원문](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-sonnet-5#design-and-frontend-defaults)).
2. **만들기 전에 선택지를 제안하게 합니다.** 기본값을 깨고 사용자에게 통제권을 줍니다. `temperature`를 받지 않으므로 실행마다 다른 디자인 방향을 얻는 공식 권장 방법입니다.

```text
Before building, propose 4 distinct visual directions tailored to this brief (each as: bg hex / accent hex / typeface, plus a one-line rationale). Ask the user to pick one, then implement only that direction.
```

이른바 "AI slop" 미감을 피하려면 위 방법과 함께 시스템 프롬프트에 아래 지시를 넣습니다. 더 자세한 처방은 [frontend-design skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)에 있습니다.

```text
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white or dark backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character. Use unique fonts, cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

## 대화형 코딩 제품

사용자 턴이 하나인 자율·비동기 코딩 에이전트와, 사용자 턴이 여럿인 대화형·동기 코딩 에이전트는 토큰 사용과 동작이 다릅니다. 코딩 제품에서 성능과 토큰 효율을 함께 높이려면 effort를 `xhigh`나 `high`로 두고, 자동 모드 같은 자율 기능을 더하고, 사용자에게 요구하는 상호작용 횟수를 줄입니다. 상호작용을 줄일 때는 작업, 의도, 관련 제약을 첫 사용자 턴에 미리 명세합니다. 모호한 요청을 여러 턴에 걸쳐 조금씩 전하면 토큰 효율이 떨어지고 성능도 떨어질 때가 있습니다.

## 코드 리뷰 하네스

이전 모델에 맞춘 리뷰 하네스에서는 처음에 재현율이 낮게 나올 수 있습니다. 능력 퇴보가 아니라 하네스 효과일 가능성이 큽니다. "심각한 문제만 보고하라", "보수적으로 하라", "사소한 지적은 하지 마라" 같은 지시를 이전 모델보다 충실히 따라서, 똑같이 깊이 조사하고 버그를 찾은 뒤에도 기준 미달이라 판단한 발견은 보고하지 않습니다. 정밀도는 대체로 오르지만, 버그를 찾는 능력이 좋아졌는데도 측정 재현율은 떨어질 수 있습니다. 공식 권장 문구:

```text
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage - a separate verification step will do that. Your goal here is coverage: it is better to surface a finding that later gets filtered out than to silently drop a real bug. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```

- 실제 두 번째 단계가 없어도 쓸 수 있지만, 확신도 필터링을 발견 단계 밖으로 빼면 대개 도움이 됩니다. 하네스에 검증·중복 제거·순위 단계가 따로 있으면 발견 단계의 일은 필터링이 아니라 망라라고 명시합니다.
- 한 번에 스스로 거르게 하려면 "중요한" 같은 질적 표현 대신 기준을 구체적으로 씁니다. 예: "report any bugs that could cause incorrect behavior, a test failure, or a misleading result; only omit nits like pure style or naming preferences."
- 평가 세트 일부로 프롬프트를 반복 조정해 재현율이나 F1 향상을 확인합니다.

## 컴퓨터 사용

`computer_toolset_20260801` 툴셋(Claude API·Google Cloud)과 이전 `computer_20251124` 도구를 모두 지원합니다. Claude API·Google Cloud에서는 웹 페이지 안 작업용 브라우저 사용 도구(`browser_toolset_20260801`)도 지원합니다. 해상도는 최대 2576px·3.75MP까지 동작하며, 내부 테스트에서는 1080p 이미지가 성능과 비용의 균형이 좋았습니다. 비용에 특히 민감하면 720p나 1366×768이 성능이 강하면서 더 저렴한 선택지입니다. 자체 테스트로 설정을 찾고, effort도 함께 조정해 봅니다.

## 요약

| 축 | 처방 |
|------|------|
| **출발점** | Sonnet 4.6 프롬프트 그대로. 조정은 증상이 있을 때만 |
| **API 계약** | `thinking` 생략 시 사고가 켜짐, 사고 예산·sampling은 400, 토큰 약 30% 증가 |
| **effort** | 기본 `high`, 가장 어려운 코딩은 `xhigh`. 얕은 추론은 프롬프트보다 effort 상향 |
| **지시 해석** | 문자 그대로. 넓게 적용할 지시는 범위를 명시 |
| **다양성** | `temperature` 대신 선택지 제안 프롬프트와 구체적 명세 |
| **리뷰 하네스** | 걸러서 보고하라는 지시를 충실히 따름 → 발견 단계는 망라로 |
