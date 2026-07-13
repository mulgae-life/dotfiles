# GPT-5.6 Prompting Guide

> **출처**:
> - [Prompting guidance for GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)
> - [Upgrading to GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
> - [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
> - [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
> - [gpt-5.6-sol / terra / luna 모델 카드](https://developers.openai.com/api/docs/models/gpt-5.6-sol)
> - [The new GPT-5.6 family | Simon Willison (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
>
> **검증일**: 2026-07-13
> **이전 버전**: [GPT-5.5 Prompting Guide](./gpt-5.5-prompt-guide.md)

---

## ⚠️ 가장 먼저 알아야 할 것 (5.5 → 5.6 핵심 변화)

GPT-5.6은 Sol/Terra/Luna 3티어 패밀리입니다. 프롬프트는 결과·핵심 제약·사용 가능한 근거·완료 기준을 명확히 두고, 해결 경로는 모델에 맡깁니다. 마이그레이션은 모델과 기존 추론 강도를 먼저 유지한 채 평가한 다음, 중복 지시와 무관한 도구를 한 묶음씩 제거하는 방식입니다. 작동 중인 프롬프트를 한 번에 전면 재작성하면 모델·추론 강도·프롬프트·도구·런타임 중 회귀 원인을 분리할 수 없습니다.

OpenAI 내부 코딩 에이전트 평가에서는 더 간결한 시스템 프롬프트가 점수 약 10~15% 향상, 총토큰 41~66% 감소, 비용 33~67% 감소를 보였습니다. 이 수치는 방향성 있는 내부 결과이며 실제 서비스의 대표 평가셋으로 재검증해야 합니다.

### 한 페이지 변화 요약

| 항목 | 5.5 | 5.6 |
|------|-----|------|
| 모델 라인업 | 단일 `gpt-5.5` | **Sol(플래그십)/Terra(균형)/Luna(고속저가) 3티어** + `gpt-5.6` 별칭(→Sol) |
| 마이그레이션 | 기존 프롬프트 기준선 | **모델만 교체 → 기존 평가 → 한 그룹씩 프롬프트 축소 → 회귀별 최소 수정** |
| Reasoning effort 출발점 | `medium` 권장 | **기존 effort를 baseline으로 두고 한 단계 낮춰 비교** |
| effort 레벨 | none~xhigh | none~xhigh + **`max` 신설** |
| 간결 지시 | 작업별 출력 계약 | 기본 출력이 더 간결하므로 **막연한 간결 지시의 필요성을 재평가** |
| Reasoning 지속 | `previous_response_id` | **`reasoning.context`** (auto/current_turn/all_turns) |
| 고난도 모드 | 별도 Pro 모델(5.4 Pro) | **`reasoning.mode: "pro"`** 파라미터 신설 — 권장 경로 (기존 Pro 모델 ID는 동작·과금 유지) |
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
- 3종 공통: 컨텍스트 1,050,000 토큰 / 최대 출력 128,000 / knowledge cutoff 2026-02-16 (모델 카드 3종 재검증 2026-07-13 — 이전 판의 "Luna 400K" 표기는 오류였음)
- Codex 클라이언트 윈도우는 API와 별개이며 **변동 가능** — 라이브 서버 캐시(`~/.codex/models_cache.json`, 2026-07-13) 기준 3종 모두 272K(장문 과금 임계값과 일치). 바이너리 오프라인 폴백에는 372K로 다르게 잡혀 있으므로, 인용 전 라이브 캐시를 확인
- 티어 선택의 비용 레버리지는 effort 튜닝보다 크다 — Luna는 Sol 대비 단가 1/5 (위 가격표)
- ⚠️ "price-per-million 비교는 무의미해지는 중" — reasoning 토큰 수가 모델·effort마다 달라 실청구액이 갈린다. 대표 작업으로 실측 비교할 것 (Willison)

**Codex 공식 선택 기준**: Sol은 복잡하고 개방형인 고가치 작업, Terra는 GPT-5.5가 담당하던 일상 작업, Luna는 완료 기준이 명확한 반복·추출·분류·변환 작업에 사용합니다.

---

## 2. Migration: 5.5 → 5.6

평가 축: **task success, final-answer completeness, required evidence, total tokens, latency, cost**.

### 마이그레이션 체크리스트

1. [ ] 사용처별 역할을 확인하고 Sol/Terra/Luna 또는 유지 대상으로 분류
2. [ ] 모델만 교체하고 기존 프롬프트·유효 추론 강도를 유지한 기준선 평가
3. [ ] 같은 추론 강도와 한 단계 낮은 값을 대표 작업에서 비교
4. [ ] 반복 규칙·행동을 바꾸지 않는 예시·절차·무관한 도구를 한 그룹씩 제거하고 매번 재평가
5. [ ] 측정된 회귀에만 가장 작은 지시를 추가
6. [ ] Chat Completions의 함수 도구 사용처는 유효 추론 강도 `none`인지 확인하고, 추론과 도구가 모두 필요하면 Responses API 이전을 별도 작업으로 검토
7. [ ] 캐싱·persisted reasoning·Pro·PTC·multi-agent는 기준선 마이그레이션과 분리하여 평가

---

## 3. Reasoning Effort (5.6 변경)

- **기본값: `medium`** (standard·pro 모드 공통, API 기준)
- GPT-5.6 지원 레벨: `none`, `low`, `medium`, `high`, `xhigh`, `max` — 단 ⚠️ reasoning 가이드의 열거에는 2026-07-13 현재 `max`가 미반영(latest-model 가이드·모델 카드에는 등재). 그 페이지 기준으로 검증하는 도구는 `max`를 거부할 수 있음
- **Codex 제품 기본 effort는 서버가 내려주는 모델 메타데이터가 결정하며 변동 가능** — 라이브 서버 캐시(2026-07-13) 기준 3티어 모두 `medium`(API 기본과 동일), 바이너리 오프라인 폴백에는 Sol `low`로 낮춰 잡혀 있음. 온보딩 문구는 양쪽 모두 "Sol is highly capable at lower reasoning efforts — try starting lower, then turn it up for harder jobs". Sol·Terra는 `ultra`(자동 작업 위임을 포함한 최대 추론)도 노출하며 Luna에는 없습니다(캐시·폴백 일치).
- Codex 제품은 Max를 지원하지만, 2026-07-13 현재 공식 `config.toml`의 `model_reasoning_effort` 열거형은 `minimal|low|medium|high|xhigh`로 표기되어 있어 Max는 모델 선택 화면에서 사용하고 전역 TOML 값으로 고정하지 않습니다.

| 설정 | 5.6 권장 사용 |
|------|--------------|
| `none` | latency-critical (분류, 빠른 검색) |
| `low` | 도구 사용, 계획, 다단계 결정 |
| `medium` | **기본값**. 품질·신뢰성 균형 |
| `high` | 평가에서 추가 깊이가 필요한 복잡한 작업 |
| `xhigh` | high보다 유의미한 품질 향상이 확인된 고난도 작업 |
| `max` | 가장 어려운 quality-first 작업. 전역 기본값으로 사용하지 않음 |

**effort를 올리기 전에** 성공 기준·의존성·도구 라우팅·검증 반복의 누락을 확인합니다. 높은 effort가 자동으로 더 나은 결과를 보장하지 않으므로 평가에서 유의미한 개선이 확인될 때만 올립니다.

**외부 실측**: Simon Willison의 펠리컨 비교는 3티어×6개 effort 18종을 실행했으며, Luna none은 0.71¢, Sol max는 48.55¢였습니다. 품질 대비 비용은 대표 작업 평가로 결정해야 합니다.

---

## 4. 간결성: 일반 지시 → 우선순위 지시 (5.6 핵심 변경)

5.6은 5.5보다 기본 출력이 더 간결합니다. `Be concise`, `Keep it short` 같은 막연한 지시는 불필요하거나 결과를 지나치게 짧게 만들 수 있으므로 실제 평가에서 효용을 확인합니다.

**대체 패턴** — 무엇을 자를지가 아니라 **무엇을 먼저 내놓을지**를 지시:

```xml
<!-- ❌ 5.6에서 위험 -->
Be concise. Keep it short. Use minimal text.

<!-- ✓ 우선순위 지시 -->
Lead with the conclusion. Include the evidence needed to support it,
any material caveat, and the next action.
```

이 원칙은 막연한 간결 지시에 대한 것입니다. 작업별 필수 내용·길이·구조·톤은 계속 명시하며, `text.verbosity`는 기본 상세도만 설정합니다. 코드 리뷰·마이그레이션·감사처럼 근거 서술이 중요한 작업은 `low`와 `medium`을 대표 사례로 비교합니다.

---

## 5. GPT-5.6 프롬프트 계약

복잡한 프롬프트는 아래 구조에서 시작하고 행동을 바꾸는 내용만 추가합니다.

```text
Role: 모델의 역할과 업무 맥락
Personality: 톤과 협업 방식
Goal: 사용자에게 전달될 결과
Success criteria: 완료 전에 참이어야 할 조건과 필수 근거
Constraints: 정책·안전·사업·증거·부작용 한계
Tools: 사용할 도구, 선행 조회, 금지 경로, 오류 처리
Output: 필수 섹션·길이·형식·톤
Stop rules: 재시도·fallback·질문·중단 조건
```

- **권한 경계**: 답변·분석, 범위 안 로컬 변경, 외부·파괴적·비용 발생 작업을 구분하고 같은 규칙은 한 곳에서 한 번만 씁니다.
- **도구 라우팅**: 독립적인 읽기는 병렬화하고, 다음 행동이 결과에 의존하면 순차 실행합니다. 빈 값·부분 결과·비정상적으로 좁은 결과에는 의미 있는 fallback을 1~2회 시도합니다.
- **검색 예산**: 필요한 근거가 확보되면 멈추고, 필수 사실·식별자·출처가 없을 때만 가장 작은 추가 검색을 수행합니다.
- **검증**: 코드에는 관련 테스트·타입·린트·빌드·스모크 테스트를, 시각 결과물에는 렌더링 검사를 적용합니다.

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
| `all_turns` | 사용 가능한 이전 턴의 reasoning 항목을 다음 컨텍스트에 포함 |

목표·가정·우선순위가 안정적인 장기 작업에는 `all_turns`, 이전 추론이 더 이상 관련 없으면 `current_turn`을 사용합니다. 오래된 추론은 토큰·지연을 늘리고 낡은 접근에 고정할 수 있으므로 항상 켜지 않습니다.

### 6.3 Programmatic Tool Calling

호스티드 JavaScript 런타임이 여러 도구 결과를 필터링·조인·정렬·중복 제거·집계하고 작은 구조로 축약합니다. 도구에 `allowed_callers`로 opt-in하며 클라이언트는 `program`/`program_output` 항목과 호출 연결을 보존해야 합니다.

- 적합: 큰 구조화 중간 결과의 결정론적 축약, 반복 검증, 다수 유사 레코드 처리
- 부적합: 한 번의 호출, 승인 작업, 호출 사이 의미 판단, 인용·원본 산출물 보존, 최종 검증
- 프롬프트에는 적용할 bounded stage, 허용 도구, 출력 스키마, 동시성·재시도·중단 한도, 직접 호출로 돌아갈 handoff를 명시

### 6.4 명시적 프롬프트 캐싱

`prompt_cache_options.mode: "explicit"` + `ttl` (기존 `prompt_cache_retention` 대체). **캐시 write는 uncached input의 1.25배 과금**, read는 할인 유지 → `cached_tokens`/`cache_write_tokens`를 추적해 실익 확인.

### 6.5 safety_identifier

안정적인 프라이버시 보존 식별자 전송 — 사용자 단위 오남용 추적용. 개별 사용자가 모델과 상호작용하는 제품에 권장(recommended)하나 필수는 아니며(not required), 적용 시 각 요청에 전달한다. 값은 사용자명·이메일의 해시 등 안정적 식별자. (Deprecated `user`를 `safety_identifier` + `prompt_cache_key`가 대체)

---

## 7. 핵심 정리

1. 작업 역할에 맞춰 Sol/Terra/Luna를 선택합니다.
2. 모델만 교체한 기준선을 먼저 만들고 프롬프트·effort·신규 기능을 한 번에 바꾸지 않습니다.
3. 기존 effort와 한 단계 낮은 값을 비교하고 `max`는 가장 어려운 quality-first 작업에만 사용합니다.
4. 막연한 간결 지시보다 보존할 내용과 먼저 생략할 내용을 지정합니다.
5. 결과·성공 기준·근거·권한·도구·검증·중단 계약은 남기고 중복 절차와 무관한 예시는 줄입니다.
6. Pro·persisted reasoning·PTC·explicit caching·multi-agent는 측정 가능한 문제를 해결할 때 각각 독립 평가합니다.

---

## 8. 외부 관찰 (Simon Willison 외 — 2026-07-13 재검증)

- 펠리컨 SVG 전수 비교: 3티어 × effort 6레벨(`max` 포함) 18종. 비용 범위는 Luna none 0.71¢ ~ Sol max 48.55¢ (약 68배 스프레드 — 개별 수치는 본문이 아닌 링크된 비교표에 있음)
- 코딩 비교(원문): "it's definitely very competent, though so far it hasn't struck me as better than Fable at the kind of complex coding tasks I've been using with Anthropic's model"
- SWE-Bench Pro: GPT-5.6 3티어는 **64.6 / 63.4 / 62.7%로 공개 수치**입니다(발표 차트·리더보드 — 이 문서 이전 판의 "서드파티 추정" 표기는 오류였음). Claude 최상위는 80.0~80.3%로 보도되나 Fable 5/Mythos 5(동일 기반 모델) 간 소수점 귀속이 출처마다 갈립니다. OpenAI는 별도 감사 *Separating signal from noise in coding evaluations*에서 "30% of SWE-Bench Pro tasks to be broken"을 발표하고 기존 권고를 철회 — 단 GPT-5.6 출시와 동시 발표라 이해충돌 비판이 병존. 모델 선택은 한 벤치마크가 아니라 실제 업무 평가로 결정합니다.
- 에이전틱 벤치마크(Terminal-Bench 2.1: Sol 88.8% → Ultra 91.9%, 병렬 서브에이전트 4개) 인용 시 주의: [METR 사전배포 평가](https://metr.org/blog/2026-06-26-gpt-5-6-sol/)는 Sol의 평가 게이밍(리워드 해킹)을 자사가 공개 시험한 모델 중 최고 비율로 기록했고, time-horizon 추정이 11시간~270시간+로 벌어져 산정 불능이었습니다 — 수치에 이 신뢰성 단서를 함께 붙입니다.

---

## 9. 커뮤니티 초기 관찰 (2026-07-13, 참고용)

아래 내용은 통제된 평가가 아닌 커뮤니티 초기 후기입니다(개별 Reddit 스레드는 미검증 — 서드파티 집계로 교차 확인). 설정 기본값의 근거로 사용하지 않습니다.

- **실행력 vs 분별력**: 커뮤니티 총평은 Sol이 실행력·장기 완주(문제를 물고 늘어져 끝까지 감), Fable 5가 분별력·질문 설계·엔드투엔드 코드베이스 판단에서 앞선다는 대비 — 하이브리드 워크플로우 권장 (집계 기사 기준, 개별 후기 원문 미검증).
- **품질 평가는 혼재**: 프론트엔드 격차가 대부분 해소됐다(일부 "동급")는 평과 여전히 약하다는 후기가 공존합니다. Sol에서 후속 지시가 더 필요하다는 보고도 있습니다.
- **사용량 우려**: Ultra·서브에이전트 작업은 태스크당 토큰 6~12× 소모라는 서드파티 분석([tokenkarma](https://tokenkarma.app/blog/codex-sol-ultra-subagent-token-cost-2026/))이 있고, 하네스 버그로 서브에이전트가 과다 스폰된 사례도 보고됩니다. 배율은 작업 의존이므로 대표 작업으로 실측합니다.
- **설정 우회는 미채택**: "272K"는 강제 컨텍스트 창이 아니라 **과금 임계값**입니다 — 272K 초과 입력은 전체 요청이 입력 2×·출력 1.5×로 과금되며, 기본 설정에서 자동 초과 위험이 보고됨(openai/codex #32486). `[features.multi_agent_v2]`는 실재 플래그지만 쿼터 절감 근거가 없고, Sol은 서브에이전트 모델 지정이 안 되는 이슈(#31814 — 전부 Sol로 실행)와 결합해 비용을 증폭시킬 수 있어 이 저장소에는 반영하지 않습니다.
- **실무 결론**: 기본 단일 에이전트로 시작하고, 독립 작업으로 분해할 수 있으며 비용 증가를 정당화할 때만 서브에이전트를 사용합니다("요청 시에만 스폰" 지침이 실증적으로 유효). 대표 작업 평가에서 완료율·총토큰·지연·재시도 횟수를 함께 비교합니다.

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
    text={"verbosity": "medium"},         # 작업별 필수 길이·구조는 프롬프트에서 지정
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

복잡한 시스템 프롬프트는 §5의 5.6 공식 골격에서 시작합니다.

---

## Sources

- [Prompting guidance for GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)
- [Upgrading to GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
- [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [Codex models | OpenAI](https://learn.chatgpt.com/docs/models)
- [GPT-5.6 in ChatGPT and Codex | OpenAI Help](https://help.openai.com/en/articles/20001354-gpt-56-in-chatgpt)
- [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
- [gpt-5.6-sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol) · [gpt-5.6-terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) · [gpt-5.6-luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [GPT-5.6 시스템 카드 (최종, 2026-07-09)](https://deploymentsafety.openai.com/gpt-5-6)
- [METR: GPT-5.6 Sol 사전배포 평가](https://metr.org/blog/2026-06-26-gpt-5-6-sol/)
- [The new GPT-5.6 family | Simon Willison (2026-07-09)](https://simonwillison.net/2026/Jul/9/gpt-5-6/)
- [Separating signal from noise in coding evaluations | OpenAI](https://openai.com/index/separating-signal-from-noise-coding-evaluations/) — SWE-Bench Pro "30% broken" 감사
- [Codex changelog](https://developers.openai.com/codex/changelog) — 0.144.0에서 GPT-5.6 3티어 추가 (2026-07-09)
- Reddit 초기 후기: 개별 스레드 URL은 존재 미검증이라 인용하지 않음 — 서드파티 집계 기사로 교차 확인 (2026-07-13)
- [GPT-5.5 Prompting Guide (이전 버전 비교)](./gpt-5.5-prompt-guide.md)
