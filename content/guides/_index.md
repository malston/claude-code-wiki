---
title: "Guides"
weight: 2
bookCollapseSection: false
---

# Guides

Practical techniques for getting the most out of Claude Code -- prompting, workflows, debugging, testing, model selection, and configuration.

- **[Effective Prompting]({{< relref "guides/effective-prompting" >}})** -- Getting better results by structuring requests with specificity, task decomposition, and well-organized CLAUDE.md files.
- **[Workflow Patterns]({{< relref "guides/workflow-patterns" >}})** -- Common development workflows including verification-driven development, iterative feedback loops, session management, and subagent delegation.
- **[Debugging Techniques]({{< relref "guides/debugging-techniques" >}})** -- Systematic troubleshooting with Claude Code. Root cause analysis, error sharing, reproduction strategies, and common anti-patterns.
- **[Testing Strategies]({{< relref "guides/testing-strategies" >}})** -- TDD patterns and test automation. Using tests as a concrete feedback loop for Claude to write, run, fail, and fix.
- **[Model Selection & Cost Management]({{< relref "guides/model-selection" >}})** -- Choosing the right model and controlling spend. Opus, Sonnet, and Haiku tiers, pricing, budget caps, and cost control mechanisms.
- **[Memory Organization]({{< relref "guides/memory-organization" >}})** -- Structuring CLAUDE.md and rules for scale. Putting the right information at the right scope to maximize context window efficiency.
- **[How Coding Assistants Manage Context]({{< relref "guides/coding-assistants-context" >}})** -- What Claude Code and Copilot do to keep the context window focused -- selective file injection, subagent isolation, compaction, and where both tools fall short.
- **[Essential Plugins]({{< relref "guides/essential-plugins" >}})** -- MCP servers and skill packs that extend Claude Code. Memory plugins, documentation access, browser automation, and workflow tools -- what they do, what they cost, and when to use them.
- **[Permissions & Enterprise]({{< relref "guides/permissions-enterprise" >}})** -- Securing and scaling Claude Code. Permission cascades, sandbox enforcement, managed settings, and API provider configuration.
- **[Spec-Driven Development]({{< relref "guides/spec-driven-development" >}})** -- Structured planning for AI-assisted projects. Replacing vibecoding with a disciplined cycle of specs, atomic tasks, and verification.
- **[Large Codebase Strategies]({{< relref "guides/large-codebase-strategies" >}})** -- Strategies for getting reliable results from Claude Code when your codebase is too large to fit in a single context window. Covers tight scoping, `/batch` for parallel migrations, git worktrees, CLAUDE.md investment, skills, and proactive compaction.
- **[Background Agents]({{< relref "guides/background-agents" >}})** -- Running many Claude Code sessions at once with `claude agents` and `--bg`. Dispatching, monitoring, and attaching to background sessions, worktree isolation, and the supervisor that hosts them.
