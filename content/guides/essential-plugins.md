---
title: "Essential Plugins: Extending Claude Code with MCP Servers and Skill Packs"
linkTitle: "Essential Plugins"
weight: 7
---

# Essential Plugins: Extending Claude Code with MCP Servers and Skill Packs

## Executive Summary

Claude Code out of the box has no memory across sessions, no access to library documentation, and no ability to interact with browsers or external services. Plugins fill these gaps. The ecosystem splits into two categories: **MCP servers** that add new tools (memory databases, documentation APIs, browser control) and **skill packs** that add workflow knowledge and specialized subagents (code review, feature development, hook automation).

This guide covers the plugins that provide the highest value relative to their token cost, with practical setup and usage guidance.

| Plugin                | Type                   | What It Adds                             | Token Cost                              | Value       |
| --------------------- | ---------------------- | ---------------------------------------- | --------------------------------------- | ----------- |
| **claude-mem**        | MCP server             | Structured cross-session memory          | ~120-320 tokens (4 tools)               | High        |
| **episodic-memory**   | MCP server + subagent  | Raw conversation search                  | ~200-400 tokens (3 tools + 1 subagent)  | High        |
| **context7**          | MCP server             | Library documentation lookup             | ~60-160 tokens (2 tools)                | Medium      |
| **claude-in-chrome**  | MCP server             | Browser automation                       | ~600+ tokens (15+ tools)                | Situational |
| **hookify**           | Skill pack + subagent  | Hook creation from conversation analysis | ~250-500 tokens (5 skills + 1 subagent) | Medium      |
| **pr-review-toolkit** | Skill pack + subagents | Specialized code review agents           | ~600+ tokens (6 subagents)              | Medium      |

## Table of Contents

- [Essential Plugins: Extending Claude Code with MCP Servers and Skill Packs](#essential-plugins-extending-claude-code-with-mcp-servers-and-skill-packs)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [Two Types of Plugins](#two-types-of-plugins)
    - [MCP Servers](#mcp-servers)
    - [Skill Packs](#skill-packs)
    - [How They Differ](#how-they-differ)
  - [Memory Plugins](#memory-plugins)
    - [claude-mem: Structured Recall](#claude-mem-structured-recall)
    - [episodic-memory: Conversation Search](#episodic-memory-conversation-search)
    - [Why Both](#why-both)
    - [Memory Usage Patterns](#memory-usage-patterns)
  - [Documentation Access](#documentation-access)
    - [context7: Library Documentation](#context7-library-documentation)
    - [When context7 Helps](#when-context7-helps)
  - [Browser Automation](#browser-automation)
    - [claude-in-chrome: Browser Control](#claude-in-chrome-browser-control)
    - [When to Enable Browser Automation](#when-to-enable-browser-automation)
  - [Workflow Automation](#workflow-automation)
    - [hookify: Hook Generation](#hookify-hook-generation)
    - [pr-review-toolkit: Code Review Agents](#pr-review-toolkit-code-review-agents)
  - [Token Cost Management](#token-cost-management)
    - [The Per-Message Tax](#the-per-message-tax)
    - [Measuring Your Plugin Overhead](#measuring-your-plugin-overhead)
    - [Project-Level Plugin Selection](#project-level-plugin-selection)
  - [Installation and Configuration](#installation-and-configuration)
  - [Building Your Plugin Stack](#building-your-plugin-stack)
    - [Minimal Setup](#minimal-setup)
    - [Full Development Setup](#full-development-setup)
    - [Evaluation Criteria](#evaluation-criteria)
  - [Best Practices](#best-practices)
  - [References](#references)

## Two Types of Plugins

### MCP Servers

MCP (Model Context Protocol) servers are external processes that expose tools to Claude. They run as separate processes alongside Claude Code and communicate through stdin/stdout. Each tool the server exposes shows up in Claude's tool list, available for explicit invocation.

```text
Claude Code ←→ MCP Server Process ←→ External Resource
                 │
                 ├── Tool: search(query)
                 ├── Tool: save(data)
                 └── Tool: read(id)
```

MCP servers are stateless from Claude's perspective -- each tool call is independent. The server itself may maintain state (a database, a browser session), but Claude treats each call as a fresh request.

### Skill Packs

Skill packs bundle skills (knowledge injected into Claude's context on demand) and subagents (isolated Claude instances that handle delegated tasks). They're installed as plugins but extend Claude through the existing skill and subagent mechanisms rather than through new tools.

```text
Plugin installs:
  ├── Skills (loaded into main context when triggered)
  │   └── "When user says /review-pr, inject this workflow"
  └── Subagents (isolated instances with specific tools)
      └── "code-reviewer: Reviews code with access to Glob, Grep, Read"
```

### How They Differ

| Aspect                    | MCP Server                              | Skill Pack                                         |
| ------------------------- | --------------------------------------- | -------------------------------------------------- |
| **How it works**          | Adds new tools to Claude's toolbox      | Adds knowledge and subagents                       |
| **Token cost**            | Per-tool definition (30-80 tokens each) | Per-skill + per-subagent description               |
| **When it loads**         | Tool definitions on every message       | Skills on invocation, subagent catalog always      |
| **External dependencies** | Often (databases, APIs, browsers)       | Rarely (just Claude instances)                     |
| **Isolation**             | Separate process                        | Skills share main context; subagents get their own |

For a deeper look at the architecture, see the [Extension Mechanisms]({{< relref "extending/extension-mechanisms" >}}) article.

## Memory Plugins

Claude Code has no built-in cross-session memory. Auto memory (MEMORY.md) persists between sessions but is limited to 200 lines of notes Claude writes for itself. For anything richer, you need plugins.

Two plugins solve this from different angles. Together they cover the full spectrum of recall.

### claude-mem: Structured Recall

**What it does:** Stores distilled observations -- facts, decisions, discoveries, and learnings -- in a searchable database. A startup hook pre-loads a context index at the beginning of every session so Claude walks in already knowing what happened recently.

**Tools provided:**

| Tool               | Purpose                                                 |
| ------------------ | ------------------------------------------------------- |
| `search`           | Search observations by keyword, type, date, project     |
| `timeline`         | Get chronological context around a specific observation |
| `get_observations` | Fetch full details for specific observation IDs         |
| `save_memory`      | Save a manual observation for future recall             |

**The 3-layer retrieval workflow:**

```text
1. search(query)         → Get index with IDs (~50-100 tokens per result)
2. timeline(anchor=ID)   → Get chronological context around interesting results
3. get_observations(IDs) → Fetch full details ONLY for filtered IDs
```

This layered approach is designed for token efficiency. You never fetch full details without filtering first -- the index tells you what's worth reading.

**What gets stored:**

Observations are written during work, either automatically by hooks or manually by Claude. Each has a type:

- Discoveries -- things learned about the codebase or tooling
- Decisions -- architectural choices and their rationale
- Bugfixes -- problems found and how they were resolved
- Changes -- what was modified and why

**Startup hook context injection:**

The startup hook writes a context index into CLAUDE.md files, giving Claude a summary of recent activity without loading full observation details. A typical index entry:

```text
| #17314 | 7:37 PM | Decision | Scoped Profiles Architecture for claudeup | ~536 tokens |
```

Claude sees the title and token cost, then decides whether to fetch the full observation based on relevance to the current task.

### episodic-memory: Conversation Search

**What it does:** Stores raw conversation transcripts from past sessions and provides semantic search across them. Where claude-mem stores the conclusion, episodic-memory stores the deliberation.

**Tools provided:**

| Tool     | Purpose                                                    |
| -------- | ---------------------------------------------------------- |
| `search` | Semantic or text search across all past conversations      |
| `read`   | Read full conversation segments with line-level pagination |

Plus a `search-conversations` subagent that can be delegated to for deeper investigation.

**Search supports two modes:**

```text
# Semantic search (finds conceptually similar content)
search(query: "how did we handle authentication")

# Precise AND matching (all terms must appear)
search(query: ["authentication", "JWT", "middleware"])
```

**Conversations are captured automatically** -- no manual curation needed. Every session's transcript is indexed for future search.

### Why Both

These plugins have different strengths and failure modes that complement each other.

**Different granularities.** claude-mem gives you the conclusion: "we chose scoped profiles with scope inference." episodic-memory gives you the deliberation that led there, including dead ends and trade-offs discussed.

**Token economics.** claude-mem's indexed approach can summarize hundreds of thousands of tokens of past work into a few thousand tokens. episodic-memory is richer but more expensive -- you go there when you need the full story.

**Different failure modes.** A distilled observation might lose important nuance. A raw transcript might bury the key insight in 500 lines of debugging output. Cross-referencing both compensates for each one's blind spots.

### Memory Usage Patterns

**The natural workflow:**

1. Claude starts a session, claude-mem's startup hook shows the context index
2. Claude needs to understand _why_ a past decision was made
3. Searches episodic-memory for the conversation where it happened
4. Reads back the specific dialogue where trade-offs were debated
5. Has both the decision and the rationale, without re-asking the user

**Searching memories before asking the user:**

```text
Before asking: "What testing framework do we use?"

1. Check claude-mem: search(query: "testing framework")
2. Check episodic-memory: search(query: ["testing", "framework", "choice"])
3. Only ask if both come up empty
```

**Recording important decisions:**

When a significant technical decision is made during a session, claude-mem captures it as a structured observation. If the conversation is also captured by episodic-memory, both the conclusion and the reasoning are preserved.

## Documentation Access

### context7: Library Documentation

**What it does:** Retrieves up-to-date documentation and code examples for any programming library, pulling from Context7's indexed documentation database.

**Tools provided:**

| Tool                 | Purpose                                    |
| -------------------- | ------------------------------------------ |
| `resolve-library-id` | Find a library's Context7 ID from its name |
| `query-docs`         | Query documentation for a specific library |

**Two-step usage pattern:**

```text
1. resolve-library-id(libraryName: "next.js", query: "server components")
   → Returns: /vercel/next.js

2. query-docs(libraryId: "/vercel/next.js", query: "how to use server components")
   → Returns: Relevant documentation and code examples
```

### When context7 Helps

- **Framework APIs** -- When Claude's training data might be outdated for fast-moving frameworks (Next.js, SvelteKit, etc.)
- **Unfamiliar libraries** -- When working with libraries Claude hasn't seen much of in training
- **Version-specific behavior** -- When you need documentation for a specific version

Where it's less useful:

- **Stable, well-known APIs** -- Claude already knows standard library APIs well
- **Simple tasks** -- Looking up basic syntax rarely needs a documentation query
- **Private libraries** -- context7 only indexes public documentation

## Browser Automation

### claude-in-chrome: Browser Control

**What it does:** Gives Claude full control over a Chrome browser through a Chrome extension. Claude can navigate, click, type, read page content, take screenshots, fill forms, execute JavaScript, and record GIFs of multi-step interactions.

**Tools provided (15+):**

| Category        | Tools                                                  |
| --------------- | ------------------------------------------------------ |
| **Navigation**  | navigate, tabs_context, tabs_create                    |
| **Reading**     | read_page, find, get_page_text                         |
| **Interaction** | computer (click, type, scroll, screenshot), form_input |
| **JavaScript**  | javascript_tool                                        |
| **Recording**   | gif_creator                                            |
| **Debugging**   | read_console_messages, read_network_requests           |

### When to Enable Browser Automation

This plugin carries the highest token cost of any common plugin (~600+ tokens just for tool definitions). Enable it when you actually need browser interaction:

- **Web scraping and data extraction** from pages that require JavaScript rendering
- **Testing web applications** by interacting with them like a user
- **Automating web workflows** (filling forms, navigating multi-step processes)
- **Debugging frontend issues** by inspecting the DOM and console

Disable it for pure backend work, CLI tool development, or projects where browser interaction adds nothing.

## Workflow Automation

### hookify: Hook Generation

**What it does:** Analyzes conversations to identify patterns that should be prevented, then generates hook configurations to enforce them automatically. Instead of manually writing hooks, you describe the problem and hookify creates the solution.

**Useful when:**

- Claude keeps making the same mistake and you want to prevent it automatically
- You want to enforce a workflow pattern (run tests before commit, format before save)
- You need to add guardrails without cluttering CLAUDE.md with rules

For the hook system itself, see the [Hooks Cookbook]({{< relref "extending/hooks-cookbook" >}}).

### pr-review-toolkit: Code Review Agents

**What it does:** Provides specialized subagents for different aspects of code review, each focused on a specific concern.

| Subagent                  | Focus                                             |
| ------------------------- | ------------------------------------------------- |
| **code-reviewer**         | Style, bugs, adherence to project conventions     |
| **silent-failure-hunter** | Error handling gaps, swallowed exceptions         |
| **code-simplifier**       | Unnecessary complexity, opportunities to simplify |
| **comment-analyzer**      | Comment accuracy and maintainability              |
| **pr-test-analyzer**      | Test coverage completeness                        |
| **type-design-analyzer**  | Type design quality, encapsulation, invariants    |

Each subagent runs in its own context window, so it doesn't bloat the main conversation. The trade-off is the catalog description cost -- six subagent descriptions in the system prompt on every message.

## Token Cost Management

### The Per-Message Tax

Every plugin adds to the system prompt, and the system prompt is sent on every API round-trip. This is covered in depth in the [Token Optimization]({{< relref "/internals/token-optimization" >}}) article, but the key point for plugins specifically:

```text
Plugin cost per message:
  MCP tools:     ~30-80 tokens per tool definition
  Subagents:     ~50-150 tokens per subagent description
  Skills:        ~25-100 tokens per skill catalog entry

Example with 4 plugins:
  claude-mem:         4 tools                    ≈ 120-320 tokens
  episodic-memory:    3 tools + 1 subagent       ≈ 200-400 tokens
  context7:           2 tools                    ≈ 60-160 tokens
  claude-in-chrome:   15+ tools                  ≈ 600+ tokens
  ──────────────────────────────────────────────────────────
  Total:                                         ≈ 980-1,480 tokens per message
```

With prompt caching, the cost is discounted 90% after the first message. But the context window space is consumed regardless -- those tokens are unavailable for conversation history and actual work.

### Measuring Your Plugin Overhead

Check the system prompt header in the first message of a session. Claude Code reports the prompt size. Compare sessions with and without plugins enabled to see the delta.

Alternatively, count tools and subagents:

```bash
# In Claude Code, ask:
"How many MCP tools and subagents are in your system prompt right now?"
```

### Project-Level Plugin Selection

Not every project needs every plugin. A CLI tool project doesn't need browser automation. A documentation project doesn't need code review agents.

Use `.claude/settings.json` at the project level to configure which MCP servers are active:

```json
{
  "mcpServers": {
    "claude-mem": { "command": "..." },
    "context7": { "command": "..." }
  }
}
```

Plugins not listed in the project settings won't load, even if they're configured globally.

## Installation and Configuration

MCP servers are configured in `~/.claude/settings.json` (global) or `.claude/settings.json` (project). Each entry specifies the command to start the server:

```json
{
  "mcpServers": {
    "plugin-name": {
      "command": "npx",
      "args": ["-y", "@package/server"],
      "env": {}
    }
  }
}
```

Skill packs are typically installed through `claudeup` for local management:

```bash
# List available extensions
claudeup local list

# Enable a skill pack
claudeup local enable skills my-skill-pack

# Disable when not needed
claudeup local disable skills my-skill-pack
```

Refer to each plugin's documentation for specific installation instructions. The exact command and arguments vary by plugin.

## Building Your Plugin Stack

### Minimal Setup

For most development work, two plugins provide the highest return:

1. **claude-mem** -- Cross-session memory with token-efficient retrieval
2. **episodic-memory** -- Conversation search for when you need the full story

Together they typically add ~320-720 tokens per message and solve Claude Code's biggest limitation (no memory across sessions).

### Full Development Setup

For active feature development with code review and documentation needs:

1. **claude-mem** + **episodic-memory** -- Memory
2. **context7** -- Library documentation access
3. **hookify** -- Workflow enforcement
4. **pr-review-toolkit** -- Code review before PRs

Total overhead: ~1,500-2,500 tokens per message. Significant but manageable within a 200K context window.

Add **claude-in-chrome** only for projects that involve web interaction.

### Evaluation Criteria

When deciding whether to add a plugin:

```text
Is this plugin worth its token cost?
│
├── Do I use it in most sessions?
│   ├── Yes → Keep enabled globally
│   └── No → Enable per-project or disable
│
├── Does it save more context than it costs?
│   ├── Yes (memory plugins prevent re-asking questions) → Keep
│   └── No (rarely invoked, always loaded) → Disable
│
└── Does the quality improvement justify the overhead?
    ├── Yes (catches bugs I'd miss, finds docs I need) → Keep
    └── No (nice to have but rarely changes outcomes) → Disable
```

## Best Practices

1. **Start with memory plugins.** claude-mem and episodic-memory solve the most impactful limitation (no cross-session recall) at reasonable token cost. Add other plugins as specific needs arise.

2. **Disable plugins you don't use per-project.** Browser automation tools cost 600+ tokens per message. Don't pay that tax on a backend-only project.

3. **Search before asking.** With memory plugins installed, Claude should check past sessions for answers before asking you to repeat information. Include this expectation in your CLAUDE.md.

4. **Let claude-mem's startup hook do its job.** The context index it injects gives Claude immediate awareness of recent work. Don't disable it to save a few hundred tokens -- the time saved from not re-explaining context is worth far more.

5. **Use the 3-layer workflow for claude-mem.** Search the index first, then get timeline context, then fetch full details only for what you need. Skipping straight to full details wastes tokens.

6. **Evaluate plugins periodically.** Your needs change as projects evolve. A plugin that was essential during initial development might add nothing during maintenance. Review and adjust.

7. **Check the token optimization article.** The [Token Optimization]({{< relref "/internals/token-optimization" >}}) guide covers how to audit your full setup and identify redundancy across plugins, skills, and subagents.

## References

- [Extension Mechanisms]({{< relref "extending/extension-mechanisms" >}}) -- Architecture deep dive on subagents, skills, and MCP servers
- [Custom Extensions]({{< relref "extending/custom-extensions" >}}) -- Building your own plugins
- [Hooks Cookbook]({{< relref "extending/hooks-cookbook" >}}) -- Hook recipes and automation patterns
- [Token Optimization]({{< relref "/internals/token-optimization" >}}) -- Auditing and managing token overhead
- [Memory Organization]({{< relref "memory-organization" >}}) -- Structuring CLAUDE.md and rules
- [Model Context Protocol (MCP)](https://modelcontextprotocol.io/) -- The protocol that MCP servers implement
