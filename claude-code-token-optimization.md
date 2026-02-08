# Optimizing Token Usage: Skills, Plugins, and Context Budget

## Executive Summary

Every Claude Code session carries a baseline token cost from skills, plugins, and system configuration loaded into the context window. This cost is per-message -- paid on every API round-trip, not just when features are used. Understanding and managing this overhead directly impacts session cost, available context for actual work, and response latency.

| Component                                        | When Loaded        | Token Cost Pattern          |
| ------------------------------------------------ | ------------------ | --------------------------- |
| **Skill catalog** (names + descriptions)         | Every message      | ~25-100 tokens per skill    |
| **Skill content** (full SKILL.md)                | On invocation only | Varies (can be significant) |
| **Plugin subagents** (descriptions in Task tool) | Every message      | ~50-150 tokens per subagent |
| **CLAUDE.md files**                              | Every message      | Entire file contents        |
| **MCP tool definitions**                         | Every message      | ~30-80 tokens per tool      |

A typical setup with 20+ plugins can consume **4,000-5,000+ tokens per message** just for the skill/subagent catalog -- before any actual work happens.

---

## Table of Contents

- [How Token Overhead Works](#how-token-overhead-works)
  - [The Two-Phase Cost Model](#the-two-phase-cost-model)
  - [What Gets Loaded at Startup](#what-gets-loaded-at-startup)
  - [Where Tokens Go](#where-tokens-go)
- [Auditing Your Setup](#auditing-your-setup)
  - [Step 1: Inventory Plugins](#step-1-inventory-plugins)
  - [Step 2: Inventory Local Skills](#step-2-inventory-local-skills)
  - [Step 3: Estimate Token Costs](#step-3-estimate-token-costs)
- [Decision Framework](#decision-framework)
  - [Keep, Disable, or Replace](#keep-disable-or-replace)
  - [Identifying Redundancy](#identifying-redundancy)
  - [The Superpowers Problem](#the-superpowers-problem)
- [Worked Example: A Real Audit](#worked-example-a-real-audit)
  - [Before: 21 Plugins + 5 Local Skills](#before-21-plugins--5-local-skills)
  - [After: 9 Plugins + 3 Local Skills](#after-9-plugins--3-local-skills)
  - [Estimated Savings](#estimated-savings)
- [Managing Skills and Plugins](#managing-skills-and-plugins)
  - [Local Skills with claudeup](#local-skills-with-claudeup)
  - [Plugin Management](#plugin-management)
  - [Per-Project Overrides](#per-project-overrides)
- [Best Practices](#best-practices)
- [References](#references)

---

## How Token Overhead Works

### The Two-Phase Cost Model

Skills and plugins have two distinct token costs:

**Phase 1: Catalog (every message)**

The skill catalog -- names, descriptions, and trigger conditions for all enabled skills -- is injected into the system prompt on every API call. This is how Claude knows what skills exist and when to invoke them. Each entry costs tokens whether or not it's used.

**Phase 2: Content (on invocation only)**

The full skill content (SKILL.md instructions, supporting files) loads only when the Skill tool is called. This is the expensive part but only happens when needed.

```
Every Message (unavoidable)
┌─────────────────────────────────────────────────┐
│ System Prompt                                   │
│ ├── CLAUDE.md files (all scopes)                │
│ ├── Skill catalog (name + description each)     │
│ ├── Subagent catalog (name + description each)  │
│ ├── MCP tool definitions                        │
│ └── Tool descriptions (Read, Edit, Bash, etc.)  │
└─────────────────────────────────────────────────┘

On Demand (only when used)
┌─────────────────────────────────────────────────┐
│ Skill invocation → full SKILL.md loaded         │
│ Subagent spawn → fresh context created          │
│ MCP tool call → request/response tokens         │
└─────────────────────────────────────────────────┘
```

### What Gets Loaded at Startup

Every enabled plugin and local skill contributes to the per-message baseline:

1. **Skill entries** -- Each skill adds a catalog entry with its name, description, and trigger conditions (~25-100 tokens each)
2. **Subagent entries** -- Each plugin subagent adds a description block in the Task tool definition (~50-150 tokens each)
3. **MCP tool definitions** -- Each MCP server tool adds its schema and description (~30-80 tokens each)

These are cumulative. A plugin that provides 3 skills and 2 subagents might add 300-500 tokens to every message.

### Where Tokens Go

For a session with 21 plugins and 5 local skills (a real configuration):

| Category                   | Entries       | Est. Tokens/Message |
| -------------------------- | ------------- | ------------------- |
| Skill catalog              | ~63 skills    | ~4,400              |
| Subagent catalog           | ~17 subagents | ~1,700              |
| MCP tool definitions       | ~20+ tools    | ~1,200              |
| CLAUDE.md (user scope)     | 1 file        | ~2,000-4,000        |
| Built-in tool descriptions | ~15 tools     | ~3,000              |
| **Total baseline**         |               | **~12,000-14,000**  |

That's 12,000+ tokens consumed before you type a single character. Over a 200-message session, the skill/subagent catalog alone costs roughly 1.2M input tokens.

---

## Auditing Your Setup

### Step 1: Inventory Plugins

Check enabled plugins in `~/.claude/settings.json`:

```json
"enabledPlugins": {
    "plugin-name@marketplace": true,
    "another-plugin@marketplace": true
}
```

Each `true` entry is an enabled plugin contributing skills, subagents, or both to your baseline.

### Step 2: Inventory Local Skills

Use `claudeup` to see what's enabled:

```bash
claudeup local list
```

Items marked with `*` are enabled. Items marked with `x` are disabled. Focus on the `skills:` section.

### Step 3: Estimate Token Costs

Look at your skill catalog in a running session. The system reminder will contain a block starting with "The following skills are available for use with the Skill tool:" -- that's the full catalog text loaded every message.

Rough estimation by description length:

| Description Type             | Example                                                                                                   | ~Tokens |
| ---------------------------- | --------------------------------------------------------------------------------------------------------- | ------- |
| Short (name + brief trigger) | `commit: Create a git commit`                                                                             | ~25     |
| Medium (trigger + context)   | `golang: Go patterns for backend development, testing, and clean architecture. Use when writing Go code.` | ~50     |
| Long (trigger + examples)    | Skills with multiple trigger examples and detailed descriptions                                           | ~80-120 |

Multiply by entry count for a rough total.

---

## Decision Framework

### Keep, Disable, or Replace

For each plugin/skill, ask these questions:

```
Is this relevant to my current workflow?
│
├── NO → Disable it
│
├── YES → Do I use it frequently?
│   │
│   ├── Rarely (< once per week) → Disable, re-enable when needed
│   │
│   └── Regularly → Keep it
│       │
│       └── Does it overlap with another plugin?
│           │
│           ├── YES → Keep the better one, disable the other
│           │
│           └── NO → Keep it
│
└── MAYBE → Is the token cost worth having it "just in case"?
    │
    ├── Small cost (1 skill, no subagents) → Keep
    │
    └── Large cost (many skills/subagents) → Disable until needed
```

### Identifying Redundancy

Common overlaps to watch for:

| Overlap                                            | Resolution                                                                                                                                       |
| -------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| `code-review` plugin vs `pr-review-toolkit` plugin | pr-review-toolkit is more comprehensive (6 subagents vs 1 skill). Keep pr-review-toolkit.                                                        |
| `commit-commands` plugin vs local `commit` command | If your CLAUDE.md has detailed git rules, the local command may suffice.                                                                         |
| Multiple code review subagents across plugins      | `code-documentation`, `feature-dev`, `pr-review-toolkit`, and `superpowers` all provide code-reviewer subagents.                                 |
| Duplicate skill entries                            | Some plugins register skills twice with different descriptions (e.g., vercel registering `deploy`, `setup`, `logs` in both short and long form). |

### The Superpowers Problem

Some plugins are all-or-nothing. The `superpowers` plugin, for example, provides 14 skills and 1 subagent (~1,400 catalog tokens). You can't selectively disable individual skills within a plugin.

Options:

1. **Keep the whole plugin** -- Accept the token cost if you use 3+ skills regularly
2. **Disable and recreate locally** -- Extract the 2-3 skills you need as local skills in `~/.claude/skills/`
3. **Disable entirely** -- If you rarely use any of its skills

The break-even point: if a plugin provides N skills and you use M of them, the wasted overhead is roughly `(N - M) * tokens_per_skill` per message. For superpowers with 14 skills at ~100 tokens each, using only 3 wastes ~1,100 tokens/message.

---

## Worked Example: A Real Audit

### Before: 21 Plugins + 5 Local Skills

Starting configuration:

**Plugins (21):**

| Plugin               | Skills | Subagents | Notes                              |
| -------------------- | ------ | --------- | ---------------------------------- |
| claude-hud           | 2      | 0         | Statusline dependency              |
| claude-mem           | 3      | 0         | Cross-session memory               |
| safety-hooks         | 0      | 0         | Hooks only, minimal cost           |
| claude-code-setup    | 1      | 0         | Automation recommender             |
| claude-md-management | 2      | 0         | CLAUDE.md maintenance              |
| code-documentation   | 0      | 3         | Subagents only                     |
| code-review          | 1      | 0         | Overlaps with pr-review-toolkit    |
| commit-commands      | 3      | 0         | Overlaps with local commit command |
| conductor            | 9      | 1         | Project management framework       |
| elements-of-style    | 1      | 0         | Prose writing rules                |
| episodic-memory      | 2      | 1         | Conversation search                |
| feature-dev          | 1      | 3         | Guided feature development         |
| frontend-design      | 1      | 0         | Frontend UI building               |
| gopls-lsp            | 0      | 0         | Go LSP tools                       |
| hookify              | 4      | 1         | Hook management                    |
| openapi              | 1      | 1         | OpenAPI doc generation             |
| pr-review-toolkit    | 1      | 6         | Comprehensive PR review            |
| security-guidance    | 0      | 0         | Minimal cost                       |
| superpowers          | 14     | 1         | Largest single consumer            |
| vercel               | 6      | 0         | 3 skills duplicated                |

**Local Skills (5):** bash, golang, pr-comments, vercel-react-best-practices, web-design-guidelines

**Estimated catalog cost: ~4,400 tokens/message (skills) + ~1,700 tokens/message (subagents)**

### Applying the Decision Framework

**Definite disables (not relevant to Go backend workflow):**

- vercel -- Not deploying to Vercel
- frontend-design -- Backend-focused work
- conductor -- Not using this project management framework
- elements-of-style -- Nice but not worth per-message cost
- openapi -- Not generating OpenAPI docs regularly
- vercel-react-best-practices (local) -- React/Next.js, irrelevant
- web-design-guidelines (local) -- UI auditing, irrelevant

**Redundancy eliminations:**

- code-review -- Overlaps with pr-review-toolkit
- commit-commands -- Local commit command + CLAUDE.md git rules suffice
- code-documentation -- 3 subagents rarely used

**Kept (essential or high-value):**

- claude-hud -- Statusline depends on it
- claude-mem -- Cross-session memory
- safety-hooks -- Hooks, minimal cost
- gopls-lsp -- Go LSP, essential
- episodic-memory -- Conversation search
- hookify -- Active hooks need management
- pr-review-toolkit -- 6 review subagents, high value
- feature-dev -- Guided development with useful subagents
- superpowers -- Referenced in CLAUDE.md for TDD and debugging

### After: 9 Plugins + 3 Local Skills

**Plugins (9):** claude-hud, claude-mem, safety-hooks, gopls-lsp, episodic-memory, hookify, pr-review-toolkit, feature-dev, superpowers

**Local Skills (3):** bash, golang, pr-comments

### Estimated Savings

| Metric                                  | Before | After  | Saved  |
| --------------------------------------- | ------ | ------ | ------ |
| Plugins                                 | 21     | 9      | 12     |
| Skill catalog entries                   | ~63    | ~35    | ~28    |
| Subagent entries                        | ~17    | ~12    | ~5     |
| Est. catalog tokens/message             | ~6,100 | ~3,800 | ~2,300 |
| Cache-read cost, 200 msgs (Opus 4.6)    | ~$0.61 | ~$0.38 | ~$0.23 |
| Without-cache cost, 200 msgs (Opus 4.6) | ~$6.10 | ~$3.80 | ~$2.30 |

The dollar savings from catalog reduction are modest with [prompt caching](claude-code-prompt-caching.md) (cache reads are 10x cheaper than base input). The real win is **context window space** -- those ~2,300 tokens freed up per message are available for actual conversation content.

---

## Managing Skills and Plugins

### Local Skills with claudeup

```bash
# List all items and status (* = enabled, x = disabled)
claudeup local list

# Disable specific skills
claudeup local disable skills vercel-react-best-practices web-design-guidelines

# Enable specific skills
claudeup local enable skills golang bash

# Wildcards work
claudeup local enable skills gsd-*

# View a skill's contents
claudeup local view skills golang
```

### Plugin Management

Plugins are managed in `~/.claude/settings.json` under `enabledPlugins`:

```json
"enabledPlugins": {
    "plugin-name@marketplace": true,   // enabled
    "other-plugin@marketplace": false  // disabled (or remove the line)
}
```

To disable a plugin, set its value to `false` or remove the entry. Restart Claude Code for changes to take effect.

There is no way to selectively disable individual skills or subagents within a plugin. It's all-or-nothing per plugin.

### Per-Project Overrides

For project-specific needs, consider:

- **Project-level skills** (`.claude/skills/`) -- Only loaded in that project
- **Project CLAUDE.md** -- Project-specific instructions that don't bloat other projects
- Enable/disable plugins per project by maintaining different settings profiles (manual process)

---

## Best Practices

1. **Audit periodically** -- Review your enabled plugins every few weeks. Needs change; disabled plugins are easy to re-enable.

2. **Match plugins to workflow** -- A Go developer doesn't need frontend-design. A solo developer doesn't need conductor. Remove what doesn't match your current work.

3. **Eliminate redundancy** -- Multiple plugins often provide overlapping capabilities (especially code review). Keep the most comprehensive one.

4. **Watch for duplicates** -- Some plugins register the same skills twice with different description lengths. This is a plugin bug but costs you tokens.

5. **Prefer local skills over heavy plugins** -- If you only need 2 skills from a 14-skill plugin, extract those as local skills and disable the plugin.

6. **Keep essential infrastructure** -- Don't disable plugins your other tools depend on (e.g., claude-hud for statusline, gopls-lsp for Go development).

7. **Restart after changes** -- Plugin enable/disable changes require a Claude Code restart to take effect.

8. **Don't over-optimize** -- A few hundred tokens of overhead from a genuinely useful plugin is a good trade. Optimize the big wins first (unused plugins with many skills) before sweating small ones.

---

## References

- [Skills](https://code.claude.com/docs/en/skills.md) -- SKILL.md structure, auto-discovery, progressive loading
- [Subagents](https://code.claude.com/docs/en/sub-agents.md) -- Task delegation, isolation model
- [Plugins](https://code.claude.com/docs/en/plugins.md) -- Plugin architecture, installation, management
- [Memory](https://code.claude.com/docs/en/memory.md) -- CLAUDE.md hierarchy, context impact
- [Model Configuration](https://code.claude.com/docs/en/model-config.md) -- Context windows, prompt caching
