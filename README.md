# Claude Code Wiki

Personal knowledge base for optimizing outcomes with Claude Code - patterns, techniques, and architectural understanding for getting the most from AI-assisted development.

## Contents

### [Extension Mechanisms: Subagents, Skills, and MCP Servers](claude-code-extension-mechanisms.md)

Understanding the three ways Claude Code extends capabilities and when to use each:

**Covered topics:**

- Technical architecture of each mechanism
- When to use each approach (with decision matrix)
- Real-world examples for custom implementations
- Context window and memory implications
- Data flow comparisons and best practices

**Quick reference:**

| Aspect         | Subagents          | Skills            | MCP Servers          |
| -------------- | ------------------ | ----------------- | -------------------- |
| **Purpose**    | Task delegation    | Workflow guidance | External access      |
| **Reasoning**  | Full AI (isolated) | Inherits main     | None (deterministic) |
| **Memory**     | Session-based      | Shared with main  | Stateless            |
| **Context**    | Own window         | Injected          | Minimal overhead     |
| **Invocation** | Explicit           | Auto-discovered   | Explicit tool calls  |

**Key pattern: Lens + Reviewer**

Implementing both lightweight awareness (skill) and deep analysis (subagent) for the same domain:

- `security-lens` (skill) - Auto-activates during coding
- `security-auditor` (subagent) - Deep analysis when explicitly invoked

### [Optimizing Token Usage: Skills, Plugins, and Context Budget](claude-code-token-optimization.md)

Managing the per-message token overhead from skills, plugins, and system configuration:

**Covered topics:**

- Two-phase cost model (catalog vs invocation)
- How to audit your plugin and skill setup
- Decision framework for keep/disable/replace
- Worked example: cutting 21 plugins to 9
- Managing skills with `claudeup` and plugin settings

**Quick reference:**

| Component                | When Loaded        | Token Cost Pattern          |
| ------------------------ | ------------------ | --------------------------- |
| **Skill catalog**        | Every message      | ~25-100 tokens per skill    |
| **Skill content**        | On invocation only | Varies                      |
| **Plugin subagents**     | Every message      | ~50-150 tokens per subagent |
| **CLAUDE.md files**      | Every message      | Entire file contents        |
| **MCP tool definitions** | Every message      | ~30-80 tokens per tool      |

**Key insight:** A setup with 20+ plugins can consume 4,000-5,000+ tokens per message just for the skill/subagent catalog -- before any actual work happens.

### [The System Prompt: What Claude Reads Before You Say Anything](claude-code-system-prompt.md)

Understanding the hidden instruction text assembled and sent on every API call:

**Covered topics:**

- What the system prompt is and how it's assembled
- Anatomy of a Claude Code API call (system prompt + conversation + reminders)
- Every component: core instructions, tool definitions, CLAUDE.md, skill/subagent catalogs, MCP, environment
- Token cost implications and prompt caching
- What you can and can't control

**Quick reference:**

| Component             | Source                   | Typical Size              |
| --------------------- | ------------------------ | ------------------------- |
| **Core instructions** | Claude Code built-in     | ~3,000-5,000 tokens       |
| **Tool definitions**  | Built-in + MCP servers   | ~3,000-5,000 tokens       |
| **CLAUDE.md files**   | All scopes               | ~2,000-4,000 tokens       |
| **Skill catalog**     | Enabled skills + plugins | ~2,000-5,000 tokens       |
| **Subagent catalog**  | Plugin descriptions      | ~1,000-2,000 tokens       |
| **Typical total**     |                          | **~12,000-20,000 tokens** |

**Key insight:** The system prompt is re-sent on every API call. Prompt caching mitigates cost (~90% discount after first message), but the context window space is consumed regardless.

### [Prompt Caching: Why Your System Prompt Doesn't Cost What You Think](claude-code-prompt-caching.md)

How prompt caching reduces the cost of re-sending the system prompt on every API call:

**Covered topics:**

- How prefix-based caching works
- Cache hierarchy in Claude Code (tools → system → messages)
- Full pricing breakdown with worked cost examples
- Cache lifetime, minimum token requirements, and invalidation rules
- Cost optimization vs context optimization distinction

**Quick reference:**

| Operation              | Multiplier | Opus 4.6   | Sonnet 4.5 |
| ---------------------- | ---------- | ---------- | ---------- |
| **Cache write (5min)** | 1.25x base | $6.25/MTok | $3.75/MTok |
| **Cache read**         | 0.1x base  | $0.50/MTok | $0.30/MTok |
| **Uncached input**     | 1x base    | $5/MTok    | $3/MTok    |

**Key insight:** Cache reads are 10x cheaper than base input. A 15,000-token system prompt costs ~$1.60 over a 200-message Opus 4.6 session with caching, vs ~$15 without.

### [Context Management: Working Within the Token Budget](claude-code-context-management.md)

Strategies for managing the context window -- Claude's working memory during a session:

**Covered topics:**

- What the context window is and how it fills up
- What consumes context (file reads are the biggest variable cost)
- Compaction: auto-compact, manual `/compact`, and what's preserved vs lost
- Subagents as context management (97.5% context savings on delegated work)
- Extended thinking and context implications
- Practical strategies for long sessions

**Quick reference:**

| Model          | Standard | Extended (Beta) | Long Context Pricing |
| -------------- | -------- | --------------- | -------------------- |
| **Opus 4.6**   | 200K     | 1M              | 2x input above 200K  |
| **Sonnet 4.5** | 200K     | 1M              | 2x input above 200K  |
| **Haiku 4.5**  | 200K     | --              | --                   |

**Key insight:** Caching reduces cost; context management reduces space consumption. They're complementary -- you need both.

### [Effective Prompting: Getting Better Results from Claude Code](claude-code-effective-prompting.md)

How to structure your requests for better outcomes -- from single messages to multi-session workflows:

**Covered topics:**

- How Claude Code processes your messages (system prompt + conversation + your input)
- The fundamentals: be explicit, action vs suggestion, provide context, reference specific code
- Task decomposition and the iterative refinement loop
- CLAUDE.md as persistent prompting (what to include, what to omit, keeping it concise)
- Working across context windows (tests-first, state files, fresh vs compaction)
- Directing tool usage (subagent delegation, parallel operations, managing over-exploration)
- Common anti-patterns to avoid

**Quick reference:**

| Principle                    | Impact                                          | Effort   |
| ---------------------------- | ----------------------------------------------- | -------- |
| **Be explicit, not vague**   | Biggest single improvement in result quality    | Low      |
| **Action over suggestion**   | Gets implementation instead of recommendations  | Low      |
| **Provide context ("why")**  | Helps Claude generalize and make good choices   | Low      |
| **Reference specific code**  | Eliminates guesswork and speeds up responses    | Low      |
| **Decompose large tasks**    | Reduces errors, enables course correction       | Medium   |
| **Use CLAUDE.md well**       | Persistent rules applied to every message       | One-time |
| **Manage multi-window work** | Enables tasks that span beyond a single session | Medium   |

**Key insight:** Specific prompts get specific results. The biggest improvement comes from stating what you want, where, and why -- not from clever prompt engineering tricks.

### [Memory Organization: Structuring CLAUDE.md and Rules for Scale](claude-code-memory-organization.md)

How to organize Claude Code's memory system -- CLAUDE.md files, rules directories, auto memory, and imports:

**Covered topics:**

- The memory hierarchy: managed policy, project, user, local, auto memory, child CLAUDE.md
- How files are discovered (directory walk) and precedence rules
- User memory vs project memory vs project local -- what goes where
- The `.claude/rules/` directory for modular, path-specific rules
- Auto memory: the 200-line limit and topic file pattern
- Imports (`@path/to/file` syntax) for sharing content across files
- Context cost of memory files and how to measure your footprint
- Common mistakes (generic instructions, monolithic files, scope conflicts)

**Quick reference:**

| Memory Type        | Location                               | Scope              | Shared With           |
| ------------------ | -------------------------------------- | ------------------ | --------------------- |
| **Managed policy** | System-level path (IT-managed)         | Organization-wide  | All users             |
| **Project memory** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team + project     | Team (via git)        |
| **Project rules**  | `./.claude/rules/*.md`                 | Team + project     | Team (via git)        |
| **User memory**    | `~/.claude/CLAUDE.md`                  | All your projects  | Just you              |
| **Project local**  | `./CLAUDE.local.md`                    | You + this project | Just you (gitignored) |
| **Auto memory**    | `~/.claude/projects/<project>/memory/` | You + this project | Just you              |

**Key insight:** Every line of CLAUDE.md costs context window space on every message. Be specific, not generic -- "use slog for logging" beats "follow best practices."

---

## Future Topics

Areas to document as I learn more about optimizing Claude Code workflows:

- **Workflow Patterns** - Common development workflows and how to optimize them
- **Testing Strategies** - TDD patterns and test automation with Claude Code
- **Debugging Techniques** - Systematic approaches to troubleshooting
- **Integration Patterns** - Connecting Claude Code with external tools and services

---

## Official Resources

Claude Code documentation:

- [Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [Skills](https://code.claude.com/docs/en/skills.md)
- [MCP Servers](https://code.claude.com/docs/en/mcp.md)
- [Memory System](https://code.claude.com/docs/en/memory.md)
- [Hooks](https://code.claude.com/docs/en/hooks.md)
