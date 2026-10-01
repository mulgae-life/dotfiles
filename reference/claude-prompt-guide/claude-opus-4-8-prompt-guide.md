# Claude Opus 4.8 Prompting Guide

> **출처**:
> - [Prompting Claude Opus 4.8 | Anthropic](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8)
> - [Claude Opus 4.8 | Anthropic](https://platform.claude.com/docs/en/models/opus-4-8/overview)
> - [Migrating to Claude Opus 5.5 | Anthropic](https://platform.claude.com/docs/en/models/opus-5-5/migration-guide) (Opus 4.8·4.7·4.6 절에서 4.8의 API 계약 확인)
> - [Effort | Anthropic](https://platform.claude.com/docs/en/build-with-claude/effort)
> - [Thinking troubleshooting | Anthropic](https://platform.claude.com/docs/en/build-with-claude/thinking-troubleshooting)
>
> **날짜**: 2026-10-01
> **자매 가이드**: [Claude Opus 5](./claude-opus-5-prompt-guide.md) · [Claude Opus 5.5](./claude-opus-5-5-prompt-guide.md)

Claude Opus 4.8 특화 프롬프팅 가이드입니다. 프롬프트 스니펫은 공식 문서 원문(영문)을 그대로 실었습니다. 시스템 프롬프트에 바로 붙여 쓰는 용도입니다.

**전제**: 공식 가이드는 "It performs well out of the box on existing Claude Opus 4.7 prompts"라고 밝힙니다. 아래 패턴은 조정이 가장 자주 필요한 행동에 한정됩니다. Opus 4.8은 레거시 모델이고 현행 Opus는 [Opus 5.5](./claude-opus-5-5-prompt-guide.md)입니다. Opus 4.8을 계속 쓰는 통합에는 이 가이드를 적용하고, Opus 5 세대 처방(적응형 사고 상시 실행, `between_tools` 등)은 섞지 않습니다.

## 목차
- [모델 개요](#모델-개요)
- [증상별 찾아가기](#증상별-찾아가기)
- [API 계약](#api-계약)
- [응답 길이](#응답-길이)
- [effort와 사고 깊이](#effort와-사고-깊이)
- [도구 사용](#도구-사용)
- [진행 업데이트](#진행-업데이트)
- [문자 그대로의 지시 이행](#문자-그대로의-지시-이행)
- [어조와 문체](#어조와-문체)
- [서브에이전트 생성 조절](#서브에이전트-생성-조절)
- [디자인·프런트엔드 기본값](#디자인프런트엔드-기본값)
- [대화형 코딩 제품](#대화형-코딩-제품)
- [코드 리뷰 하네스](#코드-리뷰-하네스)
- [컴퓨터 사용](#컴퓨터-사용)
- [요약](#요약)

## 모델 개요

| 항목 | 내용 |
|------|------|
| **모델 ID** | `claude-opus-4-8` (2026-05-28 출시). Amazon Bedrock은 `anthropic.claude-opus-4-8` |
| **상태** | Active (legacy). 현행 Opus는 Opus 5.5 |
| **강점** | 장기 에이전트 작업, 지식 작업, 비전, 메모리 작업 (공식 표현) |
| **컨텍스트/출력** | 1M 토큰(기본), 최대 128K 출력 (Batch API는 `output-300k-2026-03-24` 베타로 300K) |
| **가격** | $5 / $25 per MTok, 캐시 읽기 $0.50 |
| **캐시 최소** | 1,024 토큰 |
| **지식 컷오프** | 2026-01 |
| **Thinking** | 적응형 사고만. `thinking: {"type": "adaptive"}`를 보내야 켜짐(기본 꺼짐). `enabled`(`budget_tokens`)는 400 |
| **기본 effort** | `high`. 5단계 `low`~`max` 모두 지원. 공식 권장 시작점은 코딩·에이전트 `xhigh` |
| **Priority Tier** | 지원 (Opus 5.5는 미지원) |
| **은퇴** | 2027-05-28 이전에는 은퇴하지 않음 |

## 증상별 찾아가기

공식 가이드의 절을 증상 기준으로 묶었습니다.

| 관찰된 증상 | 갈 곳 |
|------|------|
| 답이 제품이 기대하는 길이보다 길거나 짧다 | [응답 길이](#응답-길이) |
| `low`·`medium`에서 복잡한 문제를 얕게 푼다 | [effort와 사고 깊이](#effort와-사고-깊이) |
| 적응형 사고를 켰더니 너무 자주 생각한다 | [effort와 사고 깊이](#effort와-사고-깊이) |
| 검색·도구를 쓸 상황에서 추론으로만 답한다 | [도구 사용](#도구-사용) |
| 지시를 첫 항목에만 적용한다 | [문자 그대로의 지시 이행](#문자-그대로의-지시-이행) |
| 서브에이전트를 너무 적게 또는 불필요하게 띄운다 | [서브에이전트 생성 조절](#서브에이전트-생성-조절) |
| 디자인이 늘 크림색 배경·세리프·테라코타로 나온다 | [디자인·프런트엔드 기본값](#디자인프런트엔드-기본값) |
| 대화형 코딩 세션에서 토큰이 많이 든다 | [대화형 코딩 제품](#대화형-코딩-제품) |
| 코드 리뷰 재현율이 이전 모델보다 낮게 나온다 | [코드 리뷰 하네스](#코드-리뷰-하네스) |

## API 계약

Opus 4.8은 Opus 4.7의 파괴적 변경을 그대로 이어받고, 4.7 대비 1M 컨텍스트 기본값과 대화 중 시스템 메시지가 더해졌습니다.

| 항목 | Opus 4.8 동작 |
|------|------|
| 사고 | `thinking` 생략 시 사고 없이 실행. 켜려면 `{"type": "adaptive"}`, 끄기는 `{"type": "disabled"}` 또는 생략. 수동 예산(`enabled` + `budget_tokens`)은 400 (4.7부터) |
| sampling | `temperature`·`top_p`·`top_k`를 기본값이 아닌 값으로 보내면 400 (4.7부터) |
| prefill | 마지막 assistant 턴 prefill은 400 (4.6부터). 형식은 구조화 출력, 서두 생략은 시스템 프롬프트로 |
| 강제 도구 사용 | `tool_choice` `any`·`tool` 허용 |
| 도구 사이 텍스트 | `text` 블록으로 반환 (Opus 5.5·Sonnet 5.5는 `thinking` 블록) |
| 대화 중 시스템 메시지 | 지원. 지시를 바꾸려고 대화 이력 전체를 다시 만들 필요 없이 캐시를 유지 |
| 컴퓨터 사용 | `computer_toolset_20260801`(Claude API·Google Cloud)과 이전 `computer_20251124` 모두 지원 |
| 토크나이저·이미지 | Opus 4.7에서 도입된 토크나이저와 고해상도 이미지 티어(긴 변 2576px, 이미지당 최대 4,784 토큰). 좌표는 실제 픽셀과 1:1 |
| 거절 | 실시간 사이버 안전장치(4.7부터). `stop_reason: "refusal"`과 `stop_details` 범주를 읽음 |

## 응답 길이

고정된 장황함 대신 작업이 얼마나 복잡하다고 판단하는지에 맞춰 길이를 정합니다. 단순 조회에는 짧게, 열린 분석에는 훨씬 길게 답합니다. 제품이 특정 길이나 문체에 기대고 있다면 프롬프트를 조정합니다. 장황함을 줄이는 예:

```text
Provide concise, focused responses. Skip non-essential context, and keep examples minimal.
```

과잉 설명처럼 특정한 종류의 장황함이 보이면 그것을 막는 지시를 더합니다. 적절한 간결함을 보여주는 긍정 예시가 "하지 마라"식 지시나 부정 예시보다 대체로 효과적입니다.

## effort와 사고 깊이

공식 권장 시작점은 코딩·에이전트 작업 `xhigh`, 지능이 중요한 작업 대부분은 최소 `high`입니다. API 기본값은 `high`이므로 코딩 작업에는 명시적으로 `xhigh`를 보내야 합니다. 공식 가이드는 effort가 이전 어떤 Opus보다 이 모델에서 중요할 가능성이 크니 업그레이드할 때 적극적으로 실험하라고 권합니다.

| 레벨 | 공식 설명 |
|------|------|
| `max` | 일부 작업에서 성능 이득이 있지만 토큰 증가 대비 수익이 줄고, 과잉 사고에 빠지기도 함. 지능이 많이 필요한 작업에서 시험 |
| `xhigh` | 대부분의 코딩·에이전트 작업에 가장 좋은 설정 |
| `high` | 토큰과 지능의 균형. 지능이 중요한 작업은 최소 이 레벨 |
| `medium` | 지능을 일부 내주고 토큰을 줄여야 하는 비용 민감 작업 |
| `low` | 짧고 범위가 정해진 작업, 지능이 중요하지 않은 지연 민감 워크로드 |

- **낮은 레벨을 엄격히 지킴**: `low`·`medium`에서는 요청한 범위 안에서만 일합니다. 중간 난도 작업을 `low`로 돌리면 덜 생각할 위험이 있습니다. 얕은 추론이 보이면 프롬프트로 우회하지 말고 effort를 `high`·`xhigh`로 올립니다. 지연 때문에 `low`를 유지해야 하면 아래를 더합니다.

```text
This task involves multistep reasoning. Think carefully through the problem before responding.
```

- **사고 빈도 조절**: 사고는 `thinking: {"type": "adaptive"}`를 보낼 때만 켜집니다. 켰을 때 크거나 복잡한 시스템 프롬프트에서 원하는 것보다 자주 생각하면 아래를 넣고 성능 변화를 측정합니다. 반대로 `medium`에서 덜 생각하면 첫 수단은 effort 상향입니다.

```text
Thinking adds latency and should only be used when it will meaningfully improve answer quality — typically for problems that require multistep reasoning. When in doubt, respond directly.
```

- **`max_tokens`**: `max`·`xhigh`에서는 서브에이전트와 도구 호출에 걸쳐 생각하고 행동할 여유를 줍니다. 64k 토큰에서 시작해 조정합니다.

## 도구 사용

도구 호출보다 추론을 선호하는 경향이 있고, 대부분의 경우 이쪽이 결과가 좋습니다. 도구 사용을 늘리려면 effort를 올립니다. 특히 지식 작업에서 효과가 있고, `high`·`xhigh`에서는 에이전트 검색과 코딩의 도구 사용이 크게 늘어납니다. 프롬프트로 언제 어떻게 도구를 쓰는지 지시해도 됩니다. 웹 검색 도구를 쓰지 않으면 왜, 어떻게 써야 하는지를 분명히 설명합니다.

## 진행 업데이트

긴 에이전트 작업 중 사용자에게 더 주기적이고 질 좋은 업데이트를 줍니다(4.7부터). "도구 호출 3번마다 진행 상황을 요약하라" 같은 강제 스캐폴딩을 넣어 두었다면 지워 봅니다. 업데이트의 길이나 내용이 맞지 않으면 어떤 모습이어야 하는지 프롬프트에 설명하고 예시를 줍니다.

## 문자 그대로의 지시 이행

특히 낮은 effort에서 프롬프트를 문자 그대로, 명시된 대로 해석합니다. 한 항목에 준 지시를 다른 항목으로 조용히 넓히지 않고, 하지 않은 요청을 추론하지 않습니다. 정밀하고 헛도는 일이 적어서, 세밀하게 조정한 API 프롬프트, 구조화 추출, 예측 가능한 동작이 필요한 파이프라인에서 대체로 더 좋습니다. 지시를 넓게 적용해야 하면 범위를 명시합니다(예: "Apply this formatting to every section, not just the first one").

## 어조와 문체

직설적이고 의견이 분명한 문체로 기울고, 맞장구로 시작하는 표현이 적으며, 이모지를 아껴 씁니다. 특정 목소리에 기대는 제품은 새 기준선에서 문체 프롬프트를 다시 평가합니다. 더 따뜻하고 대화적인 목소리를 원하면 아래를 더합니다.

```text
Use a warm, collaborative tone. Acknowledge the user's framing before answering.
```

## 서브에이전트 생성 조절

기본적으로 서브에이전트를 적게 띄웁니다. 프롬프트로 조절할 수 있으니 언제 서브에이전트가 바람직한지 명시적으로 안내합니다. 코딩 작업의 공식 예시:

```text
Do not spawn a subagent for work you can complete directly in a single response (e.g. refactoring a function you can already see).

Spawn multiple subagents in the same turn when fanning out across items or reading multiple files.
```

## 디자인·프런트엔드 기본값

디자인 감각이 좋지만 기본 하우스 스타일이 강합니다. 따뜻한 크림·오프화이트 배경(약 `#F4F1EA`), 세리프 디스플레이 서체(Georgia, Fraunces, Playfair), 이탤릭 단어 강조, 테라코타·앰버 강조색입니다. 에디토리얼, 숙박, 포트폴리오에는 어울리지만 대시보드, 개발 도구, 핀테크, 의료, 기업용 앱에는 어색합니다. 슬라이드와 웹 UI 모두에 나타납니다.

이 기본값은 끈질깁니다. "크림색 쓰지 마", "깔끔하고 미니멀하게" 같은 일반 지시는 다른 고정 팔레트로 옮겨 갈 뿐입니다. 안정적으로 통하는 방법은 둘입니다.

1. **구체적인 대안을 명세합니다.** 명시적 명세는 정확히 따릅니다. 공식 예시는 색상 hex 5개, 모서리 반경, 서체, 섹션 구성, hover 전환까지 적은 랜딩 페이지 명세입니다([원문](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prompting-claude-opus-4-8#design-and-frontend-defaults)).
2. **만들기 전에 선택지를 제안하게 합니다.** 기본값을 깨고 사용자에게 통제권을 줍니다. 디자인 다양성을 `temperature`에 기대던 통합은 이 방법으로 바꿉니다.

```text
Before building, propose 4 distinct visual directions tailored to this brief (each as: bg hex / accent hex / typeface — one-line rationale). Ask the user to pick one, then implement only that direction.
```

이전 모델보다 짧은 프런트엔드 프롬프트로도 이른바 "AI slop" 미감을 피합니다. 예전에 권하던 [frontend-design skill](https://github.com/anthropics/claude-code/blob/main/plugins/frontend-design/skills/frontend-design/SKILL.md)의 긴 스니펫 대신, 위 방법과 함께 아래 짧은 지시면 충분합니다.

```text
<frontend_aesthetics>
NEVER use generic AI-generated aesthetics like overused font families (Inter, Roboto, Arial, system fonts), cliched color schemes (particularly purple gradients on white or dark backgrounds), predictable layouts and component patterns, and cookie-cutter design that lacks context-specific character. Use unique fonts, cohesive colors and themes, and animations for effects and micro-interactions.
</frontend_aesthetics>
```

## 대화형 코딩 제품

사용자 턴이 하나인 자율·비동기 코딩 에이전트보다 사용자 턴이 여럿인 대화형·동기 코딩 에이전트에서 토큰을 더 씁니다. 주로 사용자 턴 뒤에 더 많이 추론하기 때문입니다. 긴 대화형 세션의 일관성, 지시 이행, 코딩 능력이 좋아지는 대신 토큰이 늘어납니다. 성능과 토큰 효율을 함께 높이려면 effort를 `xhigh`나 `high`로 두고, 자동 모드 같은 자율 기능을 더하고, 사용자에게 요구하는 상호작용 횟수를 줄입니다. 상호작용을 줄일 때는 작업, 의도, 관련 제약을 첫 사용자 턴에 미리 명세합니다. 이전 모델보다 자율적이라 이 사용 패턴에서 성능이 가장 잘 나옵니다.

## 코드 리뷰 하네스

이전 모델보다 버그를 의미 있게 잘 찾고, 내부 평가에서 재현율과 정밀도가 모두 높습니다. 그런데 이전 모델에 맞춘 리뷰 하네스에서는 처음에 재현율이 낮게 나올 수 있습니다. "심각한 문제만 보고하라", "보수적으로 하라", "사소한 지적은 하지 마라" 같은 지시를 이전 모델보다 충실히 따라서, 똑같이 깊이 조사하고 버그를 찾은 뒤에도 기준 미달이라 판단한 발견은 보고하지 않기 때문입니다. 공식 권장 문구:

```text
Report every issue you find, including ones you are uncertain about or consider low-severity. Do not filter for importance or confidence at this stage - a separate verification step will do that. Your goal here is coverage: it is better to surface a finding that later gets filtered out than to silently drop a real bug. For each finding, include your confidence level and an estimated severity so a downstream filter can rank them.
```

- 실제 두 번째 단계가 없어도 쓸 수 있지만, 확신도 필터링을 발견 단계 밖으로 빼면 대개 도움이 됩니다. 하네스에 검증·중복 제거·순위 단계가 있으면 발견 단계의 일은 필터링이 아니라 망라라고 명시합니다.
- 한 번에 스스로 거르게 하려면 "중요한" 같은 질적 표현 대신 기준을 구체적으로 씁니다. 예: "report any bugs that could cause incorrect behavior, a test failure, or a misleading result; only omit nits like pure style or naming preferences."
- 평가 세트 일부로 프롬프트를 반복 조정해 재현율이나 F1 향상을 확인합니다.

## 컴퓨터 사용

`computer_toolset_20260801` 툴셋(Claude API·Google Cloud)과 이전 `computer_20251124` 도구를 모두 지원하고, Claude API·Google Cloud에서는 브라우저 사용 도구(`browser_toolset_20260801`)도 지원합니다. 해상도는 최대 2576px·3.75MP까지 동작하며, 내부 테스트에서는 1080p 이미지가 성능과 비용의 균형이 좋았습니다. 비용에 특히 민감하면 720p나 1366×768이 성능이 강하면서 더 저렴한 선택지입니다.

## 요약

| 축 | 처방 |
|------|------|
| **출발점** | Opus 4.7 프롬프트 그대로. 조정은 증상이 있을 때만 |
| **사고** | 기본 꺼짐. `{"type": "adaptive"}`로 켬. 예산·sampling·prefill은 400 |
| **effort** | 코딩·에이전트 `xhigh`(API 기본 `high`라 명시 필요), 지능 중요 작업 최소 `high`, `xhigh`·`max`는 `max_tokens` 64k부터 |
| **도구·서브에이전트** | 추론을 선호하고 서브에이전트를 적게 띄움 → effort 상향과 명시적 안내 |
| **문체·디자인** | 직설적 문체, 크림·세리프·테라코타 하우스 스타일 → 구체적 명세나 선택지 제안 |
| **리뷰 하네스** | 걸러서 보고하라는 지시를 충실히 따름 → 발견 단계는 망라로 |
