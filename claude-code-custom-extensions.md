# Building Custom Subagents & Skills: Extending Claude Code

## Executive Summary

Claude Code's capabilities can be extended through custom subagents (autonomous task executors with isolated context), skills (injected instructions that guide behavior), and plugins (packages that bundle everything together). This article covers how to build each from scratch -- file structures, YAML configuration, tool permissions, model selection, and the architectural patterns that make extensions effective.

| Extension    | What It Is                   | File Location               | When It Runs                  |
| ------------ | ---------------------------- | --------------------------- | ----------------------------- |
| **Subagent** | Isolated AI worker           | `.claude/agents/*.md`       | When Claude delegates a task  |
| **Skill**    | Injected instructions        | `.claude/skills/*/SKILL.md` | Auto-discovered or `/invoked` |
| **Plugin**   | Packaged bundle of all three | Plugin marketplace or local | When plugin is enabled        |

---

## Table of Contents

- [Subagents](#subagents)
  - [What Subagents Are](#what-subagents-are)
  - [File Structure](#subagent-file-structure)
  - [YAML Frontmatter Reference](#subagent-yaml-reference)
  - [System Prompt Body](#system-prompt-body)
  - [Tool Permissions](#tool-permissions)
  - [Model Selection](#model-selection)
  - [Permission Modes](#permission-modes)
  - [Persistent Memory](#persistent-memory)
  - [Hooks in Subagents](#hooks-in-subagents)
  - [Preloading Skills](#preloading-skills)
  - [CLI-Defined Subagents](#cli-defined-subagents)
  - [Foreground vs Background](#foreground-vs-background)
  - [Example: Code Reviewer](#example-code-reviewer)
  - [Example: Test Runner](#example-test-runner)
- [Skills](#skills)
  - [What Skills Are](#what-skills-are)
  - [File Structure](#skill-file-structure)
  - [YAML Frontmatter Reference](#skill-yaml-reference)
  - [Invocation Control](#invocation-control)
  - [Auto-Discovery and Token Cost](#auto-discovery-and-token-cost)
  - [String Substitutions](#string-substitutions)
  - [Dynamic Context Injection](#dynamic-context-injection)
  - [Running Skills in a Subagent](#running-skills-in-a-subagent)
  - [Hooks in Skills](#hooks-in-skills)
  - [Example: Commit Skill](#example-commit-skill)
  - [Example: PR Review Skill](#example-pr-review-skill)
- [The Lens + Reviewer Pattern](#the-lens--reviewer-pattern)
  - [Architecture](#lens-reviewer-architecture)
  - [When to Use Which](#when-to-use-which)
  - [Domains That Fit](#domains-that-fit)
  - [Example: Security Domain](#example-security-domain)
- [Plugins](#plugins)
  - [What Plugins Are](#what-plugins-are)
  - [Directory Structure](#plugin-directory-structure)
  - [The Plugin Manifest](#the-plugin-manifest)
  - [MCP Servers in Plugins](#mcp-servers-in-plugins)
  - [Hooks in Plugins](#hooks-in-plugins)
  - [Plugin Namespacing](#plugin-namespacing)
  - [Testing Locally](#testing-plugins-locally)
  - [Installation and Management](#installation-and-management)
- [Managing Extensions with claudeup](#managing-extensions-with-claudeup)
  - [Commands](#claudeup-commands)
  - [Directory Layout](#directory-layout)
- [Scope and Priority](#scope-and-priority)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [References](#references)

---

## Subagents

### What Subagents Are

A subagent is an isolated AI worker that Claude delegates tasks to. Each subagent gets its own context window, its own system prompt, and a defined set of tools. When Claude spawns a subagent, the main conversation's context is protected -- the subagent does its work, returns a result, and that result is all that enters the main context.

This isolation is the key property: a subagent can read 50 files and analyze thousands of lines of code, and the main conversation only sees the summary.

### Subagent File Structure

Subagents are Markdown files with YAML frontmatter:

```
.claude/agents/
  code-reviewer.md
  test-runner.md
  security-auditor.md
```

Or for personal (cross-project) subagents:

```
~/.claude/agents/
  code-reviewer.md
  research-assistant.md
```

### Subagent YAML Reference

```yaml
---
name: code-reviewer
description: Reviews code for bugs, style issues, and security vulnerabilities.
  Use proactively after code changes.
tools: Read, Glob, Grep, Bash
model: sonnet
maxTurns: 50
permissionMode: default
skills:
  - api-conventions
mcpServers:
  - github
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-command.sh"
memory: user
---
Your system prompt goes here in the Markdown body.
```

**Field reference:**

| Field             | Required | Default   | Description                                         |
| ----------------- | -------- | --------- | --------------------------------------------------- |
| `name`            | Yes      | --        | Unique identifier (lowercase, hyphens)              |
| `description`     | Yes      | --        | When Claude should delegate to this subagent        |
| `tools`           | No       | All tools | Allowlist of tools the subagent can use             |
| `disallowedTools` | No       | None      | Denylist of tools to remove from inherited set      |
| `model`           | No       | `inherit` | `opus`, `sonnet`, `haiku`, or `inherit`             |
| `maxTurns`        | No       | 50        | Maximum agentic turns (API round-trips)             |
| `permissionMode`  | No       | `default` | How tool permissions are handled                    |
| `skills`          | No       | None      | Skills to preload at subagent startup               |
| `mcpServers`      | No       | None      | Named MCP servers available to this subagent        |
| `hooks`           | No       | None      | Lifecycle hooks scoped to this subagent             |
| `memory`          | No       | None      | `user`, `project`, or `local` for persistent memory |

### System Prompt Body

Everything below the `---` frontmatter delimiter becomes the subagent's system prompt. Write it as clear instructions:

```markdown
---
name: code-reviewer
description: Reviews code changes for quality and correctness.
tools: Read, Glob, Grep
model: sonnet
---

You are a code reviewer. Analyze the code changes described in your task.

## Review Checklist

1. Logic errors and edge cases
2. Error handling completeness
3. Security vulnerabilities (injection, auth bypass, data exposure)
4. Performance concerns (N+1 queries, unnecessary allocations)
5. Style consistency with surrounding code

## Output Format

For each issue found:

- **File**: path and line number
- **Severity**: critical / warning / suggestion
- **Issue**: clear description
- **Fix**: recommended change

If no issues found, state that explicitly.
```

### Tool Permissions

**Allowlist** -- the subagent can only use these tools:

```yaml
tools: Read, Grep, Glob, Bash
```

**Denylist** -- the subagent inherits all tools except these:

```yaml
disallowedTools: Write, Edit, Task
```

Use `tools` (allowlist) when the subagent has a narrow job. Use `disallowedTools` (denylist) when it needs most tools but you want to prevent specific actions.

**Restricting subagent tool calls further** -- you can limit which subagents a parent can spawn:

```yaml
tools: Task(worker, researcher), Read, Bash
```

**Disabling specific subagents globally** -- in your settings:

```json
{
  "permissions": {
    "deny": ["Task(Explore)", "Task(my-custom-agent)"]
  }
}
```

### Model Selection

Three ways to control which model a subagent uses, in priority order:

1. **Environment variable** (highest priority): `CLAUDE_CODE_SUBAGENT_MODEL=haiku` -- overrides all subagent model settings
2. **Per-agent YAML**: `model: sonnet` in the frontmatter
3. **Default**: `inherit` -- uses the same model as the main conversation

Use `model: sonnet` or `model: haiku` to reduce costs on subagents that don't need Opus-level reasoning. Research, file searching, and simple analysis work well on Sonnet. Quick formatting checks work on Haiku.

### Permission Modes

| Mode                | Behavior                                 |
| ------------------- | ---------------------------------------- |
| `default`           | Standard permission checking             |
| `acceptEdits`       | Auto-accept file edit/write operations   |
| `dontAsk`           | Auto-deny all permission prompts         |
| `delegate`          | Coordination-only (for agent team leads) |
| `bypassPermissions` | Skip all permission checks               |
| `plan`              | Read-only exploration mode               |

`plan` is useful for research-only subagents. `acceptEdits` is useful for formatting or code generation subagents where you want automated file writes.

### Persistent Memory

The `memory` field gives a subagent a persistent directory that survives across sessions:

| Scope     | Location                             | Use Case                     |
| --------- | ------------------------------------ | ---------------------------- |
| `user`    | `~/.claude/agent-memory/<name>/`     | Cross-project learning       |
| `project` | `.claude/agent-memory/<name>/`       | Project-specific, shareable  |
| `local`   | `.claude/agent-memory-local/<name>/` | Project-specific, gitignored |

When memory is enabled:

- The subagent gets Read/Write/Edit tools automatically
- A `MEMORY.md` file is created and maintained
- The first 200 lines of `MEMORY.md` are injected into the system prompt

### Hooks in Subagents

Hooks defined in subagent frontmatter only fire when that subagent is active:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate-bash.sh"
  PostToolUse:
    - matcher: "Edit|Write"
      hooks:
        - type: command
          command: "./scripts/auto-format.sh"
```

You can also hook into subagent lifecycle events from your project settings:

```json
{
  "hooks": {
    "SubagentStart": [
      {
        "matcher": "code-reviewer",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Code reviewer started' >> ~/.claude/audit.log"
          }
        ]
      }
    ]
  }
}
```

### Preloading Skills

The `skills` field loads skill content into the subagent's context at startup:

```yaml
skills:
  - api-conventions
  - error-handling-patterns
```

This is useful when a subagent should follow specific project conventions. The skill content is injected alongside the subagent's system prompt.

### CLI-Defined Subagents

For one-off or experimental subagents, define them inline via the CLI:

```bash
claude --agents '{
  "quick-reviewer": {
    "description": "Quick code review",
    "prompt": "You review code for obvious issues only.",
    "tools": ["Read", "Grep", "Glob"],
    "model": "haiku"
  }
}'
```

These exist only for the session and are not saved to disk.

### Foreground vs Background

- **Foreground** (default): Blocks the main conversation. Permission prompts pass through to the user.
- **Background**: Runs concurrently. Permissions are pre-approved before launch. Use `Ctrl+B` to background a running subagent.

Disable background execution with: `CLAUDE_CODE_DISABLE_BACKGROUND_TASKS=1`

### Example: Code Reviewer

```yaml
---
name: code-reviewer
description: Reviews code for bugs, logic errors, and style issues.
  Use proactively after implementing features or fixing bugs.
tools: Read, Glob, Grep
model: sonnet
---

You are a senior code reviewer. Analyze the changes described in your task.

## Focus Areas
- Logic errors and unhandled edge cases
- Missing error handling
- Security vulnerabilities
- Performance issues
- Consistency with surrounding code style

## Output
Rate each finding: critical, warning, or suggestion.
Include file path, line number, and a specific fix recommendation.
If no issues found, say so.
```

### Example: Test Runner

```yaml
---
name: test-runner
description: Runs tests and fixes failures. Use after code changes
  to verify correctness.
tools: Read, Glob, Grep, Bash, Edit, Write
model: sonnet
permissionMode: acceptEdits
---

You run tests and fix failures.

## Process
1. Run the project's test suite
2. If all tests pass, report success
3. If tests fail:
   a. Read the failing test to understand what it expects
   b. Read the implementation code
   c. Fix the root cause (not the test)
   d. Re-run tests to verify
4. Repeat until all tests pass

## Rules
- Fix implementation bugs, not tests
- If you can't determine the root cause, report the failure details
- Run the full suite after each fix to check for regressions
```

---

## Skills

### What Skills Are

Skills are sets of instructions that Claude loads into its context. Unlike subagents (which run in isolation), skills inject knowledge directly into the main conversation. They guide how Claude approaches a task without spawning a separate process.

Skills serve two purposes:

- **Knowledge injection**: What to know (coding standards, API conventions, project rules)
- **Workflow injection**: How to work (review checklists, debugging procedures, deployment steps)

### Skill File Structure

Skills are directories containing a `SKILL.md` file:

```
.claude/skills/
  commit/
    SKILL.md
  code-review/
    SKILL.md
    templates/
      review-template.md
  deploy/
    SKILL.md
    scripts/
      pre-deploy-check.sh
```

Or for personal (cross-project) skills:

```
~/.claude/skills/
  golang/
    SKILL.md
  bash/
    SKILL.md
```

### Skill YAML Reference

```yaml
---
name: code-review
description: Structured code review process for pull requests.
  Use when reviewing PRs or after implementing features.
argument-hint: "[pr-number]"
disable-model-invocation: false
user-invocable: true
allowed-tools: Read, Grep, Glob, Bash
model: sonnet
context: fork
agent: Explore
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
          once: true
---
Skill instructions in Markdown here...
```

**Field reference:**

| Field                      | Required | Default        | Description                                    |
| -------------------------- | -------- | -------------- | ---------------------------------------------- |
| `name`                     | No       | Directory name | Unique identifier (lowercase, hyphens, max 64) |
| `description`              | No       | --             | How Claude decides when to use this skill      |
| `argument-hint`            | No       | --             | Autocomplete hint shown in `/` menu            |
| `disable-model-invocation` | No       | `false`        | If `true`, only users can invoke (not Claude)  |
| `user-invocable`           | No       | `true`         | If `false`, hidden from `/` menu               |
| `allowed-tools`            | No       | None           | Tools allowed without permission prompts       |
| `model`                    | No       | --             | Model to use when skill is active              |
| `context`                  | No       | --             | `fork` to run in a subagent context            |
| `agent`                    | No       | --             | Which subagent type for `context: fork`        |
| `hooks`                    | No       | None           | Lifecycle hooks scoped to this skill           |

### Invocation Control

| Configuration              | User Can Invoke | Claude Can Invoke | Token Cost               |
| -------------------------- | --------------- | ----------------- | ------------------------ |
| Default (both true)        | Yes (`/name`)   | Yes               | Description in every msg |
| `disable-model-invocation` | Yes (`/name`)   | No                | None (no catalog entry)  |
| `user-invocable: false`    | No              | Yes               | Description in every msg |

- Skills Claude can invoke have their description loaded every message (~25-100 tokens each)
- Skills only users can invoke (`disable-model-invocation: true`) have zero per-message cost
- Full skill content only loads when the skill is actually invoked

### Auto-Discovery and Token Cost

Claude reads all skill descriptions at session start. The description text is included in every API call so Claude knows which skills are available.

- Each skill description costs ~25-100 tokens per message
- Full skill content loads only on invocation (variable cost)
- Character budget for skill content: 2% of context window (fallback: 16,000 characters)
- Override with: `SLASH_COMMAND_TOOL_CHAR_BUDGET` environment variable

To minimize token overhead: write concise descriptions, disable model invocation for rarely-used skills, and keep skill content focused.

### String Substitutions

| Variable               | Description                        |
| ---------------------- | ---------------------------------- |
| `$ARGUMENTS`           | All arguments passed on invocation |
| `$ARGUMENTS[N]` / `$N` | Specific argument by 0-based index |
| `${CLAUDE_SESSION_ID}` | Current session ID                 |

Example:

```markdown
---
name: fix-issue
description: Fix a GitHub issue
argument-hint: "[issue-number]"
---

Fix GitHub issue $ARGUMENTS:

1. Read the issue details with `gh issue view $ARGUMENTS`
2. Understand the problem
3. Implement the fix
4. Write tests
5. Create a commit referencing the issue
```

User invokes: `/fix-issue 42` -- `$ARGUMENTS` becomes `42`.

### Dynamic Context Injection

The `` !`command` `` syntax executes shell commands and injects their output into skill content before it reaches Claude:

```markdown
---
name: pr-review
description: Review a pull request
argument-hint: "[pr-number]"
context: fork
agent: Explore
allowed-tools: Bash(gh *)
---

## Pull Request Context

!`gh pr view $ARGUMENTS`

## Changed Files

!`gh pr diff $ARGUMENTS --name-only`

## Diff

!`gh pr diff $ARGUMENTS`

Review this PR for:

1. Logic errors
2. Missing tests
3. Security issues
4. Style consistency
```

The shell commands run before the skill content is sent to Claude, so Claude sees the actual PR data, not the commands.

### Running Skills in a Subagent

Set `context: fork` to run the skill in an isolated subagent context:

```yaml
---
name: deep-research
description: Research a topic thoroughly
context: fork
agent: Explore
---

Research $ARGUMENTS:
1. Search the codebase for relevant files
2. Read and analyze all related code
3. Summarize findings with file references
```

This protects the main conversation's context from the potentially large amount of data the research skill reads.

**Two ways skills and subagents interact:**

| Approach                     | System Prompt Source | Task Source         |
| ---------------------------- | -------------------- | ------------------- |
| Skill with `context: fork`   | From agent type      | SKILL.md content    |
| Subagent with `skills` field | Subagent body        | Claude's delegation |

### Hooks in Skills

Skills can define hooks that only fire while the skill is active:

```yaml
hooks:
  PreToolUse:
    - matcher: "Bash"
      hooks:
        - type: command
          command: "./scripts/validate.sh"
          once: true
```

The `once: true` field runs the hook only once per session, even if the skill fires multiple times.

### Example: Commit Skill

```yaml
---
name: commit
description: Create a well-structured git commit
allowed-tools: Bash(git *)
---

## Process
1. Run `git status` to see what's changed
2. Run `git diff --staged` to review staged changes (or `git diff` for unstaged)
3. Analyze the changes and draft a commit message:
   - Start with a type: feat, fix, refactor, test, docs, chore
   - Write a concise subject line (under 72 characters)
   - Add a body explaining *why*, not *what*
4. Stage the appropriate files (be specific, avoid `git add -A`)
5. Create the commit

## Rules
- Never commit .env files or credentials
- Never amend commits unless explicitly asked
- Use conventional commit format
```

### Example: PR Review Skill

```yaml
---
name: review-pr
description: Review a GitHub pull request
argument-hint: "[pr-number]"
context: fork
agent: Explore
allowed-tools: Bash(gh *), Read, Grep, Glob
---

## PR Data
!`gh pr view $ARGUMENTS --json title,body,additions,deletions,changedFiles`

## Changed Files
!`gh pr diff $ARGUMENTS --name-only`

## Review Process
1. Understand the PR's purpose from title and description
2. Read each changed file
3. Check for:
   - Logic errors and edge cases
   - Missing error handling
   - Security vulnerabilities
   - Test coverage for new code
   - Style consistency
4. Summarize findings with file:line references
```

---

## The Lens + Reviewer Pattern

### Lens Reviewer Architecture

For any domain (security, performance, accessibility), create two complementary components:

```
                    ┌─────────────────────────┐
                    │   Main Conversation      │
                    │                          │
  Auto-activates   │   ┌─────────────────┐    │
  during coding    │   │  Security Lens   │    │ Lightweight
  ─────────────────┼──>│  (Skill)         │    │ awareness
                   │   └─────────────────┘    │
                   │                          │
  Explicit         │   ┌─────────────────┐    │
  delegation       │   │  Security Audit  │───┼──> Isolated
  ─────────────────┼──>│  (Subagent)      │    │   deep analysis
                   │   └─────────────────┘    │
                   └─────────────────────────┘
```

- The **lens** (skill) injects lightweight checklists into the main context. It auto-activates when Claude detects relevant work. Low token cost, always present.
- The **reviewer** (subagent) performs thorough analysis in isolation. It reads many files, traces data flows, and returns a structured report. Higher cost, on-demand.

### When to Use Which

| Situation                | Use Lens (Skill) | Use Reviewer (Subagent) |
| ------------------------ | ---------------- | ----------------------- |
| Writing code             | Yes              | --                      |
| Quick self-check         | Yes              | --                      |
| Reviewing a PR           | --               | Yes                     |
| Pre-merge audit          | --               | Yes                     |
| Understanding a codebase | --               | Yes                     |

### Domains That Fit

| Domain        | Lens (Skill)       | Reviewer (Subagent)      |
| ------------- | ------------------ | ------------------------ |
| Security      | `security-lens`    | `security-auditor`       |
| Performance   | `perf-awareness`   | `perf-analyzer`          |
| Accessibility | `a11y-checklist`   | `a11y-auditor`           |
| Documentation | `docs-standards`   | `docs-reviewer`          |
| Testing       | `test-guidance`    | `test-coverage-analyzer` |
| Code review   | `code-review-lens` | `code-reviewer`          |

### Example: Security Domain

**Lens** (`.claude/skills/security-lens/SKILL.md`):

```yaml
---
name: security-lens
description: Apply security awareness during code review and implementation.
  Catches common vulnerabilities without requiring a full audit.
---

When reviewing or writing code, check for:

## Input Handling
- [ ] User input validated before use
- [ ] SQL queries use parameterized statements
- [ ] HTML output properly escaped

## Secrets
- [ ] No hardcoded credentials or API keys
- [ ] Secrets loaded from environment variables or vault

## Authentication
- [ ] Auth checks present on protected routes
- [ ] Session tokens have expiry

## Data
- [ ] Sensitive data not logged
- [ ] PII not exposed in error messages
```

**Reviewer** (`.claude/agents/security-auditor.md`):

```yaml
---
name: security-auditor
description: Thorough security audit. Use for pre-merge reviews
  or when security concerns are raised.
tools: Read, Grep, Glob, Bash
model: sonnet
---

You perform thorough security audits.

## Audit Process
1. Map the attack surface: entry points, data flows, trust boundaries
2. Trace all user input from entry to storage/output
3. Check for OWASP Top 10 vulnerabilities
4. Review authentication and authorization logic
5. Check dependency versions for known CVEs (`npm audit` / `go mod tidy`)
6. Verify secrets management

## Output Format
For each finding:
- **Severity**: Critical / High / Medium / Low
- **Category**: OWASP category or CWE ID
- **Location**: file:line
- **Description**: What the vulnerability is
- **Impact**: What an attacker could do
- **Recommendation**: Specific fix

Summarize with a risk rating: Pass / Conditional Pass / Fail.
```

---

## Plugins

### What Plugins Are

Plugins are packages that bundle subagents, skills, hooks, MCP servers, and other extensions into a single installable unit. They are the distribution mechanism for sharing extensions.

### Plugin Directory Structure

```
my-plugin/
  .claude-plugin/
    plugin.json           # Plugin manifest (optional but recommended)
  agents/                 # Subagent definitions
    security-reviewer.md
  skills/                 # Skill directories
    code-review/
      SKILL.md
    pdf-processor/
      SKILL.md
      scripts/
  hooks/                  # Hook configuration
    hooks.json
  .mcp.json               # MCP server definitions
  scripts/                # Hook and utility scripts
    security-scan.sh
```

Components live at the plugin root, not inside `.claude-plugin/`.

### The Plugin Manifest

The `plugin.json` file describes the plugin and can override default component locations:

```json
{
  "name": "my-plugin",
  "version": "1.0.0",
  "description": "What this plugin does",
  "author": {
    "name": "Author Name",
    "url": "https://github.com/author"
  },
  "repository": "https://github.com/author/plugin",
  "license": "MIT",
  "keywords": ["security", "code-review"],
  "agents": "./agents/",
  "skills": "./skills/",
  "hooks": "./hooks/hooks.json",
  "mcpServers": "./.mcp.json"
}
```

Only `name` is required. Other fields are optional. If paths are omitted, Claude Code auto-discovers components in their default locations within the plugin directory.

### MCP Servers in Plugins

Define MCP servers in `.mcp.json` at the plugin root:

```json
{
  "mcpServers": {
    "plugin-database": {
      "command": "${CLAUDE_PLUGIN_ROOT}/servers/db-server",
      "args": ["--config", "${CLAUDE_PLUGIN_ROOT}/config.json"],
      "env": {
        "DB_PATH": "${CLAUDE_PLUGIN_ROOT}/data"
      }
    }
  }
}
```

`${CLAUDE_PLUGIN_ROOT}` resolves to the plugin's absolute installation path regardless of where it's installed.

### Hooks in Plugins

Define hooks in `hooks/hooks.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "hooks": [
          {
            "type": "command",
            "command": "${CLAUDE_PLUGIN_ROOT}/scripts/format-code.sh"
          }
        ]
      }
    ]
  }
}
```

### Plugin Namespacing

Plugin skills are namespaced: `plugin-name:skill-name`. This prevents conflicts between plugins and between plugins and local skills. Users invoke plugin skills as `/plugin-name:skill-name`.

### Testing Plugins Locally

Load a local plugin directory for testing:

```bash
claude --plugin-dir ./my-plugin
claude --plugin-dir ./plugin-one --plugin-dir ./plugin-two
```

### Installation and Management

```bash
# Install from marketplace
claude plugin install my-plugin@marketplace --scope project

# Install with specific scope
claude plugin install my-plugin@marketplace --scope user

# Enable/disable
claude plugin enable my-plugin
claude plugin disable my-plugin

# Update
claude plugin update my-plugin

# Uninstall
claude plugin uninstall my-plugin@marketplace
```

Or toggle plugins in `settings.json`:

```json
{
  "enabledPlugins": {
    "my-plugin@marketplace": true,
    "other-plugin@author": false
  }
}
```

---

## Managing Extensions with claudeup

`claudeup local` is a tool for managing local extensions (personal skills, agents, hooks, rules, and output styles).

### claudeup Commands

```bash
# List all items and their enabled status
claudeup local list

# Enable specific items
claudeup local enable skills golang bash
claudeup local enable agents code-reviewer

# Disable specific items
claudeup local disable skills vercel-react-best-practices

# Wildcards
claudeup local enable skills gsd-*

# Install from external path
claudeup local install skills /path/to/my-skill

# View item contents
claudeup local view skills golang
```

**Categories:** agents, commands, skills, hooks, rules, output-styles

### Directory Layout

Items live in the library directory. Enablement works via symlinks:

```
~/.claude/.library/          # All available items
  skills/
    golang/SKILL.md
    bash/SKILL.md
    web-design/SKILL.md
  agents/
    code-reviewer.md
  hooks/
    ...

~/.claude/skills/            # Symlinks to enabled items
  golang -> ../.library/skills/golang/
  bash -> ../.library/skills/bash/

~/.claude/agents/            # Symlinks to enabled agents
  code-reviewer.md -> ../.library/agents/code-reviewer.md
```

`claudeup local enable skills golang` creates the symlink. `claudeup local disable skills golang` removes it. The `.library/` directory is the source of truth; `~/.claude/skills/` and `~/.claude/agents/` are the active set.

---

## Scope and Priority

When multiple scopes define the same extension, priority resolves conflicts:

### Subagents

| Source              | Priority    | Scope                |
| ------------------- | ----------- | -------------------- |
| `--agents` CLI flag | 1 (highest) | Session only         |
| `.claude/agents/`   | 2           | Project              |
| `~/.claude/agents/` | 3           | User (all projects)  |
| Plugin `agents/`    | 4 (lowest)  | Where plugin enabled |

### Skills

| Source              | Priority    | Scope                |
| ------------------- | ----------- | -------------------- |
| Enterprise          | 1 (highest) | Organization         |
| `~/.claude/skills/` | 2           | User (all projects)  |
| `.claude/skills/`   | 3           | Project              |
| Plugin `skills/`    | 4 (lowest)  | Where plugin enabled |

Plugin skills are namespaced (`plugin:skill`) and don't actually conflict with local skills.

### Permission Rules

You can restrict which skills and subagents are available:

```json
{
  "permissions": {
    "allow": ["Skill(commit)", "Task(code-reviewer)"],
    "deny": ["Skill(deploy *)", "Task(Explore)"]
  }
}
```

---

## Best Practices

1. **Start with a skill, graduate to a subagent.** If you find a skill's instructions insufficient because the task needs multi-file investigation, convert it to a subagent. Don't start with a subagent for simple guidance.

2. **Write concise descriptions.** The description field is loaded on every message. One or two sentences are enough. Save detailed instructions for the skill body or subagent system prompt.

3. **Use the lens + reviewer pattern for domain coverage.** A lightweight skill for awareness during coding, plus a thorough subagent for explicit audits, covers most domains well.

4. **Set `model: sonnet` on subagents that don't need Opus.** File searching, code review, and test running work well on Sonnet at 40% less cost. Reserve Opus for architecture and complex reasoning.

5. **Use `context: fork` for skills that read lots of data.** PR reviews, research tasks, and codebase exploration generate large amounts of context. Forking protects the main conversation.

6. **Test extensions with `--plugin-dir`.** Load your plugin locally and verify all components work before publishing.

7. **Use `disable-model-invocation: true` for rarely-used skills.** This removes them from the per-message catalog, saving tokens.

8. **Keep skill content under the character budget.** Default is 2% of context window (~4,000 characters for 200K context). Skills that exceed this get truncated.

9. **Scope extensions appropriately.** Personal preferences (formatting, notifications) go in `~/.claude/`. Team conventions (code review checklists, API standards) go in `.claude/` and get committed.

10. **Use `CLAUDE_CODE_SUBAGENT_MODEL` for cost control.** Set it to `haiku` when doing bulk operations that spawn many subagents, then unset it for normal work.

---

## Anti-Patterns

1. **Subagents for simple guidance.** If the task is "follow these coding standards," that's a skill. Subagents add overhead (context switching, API calls) that's wasted on simple instruction injection.

2. **Skills that try to be autonomous.** Skills inject knowledge but don't have isolated execution. If your skill needs to read 20 files and make decisions, it should be a subagent (or use `context: fork`).

3. **Overly broad descriptions.** A description like "use this for anything code-related" causes Claude to invoke the skill/subagent on nearly every task, wasting tokens and time.

4. **Large system prompts on Haiku subagents.** Haiku is fast and cheap but has limited instruction-following for complex prompts. Keep Haiku subagent prompts short and focused.

5. **Preloading many skills into a subagent.** Each preloaded skill adds to the subagent's system prompt. Preload only what's directly relevant.

6. **Plugin hooks without `${CLAUDE_PLUGIN_ROOT}`.** Hardcoded paths break when the plugin is installed in a different location. Always use the variable.

7. **Forgetting `hookEventName` in PreToolUse JSON.** The `hookSpecificOutput` object must include `"hookEventName": "PreToolUse"` or the response fails to parse. This is a common bug.

8. **Duplicating content between skills and CLAUDE.md.** If a rule belongs in CLAUDE.md (applies always), don't also put it in a skill. If it only applies during a specific workflow, put it in a skill only.

---

## References

- [Official Subagents Reference](https://code.claude.com/docs/en/sub-agents) -- complete YAML schema, tool permissions, model selection
- [Official Skills Reference](https://code.claude.com/docs/en/skills) -- skill structure, frontmatter fields, invocation control
- [Official Plugins Reference](https://code.claude.com/docs/en/plugins-reference) -- plugin manifest, directory structure, MCP integration
- [Official Plugins Guide](https://code.claude.com/docs/en/plugins) -- installation, scoping, testing
- [Extension Mechanisms Article](claude-code-extension-mechanisms.md) -- architectural overview of subagents, skills, and MCP servers
- [Token Optimization Article](claude-code-token-optimization.md) -- token cost of skills and subagent descriptions
