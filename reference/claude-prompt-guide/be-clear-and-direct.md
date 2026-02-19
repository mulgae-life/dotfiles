# Be Clear, Direct, and Detailed

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/be-clear-and-direct

---

## The Golden Rule

**Show your prompt to a colleague**, ideally someone who has minimal context on the task, and ask them to follow the instructions. If they're confused, Claude will likely be too.

## Core Principles

When interacting with Claude, think of it as a brilliant but very new employee (with amnesia) who needs explicit instructions. Like any new employee, Claude does not have context on your norms, styles, guidelines, or preferred ways of working.

The more precisely you explain what you want, the better Claude's response will be.

## How to Be Clear, Contextual, and Specific

- **Give Claude contextual information:**
  - What the task results will be used for
  - What audience the output is meant for
  - What workflow the task is part of, and where this task belongs in that workflow
  - The end goal of the task, or what a successful task completion looks like

- **Be specific about what you want Claude to do:** If you want Claude to output only code and nothing else, say so.

- **Provide instructions as sequential steps:** Use numbered lists or bullet points to better ensure that Claude carries out the task the exact way you want it to.

## Examples

### Example 1: Anonymizing Customer Feedback

| Unclear Prompt | Clear Prompt |
|----------------|--------------|
| Please remove all personally identifiable information from these customer feedback messages: {{FEEDBACK_DATA}} | Your task is to anonymize customer feedback for our quarterly review.<br/><br/>Instructions:<br/>1. Replace all customer names with "CUSTOMER_[ID]"<br/>2. Replace email addresses with "EMAIL_[ID]@example.com"<br/>3. Redact phone numbers as "PHONE_[ID]"<br/>4. If a message mentions a specific product, leave it intact<br/>5. If no PII is found, copy the message verbatim<br/>6. Output only the processed messages, separated by "---"<br/><br/>Data to process: {{FEEDBACK_DATA}} |

**Result without clarity**: Claude still makes mistakes, such as leaving in a customer's name.

**Result with clarity**: All PII properly anonymized with consistent ID format.

### Example 2: Crafting a Marketing Email

| Vague Prompt | Specific Prompt |
|--------------|-----------------|
| Write a marketing email for our new AcmeCloud features. | Your task is to craft a targeted marketing email for our Q3 AcmeCloud feature release.<br/><br/>Instructions:<br/>1. Write for this target audience: Mid-size tech companies (100-500 employees) upgrading from on-prem to cloud<br/>2. Highlight 3 key new features: advanced data encryption, cross-platform sync, and real-time collaboration<br/>3. Tone: Professional yet approachable. Emphasize security, efficiency, and teamwork<br/>4. Include a clear CTA: Free 30-day trial with priority onboarding<br/>5. Subject line: Under 50 chars, mention "security" and "collaboration"<br/>6. Personalization: Use {{COMPANY_NAME}} and {{CONTACT_NAME}} variables<br/><br/>Structure:<br/>1. Subject line<br/>2. Email body (150-200 words)<br/>3. CTA button text |

**Vague prompt issues**: Claude makes up details to fill gaps, includes irrelevant features.

**Specific prompt benefits**: Targeted message, appropriate tone, correct features, proper structure.

### Example 3: Incident Response

| Vague Prompt | Detailed Prompt |
|--------------|-----------------|
| Analyze this AcmeCloud outage report and summarize the key points.<br/><br/>{{REPORT}} | Analyze this AcmeCloud outage report. Skip the preamble. Keep your response terse and write only the bare bones necessary information. List only:<br/>1) Cause<br/>2) Duration<br/>3) Impacted services<br/>4) Number of affected users<br/>5) Estimated revenue loss<br/><br/>Here's the report: {{REPORT}} |

**Vague output**: Long summary with unnecessary context and formatting.

**Detailed output**:
```
1) Cause: Misconfigured load balancer update
2) Duration: 4h 37m (09:15-13:52 UTC, May 15)
3) Impacted: Core sync, admin dashboard (down); mobile app (partial)
4) Affected users: 1.3M (68% of base)
5) Est. revenue loss: $420,000
```

## Best Practices

1. **Provide context** about task purpose and audience
2. **Be explicit** about output format and constraints
3. **Use numbered steps** for multi-step tasks
4. **Specify what NOT to do** when relevant
5. **Define success criteria** clearly

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
