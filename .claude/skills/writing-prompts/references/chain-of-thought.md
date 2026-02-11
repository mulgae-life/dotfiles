# Chain of Thought (CoT) 프롬프팅

복잡한 작업에서 모델이 단계별로 추론하도록 유도하는 기법입니다.

## 개요

Chain of Thought (CoT) 프롬프팅은 **OpenAI와 Anthropic 모두에서 권장**하는 핵심 기법입니다.

**핵심 원칙**: 모델이 사고 과정을 **출력**해야 실제로 추론이 발생합니다.

## 플랫폼별 용어

| 플랫폼 | 용어 | 표현 |
|--------|------|------|
| **OpenAI** | Chain of Thought | "Think step-by-step" |
| **Anthropic** | Let Claude think | "Think step-by-step" / 3단계 구분 |
| **공통** | ✅ 동일 개념 | 사고 과정 출력 필수 |

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

1. **항상 사고 출력** - 출력 없이는 사고가 발생하지 않음
2. **구조화된 태그 사용** - `<thinking>`, `<answer>` 태그로 파싱 용이
3. **작업 복잡도에 맞추기** - 단순 작업에는 복잡한 CoT 불필요
4. **사고 단계 안내** - Claude가 무엇을 고려해야 할지 명시
5. **다른 기법과 결합** - XML 태그, 예시 등과 함께 사용

## 참고 자료

- [Anthropic 공식 가이드](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/chain-of-thought)
- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)