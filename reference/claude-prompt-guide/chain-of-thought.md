# Let Claude Think (Chain of Thought Prompting) to Increase Performance

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/chain-of-thought

---

## Overview

When faced with complex tasks like research, analysis, or problem-solving, giving Claude space to think can dramatically improve its performance. This technique, known as **chain of thought (CoT) prompting**, encourages Claude to break down problems step-by-step, leading to more accurate and nuanced outputs.

## Before Implementing CoT

### Why Let Claude Think?

- **Accuracy**: Stepping through problems reduces errors, especially in math, logic, analysis, or generally complex tasks
- **Coherence**: Structured thinking leads to more cohesive, well-organized responses
- **Debugging**: Seeing Claude's thought process helps you pinpoint where prompts may be unclear

### Why Not Let Claude Think?

- Increased output length may impact latency
- Not all tasks require in-depth thinking. Use CoT judiciously to ensure the right balance of performance and latency

**Tip**: Use CoT for tasks that a human would need to think through, like complex math, multi-step analysis, writing complex documents, or decisions with many factors.

## How to Prompt for Thinking

The chain of thought techniques below are **ordered from least to most complex**. Less complex methods take up less space in the context window, but are also generally less powerful.

**Critical**: Always have Claude output its thinking. Without outputting its thought process, no thinking occurs!

### 1. Basic Prompt

Include "Think step-by-step" in your prompt.

**Pros**: Simple to implement
**Cons**: Lacks guidance on *how* to think (not ideal for app-specific tasks)

**Example:**
```
Draft personalized emails to donors asking for contributions to this year's
Care for Kids program.

Program information: {{PROGRAM_DETAILS}}
Donor information: {{DONOR_DETAILS}}

Think step-by-step before you write the email.
```

### 2. Guided Prompt

Outline specific steps for Claude to follow in its thinking process.

**Pros**: More structured than basic
**Cons**: Lacks structuring to make it easy to strip out and separate the answer from the thinking

**Example:**
```
Draft personalized emails to donors asking for contributions to this year's
Care for Kids program.

Program information: {{PROGRAM_DETAILS}}
Donor information: {{DONOR_DETAILS}}

Think before you write the email. First, think through what messaging might
appeal to this donor given their donation history and which campaigns they've
supported in the past. Then, think through what aspects of the Care for Kids
program would appeal to them, given their history. Finally, write the
personalized donor email using your analysis.
```

### 3. Structured Prompt

Use XML tags like `<thinking>` and `<answer>` to separate reasoning from the final answer.

**Pros**: Easy to parse, clear separation, most reliable
**Cons**: Slightly longer prompt

**Example:**
```
Draft personalized emails to donors asking for contributions to this year's
Care for Kids program.

Program information: {{PROGRAM_DETAILS}}
Donor information: {{DONOR_DETAILS}}

Think before you write the email in <thinking> tags. First, think through what
messaging might appeal to this donor given their donation history and which
campaigns they've supported in the past. Then, think through what aspects of
the Care for Kids program would appeal to them, given their history. Finally,
write the personalized donor email in <email> tags, using your analysis.
```

## Example: Financial Analysis

### Without Thinking

**Prompt:**
```
You're a financial advisor. A client wants to invest $10,000. They can choose
between two options:
A) A stock that historically returns 12% annually but is volatile
B) A bond that guarantees 6% annually

The client needs the money in 5 years for a down payment on a house. Which
option do you recommend?
```

**Output (superficial):**
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

### With Thinking

**Prompt:**
```
You're a financial advisor. A client wants to invest $10,000. They can choose
between two options:
A) A stock that historically returns 12% annually but is volatile
B) A bond that guarantees 6% annually

The client needs the money in 5 years for a down payment on a house. Which
option do you recommend? Think step-by-step.
```

**Output (thorough):**
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

1. **Always output thinking** - Claude doesn't think without outputting
2. **Use structured tags** - `<thinking>` and `<answer>` for easy parsing
3. **Match complexity to task** - Simple tasks don't need complex CoT
4. **Guide the thinking steps** - Tell Claude what to consider
5. **Combine with other techniques** - XML tags, examples, etc.

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
