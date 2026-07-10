# GPT-5.6 Prompting Guide

> **출처**:
> - [Prompt guidance for GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance)
> - [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
> - [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
> - [gpt-5.6-sol / terra / luna 모델 카드](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
> - [The new GPT-5.6 family | Simon Willison (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
>
> **날짜**: 2026-07-10 (출시 이튿날 작성 — 커뮤니티 표본이 얇아 §9는 이후 갱신 여지 있음)
> **이전 버전**: [GPT-5.5 Prompting Guide](./gpt-5.5-prompt-guide.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.5 → 5.6 핵심 변화)

두 가지가 다르다. **① 단일 모델이 아니라 Sol/Terra/Luna 3티어 패밀리**이고, **② 프롬프팅 기조는 5.5를 계승**하되 마이그레이션 관점이 바뀌었다:

> "Prompting best practices for GPT-5.5 remains applicable to GPT-5.6."
> "Treat migration as a tuning pass, not only a model-slug change."

5.5 때의 "fresh baseline 재구성"(전면 재작성)이 아니라, **기존 5.5 프롬프트를 유지한 채 effort·verbosity·지시 민감도를 재튜닝**하는 접근. 단 5.4 이전 스택을 아직 쓰고 있다면 5.5 가이드의 fresh baseline 원칙이 먼저다.

### 한 페이지 변화 요약

| 항목 | 5.5 | 5.6 |
|------|-----|------|
| 모델 라인업 | 단일 `gpt-5.5` | **Sol(플래그십)/Terra(균형)/Luna(고속저가) 3티어** + `gpt-5.6` 별칭(→Sol) |
| 마이그레이션 | fresh baseline 재구성 | **tuning pass** — 프롬프트 유지, 설정 재튜닝 |
| Reasoning effort 출발점 | `medium` 권장 | **기존 effort를 baseline으로 두고 한 단계 낮춰 비교** |
| effort 레벨 | none~xhigh | none~xhigh + **`max` 신설** (단 문서 간 불일치, §3 참조) |
| 간결 지시 | verbosity `low` 권장 | **"Be concise"류 일반 지시에 더 민감** → 우선순위 지시로 대체 |
| 응답 기본값 | plain prose 권장 | 기본이 이미 **compression 편향** (도입부·반복·긴 리스트 감소) |
| Reasoning 지속 | `previous_response_id` | **`reasoning.context`** (auto/current_turn/all_turns) |
| 고난도 모드 | 별도 Pro 모델(5.4 Pro) | **`reasoning.mode: "pro"`** 파라미터로 통합 |
| 도구 오케스트레이션 | 수동 병렬 지시 | **Programmatic Tool Calling** (호스티드 JS 런타임) |
| 캐싱 | `prompt_cache_retention` | **`prompt_cache_options` (explicit mode + ttl)**, write 1.25배 과금 |

---

## 1. 모델 선택 (5.6 신규 — 3티어)

| 모델 | ID | 포지셔닝 | 가격 ($/1M in / cached / out) |
|------|-----|---------|------------------------------|
| GPT-5.6 Sol | `gpt-5.6-sol` | 플래그십. "flagship capability" | $5.00 / $0.50 / $30.00 |
| GPT-5.6 Terra | `gpt-5.6-terra` | 균형. "strong performance at a lower price" | $2.50 / $0.25 / $15.00 |
| GPT-5.6 Luna | `gpt-5.6-luna` | 고속·저가. "efficient, high-volume workloads" | $1.00 / $0.10 / $6.00 |

- `gpt-5.6`은 별칭으로 **Sol로 라우팅**된다
- 3종 공통: 컨텍스트 1,050,000 토큰 / 최대 출력 128,000 / knowledge cutoff 2026-02-16
- 티어 선택의 비용 레버리지는 effort 튜닝보다 크다 — Luna는 Sol 대비 단가 1/5 (위 가격표)
- ⚠️ "price-per-million 비교는 무의미해지는 중" — reasoning 토큰 수가 모델·effort마다 달라 실청구액이 갈린다. 대표 작업으로 실측 비교할 것 (Willison)

**멀티모델 라우팅 패턴** (커뮤니티): Sol = 계획·검증·최종 종합, Terra = 일상 생성, Luna = 소규모 서브태스크. 서브에이전트 워크플로우에서 토큰 폭식을 막는 기본기.

---

## 2. Migration: 5.5 → 5.6 (tuning pass)

공식 원문:

> "If you are migrating from GPT-5.5 or GPT-5.4, preserve your current reasoning effort as the baseline, then compare one level lower."
> "Start with your current GPT-5.5 or GPT-5.4 reasoning setting, then test the same setting and one level lower on representative tasks."

평가 축: **task success, final-answer completeness, required evidence, total tokens, latency, cost**.

### 마이그레이션 체크리스트

1. [ ] 모델명 → `gpt-5.6-sol` (또는 작업 특성에 맞는 terra/luna)
2. [ ] 기존 `reasoning.effort`를 baseline으로 유지 → **한 단계 낮춘 값과 대표 작업으로 비교** → 품질이 유지되면 낮은 쪽 채택
3. [ ] "Be concise"류 일반 간결 지시 제거 → 우선순위 지시로 대체 (§4)
4. [ ] 전역 응답 템플릿 → lightweight outline으로 완화
5. [ ] 5.4 이전에서 상속한 장황한 프롬프트 축소 — 내부 평가에서 짧은 프롬프트 대체 시 스코어 +10~15%, 토큰 41~66% 절감 사례
6. [ ] `prompt_cache_retention` → `prompt_cache_options` (explicit + ttl) 이전 검토
7. [ ] 장기 워크플로우면 `reasoning.context` 설정 검토 (§6)
8. [ ] role-play 프레이밍·"think step by step"류 CoT 넛지 잔재 제거 (네이티브 추론과 충돌)

5.5 가이드의 체크리스트(outcome-first 재구조화, personality/collaboration 분리, Structured Outputs, retrieval budget)는 **이미 적용돼 있다는 전제**. 미적용이면 [5.5 가이드](./gpt-5.5-prompt-guide.md) §13부터.

---

## 3. Reasoning Effort (5.6 변경)

- **기본값: `medium`** (standard·pro 모드 공통)
- 지원 레벨 — ⚠️ **공식 문서 간 불일치가 있다** (2026-07-10 기준):
  - latest-model 가이드: "`none`, `low`, `medium`, `high`, `xhigh`, and `max`" — "가장 어려운 quality-first 작업엔 `max`"
  - reasoning 가이드: `none`, `minimal`, `low`, `medium`, `high`, `xhigh` (`max` 미언급)
  - → `max`/`minimal`은 실제 API 호출로 지원 여부를 확인한 뒤 채택 권장 (Willison이 3티어 모두 `max` 호출 결과를 공개해 작동 자체는 시사됨 — 단 공식 enum 등재는 문서마다 다름)

| 설정 | 5.6 권장 사용 |
|------|--------------|
| `none` | latency-critical (분류, 빠른 검색) |
| `low` | 도구 사용, 계획, 다단계 결정 |
| `medium` | **기본값**. 품질·신뢰성 균형 |
| `high` | 복잡한 디버깅, 깊은 계획 |
| `xhigh` | 비동기·장시간 워크플로우 |
| `max` | quality-first 초고난도 (문서 불일치 — 검증 후 사용) |

**effort를 올리기 전에**: 5.5와 동일 — 높은 effort가 자동으로 낫지 않다. 지시 충돌·약한 정지 기준·개방형 도구 접근이 있으면 overthinking과 불필요한 탐색만 늘어난다. **eval로 측정 가능한 개선이 확인될 때만 올릴 것.**

**외부 실측** (Willison 펠리컨 비교, 3티어×6레벨 — `max` 포함 18종): effort 상향의 비용 곡선이 가파르다 — Sol 기준 none 5.90¢(출력 1,961토큰) → high 10.38¢(3,454토큰). 품질이 비용만큼 오르는지는 각자 eval로 확인할 것 — 공식 권고("한 단계 낮춰 비교")와 같은 방향.

---

## 4. 간결성: 일반 지시 → 우선순위 지시 (5.6 핵심 변경)

5.6은 기본 출력이 이미 짧다(compression 편향). 그 위에 일반 간결 지시를 얹으면 **작업 우선순위 자체가 왜곡**된다:

> "GPT-5.6 is more sensitive than GPT-5.5 to instructions such as 'Be concise,' 'Keep it short,' or 'Use minimal text.'"
> "An instruction such as 'Be concise. Use minimal text.' does more than remove filler—it can change how the model prioritizes the task."

**대체 패턴** — 무엇을 자를지가 아니라 **무엇을 먼저 내놓을지**를 지시:

```xml
<!-- ❌ 5.6에서 위험 -->
Be concise. Keep it short. Use minimal text.

<!-- ✓ 우선순위 지시 -->
Lead with the conclusion. Include the evidence needed to support it,
any material caveat, and the next action.
```

주의: 이 원칙은 **일반적(막연한) 간결 지시**에 대한 것이다. "단순 질문은 1-2문장", "단어 수 상한 N" 같은 **카운트 가능한 구체 제약**은 여전히 유효하다. `text.verbosity = "low"` 파라미터 출발점도 5.5와 동일하게 유지 — 단 코드 리뷰·마이그레이션·감사 설명처럼 근거 서술이 필요한 출력엔 low가 부적합하다는 실전 보고가 있다.

---

## 5. 5.5에서 그대로 유지되는 것

아래는 5.6 공식 가이던스가 재확인한 5.5 원칙 — 상세는 [5.5 가이드](./gpt-5.5-prompt-guide.md) 해당 섹션:

- **Outcome-first** (5.5 §3): 최소 프롬프트에서 시작, eval로 gap이 드러날 때만 지시 추가. "Add detail only where it changes behavior"
- **Personality + Collaboration Style 분리** (5.5 §4): 막연한 friendliness 대신 구체 지시 — "Be direct and tactful. 마찰은 구체적으로 인정. canned reassurance와 불필요한 sign-off 회피"
- **Plain prose 기본** (5.5 §10): 5.6은 기본값이 더 짧아져 별도 지시 필요성이 오히려 줄었다
- **Retrieval budget / stop rules** (5.5 §5), **출력 검증 도구** (5.5 §7.1), **Structured Outputs** (5.5 §9.3)
- **구조 지시**: 전역 응답 템플릿 대신 **lightweight outline**

---

## 6. 신규 API 기능과 프롬프팅

### 6.1 Pro mode — `reasoning.mode: "pro"`

표준 대비 더 많은 model work. 토큰·지연 증가, **선택 모델의 표준 토큰 요율로 과금**. 5.4 Pro 같은 별도 모델이 아니라 파라미터다.

> "Use pro mode when a marginal quality improvement materially affects the outcome."

일상 작업엔 끄고, 오답 비용이 큰 지점(최종 검증, 고위험 판단)에만 선별 적용.

### 6.2 Reasoning 지속 — `reasoning.context`

| 값 | 의미 |
|----|------|
| `auto` (기본) | 모델 기본 동작 |
| `current_turn` | 현재 턴 추론만 사용 |
| `all_turns` | 이전 턴들의 reasoning 항목까지 렌더링 — 장기 워크플로우에서 컨텍스트 절약 |

### 6.3 Programmatic Tool Calling

호스티드 JS 런타임이 도구 호출을 오케스트레이션. 도구에 `allowed_callers`로 opt-in, `program`/`program_output` 아이템 처리 필요. 프롬프팅 포인트:

> "When both direct and programmatic calling are available, explicitly state: Which bounded stage should use Programmatic Tool Calling."
> "Evaluate the final user-visible answer, not only the program result."

### 6.4 명시적 프롬프트 캐싱

`prompt_cache_options.mode: "explicit"` + `ttl` (기존 `prompt_cache_retention` 대체). **캐시 write는 uncached input의 1.25배 과금**, read는 할인 유지 → `cached_tokens`/`cache_write_tokens`를 추적해 실익 확인.

### 6.5 safety_identifier

요청마다 안정적인 프라이버시 보존 식별자 전송 — 사용자 단위 오남용 추적용.

---

## 7. Key Takeaways

1. **3티어 선택이 첫 결정**: Sol/Terra/Luna — 티어 라우팅이 effort 튜닝보다 비용 레버리지가 크다
2. **Tuning pass, not rewrite**: 5.5 프롬프트 유지, 설정 재튜닝
3. **effort는 기존 값 baseline + 한 단계 하향 비교** — effort 상향의 비용 곡선이 가파르다 (Sol none 5.90¢ → high 10.38¢ 실측)
4. **"Be concise" 금지 → 우선순위 지시** ("결론 먼저, 근거, 중대 caveat, 다음 액션")
5. **5.5 원칙 전부 유효**: outcome-first, personality/collaboration 분리, plain prose, retrieval budget
6. **pro mode·PTC·explicit caching은 선별 적용** — 기본 off, 실익 확인 후

---

## 8. 외부 노하우 (Simon Willison, 2026-07-09)

- 펠리컨 SVG 전수 비교: 3티어 × effort 6레벨(**`max` 포함**) 18종 — `max`가 API에서 실제 작동함을 시사. Sol 비용은 none 5.90¢ → high 10.38¢
- 코딩 비교(원문): "it hasn't struck me as better than Fable at the kind of complex coding tasks I've been using with Anthropic's model"
- 벤치마크 읽을 때 주의: OpenAI 발표의 Agents' Last Exam 그래프는 y축이 30%에서 시작(과장 효과). SWE-Bench Pro는 OpenAI 스스로 열세 인정(Fable 5 80% vs Sol 64.6%), SWE-bench Verified 공식 점수는 미공개

---

## 9. 커뮤니티 초기 관찰 (2026-07-10, 출시 +1일 — 표본 얇음, 참고용)

> 원문·출처: `dotfiles/.claude/scratch/research-gpt56.md`. HN 출시 스레드(item?id=48849066)와 언론 2차 요약 기반. Reddit 원문 미확인.

- **개선 컨센서스**: 장기 실행·완주력 — 조기 중단 없이 물고 늘어짐. 서브에이전트 오케스트레이션(Sol Ultra: Terminal-Bench 2.1 88.8→91.9%)
- **한계**: 프론트엔드 산출물 품질 여전히 약함. 복잡 코딩은 Fable 5 우위가 다수 의견
- **⚠️ 오버스텝·허위 보고**: OpenAI 시스템 카드 자인 — "5.5보다 사용자 의도를 넘어서는 경향". 승인 안 된 파괴적 행동·허위 완료 보고 사례(METR 플래그) → **검증 루프 강제 + 고위험 변경 사람 리뷰 게이트**가 5.5 때보다 더 중요
- **Ultra 토큰 폭식**: 표준 Sol 대비 2~3배 → rollout budget 캡(예: 500k), 티어 라우팅(§1), 반복 상한(N회 실패 시 에스컬레이션)

---

## 10. 한 페이지 치트시트

### API 호출 디폴트 (5.6)

```python
response = client.responses.create(
    model="gpt-5.6-sol",                  # 일상 생성은 terra, 대량 소작업은 luna
    reasoning={
        "effort": "medium",               # 5.5에서 오면: 기존 값 baseline + 한 단계 하향 비교
        # "mode": "pro",                  # 오답 비용 큰 지점만 선별
        # "context": "all_turns",         # 장기 워크플로우만
    },
    text={"verbosity": "low"},            # 근거 서술 필요한 출력은 medium
    input=[ ... ],
    tools=[ ... ],
)
```

### 프롬프트에서 이번에 바꿀 것 (최소 diff)

```diff
- Be concise. Keep it short.
+ Lead with the conclusion. Include the evidence needed to support it,
+ any material caveat, and the next action.
```

시스템 프롬프트 골격은 5.5와 동일 — [5.5 가이드 §16](./gpt-5.5-prompt-guide.md) 참조.

---

## Sources

- [Prompt guidance for GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance)
- [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
- [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
- [gpt-5.6-sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol) · [gpt-5.6-terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) · [gpt-5.6-luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [GPT-5.6 시스템 카드 (preview)](https://deploymentsafety.openai.com/gpt-5-6-preview)
- [The new GPT-5.6 family | Simon Willison (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
- [HN 출시 스레드](https://news.ycombinator.com/item?id=48849066)
- [GPT-5.5 Prompting Guide (이전 버전 비교)](./gpt-5.5-prompt-guide.md)
