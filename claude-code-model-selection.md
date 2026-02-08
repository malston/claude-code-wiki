# Model Selection & Cost Management: Choosing the Right Model and Controlling Spend

## Executive Summary

Claude Code offers three model tiers -- Opus, Sonnet, and Haiku -- each with different capability, speed, and cost profiles. The right model depends on the task: Opus for complex reasoning, Sonnet for daily coding, Haiku for fast simple tasks. Beyond model choice, Claude Code provides several cost control mechanisms: prompt caching, auto-compaction, budget caps, effort levels, and subagent model selection. This article covers how to choose models, configure them, and manage costs effectively.

| Model          | Strengths                       | Input/MTok | Output/MTok | Cache Read | Speed    |
| -------------- | ------------------------------- | ---------- | ----------- | ---------- | -------- |
| **Opus 4.6**   | Complex reasoning, architecture | $5         | $25         | $0.50      | Moderate |
| **Sonnet 4.5** | Daily coding, balanced          | $3         | $15         | $0.30      | Fast     |
| **Haiku 4.5**  | Quick tasks, simple operations  | $1         | $5          | $0.10      | Fastest  |

---

## Table of Contents

- [The Model Lineup](#the-model-lineup)
  - [Opus 4.6](#opus-46)
  - [Sonnet 4.5](#sonnet-45)
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
  - [Extended Context](#extended-context)
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
- [References](#references)

---

## The Model Lineup

### Opus 4.6

The most capable model. Best for tasks requiring deep reasoning, complex architecture decisions, multi-step planning, and extended thinking.

| Attribute          | Value                      |
| ------------------ | -------------------------- |
| Input pricing      | $5/MTok                    |
| Output pricing     | $25/MTok                   |
| Cache read pricing | $0.50/MTok                 |
| Context window     | 200K (standard), 1M (beta) |
| Max output         | 128K tokens                |
| Extended thinking  | Yes (adaptive)             |
| Effort levels      | Low, medium, high          |
| Knowledge cutoff   | May 2025                   |

Opus 4.6 is the default for Max, Teams, and Pro subscribers. It supports adaptive thinking -- dynamically allocating reasoning depth based on task complexity.

### Sonnet 4.5

The workhorse model. Handles most coding tasks effectively at lower cost and faster speed than Opus.

| Attribute          | Value                      |
| ------------------ | -------------------------- |
| Input pricing      | $3/MTok                    |
| Output pricing     | $15/MTok                   |
| Cache read pricing | $0.30/MTok                 |
| Context window     | 200K (standard), 1M (beta) |
| Max output         | 64K tokens                 |
| Extended thinking  | Yes                        |
| Knowledge cutoff   | January 2025               |

Anthropic's official recommendation for uncertain model choice. Good at code generation, bug fixing, test writing, and refactoring.

### Haiku 4.5

The speed-optimized model. Best for simple tasks where response time matters more than depth.

| Attribute          | Value         |
| ------------------ | ------------- |
| Input pricing      | $1/MTok       |
| Output pricing     | $5/MTok       |
| Cache read pricing | $0.10/MTok    |
| Context window     | 200K          |
| Max output         | 64K tokens    |
| Extended thinking  | Yes           |
| Knowledge cutoff   | February 2025 |

5x cheaper than Opus on input, 5x cheaper on output. Good for subagent tasks, simple lookups, and quick operations that don't need deep reasoning.

### Legacy Models

Still available but migration recommended:

| Model    | Input/MTok | Output/MTok | Notes                             |
| -------- | ---------- | ----------- | --------------------------------- |
| Opus 4.5 | $5         | $25         | Same pricing as 4.6, less capable |
| Opus 4.1 | $15        | $75         | 3x more expensive than 4.6        |
| Sonnet 4 | $3         | $15         | Same pricing as 4.5               |
| Opus 4   | $15        | $75         | 3x more expensive than 4.6        |

Opus 4.6 is strictly better and cheaper than Opus 4.1 and Opus 4. There's no reason to stay on the older models.

---

## When to Use Each Model

### Decision Framework

```
Is the task complex reasoning, architecture, or multi-step planning?
  YES ──▶ Opus 4.6
  NO  ──▼

Is it standard coding work (features, bugs, refactoring, tests)?
  YES ──▶ Sonnet 4.5
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

---

## Configuring Models in Claude Code

### Model Aliases

Claude Code provides convenience aliases that always point to the latest version:

| Alias        | Resolves To         | Use Case                              |
| ------------ | ------------------- | ------------------------------------- |
| `default`    | Account-dependent   | Let Claude Code choose                |
| `opus`       | Opus 4.6            | Complex reasoning                     |
| `sonnet`     | Sonnet 4.5          | Daily coding                          |
| `haiku`      | Haiku 4.5           | Fast simple tasks                     |
| `sonnet[1m]` | Sonnet 4.5 + 1M ctx | Long sessions                         |
| `opusplan`   | Opus + Sonnet       | Plan with Opus, implement with Sonnet |

To pin a specific version (e.g., for reproducibility), use the full model name:

```bash
claude --model claude-sonnet-4-5-20250929
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

Opus 4.6 supports adaptive thinking with three effort levels that control how deeply it reasons:

| Level      | Behavior                                | When to Use                     |
| ---------- | --------------------------------------- | ------------------------------- |
| **High**   | Deep reasoning, full thinking (default) | Architecture, complex bugs      |
| **Medium** | Moderate reasoning                      | Standard features, clear tasks  |
| **Low**    | Fast, minimal thinking                  | Simple fixes, well-defined work |

Configure effort:

```bash
# Environment variable
CLAUDE_CODE_EFFORT_LEVEL=medium claude

# In settings.json
{ "effortLevel": "medium" }

# In /model menu, use left/right arrow keys to adjust
```

Lower effort = fewer thinking tokens = lower cost and faster response. A `medium` effort Opus session can cost significantly less than `high` while still outperforming Sonnet on reasoning tasks.

### Extended Context

The `[1m]` suffix enables 1 million token context windows:

```bash
/model sonnet[1m]
/model claude-sonnet-4-5-20250929[1m]
```

Extended context costs 2x input pricing above 200K tokens. Use it for sessions that involve reading many large files, not as a default.

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

```
"use a subagent with model haiku to search for all TODO comments"
```

Running subagents on Haiku is one of the highest-leverage cost optimizations. Most subagent tasks -- file searches, pattern matching, codebase exploration -- don't need Opus-level reasoning.

---

## Understanding Costs

### How Costs Accumulate

Every message in Claude Code sends the full conversation context to the API. Costs scale with:

```
Cost per message ≈ (system prompt + conversation history + new input) × input price
                  + (response length) × output price
                  + (thinking tokens) × output price
```

The system prompt (12,000-20,000 tokens) is re-sent every message but heavily cached. The conversation history grows with each turn. Auto-compaction kicks in at ~75-92% context usage, summarizing older messages.

### Prompt Caching Economics

Prompt caching dramatically reduces the cost of re-sending the system prompt and stable conversation prefix:

| Operation      | Multiplier | Opus 4.6   | Sonnet 4.5 | Haiku 4.5  |
| -------------- | ---------- | ---------- | ---------- | ---------- |
| Cache write    | 1.25x base | $6.25/MTok | $3.75/MTok | $1.25/MTok |
| **Cache read** | **0.1x**   | **$0.50**  | **$0.30**  | **$0.10**  |
| Uncached input | 1x base    | $5/MTok    | $3/MTok    | $1/MTok    |

Cache reads are 10x cheaper than base input. After the first message in a session, most of the system prompt is cached. Over a 200-message session, a 15,000-token system prompt costs ~$1.60 with caching vs ~$15 without (using Opus 4.6).

Claude Code manages cache breakpoints automatically -- there's nothing to configure.

### Extended Thinking Costs

Extended thinking tokens are billed as output tokens. With Opus 4.6 at $25/MTok output:

| Thinking budget  | Cost per use (if fully consumed) |
| ---------------- | -------------------------------- |
| 32K tokens (max) | ~$0.80                           |
| 16K tokens       | ~$0.40                           |
| 8K tokens        | ~$0.20                           |
| Disabled         | $0                               |

Control thinking budget:

```bash
# Reduce thinking tokens
MAX_THINKING_TOKENS=8000 claude

# Disable thinking entirely
# (via /config → Extended thinking → Off)
```

Lower effort levels also reduce thinking token consumption.

### Typical Cost Ranges

From Anthropic's data:

- **Average:** ~$6/developer/day
- **90th percentile:** <$12/developer/day
- **Monthly average:** ~$100-200/developer (Sonnet 4.5)
- **Background usage:** <$0.04/session (summarization, status checks)

These numbers assume Sonnet 4.5. Opus sessions cost roughly 1.7x more for the same work due to higher input/output pricing.

---

## Cost Reduction Strategies

### Context Management

Context size is the primary cost driver. Smaller context = cheaper messages.

**Clear between tasks:**

```
/clear    # Reset context when switching to unrelated work
```

Stale context wastes tokens on every subsequent message. Use `/rename` before clearing so you can `/resume` later.

**Compact proactively:**

```
/compact Focus on code changes and test results
```

Auto-compaction triggers at ~75-92% usage, but manual compaction lets you control what's preserved.

**Use subagents for investigation:**

```
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

```
/context    # See context breakdown
```

**Disable unused MCP servers:**

```
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

---

## Tracking and Monitoring Costs

### Session-Level Tracking

```
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

---

## Best Practices

1. **Default to Sonnet.** Most coding tasks don't need Opus. Switch up only when you need deeper reasoning.

2. **Use opusplan for features.** Plan with Opus, execute with Sonnet -- best of both worlds without paying Opus rates for implementation.

3. **Run subagents on Haiku.** File searches, pattern matching, and codebase exploration are Haiku-level tasks. Set `CLAUDE_CODE_SUBAGENT_MODEL=haiku` or configure per-agent.

4. **Clear between tasks.** `/clear` is the single most effective cost reduction. Stale context is wasted money on every subsequent message.

5. **Lower effort for clear tasks.** If you're using Opus and the task is well-defined, use `medium` effort to cut thinking token costs.

6. **Set budget limits in automation.** Every `claude -p` invocation in CI should have `--max-turns` and `--max-budget-usd`.

7. **Check /cost periodically.** Awareness drives behavior. If a session is expensive, ask why -- usually context has grown too large.

8. **Preprocess with hooks.** Don't let Claude read entire log files when a hook can grep for errors first.

9. **Disable unused MCP servers.** Each idle server adds tool definitions to every message. Run `/mcp` and disable what you're not using.

10. **Reduce extended thinking for simple tasks.** Set `MAX_THINKING_TOKENS=8000` or disable thinking when deep reasoning isn't needed.

---

## Anti-Patterns

### Using Opus for Everything

```
Bad:  claude --model opus
      "rename this variable from foo to bar"
      (Opus costs 1.7x more for a task Sonnet handles perfectly)

Good: claude --model sonnet
      "rename this variable from foo to bar"
```

Reserve Opus for tasks that actually benefit from its reasoning capabilities.

### Never Clearing Context

```
Bad:  One continuous session for a full day of varied work.
      By afternoon, every message processes 150K tokens of
      stale context from morning tasks.

Good: /clear between unrelated tasks. Start fresh with
      specific context for each task.
```

### Running Subagents on Opus

```
Bad:  "use a subagent to find all files containing TODO"
      (runs on your main model -- Opus at $5/MTok input)

Good: Configure subagent model:
      CLAUDE_CODE_SUBAGENT_MODEL=haiku
      or per-agent: model: haiku in the agent YAML
```

### No Budget Controls in CI

```
Bad:  claude -p "Fix all bugs in the codebase"
      (unbounded turns, unbounded cost)

Good: claude -p --max-turns 10 --max-budget-usd 5.00 \
        --model sonnet "Fix the login bug in @src/auth.ts"
```

### Ignoring Prompt Caching

```
Bad:  Disabling prompt caching to "save money"
      (DISABLE_PROMPT_CACHING=1)

Good: Let prompt caching work. Cache reads are 10x cheaper
      than uncached input. Disabling it increases costs.
```

Prompt caching is always net positive for Claude Code usage patterns. Don't disable it unless debugging specific issues.

---

## References

- [Manage Costs Effectively (Claude Code Docs)](https://code.claude.com/docs/en/costs) -- Official cost management guide
- [Model Configuration (Claude Code Docs)](https://code.claude.com/docs/en/model-config) -- Model aliases, effort levels, environment variables
- [Models Overview (Claude API Docs)](https://platform.claude.com/docs/en/about-claude/models/overview) -- Full model comparison and pricing
- [Prompt Caching (Claude API Docs)](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) -- Cache mechanics and pricing
- [Prompt Caching Article](claude-code-prompt-caching.md) -- Wiki deep dive on caching economics
- [Context Management Article](claude-code-context-management.md) -- Wiki guide to managing context window
- [Token Optimization Article](claude-code-token-optimization.md) -- Wiki guide to reducing per-message overhead
