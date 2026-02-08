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

| Aspect | Subagents | Skills | MCP Servers |
|--------|-----------|--------|-------------|
| **Purpose** | Task delegation | Workflow guidance | External access |
| **Reasoning** | Full AI (isolated) | Inherits main | None (deterministic) |
| **Memory** | Session-based | Shared with main | Stateless |
| **Context** | Own window | Injected | Minimal overhead |
| **Invocation** | Explicit | Auto-discovered | Explicit tool calls |

**Key pattern: Lens + Reviewer**

Implementing both lightweight awareness (skill) and deep analysis (subagent) for the same domain:

- `security-lens` (skill) - Auto-activates during coding
- `security-auditor` (subagent) - Deep analysis when explicitly invoked

---

## Future Topics

Areas to document as I learn more about optimizing Claude Code workflows:

- **Effective Prompting** - How to structure requests for best outcomes
- **Context Management** - Strategies for staying within token budgets
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
