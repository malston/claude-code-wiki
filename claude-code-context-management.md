# Context Management: Working Within the Token Budget

## Executive Summary

The context window is Claude's working memory -- everything the model can reference when generating a response. In Claude Code, it fills with the system prompt, conversation history, tool results, and file contents. Managing this space is the single most important factor in maintaining effective sessions as they grow longer.

| Model             | Standard Window | Extended (Beta) | Long Context Pricing             |
| ----------------- | --------------- | --------------- | -------------------------------- |
| Claude Opus 4.6   | 200K tokens     | 1M tokens       | 2x input, 1.5x output above 200K |
| Claude Sonnet 4.5 | 200K tokens     | 1M tokens       | 2x input, 1.5x output above 200K |
| Claude Sonnet 4   | 200K tokens     | 1M tokens       | 2x input, 1.5x output above 200K |
| Claude Haiku 4.5  | 200K tokens     | --              | --                               |

**Key insight:** [Prompt caching](claude-code-prompt-caching.md) reduces the _cost_ of repeated content, but every token still occupies context window _space_. You can afford a 20,000-token system prompt financially, but those 20,000 tokens are unavailable for conversation content regardless.

---

## Table of Contents

- [Context Management: Working Within the Token Budget](#context-management-working-within-the-token-budget)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [What the Context Window Is](#what-the-context-window-is)
    - [How It Fills Up](#how-it-fills-up)
    - [What Consumes Context](#what-consumes-context)
    - [A Typical Session's Context Budget](#a-typical-sessions-context-budget)
  - [Context Awareness](#context-awareness)
  - [When Context Runs Out: Compaction](#when-context-runs-out-compaction)
    - [How Compaction Works](#how-compaction-works)
    - [Auto-Compact in Claude Code](#auto-compact-in-claude-code)
    - [Manual Compaction](#manual-compaction)
    - [What Compaction Preserves and Loses](#what-compaction-preserves-and-loses)
  - [Strategies for Context Efficiency](#strategies-for-context-efficiency)
    - [Reduce System Prompt Overhead](#reduce-system-prompt-overhead)
    - [Use Subagents to Offload Work](#use-subagents-to-offload-work)
    - [Be Selective with File Reads](#be-selective-with-file-reads)
    - [Keep Conversations Focused](#keep-conversations-focused)
    - [Use the 1M Context Window](#use-the-1m-context-window)
  - [How Context Flows in Claude Code](#how-context-flows-in-claude-code)
    - [A Single Message Round-Trip](#a-single-message-round-trip)
    - [Growth Over a Session](#growth-over-a-session)
    - [The Compaction Cycle](#the-compaction-cycle)
  - [Subagents as Context Management](#subagents-as-context-management)
    - [How Subagents Help](#how-subagents-help)
    - [When to Delegate vs Stay in Main Context](#when-to-delegate-vs-stay-in-main-context)
  - [Extended Thinking and Context](#extended-thinking-and-context)
  - [Practical Tips](#practical-tips)
  - [References](#references)

---

## What the Context Window Is

The context window is the total space available for all input and output in a single API call. It includes everything Claude can "see" when generating a response: the system prompt, the full conversation history, tool results, and the response itself.

Think of it as a fixed-size desk. The system prompt is a permanent stack of papers that never leaves. Every message you send and every response Claude gives adds more papers. Every file read and tool result adds more. When the desk fills up, something has to go.

### How It Fills Up

Every API call in a Claude Code session sends:

```
Context Window (200K tokens)
┌──────────────────────────────────────────────────┐
│ System prompt (fixed)             ~15,000-20,000 │
│ ┌──────────────────────────────────────────────┐ │
│ │ Conversation history (grows)                 │ │
│ │ ├── User message 1                           │ │
│ │ ├── Assistant response 1 (+ tool calls)      │ │
│ │ ├── Tool results 1 (file contents, etc.)     │ │
│ │ ├── User message 2                           │ │
│ │ ├── Assistant response 2                     │ │
│ │ ├── ...                                      │ │
│ │ └── Latest user message                      │ │
│ └──────────────────────────────────────────────┘ │
│ Response output (current turn)                   │
└──────────────────────────────────────────────────┘
```

The system prompt is constant. The conversation history grows with every turn. The response output needs room too. The usable space for conversation shrinks over time.

### What Consumes Context

Not all content is equal. Some things consume far more tokens than expected:

| Content Type          | Typical Size         | Notes                                                                                    |
| --------------------- | -------------------- | ---------------------------------------------------------------------------------------- |
| System prompt         | 12,000-20,000 tokens | Fixed overhead every message (see [system prompt article](claude-code-system-prompt.md)) |
| User message          | 10-200 tokens        | Your typed input                                                                         |
| Assistant response    | 100-2,000 tokens     | Explanations, reasoning                                                                  |
| Tool call + result    | Varies widely        | A `Read` of a 500-line file can be 5,000+ tokens                                         |
| File read (@-mention) | 100-10,000+ tokens   | Entire file contents injected                                                            |
| Grep/Glob results     | 100-5,000 tokens     | Depends on match count                                                                   |
| Web search results    | 500-3,000 tokens     | Search snippets                                                                          |
| System reminders      | 50-500 tokens        | Hook outputs, plugin status                                                              |

**The biggest consumers are tool results** -- especially file reads. Reading a large file dumps its entire contents into the context. In an active coding session, multiple file reads and their associated tool call metadata can consume the majority of your context budget.

### A Typical Session's Context Budget

For a 200K context window with a 15,000-token system prompt:

```
Available for conversation: 200,000 - 15,000 = 185,000 tokens

At ~100 tokens per typical message exchange:
  Theoretical maximum: ~1,850 simple back-and-forth turns

In practice with tool use (file reads, edits, searches):
  ~200-500 tokens per tool call + result
  ~50-100 meaningful tool-using turns before approaching limits
```

Real sessions hit limits faster than expected because file reads and search results are token-expensive. A single `Read` of a large file can consume as much context as 50 simple messages.

---

## Context Awareness

Claude Sonnet 4.5 and Haiku 4.5 have a built-in feature called **context awareness** -- the model tracks its remaining context budget throughout a conversation.

At session start, Claude receives its total budget:

```
<budget:token_budget>200000</budget:token_budget>
```

After each tool call, Claude receives an update:

```
<system_warning>Token usage: 35000/200000; 165000 remaining</system_warning>
```

This allows Claude to make informed decisions about how to use remaining context -- whether to read a large file, delegate to a subagent, or wrap up work before running out of space.

**Note:** Opus 4.6 does not currently have context awareness -- it does not receive token budget updates. This means Opus may be less efficient at self-managing context in very long sessions.

---

## When Context Runs Out: Compaction

### How Compaction Works

When the conversation approaches the context window limit, Claude Code automatically summarizes older parts of the conversation to free up space. This is called **compaction**.

The process:

1. Input tokens exceed a trigger threshold (default: ~150K tokens)
2. Claude generates a summary of the conversation so far
3. The summary replaces the original conversation history
4. The session continues with the compressed context

```
Before compaction:
┌──────────────────────────────────────────────────┐
│ System prompt                          15,000    │
│ Turn 1: user + assistant + tools       12,000    │
│ Turn 2: user + assistant + tools        8,000    │
│ ...                                              │
│ Turn 47: user + assistant + tools       5,000    │
│ Turn 48: current                        3,000    │
│                                    ──────────    │
│ Total:                               ~180,000    │ ← Approaching limit
└──────────────────────────────────────────────────┘

After compaction:
┌──────────────────────────────────────────────────┐
│ System prompt                          15,000    │
│ [Summary of turns 1-45]                 3,000    │
│ Turn 46: user + assistant + tools       6,000    │
│ Turn 47: user + assistant + tools       5,000    │
│ Turn 48: current                        3,000    │
│                                    ──────────    │
│ Total:                                ~32,000    │ ← Lots of room again
└──────────────────────────────────────────────────┘
```

### Auto-Compact in Claude Code

Claude Code handles compaction automatically. You don't need to configure anything. When the context usage reaches roughly 75-92% (depending on internal heuristics), auto-compact triggers and summarizes the conversation.

You'll see a message like:

```
Auto-compact: Summarizing conversation to free up context...
```

This is normal and expected in long sessions. The session continues seamlessly -- you don't lose your place.

### Manual Compaction

You can also trigger compaction manually at any time using the `/compact` command:

```
/compact                              # Default summarization
/compact Focus on the API changes     # Custom instructions
```

Manual compaction is available when context usage is above ~70%. Use it proactively when:

- You're about to start a large task and want maximum context space
- The conversation has accumulated lots of irrelevant history
- You want to control what gets preserved in the summary

You can also influence compaction behavior through CLAUDE.md instructions to ensure critical context survives summarization.

### What Compaction Preserves and Loses

Compaction is a lossy process. The summary captures the gist of the conversation but loses:

| Preserved                         | Lost                                      |
| --------------------------------- | ----------------------------------------- |
| Key decisions and their reasoning | Exact wording of earlier exchanges        |
| Current state of the task         | Detailed file contents from earlier reads |
| Recent turns (kept verbatim)      | Intermediate debugging steps              |
| Important technical details       | Tool call metadata                        |
| Next steps and pending work       | Exploration paths that were abandoned     |

**This is the fundamental trade-off**: compaction lets sessions run indefinitely, but at the cost of detail from earlier in the conversation. The more compactions occur, the more historical detail is lost.

---

## Strategies for Context Efficiency

### Reduce System Prompt Overhead

The system prompt is a fixed cost on every message. Reducing it frees space for conversation:

- **Disable unused plugins** -- Each plugin adds skills and subagent descriptions (see [token optimization article](claude-code-token-optimization.md))
- **Keep CLAUDE.md concise** -- Every line is re-sent every message
- **Remove unused MCP servers** -- Each adds tool definitions

A 20K system prompt leaves 180K for conversation. A 12K system prompt leaves 188K. That's 8K more tokens -- roughly 2-3 more file reads.

### Use Subagents to Offload Work

Subagents (the Task tool) run in their own isolated context windows. This means their work doesn't consume your main context:

```
Main context (200K)          Subagent context (200K)
┌────────────────────┐       ┌────────────────────┐
│ System prompt      │       │ Subagent prompt     │
│ Conversation       │  ──→  │ 40 turns of         │
│ "Delegate task"    │       │ investigation       │
│ ← Summary result   │  ←──  │ Detailed findings   │
│ Continue working   │       └────────────────────┘
└────────────────────┘
```

A 40-turn investigation that would consume ~20K tokens in your main context becomes a single summary result of ~500 tokens. See [subagents as context management](#subagents-as-context-management) below.

### Be Selective with File Reads

File reads are the largest variable context consumer. Strategies:

- **Read specific line ranges** instead of entire files when you only need a section
- **Use Grep first** to find relevant lines, then read only those areas
- **Avoid re-reading files** you've already seen unless they've changed
- **Use Glob to find files** before reading -- don't read files speculatively

A 1,000-line file consumes roughly 8,000-10,000 tokens. Reading 5 such files uses ~40,000-50,000 tokens -- a quarter of a 200K context window.

### Keep Conversations Focused

Context accumulates faster in unfocused sessions:

- **Start new sessions for unrelated tasks** -- Don't reuse a session for completely different work
- **Commit and start fresh** when switching between distinct features
- **Use `/compact` proactively** before starting a new phase of work
- **Be specific in requests** -- Vague requests lead to more exploratory tool calls that consume context

### Use the 1M Context Window

For sessions that will be particularly long or context-heavy, the 1M token context window provides 5x the standard capacity. This is available in beta for Opus 4.6, Sonnet 4.5, and Sonnet 4 (requires usage tier 4).

**Trade-off:** Tokens above 200K are billed at 2x input and 1.5x output pricing. For very long sessions, the extra cost may be worth avoiding compaction and its associated information loss.

---

## How Context Flows in Claude Code

### A Single Message Round-Trip

When you send a message, here's what happens to the context:

```
You type: "Read the main.go file and add error handling to the HTTP handler"

API call sent:
  System prompt:                    15,000 tokens (cached)
  Previous conversation history:    45,000 tokens (partially cached)
  Your new message:                     30 tokens
                                   ──────────
  Total input:                      60,030 tokens

Claude responds with tool calls:
  [Read main.go]                       → file contents returned: 3,000 tokens
  [Edit main.go]                       → edit confirmation: 200 tokens
  [Read main.go again for verification] → file contents: 3,200 tokens
  Text explanation:                     500 tokens

New context size after this turn:
  Previous:                         60,030 tokens
  + Tool calls and results:          6,900 tokens
  + Response text:                     500 tokens
                                   ──────────
  Total:                            67,430 tokens
```

Each turn adds the user message, all tool calls and their results, and the assistant's response to the conversation history. This accumulates quickly.

### Growth Over a Session

```
Turn  1: 15,000 (system) +  1,000 (conversation) = ~16,000 tokens
Turn 10: 15,000 (system) + 25,000 (conversation) = ~40,000 tokens
Turn 30: 15,000 (system) + 80,000 (conversation) = ~95,000 tokens
Turn 50: 15,000 (system) + 150,000 (conversation) = ~165,000 tokens
Turn 55: Auto-compact triggers → summarizes to ~30,000 conversation tokens
Turn 56: 15,000 (system) + 32,000 (conversation) = ~47,000 tokens
...cycle repeats
```

The sawtooth pattern: context grows linearly, compaction drops it, then it grows again. Each compaction cycle loses some historical detail.

### The Compaction Cycle

```
Context
Usage
  ▲
  │    ╱╲        ╱╲        ╱╲
  │   ╱  ╲      ╱  ╲      ╱  ╲
  │  ╱    ╲    ╱    ╲    ╱    ╲
200K│─────────────────────────────── Limit
  │╱      ╲  ╱      ╲  ╱      ╲
  │        ╲╱        ╲╱        ╲
  │
  └──────────────────────────────→ Time
       Compact  Compact  Compact
```

Each cycle preserves the system prompt (unchanged) and a summary of previous work. Recent turns are kept verbatim. The effective "memory depth" shrinks with each compaction.

---

## Subagents as Context Management

### How Subagents Help

Subagents are the most powerful context management tool available. By running work in a separate context, they:

1. **Prevent context pollution** -- A 40-turn investigation doesn't bloat your main context
2. **Provide fresh context** -- The subagent starts with maximum available space
3. **Return concise summaries** -- Only the final result enters your main context
4. **Are resumable** -- Can continue work across multiple invocations without re-consuming main context

**The math:**

| Approach                              | Main Context Cost          |
| ------------------------------------- | -------------------------- |
| 40-turn investigation in main context | ~20,000 tokens             |
| Same investigation via subagent       | ~500 tokens (summary only) |
| Savings                               | ~19,500 tokens (97.5%)     |

### When to Delegate vs Stay in Main Context

| Scenario                      | Recommendation | Why                                          |
| ----------------------------- | -------------- | -------------------------------------------- |
| Quick file read + small edit  | Main context   | Subagent overhead not worth it               |
| Multi-file exploration        | Subagent       | Exploration consumes lots of context         |
| Complex debugging (10+ turns) | Subagent       | Keeps investigation isolated                 |
| Simple question               | Main context   | Fast, low cost                               |
| Code review                   | Subagent       | Reads many files, produces structured output |
| Architecture analysis         | Subagent       | Deep reasoning, many file reads              |

**Rule of thumb:** If the task will involve reading 3+ files or take more than 10 turns, delegate to a subagent.

---

## Extended Thinking and Context

When extended thinking is enabled, thinking tokens count toward the context window during the current turn but are **automatically stripped from subsequent turns**. This means:

- Thinking tokens don't accumulate in your conversation history
- They only consume context during the turn they're generated
- The API handles stripping automatically -- you don't need to manage this

This design prevents thinking tokens from eating into your context budget over time. A turn with 10,000 thinking tokens will briefly use that space, but it's freed for the next turn.

**Exception:** During tool use, thinking blocks must be preserved until the tool use cycle completes. They're stripped after the cycle ends.

---

## Practical Tips

1. **Watch the context indicator** -- Claude Code shows context usage. Pay attention to it approaching limits.

2. **Use `/compact` before big tasks** -- If you're about to start something that will read many files, compact first to maximize available space.

3. **Delegate exploration** -- When you say "find all the places where X is used", that's an exploration task. Use the Explore subagent to avoid dumping search results into your main context.

4. **Read files strategically** -- Use `offset` and `limit` parameters on the Read tool to read only the sections you need.

5. **Start new sessions for new tasks** -- Don't try to do everything in one session. Context accumulation across unrelated tasks wastes space.

6. **Don't fight compaction** -- Auto-compact is designed to keep sessions running. If you need to preserve specific context, use manual `/compact` with custom instructions.

7. **Leverage the system prompt wisely** -- Instructions in CLAUDE.md persist across compactions. If there's something Claude must always know during a session, put it in CLAUDE.md rather than repeating it in messages (which can be compacted away).

8. **Save state to memory before long sessions** -- If you're approaching what might be a compaction, save important decisions and state to your memory files. Memory files survive compaction because they're re-read from disk, not from conversation history.

---

## References

- [Context Windows (Anthropic Docs)](https://platform.claude.com/docs/en/build-with-claude/context-windows) -- Context window sizes, long context, context awareness
- [Compaction (Anthropic Docs)](https://platform.claude.com/docs/en/build-with-claude/compaction) -- Server-side compaction API
- [Context Editing (Anthropic Docs)](https://platform.claude.com/docs/en/build-with-claude/context-editing) -- Tool result clearing, thinking block clearing
- [System Prompt Article](claude-code-system-prompt.md) -- What occupies the fixed portion of your context
- [Token Optimization Article](claude-code-token-optimization.md) -- Reducing system prompt overhead
- [Prompt Caching Article](claude-code-prompt-caching.md) -- Cost reduction (distinct from context space)
- [Extension Mechanisms Article](claude-code-extension-mechanisms.md) -- Subagents for context isolation
