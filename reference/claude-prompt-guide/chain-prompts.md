# Chain Complex Prompts for Stronger Performance

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/chain-prompts

---

## Overview

When working with complex tasks, Claude can sometimes drop the ball if you try to handle everything in a single prompt. Chain of thought (CoT) prompting is great, but what if your task has multiple distinct steps that each require in-depth thought?

Enter **prompt chaining**: breaking down complex tasks into smaller, manageable subtasks.

## Why Chain Prompts?

1. **Accuracy**: Each subtask gets Claude's full attention, reducing errors
2. **Clarity**: Simpler subtasks mean clearer instructions and outputs
3. **Traceability**: Easily pinpoint and fix issues in your prompt chain

## When to Chain Prompts

Use prompt chaining for multi-step tasks like research synthesis, document analysis, or iterative content creation. When a task involves multiple transformations, citations, or instructions, chaining prevents Claude from dropping or mishandling steps.

**Remember:** Each link in the chain gets Claude's full attention!

**Debugging tip**: If Claude misses a step or performs poorly, isolate that step in its own prompt. This lets you fine-tune problematic steps without redoing the entire task.

## How to Chain Prompts

1. **Identify subtasks**: Break your task into distinct, sequential steps
2. **Structure with XML for clear handoffs**: Use XML tags to pass outputs between prompts
3. **Have a single-task goal**: Each subtask should have a single, clear objective
4. **Iterate**: Refine subtasks based on Claude's performance

### Example Chained Workflows

- **Multi-step analysis**: See the legal and business examples below
- **Content creation pipelines**: Research → Outline → Draft → Edit → Format
- **Data processing**: Extract → Transform → Analyze → Visualize
- **Decision-making**: Gather info → List options → Analyze each → Recommend
- **Verification loops**: Generate content → Review → Refine → Re-review

**Optimization tip**: For tasks with independent subtasks (like analyzing multiple docs), create separate prompts and run them in parallel for speed.

### Advanced: Self-Correction Chains

You can chain prompts to have Claude review its own work! This catches errors and refines outputs, especially for high-stakes tasks.

#### Example: Self-Correcting Research Summary

**Prompt 1: Generate Summary**
```
Summarize this medical research paper.

<paper>{{RESEARCH_PAPER}}</paper>

Focus on methodology, findings, and clinical implications.
```

**Output 1 (stored as {{SUMMARY}}):**
```
Methodology: Double-blind RCT with 500 Type 2 diabetes patients. Group A (n=250)
received novel GLP-1/GIP dual agonist; Group B (n=250) received standard GLP-1
agonist. 24-week trial, primary endpoint: HbA1c reduction.

Findings:
- Group A: 1.8% mean HbA1c reduction
- Group B: 1.1% mean HbA1c reduction
- 68% of Group A vs. 52% of Group B achieved HbA1c <7%
- Group A: 5.2kg mean weight loss
- Group B: 3.1kg mean weight loss

Safety: Similar adverse event profiles, no serious events attributed to treatment.

Clinical Implications: Dual agonist shows superior glycemic control and weight
loss compared to standard therapy. Could be a game-changer, especially for obese
diabetics.
```

**Prompt 2: Review Summary**
```
Your task is to provide feedback on a research paper summary. Here is a summary
of a medical research paper:

<summary>{{SUMMARY}}</summary>

Here is the research paper:
<paper>{{RESEARCH_PAPER}}</paper>

Review this summary for accuracy, clarity, and completeness on a graded A-F scale.
```

**Output 2 (stored as {{FEEDBACK}}):**
```
1. Accuracy: A
   - Correctly reported key stats: HbA1c reductions, weight loss.
   - Accurately noted safety profile and lack of serious adverse events.
   - Assertion of "game-changer" is justified by significantly better outcomes.

2. Clarity: A-
   - Concise and well-structured with clear sections.
   - Good use of comparative language.
   - Minor issue: Acronyms like "RCT," "GLP-1," and "GIP" not defined.

3. Completeness: B+
   - Covers all requested areas: methodology, findings, clinical implications.
   - Missing: Baseline characteristics of groups (were they well-matched?).
   - Missing: Any secondary endpoints (e.g., blood pressure, lipids).
   - Consider: Long-term implications or need for further research.

Overall, the summary is accurate and clear. To elevate to A+, define acronyms,
mention group baseline stats, note any secondary outcomes, and briefly touch on
the need for long-term studies.
```

**Prompt 3: Improve Summary**
```
Your task is to improve a paper summary given feedback. Here is the first draft:

<summary>{{SUMMARY}}</summary>

Here is the research paper:
<paper>{{RESEARCH_PAPER}}</paper>

Here is the feedback:
<feedback>{{FEEDBACK}}</feedback>

Update the summary based on the feedback.
```

**Final Output:**
```
Methodology: Double-blind randomized controlled trial (RCT) with 500 Type 2 diabetes
patients. Group A (n=250) received a novel glucagon-like peptide-1/glucose-dependent
insulinotropic polypeptide (GLP-1/GIP) dual agonist; Group B (n=250) received a
standard GLP-1 agonist. The 24-week trial's primary endpoint was HbA1c reduction.
Groups were well-matched for age, BMI, and baseline HbA1c.

Findings:
- Group A: 1.8% mean HbA1c reduction
- Group B: 1.1% mean HbA1c reduction
- 68% of Group A vs. 52% of Group B achieved HbA1c <7%
- Group A: 5.2kg mean weight loss
- Group B: 3.1kg mean weight loss

Secondary endpoints showed improvements in blood pressure and lipid profiles for
both groups, with Group A showing slightly better results.

Safety: Similar adverse event profiles, with no serious events attributed to either
treatment.

Clinical Implications: The dual GLP-1/GIP agonist demonstrates superior glycemic
control and weight loss compared to standard GLP-1 therapy. These results suggest
it could be a significant advancement, particularly for obese diabetics. However,
longer-term studies are needed to confirm sustained efficacy and safety, as well
as to investigate potential benefits on cardiovascular outcomes.
```

## Example: Legal Contract Analysis

### Without Chaining (Single Prompt)

**Prompt:**
```
You're our Chief Legal Officer. Review this SaaS contract for risks, focusing on
data privacy, SLAs, and liability caps.

<contract>{{CONTRACT}}</contract>

Then draft an email to the vendor with your concerns and proposed changes.
```

**Issues:**
- Claude misses the instruction to provide proposed changes in its email draft
- Analysis is superficial
- Email lacks specific recommendations

### With Chaining (Multi-Step)

**Prompt 1: Analyze Risks**
```
You're our Chief Legal Officer. Review this SaaS contract for risks, focusing on
data privacy, SLAs, and liability caps.

<contract>{{CONTRACT}}</contract>

Output your findings in <risks> tags.
```

**Output 1 ({{CONCERNS}}):**
```
<risks>
1. Data Privacy (Section 7):
   - Issue: Vendor has broad rights to use client data for "service improvement."
   - Risk: Could lead to unauthorized data sharing or monetization of client data.
   - Impact: Potential breach of client trust, regulatory fines (GDPR, CCPA).

2. SLAs (Section 5):
   - Issue: 99.5% uptime guarantee is below industry standard (typically 99.99%).
   - Risk: Up to 43.8 hours of downtime per year vs. 52.6 minutes at 99.99%.
   - Impact: Operational disruptions, revenue loss, client dissatisfaction.

3. Liability (Section 9):
   - Issue: Liability cap set at 3 months of fees.
   - Risk: Inadequate for potential data breaches, IP theft, or prolonged service failures.
   - Impact: Insufficient compensation for damages that could far exceed the cap.
</risks>
```

**Prompt 2: Draft Email**
```
Draft an email to a SaaS product vendor outlining the following concerns and
proposing changes. Here are the concerns:

<concerns>{{CONCERNS}}</concerns>
```

**Output 2 ({{EMAIL}}):**
```
Dear {{VENDOR}},

After a thorough review of the proposed SaaS agreement, our legal team has identified
several high-priority concerns that must be addressed before we can proceed:

1. Data Privacy (Section 7):
   - Current: Broad rights to use client data for "service improvement."
   - Concern: Potential unauthorized data sharing or monetization.
   - Proposed Change: Limit data use to direct service provision. Any use for
     improvement, analytics, or marketing must be opt-in, revocable, and anonymized.

2. SLAs (Section 5):
   - Current: 99.5% uptime guarantee.
   - Concern: Up to 43.8 hours of downtime per year, risking operational disruptions.
   - Proposed Change: 99.99% uptime with tiered service credits. E.g., 10% credit
     for <99.99%, 25% for <99.9%, 50% for <99.5%.

3. Liability (Section 9):
   - Current: Cap at 3 months of fees.
   - Concern: Grossly inadequate for data breaches, IP theft, or prolonged outages.
   - Proposed Change: 12 months' fees for general liability. Uncapped for data
     breaches, willful misconduct, IP infringement.

These changes are non-negotiable for us. They align with industry standards and our
commitment to data security and operational excellence.

Please have your legal team review and incorporate these changes. We're happy to
discuss further.

Best regards,
{{CLO_NAME}}
```

**Prompt 3: Review Email**
```
Your task is to review an email and provide feedback. Here is the email:

<email>{{EMAIL}}</email>

Give feedback on tone, clarity, and professionalism.
```

**Output 3:**
```
1. Tone:
   - Professional and assertive without being confrontational.
   - Use of "non-negotiable" is strong but justified given the criticality.
   - Collaborative language balances firmness.

2. Clarity:
   - Excellent structuring: Current state, concern, and proposed change for each issue.
   - Technical terms are appropriate for B2B SaaS context.
   - Action items are clear.

3. Professionalism:
   - Focuses on mutual benefit and industry standards.
   - Mentions broader responsibilities, elevating the discussion.
   - Offers further discussion, showing commitment.

Overall, the email strikes the right balance. No revisions needed; proceed with sending.
```

## Example: Business Strategy Analysis

**Prompt 1: Analyze Strategy**
```
As a senior solutions architect, review and analyze this multitenancy strategy for
our new enterprise SaaS product.

<strategy>{{STRATEGY}}</strategy>

Focus on scalability, security, and cost-effectiveness.
```

**Prompt 2: Draft Review Document**
```
Draft a strategy review document for engineering leadership based on this analysis:

<strategy>{{STRATEGY}}</strategy>
<analysis>{{ANALYSIS}}</analysis>

Include an executive summary, detailed analysis, and recommendations.
```

**Prompt 3: Grade Document**
```
Grade this strategy review document for clarity, actionability, and alignment with
enterprise priorities.

<priorities>{{PRIORITIES}}</priorities>
<strategy_doc>{{STRATEGY_DOC}}</strategy_doc>
```

## Best Practices

1. **Break tasks into 2-5 steps** - Not too many, not too few
2. **Use XML tags for handoffs** - `<analysis>{{STEP1_OUTPUT}}</analysis>`
3. **Single objective per step** - Don't combine unrelated tasks
4. **Sequential when dependent** - Parallel when independent
5. **Include full context** - Each prompt should have all needed info
6. **Review steps can catch errors** - Add review prompts for quality
7. **Test each step individually** - Debug one step at a time

## Common Chain Patterns

### Analysis → Draft → Review
```
1. Analyze data
2. Draft recommendations
3. Review and refine
```

### Extract → Transform → Output
```
1. Extract key information
2. Transform into desired format
3. Output final result
```

### Research → Synthesize → Recommend
```
1. Research multiple sources
2. Synthesize findings
3. Recommend actions
```

### Generate → Critique → Improve
```
1. Generate initial output
2. Critique for quality
3. Improve based on critique
```

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
