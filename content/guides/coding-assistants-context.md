---
title: "How Coding Assistants Manage Context"
linkTitle: "Coding Assistants and Context"
weight: 4
---

# How Coding Assistants Manage Context

Raw API usage gives you a context window and a model. Everything else -- deciding what to put in that window, when to remove it, and how to structure requests -- is your problem. Coding assistants like Claude Code and GitHub Copilot take on parts of that work automatically.

This page covers what they actually do, where the approaches differ, and where both fall short.

## The Core Problem

Every token in the context window is there for the entire request. The model attends to all of it when generating each response token. A file you read at turn 3 that hasn't been relevant since is still consuming context at turn 50 -- and its presence means less space for content that is relevant now.

Left unmanaged, a session fills with:

- File contents read once and never referenced again
- Long error traces from debugging paths that were abandoned
- Redundant conversation history describing work that's already done
- Tool call metadata that carries no useful information forward

The model's responses don't degrade suddenly when context fills up. They degrade gradually as the ratio of relevant to irrelevant content shifts. Managing context is really managing that ratio.

## What Coding Assistants Do

### Selective File Injection

The biggest single lever. Instead of loading entire files, a good assistant reads only what's needed for the current task.

```text
Naive approach:
  Read auth.go (1,800 lines = ~14,000 tokens)

Selective approach:
  Grep for "handleLogin" → found at line 247
  Read auth.go lines 240-290 (~400 tokens)
```

A 1,800-line file costs roughly 14,000 tokens to load. A 50-line range costs roughly 400. Over a session with many file reads, the difference compounds.

Claude Code does this reactively -- it uses grep and glob tools to locate relevant content before reading. Copilot uses a static workspace index and retrieves chunks it scores as relevant to your current cursor position or query. The reactive approach is more precise; the index approach is faster.

### Subagent Isolation

Claude Code's Task tool runs delegated work in a separate context window. The investigation happens in its own 200K-token space and returns a summary.

```text
Main context (200K)              Subagent context (200K)
┌──────────────────┐             ┌───────────────────┐
│ System prompt    │             │ Subagent prompt   │
│ Conversation     │ ──────────→ │ 35 turns of       │
│ "Find all usages │             │ grep, read, trace │
│  of legacy API"  │             │ across 12 files   │
│                  │ ←────────── │                   │
│ ← 400-token      │             │ Detailed findings │
│   summary        │             └───────────────────┘
└──────────────────┘

Main context cost: ~400 tokens
Subagent context cost: ~18,000 tokens (isolated, discarded)
```

Without subagents, that 35-turn investigation runs in the main context and consumes 18,000 tokens that never leave. With subagents, the main context pays only for the summary.

Copilot has no equivalent mechanism. All work happens in a single context.

### Conversation Compaction

When context approaches the limit, Claude Code automatically summarizes older turns to free up space. The session continues without interruption.

```text
Before compaction (~180K tokens):
  System prompt: 15K
  Turns 1-47: 160K
  Current turn: 5K

After compaction (~35K tokens):
  System prompt: 15K
  Summary of turns 1-45: 3K
  Turns 46-47 verbatim: 12K
  Current turn: 5K
```

The tradeoff is lossy compression: exact file contents from earlier reads, intermediate debugging steps, and abandoned exploration paths are reduced to prose summaries. After multiple compaction cycles, early session detail is significantly thinned.

You can also trigger compaction manually before a large task to maximize available space:

```bash
/compact Focus on the authentication changes we've made so far
```

The custom instruction tells Claude what to preserve in the summary.

Copilot manages context differently -- it operates on shorter interaction windows and doesn't maintain session-length conversation history in the same way, so compaction isn't part of its model.

### Prompt Caching

The system prompt, CLAUDE.md contents, and tool definitions are identical on every API call in a session. Prompt caching means these are processed once and the result is reused on subsequent calls.

This doesn't change how much context window space they consume -- a 15K-token system prompt still occupies 15K tokens on every call. But it reduces the cost and latency of those tokens significantly. On Opus 4.6, cached input tokens cost $0.50/MTok vs $7.50/MTok uncached -- a 93% reduction for content that repeats every message.

See the [Prompt Caching article]({{< relref "prompt-caching" >}}) for details.

### Workspace Indexing (Copilot)

Copilot maintains a static index of the workspace and retrieves chunks scored as relevant to the current context -- your open file, cursor position, recent edits, and query. This happens before the model call, so the model receives pre-filtered context rather than raw file contents.

The advantage is speed: retrieval is fast and doesn't require tool calls. The disadvantage is that static scoring can miss relevance that only becomes apparent during reasoning -- a file that's important because of a dependency chain, not because it shares keywords with the current file.

Claude Code's reactive approach (grep → read → reason → grep again) is slower but can follow dependency chains that a static index would miss.

## Comparison

| Capability                  | Claude Code                          | Copilot                          |
| --------------------------- | ------------------------------------ | -------------------------------- |
| File injection strategy     | Reactive (grep/glob/read)            | Static index retrieval           |
| Subagent isolation          | Yes (Task tool)                      | No                               |
| Conversation compaction     | Automatic + manual `/compact`        | Not applicable                   |
| Prompt caching              | Yes                                  | Yes (implementation varies)      |
| Persistent memory           | CLAUDE.md, auto memory (opt-in)      | Limited (recent history only)    |
| Context window              | 200K standard, 1M extended (beta)    | Varies by model/plan             |

## Where Both Fall Short

Neither tool changes the fundamental constraint: the model generates each response token conditioned only on what's currently in the context window. There is no retrieval, no background memory, no persistent state -- only what fits in the window right now.

**Long sessions degrade.** Compaction is lossy. After two or three cycles, the model has lost the exact wording of earlier decisions, the specific error messages from debugging paths, and the reasoning behind choices made 40 turns ago. The model's capability is unchanged; the information available to it is thinner.

**No cross-session memory without explicit tooling.** Every new session starts blank. Claude Code's CLAUDE.md and auto memory features compensate for this, but they're opt-in and require the model to write state to files during the session. If it doesn't, the next session has no record of what was done.

**Context budget is finite and fills fast.** A 200K context window sounds large. With a 15K system prompt, active conversation history, and several file reads, a session can approach limits in 50-100 turns. Tool-heavy workflows hit limits faster than conversational ones.

**Attention dilution.** Even within limits, a context window packed with loosely relevant content produces lower quality responses than a focused context with only what matters. The model doesn't "ignore" irrelevant content -- it attends to all of it, and irrelevant tokens compete with relevant ones.

## Practical Implications

Start new sessions for distinct tasks. Context accumulated across unrelated work takes up space and has no value for the current task.

Delegate exploration to subagents. Any task involving reading 3+ files or taking more than 10 turns to investigate is a candidate for the Task tool.

Use `/compact` proactively. Before starting a large task, compact with custom instructions to preserve the decisions that matter and discard the rest.

Keep CLAUDE.md concise. It's re-sent on every message. Every line is a fixed cost. Put project conventions there; don't use it as a session log.

Be specific in requests. Vague requests produce exploratory tool calls. Exploratory tool calls dump file contents into context. Most of that content won't be referenced again.

## References

- [Context Management]({{< relref "context-management" >}}) -- How the context window fills over a session and strategies for managing it
- [Token Optimization]({{< relref "token-optimization" >}}) -- Auditing and reducing baseline token overhead
- [Prompt Caching]({{< relref "prompt-caching" >}}) -- Cost reduction for repeated content
- [Extension Mechanisms]({{< relref "/extending/extension-mechanisms" >}}) -- Subagents and the Task tool
- [Tool Execution Context]({{< relref "tool-execution-context" >}}) -- How context behaves during bash tool chains
