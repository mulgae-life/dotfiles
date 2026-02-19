# Use XML Tags to Structure Your Prompts

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/use-xml-tags

---

## Overview

When your prompts involve multiple components like context, instructions, and examples, XML tags can be a game-changer. They help Claude parse your prompts more accurately, leading to higher-quality outputs.

**XML tip**: Use tags like `<instructions>`, `<example>`, and `<formatting>` to clearly separate different parts of your prompt. This prevents Claude from mixing up instructions with examples or context.

## Why Use XML Tags?

- **Clarity**: Clearly separate different parts of your prompt and ensure your prompt is well structured
- **Accuracy**: Reduce errors caused by Claude misinterpreting parts of your prompt
- **Flexibility**: Easily find, add, remove, or modify parts of your prompt without rewriting everything
- **Parseability**: Having Claude use XML tags in its output makes it easier to extract specific parts of its response by post-processing

**Note**: There are no canonical "best" XML tags that Claude has been trained with in particular, although we recommend that your tag names make sense with the information they surround.

## Tagging Best Practices

1. **Be consistent**: Use the same tag names throughout your prompts, and refer to those tag names when talking about the content (e.g., "Using the contract in <contract> tags...")

2. **Nest tags**: You should nest tags `<outer><inner></inner></outer>` for hierarchical content

**Power user tip**: Combine XML tags with other techniques like multishot prompting (`<examples>`) or chain of thought (`<thinking>`, `<answer>`). This creates super-structured, high-performance prompts.

## Example: Generating Financial Reports

### Without XML Tags

**Prompt:**
```
You're a financial analyst at AcmeCorp. Generate a Q2 financial report for our
investors. Include sections on Revenue Growth, Profit Margins, and Cash Flow,
like with this example from last year: {{Q1_REPORT}}. Use data points from
this spreadsheet: {{SPREADSHEET_DATA}}. The report should be extremely concise,
to the point, professional, and in list format. It should highlight both
strengths and areas for improvement.
```

**Issues:**
- Claude misunderstands where the Q1 report example stops and instructions begin
- Generates long narrative format instead of list format
- Mixes up what data goes where

### With XML Tags

**Prompt:**
```
You're a financial analyst at AcmeCorp. Generate a Q2 financial report for our investors.

AcmeCorp is a B2B SaaS company. Our investors value transparency and actionable insights.

Use this data for your report:
<data>{{SPREADSHEET_DATA}}</data>

<instructions>
1. Include sections: Revenue Growth, Profit Margins, Cash Flow.
2. Highlight strengths and areas for improvement.
</instructions>

Make your tone concise and professional. Follow this structure:
<formatting_example>{{Q1_REPORT}}</formatting_example>
```

**Result:**
```
Q2 Financial Report for AcmeCorp Investors

Revenue Growth:
- Q2 revenue: $15.2M (22% YoY ↑)
- Enterprise clients: 30% ↑
- SMB segment: 5% ↓
  Action: Targeted Q3 marketing

Profit Margins:
- Gross margin: 72% (3% ↑ from Q1)
  Reason: Infrastructure optimizations
- EBITDA margin: 18% (2% ↓)
  Reason: R&D investment in AI features

Cash Flow:
- Operating cash flow: $4.1M (strong)
- Cash reserves: $28M (15-month runway)
- Customer acquisition cost: 20% ↑
  Action: Optimize sales strategies

Outlook:
- Core financials: Robust
- Q3 focus: Revitalize SMB, optimize sales

Management remains committed to balancing growth investments with financial discipline.
```

## Example: Legal Contract Analysis

### Without XML Tags

**Prompt:**
```
Analyze this software licensing agreement for potential risks and liabilities:
{{CONTRACT}}. Focus on indemnification, limitation of liability, and IP ownership
clauses. Also, note any unusual or concerning terms. Here's our standard contract
for reference: {{STANDARD_CONTRACT}}. Give a summary of findings and
recommendations for our legal team.
```

**Issues:**
- Disorganized analysis
- Misses key points
- Hard to extract actionable items

### With XML Tags

**Prompt:**
```
Analyze this software licensing agreement for legal risks and liabilities.

We're a multinational enterprise considering this agreement for our core data infrastructure.

<agreement>
{{CONTRACT}}
</agreement>

This is our standard contract for reference:
<standard_contract>{{STANDARD_CONTRACT}}</standard_contract>

<instructions>
1. Analyze these clauses:
   - Indemnification
   - Limitation of liability
   - IP ownership

2. Note unusual or concerning terms.

3. Compare to our standard contract.

4. Summarize findings in <findings> tags.

5. List actionable recommendations in <recommendations> tags.
</instructions>
```

**Result:**
```
<findings>
1. Indemnification (Clause 8):
   - Issue: Overly broad. We indemnify vendor against "any and all claims"
     arising from our use.
   - Risk: Could hold us liable even for vendor's negligence or product defects.
   - Deviation: Our standard limits indemnity to claims arising from our
     violation of agreement.

2. Limitation of Liability (Clause 9):
   - Issue: Caps all damages at $500, including direct damages.
   - Risk: Grossly inadequate for enterprise use. A critical failure could cost millions.
   - Deviation: Our standard allows for direct damages up to 12 months of fees paid.

3. IP Ownership (Clause 12):
   - Issue: Grants vendor joint ownership of our modifications/integrations.
   - Risk: Vendor could use or sell our proprietary algorithms or data insights.
   - Deviation: Our standard retains full ownership of our work.

4. Unusual Terms:
   - Clause 5.3: Vendor can use our usage data for "any purpose."
   - Clause 7.2: Vendor can terminate for "convenience" with only 7 days' notice.
   - Clause 11: No warranties of any kind, even for basic merchantability.
</findings>

<recommendations>
1. Reject this agreement. Risks far outweigh benefits for an enterprise.
2. Counter-propose:
   - Indemnification: Limit to claims arising from our violation of agreement.
   - Liability: Cap at 12 months' fees for direct damages; negotiate for indirect.
   - IP: Full ownership of our modifications/integrations.
   - Data Use: Restrict to service improvement only.
   - Termination: Minimum 90 days' notice; only for cause.
   - Warranties: Demand basic merchantability and fitness for purpose.
3. If vendor refuses, explore alternative providers or in-house solutions.
4. Engage legal counsel for contract negotiation given high stakes.
</recommendations>
```

## Common Tag Patterns

### Input/Output Structure
```xml
<input>
{{USER_DATA}}
</input>

<output_format>
1. Summary (1-2 sentences)
2. Key findings (bullet points)
3. Recommendation
</output_format>
```

### Multi-Document Analysis
```xml
<documents>
  <document index="1">
    <source>annual_report_2023.pdf</source>
    <content>{{ANNUAL_REPORT}}</content>
  </document>
  <document index="2">
    <source>competitor_analysis.xlsx</source>
    <content>{{COMPETITOR_ANALYSIS}}</content>
  </document>
</documents>
```

### Chain of Thought
```xml
<thinking>
[Claude's reasoning process]
</thinking>

<answer>
[Final answer]
</answer>
```

### Examples
```xml
<examples>
  <example id="1">
    <input>...</input>
    <output>...</output>
  </example>
  <example id="2">
    <input>...</input>
    <output>...</output>
  </example>
</examples>
```

## Best Practices

1. **Use descriptive tag names** - `<customer_data>` is better than `<data>`
2. **Be consistent** - Use same tags throughout a prompt
3. **Nest when appropriate** - Hierarchy helps Claude understand relationships
4. **Reference tags explicitly** - "Using the data in <data> tags, analyze..."
5. **Combine with other techniques** - XML + examples + CoT = powerful prompts

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
