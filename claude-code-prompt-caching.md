# Prompt Caching: Why Your System Prompt Doesn't Cost What You Think

## Executive Summary

Prompt caching allows the API to reuse previously processed prompt prefixes, reducing both cost and latency. Since Claude Code re-sends the system prompt on every API call, caching is what makes large system prompts economically viable. Without caching, a 200-message session with a 15,000-token system prompt would cost ~$15 on Opus 4.6. With caching, it costs ~$1.60 -- an 89% reduction.

| Metric                                    | Without Caching | With Caching     | Savings     |
| ----------------------------------------- | --------------- | ---------------- | ----------- |
| System prompt cost (200 msgs, Opus 4.6)   | ~$15.00         | ~$1.60           | 89%         |
| System prompt cost (200 msgs, Sonnet 4.5) | ~$9.00          | ~$0.96           | 89%         |
| Latency (long prompts)                    | Full processing | Up to 85% faster | Significant |

**Pricing multipliers (all models):**

| Operation                | Multiplier vs Base Input | Opus 4.6 ($5 base) | Sonnet 4.5 ($3 base) |
| ------------------------ | ------------------------ | ------------------ | -------------------- |
| Cache write (5-min TTL)  | 1.25x                    | $6.25/MTok         | $3.75/MTok           |
| Cache write (1-hour TTL) | 2x                       | $10/MTok           | $6/MTok              |
| Cache read               | 0.1x                     | $0.50/MTok         | $0.30/MTok           |
| Uncached input           | 1x                       | $5/MTok            | $3/MTok              |

---

## Table of Contents

- [How Prompt Caching Works](#how-prompt-caching-works)
  - [The Basic Mechanism](#the-basic-mechanism)
  - [Cache Lifetime (TTL)](#cache-lifetime-ttl)
  - [What Gets Cached](#what-gets-cached)
- [Prompt Caching in Claude Code](#prompt-caching-in-claude-code)
  - [Why It Matters for Claude Code](#why-it-matters-for-claude-code)
  - [The Cache Hierarchy](#the-cache-hierarchy)
  - [What Stays Cached Between Messages](#what-stays-cached-between-messages)
  - [What Breaks the Cache](#what-breaks-the-cache)
- [The Economics](#the-economics)
  - [Model Pricing](#model-pricing)
  - [Worked Example: A Typical Claude Code Session](#worked-example-a-typical-claude-code-session)
  - [The Real Cost of System Prompt Bloat](#the-real-cost-of-system-prompt-bloat)
- [Cache Mechanics](#cache-mechanics)
  - [Prefix Matching](#prefix-matching)
  - [Minimum Token Requirements](#minimum-token-requirements)
  - [Cache Breakpoints](#cache-breakpoints)
  - [Cache Invalidation Rules](#cache-invalidation-rules)
- [What This Means for Optimization](#what-this-means-for-optimization)
  - [Cost Optimization vs Context Optimization](#cost-optimization-vs-context-optimization)
  - [When to Worry About Caching](#when-to-worry-about-caching)
  - [When Not to Worry](#when-not-to-worry)
- [References](#references)

---

## How Prompt Caching Works

### The Basic Mechanism

Every API call sends the full prompt to the model. Without caching, the model processes every token from scratch each time. With caching, the model can reuse previously processed prefixes:

```
Message 1 (no cache exists yet):
┌─────────────────────────────────────────┐
│ System prompt (15,000 tokens)           │ ← Processed and written to cache
│ User message (50 tokens)                │ ← Processed normally
└─────────────────────────────────────────┘
  Cost: 15,000 × $6.25/MTok (cache write) + 50 × $5/MTok (uncached)

Message 2 (cache hit):
┌─────────────────────────────────────────┐
│ System prompt (15,000 tokens)           │ ← Read from cache (90% cheaper)
│ Previous conversation (500 tokens)      │ ← Processed normally
│ User message (50 tokens)                │ ← Processed normally
└─────────────────────────────────────────┘
  Cost: 15,000 × $0.50/MTok (cache read) + 550 × $5/MTok (uncached)
```

The cache operates on **prefix matching** -- it caches everything from the beginning of the prompt up to a designated breakpoint. The prefix must be identical between requests for a cache hit.

### Cache Lifetime (TTL)

- **Default: 5 minutes** -- Refreshed every time the cached content is used (so active sessions keep the cache alive indefinitely)
- **Optional: 1 hour** -- Costs more to write (2x base instead of 1.25x) but survives longer idle periods
- No manual cache clearing -- entries expire automatically after the TTL without use

For Claude Code sessions, the 5-minute default is fine. As long as you're actively working (sending messages within 5 minutes of each other), the cache stays warm.

### What Gets Cached

The cache covers the full prompt prefix in order: **tools → system → messages**. This order forms a hierarchy where each level builds on the previous.

Cacheable content includes:

- Tool definitions (including MCP tools)
- System messages (instructions, CLAUDE.md content, skill catalogs)
- Conversation messages (user turns, assistant turns, tool results)
- Images and documents in messages
- Tool use and tool result blocks

**Not cacheable:** Thinking blocks (from extended thinking) cannot be explicitly cached, though they get cached implicitly when passed back in tool use flows.

---

## Prompt Caching in Claude Code

### Why It Matters for Claude Code

Claude Code is uniquely positioned to benefit from prompt caching because its system prompt is:

1. **Large** -- Typically 12,000-20,000 tokens (see the [system prompt article](claude-code-system-prompt.md))
2. **Stable** -- The same content is sent on every message within a session
3. **Repeated frequently** -- Sessions routinely involve 50-200+ API calls

Without caching, a Claude Code session would be prohibitively expensive. The system prompt alone would cost $15-20 per 200-message session on Opus 4.6. Caching brings that down to ~$1.50-2.00.

### The Cache Hierarchy

Claude Code's prompt follows the standard cache hierarchy:

```
1. Tool definitions (Read, Edit, Bash, Glob, Grep, Task, etc.)
   + MCP tool definitions (context7, episodic-memory, etc.)
       │
2. System messages
   ├── Core instructions (safety rules, behavior guidelines)
   ├── CLAUDE.md files (all scopes)
   ├── Skill catalog (names + descriptions)
   ├── Subagent catalog (in Task tool definition)
   ├── MCP server instructions
   └── Environment context (git status, working directory)
       │
3. Conversation messages
   ├── User messages
   ├── Assistant responses
   ├── Tool calls and results
   └── System reminders (hook outputs, plugin status)
```

Levels 1 and 2 are nearly identical across messages -- this is what gets cached. Level 3 grows with each message; the new portions are uncached.

### What Stays Cached Between Messages

In a typical Claude Code session:

| Content                     | Cached?                   | Why                                              |
| --------------------------- | ------------------------- | ------------------------------------------------ |
| Tool definitions            | Yes (after first message) | Identical every message                          |
| Core instructions           | Yes                       | Identical every message                          |
| CLAUDE.md files             | Yes                       | Identical every message                          |
| Skill catalog               | Yes                       | Identical every message                          |
| Subagent catalog            | Yes                       | Identical every message                          |
| Previous conversation turns | Mostly                    | Prefix is identical; only new turns are uncached |
| Latest user message         | No                        | New content each time                            |
| System reminders            | Partially                 | Some are identical, some vary                    |

The result: after the first message, roughly 80-95% of input tokens on subsequent messages are cache reads at 10% of the base price.

### What Breaks the Cache

Changes to the prompt prefix invalidate the cache from that point forward:

| Change                                  | Impact                                                             |
| --------------------------------------- | ------------------------------------------------------------------ |
| Tool definition changes                 | Invalidates everything (tools are first in hierarchy)              |
| System prompt changes                   | Invalidates system + messages cache                                |
| Enabling/disabling a plugin mid-session | Full cache invalidation (changes tool definitions + system prompt) |
| Adding/removing an MCP server           | Full cache invalidation                                            |
| Context compaction (long sessions)      | Conversation history changes, partial invalidation                 |

**In practice, cache invalidation rarely happens within a Claude Code session.** The system prompt doesn't change mid-session. The main cause of partial invalidation is context compaction in very long sessions, where older messages get summarized.

---

## The Economics

### Model Pricing

Current pricing for models commonly used with Claude Code:

| Model             | Base Input | Cache Write (5min) | Cache Read | Output   |
| ----------------- | ---------- | ------------------ | ---------- | -------- |
| Claude Opus 4.6   | $5/MTok    | $6.25/MTok         | $0.50/MTok | $25/MTok |
| Claude Opus 4.5   | $5/MTok    | $6.25/MTok         | $0.50/MTok | $25/MTok |
| Claude Sonnet 4.5 | $3/MTok    | $3.75/MTok         | $0.30/MTok | $15/MTok |
| Claude Sonnet 4   | $3/MTok    | $3.75/MTok         | $0.30/MTok | $15/MTok |
| Claude Haiku 4.5  | $1/MTok    | $1.25/MTok         | $0.10/MTok | $5/MTok  |

The key ratio: **cache reads are 10x cheaper than base input**. This makes caching extremely effective for repeated prefixes.

### Worked Example: A Typical Claude Code Session

Assumptions:

- 15,000-token system prompt
- 200-message session
- Opus 4.6 pricing

**Without caching:**

```
200 messages × 15,000 tokens × $5/MTok = $15.00
(just for the system prompt -- conversation tokens add more)
```

**With caching:**

```
Message 1 (cache write):
  15,000 tokens × $6.25/MTok = $0.09

Messages 2-200 (cache reads):
  199 × 15,000 tokens × $0.50/MTok = $1.49

Total system prompt cost: $0.09 + $1.49 = $1.58
Savings: $15.00 - $1.58 = $13.42 (89% reduction)
```

The conversation history also benefits from caching. As the conversation grows, previously sent turns become part of the cached prefix. Only the newest message is uncached.

### The Real Cost of System Prompt Bloat

Even with caching, system prompt size matters:

| System Prompt Size | Without Caching (200 msgs) | With Caching (200 msgs) | Cache Reads Cost |
| ------------------ | -------------------------- | ----------------------- | ---------------- |
| 10,000 tokens      | $10.00                     | $1.06                   | $1.00            |
| 15,000 tokens      | $15.00                     | $1.58                   | $1.49            |
| 20,000 tokens      | $20.00                     | $2.11                   | $1.99            |
| 30,000 tokens      | $30.00                     | $3.16                   | $2.99            |

(Opus 4.6 pricing)

The cost difference between a 10K and 30K system prompt is ~$2 per session with caching -- noticeable over many sessions but not catastrophic. The more significant impact of a bloated system prompt is **context window space**: those 30,000 tokens are unavailable for conversation content regardless of caching.

---

## Cache Mechanics

### Prefix Matching

Cache hits require **100% identical** content from the beginning of the prompt up to the cache breakpoint. Even a single character difference causes a cache miss for everything after the point of difference.

This is why the system prompt is ideal for caching -- it's assembled from the same sources every message and doesn't change mid-session.

### Minimum Token Requirements

Not all prompts are eligible for caching. Each model has a minimum cacheable prefix length:

| Model                                         | Minimum Tokens |
| --------------------------------------------- | -------------- |
| Claude Opus 4.6, Opus 4.5                     | 4,096          |
| Claude Sonnet 4.5, Sonnet 4, Opus 4.1, Opus 4 | 1,024          |
| Claude Haiku 4.5                              | 4,096          |

Claude Code system prompts are well above these minimums (typically 12,000-20,000 tokens), so caching always applies.

### Cache Breakpoints

The API supports up to 4 explicit cache breakpoints using `cache_control` parameters. Claude Code manages these internally -- you don't set them yourself.

The system automatically checks for cache hits by looking backwards from each breakpoint (up to 20 blocks), finding the longest matching prefix. In Claude Code, this means:

1. Tool definitions get cached as a block
2. System prompt gets cached as a block
3. Conversation history gets incrementally cached as it grows

### Cache Invalidation Rules

The cache follows the hierarchy: **tools → system → messages**. Changes at each level invalidate that level and everything after it.

```
tools change    → tools, system, messages all invalidated
system changes  → system and messages invalidated (tools still cached)
messages change → only messages invalidated (tools and system still cached)
```

Specific invalidation triggers:

| Change                    | Tools Cache | System Cache | Messages Cache |
| ------------------------- | ----------- | ------------ | -------------- |
| Tool definitions modified | Invalidated | Invalidated  | Invalidated    |
| Web search toggled        | Valid       | Invalidated  | Invalidated    |
| Speed mode toggled        | Valid       | Invalidated  | Invalidated    |
| Tool choice changed       | Valid       | Valid        | Invalidated    |
| Images added/removed      | Valid       | Valid        | Invalidated    |
| Thinking params changed   | Valid       | Valid        | Invalidated    |

---

## What This Means for Optimization

### Cost Optimization vs Context Optimization

Prompt caching creates an important distinction between two types of optimization:

**Cost optimization** -- Reducing the dollar amount spent on input tokens. Caching handles this automatically and effectively. The 90% discount on cached reads means that even a large system prompt is cheap per-message.

**Context optimization** -- Reducing the context window space consumed by the system prompt. Caching does **not** help here. A 20,000-token system prompt still occupies 20,000 tokens of your context window on every message, whether those tokens are cached or not.

```
Context window budget (e.g., 200K tokens):
┌──────────────────────────────────────────────┐
│ System prompt: 20,000 tokens                 │ ← Cheap (cached) but takes space
│ Conversation history: grows over time        │ ← New content, full price
│ Available for new content: what's left       │ ← This is what you're optimizing
└──────────────────────────────────────────────┘
```

This is why the [token optimization article](claude-code-token-optimization.md) still matters even with caching. Disabling unused plugins saves context window space, not just money.

### When to Worry About Caching

You generally don't need to think about prompt caching in Claude Code -- it's handled automatically. But be aware of these scenarios:

- **Long idle periods** -- If you step away for more than 5 minutes between messages, the cache expires. The next message pays full price for a cache write. This is a one-time cost and the cache rebuilds immediately.
- **Very long sessions** -- Context compaction (summarizing old messages) changes the conversation history, causing partial cache invalidation. This is normal and expected.
- **Plugin/MCP changes mid-session** -- If you enable/disable plugins or MCP servers during a session, it invalidates the entire cache. Restart Claude Code to get clean caching.

### When Not to Worry

- **System prompt size (for cost)** -- With caching, the cost difference between a 10K and 30K system prompt is ~$2 per 200-message session. Not worth agonizing over.
- **Conversation length** -- Previous turns get cached incrementally. Long conversations are efficiently handled.
- **Cache management** -- Claude Code handles breakpoint placement and cache strategy automatically. There's nothing to configure.

---

## References

- [Prompt Caching (Anthropic Docs)](https://platform.claude.com/docs/en/build-with-claude/prompt-caching) -- Full API documentation
- [Pricing](https://platform.claude.com/docs/en/about-claude/pricing) -- Current model pricing with caching multipliers
- [System Prompt Article](claude-code-system-prompt.md) -- What gets cached in Claude Code
- [Token Optimization Article](claude-code-token-optimization.md) -- Context window optimization (complementary to caching)
