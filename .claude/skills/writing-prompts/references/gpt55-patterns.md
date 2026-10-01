# GPT-5.5 프롬프트 패턴

대상 모델: `gpt-5.5` (기본 스냅샷 `gpt-5.5-2026-04-23`). `gpt-5.5-pro` 등 이름이 비슷한 별도 모델에는 이 계약을 넓히지 않는다.

## 목차
- [작성 체크리스트](#작성-체크리스트)
- [개요 (5.4 → 5.5 핵심 변화)](#개요-54--55-핵심-변화)
- [1. Outcome-First Prompting (신규)](#1-outcome-first-prompting-신규)
- [2. Personality + Collaboration Style 분리 (신규)](#2-personality--collaboration-style-분리-신규)
- [3. Retrieval Budget (신규/강조)](#3-retrieval-budget-신규강조)
- [4. Tool Validation (강조)](#4-tool-validation-강조)
- [5. Markdown 절제 정책 (강조)](#5-markdown-절제-정책-강조)
- [6. Structured Outputs 권장](#6-structured-outputs-권장)
- [7. Image Detail 기본값 변경](#7-image-detail-기본값-변경)
- [8. Long-Task User-Visible Updates (신규)](#8-long-task-user-visible-updates-신규)
- [9. 5.4 패턴 호환](#9-54-패턴-호환)
- [10. 마이그레이션 전략 (5.4 → 5.5)](#10-마이그레이션-전략-54--55)
- [참고](#참고)


공식 안내는 GPT-5.5를 5.2·5.4의 단순 교체가 아니라 **새로 맞춰야 할 모델 패밀리**로 다루라고 한다("treat it as a new model family to tune for, not a drop-in replacement"). 제품 계약을 보존하는 가장 작은 프롬프트로 새 기준선을 만들고, effort·verbosity·도구 설명·출력 형식을 대표 사례로 조정한다.
effort를 올리기 전에 관찰된 실패(조기 종료, 누락, 검증 부재)에 필요한 지시만 보완하고 비교한다. 아래 블록을 한꺼번에 넣지 않는다.

---

## 작성 체크리스트

- [ ] **모델 ID·API 확정**: `gpt-5.5`. 추론·도구·다중 턴은 Responses API. Chat Completions의 도구 호출은 `reasoning_effort: "none"`일 때만 된다(GPT-5.4부터)
- [ ] **결과 중심**: 기대 결과, 성공 기준, 허용되는 부작용, 증거 규칙, 출력 형태를 쓴다. 정확한 경로가 제품 요구일 때만 단계를 지시한다
- [ ] **최소 프롬프트**: 옛 프롬프트 스택을 통째로 옮기지 않는다
- [ ] **절대 규칙**: `ALWAYS`·`NEVER`·`must`·`only`는 진짜 불변 조건(안전 규칙, 필수 출력 필드, 절대 하면 안 되는 행동)에만. 검색·질문·도구 사용·반복 여부 같은 판단은 결정 규칙으로
- [ ] **중단 조건**: 도구·검색을 쓰면 중단 조건과 검색 예산을 명시
- [ ] **effort**: `medium`(기본)에서 시작. 지연이 중요하면 `none`보다 `low`를 먼저 평가, `high`·`xhigh`는 평가로 품질 이득이 확인될 때만
- [ ] **verbosity**: API 기본 `medium`, 짧은 응답이 필요하면 `text.verbosity: "low"`
- [ ] **출력 스키마**: 가능하면 프롬프트에서 빼고 Structured Outputs로(Responses는 `text.format`)
- [ ] **personality·collaboration style**: 고객 대면·대화형 제품이면 둘 다 짧게 정의. 목표·성공 기준을 대신하지 않음
- [ ] **검증**: 가장 관련 있는 검증을 고르게 하고, 실행하지 못하면 이유와 차선책을 밝히게
- [ ] **날짜**: 현재 UTC 날짜를 알리는 중복 지시는 생략. 업무 시간대, 정책 발효일, 사용자 현지 날짜는 명시
- [ ] **캐싱**: 정적 내용은 앞, 동적 내용은 뒤. 공유 접두부에는 고정 `prompt_cache_key`
- [ ] **상태 관리**: 응답 항목을 직접 재생하면 `phase` 값을 그대로 보존

---

## 개요 (5.4 → 5.5 핵심 변화)

| 항목 | 5.4까지 | 5.5 |
|------|---------|------|
| 프롬프트 철학 | Output contract + 단계별 절차 | **Outcome-first** (목표·성공 기준 정의) |
| Reasoning effort 기본 | 작업 형태별 매트릭스 | **`medium` 권장 출발점**, 많은 워크로드는 `low` |
| Verbosity | 별도 권장 없음 | API 기본 `medium`, **간결한 응답에는 `low`가 나은 출발점** |
| Personality | 통합 블록 | **Personality + Collaboration Style 분리** |
| Markdown | 절제 권고 | **일반 대화·설명은 평문 단락 기본** (형식 지시에 잘 따름) |
| Retrieval | research_mode 3-pass | **명시적 stopping conditions** |
| 출력 스키마 | 프롬프트 + 검증 | **가능하면 Structured Outputs** |
| 이미지 `detail` 미지정·`auto` | `high` 동작 | **`original` 동작** (computer use 향상) |
| 마이그레이션 | 단순 교체 | **검증 없는 단순 교체를 가정하지 않음**, 최소 프롬프트로 새 기준선 |

> 상세 가이드: [`reference/openai-prompt-guide/gpt-5.5-prompt-guide.md`](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md)

---

## 1. Outcome-First Prompting (신규)

5.5의 가장 큰 변화. **절차를 미세 명령하는 대신 목표·성공 기준·제약을 정의**하고 경로 선택은 모델에 맡긴다.

> "GPT-5.5 works best when prompts define the outcome and leave room for the model to choose an efficient solution path."

### 시스템 프롬프트 권장 구조

```
Role → Personality → Goal → Success criteria →
Constraints → Output shape → Stop rules
```

각 섹션은 짧게. **"Add detail only where it changes behavior."**

### 예시

```xml
<goal>
Resolve the customer's issue end to end. Use available tools when they
materially improve correctness or grounding.
</goal>

<success_criteria>
- The user's stated problem is fixed or a clear blocker is reported.
- Any actions taken are reversible or have been confirmed by the user.
- Output ends with a 1-2 sentence summary of what was done and what
  remains optional.
</success_criteria>

<stop_rules>
- Stop when success criteria are met.
- Resolve the user query in the fewest useful tool loops, but do not
  let loop minimization outrank correctness.
</stop_rules>
```

### Anti-Pattern

- ❌ 단계별 명령: "First inspect A. Then inspect B. Then write..." (모든 단계가 정말 필요할 때만)
- ❌ 절대 규칙 남용: `ALWAYS do X. NEVER do Y. ALWAYS verify Z.`
- ❌ 옛 프롬프트 통째 이월

`ALWAYS`·`NEVER`·`must`·`only`는 진짜 불변 조건에 쓴다. 공식 예시는 안전 규칙, 필수 출력 필드, 절대 일어나면 안 되는 행동이다. 언제 검색할지, 언제 되물을지, 도구를 쓸지, 계속 반복할지 같은 판단에는 결정 규칙을 쓴다.

---

## 2. Personality + Collaboration Style 분리 (신규)

**personality**(어떻게 들리는가)와 **collaboration style**(어떻게 일하는가)을 명시적으로 분리. 공식 권고는 "Keep both short."이고, 어느 쪽도 목표·성공 기준·도구 규칙·중단 조건을 대신하지 않는다. 기본 문체가 효율적·직접적이므로 고객 대면·지원·코칭·대화형 제품에서 특히 필요하다.

### Personality 4종 (Cookbook prompt_personalities)

| 패턴 | 사용처 | 핵심 표현 |
|------|--------|----------|
| **Professional** | 비즈니스 커뮤니케이션, 엔터프라이즈 | "focused, formal, and exacting" |
| **Efficient** | 개발자 도구, 자동화, CLI | "direct, complete, and easy to parse... DO NOT add extra features" |
| **Fact-Based** | 디버깅, 위험 분석, 리서치 | "Do not guess or fill gaps with fabricated details" |
| **Exploratory** | 학습, 기술 지식 공유 | "Aim to make learning enjoyable and useful" |

### 예시 — Personality (Steady Task-Focused, 공식 예시 4문단 중 1·3문단)

```text
# Personality
You are a capable collaborator: approachable, steady, and direct. Assume the user is competent and acting in good faith, and respond with patience, respect, and practical helpfulness.

Stay concise without becoming curt. Give enough context for the user to understand and trust the answer, then stop. Use examples, comparisons, or simple analogies when they make the point easier to grasp. When correcting the user or disagreeing, be candid but constructive. When an error is pointed out, acknowledge it plainly and focus on fixing it.
```

공식 예시의 2문단(되묻기보다 진행)과 4문단(어조 맞추기, 이모지 자제)은 [풀 가이드 §4.2](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md#42-personality-블록-예시-steady-task-focused)에 있다. 공식 문서에는 표현력 있는 협업형 예시도 있다.

### 예시 — Collaboration Style (레포 적용 예시)

```xml
<collaboration_style>
- Ask a clarifying question only when the next step is genuinely
  ambiguous and proceeding would waste effort or cause harm.
- For everything else, choose the most reasonable interpretation,
  state your assumption in one line, and proceed.
- Run the most relevant validation available before declaring done.
- Surface blockers early; do not silently swap to a worse approach.
</collaboration_style>
```

### Anti-Pattern

- ❌ Personality에 task logic / domain rules 혼합
- ❌ 과도한 친근함이나 헤징(hedging)으로 신뢰성 훼손
- ❌ Personality를 요청된 artifact(이메일·코드·메모)에 강제 적용

---

## 3. Retrieval Budget (신규/강조)

너무 많이 검색하거나 너무 일찍 멈추는 양극단을 모두 피하기 위한 **명시적 stopping conditions**. 공식 문서는 검색 예산을 "검색의 중단 규칙"으로 설명한다(아래는 공식 예시 원문).

```text
For ordinary Q&A, start with one broad search using short, discriminative keywords. If the top results contain enough citable support for the core request, answer from those results instead of searching again.

Make another retrieval call only when:
- The top results do not answer the core question.
- A required fact, parameter, owner, date, ID, or source is missing.
- The user asked for exhaustive coverage, a comparison, or a comprehensive list.
- A specific document, URL, email, meeting, record, or code artifact must be read.
- The answer would otherwise contain an important unsupported factual claim.

Do not search again to improve phrasing, add examples, cite nonessential details, or support wording that can safely be made more generic.
```

**원칙**: "Resolve the user query in the fewest useful tool loops, but do not let loop minimization outrank correctness, accessible fallback evidence, calculations, or required citation tags for factual claims."

증거가 없다는 사실을 곧바로 "아니다"라는 사실 판단으로 바꾸지 않게 한다("Absence of evidence shouldn't automatically become a factual 'no.'"). 증거가 부족할 때의 동작도 정한다: "Use the minimum evidence sufficient to answer correctly, cite it precisely, then stop."

---

## 4. Tool Validation (강조)

검증이 가능한 작업이면 모델이 자기 결과를 도구로 확인할 수 있게 한다("Give GPT-5.5 access to tools that let it check outputs when validation is possible."). 모든 검사를 매번 강제하지 않고, 변경과 관련된 검증을 고르게 한다. 아래는 공식 예시 원문이다.

코딩 에이전트:

```text
After making changes, run the most relevant validation available:
- targeted unit tests for changed behavior
- type checks or lint checks when applicable
- build checks for affected packages
- a minimal smoke test when full validation is too expensive

If validation cannot be run, explain why and describe the next best check.
```

시각 산출물:

```text
Render the artifact before finalizing. Inspect the rendered output for layout, clipping, spacing, missing content, and visual consistency. Revise until the rendered output matches the requirements.
```

---

## 5. Markdown 절제 정책 (강조)

5.5는 출력 형식·구조 지시를 잘 따른다("highly steerable on output format and structure"). 그 통제력은 이해나 제품 적합성을 높일 때 쓰고, 무거운 구조는 이해를 돕거나 UI가 안정된 산출물을 요구할 때만 쓴다. 아래는 공식 예시 원문이다.

```text
Let formatting serve comprehension. Use plain paragraphs as the default format for normal conversation, explanations, reports, documentation, and technical writeups. Keep the presentation clean and readable without making the structure feel heavier than the content.

Use headers, bold text, bullets, and numbered lists sparingly. Reach for them when the user requests them, when the answer needs clear comparison or ranking, or when the information would be harder to scan as prose. Otherwise, favor short paragraphs and natural transitions.

Respect formatting preferences from the user. If they ask for a terse answer, minimal formatting, no bullets, no headers, or a specific structure, follow that preference unless there is a strong reason not to.
```

편집·요약·고객 메시지는 문체를 고치라고 하기 전에 보존할 것을 먼저 말한다: "Preserve the requested artifact, length, structure, and genre first. Quietly improve clarity, flow, and correctness. Do not add new claims, extra sections, or a more promotional tone unless explicitly requested."

---

## 6. Structured Outputs 권장

공식 권고는 **가능하면 출력 스키마 정의를 프롬프트에서 빼고 Structured Outputs를 쓰는 것**이다. Responses API는 `text.format`, Chat Completions는 `response_format`으로 지정한다.

```python
response = client.responses.create(
    model="gpt-5.5",
    text={
        "format": {
            "type": "json_schema",
            "name": "<schema_name>",
            "strict": True,
            "schema": { ... },
        }
    },
    input=[ ... ],
)
```

지원하는 스키마로 정상 완료된 출력은 형식이 강제된다. 다만 "Structured Outputs can still contain mistakes."이므로 거절과 불완전 응답(최대 토큰 도달)을 따로 처리하고, 값의 의미와 업무 조건은 별도로 검증한다. 프롬프트의 중복 스키마 설명은 줄일 수 있지만 총 입력 토큰 절약을 보장하지는 않는다.

프롬프트의 보조 컨트롤이 필요한 경우:

```xml
<structured_output_contract>
- Output only the requested format.
- Do not add prose or markdown fences unless they were requested.
- Validate that parentheses and brackets are balanced.
- Do not invent tables or fields.
- If required schema information is missing, ask for it or return an
  explicit error object.
</structured_output_contract>
```

---

## 7. Image Detail 기본값 변경

`detail`은 최상위 파라미터가 아니라 **이미지 입력 항목마다** 지정한다(`{"type": "input_image", "image_url": ..., "detail": "high"}`). 생략하면 `auto`이고, 5.5에서는 `auto`가 `original`과 같은 크기 처리로 바뀌었다(computer use 정확도 향상 목적).

| 값 | 5.5 크기 처리 | 사용처 |
|-----|--------|-----|
| `original` (미지정·`auto` 포함) | 최대 10,240,000픽셀 또는 한 변 6,000픽셀까지 축소 없이 | 컴퓨터 사용, OCR, 좌표가 중요한 작업, 대형·밀집 이미지 |
| `high` | 최대 2,500,000픽셀 또는 한 변 2,048픽셀까지 축소 없이 | 원본 좌표가 필요 없는 표준 고충실도 이해 |
| `low` | 한 변 512픽셀을 넘으면 이전 모델보다 강하게 축소 | 대략적인 이해, 컨텍스트 효율 |

> 일반 차트·문서에서 `high`나 `low`로 낮출지는 그 이미지에서 품질과 토큰을 비교해 정한다. 공식 문서는 `low`가 항상 `high`보다 토큰을 적게 쓰지는 않는다고 적는다.

---

## 8. Long-Task User-Visible Updates (신규)

스트리밍 앱에서 5.5는 보이는 텍스트를 내기 전에 추론·계획·도구 준비에 시간을 쓸 수 있다. 여러 단계이거나 도구 호출이 필요하거나 장기 에이전트 작업이면, 요청을 확인하고 첫 단계를 밝히는 짧은 서두(preamble)로 시작하게 한다. 공식 예시 원문:

```text
Before any tool calls for a multi-step task, send a short user-visible update that acknowledges the request and states the first step. Keep it to one or two sentences.
```

메시지 단계(phase)를 따로 노출하는 코딩 에이전트는 더 명시적으로 쓸 수 있다: "You must always start with an intermediary update before any content in the analysis channel if the task will require calling tools. The user update should acknowledge the request and explain your first step."

### 수동 이력 재생과 `phase`

`previous_response_id`를 쓰면 API가 이전 assistant 상태를 자동으로 보존한다. 애플리케이션이 assistant 출력 항목을 직접 다음 요청에 재생하면 각 항목의 원래 `phase` 값을 그대로 돌려보낸다. 중간 진행 업데이트는 `phase: "commentary"`, 완료된 답은 `phase: "final_answer"`이고, user 메시지에는 `phase`를 넣지 않는다. 서두, 반복 도구 호출, 중간 업데이트 뒤의 최종 답이 섞인 응답에서 특히 중요하다.

---

## 9. 5.4 패턴 호환

5.4 세대의 다음 블록은 5.5에서도 쓸 수 있다. 오늘 재확인한 5.5 공식 권장문이 아니라 이전 세대 적용 예시이므로, 관찰된 실패에 맞는 것만 골라 **outcome-first 프레임 안에 배치**한다(3단계 조사 절차나 검증 블록을 모든 작업에 자동으로 넣지 않는다):

- `<output_contract>` / `<verbosity_controls>`
- `<default_follow_through_policy>`
- `<instruction_priority>`
- `<tool_persistence_rules>` / `<dependency_checks>`
- `<parallel_tool_calling>`
- `<completeness_contract>`
- `<empty_result_recovery>`
- `<verification_loop>` / `<missing_context_gating>` / `<action_safety>`
- `<citation_rules>` / `<grounding_rules>` / `<research_mode>`
- `<autonomy_and_persistence>` / `<terminal_tool_hygiene>`

블록 원문은 [GPT-5.5 풀 가이드 §6~§12](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md#6-core-prompt-patterns-54에서-유지-outcome-first-프레임-안에-배치) 참조.

5.5에서 새로 추가/강조된 것: §1~§8.

---

## 10. 마이그레이션 전략 (5.4 → 5.5)

> ⚠️ **검증 없는 단순 교체를 가정하지 않는다**. "treat it as a new model family to tune for, not a drop-in replacement for `gpt-5.2` or `gpt-5.4`."
> 옛 프롬프트의 효과성은 5.5가 보장하지 않는다. 제품 계약을 보존한 최소 프롬프트로 기준선을 평가한다.

### 시작 설정 예시 (평가로 조정)

| 현재 | GPT-5.5 시작 |
|------|-------------|
| `gpt-5.4` (일반) | `medium` effort, 짧은 응답이면 `low` verbosity, 최소 프롬프트로 새 기준선 |
| `gpt-5.4` (코딩 에이전트) | `medium` effort 유지, outcome-first 재구조화 + 관련 검증 지시 |
| `gpt-5.4` (리서치) | `medium` + retrieval_budget 추가 + 단계별 절차 → outcome 재작성 |
| `gpt-5.4` (장기 에이전트) | `medium`/`high` + tool persistence + completeness, xhigh는 eval 후 |

### 체크리스트

1. [ ] 모델명 `gpt-5.5`로 변경
2. [ ] **최소 프롬프트로 새 기준선** (옛 프롬프트를 통째로 옮기지 않음)
3. [ ] `reasoning.effort = "medium"` 출발점
4. [ ] `text.verbosity = "low"` 평가
5. [ ] 출력 스키마 → Structured Outputs로 이전 (Responses는 `text.format`)
6. [ ] 단계별 절차 → outcome-first goal/success_criteria 재작성
7. [ ] Personality + Collaboration Style 분리 (둘 다 짧게)
8. [ ] `<retrieval_budget>` 추가 (도구 사용 시)
9. [ ] 관련 검증 지시 추가 (검증 가능한 작업)
10. [ ] 형식 지시 정리 (평문 단락 기본, 필요한 구조만)
11. [ ] 현재 UTC 날짜를 알리는 중복 지시만 제거 (업무 시간대·정책 발효일·사용자 현지 날짜는 유지)
12. [ ] 이미지 `detail` 미지정·`auto`가 `original` 동작으로 바뀐 영향 평가, 필요하면 항목별로 `high` 지정
13. [ ] 도구 중심·장기 워크플로: `phase`·서두·assistant 항목 재생 처리 확인. Chat Completions 도구 호출은 `reasoning_effort: "none"`일 때만

### 자동 마이그레이션 (Codex CLI)

```
$openai-docs migrate this project to gpt-5.5
```

OpenAI Docs Skill이 프로젝트 프롬프트 스택을 5.5 권장에 맞게 자동 변환.

---

## 참고

- [GPT-5.5 Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-5.5-prompt-guide.md) — 전체 가이드 + 외부 노하우
- [Using GPT-5.5 (공식, 5.5 전용 원문)](https://developers.openai.com/api/docs/guides/latest-model/gpt-5.5.md) — 버전 없는 `latest-model`·`prompt-guidance` 주소는 최신 모델 문서로 바뀌므로 이 주소를 쓴다
- [GPT-5.5 모델 페이지 (공식)](https://developers.openai.com/api/docs/models/gpt-5.5)
- [Structured Outputs (공식)](https://developers.openai.com/api/docs/guides/structured-outputs)
- [Prompt Personalities (Cookbook)](https://developers.openai.com/cookbook/examples/gpt-5/prompt_personalities)
- [Simon Willison — GPT-5.5 prompting guide (2026-04-25)](https://simonwillison.net/2026/Apr/25/gpt-5-5-prompting-guide/)
