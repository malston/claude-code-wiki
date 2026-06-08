---
title: "Extending"
weight: 3
bookCollapseSection: false
---

# Extending

Building on Claude Code -- subagents, skills, hooks, MCP servers, integration patterns, multi-agent teams, and dynamic workflows.

- **[Extension Mechanisms]({{< relref "extending/extension-mechanisms" >}})** -- Architecture deep dive into subagents for task delegation, skills for knowledge and workflow injection, and MCP servers for external tool access.
- **[Custom Extensions]({{< relref "extending/custom-extensions" >}})** -- Building custom subagents, skills, and plugins. File structures, YAML configuration, tool permissions, model selection, and the lens+reviewer pattern.
- **[Hooks Cookbook]({{< relref "extending/hooks-cookbook" >}})** -- Copy-paste recipes for hook-based automation: auto-formatting, command safety, test gates, notifications, logging, and context injection.
- **[Integration Patterns]({{< relref "extending/integration-patterns" >}})** -- Connecting Claude Code with external tools via MCP servers, hooks, headless mode, and GitHub Actions.
- **[Agent Teams]({{< relref "extending/agent-teams" >}})** -- Multi-agent orchestration where multiple Claude Code instances coordinate through direct messaging, shared task lists, and team lead delegation.
- **[Dynamic Workflows]({{< relref "extending/dynamic-workflows" >}})** -- Orchestrating subagents at scale with a script Claude writes and the runtime runs in the background. The ultracode trigger, the `/workflows` view, saving workflows, and when to use them instead of subagents or agent teams.
