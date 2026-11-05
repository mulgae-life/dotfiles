# Use Examples (Multishot Prompting) to Guide Claude's Behavior

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/multishot-prompting

---

## Overview

Examples are your secret weapon shortcut for getting Claude to generate exactly what you need. By providing a few well-crafted examples in your prompt, you can dramatically improve the accuracy, consistency, and quality of Claude's outputs.

This technique, known as **few-shot** or **multishot prompting**, is particularly effective for tasks that require structured outputs or adherence to specific formats.

**Power tip**: Include 3-5 diverse, relevant examples to show Claude exactly what you want. More examples = better performance, especially for complex tasks.

## Why Use Examples?

- **Accuracy**: Examples reduce misinterpretation of instructions
- **Consistency**: Examples enforce uniform structure and style
- **Performance**: Well-chosen examples boost Claude's ability to handle complex tasks

## Crafting Effective Examples

For maximum effectiveness, make sure that your examples are:

- **Relevant**: Your examples mirror your actual use case
- **Diverse**: Your examples cover edge cases and potential challenges, and vary enough that Claude doesn't inadvertently pick up on unintended patterns
- **Clear**: Your examples are wrapped in `<example>` tags (if multiple, nested within `<examples>` tags) for structure

**Tip**: Ask Claude to evaluate your examples for relevance, diversity, or clarity. Or have Claude generate more examples based on your initial set.

## Example: Analyzing Customer Feedback

### Without Examples

**Prompt:**
```
Analyze this customer feedback and categorize the issues. Use these categories:
UI/UX, Performance, Feature Request, Integration, Pricing, and Other.
Also rate the sentiment (Positive/Neutral/Negative) and priority (High/Medium/Low).

Here is the feedback: {{FEEDBACK}}
```

**Issues with output:**
- Claude does not list multiple categories for each feedback item, despite analysis indicating multiple categories
- Includes long explanation when we may not want it
- Inconsistent format

### With Examples

**Prompt:**
```
Our CS team is overwhelmed with unstructured feedback. Your task is to analyze
feedback and categorize issues for our product and engineering teams. Use these
categories: UI/UX, Performance, Feature Request, Integration, Pricing, and Other.
Also rate the sentiment (Positive/Neutral/Negative) and priority (High/Medium/Low).

Here is an example:

<example>
Input: The new dashboard is a mess! It takes forever to load, and I can't find
the export button. Fix this ASAP!
Category: UI/UX, Performance
Sentiment: Negative
Priority: High
</example>

Now, analyze this feedback: {{FEEDBACK}}
```

**Improved output:**
```
1. The new dashboard is a mess! It takes forever to load, and I can't find the
   export button. Fix this ASAP!
   Category: UI/UX, Performance
   Sentiment: Negative
   Priority: High

2. Love the Salesforce integration! But it'd be great if you could add Hubspot too.
   Category: Integration, Feature Request
   Sentiment: Positive
   Priority: Medium

3. Your pricing is ridiculous! $99/mo for basic features? I'm switching to Competitor X.
   Category: Pricing
   Sentiment: Negative
   Priority: High

4. The mobile app keeps crashing when I try to upload large files (>50MB).
   This is critical for our field agents.
   Category: Performance
   Sentiment: Negative
   Priority: High

5. Overall, I'm happy with the product. The UI is intuitive, and the customer
   support is top-notch. Keep it up!
   Category: UI/UX, Other (Customer Support)
   Sentiment: Positive
   Priority: Low
```

## Best Practices

1. **Use 3-5 examples** for most tasks
2. **Include edge cases** in your examples
3. **Maintain consistent formatting** across all examples
4. **Use XML tags** to structure examples clearly:
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

5. **Vary examples** to avoid Claude picking up unintended patterns
6. **Make examples realistic** - use actual use case scenarios

## Tips

- You can ask Claude to evaluate whether your examples are good
- You can ask Claude to generate additional examples based on your initial set
- Combine with other techniques like XML tags and chain of thought for even better results

## Resources

- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
