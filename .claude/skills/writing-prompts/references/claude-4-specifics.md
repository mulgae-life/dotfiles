# Claude 4.x (Opus 4.8 · Sonnet 4.6 · Haiku 4.5) 특화 기법

대상 모델: `claude-opus-4-8` · `claude-sonnet-4-6` · `claude-haiku-4-5` (스냅샷 `claude-haiku-4-5-20251001`)

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [모델별 계약](#모델별-계약)
- [공통 원칙](#공통-원칙)
- [Opus 4.8](#opus-48)
- [Sonnet 4.6](#sonnet-46)
- [Haiku 4.5](#haiku-45)
- [요약](#요약)

> 세 모델은 사고 방식이 모두 다르다. Opus 4.8은 적응형 사고만(기본 꺼짐), Sonnet 4.6은 적응형과 폐기 예정인 확장 사고, Haiku 4.5는 확장 사고만 쓰고 effort를 지원하지 않는다. 같은 체크리스트로 묶어 처리하지 않는다. Claude 5 세대 처방(de-prescribe, 검증 지시 삭제, `between_tools`, append-only 이력)은 대상 모델 문서가 권하지 않으면 넣지 않는다 → Claude 5 세대는 [claude-5-specifics.md](claude-5-specifics.md).
>
> 근거: Opus 4.8은 공식 전용 프롬프팅 문서가 있다 → [Opus 4.8 풀 가이드](../../../../reference/claude-prompt-guide/claude-opus-4-8-prompt-guide.md). Sonnet 4.6·Haiku 4.5는 전용 문서가 없어 공식 [Prompting best practices](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices)(현역 모델 공통), 모델 개요, 마이그레이션·effort·thinking 문서가 근거다. 모범 사례 문서는 특정 모델 이름이 붙은 기법을 "그 모델에서 측정된 것"으로 보고 다른 모델에는 평가 후 적용하라고 한다.

---

## 작성 체크리스트

**공통**
- [ ] **명시적 지시**: 원하는 동작을 구체적으로 쓴다. 기본 이상의 범위·기능을 원하면 수식어로 명시한다("Include as many relevant features and interactions as possible")
- [ ] **실행과 제안 구분**: "Can you suggest some changes..."는 제안만 할 수 있다 → 실행을 원하면 "Change this function..."처럼 동사로 지시
- [ ] **이유 제공**: 규칙에 "왜"를 붙인다
- [ ] **예시 점검**: 세부까지 따라 하므로 예시가 원하는 동작과 정확히 맞는지 확인
- [ ] **강조 수위**: "CRITICAL: You MUST use this tool" 같은 공격적 표현 대신 "Use this tool when..." (Opus 4.5·4.6에서 측정된 과잉 반응. 4.8·Sonnet 4.6은 평가 후 적용)
- [ ] **출력 형식**: "하지 마라"보다 원하는 형식을 긍정형으로("Your response should be composed of smoothly flowing prose paragraphs.")
- [ ] **긴 자료 배치**: 긴 문서는 위, 질문은 끝 → [long-context.md](long-context.md)

**모델별** (대상 모델 행만)
- [ ] **Opus 4.8**: prefill·`budget_tokens`·기본값이 아닌 sampling은 400. 사고는 `thinking: {type: "adaptive"}`를 보내야 켜짐. 코딩·에이전트는 effort `xhigh`를 명시(API 기본은 `high`). 지시를 문자 그대로 적용하므로 넓게 적용할 지시는 범위 명시
- [ ] **Sonnet 4.6**: prefill 400. 사고는 적응형 권장(`enabled` + `budget_tokens`는 폐기 예정이지만 동작). effort는 `low`·`medium`·`high`·`max`(`xhigh` 없음), 기본 `high`지만 공식 권장 기본은 `medium` → 값을 명시. sampling은 사고를 끈 요청에서만 자유롭게 쓴다(사고 중에는 `temperature`·`top_k` 불가, `top_p`는 0.95~1)
- [ ] **Haiku 4.5**: effort 미지원 → 사고량은 `thinking: {type: "enabled", budget_tokens: N}`(`adaptive`는 400). 사고를 켜면 prefill·강제 `tool_choice`를 쓸 수 없고 `temperature`·`top_k`도 막힌다. `temperature`와 `top_p`는 둘 중 하나만(둘 다 400). 컨텍스트 200K·출력 64K

---

## 모델별 계약

| 항목 | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 |
|------|---------|-----------|-----------|
| **상태·은퇴** | Active (legacy), 2027-05-28 이후 | Active (legacy), 2027-02-17 이후 | Active (latest), **2026-10-15 이후** |
| **현행 후속** | Opus 5.5 | Sonnet 5.5 | 없음 (현행 Haiku) |
| **컨텍스트/출력** | 1M / 128K | 1M / 128K | 200K / 64K |
| **가격 (MTok)** | $5 / $25 | $3 / $15 | $1 / $5 |
| **지식 컷오프** | 2026-01 | 2025-08 | 2025-02 |
| **사고** | 적응형만, 기본 꺼짐. `enabled` 400 | 적응형 + 확장(폐기 예정), 기본 꺼짐 | 확장만. `adaptive` 400 |
| **effort** | `low`~`max` 5단계, 기본 `high` | `low`·`medium`·`high`·`max`, 기본 `high` | 미지원 |
| **sampling** | 기본값이 아닌 값 400 | 사고를 끈 요청에서 허용. 사고 중에는 `temperature`·`top_k` 불가, `top_p`는 0.95~1만 | 사고를 끈 요청에서 허용. 사고 중 제약은 Sonnet 4.6과 같음 (`temperature`·`top_p` 동시 지정은 항상 400) |
| **prefill** | 400 | 400 | 사고를 끈 요청에서만 |
| **강제 `tool_choice`** | 허용 | 허용 (`enabled` 사고와는 불가) | 사고를 끈 요청에서만 |
| **캐시 최소** | 1,024 토큰 | 1,024 토큰 | 4,096 토큰 |
| **이미지** | 고해상도 티어(긴 변 2576px) | 표준(1568px) | 표준(1568px) |
| **컨텍스트 인식** | — | 지원 | 지원 |

사고를 켠 요청에서 Sonnet 4.6·Haiku 4.5는 `temperature`·`top_k`를 받지 않고 `top_p`는 0.95~1만 받는다. 확장 사고(`enabled`)는 `tool_choice`가 `auto`·`none`일 때만 동작한다.

은퇴 날짜는 "이 날짜 이전에는 은퇴하지 않음"이라는 공식 약속이다. 특히 Haiku 4.5는 약속 기간이 곧 끝나므로 새 통합이면 모델 수명을 먼저 확인한다. 후속 모델로 바꾸는 판단은 사용자 몫이고, 프롬프트 작성 요청만으로 대상 모델을 바꾸지 않는다.

---

## 공통 원칙

[공식, Prompting best practices — 현역 모델 공통 절]

### 명시적 지시와 맥락

4.x 세대는 정확한 지시 이행에 맞춰 훈련됐다. "기대 이상"의 동작을 원하면 명시적으로 요청한다.

```text
Create an analytics dashboard. Include as many relevant features and interactions as possible. Go beyond the basics to create a fully-featured implementation.
```

규칙에는 이유를 붙인다. "NEVER use ellipses"보다 아래가 낫다.

```text
Your response will be read aloud by a text-to-speech engine, so never use ellipses since the text-to-speech engine will not know how to pronounce them.
```

### 행동 기본값 (실행 ↔ 신중)

제품이 원하는 쪽 하나만 넣는다.

```text
<default_to_action>
By default, implement changes rather than only suggesting them. If the user's intent is unclear, infer the most useful likely action and proceed, using tools to discover any missing details instead of guessing. Try to infer the user's intent about whether a tool call (e.g., file edit or read) is intended or not, and act accordingly.
</default_to_action>
```

```text
<do_not_act_before_instructions>
Do not jump into implementation or change files unless clearly instructed to make changes. When the user's intent is ambiguous, default to providing information, doing research, and providing recommendations rather than taking action. Only proceed with edits, modifications, or implementations when the user explicitly requests them.
</do_not_act_before_instructions>
```

### 출력 형식과 문체

- 4.x 이후 모델은 더 간결하고 직접적이며, 도구 호출 뒤 요약을 건너뛸 수 있다. 요약이 필요하면: "After completing a task that involves tool use, provide a quick summary of the work you've done."
- 형식은 긍정형으로 지시하고, 필요하면 XML 태그로 형식을 지정한다("Write the prose sections of your response in <smoothly_flowing_prose_paragraphs> tags.")

### 구모델용 지시 덜어내기

4.6 세대부터 더 주도적이라 이전 모델용 "더 철저히, 도구를 적극적으로" 지시가 과잉 반응을 부른다. "If in doubt, use [tool]" 같은 일괄 기본값은 "Use [tool] when it would enhance your understanding of the problem"처럼 조건부로 바꾸고, 그래도 과하면 effort를 낮춘다. 과잉 엔지니어링(추가 파일·불필요한 추상화)이 보이면 모범 사례 문서의 "Avoid over-engineering..." 스니펫을 쓴다(Opus 4.5·4.6에서 측정된 경향).

### 장기 작업과 컨텍스트 인식

Sonnet 4.6·Haiku 4.5는 남은 컨텍스트(토큰 예산)를 추적한다. 압축이나 외부 메모리 저장을 제공하는 하네스라면 이를 알려 조기 마무리를 막는다.

```text
Your context window will be automatically compacted as it approaches its limit, allowing you to continue working indefinitely from where you left off. Therefore, do not stop tasks early due to token budget concerns. As you approach your token budget limit, save your current progress and state to memory before the context window refreshes. Always be as persistent and autonomous as possible and complete tasks fully, even if the end of your budget is approaching. Never artificially stop any task early regardless of the context remaining.
```

여러 컨텍스트 창에 걸친 작업은 구조화된 상태 파일(예: `tests.json`)과 자유 형식 진행 메모(`progress.txt`)를 함께 두고, git으로 체크포인트를 남긴다.

### 사고가 꺼져 있을 때

Opus 4.8·Sonnet 4.6은 `thinking`을 생략하면 사고 없이 실행된다. 사고 없이 단계적 추론이 필요하면 `<thinking>`·`<answer>` 태그로 추론과 최종 답을 나누는 수동 CoT를 쓴다. 사고를 켠 경우에는 손으로 쓴 단계 계획보다 "think thoroughly" 같은 일반 지시가 대체로 낫다.

---

## Opus 4.8

공식 전용 문서가 있다. 영문 스니펫 원문과 상세는 [Opus 4.8 풀 가이드](../../../../reference/claude-prompt-guide/claude-opus-4-8-prompt-guide.md).

- **API 계약**: Opus 4.7의 파괴적 변경(sampling·`budget_tokens` 400)과 4.6의 prefill 400을 이어받는다. 1M 컨텍스트가 기본이고 대화 중 시스템 메시지를 지원한다. `disabled`·강제 `tool_choice`·`computer_20251124`를 받고 도구 사이 텍스트는 `text` 블록이다
- **effort**: 코딩·에이전트는 `xhigh`, 지능이 중요한 작업은 최소 `high`. 공식 문서는 effort가 이전 어떤 Opus보다 중요하다고 본다. `xhigh`·`max`는 `max_tokens` 64k부터
- **낮은 effort를 엄격히 지킴**: 얕은 추론은 프롬프트로 우회하지 말고 effort 상향. `low` 유지가 필요하면 "This task involves multistep reasoning. Think carefully through the problem before responding."
- **문자 그대로 이행**: 한 항목의 지시를 다른 항목으로 넓히지 않는다 → 범위 명시
- **도구·서브에이전트를 덜 씀**: 추론을 선호하고 서브에이전트를 적게 띄운다 → effort 상향과 명시적 안내(언제 띄우고 언제 직접 할지)
- **문체·디자인**: 직설적이고 이모지를 아낀다. 디자인은 크림 배경·세리프·테라코타 하우스 스타일이 강하다 → 구체적 명세나 4가지 방향 제안
- **리뷰 하네스**: "심각한 것만 보고" 지시를 충실히 따라 재현율이 낮아 보일 수 있다 → 발견 단계는 망라로

---

## Sonnet 4.6

전용 공식 프롬프팅 문서는 없다. 아래는 개요·effort·thinking·마이그레이션 문서와 모범 사례 문서에서 Sonnet 4.6이 명시된 항목이다.

- **effort를 명시한다**: 기본값은 `high`지만 공식 권장 기본은 `medium`이다("Medium effort (recommended default)"). 예기치 않은 지연을 피하려면 값을 명시한다

| effort | 공식 권장 용도 |
|--------|------|
| `low` | 대량·지연 민감 워크로드, 채팅과 비코딩 작업 |
| `medium` | 대부분의 애플리케이션. 에이전트 코딩, 도구 중심 워크플로, 코드 생성 |
| `high` | 속도·비용보다 품질이 중요한 복잡한 추론 |
| `max` | 토큰 지출 제약 없는 최고 능력 (`xhigh`는 Sonnet 4.6에 없음) |

- **사고**: `thinking`을 생략하면 사고 없이 실행된다. 켜려면 `{"type": "adaptive"}` + effort. `{"type": "enabled", "budget_tokens": N}`은 아직 동작하지만 폐기 예정이고, 사고 비용의 확실한 상한이 필요할 때만 쓴다
- **prefill 400**: 4.6 세대부터 마지막 assistant 턴 prefill을 받지 않는다. JSON 등 형식은 Structured Outputs, 서두 생략은 시스템 프롬프트 지시, 이어 쓰기는 user 메시지로
- **sampling**: 사고를 끈 요청에서는 `temperature`·`top_p`·`top_k`를 받는다(Sonnet 5부터 사고와 무관하게 400). 다양성을 sampling에 기대는 프롬프트는 Sonnet 5 이후로 옮길 때 다시 설계해야 한다
- **주도성**: 4.6 세대는 더 주도적이다. 이전 모델용 "더 철저히" 지시를 덜어낸다
- **후속 모델 대비**: Sonnet 5에서는 `thinking` 생략 시 사고가 켜지고 토큰이 약 30% 늘어난다. 4.6용 `max_tokens`가 그대로 맞는다고 가정하지 않는다

---

## Haiku 4.5

전용 공식 프롬프팅 문서는 없다. 근거는 개요·마이그레이션 문서와 모범 사례 문서다. 이 스킬이 다루는 Claude 모델 중 유일하게 effort와 적응형 사고를 쓰지 않고, prefill을 받는다.

- **사고**: 확장 사고만. `thinking: {type: "enabled", budget_tokens: N}`으로 켜고, `adaptive`는 400. 공식 마이그레이션 문서는 코딩·추론 작업에서 확장 사고를 켜면 성능이 크게 오른다고 권한다. 확장 사고는 프롬프트 캐시 효율에 영향을 준다
- **도구 사이 사고(interleaved thinking) 미지원**: 공식 thinking 문서 원문은 "Claude Haiku 4.5 does not support interleaved thinking."이다. 도구 결과마다 사고 블록이 이어진다고 가정하지 않는다
- **effort 미지원**: `output_config.effort`를 보내지 않는다. 사고량은 `budget_tokens`, 응답 길이는 프롬프트로 조절한다
- **sampling**: `temperature`와 `top_p` 중 하나만. 둘 다 보내면 400. 사고를 켜면 `temperature`·`top_k`는 쓸 수 없다
- **prefill**: 사고를 끈 요청에서만 마지막 assistant 턴을 미리 채울 수 있다. 다만 후속 모델(4.6 이후 전부)에서는 400이므로, 모델 교체 가능성이 있으면 Structured Outputs와 시스템 프롬프트 지시로 쓰는 편이 옮기기 쉽다

| 목적 | prefill 예 |
|------|-----------|
| JSON으로 바로 시작 | `{"role": "assistant", "content": "{"}` |
| XML 섹션으로 시작 | `{"role": "assistant", "content": "<analysis>"}` |
| 캐릭터 유지 | `{"role": "assistant", "content": "[캐릭터명]"}` |
| 서두 없이 목록부터 | `{"role": "assistant", "content": "1."}` |

prefill은 짧게 두고 공백으로 끝내지 않는다(끝 공백은 API 오류). 지시만으로 충분한 작업에는 쓰지 않는다.
- **문체**: "Claude 4 models have a more concise, direct communication style." 요약·설명이 더 필요하면 명시한다
- **컨텍스트**: 200K / 출력 64K. 컨텍스트 인식을 지원하므로 압축 하네스라면 [공통 원칙](#장기-작업과-컨텍스트-인식)의 스니펫을 쓴다
- **캐시 최소 4,096 토큰**: 짧은 시스템 프롬프트는 캐시되지 않는다
- **거절**: `stop_reason: "refusal"`을 처리한다

---

## 요약

| 축 | Opus 4.8 | Sonnet 4.6 | Haiku 4.5 |
|----|---------|-----------|-----------|
| **사고 켜기** | `adaptive` | `adaptive` (예산은 폐기 예정) | `enabled` + `budget_tokens` |
| **깊이 조절** | effort (코딩 `xhigh`) | effort (권장 `medium`) | `budget_tokens` |
| **형식 강제** | Structured Outputs | Structured Outputs | prefill(사고 끈 요청) 또는 Structured Outputs |
| **sampling** | 쓰지 않음 | 사고 끈 요청에서 사용 | 사고 끈 요청에서 둘 중 하나만 |
| **프롬프트 성향** | 문자 그대로, 범위 명시 | 주도적, 구모델용 강조 덜어내기 | 간결, 필요한 설명은 명시 |

**핵심**: 세 모델의 사고 설정을 섞지 않는다. 같은 "4.x"라도 사고 방식·effort·prefill 계약이 모두 다르다.
