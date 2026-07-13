Using GPT-5.6 (Sol / Terra / Luna)
==================================

Learn best practices, features, and migration guidance for the GPT-5.6 model family.

> **출처**: [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
> **검증일**: 2026-07-13 (GA 2026-07-09)
> **이전 버전**: [Using GPT-5.4](./openai_api_latest_model_gpt5.4.md)

GPT-5.6 is OpenAI's frontier model family for professional work, released as three tiers instead of a single flagship. Frontier improvements claimed in SW engineering, computer use, professional knowledge work, scientific research, and cybersecurity.

Key changes over GPT-5.5:
*   Three-tier lineup (Sol / Terra / Luna) replaces the single-model release
*   Max reasoning effort and multi-agent orchestration beta
*   Pro mode as a parameter (`reasoning.mode`) — the recommended successor to the separate 5.4-era Pro model (existing Pro model IDs keep their behavior and pricing)
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

The generic alias `gpt-5.6` routes requests to `gpt-5.6-sol`. Codex exposes Sol, Terra, and Luna; OpenAI's support page lists Codex CLI `0.144.0` as the minimum version for GPT-5.6 (locally confirmed: the codex-cli 0.144.1 embedded model registry sets `minimal_client_version: "0.144.0"` for all three tiers).

Context window and output
-------------------------

| Spec (all tiers) | Value |
|------------------|-------|
| Context window | 1,050,000 tokens (~1M) |
| Max output tokens | 128,000 |
| Knowledge cutoff | February 16, 2026 |

All three model cards list identical context window, max output, and knowledge cutoff (re-verified against the Sol/Terra/Luna cards on 2026-07-13; an earlier revision of this doc wrongly listed Luna at 400K).

> **Codex client note** (codex-cli 0.144.1 embedded registry, 2026-07-13): inside Codex, the client-side context window is **372,000 tokens for all three tiers** (GPT-5.5 was 272,000) — the ~1M window above applies to the raw API. Codex product defaults also differ from the API default `medium`: Sol starts at `low` ("Sol is highly capable at lower reasoning efforts — try starting lower, then turn it up for harder jobs"), Terra/Luna at `medium`.

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
- **Long-context surcharge**: requests with more than 272K input tokens are billed at **2× input / 1.5× output for the entire request** (all tiers)
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
| `high` | Complex tasks where evals show more depth is useful |
| `xhigh` | Hard tasks where evals show a meaningful gain over high |
| `max` | Hardest quality-first tasks; do not use as a global default |

> API-supported values for GPT-5.6 are `none|low|medium|high|xhigh|max` per the latest-model guide and all three model cards. ⚠️ Cross-doc gap persists (2026-07-13): the reasoning guide's enum still lists `none, low, medium, high, xhigh` **without `max`** — validators built on that page may reject `max`. Naming duality: the API's minimum is `none`, while the Codex config's minimum is called `minimal` (no `none` in Codex config, no `minimal` in the API).
>
> Codex product: also offers Max, and Sol/Terra additionally expose `ultra` ("maximum reasoning with automatic task delegation" — parallel subagents; Luna has no ultra). The official `config.toml` reference lists the `model_reasoning_effort` enum as `minimal|low|medium|high|xhigh`; locally verified (codex-cli 0.144.1), the client does not validate this enum — the value passes through to the API, and the embedded per-tier registry lists `low|medium|high|xhigh|max(+ultra)`. Prefer selecting Max/Ultra in the product's model picker instead of pinning them in global TOML.

### Reasoning Mode (new)

```json
{
  "model": "gpt-5.6-sol",
  "reasoning": { "mode": "pro", "effort": "medium" }
}
```

- `"pro"`: more model work than standard — higher quality ceiling, higher latency and token usage. Returns a single final answer. Official selection rule: "Use pro mode when a marginal quality improvement materially affects the outcome."
- Recommended successor to the separate `-pro` model pattern of GPT-5.4. Existing Pro model IDs keep their current behavior and pricing ("Existing Pro model IDs keep their current behavior and pricing" — latest-model guide).

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
| `all_turns` | Make compatible reasoning items from prior turns available to the next context |

Use `all_turns` when goals, assumptions, and priorities remain stable. Use `current_turn` when prior reasoning is stale. Persisted reasoning can improve continuity and cache efficiency, but stale reasoning can add tokens, latency, and anchoring.

### Verbosity Control

`text.verbosity` supports `low | medium | high`. GPT-5.6 tends to be more concise than GPT-5.5, so re-evaluate broad brevity instructions and specify task-specific required content, length, structure, and tone in the prompt.

New features
------------

### Programmatic Tool Calling

Hosted JavaScript runtime orchestrates tool calls inside one model turn. Tools opt in via `allowed_callers`; clients must handle `program` / `program_output` items and preserve `call_id` / `caller` linkage. Use it only for bounded deterministic reduction of large structured results. Approval, semantic judgment, citations, and final validation should remain direct tool calls.

### Explicit Prompt Caching

Implicit caching remains available without code changes. `prompt_cache_options.mode: "explicit"` with `prompt_cache_options.ttl` replaces `prompt_cache_retention` when explicit breakpoints are needed. Cache writes are billed at 1.25× uncached input, so track cache writes and reads before adopting explicit mode.

### Multi-agent (beta)

The Responses API exposes multi-agent orchestration as a beta ("Multi-agent is available as a beta feature with all GPT-5.6 models") — enable with the `OpenAI-Beta: responses_multi_agent=v1` header; default `max_concurrent_subagents` is 3. Codex surfaces parallel subagents as Ultra rather than a separate model (subagents are trained to cooperate and can communicate with each other during a task). OpenAI's Codex model guide states that most tasks do not need Max or Ultra; use Ultra only when work divides into meaningful independent parts.

Cost/reliability caveats (community-verified 2026-07-13): reported gains are modest relative to cost — Terminal-Bench 2.1 goes 88.8% (Sol) → 91.9% (Ultra, 4 parallel subagents) while third-party aggregations report **6–12× tokens per task**, amplified by a harness over-spawn bug and by openai/codex #31814 (a Sol main session cannot route subagents to a cheaper tier — they all run Sol). METR rates Sol's reward-hacking rate the "highest of any public model it has assessed" — attach that caveat when citing agentic benchmark numbers. Validate multipliers on representative tasks.

### safety_identifier

Send a stable, privacy-preserving `safety_identifier` with each request for per-user abuse tracking.

Compatibility note: Chat Completions tools
------------------------------------------

For GPT-5.6, function tools in Chat Completions require effective reasoning `none`. Because omitted GPT-5.6 effort defaults to `medium`, a model-only swap can break this combination. Keep `none` explicitly for latency-sensitive Chat Completions tool flows, or migrate to Responses when both reasoning and tools are required.

Supported features
------------------

Streaming, Function calling, Structured outputs, Web search, File search, Code interpreter, Computer use, MCP, Programmatic tool calling, Explicit prompt caching, Persisted reasoning, Pro mode. Fine-tuning not supported (Sol).

Available endpoints: Chat Completions, Responses, Realtime, Assistants, Batch, Embeddings (full list per model card).

Migration guidance
------------------

Preserve behavior, latency class, cost class, reasoning level, endpoint contract, tool semantics, cache behavior, and output contract before adopting optional 5.6 features.

Evaluation axes: task success, final-answer completeness, required evidence, total tokens, latency, cost.

| From | Suggested GPT-5.6 Start | Notes |
|------|------------------------|-------|
| `gpt-5.5` flagship | `gpt-5.6-sol`; keep effective effort, A/B one level lower | Preserve prompt and endpoint behavior first |
| GPT-5.5 everyday work | Evaluate `gpt-5.6-terra` | Official Codex guide calls Terra the natural starting point for prior GPT-5.5 work |
| Mini / balanced lower-cost route | `gpt-5.6-terra` | Preserve latency and cost role |
| Nano / extraction / classification / high-volume route | `gpt-5.6-luna` | Same 1.05M context as other tiers; validate quality on representative tasks |
| `gpt-5.4-pro` | Sol + `reasoning.mode: "pro"` only when Pro behavior is required | Evaluate separately from baseline migration |
| Long-horizon agent | Preserve current state strategy; evaluate `reasoning.context` separately | Do not enable persisted reasoning merely because it exists |

Best practices
--------------

1. Choose Sol for complex open-ended work, Terra for everyday work, and Luna for clear repeatable work.
2. Switch the model first, preserve effective effort, then evaluate the same setting and one level lower.
3. Remove repeated instructions and irrelevant tools one group at a time; add only the smallest instruction required by a measured regression.
4. Keep autonomy, approval, evidence, validation, and stopping boundaries explicit and non-duplicated.
5. Adopt Pro, persisted reasoning, PTC, explicit caching, and multi-agent separately from the baseline migration.
6. Validate task success, completeness, evidence, tool behavior, total tokens, latency, and cost before declaring migration complete.

Sources
-------

- [Using GPT-5.6 | OpenAI API](https://developers.openai.com/api/docs/guides/latest-model?model=gpt-5.6)
- [Upgrading to GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/upgrading-to-gpt-5p6-sol)
- [Prompting guidance for GPT-5.6 Sol | OpenAI API](https://developers.openai.com/api/docs/guides/prompt-guidance-gpt-5p6)
- [Reasoning | OpenAI API](https://developers.openai.com/api/docs/guides/reasoning)
- [gpt-5.6-sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol) · [gpt-5.6-terra](https://developers.openai.com/api/docs/models/gpt-5.6-terra) · [gpt-5.6-luna](https://developers.openai.com/api/docs/models/gpt-5.6-luna)
- [Codex models | OpenAI](https://learn.chatgpt.com/docs/models)
- [Codex configuration reference | OpenAI](https://learn.chatgpt.com/docs/config-file/config-reference)
- [GPT-5.6 in ChatGPT and Codex | OpenAI Help](https://help.openai.com/en/articles/20001354-gpt-56-in-chatgpt)
- [GPT-5.6 system card (preview)](https://deploymentsafety.openai.com/gpt-5-6-preview)
- 프롬프팅 상세: [GPT-5.6 Prompting Guide](../openai-prompt-guide/gpt-5.6-prompt-guide.md)
