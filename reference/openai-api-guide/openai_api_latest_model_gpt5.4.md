Using GPT-5.4
=============

Learn best practices, features, and migration guidance for GPT-5.4 and the GPT-5 model family.

> **출처**: [Using GPT-5.4 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model/)
> **날짜**: 2026-03-05

GPT-5.4 is OpenAI's most capable frontier model for complex professional work. Released alongside GPT-5.3 Instant and GPT-5.4 Pro, it integrates coding features from GPT-5.3-Codex into the flagship model.

Key improvements over GPT-5.2:
*   Individual claim hallucination reduced by 33%
*   Full response error rate reduced by 18%
*   Token usage reduced by up to 47% on some tasks
*   End-to-end time reduction in multi-step trajectories
*   Coding capabilities and document understanding
*   Tool use and multi-step instruction following
*   Image perception and multimodal tasks
*   Web search synthesis and fact-finding

Meet the models
---------------

| Model | ID | Snapshot | Description |
|-------|-----|---------|------------|
| GPT-5.4 | `gpt-5.4` | `gpt-5.4-2026-03-05` | General-purpose: reasoning, knowledge, code |
| GPT-5.4 Pro | `gpt-5.4-pro` | - | Enhanced reasoning for difficult problems (Responses API only) |
| GPT-5 Mini | `gpt-5-mini` | - | Cost-optimized reasoning and chat |
| GPT-5 Nano | `gpt-5-nano` | - | High-throughput instruction-following |

Context window and output
-------------------------

| Spec | Value |
|------|-------|
| Context window | 1,050,000 tokens (~1M) |
| Max output tokens | 128,000 |
| Knowledge cutoff | August 31, 2025 |

Pricing
-------

### GPT-5.4 Standard (< 272K tokens)

| Item | Per 1M tokens |
|------|--------------|
| Input | $2.50 |
| Cached Input | $0.25 |
| Output | $15.00 |

### GPT-5.4 Pro Standard (< 272K tokens)

| Item | Per 1M tokens |
|------|--------------|
| Input | $30.00 |
| Output | $180.00 |

**Notes:**
- Prompts exceeding 272K input tokens: 2x input + 1.5x output for the full session
- Batch pricing: 50% of standard (GPT-5.4: Input $1.25 / Output $7.50)
- Reasoning tokens are billed as output tokens but not visible in API
- Regional data residency: +10% uplift

Rate Limits (Tier 5)
--------------------

| Limit | Value |
|-------|-------|
| Requests per minute | 15,000 |
| Tokens per minute | 40,000,000 |

Tier 1: 500 RPM, 500K TPM

Core parameters
---------------

### Reasoning Effort

Controls token generation before response. Default is `none` for GPT-5.4.

```json
{
  "model": "gpt-5.4",
  "input": "your question",
  "reasoning": {
    "effort": "none"
  }
}
```

| Setting | Use Case |
|---------|----------|
| `none` | Fast, cost-sensitive, latency-sensitive tasks |
| `low` | Latency-sensitive with complex instructions |
| `medium` | Balanced reasoning |
| `high` | Tasks requiring stronger reasoning |
| `xhigh` | Long, agentic, reasoning-heavy tasks (use sparingly) |

### Verbosity Control

```json
{
  "model": "gpt-5.4",
  "input": "your prompt",
  "text": {
    "verbosity": "low"
  }
}
```

| Setting | Description |
|---------|------------|
| `low` | Concise responses |
| `medium` | Balanced (default) |
| `high` | Detailed explanations |

### Phase Parameter (Responses API)

For multi-step flows, include `phase` in assistant messages:

```json
{
  "role": "assistant",
  "phase": "commentary",
  "content": "I'll check the logs first."
}
```

- `"commentary"`: intermediate updates before tool calls
- `"final_answer"`: completed responses
- Omitting phase can cause early stopping on complex tasks
- Do not add `phase` to user messages

### API Compatibility

**Only supported with reasoning effort `none`:**
- `temperature`
- `top_p`
- `logprobs`

These parameters raise errors with higher reasoning effort settings.

New features
------------

### Tool Search

Defers tool definitions to runtime, loading only needed schemas. Useful for large tool ecosystems.

```json
{
  "tool_choice": {
    "type": "allowed_tools",
    "mode": "auto",
    "tools": [
      { "type": "function", "name": "get_weather" },
      { "type": "function", "name": "search_docs" }
    ]
  }
}
```

### Computer Use

Native capabilities to interact with software interfaces through screenshots and structured actions. Use in isolated environments with human oversight for high-impact actions.

- Use `original` image detail for click-accuracy and OCR
- Use `high` for standard high-fidelity understanding

### Compaction

First mainline model supporting compaction for extended agent trajectories:
- Compact after major milestones
- Treat compacted items as opaque state
- The endpoint is ZDR compatible and returns `encrypted_content` for future requests
- Maintains coherence over longer multi-turn conversations

### MCP Integration

Model Context Protocol support via Responses API.

### Custom Tools

```json
{
  "type": "custom",
  "name": "code_exec",
  "description": "Executes arbitrary python code"
}
```

Supports context-free grammar (CFG) constraints for output validation.

Supported features
------------------

Streaming, Function calling, Structured outputs, Distillation, Web search, File search, Image generation, Code interpreter, Hosted shell, Apply patch, Skills, Computer use, MCP, Tool search

Available endpoints: Chat Completions, Responses, Realtime, Assistants, Batch, Fine-tuning, Embeddings

Migration guidance
------------------

| From | Suggested GPT-5.4 Start | Notes |
|------|------------------------|-------|
| `gpt-5.2` | Match current reasoning effort | Drop-in replacement with defaults |
| `gpt-5.3-codex` | Match current reasoning effort | Keep reasoning same for coding |
| `gpt-4.1` or `gpt-4o` | `none` | Keep snappy, increase if evals regress |
| Research-heavy assistants | `medium` or `high` | Use explicit research multi-pass and citation gating |
| Long-horizon agents | `medium` or `high` | Add tool persistence and completeness accounting |

### Chat Completions → Responses API

Advantages of passing chain-of-thought between turns:
- Improved intelligence
- Fewer reasoning tokens
- Higher cache hit rates
- Reduced latency

Best practices
--------------

1. Pass previous reasoning items back via `previous_response_id` to avoid re-reasoning
2. Use the GPT-5.4 prompt optimizer for automatic improvements
3. Validate freeform tool outputs server-side against injection
4. Preserve `phase` values in multi-turn conversations
5. Lower reasoning effort and verbosity reduces latency
6. Leverage 1M token window for codebase or document analysis

Sources
-------

- [Introducing GPT-5.4 | OpenAI](https://openai.com/index/introducing-gpt-5-4/)
- [GPT-5.4 Model | OpenAI API](https://developers.openai.com/api/docs/models/gpt-5.4)
- [GPT-5.4 Pro Model | OpenAI API](https://developers.openai.com/api/docs/models/gpt-5.4-pro)
- [Using GPT-5.4 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model/)
- [Pricing | OpenAI API](https://developers.openai.com/api/docs/pricing)
