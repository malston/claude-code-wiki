---
title: "Model Selection & Cost Management: Choosing the Right Model and Controlling Spend"
linkTitle: "Model Selection & Cost"
weight: 5
---

# Model Selection & Cost Management: Choosing the Right Model and Controlling Spend

## Executive Summary

Claude Code offers three model tiers -- Opus, Sonnet, and Haiku -- each with different capability, speed, and cost profiles. The right model depends on the task: Opus for complex reasoning, Sonnet for daily coding, Haiku for fast simple tasks. Beyond model choice, Claude Code provides several cost control mechanisms: prompt caching, auto-compaction, budget caps, effort levels, and subagent model selection. This article covers how to choose models, configure them, and manage costs effectively.

| Model          | Strengths                                    | Input/MTok | Output/MTok | Cache Read | Speed    |
| -------------- | -------------------------------------------- | ---------- | ----------- | ---------- | -------- |
| **Opus 4.8**   | Long-horizon agentic work, complex reasoning | $5         | $25         | $0.50      | Moderate |
| **Sonnet 4.6** | Daily coding, balanced                       | $3         | $15         | $0.30      | Fast     |
| **Haiku 4.5**  | Quick tasks, simple operations               | $1         | $5          | $0.10      | Fastest  |

Opus 4.8, 4.7, and 4.6 share the same per-token pricing. Opus 4.8 is the current default for the `opus` alias.

## Table of Contents

- [Model Selection \& Cost Management: Choosing the Right Model and Controlling Spend](#model-selection--cost-management-choosing-the-right-model-and-controlling-spend)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [The Model Lineup](#the-model-lineup)
    - [Opus 4.8](#opus-48)
    - [Opus 4.7 and 4.6](#opus-47-and-46)
    - [Sonnet 4.6](#sonnet-46)
    - [Haiku 4.5](#haiku-45)
    - [Legacy Models](#legacy-models)
  - [When to Use Each Model](#when-to-use-each-model)
    - [Decision Framework](#decision-framework)
    - [Task-Based Recommendations](#task-based-recommendations)
  - [Configuring Models in Claude Code](#configuring-models-in-claude-code)
    - [Model Aliases](#model-aliases)
    - [Switching Models](#switching-models)
    - [The opusplan Strategy](#the-opusplan-strategy)
    - [Effort Levels](#effort-levels)
    - [Fallback Models](#fallback-models)
    - [Extended Context](#extended-context)
    - [Fast Mode](#fast-mode)
    - [Subagent Model Selection](#subagent-model-selection)
  - [Understanding Costs](#understanding-costs)
    - [How Costs Accumulate](#how-costs-accumulate)
    - [Prompt Caching Economics](#prompt-caching-economics)
    - [Extended Thinking Costs](#extended-thinking-costs)
    - [Typical Cost Ranges](#typical-cost-ranges)
  - [Cost Reduction Strategies](#cost-reduction-strategies)
    - [Context Management](#context-management)
    - [Model Selection Strategies](#model-selection-strategies)
    - [MCP and Plugin Overhead](#mcp-and-plugin-overhead)
    - [Hook-Based Preprocessing](#hook-based-preprocessing)
    - [Headless Mode Budget Controls](#headless-mode-budget-controls)
  - [Tracking and Monitoring Costs](#tracking-and-monitoring-costs)
    - [Session-Level Tracking](#session-level-tracking)
    - [Team-Level Management](#team-level-management)
    - [Rate Limit Planning](#rate-limit-planning)
  - [Best Practices](#best-practices)
  - [Anti-Patterns](#anti-patterns)
    - [Using Opus for Everything](#using-opus-for-everything)
    - [Never Clearing Context](#never-clearing-context)
    - [Running Subagents on Opus](#running-subagents-on-opus)
    - [No Budget Controls in CI](#no-budget-controls-in-ci)
    - [Ignoring Prompt Caching](#ignoring-prompt-caching)
  - [References](#references)

## The Model Lineup

### Opus 4.8

The most capable model. Best for long-horizon agentic work, complex architecture decisions, multi-step planning, and extended thinking.

| Attribute          | Value                         |
| ------------------ | ----------------------------- |
| Input pricing      | $5/MTok                       |
| Output pricing     | $25/MTok                      |
| Cache read pricing | $0.50/MTok                    |
| Context window     | 1M (standard pricing)         |
| Max output         | 128K tokens                   |
| Extended thinking  | Yes (adaptive only)           |
| Effort levels      | Low, medium, high, xhigh, max |
| Default effort     | High                          |

Opus 4.8 is the default for Max and Team Premium subscribers and what the `opus` alias resolves to. Pro subscribers default to Sonnet. It supports adaptive thinking -- dynamically allocating reasoning depth based on task complexity -- and defaults to `high` effort, with `/effort xhigh` available for harder agentic work. Opus 4.8 uses a leaner system prompt than earlier models by default, which trims the fixed per-message token overhead (see the [System Prompt article]({{< relref "/internals/system-prompt" >}})).

Opus 4.7 and 4.8 use a different tokenizer than Opus 4.6 and earlier. Per-token pricing is identical, but the same text can tokenize to as much as 35% more tokens, so compare total cost rather than assuming the price tag tells the whole story.

### Opus 4.7 and 4.6

Prior-generation Opus models, both still active and priced identically to Opus 4.8 ($5/$25/$0.50 per MTok, 1M context at standard pricing, 128K max output).

| Model    | Thinking      | Effort levels                 | Notes                                                 |
| -------- | ------------- | ----------------------------- | ----------------------------------------------------- |
| Opus 4.7 | Adaptive only | Low, medium, high, xhigh, max | Same request surface as 4.8                           |
| Opus 4.6 | Adaptive      | Low, medium, high, max        | `budget_tokens` deprecated but functional; no `xhigh` |

On Opus 4.7 and 4.8, `budget_tokens` and sampling parameters are removed -- use adaptive thinking and effort. On Opus 4.6, manual `budget_tokens` still works but is deprecated in favor of adaptive thinking.

### Sonnet 4.6

The workhorse model. Handles most coding tasks effectively at lower cost and faster speed than Opus.

| Attribute          | Value                 |
| ------------------ | --------------------- |
| Input pricing      | $3/MTok               |
| Output pricing     | $15/MTok              |
| Cache read pricing | $0.30/MTok            |
| Context window     | 1M (standard pricing) |
| Max output         | 64K tokens            |
| Extended thinking  | Yes (adaptive)        |
| Effort levels      | Low, medium, high     |

Anthropic's official recommendation for uncertain model choice. Good at code generation, bug fixing, test writing, and refactoring. Supports adaptive thinking and effort levels (low, medium, high -- no `max` or `xhigh`).

### Haiku 4.5

The speed-optimized model. Best for simple tasks where response time matters more than depth.

| Attribute          | Value         |
| ------------------ | ------------- |
| Input pricing      | $1/MTok       |
| Output pricing     | $5/MTok       |
| Cache read pricing | $0.10/MTok    |
| Context window     | 200K          |
| Max output         | 64K tokens    |
| Extended thinking  | Manual budget |
| Effort levels      | Not supported |

5x cheaper than Opus on input, 5x cheaper on output. Good for subagent tasks, simple lookups, and quick operations that don't need deep reasoning. Haiku 4.5 does not support the effort parameter; control its thinking with `MAX_THINKING_TOKENS` instead.

### Legacy Models

Still available but migration recommended:

| Model    | Input/MTok | Output/MTok | Notes                             |
| -------- | ---------- | ----------- | --------------------------------- |
| Opus 4.5 | $5         | $25         | Same pricing as 4.6, less capable |
| Opus 4.1 | $15        | $75         | 3x more expensive than 4.6        |
| Sonnet 4 | $3         | $15         | Same pricing as 4.5               |
| Opus 4   | $15        | $75         | 3x more expensive than 4.6        |

Opus 4.8 is strictly better and cheaper than Opus 4.1 and Opus 4. There's no reason to stay on the older models.

## When to Use Each Model

### Decision Framework

```text
Is the task complex reasoning, architecture, or multi-step planning?
  YES ──▶ Opus 4.8
  NO  ──▼

Is it standard coding work (features, bugs, refactoring, tests)?
  YES ──▶ Sonnet 4.6
  NO  ──▼

Is it a simple lookup, quick fix, or subagent task?
  YES ──▶ Haiku 4.5
```

### Task-Based Recommendations

| Task                                | Recommended Model | Why                                           |
| ----------------------------------- | ----------------- | --------------------------------------------- |
| Complex architecture decisions      | Opus              | Needs deep multi-step reasoning               |
| Designing a new system from scratch | Opus              | Benefits from extended thinking               |
| Debugging subtle race conditions    | Opus              | Requires tracing through complex interactions |
| Implementing a new feature          | Sonnet            | Standard coding, good quality at lower cost   |
| Writing tests                       | Sonnet            | Well-defined task, pattern-following          |
| Fixing a clear bug                  | Sonnet            | Direct fix, doesn't need deep reasoning       |
| Refactoring existing code           | Sonnet            | Pattern transformation, well-structured       |
| Code review                         | Sonnet            | Can identify issues without Opus-level depth  |
| Simple file lookups in subagents    | Haiku             | Speed matters, depth doesn't                  |
| Generating boilerplate              | Haiku             | Template-following, no reasoning needed       |
| Quick searches across a codebase    | Haiku             | Exploration that feeds into deeper work       |
| Prompt/agent hooks (LLM evaluation) | Haiku             | Fast evaluation, binary decisions             |

**The opusplan sweet spot:** For features that need careful planning but straightforward implementation, use `opusplan` -- Opus reasons through the design, Sonnet implements it.

## Configuring Models in Claude Code

### Model Aliases

Claude Code provides convenience aliases that always point to the latest version:

| Alias        | Resolves To         | Use Case                              |
| ------------ | ------------------- | ------------------------------------- |
| `opus`       | Opus 4.8            | Complex reasoning                     |
| `sonnet`     | Sonnet 4.6          | Daily coding                          |
| `best`       | Opus 4.8            | Alias for the most capable model      |
| `haiku`      | Haiku 4.5           | Fast simple tasks                     |
| `sonnet[1m]` | Sonnet 4.6 + 1M ctx | Long sessions                         |
| `opusplan`   | Opus + Sonnet       | Plan with Opus, implement with Sonnet |

To pin a specific version (e.g., for reproducibility), use the full model name:

```bash
claude --model claude-opus-4-8
```

### Switching Models

Four ways to set your model, in priority order:

1. **Mid-session:** `/model sonnet` (immediate switch)
2. **At startup:** `claude --model opus`
3. **Environment variable:** `ANTHROPIC_MODEL=sonnet`
4. **Settings file:** `"model": "opus"` in settings.json

```bash
# Start with a specific model
claude --model opus

# Switch during a session
/model sonnet

# Check what you're running
/status
```

### The opusplan Strategy

`opusplan` automatically switches between models based on mode:

- **Plan mode** (Shift+Tab) -- Uses Opus for reasoning and architecture
- **Execution mode** -- Switches to Sonnet for code generation

```bash
claude --model opusplan
```

This gives you Opus-quality planning at Sonnet-level execution cost. Particularly effective for the explore-plan-implement workflow.

### Effort Levels

Effort controls how deeply a model reasons and how much it spends per turn. It applies to Opus 4.5, 4.6, 4.7, and 4.8 and to Sonnet 4.6. Sonnet 4.5 and Haiku 4.5 do not support the effort parameter.

| Level      | Behavior                                | Availability              | When to Use                     |
| ---------- | --------------------------------------- | ------------------------- | ------------------------------- |
| **Max**    | Maximum reasoning depth                 | Opus 4.6, 4.7, 4.8        | Hardest problems, research      |
| **xhigh**  | Between high and max                    | Opus 4.7, 4.8             | Long-horizon agentic coding     |
| **High**   | Deep reasoning, full thinking (default) | All effort-capable models | Architecture, complex bugs      |
| **Medium** | Moderate reasoning                      | All effort-capable models | Standard features, clear tasks  |
| **Low**    | Fast, minimal thinking                  | All effort-capable models | Simple fixes, well-defined work |

`max` is Opus-tier only. `xhigh` exists on Opus 4.7 and 4.8 (other models fall back to `high`). Opus 4.8 defaults to `high`. Pro, Max, and Team subscribers on Opus 4.6 and Sonnet 4.6 also default to `high`.

Set effort four ways. The `/effort` command opens an interactive slider (arrow keys, labeled Faster to Smarter), or you can pass a level directly:

```text
/effort xhigh
```

In the `/model` menu, adjust the effort slider with the arrow keys. Or set it with an environment variable:

```bash
CLAUDE_CODE_EFFORT_LEVEL=medium claude
```

Or in `settings.json`:

```json
{ "effortLevel": "medium" }
```

Lower effort means fewer thinking tokens, fewer tool calls, and terser output -- lower cost and faster response. A `medium` effort Opus session can cost significantly less than `high` while still outperforming Sonnet on reasoning tasks.

### Fallback Models

When the primary model is unavailable (overloaded, not found, or unset), Claude Code can fall back to other models instead of failing. The `fallbackModel` setting takes up to three models, tried in order:

```json
{
  "model": "opus",
  "fallbackModel": ["sonnet", "haiku"]
}
```

The `--fallback-model` flag does the same on the command line and applies to interactive sessions as well as headless runs:

```bash
claude --model opus --fallback-model sonnet
```

### Extended Context

Opus 4.8, 4.7, and 4.6 and Sonnet 4.6 include the full 1M token context window at standard pricing -- a 900K-token request is billed at the same per-token rate as a 9K-token request. Opus 4.7 and 4.8 run at 1M context natively. For Sonnet, the `[1m]` suffix selects the 1M variant:

```bash
/model sonnet[1m]
```

There is no longer a long-context premium on these models. (The earlier 1M beta on Sonnet 4.5 billed input at 2x above 200K tokens; the current models do not.) The 1M window still consumes more context budget and slows each turn as it fills, so reserve it for sessions that genuinely read many large files.

### Fast Mode

Fast mode (research preview) runs Opus with faster output at premium pricing. It is the same Opus model, not a downgrade to a smaller one. Toggle it with `/fast`. It is available on Opus 4.8, 4.7, and 4.6, and the premium applies across the full context window, including requests over 200K input tokens.

| Model    | Fast input/MTok | Fast output/MTok | Multiplier vs standard |
| -------- | --------------- | ---------------- | ---------------------- |
| Opus 4.8 | $10             | $50              | 2x (for ~2.5x speed)   |
| Opus 4.7 | $30             | $150             | 6x                     |
| Opus 4.6 | $30             | $150             | 6x                     |

Fast mode is the best value on Opus 4.8: 2x the rate for roughly 2.5x the speed. It is not available on Claude Platform on AWS or with the Batch API. Prompt caching multipliers apply on top of fast-mode pricing.

### Subagent Model Selection

Subagents can run on different models than your main session:

**Per-agent configuration** (in `.claude/agents/*.md`):

```yaml
---
name: quick-search
description: Fast codebase search
model: haiku
---
```

**Global override** (environment variable):

```bash
CLAUDE_CODE_SUBAGENT_MODEL=haiku claude
```

**In the Task tool** (inline):

```text
"use a subagent with model haiku to search for all TODO comments"
```

Running subagents on Haiku is one of the highest-leverage cost optimizations. Most subagent tasks -- file searches, pattern matching, codebase exploration -- don't need Opus-level reasoning.

## Understanding Costs

### How Costs Accumulate

Every message in Claude Code sends the full conversation context to the API. Costs scale with:

```text
Cost per message ≈ (system prompt + conversation history + new input) × input price
                  + (response length) × output price
                  + (thinking tokens) × output price
```

The system prompt (12,000-20,000 tokens) is re-sent every message but heavily cached. The conversation history grows with each turn. Auto-compaction kicks in at ~75-92% context usage, summarizing older messages.

### Prompt Caching Economics

Prompt caching dramatically reduces the cost of re-sending the system prompt and stable conversation prefix:

| Operation      | Multiplier | Opus 4.8   | Sonnet 4.6 | Haiku 4.5  |
| -------------- | ---------- | ---------- | ---------- | ---------- |
| Cache write    | 1.25x base | $6.25/MTok | $3.75/MTok | $1.25/MTok |
| **Cache read** | **0.1x**   | **$0.50**  | **$0.30**  | **$0.10**  |
| Uncached input | 1x base    | $5/MTok    | $3/MTok    | $1/MTok    |

Cache reads are 10x cheaper than base input. After the first message in a session, most of the system prompt is cached. Over a 200-message session, a 15,000-token system prompt costs ~$1.60 with caching vs ~$15 without (using Opus 4.8).

Claude Code manages cache breakpoints automatically -- there's nothing to configure.

### Extended Thinking Costs

Extended thinking tokens are billed as output tokens. With Opus 4.8 at $25/MTok output:

| Thinking budget  | Cost per use (if fully consumed) |
| ---------------- | -------------------------------- |
| 32K tokens (max) | ~$0.80                           |
| 16K tokens       | ~$0.40                           |
| 8K tokens        | ~$0.20                           |
| Disabled         | $0                               |

Control thinking spend by model type. On Opus 4.8 and other adaptive models, lower the effort level to reduce thinking tokens -- `MAX_THINKING_TOKENS` is ignored on these models except `0`, which disables thinking. On manual-budget models (Sonnet 4.5, Haiku 4.5), cap the budget directly:

```bash
# Manual-budget models: cap thinking tokens
MAX_THINKING_TOKENS=8000 claude

# Disable thinking entirely (any model)
MAX_THINKING_TOKENS=0 claude
```

On adaptive models, effort is the primary thinking-cost lever. You can also disable thinking from `/config`.

### Typical Cost Ranges

From Anthropic's data:

- **Average:** ~$6/developer/day
- **90th percentile:** <$12/developer/day
- **Monthly average:** ~$100-200/developer (Sonnet 4.6)
- **Background usage:** <$0.04/session (summarization, status checks)

These numbers assume Sonnet 4.6. Opus sessions cost roughly 1.7x more for the same work due to higher input/output pricing.

## Cost Reduction Strategies

### Context Management

Context size is the primary cost driver. Smaller context = cheaper messages.

**Clear between tasks:**

```sh
/clear    # Reset context when switching to unrelated work
```

Stale context wastes tokens on every subsequent message. Use `/rename` before clearing so you can `/resume` later.

**Compact proactively:**

```sh
/compact Focus on code changes and test results
```

Auto-compaction triggers at ~75-92% usage, but manual compaction lets you control what's preserved.

**Use subagents for investigation:**

```text
"use a subagent to investigate how authentication works"
```

The subagent reads many files in its own context and returns a summary. Your main context stays clean.

### Model Selection Strategies

**Default to Sonnet, upgrade to Opus when needed:**

Most coding tasks don't benefit from Opus. Start with Sonnet and switch to Opus only for:

- Complex architectural planning
- Debugging subtle multi-system issues
- Tasks where Sonnet's first attempt wasn't good enough

**Use opusplan for features:**

Plan with Opus's superior reasoning, execute with Sonnet's efficiency:

```bash
claude --model opusplan
```

**Lower effort for clear tasks:**

If you're using Opus but the task is well-defined, drop effort to `medium`:

```bash
CLAUDE_CODE_EFFORT_LEVEL=medium claude
```

**Use Haiku for subagents:**

```yaml
# .claude/agents/searcher.md
---
model: haiku
---
```

Or globally: `CLAUDE_CODE_SUBAGENT_MODEL=haiku`

### MCP and Plugin Overhead

Each MCP server adds tool definitions to context, even when idle. Each plugin adds skill and subagent descriptions.

**Check what's consuming space:**

```sh
/context    # See context breakdown
```

**Disable unused MCP servers:**

```sh
/mcp    # View and manage servers
```

**Enable Tool Search for many tools:**

```bash
ENABLE_TOOL_SEARCH=auto:5 claude    # Defer tools exceeding 5% of context
```

**Prefer CLI tools over MCP:**

`gh`, `aws`, `gcloud`, `sentry-cli` are more context-efficient than MCP servers because they don't add persistent tool definitions.

### Hook-Based Preprocessing

Use hooks to filter data before Claude sees it:

```bash
#!/bin/bash
# filter-test-output.sh -- show only failures
input=$(cat)
cmd=$(echo "$input" | jq -r '.tool_input.command')

if [[ "$cmd" =~ ^(npm test|pytest|go test) ]]; then
  filtered_cmd="$cmd 2>&1 | grep -A 5 -E '(FAIL|ERROR)' | head -100"
  echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"allow","updatedInput":{"command":"'"$filtered_cmd"'"}}}'
else
  echo "{}"
fi
```

Instead of Claude reading 10,000 lines of test output, the hook passes only the relevant failures -- reducing context from tens of thousands of tokens to hundreds.

### Headless Mode Budget Controls

For automated usage, always set limits:

```bash
# Cap turns and budget
claude -p \
  --max-turns 10 \
  --max-budget-usd 5.00 \
  --model sonnet \
  "Fix the authentication bug in @src/auth.ts"
```

| Flag                 | Purpose                               |
| -------------------- | ------------------------------------- |
| `--max-turns N`      | Hard limit on agentic turns           |
| `--max-budget-usd N` | Dollar cap for the invocation         |
| `--model sonnet`     | Use cheaper model for batch work      |
| `--fallback-model`   | Auto-fallback when primary overloaded |

## Tracking and Monitoring Costs

### Session-Level Tracking

```sh
/cost    # Show current session token usage and cost
/stats   # Usage patterns (for subscribers)
```

Configure your status line to show cost continuously. The claude-hud plugin can display token usage and cost in real-time.

### Team-Level Management

- **Workspace spend limits:** Set in the Claude Console to cap total team spend
- **Usage reporting:** View per-developer usage in the Console
- **Dedicated workspace:** Claude Code auto-creates a "Claude Code" workspace for centralized tracking

### Rate Limit Planning

Recommended per-user Token Per Minute (TPM) allocations:

| Team Size    | TPM per User | RPM per User |
| ------------ | ------------ | ------------ |
| 1-5 users    | 200k-300k    | 5-7          |
| 5-20 users   | 100k-150k    | 2.5-3.5      |
| 20-50 users  | 50k-75k      | 1.25-1.75    |
| 50-100 users | 25k-35k      | 0.62-0.87    |
| 100-500      | 15k-20k      | 0.37-0.47    |
| 500+         | 10k-15k      | 0.25-0.35    |

TPM per user decreases with team size because fewer users are active concurrently. These are organization-level limits -- individuals can burst above their share when others are idle.

## Best Practices

1. **Default to Sonnet.** Most coding tasks don't need Opus. Switch up only when you need deeper reasoning.

2. **Use opusplan for features.** Plan with Opus, execute with Sonnet -- Opus-quality architecture at Sonnet-level cost.

3. **Run subagents on Haiku.** File searches, pattern matching, and codebase exploration are Haiku-level tasks. Set `CLAUDE_CODE_SUBAGENT_MODEL=haiku` or configure per-agent.

4. **Clear between tasks.** `/clear` is the single most effective cost reduction. Stale context is wasted money on every subsequent message.

5. **Lower effort for clear tasks.** If you're using Opus and the task is well-defined, use `medium` effort to cut thinking token costs.

6. **Set budget limits in automation.** Every `claude -p` invocation in CI should have `--max-turns` and `--max-budget-usd`.

7. **Check /cost periodically.** Awareness drives behavior. If a session is expensive, ask why -- usually context has grown too large.

8. **Preprocess with hooks.** Don't let Claude read entire log files when a hook can grep for errors first.

9. **Disable unused MCP servers.** Each idle server adds tool definitions to every message. Run `/mcp` and disable what you're not using.

10. **Lower effort for simple tasks.** On adaptive models (Opus 4.8, Sonnet 4.6), drop to `low` effort when deep reasoning isn't needed. `MAX_THINKING_TOKENS` caps only manual-budget models (Sonnet 4.5, Haiku 4.5); `MAX_THINKING_TOKENS=0` disables thinking on any model.

## Anti-Patterns

### Using Opus for Everything

```text
Bad:  claude --model opus
      "rename this variable from foo to bar"
      (Opus costs 1.7x more for a task Sonnet handles perfectly)

Good: claude --model sonnet
      "rename this variable from foo to bar"
```

Reserve Opus for tasks that actually benefit from its reasoning capabilities.

### Never Clearing Context

```text
Bad:  One continuous session for a full day of varied work.
      By afternoon, every message processes 150K tokens of
      stale context from morning tasks.

Good: /clear between unrelated tasks. Start fresh with
      specific context for each task.
```

### Running Subagents on Opus

```text
Bad:  "use a subagent to find all files containing TODO"
      (runs on your main model -- Opus at $5/MTok input)

Good: Configure subagent model:
      CLAUDE_CODE_SUBAGENT_MODEL=haiku
      or per-agent: model: haiku in the agent YAML
```

### No Budget Controls in CI

```text
Bad:  claude -p "Fix all bugs in the codebase"
      (unbounded turns, unbounded cost)

Good: claude -p --max-turns 10 --max-budget-usd 5.00 \
        --model sonnet "Fix the login bug in @src/auth.ts"
```

### Ignoring Prompt Caching

```text
Bad:  Disabling prompt caching to "save money"
      (DISABLE_PROMPT_CACHING=1)

Good: Let prompt caching work. Cache reads are 10x cheaper
      than uncached input. Disabling it increases costs.
```

Prompt caching is always net positive for Claude Code usage patterns. Don't disable it unless debugging specific issues.

## References

- [Manage Costs Effectively (Claude Code Docs)](https://code.claude.com/docs/en/costs) -- Official cost management guide
- [Model Configuration (Claude Code Docs)](https://code.claude.com/docs/en/model-config) -- Model aliases, effort levels, environment variables
- [Models Overview (Claude API Docs)](https://platform.claude.com/docs/en/about-claude/models/overview) -- Full model comparison and pricing
- [Prompt Caching (Claude API Docs)](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) -- Cache mechanics and pricing
- [Prompt Caching Article]({{< relref "/internals/prompt-caching" >}}) -- Wiki deep dive on caching economics
- [Context Management Article]({{< relref "/internals/context-management" >}}) -- Wiki guide to managing context window
- [Token Optimization Article]({{< relref "/internals/token-optimization" >}}) -- Wiki guide to reducing per-message overhead
- [Extended Thinking Article]({{< relref "/internals/extended-thinking" >}}) -- Thinking budgets, effort levels, adaptive thinking details
