# The System Prompt: What Claude Reads Before You Say Anything

## Executive Summary

The system prompt is the hidden instruction text sent to the model on every API call, before any conversation messages. It defines Claude's behavior, available tools, safety rules, and injected knowledge. In Claude Code, it's assembled from multiple sources and re-sent with every message -- making it the single largest factor in per-message token overhead.

| Component                 | Source                           | Typical Size              |
| ------------------------- | -------------------------------- | ------------------------- |
| Core instructions         | Claude Code built-in             | ~3,000-5,000 tokens       |
| Tool definitions          | Built-in + MCP servers           | ~3,000-5,000 tokens       |
| CLAUDE.md files           | User, project, enterprise scopes | ~2,000-4,000 tokens       |
| Skill catalog             | Enabled skills + plugins         | ~2,000-5,000 tokens       |
| Subagent catalog          | Plugin subagent descriptions     | ~1,000-2,000 tokens       |
| Environment + git context | Auto-detected                    | ~200-500 tokens           |
| **Typical total**         |                                  | **~12,000-20,000 tokens** |

---

## Table of Contents

- [What the System Prompt Is](#what-the-system-prompt-is)
- [Anatomy of a Claude Code API Call](#anatomy-of-a-claude-code-api-call)
- [System Prompt Components](#system-prompt-components)
  - [Core Instructions](#core-instructions)
  - [Tool Definitions](#tool-definitions)
  - [CLAUDE.md Files](#claudemd-files)
  - [Skill Catalog](#skill-catalog)
  - [Subagent Catalog](#subagent-catalog)
  - [MCP Server Instructions](#mcp-server-instructions)
  - [Environment and Git Context](#environment-and-git-context)
  - [Plugin-Injected Content](#plugin-injected-content)
- [How It Gets Assembled](#how-it-gets-assembled)
- [Why This Matters](#why-this-matters)
  - [Token Cost](#token-cost)
  - [Behavior Shaping](#behavior-shaping)
  - [Prompt Caching](#prompt-caching)
- [What You Can Control](#what-you-can-control)
- [References](#references)

---

## What the System Prompt Is

Every API call to Claude has three parts: system prompt, conversation history, and the current message. The system prompt is the first part -- instructions the model reads before seeing any conversation.

The user never sees the system prompt directly in the chat interface. But it determines:

- What tools Claude can use and how
- What rules and guidelines Claude follows
- What skills and subagents are available
- How Claude should behave, communicate, and make decisions

In Claude Code, the system prompt is not a single static document. It's dynamically assembled from multiple sources at startup and updated with minor additions (like system reminders) throughout the session.

---

## Anatomy of a Claude Code API Call

Every message you send triggers an API call structured like this:

```
┌─────────────────────────────────────────────┐
│ System Prompt                               │  ← Re-sent every call
│ ├── Core instructions                       │
│ ├── Tool definitions                        │
│ ├── CLAUDE.md files                         │
│ ├── Skill catalog                           │
│ ├── Subagent catalog (in Task tool def)     │
│ ├── MCP tool definitions                    │
│ ├── Environment info                        │
│ └── Plugin-injected instructions            │
├─────────────────────────────────────────────┤
│ Conversation History                        │  ← Grows with each turn
│ ├── Message 1 (user)                        │
│ ├── Message 2 (assistant + tool calls)      │
│ ├── Message 3 (tool results)                │
│ ├── ...                                     │
│ └── Message N (user) ← your latest message  │
├─────────────────────────────────────────────┤
│ System Reminders                            │  ← Injected by hooks/plugins
│ ├── Hook outputs                            │
│ ├── Skill availability reminders            │
│ └── Plugin status messages                  │
└─────────────────────────────────────────────┘
```

The system prompt and conversation history are both input tokens -- you pay for all of them on every call. The system prompt is roughly the same size every time; the conversation history grows.

---

## System Prompt Components

### Core Instructions

The foundation of Claude's behavior in Claude Code. These are built-in and not user-modifiable.

**Includes:**

- How to use each built-in tool (Read, Edit, Write, Bash, Grep, Glob, etc.)
- Safety rules and security boundaries
- Git commit and PR creation workflows
- Tone and style guidelines
- General coding principles (avoid over-engineering, don't introduce vulnerabilities)
- When to ask for confirmation vs. act autonomously

**Typical size:** ~3,000-5,000 tokens

### Tool Definitions

Schema definitions for every available tool. Each tool has a name, description, and JSON schema for its parameters.

**Built-in tools** (~15):

- Read, Edit, Write, Bash, Glob, Grep
- Task, WebFetch, WebSearch
- NotebookEdit, EnterPlanMode, ExitPlanMode
- AskUserQuestion, Skill
- TodoWrite (TaskCreate/TaskUpdate/TaskList)

**MCP tools** (varies by configuration):

Each connected MCP server adds its tool definitions. A server like `claude-in-chrome` adds 15+ tools; `context7` adds 2; `episodic-memory` adds 2-3. Each tool definition costs ~30-80 tokens.

**Typical size:** ~3,000-5,000 tokens (built-in + MCP combined)

### CLAUDE.md Files

All discovered CLAUDE.md files from every scope are loaded into the system prompt:

```
Precedence (highest to lowest):
1. Enterprise policy    (organization-wide)
2. Project CLAUDE.md    (repo root, version controlled)
3. User CLAUDE.md       (~/.claude/CLAUDE.md)
4. Project local        (.claude/CLAUDE.local.md)
```

These contain your coding standards, preferences, team conventions, and workflow rules. Everything in these files is literally part of the instructions Claude reads before responding.

**Typical size:** ~2,000-4,000 tokens (varies widely by configuration)

**Why it matters:** A 200-line CLAUDE.md might seem small, but at ~1,500-2,000 tokens, it's re-sent on every message. This is intentional -- these are your persistent instructions. But it means bloated CLAUDE.md files have a real cost.

### Skill Catalog

Every enabled skill (local + plugin) contributes a catalog entry with its name, description, and trigger conditions. This is how Claude knows what skills exist and when to activate them.

Example catalog entry:

```
- golang: Go patterns for backend development, testing, and
  clean architecture. Use when writing Go code.
```

That single entry is ~25 tokens. With 60+ skills enabled, the catalog can reach 4,000-5,000 tokens.

**Important:** This is just the catalog (names and descriptions). The full skill content only loads when the Skill tool is invoked. See the [token optimization article](claude-code-token-optimization.md) for details on the two-phase cost model.

**Typical size:** ~2,000-5,000 tokens (depends on number of enabled skills)

### Subagent Catalog

Plugin subagents are described in the Task tool's definition block. Each subagent gets a description explaining what it does, when to use it, and example invocations.

Example (abbreviated):

```
- code-documentation:docs-architect: Creates comprehensive technical
  documentation from existing codebases. Use PROACTIVELY for system
  documentation, architecture guides, or technical deep-dives.
```

These descriptions tend to be longer than skill catalog entries (~50-150 tokens each) because they include usage guidance and examples.

**Typical size:** ~1,000-2,000 tokens (depends on number of plugin subagents)

### MCP Server Instructions

MCP servers can provide free-form instructions that get injected into the system prompt. These tell Claude how to use that server's tools effectively.

Example:

```
## context7
Use this server to retrieve up-to-date documentation and code
examples for any library.
```

Some servers (like `claude-in-chrome`) inject extensive instructions covering safety rules, interaction patterns, and behavioral guidelines. These can be significant -- the browser automation instructions alone can be several thousand tokens.

**Typical size:** Varies widely (~100-3,000+ tokens per server)

### Environment and Git Context

Automatically detected context about the current environment:

- Working directory and whether it's a git repo
- Platform (darwin, linux, windows)
- Current date
- Model name and ID
- Git branch, status, and recent commits (snapshot at session start)

**Typical size:** ~200-500 tokens

### Plugin-Injected Content

Plugins can inject additional content through hooks and system reminders:

- **PreToolUse hooks** -- Validation scripts that run before tool execution
- **PostToolUse hooks** -- Scripts that run after tool execution
- **System reminders** -- Status messages, context updates, skill availability lists
- **Startup hooks** -- Initial context injection at session start

Hook outputs appear as `<system-reminder>` blocks in the conversation, not in the system prompt itself. But they still consume tokens as part of the conversation history.

**Typical size:** Variable (minimal for well-designed hooks)

---

## How It Gets Assembled

At session startup:

```
1. Load core instructions (built-in, static)
        │
2. Discover and load CLAUDE.md files (all scopes)
        │
3. Enumerate enabled skills → build catalog
        │
4. Enumerate enabled plugin subagents → add to Task tool definition
        │
5. Connect MCP servers → add tool definitions + server instructions
        │
6. Detect environment (OS, git status, working directory)
        │
7. Run startup hooks → inject initial context
        │
8. Assemble complete system prompt
        │
9. First API call: system prompt + user's first message
```

On subsequent messages, the system prompt stays largely the same. What changes:

- System reminders get appended to the conversation (not the system prompt)
- Context compaction may summarize older messages when approaching limits
- Skill invocations add content to the conversation history

---

## Why This Matters

### Token Cost

The system prompt is re-sent on every API call. For a 15,000-token system prompt over a 200-message session:

- **Input tokens from system prompt alone:** 3,000,000
- **At Opus input pricing ($15/M tokens):** ~$45 just for the system prompt
- **At Sonnet input pricing ($3/M tokens):** ~$9

This is the baseline cost before conversation content. It's why managing system prompt size matters.

### Behavior Shaping

Everything in the system prompt is treated as high-priority instruction. This is why:

- CLAUDE.md rules actually work -- they're literally in the model's instructions
- Skill descriptions determine auto-discovery success
- Safety rules can't be overridden by conversation content
- Tool definitions constrain what actions are possible

The system prompt is the highest-authority input. User messages come second. Web content and tool results come last.

### Prompt Caching

Claude Code uses prompt caching to mitigate the cost of re-sending the system prompt. Since the system prompt is nearly identical across messages, the cached portion doesn't incur full input token costs on subsequent calls.

**How it helps:**

- First message: full cost for system prompt tokens
- Subsequent messages: cached system prompt tokens cost ~90% less
- Cache invalidates if the system prompt changes significantly

This means the per-message cost of a large system prompt is real but partially mitigated. The first message in a session pays the full price; subsequent messages benefit from caching.

---

## What You Can Control

| Component                 | Controllable? | How                               |
| ------------------------- | ------------- | --------------------------------- |
| Core instructions         | No            | Built into Claude Code            |
| Built-in tool definitions | No            | Fixed set                         |
| CLAUDE.md files           | Yes           | Edit the files, keep them concise |
| Skill catalog             | Yes           | Enable/disable skills and plugins |
| Subagent catalog          | Yes           | Enable/disable plugins            |
| MCP tool definitions      | Yes           | Add/remove MCP servers            |
| MCP server instructions   | Partially     | Server-dependent                  |
| Environment context       | No            | Auto-detected                     |

The biggest optimization levers:

1. **Disable unused plugins** -- Removes their skills and subagents from the catalog
2. **Keep CLAUDE.md concise** -- Every line is re-sent every message
3. **Remove unused MCP servers** -- Each adds tool definitions to the baseline
4. **Disable unused local skills** -- Removes catalog entries

See the [token optimization article](claude-code-token-optimization.md) for a detailed audit process.

---

## References

- [Memory System](https://code.claude.com/docs/en/memory.md) -- CLAUDE.md hierarchy, scopes, precedence
- [Skills](https://code.claude.com/docs/en/skills.md) -- Skill catalog, auto-discovery
- [Plugins](https://code.claude.com/docs/en/plugins.md) -- Plugin architecture, skill/subagent registration
- [MCP Servers](https://code.claude.com/docs/en/mcp.md) -- Tool definitions, server instructions
- [Model Configuration](https://code.claude.com/docs/en/model-config.md) -- Context windows, prompt caching
- [Hooks](https://code.claude.com/docs/en/hooks.md) -- Hook types, system reminders
