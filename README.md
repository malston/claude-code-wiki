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

---

## Future Topics

Areas to document as I learn more about optimizing Claude Code workflows:

- **Effective Prompting** - How to structure requests for best outcomes
- **Memory Organization** - Structuring CLAUDE.md files for different scopes
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
