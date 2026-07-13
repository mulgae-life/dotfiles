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


GPT-5.6은 Sol/Terra/Luna **3티어 패밀리**. 마이그레이션은 모델만 먼저 교체해 기존 프롬프트·effort로 기준선을 평가한 뒤, 중복 지시와 무관한 도구를 한 그룹씩 줄이고 측정된 회귀에만 최소 지시를 추가하는 방식이다 — 공식: "Preserve the old effective reasoning effort explicitly" / "test the same setting and one lower on representative tasks" (Upgrading to GPT-5.6 Sol).
공식 내부 평가에서 더 간결한 시스템 프롬프트가 점수 +10~15%, 총토큰 -41~66%, 비용 -33~67%를 기록했다 (prompt-guidance, 대표 작업으로 재검증 필요).

---

## 개요 (5.5 → 5.6 핵심 변화)

| 항목 | 5.5 | 5.6 |
|------|-----|------|
| 모델 라인업 | 단일 `gpt-5.5` | **Sol/Terra/Luna 3티어** + `gpt-5.6` 별칭(→Sol) |
| 마이그레이션 | 기존 프롬프트 기준선 | **모델만 교체 → 기준선 평가 → 한 그룹씩 프롬프트 축소 → 회귀별 최소 수정** |
| effort 출발점 | `medium` 권장 | **기존 effort baseline + 한 단계 낮춰 비교** |
| 간결 지시 | verbosity `low` 권장 | 기본 출력이 더 간결 → **막연한 간결 지시의 효용 재평가** (과작동 위험) |
| 응답 기본값 | plain prose 권장 | 기본 출력이 5.5보다 간결 (별도 지시 필요성 감소) |
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

5.6은 기본 출력이 5.5보다 간결하다. 그 위에 얹은 막연한 간결 지시는 불필요하거나 응답을 지나치게 짧게 만들 수 있다:

> "GPT-5.6 tends to be more concise by default than GPT-5.5. When migrating, check whether broad brevity instructions such as 'Be concise' or 'Keep it short' are still useful" — 이런 지시는 "can sometimes make responses too brief." (prompt-guidance-gpt-5p6)

```xml
<!-- ❌ 작업 우선순위를 왜곡할 수 있음 -->
Be concise. Keep it short. Use minimal text.

<!-- ✓ 무엇을 먼저 내놓을지 지시 -->
Lead with the conclusion. Include the evidence needed to support it,
any material caveat, and the next action.
```

- **카운트 가능한 구체 제약**("3문장 이내", "단어 수 상한 N")은 여전히 유효 — 금지 대상은 막연한 간결 지시
- `text.verbosity`는 기본 상세도만 설정 — 근거 서술이 중요한 작업(리뷰·감사·마이그레이션)은 `low`/`medium`을 대표 사례로 비교
- 전역 응답 템플릿 대신 **lightweight outline**

---

## 3. Reasoning Effort 재튜닝 (변경)

공식 마이그레이션 지침:

> "Preserve the old effective reasoning effort explicitly." / "After the baseline passes, test the same setting and one lower on representative tasks." (Upgrading to GPT-5.6 Sol, 2026-07-13 검증)

- 기본값 `medium` (standard·pro 공통, API 기준). 신규 프로젝트는 medium 출발
- Codex 제품 기본 effort는 서버 메타데이터가 결정(변동 가능) — 라이브 캐시(2026-07-13) 기준 3티어 모두 `medium`, 바이너리 오프라인 폴백은 Sol `low`. 온보딩 문구는 "낮게 시작해 어려운 작업에서 올려라"
- 5.6이 더 적은 토큰으로 같은 품질을 내는 경우가 많아 **하향 여지를 먼저 평가**
- 평가 축: task success, final-answer completeness, required evidence, total tokens, latency, cost
- `max` 레벨 신설 — latest-model 가이드·모델 카드에 정식 등재, 단 reasoning 가이드 열거에는 미반영(2026-07-13). 전역 기본값으로 쓰지 않기
- effort를 올리기 전에 5.5 패턴(§5) 먼저 — 높은 effort는 지시 충돌·약한 정지 기준과 만나면 overthinking만 유발

---

## 4. 신규 API 기능 프롬프팅

### reasoning.mode: "pro"

> "Use pro mode when a marginal quality improvement materially affects the outcome."

토큰·지연 증가(과금은 표준 요율). 오답 비용이 큰 지점(최종 검증, 고위험 판단)에만 선별 적용.

### reasoning.context

`auto`(기본) / `current_turn` / `all_turns`. 목표·가정이 안정적인 장기 워크플로우에서 `all_turns`로 이전 턴 추론을 다음 컨텍스트에 포함(연속성·캐시 효율). 오래된 추론은 토큰·지연·앵커링을 늘리므로 항상 켜지 않기.

### Programmatic Tool Calling

호스티드 JS 런타임이 도구 오케스트레이션 (도구에 `allowed_callers` opt-in). 프롬프팅 포인트:

> "When both direct and programmatic calling are available, explicitly state: Which bounded stage should use Programmatic Tool Calling."
> "Evaluate the final user-visible answer, not only the program result."

### 명시적 프롬프트 캐싱

`prompt_cache_options.mode: "explicit"` + `ttl` (기존 `prompt_cache_retention` 대체). **write 1.25배 과금** — read 물량으로 회수되는지 확인.

---

## 5. 5.5 패턴 호환

5.5 패턴의 골자는 5.6 공식 프롬프트 계약(Role / Personality / Goal / Success criteria / Constraints / Tools / Output / Stop rules 8섹션, prompt-guidance-gpt-5p6)으로 흡수됐다. 이 골격에서 시작하고 행동을 바꾸는 내용만 추가:

- Outcome-first (goal / success_criteria / stop_rules) → Goal·Success criteria·Stop rules 섹션
- Personality + Collaboration Style 분리 → Role·Personality 섹션
- `<retrieval_budget>` (stopping conditions) → Tools·Stop rules 섹션
- `<tool_validation>` (출력 검증을 도구로) → Success criteria·Tools 섹션
- Markdown 절제 → Output 섹션 (5.6은 기본 출력이 더 간결)
- Structured Outputs API 강제
- 5.4 계열 패턴 (`<output_contract>`, `<completeness_contract>` 등)

상세는 [`gpt55-patterns.md`](./gpt55-patterns.md) 참조. 5.6에서 새로 추가/변경된 것: §1~§4.

---

## 6. 마이그레이션 전략 (5.5 → 5.6)

> "Preserve the old effective reasoning effort explicitly." / "After the baseline passes, test the same setting and one lower on representative tasks." (Upgrading to GPT-5.6 Sol)

### 체크리스트

1. [ ] 사용처별 역할 분류 → `gpt-5.6-sol`(복잡·개방형) / `terra`(일상 — 기존 5.5 작업의 자연스러운 출발점) / `luna`(명확·반복)
2. [ ] **모델만 교체**하고 기존 프롬프트·유효 effort를 유지한 기준선 평가
3. [ ] 같은 effort와 **한 단계 낮춘 값을 대표 작업으로 비교** → 품질 유지되면 낮은 쪽
4. [ ] 반복 규칙·행동을 바꾸지 않는 예시·무관한 도구를 **한 그룹씩 제거**하고 매번 재평가 (prompt-guidance)
5. [ ] 측정된 회귀에만 가장 작은 지시 추가. "Be concise"류 막연한 간결 지시는 효용 재평가
6. [ ] Chat Completions에서 함수 도구를 쓰는 경로는 유효 effort `none`인지 확인 (5.6 호환 조건)
7. [ ] `prompt_cache_retention` → `prompt_cache_options` 이전 검토
8. [ ] 캐싱·`reasoning.context`·pro·PTC·multi-agent는 기준선 마이그레이션과 **분리 평가**

### 주의 (커뮤니티 관찰, 2026-07-13 갱신)

- 시스템 카드 자인: **5.5보다 사용자 의도를 넘어서는(overstep) 경향** + METR은 Sol의 리워드 해킹 비율을 공개 모델 중 최고로 평가 → 검증 루프·고위험 변경 사람 리뷰 게이트 강화
- 실행력·장기 완주는 Sol 강점, 분별력·엔드투엔드 코드베이스 판단은 Claude Fable 5 우위가 중론 → 하이브리드 워크플로우 권장
- Ultra·서브에이전트는 태스크당 토큰 6~12× 소모라는 서드파티 분석([tokenkarma](https://tokenkarma.app/blog/codex-sol-ultra-subagent-token-cost-2026/))이 있음(개선 폭은 완만, Terminal-Bench +3.1pp) → 가장 어려운 독립 분해형 작업에만

---

## 참고

- [GPT-5.6 Prompting Guide (full)](../../../../reference/openai-prompt-guide/gpt-5.6-prompt-guide.md) — 전체 가이드 + 외부 노하우
- [Prompting guidance for GPT-5.6 Sol (공식)](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)
- [Upgrading to GPT-5.6 Sol (공식)](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
- [Using GPT-5.6 (공식)](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [Simon Willison — The new GPT-5.6 family (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
- [GPT-5.5 패턴 (이전 버전)](./gpt55-patterns.md)
