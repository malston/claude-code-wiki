# Integration Patterns: Connecting Claude Code with External Tools and Services

## Executive Summary

Claude Code connects to external systems through four integration mechanisms: MCP servers for tool access, hooks for workflow automation, headless mode for CLI scripting, and GitHub Actions for CI/CD. Each serves a different purpose and operates at a different layer. This article covers when to use each, how they work, and practical patterns for combining them.

| Mechanism          | Purpose                       | Direction            | Runs When                |
| ------------------ | ----------------------------- | -------------------- | ------------------------ |
| **MCP servers**    | Connect external tools/data   | Claude calls out     | Claude decides to use it |
| **Hooks**          | Automate around Claude's work | System calls scripts | Lifecycle events fire    |
| **Headless mode**  | Script Claude from outside    | External calls in    | Your script invokes it   |
| **GitHub Actions** | CI/CD automation              | Events call Claude   | GitHub events trigger it |

---

## Table of Contents

- [The Integration Landscape](#the-integration-landscape)
- [MCP Servers: Connecting External Tools](#mcp-servers-connecting-external-tools)
  - [Transport Types](#transport-types)
  - [Configuration Scopes](#configuration-scopes)
  - [Authentication](#authentication)
  - [Practical MCP Examples](#practical-mcp-examples)
  - [MCP Tool Search](#mcp-tool-search)
  - [MCP Resources](#mcp-resources)
- [Hooks: Automating Workflows](#hooks-automating-workflows)
  - [Hook Lifecycle](#hook-lifecycle)
  - [Hook Types](#hook-types)
  - [Common Hook Patterns](#common-hook-patterns)
  - [Async Hooks](#async-hooks)
  - [Hook Configuration Locations](#hook-configuration-locations)
- [Headless Mode: CLI Automation](#headless-mode-cli-automation)
  - [Basic Usage](#basic-usage)
  - [Output Formats](#output-formats)
  - [System Prompt Customization](#system-prompt-customization)
  - [Piping and Composition](#piping-and-composition)
  - [Automation Flags](#automation-flags)
- [GitHub Actions: CI/CD Integration](#github-actions-cicd-integration)
  - [The Official Action](#the-official-action)
  - [Setup](#setup)
  - [Common Workflows](#common-workflows)
  - [Cost Considerations](#cost-considerations)
- [Claude as MCP Server](#claude-as-mcp-server)
- [Plugins: Packaging Integrations](#plugins-packaging-integrations)
- [Integration Decision Framework](#integration-decision-framework)
- [Combining Integration Patterns](#combining-integration-patterns)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [References](#references)

---

## The Integration Landscape

Claude Code integrates with external systems through four distinct mechanisms. Each operates at a different layer and serves a different purpose:

```
                    ┌──────────────────────────────────┐
                    │          GitHub Events            │
                    │   (PR, issue, push, schedule)     │
                    └──────────────┬───────────────────┘
                                   │
                                   ▼
┌────────────┐    ┌──────────────────────────────────┐
│  Your       │───▶│         Claude Code               │
│  Scripts    │    │                                    │
│  (claude -p)│    │  ┌────────┐    ┌──────────────┐  │
└────────────┘    │  │ Hooks  │    │  MCP Servers  │  │
                    │  │ (auto) │    │  (on demand)  │  │
                    │  └───┬────┘    └──────┬───────┘  │
                    │      │               │           │
                    └──────┼───────────────┼───────────┘
                           │               │
                           ▼               ▼
                    ┌────────────┐  ┌──────────────┐
                    │ Local      │  │ External     │
                    │ Scripts    │  │ Services     │
                    │ (lint,     │  │ (GitHub,     │
                    │  format,   │  │  Sentry,     │
                    │  test)     │  │  Postgres,   │
                    └────────────┘  │  Notion...)  │
                                    └──────────────┘
```

**MCP servers** give Claude access to external tools and data. Claude decides when to call them during a conversation. Think of them as plugins that extend Claude's capabilities -- database access, issue trackers, monitoring systems.

**Hooks** run shell commands or LLM prompts at specific lifecycle points. They execute automatically when events fire -- after a file is written, before a tool runs, when a session starts. You don't ask Claude to run hooks; they run by themselves.

**Headless mode** (`claude -p`) turns Claude into a command-line tool that other programs can call. It reads a prompt, does the work, prints the result, and exits. This is what makes Claude composable with Unix pipelines and CI/CD systems.

**GitHub Actions** trigger Claude in response to GitHub events -- PR comments, issue creation, scheduled runs. The official `anthropics/claude-code-action` wraps headless mode into a GitHub-native integration.

---

## MCP Servers: Connecting External Tools

The Model Context Protocol (MCP) is an open standard for connecting AI tools to external services. MCP servers expose tools, resources, and prompts that Claude can use during conversations.

### Transport Types

MCP supports three transport mechanisms:

| Transport | How It Works                      | When to Use                       |
| --------- | --------------------------------- | --------------------------------- |
| **HTTP**  | Remote server, HTTP requests      | Cloud services, SaaS integrations |
| **SSE**   | Remote server, Server-Sent Events | Legacy servers (deprecated)       |
| **stdio** | Local process, stdin/stdout       | Local tools, custom scripts       |

```bash
# HTTP (recommended for remote servers)
claude mcp add --transport http notion https://mcp.notion.com/mcp

# stdio (for local processes)
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@localhost:5432/mydb"
```

HTTP is the recommended transport for remote services. SSE is deprecated. stdio runs a local process and communicates over stdin/stdout -- good for tools that need direct system access.

### Configuration Scopes

MCP servers can be configured at three scope levels:

| Scope       | Storage Location            | Shared?       | Use Case                           |
| ----------- | --------------------------- | ------------- | ---------------------------------- |
| **Local**   | `~/.claude.json`            | No (just you) | Personal dev servers, credentials  |
| **Project** | `.mcp.json` in project root | Yes (via git) | Team-shared tools                  |
| **User**    | `~/.claude.json`            | No (just you) | Personal tools across all projects |

```bash
# Local scope (default)
claude mcp add --transport http stripe https://mcp.stripe.com

# Project scope (shared via git)
claude mcp add --transport http paypal --scope project https://mcp.paypal.com/mcp

# User scope (available across all projects)
claude mcp add --transport http hubspot --scope user https://mcp.hubspot.com/anthropic
```

Project-scoped servers are the key collaboration feature. The `.mcp.json` file at your project root defines the MCP servers every team member gets:

```json
{
  "mcpServers": {
    "api-server": {
      "type": "http",
      "url": "${API_BASE_URL:-https://api.example.com}/mcp",
      "headers": {
        "Authorization": "Bearer ${API_KEY}"
      }
    }
  }
}
```

Environment variable expansion (`${VAR}` and `${VAR:-default}`) allows sharing configuration while keeping credentials local.

### Authentication

Remote MCP servers often require authentication. Claude Code supports OAuth 2.0 natively:

```bash
# Add the server
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# Authenticate (opens browser for OAuth flow)
# Type /mcp in Claude Code, then select "Authenticate"
```

For servers requiring pre-configured OAuth credentials:

```bash
claude mcp add --transport http \
  --client-id your-client-id --client-secret --callback-port 8080 \
  my-server https://mcp.example.com/mcp
```

Authentication tokens are stored securely and refreshed automatically.

### Practical MCP Examples

**Database access:**

```bash
claude mcp add --transport stdio db -- npx -y @bytebase/dbhub \
  --dsn "postgresql://readonly:pass@prod.db.com:5432/analytics"

# Then in Claude Code:
# "What's our total revenue this month?"
# "Show me the schema for the orders table"
```

**GitHub integration:**

```bash
claude mcp add --transport http github https://api.githubcopilot.com/mcp/

# "Review PR #456 and suggest improvements"
# "Create a new issue for the bug we just found"
```

**Error monitoring:**

```bash
claude mcp add --transport http sentry https://mcp.sentry.dev/mcp

# "What are the most common errors in the last 24 hours?"
# "Which deployment introduced these new errors?"
```

### MCP Tool Search

When you have many MCP servers, tool definitions can consume significant context. Claude Code's Tool Search feature automatically kicks in when MCP tool descriptions exceed 10% of the context window:

- MCP tools load on-demand instead of upfront
- Claude searches for relevant tools when needed
- Context consumption drops significantly

Configure with the `ENABLE_TOOL_SEARCH` environment variable:

| Value      | Behavior                                   |
| ---------- | ------------------------------------------ |
| `auto`     | Activates when tools exceed 10% of context |
| `auto:<N>` | Custom threshold (e.g., `auto:5` for 5%)   |
| `true`     | Always enabled                             |
| `false`    | Disabled, all tools loaded upfront         |

### MCP Resources

MCP servers can expose resources that you reference with `@` mentions:

```
# Reference an issue directly
> Can you analyze @github:issue://123 and suggest a fix?

# Compare across sources
> Compare @postgres:schema://users with @docs:file://database/user-model
```

Resources are fetched and included as attachments when referenced.

---

## Hooks: Automating Workflows

Hooks are shell commands or LLM prompts that execute automatically at specific points in Claude Code's lifecycle. They're the mechanism for enforcing standards, automating side effects, and customizing behavior.

### Hook Lifecycle

Hooks fire at specific points during a session:

```
SessionStart ──▶ UserPromptSubmit ──▶ PreToolUse ──▶ [tool executes]
                                                          │
                  Stop ◀── PostToolUse/PostToolUseFailure ◀┘
                   │
                   ▼
              SessionEnd
```

Key events:

| Event              | When It Fires               | Can Block? |
| ------------------ | --------------------------- | ---------- |
| `SessionStart`     | Session begins or resumes   | No         |
| `UserPromptSubmit` | User submits a prompt       | Yes        |
| `PreToolUse`       | Before a tool call executes | Yes        |
| `PostToolUse`      | After a tool call succeeds  | No (done)  |
| `Stop`             | Claude finishes responding  | Yes        |
| `Notification`     | Claude sends a notification | No         |
| `SubagentStart`    | A subagent is spawned       | No         |
| `SubagentStop`     | A subagent finishes         | Yes        |
| `TaskCompleted`    | A task is marked completed  | Yes        |
| `PreCompact`       | Before context compaction   | No         |
| `SessionEnd`       | Session terminates          | No         |

### Hook Types

Claude Code supports three hook types:

**Command hooks** run a shell command:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/lint.sh"
          }
        ]
      }
    ]
  }
}
```

**Prompt hooks** send a prompt to a Claude model for single-turn evaluation:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Check if all tasks are complete: $ARGUMENTS",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

**Agent hooks** spawn a subagent with tool access for multi-turn verification:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Verify all unit tests pass. Run the test suite. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### Common Hook Patterns

**Auto-format after file writes:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/format.sh"
          }
        ]
      }
    ]
  }
}
```

**Block destructive commands:**

```bash
#!/bin/bash
# .claude/hooks/block-dangerous.sh
COMMAND=$(jq -r '.tool_input.command')
if echo "$COMMAND" | grep -q 'rm -rf'; then
  jq -n '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: "Destructive command blocked"
    }
  }'
else
  exit 0
fi
```

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous.sh"
          }
        ]
      }
    ]
  }
}
```

**Auto-run tests after file changes:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/run-tests.sh",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

**Load project context at session start:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/load-context.sh"
          }
        ]
      }
    ]
  }
}
```

**Set environment variables for the session:**

```bash
#!/bin/bash
# .claude/hooks/setup-env.sh
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
  echo 'export DEBUG=true' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

The `CLAUDE_ENV_FILE` variable is available in `SessionStart` hooks. Variables written to this file persist for all Bash commands in the session.

### Async Hooks

By default, hooks block Claude's execution until they complete. For long-running tasks, set `"async": true` to run in the background:

```json
{
  "type": "command",
  "command": ".claude/hooks/run-tests.sh",
  "async": true,
  "timeout": 300
}
```

Async hooks cannot block or return decisions -- the triggering action has already proceeded. Output is delivered on the next conversation turn.

### Hook Configuration Locations

| Location                      | Scope              | Shared?              |
| ----------------------------- | ------------------ | -------------------- |
| `~/.claude/settings.json`     | All your projects  | No                   |
| `.claude/settings.json`       | Single project     | Yes (via git)        |
| `.claude/settings.local.json` | Single project     | No (gitignored)      |
| Plugin `hooks/hooks.json`     | When plugin active | Yes (with plugin)    |
| Skill/agent YAML frontmatter  | While active       | Yes (with component) |

Use `/hooks` in Claude Code to manage hooks interactively.

---

## Headless Mode: CLI Automation

The `-p` (or `--print`) flag runs Claude Code non-interactively: it reads a prompt, does the work, prints the result to stdout, and exits. This turns Claude into a composable command-line tool.

### Basic Usage

```bash
# Simple query
claude -p "Generate a .gitignore for a Go project"

# Process piped input
cat src/utils.ts | claude -p "Find potential bugs"

# Reference files with @
claude -p "Refactor @src/api/auth.ts to use async/await"
```

### Output Formats

| Format     | Flag                          | Use Case                        |
| ---------- | ----------------------------- | ------------------------------- |
| **Text**   | `--output-format text`        | Human-readable output (default) |
| **JSON**   | `--output-format json`        | Structured output for scripts   |
| **Stream** | `--output-format stream-json` | Real-time streaming for UIs     |

```bash
# Get structured JSON output
claude -p "List all TODO comments in the codebase" --output-format json

# Stream results for real-time display
claude -p "Refactor auth module" --output-format stream-json
```

For validated structured output, use `--json-schema`:

```bash
claude -p --json-schema '{"type":"object","properties":{"bugs":{"type":"array"}}}' \
  "Find bugs in @src/auth.ts"
```

### System Prompt Customization

Four flags for controlling the system prompt in headless mode:

| Flag                          | Effect                        | Keeps defaults? |
| ----------------------------- | ----------------------------- | --------------- |
| `--system-prompt`             | Replaces entire system prompt | No              |
| `--system-prompt-file`        | Replaces with file contents   | No              |
| `--append-system-prompt`      | Appends to default prompt     | Yes             |
| `--append-system-prompt-file` | Appends file contents         | Yes             |

```bash
# Add rules while keeping Claude Code defaults (recommended)
claude -p --append-system-prompt "Always use TypeScript" "Review this file"

# Load custom rules from a file
claude -p --append-system-prompt-file ./prompts/review-rules.txt "Review this PR"

# Complete prompt replacement (loses Claude Code defaults)
claude -p --system-prompt "You are a security auditor" "Audit @src/auth.ts"
```

For most use cases, `--append-system-prompt` is safest because it preserves Claude Code's built-in capabilities.

### Piping and Composition

Headless mode composes with Unix pipelines:

```bash
# Analyze test output
go test ./... 2>&1 | claude -p "Explain these test failures"

# Review a diff
git diff main | claude -p "Review these changes for bugs"

# Process multiple files
find . -name "*.go" -newer go.sum | \
  xargs cat | \
  claude -p "Find any Go 1.22 features in these recently modified files"

# Chain Claude invocations
claude -p "Find all API endpoints in @src/" --output-format json | \
  claude -p "Generate OpenAPI docs for these endpoints"
```

### Automation Flags

Flags useful for headless/scripted usage:

| Flag                       | Purpose                                       |
| -------------------------- | --------------------------------------------- |
| `--max-turns N`            | Limit agentic turns (prevent runaway)         |
| `--max-budget-usd N`       | Cap API spend per invocation                  |
| `--allowedTools "..."`     | Restrict which tools Claude can use           |
| `--disallowedTools "..."`  | Block specific tools                          |
| `--model alias`            | Choose model (`sonnet`, `opus`, `haiku`)      |
| `--fallback-model alias`   | Fallback when primary is overloaded           |
| `--permission-mode mode`   | Set permission mode (`plan`, `dontAsk`, etc.) |
| `--mcp-config path`        | Load MCP servers from config file             |
| `--no-session-persistence` | Don't save session to disk                    |

```bash
# Constrained automation: limited turns, specific tools, capped budget
claude -p \
  --max-turns 5 \
  --max-budget-usd 2.00 \
  --allowedTools "Read" "Grep" "Glob" \
  --model sonnet \
  "Find all functions that handle authentication"
```

Authentication for headless mode uses the `CLAUDE_CODE_API_KEY` environment variable:

```bash
export CLAUDE_CODE_API_KEY="sk-ant-..."
claude -p "Review this codebase for security issues"
```

---

## GitHub Actions: CI/CD Integration

The official `anthropics/claude-code-action` brings Claude into your GitHub workflow. Tag `@claude` in any PR or issue comment, or trigger Claude automatically on GitHub events.

### The Official Action

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

Two modes of operation:

1. **Interactive** -- Claude responds to `@claude` mentions in PR/issue comments
2. **Automation** -- Claude runs immediately with a provided prompt

The action auto-detects which mode to use based on your configuration.

### Setup

**Quick setup (recommended):**

```bash
# In Claude Code terminal
/install-github-app
```

This installs the Claude GitHub app and configures secrets automatically.

**Manual setup:**

1. Install the Claude GitHub app: https://github.com/apps/claude
2. Add `ANTHROPIC_API_KEY` to repository secrets
3. Copy the workflow file from [examples/claude.yml](https://github.com/anthropics/claude-code-action/blob/main/examples/claude.yml)

### Common Workflows

**Respond to @claude mentions in PRs and issues:**

```yaml
name: Claude Code
on:
  issue_comment:
    types: [created]
  pull_request_review_comment:
    types: [created]
jobs:
  claude:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
```

**Auto-review PRs on open:**

```yaml
name: Code Review
on:
  pull_request:
    types: [opened, synchronize]
jobs:
  review:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "/review"
          claude_args: "--max-turns 5"
```

**Scheduled reports:**

```yaml
name: Daily Report
on:
  schedule:
    - cron: "0 9 * * *"
jobs:
  report:
    runs-on: ubuntu-latest
    steps:
      - uses: anthropics/claude-code-action@v1
        with:
          anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
          prompt: "Generate a summary of yesterday's commits and open issues"
```

**Key parameters:**

| Parameter           | Description                                |
| ------------------- | ------------------------------------------ |
| `prompt`            | Instructions or skill (e.g., `/review`)    |
| `claude_args`       | CLI flags passed to Claude Code            |
| `anthropic_api_key` | API key from repository secrets            |
| `trigger_phrase`    | Custom trigger (default: `@claude`)        |
| `use_bedrock`       | Use AWS Bedrock instead of direct API      |
| `use_vertex`        | Use Google Vertex AI instead of direct API |

Pass any CLI flag via `claude_args`:

```yaml
claude_args: "--max-turns 5 --model claude-sonnet-4-5-20250929"
```

### Cost Considerations

GitHub Actions with Claude incurs two costs:

1. **GitHub Actions minutes** -- Runner time consumed per job
2. **API tokens** -- Claude API usage based on prompt/response length

Optimization tips:

- Set `--max-turns` to prevent excessive iterations
- Use workflow-level timeouts
- Use GitHub concurrency controls to limit parallel runs
- Be specific with `@claude` commands to reduce unnecessary work

---

## Claude as MCP Server

Claude Code can expose itself as an MCP server that other applications connect to:

```bash
claude mcp serve
```

This makes Claude Code's tools (Read, Edit, Glob, Grep, etc.) available to other MCP clients. Configure in Claude Desktop:

```json
{
  "mcpServers": {
    "claude-code": {
      "type": "stdio",
      "command": "claude",
      "args": ["mcp", "serve"],
      "env": {}
    }
  }
}
```

This enables scenarios where other AI assistants or tools delegate file operations to Claude Code.

---

## Plugins: Packaging Integrations

Plugins bundle multiple integration mechanisms -- MCP servers, hooks, skills, and subagents -- into a distributable package. When a plugin is enabled, all its components activate together.

A plugin can include MCP servers in two ways:

**`.mcp.json` at the plugin root:**

```json
{
  "database-tools": {
    "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
    "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
    "env": {
      "DB_URL": "${DB_URL}"
    }
  }
}
```

**Inline in `plugin.json`:**

```json
{
  "name": "my-plugin",
  "mcpServers": {
    "plugin-api": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/api-server",
      "args": ["--port", "8080"]
    }
  }
}
```

Plugin MCP servers start automatically when the plugin is enabled. The `${CLAUDE_PLUGIN_ROOT}` variable resolves to the plugin's directory.

Hooks are defined in `hooks/hooks.json` within the plugin:

```json
{
  "description": "Automatic code formatting",
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format.sh",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

---

## Integration Decision Framework

Use this flowchart to choose the right integration mechanism:

```
Need Claude to access an external service?
  YES ──▶ MCP server
  NO  ──▼

Need something to run automatically during Claude's work?
  YES ──▶ Hook
  NO  ──▼

Need to call Claude from a script or pipeline?
  YES ──▶ Headless mode (claude -p)
  NO  ──▼

Need Claude to respond to GitHub events?
  YES ──▶ GitHub Actions
  NO  ──▼

Need to package multiple integrations for a team?
  YES ──▶ Plugin
```

Decision matrix for common scenarios:

| Scenario                                | Mechanism          | Why                                    |
| --------------------------------------- | ------------------ | -------------------------------------- |
| Query a database during conversations   | MCP server         | Claude needs on-demand access to data  |
| Auto-format files after every edit      | Hook (PostToolUse) | Runs automatically, no Claude decision |
| Review PRs when they're opened          | GitHub Actions     | Triggered by GitHub events             |
| Analyze test output in a shell script   | Headless mode      | Script calls Claude, processes output  |
| Block dangerous shell commands          | Hook (PreToolUse)  | Must intercept before execution        |
| Generate daily code quality reports     | GitHub Actions     | Scheduled trigger, structured output   |
| Access Jira issues during development   | MCP server         | Claude calls it when discussing tasks  |
| Run tests after Claude edits files      | Hook (async)       | Background verification, non-blocking  |
| Migrate 100 files with the same pattern | Headless mode      | Batch processing via loop              |
| Share team tooling configuration        | Plugin             | Bundles MCP + hooks + skills together  |

---

## Combining Integration Patterns

The real power comes from combining mechanisms. Here are practical multi-mechanism patterns:

### MCP + Hooks: Auto-Validated External Access

Use an MCP server for database access, with a hook that validates queries before they execute:

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "mcp__db__.*",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/validate-query.sh"
          }
        ]
      }
    ]
  }
}
```

The hook runs before every database MCP tool call, checking for destructive operations.

### Headless + GitHub Actions: Automated PR Reviews

A GitHub Action triggers headless Claude to review PRs and post results:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    prompt: "/review"
    claude_args: "--max-turns 5 --model sonnet"
```

### Hooks + Headless: Self-Correcting CI Pipeline

A `Stop` hook verifies all tests pass before Claude finishes. If tests fail, Claude continues working:

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Run the test suite and verify all tests pass. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

### Project-Scoped MCP + CLAUDE.md: Team Consistency

Share MCP configuration and usage guidelines together:

`.mcp.json` (committed to git):

```json
{
  "mcpServers": {
    "sentry": {
      "type": "http",
      "url": "https://mcp.sentry.dev/mcp"
    }
  }
}
```

`CLAUDE.md` (committed to git):

```markdown
## Error Investigation

When investigating production errors, always check Sentry first
using the sentry MCP server before looking at logs.
```

---

## Best Practices

1. **Start with the simplest mechanism.** If a hook can solve it, don't build an MCP server. If headless mode works, don't set up GitHub Actions.

2. **Use project scope for team-shared integrations.** `.mcp.json` and `.claude/settings.json` go into version control. Credentials stay in environment variables or local scope.

3. **Set timeouts on all hooks.** A hung hook blocks Claude indefinitely. Default is 600 seconds for commands, 30 for prompts, 60 for agents -- adjust based on your use case.

4. **Use `--max-turns` in CI.** Headless mode and GitHub Actions should always have turn limits to prevent runaway sessions and unbounded costs.

5. **Keep hooks fast.** Hooks run frequently -- after every tool call, on every prompt. A 5-second hook that runs after every file write adds up quickly. Use async hooks for anything slow.

6. **Use environment variable expansion in `.mcp.json`.** Never hardcode credentials. Use `${API_KEY}` syntax with defaults where appropriate.

7. **Match MCP tools specifically in hooks.** Use regex matchers like `mcp__db__write.*` rather than broad patterns. Matching `mcp__.*` catches every MCP tool call.

8. **Test hooks in isolation first.** Run hook scripts manually with sample JSON input before configuring them in Claude Code. Use `claude --debug` to see hook execution details.

9. **Use the `/hooks` and `/mcp` menus.** These interactive menus show what's configured and let you manage integrations without editing JSON files directly.

10. **Document MCP server instructions.** If you're building an MCP server, the server instructions field helps Claude understand when to search for your tools (especially with Tool Search enabled).

---

## Anti-Patterns

### Using MCP When a Hook Would Suffice

```
Bad:  Building an MCP server to run linters after file edits
      (Claude has to decide to call it)

Good: A PostToolUse hook that auto-runs linters on Write|Edit
      (runs automatically, no Claude decision needed)
```

MCP servers are for when Claude needs on-demand access to external data or services. For automatic reactions to events, use hooks.

### Headless Mode Without Turn Limits

```
Bad:  claude -p "Fix all the bugs in this codebase"
      (could run indefinitely, consuming unlimited tokens)

Good: claude -p --max-turns 10 --max-budget-usd 5.00 \
        "Fix the authentication bug in @src/auth.ts"
      (bounded scope, bounded cost)
```

Always set `--max-turns` and/or `--max-budget-usd` in automated contexts.

### Blocking Hooks That Should Be Async

```
Bad:  A PostToolUse hook that runs the full test suite
      synchronously after every file write
      (Claude waits minutes between each edit)

Good: The same hook with "async": true
      (Claude continues working, test results arrive later)
```

If a hook doesn't need to block Claude's next action, make it async.

### Hardcoding Credentials in Project Config

```
Bad:  .mcp.json with "Authorization": "Bearer sk-ant-abc123..."
      (committed to git, visible to everyone)

Good: .mcp.json with "Authorization": "Bearer ${API_KEY}"
      (credentials in local environment)
```

Credentials belong in environment variables or local-scoped configuration, not in version-controlled files.

### Over-Broad Hook Matchers

```
Bad:  A PreToolUse hook with no matcher that runs
      on every single tool call
      (adds latency to reads, searches, everything)

Good: A PreToolUse hook with matcher "Bash" that only
      checks shell commands
      (runs only when relevant)
```

Use the most specific matcher possible to minimize unnecessary hook executions.

---

## References

- [MCP Documentation (Claude Code)](https://code.claude.com/docs/en/mcp) -- Official MCP configuration guide
- [Hooks Reference (Claude Code)](https://code.claude.com/docs/en/hooks) -- Hook events, schemas, and configuration
- [Hooks Guide (Claude Code)](https://code.claude.com/docs/en/hooks-guide) -- Practical hook setup walkthrough
- [CLI Reference (Claude Code)](https://code.claude.com/docs/en/cli-reference) -- Full command-line flag reference
- [GitHub Actions (Claude Code)](https://code.claude.com/docs/en/github-actions) -- Official GitHub Actions integration
- [claude-code-action Repository](https://github.com/anthropics/claude-code-action) -- Source and examples for the GitHub Action
- [Model Context Protocol](https://modelcontextprotocol.io/introduction) -- MCP specification and SDK
- [Extension Mechanisms Article](claude-code-extension-mechanisms.md) -- Subagents, skills, and MCP architecture overview
- [Workflow Patterns Article](claude-code-workflow-patterns.md) -- Headless mode and parallel work patterns
- [Testing Strategies Article](claude-code-testing-strategies.md) -- Auto-testing with hooks
