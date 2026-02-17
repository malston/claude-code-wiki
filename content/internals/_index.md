---
title: "Internals"
weight: 1
bookCollapseSection: false
---

# Internals

How Claude Code works under the hood -- the system prompt, context window, caching, token economics, and reasoning.

- **[The System Prompt]({{< relref "internals/system-prompt" >}})** -- What Claude reads before you say anything. Anatomy of the system prompt, how it's assembled from multiple sources, and why it's the largest factor in per-message token overhead.
- **[Context Management]({{< relref "internals/context-management" >}})** -- Working within the token budget. How the context window fills with system prompt, conversation history, tool results, and file contents, and strategies for managing it as sessions grow.
- **[Prompt Caching]({{< relref "internals/prompt-caching" >}})** -- Why your system prompt doesn't cost what you think. How the API reuses previously processed prompt prefixes to reduce both cost and latency.
- **[Token Optimization]({{< relref "internals/token-optimization" >}})** -- Auditing and optimizing the baseline token cost from skills, plugins, and system configuration that every session carries.
- **[Extended Thinking]({{< relref "internals/extended-thinking" >}})** -- How Claude reasons through complex problems. Adaptive thinking, effort levels, thinking token billing, and cost management.
- **[Tool Execution Context]({{< relref "internals/tool-execution-context" >}})** -- Why skill instructions and CLAUDE.md rules may not be in active scope when Claude processes bash tool results, and how to structure workflows that depend on behavioral constraints.
