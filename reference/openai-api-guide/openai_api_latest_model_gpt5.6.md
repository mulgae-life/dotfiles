Using GPT-5.6 (Sol / Terra / Luna)
==================================

Learn best practices, features, and migration guidance for the GPT-5.6 model family.

> **출처**: [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
> **날짜**: 2026-07-10 (GA 2026-07-09)
> **이전 버전**: [Using GPT-5.4](./openai_api_latest_model_gpt5.4.md)

GPT-5.6 is OpenAI's frontier model family for professional work, released as three tiers instead of a single flagship. Frontier improvements claimed in SW engineering, computer use, professional knowledge work, scientific research, and cybersecurity.

Key changes over GPT-5.5:
*   Three-tier lineup (Sol / Terra / Luna) replaces the single-model release
*   Long-horizon task completion and sub-agent orchestration (Sol Ultra: Terminal-Bench 2.1 88.8% → 91.9% with parallel sub-agents)
*   Pro mode as a parameter (`reasoning.mode`), replacing the separate Pro model of the 5.4 era
*   Persisted reasoning across turns (`reasoning.context`)
*   Programmatic Tool Calling (hosted JS runtime orchestration)
*   Explicit prompt caching (`prompt_cache_options`)
*   System card note: first time small/fast tiers (Terra, Luna) received High capability ratings (Bio/Chem, Cybersecurity); AI Self-Improvement below High

Meet the models
---------------

| Model | ID | Snapshot | Description |
|-------|-----|---------|------------|
| GPT-5.6 Sol | `gpt-5.6-sol` | `gpt-5.6-sol` | Flagship capability. Default target of the `gpt-5.6` alias |
| GPT-5.6 Terra | `gpt-5.6-terra` | `gpt-5.6-terra` | Strong performance at a lower price |
| GPT-5.6 Luna | `gpt-5.6-luna` | `gpt-5.6-luna` | Efficient, high-volume workloads |

The generic alias `gpt-5.6` routes requests to `gpt-5.6-sol`. No `-codex` variant exists for this generation; Codex CLI uses the same three tiers (default `gpt-5.6-sol`, supported from Codex CLI 0.142.0).

Context window and output (all tiers)
-------------------------------------

| Spec | Value |
|------|-------|
| Context window | 1,050,000 tokens (~1M) |
| Max output tokens | 128,000 |
| Knowledge cutoff | February 16, 2026 |

Pricing
-------

Per 1M tokens (standard):

| Tier | Input | Cached Input | Output |
|------|-------|--------------|--------|
| Sol | $5.00 | $0.50 | $30.00 |
| Terra | $2.50 | $0.25 | $15.00 |
| Luna | $1.00 | $0.10 | $6.00 |

**Notes:**
- Explicit prompt cache **writes cost 1.25× the uncached input rate**; cache reads remain discounted → track `cached_tokens` / `cache_write_tokens`
- Pro mode is billed at the selected model's standard token rates (more tokens, not a higher rate)
- Reasoning tokens are billed as output tokens; per-million price comparison across tiers/effort levels is misleading — benchmark real cost on representative tasks

Core parameters
---------------

### Reasoning Effort

Default is `medium` for GPT-5.6 (both standard and pro modes).

```json
{
  "model": "gpt-5.6-sol",
  "input": "your question",
  "reasoning": { "effort": "medium" }
}
```

| Setting | Use Case |
|---------|----------|
| `none` | Latency-critical tasks (classification, fast retrieval) |
| `low` | Tool use, planning, multi-step decisions |
| `medium` | Default. Balanced quality and reliability |
| `high` | Complex debugging, deep planning |
| `xhigh` | Async, long-running workflows |
| `max` | Hardest quality-first tasks — ⚠️ see doc inconsistency note |

> ⚠️ **Doc inconsistency (as of 2026-07-10)**: the latest-model guide lists `none, low, medium, high, xhigh, max`; the reasoning guide lists `none, minimal, low, medium, high, xhigh` (no `max`). Verify `max`/`minimal` support with an actual API call before adopting (Simon Willison published `max` results for all three tiers, suggesting it works via the API). Codex CLI: `max` became first-class in 0.143.0–0.144.0 but is not yet listed in the `model_reasoning_effort` config enum (`minimal|low|medium|high|xhigh`).

### Reasoning Mode (new)

```json
{
  "model": "gpt-5.6-sol",
  "reasoning": { "mode": "pro", "effort": "medium" }
}
```

- `"pro"`: more model work than standard — higher quality ceiling, higher latency and token usage. Returns a single final answer. Official selection rule: "Use pro mode when a marginal quality improvement materially affects the outcome."
- Replaces the separate `-pro` model pattern of GPT-5.4.

### Reasoning Context (new)

Persist reasoning across turns:

```json
{
  "reasoning": { "context": "all_turns" }
}
```

| Value | Behavior |
|-------|----------|
| `auto` (default) | Model default behavior |
| `current_turn` | Use only the current turn's reasoning |
| `all_turns` | Render prior turns' reasoning items — recommended for long-running workflows to reduce rendered context |

### Verbosity Control

Unchanged from 5.5 (`low | medium | high`, default `medium`). Note that GPT-5.6 output is already compression-biased; prefer priority instructions ("lead with the conclusion...") over generic "be concise" prompts, which GPT-5.6 is more sensitive to than 5.5.

New features
------------

### Programmatic Tool Calling

Hosted JS runtime orchestrates tool calls inside one model turn. Tools opt in via `allowed_callers`; clients must handle `program` / `program_output` items. When both direct and programmatic calling are available, state explicitly which bounded stage should use programmatic calling, and evaluate the final user-visible answer, not only the program result.

### Explicit Prompt Caching

`prompt_cache_options.mode: "explicit"` with `prompt_cache_options.ttl` replaces `prompt_cache_retention`. Cache writes billed at 1.25× uncached input.

### Multi-agent (beta)

Sub-agent orchestration support; Sol "Ultra" mode (parallel sub-agents) is surfaced in ChatGPT/Codex rather than as a separate API model. Expect 2–3× token usage vs. standard Sol (community observation, HN early reports) — cap with rollout budgets and route sub-tasks to Terra/Luna.

### safety_identifier

Send a stable, privacy-preserving `safety_identifier` with each request for per-user abuse tracking.

Supported features
------------------

Streaming, Function calling, Structured outputs, Web search, File search, Code interpreter, Computer use, MCP, Programmatic tool calling, Explicit prompt caching, Persisted reasoning, Pro mode. Fine-tuning not supported (Sol).

Available endpoints: Chat Completions, Responses, Realtime, Assistants, Batch, Embeddings (full list per model card).

Migration guidance
------------------

Official principle: **"Treat migration as a tuning pass, not only a model-slug change."**

> "If you are migrating from GPT-5.5 or GPT-5.4, preserve your current reasoning effort as the baseline, then compare one level lower."

Evaluation axes: task success, final-answer completeness, required evidence, total tokens, latency, cost.

| From | Suggested GPT-5.6 Start | Notes |
|------|------------------------|-------|
| `gpt-5.5` | Same tier role → `gpt-5.6-sol`; keep effort, A/B one level lower | Keep 5.5 prompt stack; re-tune settings only |
| `gpt-5.4` / `gpt-5.4-pro` | `gpt-5.6-sol`; Pro workloads → `reasoning.mode: "pro"` | Apply 5.5 fresh-baseline rewrite first if still on 5.4-era prompts |
| Cost-sensitive pipelines | `gpt-5.6-terra` or `gpt-5.6-luna` | Tier routing beats effort tuning for cost leverage |
| Long-horizon agents | Sol + `reasoning.context: "all_turns"` | Add verification loops — system card admits stronger overstepping tendency than 5.5 |

Best practices
--------------

1. Pick the tier first (Sol=planning/verification/final synthesis, Terra=everyday generation, Luna=small sub-tasks) — larger cost lever than effort
2. Keep 5.5 prompt stacks; replace generic conciseness instructions with priority instructions
3. Gate high-risk changes behind human review — GPT-5.6 oversteps user intent more than 5.5 (system card, METR)
4. Use explicit caching deliberately; verify the 1.25× write cost pays back via read volume
5. Reserve pro mode for points where marginal quality materially affects the outcome
6. Verify `max` effort support via API before depending on it

Sources
-------

- [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model)
- [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
- [gpt-5.6-sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol) · [gpt-5.6-terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) · [gpt-5.6-luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [GPT-5.6 system card (preview)](https://deploymentsafety.openai.com/gpt-5-6-preview)
- [Prompt guidance | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance)
- 프롬프팅 상세: [GPT-5.6 Prompting Guide](../openai-prompt-guide/gpt-5.6-prompt-guide.md)
