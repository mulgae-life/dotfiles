# Chain of Thought (CoT) 프롬프팅

복잡한 작업에서 모델이 단계별로 추론하도록 유도하는 기법입니다.

## 개요

Chain of Thought (CoT) 프롬프팅의 권장 방식은 공급자·모델·사고 설정에 따라 다릅니다.

**핵심 원칙**: 수동 CoT는 중간 추론 단계를 서술하게 하는 기법입니다. 적용 여부와 출력 방식은 모델의 내장 추론 기능, 사고 설정, 과제별 평가에 따라 정하며, 아래 "CoT 분기: 모델 유형별 주의사항" 섹션을 따릅니다.

## 플랫폼별 용어

| 플랫폼 | 용어 | 표현 |
|--------|------|------|
| **OpenAI** | Chain of Thought | "Think step-by-step" |
| **Anthropic** | Let Claude think | "Think step-by-step" / 3단계 구분 |
| **공통** | ✅ 동일 개념 | 사고 과정 출력(표준 모델 한정, 아래 "CoT 분기" 참조) |

## 왜 사용하는가?

### ✅ 장점

- **정확도**: 단계별 추론으로 에러 감소 (수학, 논리, 분석)
- **일관성**: 구조화된 사고 → 일관된 응답
- **디버깅**: 사고 과정을 보면 프롬프트 개선점 파악

### ⚠️ 단점

- 출력 길이 증가 → 지연 시간 증가
- 모든 작업에 필요하지 않음

**사용 시기**: 인간도 생각이 필요한 작업 (복잡한 수학, 다단계 분석, 복잡한 문서 작성, 여러 요소를 고려한 결정)

## 사용 방법

### 레벨 1: Basic (가장 간단)

단순히 "Think step-by-step" 추가.

```yaml
질문: 다음 문제를 풀어주세요.

Think step-by-step.
```

**장점**: 간단
**단점**: "어떻게" 생각할지 가이드 없음

### 레벨 2: Guided (단계 명시)

생각해야 할 단계를 명시적으로 제공.

```yaml
질문: 이 계약을 분석하세요.

Think before you answer. First, identify potential risks. Then, evaluate the
severity of each risk. Finally, provide recommendations.
```

**장점**: 구조화된 사고
**단점**: 사고와 답변을 분리하기 어려움

### 레벨 3: Structured (XML 태그) ⭐ 권장

`<thinking>`, `<answer>` 태그로 사고와 답변 분리.

```yaml
질문: 이 계약을 분석하세요.

Think before you answer in <thinking> tags. First, identify potential risks.
Then, evaluate the severity of each risk. Finally, provide recommendations in
<answer> tags based on your analysis.
```

**장점**:
- 명확한 분리
- 파싱 용이
- 가장 신뢰할 수 있음

**단점**: 약간 긴 프롬프트

## 실전 예시

### 예시 1: 금융 분석

#### Without CoT
```
User: You're a financial advisor. A client wants to invest $10,000. They can
choose between:
A) A stock that historically returns 12% annually but is volatile
B) A bond that guarantees 6% annually

The client needs the money in 5 years for a down payment on a house. Which
option do you recommend?
```

**출력 (표면적)**:
```
I would recommend option B, the bond that guarantees a 6% annual return. Here's why:

1. Certainty: The bond offers a guaranteed 6% annual return, which provides
   certainty in financial planning.
2. Risk aversion: Since the client needs this money for an important life event,
   they likely have a low risk tolerance.
3. Time horizon: With only 5 years, there's less time to recover from potential
   stock market downturns.

While the stock's historical 12% return is attractive, past performance doesn't
guarantee future results.
```

#### With CoT
```
User: You're a financial advisor. A client wants to invest $10,000. They can
choose between:
A) A stock that historically returns 12% annually but is volatile
B) A bond that guarantees 6% annually

The client needs the money in 5 years for a down payment on a house. Which
option do you recommend? Think step-by-step.
```

**출력 (심층 분석)**:
```
<thinking>
1. Understand the client's goal and timeline:
   - Goal: Down payment for a house
   - Timeline: 5 years
   - Implication: Short-term, high-priority financial goal. Client cannot afford
     significant risk or volatility.

2. Analyze Option A (Stock):
   - Pro: Higher historical return (12% annually)
   - Con: Volatile (implying potential for significant gains or losses)
   - Calculate potential 5-year return:
     - Best case (12% annually): $10,000 * (1.12)^5 ≈ $17,623.42
     - Worst case (market crash): Could lose substantial portion, e.g., 50% = $5,000

3. Analyze Option B (Bond):
   - Pro: Guaranteed return (6% annually)
   - Con: Lower return compared to historical stock performance
   - Calculate 5-year return:
     - Guaranteed: $10,000 * (1.06)^5 ≈ $13,382.25

4. Consider risk tolerance:
   - Goal is a house down payment (essential, not discretionary)
   - Short timeline (5 years) limits ability to recover from market downturns
   - Conclusion: Client likely has low risk tolerance

5. Historical perspective:
   - Stock's 12% is historical, not guaranteed
   - In 5-year periods, stock market can vary wildly:
     - 2003-2007: S&P 500 up ~82%
     - 2007-2011: S&P 500 down ~2%
   - Conclusion: Past performance doesn't guarantee future results

6. Final analysis:
   - Option A: Higher potential return but unacceptable risk of not meeting goal
   - Option B: Guaranteed to meet ~80% of best-case stock scenario, 100% certainty
</thinking>

<answer>
I recommend Option B, the bond with a guaranteed 6% annual return. While the
stock's historical 12% return is tempting, the bond ensures you'll have $13,382.25
in 5 years for your house down payment. Given the importance and short timeline
of your goal, the stock's volatility poses an unacceptable risk. The bond provides
certainty, which is invaluable for such a crucial financial milestone.
</answer>
```

## Best Practices

1. **수동 CoT를 적용할 때 출력 구분** - `<thinking>`·`<answer>` 태그로 추론 서술과 최종 답을 나눕니다. 적용 여부와 모델별 예외는 아래 "CoT 분기"를 따릅니다
2. **구조화된 태그 사용** - `<thinking>`, `<answer>` 태그로 파싱 용이
3. **작업 복잡도에 맞추기** - 단순 작업에는 복잡한 CoT 불필요
4. **사고 단계 안내** - Claude가 무엇을 고려해야 할지 명시
5. **다른 기법과 결합** - XML 태그, 예시 등과 함께 사용

---

## CoT 분기: 모델 유형별 주의사항 (2025~2026)

> **핵심**: CoT는 죽지 않았지만, 모든 모델에 동일하게 적용할 수 없습니다.

### 모델 유형별 CoT 전략

| 모델 유형 | CoT 효과 | 권장 전략 |
|-----------|---------|----------|
| 비추론 모델 (소형·오픈웨이트, thinking을 끈 Gemma 4·Qwen 3.8 등) | ✅ 복잡한 과제에서 효과, 과제별 평가 필요 | Structured CoT (XML 태그) 사용 |
| GPT 추론 모델 (GPT-5.6·GPT-6) | ⚠️ 추론 유도 문구는 불필요, 때로 방해 가능 | 추론을 유도하려고 덧붙인 "think step by step"·"explain your reasoning"은 생략. `reasoning.effort`로 내장 추론 제어 |
| DeepSeek-R1 | 공급자 권고가 다름 | 공식 사용 권고는 수학 문제에 "Please reason step by step, and put your final answer within \boxed{}." 같은 지시를 넣으라고 안내 ([DeepSeek-R1 사용 권고](https://github.com/deepseek-ai/DeepSeek-R1#usage-recommendations)) |
| Claude 5 (Opus 5.5·Fable 5.1·Opus 5) | ⚠️ thinking이 켜져 있으면 일반 지시 우선, 내부 추론 재현 요구는 거절 대상 | 손으로 쓴 단계별 사고 지시보다 일반 지시를 우선. 수동 CoT는 thinking을 끈 경우의 대안이나, Opus 5는 낮은 effort로 thinking을 켜 두기를 우선 권고. 내부 추론을 답변에 재현하게 하는 지시는 `reasoning_extraction` 거절 대상이라 제거하고 thinking 블록(`display: "summarized"`)을 읽음 → [claude-5-specifics.md](claude-5-specifics.md) |

결과의 근거, 변경 이유, 테스트 결과를 설명하라는 요청은 모델과 관계없이 유지합니다. 위 처방이 겨냥하는 것은 추론을 유도하려고 덧붙인 문구와 내부 추론을 재현하게 하는 요구입니다.

### GPT 추론 모델에서 추가 CoT 지시를 생략하는 이유

OpenAI는 GPT 추론 모델이 내부에서 추론하므로, 추론을 유도하려고 덧붙인 "think step by step"·"explain your reasoning"은 불필요하다고 안내합니다. 이런 지시가 성능을 높이지 못하거나 때로 방해할 수 있다는 권고이며, 모든 과제에서 이득이 없다는 실험 결과를 뜻하지 않습니다. 해당 문서 본문은 o 시리즈를 중심으로 설명하므로, GPT-6에서는 출발 원칙으로 삼고 과제별 결과로 확인합니다. 예시 없는 간결한 프롬프트에서 시작하고 필요하면 예시를 추가합니다([OpenAI 추론 모범 사례](https://developers.openai.com/api/docs/guides/reasoning-best-practices#how-to-prompt-reasoning-models-effectively)).

```yaml
# ❌ GPT 추론 모델에서 비권장
system_prompt: |
  Think step by step before answering.

# ✅ GPT 추론 모델에서 권장
system_prompt: |
  다음 문제를 풀어주세요.
  # reasoning_effort 파라미터로 추론 깊이 제어
```

### Claude thinking과의 관계

Claude 5 세대는 adaptive thinking이 기본으로 켜져 있습니다. Opus 5.5·Fable 5·5.1은 끌 수 없고, Opus 5·Haiku 5.5는 effort `high` 이하에서만 `thinking: {"type": "disabled"}`로 끌 수 있습니다. Sonnet 5.5의 가장 낮은 사고 설정은 `between_tools`이며, effort가 `high` 이하일 때 허용됩니다. 켜져 있을 때는:
- 모델이 자동으로 구조적 추론을 수행
- 수동 CoT 프롬프팅 대신 `output_config.effort`로 깊이 제어
- 추론 감사(audit)가 필요하면 thinking 블록(`display: "summarized"`)을 읽고, 내부 추론을 답변에 재현하게 하지 않기. 일반적인 결과의 근거 설명은 요청할 수 있음

### 2026년 CoT 사용 가이드라인

1. **먼저 모델 유형 확인** — GPT 추론 모델이면 추론 유도용 CoT 문구 생략
2. **API 파라미터 우선** — `reasoning.effort`, `output_config.effort` 등 내장 기능 활용
3. **표준 모델과 thinking을 끈 모델에서 수동 CoT 검토** — 복잡한 작업(수학, 다단계 분석)에 한정. 단, Opus 5는 낮은 effort로 thinking을 켜 두기를 우선
4. **CoT와 예시의 조합** — GPT 추론 모델은 예시 없이 시작하고 필요하면 예시를 추가. Claude는 thinking을 켠 상태에서도 예시를 쓸 수 있고, 예시 안의 `<thinking>` 태그로 추론 방식을 보여 줌

## 참고 자료

- [Anthropic 공식 가이드](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices#leverage-thinking-and-interleaved-thinking-capabilities)
- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)