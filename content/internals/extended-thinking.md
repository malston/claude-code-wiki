---
title: "Extended Thinking: How Claude Reasons Through Complex Problems"
linkTitle: "Extended Thinking"
weight: 5
---

# Extended Thinking: How Claude Reasons Through Complex Problems

## Executive Summary

Extended thinking gives Claude additional tokens to reason before responding. On Opus 4.6 and Sonnet 4.6, thinking is adaptive: Claude decides how much to think based on task complexity. Thinking tokens are billed as output tokens ($25/MTok on Opus 4.6), making thinking depth the second-biggest cost lever after model selection. On Opus 4.6, effort levels (low/medium/high/max) control how much Claude thinks; Sonnet 4.6 supports low/medium/high effort.

| Aspect                          | Details                                                |
| ------------------------------- | ------------------------------------------------------ |
| **Default state**               | Enabled by default in Claude Code                      |
| **Opus 4.6 / Sonnet 4.6 mode**  | Adaptive (dynamic depth based on complexity)           |
| **Other models**                | Manual (fixed budget via `budget_tokens`)              |
| **Default budget**              | 31,999 tokens (configurable via `MAX_THINKING_TOKENS`) |
| **Billing**                     | Thinking tokens billed as output tokens                |
| **Visibility**                  | Summarized view; `Ctrl+O` for verbose thinking text    |

---

## Table of Contents

- [Extended Thinking: How Claude Reasons Through Complex Problems](#extended-thinking-how-claude-reasons-through-complex-problems)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [How Extended Thinking Works](#how-extended-thinking-works)
    - [Why Intermediate Tokens Help](#why-intermediate-tokens-help)
    - [The Thinking Process](#the-thinking-process)
    - [Adaptive Thinking (Opus 4.6)](#adaptive-thinking-opus-46)
    - [Summarized Thinking](#summarized-thinking)
    - [Interleaved Thinking](#interleaved-thinking)
  - [Effort Levels](#effort-levels)
    - [Available Levels](#available-levels)
    - [What Effort Controls](#what-effort-controls)
    - [Setting Effort in Claude Code](#setting-effort-in-claude-code)
  - [Configuration](#configuration)
    - [Toggle Thinking On/Off](#toggle-thinking-onoff)
    - [MAX\_THINKING\_TOKENS](#max_thinking_tokens)
    - [Thinking Budget vs Output Budget](#thinking-budget-vs-output-budget)
    - [Context Window Interaction](#context-window-interaction)
    - [Thinking in Subagents](#thinking-in-subagents)
  - [When to Use Extended Thinking](#when-to-use-extended-thinking)
    - [Tasks That Benefit](#tasks-that-benefit)
    - [Tasks Where It's Overkill](#tasks-where-its-overkill)
  - [Cost Management](#cost-management)
    - [How Thinking Tokens Are Billed](#how-thinking-tokens-are-billed)
    - [Cost Control Levers](#cost-control-levers)
    - [Cost Estimates](#cost-estimates)
  - [Model Support](#model-support)
    - [Feature Compatibility](#feature-compatibility)
  - [Best Practices](#best-practices)
  - [Anti-Patterns](#anti-patterns)
  - [References](#references)

---

## How Extended Thinking Works

### Why Intermediate Tokens Help

Token generation is autoregressive: each token is predicted from all prior tokens in the context window. When Claude generates intermediate reasoning tokens, those tokens become context for the tokens that follow. The model is using its own output as working memory.

A direct prompt-to-answer jump gives the final answer a short context to condition on. A chain of intermediate steps -- exploring an approach, identifying a constraint, reconsidering -- gives the final answer more to work from. This is why thinking improves quality on problems that require multiple dependent steps, and why it has no effect on problems where the answer is immediate.

There is no separate reasoning system running in parallel. The thinking phase and the response phase use the same next-token prediction mechanism. The difference is that thinking tokens are generated first, accumulate in context, and are then available when the response tokens are generated.

### The Thinking Process

When thinking is enabled, Claude generates internal reasoning before crafting its response:

```text
User prompt arrives
    │
    ▼
┌─────────────────────┐
│  Thinking Phase     │  Claude generates intermediate reasoning:
│  (thinking tokens)  │  - Explores approaches
│                     │  - Identifies constraints and edge cases
│                     │  - Backtracks from dead ends
│                     │  - Commits to an approach
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Summary Phase      │  Full thinking summarized
│  (no extra charge)  │  for user visibility
└──────────┬──────────┘
           │
           ▼
┌─────────────────────┐
│  Response Phase     │  Final answer conditioned
│  (output tokens)    │  on all prior thinking tokens
└─────────────────────┘
```

The thinking phase is where quality differences appear. On problems that require multiple dependent steps, thinking tokens give the response tokens more context to condition on. On problems that don't -- simple lookups, mechanical edits -- thinking tokens add cost without improving output.

### Adaptive Thinking (Opus 4.6)

Opus 4.6 uses **adaptive thinking** by default. Instead of a fixed budget, Claude decides how much to think based on the complexity of each request:

- Simple requests (rename a variable, fix a typo): minimal or no thinking
- Moderate requests (implement a function, fix a bug): moderate thinking
- Complex requests (architect a system, debug a race condition): deep thinking

This replaces the manual `budget_tokens` approach used on earlier models. You don't need to estimate how many thinking tokens a task needs -- Claude adjusts automatically.

Combined with effort levels, adaptive thinking gives you a spectrum from fast/cheap to thorough/expensive without manual tuning.

### Summarized Thinking

Claude 4 models return a **summarized** version of the thinking, not the raw thinking output:

- You see a summary of the key reasoning steps
- You are billed for the **full** thinking tokens, not the summary
- The summary is generated by a separate model at no extra charge
- The thinking model does not see the summarized output

The billed output token count will be higher than the visible token count. This is expected.

In Claude Code, toggle verbose mode (`Ctrl+O`) to see the thinking text as gray italic text in the transcript.

### Interleaved Thinking

With tool use, Claude can think **between** tool calls, not just before the first response:

```text
Think → Call tool → Read result → Think again → Call another tool → Think → Respond
```

On Opus 4.6 with adaptive thinking, interleaved thinking is automatic. On earlier models, it requires a beta header. In Claude Code, this is handled transparently -- you don't need to configure anything.

Interleaved thinking is useful for multi-step tasks where each tool result changes what to do next. Claude can reconsider its approach after seeing actual file contents or command output rather than committing to a plan upfront.

## Effort Levels

### Available Levels

| Level      | Thinking Behavior                     | Speed   | Cost    | Availability  |
| ---------- | ------------------------------------- | ------- | ------- | ------------- |
| **max**    | No depth limit, absolute maximum      | Slowest | Highest | Opus 4.6 only |
| **high**   | Almost always thinks deeply (default) | Slow    | High    | All models    |
| **medium** | May skip thinking for simple queries  | Medium  | Medium  | All models    |
| **low**    | Minimizes or skips thinking           | Fast    | Low     | All models    |

`max` is exclusive to Opus 4.6 and errors on other models.

Effort is a **behavioral signal, not a strict token budget**. At lower effort, Claude still thinks on genuinely difficult problems -- it just thinks less than it would at higher effort for the same problem.

### What Effort Controls

Effort affects **all tokens** in the response, not just thinking:

| Aspect             | Low Effort                          | High Effort                     |
| ------------------ | ----------------------------------- | ------------------------------- |
| Thinking depth     | Minimal or skipped for simple tasks | Deep reasoning on most tasks    |
| Tool calls         | Fewer, combined operations          | More, thorough exploration      |
| Explanations       | Terse confirmations                 | Detailed plans and summaries    |
| Code comments      | Minimal                             | Comprehensive                   |
| Action style       | Proceeds directly                   | Explains approach before acting |

### Setting Effort in Claude Code

Three methods, in order of priority:

- `/model` command: Use left/right arrow keys to adjust the effort slider when selecting a model.
- Environment variable: `CLAUDE_CODE_EFFORT_LEVEL=low|medium|high`
- Settings file: Set `effortLevel` in your settings JSON.

---

## Configuration

### Toggle Thinking On/Off

| Method          | Scope           | Details                                         |
| --------------- | --------------- | ----------------------------------------------- |
| `Option+T` / `Alt+T` | Current session | Toggles thinking for this session only     |
| `/config`       | Permanent       | Saved as `alwaysThinkingEnabled` in settings    |
| `Ctrl+O`        | Display only    | Shows thinking text in verbose mode             |

### MAX_THINKING_TOKENS

Controls the thinking token budget for manual-mode models:

| Setting          | Value          |
| ---------------- | -------------- |
| Default          | 31,999 tokens  |
| Maximum          | 63,999 tokens  |
| Minimum          | 1,024 tokens   |
| Disable thinking | Set to `0`     |

```bash
# Temporary (session only)
MAX_THINKING_TOKENS=63999 claude

# Permanent
export MAX_THINKING_TOKENS=63999  # in ~/.zshrc or ~/.bashrc
```

On Opus 4.6, `MAX_THINKING_TOKENS` is ignored because adaptive thinking controls depth dynamically. Exception: setting it to `0` still disables thinking entirely.

### Thinking Budget vs Output Budget

- `budget_tokens` must be less than `max_tokens` (standard mode)
- With interleaved thinking (tool use), `budget_tokens` can exceed `max_tokens`
- Opus 4.6: up to 128K output tokens
- Earlier models: up to 64K output tokens

The budget is a target, not a strict limit -- actual usage varies by task.

### Context Window Interaction

Thinking tokens interact with the context window differently depending on the model:

**Opus 4.5 and later (including 4.6):** Thinking blocks from previous turns are preserved in context. Thinking tokens consume context window space across turns.

**Earlier models:** Thinking blocks are stripped from context between turns. Only the final response carries forward.

**With tool use (all models):**

```text
context = input tokens + previous thinking tokens + tool tokens + new thinking + response
```

**Without tool use:**

```text
context = input tokens - previous thinking tokens + new thinking + response
```

### Thinking in Subagents

Each subagent has its own context window and thinking budget. Considerations:

- Set `model: haiku` or `model: sonnet` on subagents that don't need deep reasoning
- `CLAUDE_CODE_SUBAGENT_MODEL` overrides all subagent model settings
- Low effort is recommended for subagents doing simple tasks (research, file searching)
- Thinking adds latency -- for parallel subagent work, lower effort means faster results

---

## When to Use Extended Thinking

The deciding factor is whether the task requires multiple dependent reasoning steps. If the answer requires working through constraints, dependencies, or tradeoffs that build on each other, thinking tokens improve output. If the answer is deterministic or immediate, they don't.

### Tasks That Benefit

| Task Type                   | Why Thinking Helps                                            |
| --------------------------- | ------------------------------------------------------------- |
| **Architecture decisions**  | Dependencies between components require multi-step analysis   |
| **Complex debugging**       | Hypothesis → test → revise cycles benefit from working memory |
| **Implementation planning** | Sequencing work correctly requires tracking many constraints  |
| **Algorithm design**        | Edge cases interact; reasoning through them compounds         |
| **Security review**         | Data flows require tracing across many steps                  |
| **Multi-file refactoring**  | Cross-file dependencies need to be tracked simultaneously     |

### Tasks Where It's Overkill

| Task Type                   | Why Thinking Adds No Value                     |
| --------------------------- | ---------------------------------------------- |
| **Simple file edits**       | No ambiguity to reason about                   |
| **Formatting changes**      | Mechanical transformation, no judgment needed  |
| **Find-and-replace**        | Deterministic operation                        |
| **File reads and searches** | No decision-making involved                    |
| **Quick lookups**           | Answer is immediate, no reasoning chain needed |

On Opus 4.6 with adaptive thinking, Claude already allocates less thinking to simple tasks. For explicit control, use `low` effort for routine work and `high` or `max` for complex tasks.

## Cost Management

### How Thinking Tokens Are Billed

Thinking tokens are billed as **output tokens** at the model's output rate:

| Model          | Output Rate (including thinking) | Cache Read |
| -------------- | -------------------------------- | ---------- |
| **Opus 4.6**   | $25/MTok                         | $0.50/MTok |
| **Sonnet 4.5** | $15/MTok                         | $0.30/MTok |
| **Haiku 4.5**  | $5/MTok                          | $0.10/MTok |

A request that generates 10,000 thinking tokens + 2,000 response tokens costs the same as 12,000 output tokens.

### Cost Control Levers

| Lever                     | Effect                                        | How to Set                         |
| ------------------------- | --------------------------------------------- | ---------------------------------- |
| **Effort level**          | Controls thinking depth (biggest lever)       | `/model` slider, env var, settings |
| **Model selection**       | Sonnet at $15/MTok vs Opus at $25/MTok        | `/model` command                   |
| **Disable thinking**      | Zero thinking tokens                          | `Option+T` / `Alt+T`, `/config`    |
| **MAX_THINKING_TOKENS**   | Cap thinking budget (non-Opus-4.6 models)     | Environment variable               |
| **Subagent model choice** | Use cheaper models for simple delegated tasks | Per-agent `model:` field           |

### Cost Estimates

Rough estimates for a 100-message Opus 4.6 session:

| Effort Level | Avg Thinking Tokens/Msg | Thinking Cost (100 msgs) | Total Session Cost |
| ------------ | ----------------------- | ------------------------ | ------------------ |
| **max**      | ~20,000                 | ~$50                     | ~$60-75            |
| **high**     | ~10,000                 | ~$25                     | ~$35-50            |
| **medium**   | ~5,000                  | ~$12.50                  | ~$20-30            |
| **low**      | ~1,000                  | ~$2.50                   | ~$10-15            |

Actual costs vary based on task complexity, response length, and tool call volume.

## Model Support

| Model            | Thinking Mode   | Effort Levels          | Interleaved | Max Output |
| ---------------- | --------------- | ---------------------- | ----------- | ---------- |
| **Opus 4.6**     | Adaptive        | low, medium, high, max | Automatic   | 128K       |
| **Sonnet 4.6**   | Adaptive        | low, medium, high      | Automatic   | 64K        |
| **Opus 4.5**     | Manual (budget) | low, medium, high      | Beta header | 128K       |
| **Sonnet 4.5**   | Manual (budget) | --                     | Beta header | 64K        |
| **Haiku 4.5**    | Manual (budget) | --                     | Beta header | 64K        |

Adaptive thinking is available on Opus 4.6 and Sonnet 4.6. Manual `budget_tokens` mode is deprecated on these models but remains available on all others. `max` effort remains exclusive to Opus 4.6.

### Feature Compatibility

Extended thinking is **not compatible** with:

- `temperature` modifications (must be default)
- `top_k` modifications
- Forced tool use (`tool_choice: "any"` or `tool_choice: "tool"`)
- Response pre-filling

`top_p` can be set between 0.95 and 1.0 when thinking is enabled.

Changing thinking parameters invalidates prompt cache for messages, though system prompts and tool definitions remain cached.

## Best Practices

1. **Use adaptive thinking on Opus 4.6.** Don't set manual budgets -- let Claude decide how much to think. This is the default in Claude Code and works well for most workflows.

2. **Use effort levels as your primary cost control.** Instead of toggling thinking on/off, adjust effort. `medium` provides a good balance for daily work. `high` or `max` for complex architecture and debugging.

3. **Use lower effort for subagents.** Subagents doing research, file searching, or simple analysis don't need deep thinking. Set `model: sonnet` or effort to `low` on delegated tasks.

4. **Don't optimize thinking for simple tasks.** On Opus 4.6 with adaptive thinking, Claude already minimizes thinking for simple requests.

5. **Enable verbose mode for debugging.** `Ctrl+O` shows thinking text, which helps understand why Claude made specific decisions. Useful when Claude's response doesn't match expectations.

6. **Budget thinking tokens for cost-sensitive workflows.** In CI/CD or headless mode, set `MAX_THINKING_TOKENS` to a reasonable cap to prevent runaway costs on unexpectedly complex inputs.

7. **Use the `opusplan` alias.** Opus for planning (where thinking helps most) and Sonnet for execution (where thinking is less critical) is a reasonable cost/quality split.

## Anti-Patterns

1. **Setting MAX_THINKING_TOKENS on Opus 4.6.** The variable is ignored on Opus 4.6 (except `0`). Use effort levels instead.

2. **Disabling thinking globally.** On complex tasks, thinking tokens are where quality improvements come from. Disable it per-task if needed, not globally.

3. **Using "ultrathink" or "think hard" in prompts.** These phrases are interpreted as regular text, not as thinking budget controls. The old "ultrathink" keyword hack has been deprecated.

4. **Max effort on routine tasks.** `max` effort on simple file edits wastes tokens and adds latency. Reserve `max` for tasks that require many dependent reasoning steps.

5. **Expecting visible token counts to match billing.** Claude 4 models show summarized thinking. The billed count (full thinking) is higher than what you see. This is expected, not a bug.

6. **Ignoring thinking costs in headless mode.** Automated pipelines can run many requests. Without `MAX_THINKING_TOKENS` or effort limits, thinking costs accumulate quickly.

## References

- [Extended Thinking (API)](https://platform.claude.com/docs/en/build-with-claude/extended-thinking) -- API-level thinking configuration
- [Adaptive Thinking](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking) -- Opus 4.6 adaptive mode
- [Effort Parameter](https://platform.claude.com/docs/en/build-with-claude/effort) -- effort levels and behavioral effects
- [Extended Thinking Tips](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/extended-thinking-tips) -- prompt engineering for thinking
- [Model Configuration (Claude Code)](https://code.claude.com/docs/en/model-config) -- effort levels, model aliases, thinking settings
- [Cost Management (Claude Code)](https://code.claude.com/docs/en/costs) -- pricing, typical costs
- [Pricing](https://platform.claude.com/docs/en/about-claude/pricing) -- token pricing per model
- [Model Selection Article]({{< relref "/guides/model-selection" >}}) -- model comparison and cost strategies
