# GPT-5.6 프롬프트 패턴

## 목차
- [개요 (5.5 → 5.6 핵심 변화)](#개요-55--56-핵심-변화)
- [1. 모델 티어 선택 (신규)](#1-모델-티어-선택-신규)
- [2. 간결 지시 → 우선순위 지시 (변경)](#2-간결-지시--우선순위-지시-변경)
- [3. Reasoning Effort 재튜닝 (변경)](#3-reasoning-effort-재튜닝-변경)
- [4. 신규 API 기능 프롬프팅](#4-신규-api-기능-프롬프팅)
- [5. 5.5 패턴 호환](#5-55-패턴-호환)
- [6. 마이그레이션 전략 (5.5 → 5.6)](#6-마이그레이션-전략-55--56)
- [참고](#참고)


GPT-5.6은 Sol/Terra/Luna **3티어 패밀리**. 프롬프팅 기조는 5.5를 계승한다 — 공식: "Prompting best practices for GPT-5.5 remains applicable to GPT-5.6."
5.5 때의 전면 재작성(fresh baseline)이 아니라 **기존 프롬프트를 유지한 채 설정을 재튜닝**하는 것이 핵심.

---

## 개요 (5.5 → 5.6 핵심 변화)

| 항목 | 5.5 | 5.6 |
|------|-----|------|
| 모델 라인업 | 단일 `gpt-5.5` | **Sol/Terra/Luna 3티어** + `gpt-5.6` 별칭(→Sol) |
| 마이그레이션 | fresh baseline 재구성 | **tuning pass** — 프롬프트 유지, 설정 재튜닝 |
| effort 출발점 | `medium` 권장 | **기존 effort baseline + 한 단계 낮춰 비교** |
| 간결 지시 | verbosity `low` 권장 | **"Be concise"류 일반 지시에 더 민감** → 우선순위 지시 |
| 응답 기본값 | plain prose 권장 | 기본이 이미 **compression 편향** |
| Reasoning 지속 | `previous_response_id` | **`reasoning.context`** (auto/current_turn/all_turns) |
| 고난도 모드 | - | **`reasoning.mode: "pro"`** |

> 상세 가이드: [`reference/openai-prompt-guide/gpt-5.6-prompt-guide.md`](../../../../reference/openai-prompt-guide/gpt-5.6-prompt-guide.md)

---

## 1. 모델 티어 선택 (신규)

| 모델 | 포지셔닝 | $/1M (in / out) |
|------|---------|------------------|
| `gpt-5.6-sol` | 플래그십 — 계획·검증·최종 종합 | $5.00 / $30.00 |
| `gpt-5.6-terra` | 균형 — 일상 생성 | $2.50 / $15.00 |
| `gpt-5.6-luna` | 고속·저가 — 대량 소작업, 서브태스크 | $1.00 / $6.00 |

- **티어 라우팅이 effort 튜닝보다 비용 레버리지가 크다** — 서브에이전트/파이프라인은 단계별로 티어를 나눠 배치
- reasoning 토큰 수가 티어·effort마다 달라 $/1M 단순 비교는 부정확 — 대표 작업으로 실측 비교

---

## 2. 간결 지시 → 우선순위 지시 (변경)

5.6은 기본 출력이 이미 짧고, 일반 간결 지시에 5.5보다 민감하다:

> "GPT-5.6 is more sensitive than GPT-5.5 to instructions such as 'Be concise,' 'Keep it short,' or 'Use minimal text.'"
> "An instruction such as 'Be concise. Use minimal text.' does more than remove filler—it can change how the model prioritizes the task."

```xml
<!-- ❌ 작업 우선순위를 왜곡할 수 있음 -->
Be concise. Keep it short. Use minimal text.

<!-- ✓ 무엇을 먼저 내놓을지 지시 -->
Lead with the conclusion. Include the evidence needed to support it,
any material caveat, and the next action.
```

- **카운트 가능한 구체 제약**("3문장 이내", "단어 수 상한 N")은 여전히 유효 — 금지 대상은 막연한 간결 지시
- `text.verbosity = "low"` 파라미터 출발점은 5.5와 동일하게 유지
- 전역 응답 템플릿 대신 **lightweight outline**

---

## 3. Reasoning Effort 재튜닝 (변경)

공식 마이그레이션 지침:

> "If you are migrating from GPT-5.5 or GPT-5.4, preserve your current reasoning effort as the baseline, then compare one level lower."

- 기본값 `medium` (standard·pro 공통). 신규 프로젝트는 medium 출발
- 5.6이 더 적은 토큰으로 같은 품질을 내는 경우가 많아 **하향 여지를 먼저 평가**
- 평가 축: task success, final-answer completeness, required evidence, total tokens, latency, cost
- `max` 레벨 신설 — 단 공식 문서 간 등재 불일치(2026-07-10 기준). 실호출 확인 후 채택
- effort를 올리기 전에 5.5 패턴(§5) 먼저 — 높은 effort는 지시 충돌·약한 정지 기준과 만나면 overthinking만 유발

---

## 4. 신규 API 기능 프롬프팅

### reasoning.mode: "pro"

> "Use pro mode when a marginal quality improvement materially affects the outcome."

토큰·지연 증가(과금은 표준 요율). 오답 비용이 큰 지점(최종 검증, 고위험 판단)에만 선별 적용.

### reasoning.context

`auto`(기본) / `current_turn` / `all_turns`. 장기 워크플로우에서 `all_turns`로 이전 턴 추론을 보존해 렌더링 컨텍스트 절약.

### Programmatic Tool Calling

호스티드 JS 런타임이 도구 오케스트레이션 (도구에 `allowed_callers` opt-in). 프롬프팅 포인트:

> "When both direct and programmatic calling are available, explicitly state: Which bounded stage should use Programmatic Tool Calling."
> "Evaluate the final user-visible answer, not only the program result."

### 명시적 프롬프트 캐싱

`prompt_cache_options.mode: "explicit"` + `ttl` (기존 `prompt_cache_retention` 대체). **write 1.25배 과금** — read 물량으로 회수되는지 확인.

---

## 5. 5.5 패턴 호환

5.5의 패턴 전부가 5.6에서 그대로 유효:

- Outcome-first (goal / success_criteria / stop_rules)
- Personality + Collaboration Style 분리
- `<retrieval_budget>` (stopping conditions)
- `<tool_validation>` (출력 검증을 도구로)
- Markdown 절제 (plain prose 기본 — 5.6은 기본값이 더 짧아짐)
- Structured Outputs API 강제
- 5.4 계열 패턴 (`<output_contract>`, `<completeness_contract>` 등)

상세는 [`gpt55-patterns.md`](./gpt55-patterns.md) 참조. 5.6에서 새로 추가/변경된 것: §1~§4.

---

## 6. 마이그레이션 전략 (5.5 → 5.6)

> "Treat migration as a tuning pass, not only a model-slug change."

### 체크리스트

1. [ ] 모델명 → `gpt-5.6-sol` (작업 특성 따라 terra/luna)
2. [ ] 기존 effort baseline 유지 → **한 단계 낮춘 값과 대표 작업 비교** → 품질 유지되면 낮은 쪽
3. [ ] "Be concise"류 일반 간결 지시 → 우선순위 지시로 교체
4. [ ] 전역 응답 템플릿 → lightweight outline
5. [ ] role-play 프레이밍·"think step by step" CoT 넛지 잔재 제거
6. [ ] `prompt_cache_retention` → `prompt_cache_options` 이전 검토
7. [ ] 장기 워크플로우면 `reasoning.context` 검토
8. [ ] 5.4 이전 스택이면 5.5 fresh baseline 원칙 먼저 적용 ([gpt55-patterns.md §10](./gpt55-patterns.md))

### 주의 (커뮤니티 초기 관찰, 출시 +1일)

- 시스템 카드 자인: **5.5보다 사용자 의도를 넘어서는(overstep) 경향** → 검증 루프·고위험 변경 사람 리뷰 게이트 강화
- 장기 실행·완주력은 뚜렷한 개선 컨센서스, 복잡 코딩은 Claude Fable 5 우위가 다수 의견

---

## 참고

- [GPT-5.6 Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-5.6-prompt-guide.md) — 전체 가이드 + 외부 노하우
- [Prompt guidance (공식)](https://developers.openai.com/api/docs/guides/prompt-guidance)
- [Using GPT-5.6 (공식)](https://developers.openai.com/api/docs/guides/latest-model)
- [Simon Willison — The new GPT-5.6 family (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
- [GPT-5.5 패턴 (이전 버전)](./gpt55-patterns.md)
