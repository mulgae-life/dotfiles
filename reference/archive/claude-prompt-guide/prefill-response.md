# Prefill Claude's Response for Greater Output Control

Source: https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/prefill-claudes-response

---

## Overview

When using Claude, you have the unique ability to guide its responses by prefilling the `Assistant` message. This powerful technique allows you to direct Claude's actions, skip preambles, enforce specific formats like JSON or XML, and even help Claude maintain character consistency in role-play scenarios.

In some cases where Claude is not performing as expected, a few prefilled sentences can vastly improve Claude's performance. **A little prefilling goes a long way!**

**Note**: Prefilling is only available for non-extended thinking modes. It's not currently supported with extended thinking.

## How to Prefill Claude's Response

To prefill, include the desired initial text in the `Assistant` message (Claude's response will continue from where the `Assistant` message leaves off):

```python
import anthropic

client = anthropic.Anthropic()
response = client.messages.create(
    model="claude-sonnet-4-5",
    max_tokens=1024,
    messages=[
        {"role": "user", "content": "What is your favorite color?"},
        {"role": "assistant", "content": "As an AI assistant, I don't have a favorite color, But if I had to pick, it would be green because"}  # Prefill here
    ]
)
```

**Warning**: The prefill content cannot end with trailing whitespace. A prefill like `"As an AI assistant, I "` (with a space at the end) will result in an error.

## Use Case 1: Controlling Output Formatting and Skipping the Preamble

**Power user tip**: Prefilling `{` forces Claude to skip the preamble and directly output the JSON object. This is cleaner, more concise, and easier for programs to parse without additional processing.

For guaranteed JSON output that conforms to a specific schema, consider using [Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs) instead of prefilling.

### Without Prefilling

**Prompt:**
```
Extract the name, size, price, and color from this product description as a JSON object:

<description>
The SmartHome Mini is a compact smart home assistant available in black or white
for only $49.99. At just 5 inches wide, it lets you control lights, thermostats,
and other connected devices via voice or app—no matter where you place it in your
home. This affordable little hub brings convenient hands-free control to your
smart devices.
</description>
```

**Output:**
```
Here's the extracted information in JSON format:

```json
{
  "name": "SmartHome Mini",
  "size": "5 inches wide",
  "price": "$49.99",
  "colors": ["black", "white"]
}
```

I've extracted the following details from the product description:
- **Name**: SmartHome Mini
- **Size**: 5 inches wide
- **Price**: $49.99
- **Colors**: Available in black and white

The JSON object provides a structured format that's easy for programs to parse
and use. Let me know if you need any modifications or have any other questions!
```

### With Prefilling

**Prompt:**
```
user: Extract the name, size, price, and color from this product description as a JSON object:

<description>
The SmartHome Mini is a compact smart home assistant available in black or white
for only $49.99. At just 5 inches wide, it lets you control lights, thermostats,
and other connected devices via voice or app—no matter where you place it in your
home. This affordable little hub brings convenient hands-free control to your
smart devices.
</description>

assistant: {
```

**Output:**
```
"name": "SmartHome Mini",
"size": "5 inches wide",
"price": "$49.99",
"colors": [
  "black",
  "white"
]
}
```

**Benefits:**
- No preamble or explanation
- Pure JSON output
- Easy to parse programmatically
- More concise

## Use Case 2: Maintaining Character in Roleplay Scenarios

**Role-play tip**: Prefilling a bracketed `[ROLE_NAME]` can remind Claude to stay in character, even for longer and more complex conversations. This is especially powerful when combined with role prompting in the `system` parameter.

### Without Prefilling

**Conversation context:** 50 turns into a "Sherlock Holmes" roleplay

**Prompt:**
```
What do you deduce about the owner of this shoe? <image>muddy_shoe.jpg</image>
```

**Output (breaks character):**
```
As an AI assistant, I would be happy to analyze the image of a muddy shoe as if
you had provided it. Here's my deduction...
```

### With Prefilling

**Prompt:**
```
user: What do you deduce about the owner of this shoe? <image>muddy_shoe.jpg</image>

assistant: [Sherlock Holmes]
```

**Output (stays in character):**
```
Ah, what have we here? A most curious specimen, Watson! Let us examine this shoe
with a discerning eye. The mud, you see, is not your common London clay, but rather
the distinctive reddish hue of the iron-rich soil found only in the environs of
Hampstead Heath. And yet, the wear on the sole suggests a gait more suited to the
cobblestones of Whitechapel than the gentle slopes of the Heath.

Now, observe the laces! They are tied with a particular knot favored by those in
the medical profession—doubtless a habit acquired during years of tying surgical
gowns. But the scuff marks on the toe box tell a different tale: they are consistent
with the kicking motion one might employ in the martial arts, specifically Baritsu.

We may conclude, then, that our absent shoe owner is a doctor, possibly a surgeon,
who resides in Whitechapel but frequents Hampstead Heath—perhaps for a secret
Baritsu practice, away from prying eyes. A most intriguing case, Watson! We must
make haste; the game is afoot!
```

## Common Prefilling Patterns

### Force JSON Output
```python
messages=[
    {"role": "user", "content": "Analyze this data and output JSON: {{DATA}}"},
    {"role": "assistant", "content": "{"}
]
```

### Force XML Output
```python
messages=[
    {"role": "user", "content": "Provide a structured analysis"},
    {"role": "assistant", "content": "<analysis>"}
]
```

### Maintain Character
```python
messages=[
    {"role": "user", "content": "What do you think about this?"},
    {"role": "assistant", "content": "[Pirate Captain] Arrr,"}
]
```

### Skip Preamble, Direct Answer
```python
messages=[
    {"role": "user", "content": "List the top 3 benefits"},
    {"role": "assistant", "content": "1."}
]
```

### Force Specific Format
```python
messages=[
    {"role": "user", "content": "Summarize this article"},
    {"role": "assistant", "content": "**Summary:**"}
]
```

## Best Practices

1. **Use sparingly** - Only prefill when you need tight control
2. **No trailing whitespace** - Will cause an error
3. **Combine with clear instructions** - Prefill + good prompt = best results
4. **Test without first** - See if you need prefilling at all
5. **Short prefills work best** - A few characters or words is usually enough

## When to Use Prefilling

✅ **Good use cases:**
- Forcing specific output formats (JSON, XML)
- Skipping preambles for cleaner outputs
- Maintaining character in long roleplays
- Directing Claude to specific response styles
- Ensuring consistent formatting

❌ **Avoid prefilling for:**
- Simple tasks that don't need format control
- When you want Claude's natural preamble/explanation
- Extended thinking mode (not supported)
- When Structured Outputs is a better fit (for strict JSON schema)

## Resources

- [Working with Messages](https://platform.claude.com/docs/en/build-with-claude/working-with-messages)
- [Structured Outputs](https://platform.claude.com/docs/en/build-with-claude/structured-outputs)
- [Prompt library](https://platform.claude.com/docs/en/resources/prompt-library/library)
- [GitHub prompting tutorial](https://github.com/anthropics/prompt-eng-interactive-tutorial)
- [Google Sheets prompting tutorial](https://docs.google.com/spreadsheets/d/19jzLgRruG9kjUQNKtCg1ZjdD6l6weA6qRXG5zLIAhC8)
