---
title: "Custom Hooks Cookbook: Practical Recipes for Automating Claude Code"
linkTitle: "Hooks Cookbook"
weight: 3
---

# Custom Hooks Cookbook: Practical Recipes for Automating Claude Code

## Executive Summary

Hooks let you run code at specific points in Claude Code's lifecycle -- before a tool runs, after a file is edited, when a session starts, when Claude finishes responding. This cookbook provides copy-paste-ready recipes for the most common use cases: auto-formatting, command safety, test gates, notifications, logging, and context injection. Each recipe includes the hook configuration, the script, and notes on gotchas.

| Category            | Example Recipes                                       | Hook Events Used                               |
| ------------------- | ----------------------------------------------------- | ---------------------------------------------- |
| **Code quality**    | Auto-format, lint on save, type check                 | PostToolUse (Edit\|Write)                      |
| **Safety**          | Block dangerous commands, protect files, branch guard | PreToolUse (Bash, Edit\|Write)                 |
| **Verification**    | Test gates, build checks, stop-until-passing          | PostToolUse, Stop, TaskCompleted               |
| **Notifications**   | Desktop alerts, Slack, TTS                            | Notification                                   |
| **Logging**         | Command audit, session tracking, debug wrapper        | PostToolUse, SessionStart                      |
| **Context**         | Inject reminders, load state, persist env vars        | SessionStart, UserPromptSubmit                 |
| **Quality gates**   | Block stopping until tasks complete, auto code review | Stop, SubagentStop, TaskCompleted, PostToolUse |
| **Display control** | Redact displayed output, replace tool results         | MessageDisplay, PostToolUse                    |

## Table of Contents

- [Custom Hooks Cookbook: Practical Recipes for Automating Claude Code](#custom-hooks-cookbook-practical-recipes-for-automating-claude-code)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [Hook Fundamentals](#hook-fundamentals)
    - [Where Hooks Live](#where-hooks-live)
    - [Hook Types](#hook-types)
    - [Exit Code Protocol](#exit-code-protocol)
    - [JSON Output Format](#json-output-format)
    - [Environment Variables](#environment-variables)
  - [Event Reference](#event-reference)
    - [Complete Event Table](#complete-event-table)
    - [Matcher Syntax](#matcher-syntax)
    - [Tool Input Schemas](#tool-input-schemas)
    - [Event Input Schemas](#event-input-schemas)
  - [Recipes: Code Quality](#recipes-code-quality)
    - [Auto-Format with Prettier](#auto-format-with-prettier)
    - [Auto-Format Go Files](#auto-format-go-files)
    - [Run Ruff on Python Files](#run-ruff-on-python-files)
    - [ESLint on Save](#eslint-on-save)
  - [Recipes: Safety](#recipes-safety)
    - [Block Dangerous Commands](#block-dangerous-commands)
    - [Protect Sensitive Files](#protect-sensitive-files)
    - [Block Pushes to Protected Branches](#block-pushes-to-protected-branches)
    - [Prevent Credential Leaks in Commands](#prevent-credential-leaks-in-commands)
  - [Recipes: Verification](#recipes-verification)
    - [Run Tests After File Changes](#run-tests-after-file-changes)
    - [Stop Hook Test Gate](#stop-hook-test-gate)
    - [Task Completion Test Gate](#task-completion-test-gate)
    - [Build Verification Gate](#build-verification-gate)
  - [Recipes: Notifications](#recipes-notifications)
    - [macOS Desktop Notification](#macos-desktop-notification)
    - [Linux Desktop Notification](#linux-desktop-notification)
    - [Slack Webhook Notification](#slack-webhook-notification)
  - [Recipes: Logging and Auditing](#recipes-logging-and-auditing)
    - [Log Every Bash Command](#log-every-bash-command)
    - [Session Start Logger](#session-start-logger)
    - [Debug Wrapper Script](#debug-wrapper-script)
  - [Recipes: Context Injection](#recipes-context-injection)
    - [Inject Reminders After Compaction](#inject-reminders-after-compaction)
    - [Load Project State on Session Start](#load-project-state-on-session-start)
    - [Inject Sprint Context With Every Prompt](#inject-sprint-context-with-every-prompt)
    - [Persist Environment Variables](#persist-environment-variables)
  - [Recipes: Quality Gates](#recipes-quality-gates)
    - [Prompt-Based Stop Gate](#prompt-based-stop-gate)
    - [Agent-Based Verification Gate](#agent-based-verification-gate)
    - [Stop Hook Code Review](#stop-hook-code-review)
  - [Recipes: Error Recovery](#recipes-error-recovery)
    - [Alert on API Failures (StopFailure)](#alert-on-api-failures-stopfailure)
    - [Log API Errors to File (StopFailure)](#log-api-errors-to-file-stopfailure)
  - [Recipes: Permission Auditing](#recipes-permission-auditing)
    - [Log Denied Tool Calls (PermissionDenied)](#log-denied-tool-calls-permissiondenied)
  - [Recipes: Context Recovery](#recipes-context-recovery)
    - [Inject Context After Compaction (PostCompact)](#inject-context-after-compaction-postcompact)
  - [Recipes: Repo Setup](#recipes-repo-setup)
    - [Run Setup Scripts on Init (Setup)](#run-setup-scripts-on-init-setup)
  - [Recipes: Task Management](#recipes-task-management)
    - [Notify on Task Creation (TaskCreated)](#notify-on-task-creation-taskcreated)
  - [Recipes: MCP Elicitation](#recipes-mcp-elicitation)
    - [Auto-Approve Trusted MCP Servers (Elicitation)](#auto-approve-trusted-mcp-servers-elicitation)
    - [Audit MCP Responses (ElicitationResult)](#audit-mcp-responses-elicitationresult)
  - [Recipes: Configuration Monitoring](#recipes-configuration-monitoring)
    - [Block Unauthorized Settings Changes (ConfigChange)](#block-unauthorized-settings-changes-configchange)
    - [Log All Configuration Changes (ConfigChange)](#log-all-configuration-changes-configchange)
  - [Recipes: Instruction Auditing](#recipes-instruction-auditing)
    - [Log Instruction Loading (InstructionsLoaded)](#log-instruction-loading-instructionsloaded)
  - [Recipes: File System Monitoring](#recipes-file-system-monitoring)
    - [Auto-Source Environment on Directory Change (CwdChanged)](#auto-source-environment-on-directory-change-cwdchanged)
    - [Hot-Reload on File Changes (FileChanged)](#hot-reload-on-file-changes-filechanged)
  - [Recipes: Worktree Management](#recipes-worktree-management)
    - [Custom Worktree Creation (WorktreeCreate)](#custom-worktree-creation-worktreecreate)
    - [Clean Up Worktrees (WorktreeRemove)](#clean-up-worktrees-worktreeremove)
  - [Combining Hooks](#combining-hooks)
    - [A Complete Safety Setup](#a-complete-safety-setup)
    - [A Complete CI-Style Setup](#a-complete-ci-style-setup)
  - [Gotchas and Debugging](#gotchas-and-debugging)
    - [The Stop Hook Infinite Loop](#the-stop-hook-infinite-loop)
    - [Shell Profile Pollution](#shell-profile-pollution)
    - [Hook Snapshot at Startup](#hook-snapshot-at-startup)
    - [Async Hooks Cannot Block](#async-hooks-cannot-block)
    - [Exit 2 vs JSON](#exit-2-vs-json)
    - [PermissionRequest Hooks Don't Fire in Headless Mode](#permissionrequest-hooks-dont-fire-in-headless-mode)
    - [PostToolUse Cannot Undo](#posttooluse-cannot-undo)
    - [The hookEventName Bug](#the-hookeventname-bug)
    - [Debugging Commands](#debugging-commands)
  - [Best Practices](#best-practices)
  - [Anti-Patterns](#anti-patterns)
  - [References](#references)

## Hook Fundamentals

### Where Hooks Live

Hooks are configured in JSON settings files. Three scopes are available:

| Location                      | Scope               | Committable? |
| ----------------------------- | ------------------- | ------------ |
| `~/.claude/settings.json`     | All your projects   | No           |
| `.claude/settings.json`       | This project (team) | Yes          |
| `.claude/settings.local.json` | This project (you)  | No           |

Hooks from all scopes merge together. Plugins can also register hooks via `hooks/hooks.json` in their package.

### Hook Types

**Command hooks** run a shell command. The script receives JSON on stdin and communicates via exit codes and stdout.

```json
{
  "type": "command",
  "command": "/path/to/script.sh",
  "timeout": 600,
  "async": false
}
```

Add an `args` array to run in **exec form**: `command` is resolved as an executable and spawned directly with `args` as its argument vector, with no shell. Nothing is tokenized, so pipes, `&&`, globs, and quoting do not apply. Claude Code still substitutes its own path placeholders such as `${CLAUDE_PLUGIN_ROOT}` and `${CLAUDE_PROJECT_DIR}`, but there is no shell expansion -- arbitrary `$VAR`, `$(...)`, and backticks are passed literally. Use exec form to avoid shell-quoting bugs. On Windows, `command` must resolve to a real `.exe`; `.cmd`/`.bat` shims still need shell form.

```json
{
  "type": "command",
  "command": "node",
  "args": ["${CLAUDE_PLUGIN_ROOT}/scripts/format.js", "--fix"]
}
```

**Prompt hooks** send a single-turn prompt to a Claude model (Haiku by default). The model returns `{"ok": true/false, "reason": "..."}`.

```json
{
  "type": "prompt",
  "prompt": "Evaluate whether the task is complete. Context: $ARGUMENTS",
  "model": "haiku",
  "timeout": 30
}
```

The `$ARGUMENTS` placeholder is replaced with the hook's JSON input data. Prompt hooks are supported on PreToolUse, PostToolUse, PostToolUseFailure, PermissionRequest, UserPromptSubmit, Stop, SubagentStop, and TaskCompleted.

**Agent hooks** spawn a subagent with multi-turn tool access (Read, Grep, Glob -- up to 50 turns).

```json
{
  "type": "agent",
  "prompt": "Verify all unit tests pass. Run the test suite. $ARGUMENTS",
  "timeout": 120
}
```

Agent hooks are useful when verification requires inspecting files or running commands beyond evaluating the input data.

**HTTP hooks** POST the hook's JSON input to a URL and expect a JSON response. Header values support `$VAR_NAME` / `${VAR_NAME}` env var interpolation for secrets -- only variables listed in `allowedEnvVars` are resolved; all others become empty strings.

```json
{
  "type": "http",
  "url": "https://hooks.example.com/claude/pre-tool",
  "headers": {
    "Authorization": "Bearer $HOOK_TOKEN"
  },
  "allowedEnvVars": ["HOOK_TOKEN"],
  "timeout": 30
}
```

HTTP hooks use HTTP status codes instead of exit codes: 2xx is success, anything else is a non-blocking error. The response body must be JSON matching the same schema as command hook stdout (e.g., `{"decision": "block", "reason": "..."}` or `{}`). An empty body is treated as `{}`. The default timeout is 10 minutes. Admins can restrict allowed URLs via `allowedHttpHookUrls` in settings, using `*` wildcards (same semantics as `allowedMcpServers`). When sandboxing is enabled, requests route through the sandbox network proxy. An SSRF guard blocks requests to private/link-local IP ranges (but allows loopback).

**MCP tool hooks** call a tool on a configured MCP server directly, with no shell or script.

```json
{
  "type": "mcp_tool",
  "server": "github",
  "tool": "create_issue",
  "input": { "title": "Hook fired for ${tool_input.file_path}" },
  "timeout": 600
}
```

String values in `input` support `${path}` substitution from the hook's JSON input (e.g., `${tool_input.file_path}`). The tool's text result is handled like command-hook stdout: parsed as a decision if it is valid JSON, otherwise shown as plain text. MCP tool hooks work on every event once MCP servers connect, except `SessionStart` and `Setup`, which fire before servers finish connecting.

### Exit Code Protocol

| Exit Code | Meaning            | Behavior                                                       |
| --------- | ------------------ | -------------------------------------------------------------- |
| **0**     | Success            | Stdout parsed for JSON. For SessionStart, stdout is context    |
| **2**     | Blocking error     | Stderr fed to Claude. Blocks the action (if event supports it) |
| **Other** | Non-blocking error | Stderr shown in verbose mode (Ctrl+O). Execution continues     |

Not every event supports blocking. The events that respond to exit 2:

- **Can block:** PreToolUse, PermissionRequest, UserPromptSubmit, Stop, SubagentStop, TeammateIdle, TaskCreated, TaskCompleted, Elicitation, ElicitationResult, PreCompact, ConfigChange
- **Cannot block:** PostToolUse, PostToolUseFailure, Notification, SubagentStart, SessionStart, SessionEnd, PostCompact, InstructionsLoaded, CwdChanged, FileChanged, WorktreeRemove, MessageDisplay
- **Fire-and-forget:** StopFailure (all exit codes ignored)
- **Special protocol:** Setup (blocking errors ignored), WorktreeCreate (stdout = worktree path), PermissionDenied (can signal retry)

### JSON Output Format

When a hook exits 0 and prints JSON to stdout, these universal fields are available:

| Field              | Default | Description                                                                                          |
| ------------------ | ------- | ---------------------------------------------------------------------------------------------------- |
| `continue`         | `true`  | If `false`, Claude stops the entire session                                                          |
| `stopReason`       | --      | Message shown to user when `continue` is `false`                                                     |
| `suppressOutput`   | `false` | If `true`, hides stdout from verbose mode                                                            |
| `systemMessage`    | --      | Warning message shown to user                                                                        |
| `terminalSequence` | --      | Allowlisted terminal escape sequence to emit (notifications, window title, bell); requires v2.1.141+ |

`terminalSequence` replaces writing to `/dev/tty`, which hooks cannot access. Allowlisted sequences include OSC 0/1/2 (window and icon titles), OSC 9 (iTerm2, Windows Terminal, WezTerm notifications), OSC 99 (Kitty), OSC 777 (Ghostty, Warp), and a bare BEL. Clipboard (OSC 52), hyperlink (OSC 8), and cursor/color sequences are rejected.

For PreToolUse specifically, structured decisions go in `hookSpecificOutput`:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "deny",
    "permissionDecisionReason": "This command is not allowed"
  }
}
```

The three permission decisions: `allow` (skip permission prompt), `deny` (block with reason), `ask` (show permission prompt with additional context).

Other events carry their own `hookSpecificOutput` keys. Each key requires the matching `hookEventName`:

| Event              | Key                 | Effect                                                                                                            |
| ------------------ | ------------------- | ----------------------------------------------------------------------------------------------------------------- |
| SessionStart       | `additionalContext` | Context string added before the first prompt                                                                      |
| SessionStart       | `sessionTitle`      | Sets the session title (only on `startup` or `resume`; ignored on clear/compact)                                  |
| SessionStart       | `reloadSkills`      | `true` re-scans skill directories after hooks run, so skills installed by the hook are available the same session |
| Stop, SubagentStop | `additionalContext` | Feedback that continues the conversation without the blocking-error label of exit 2                               |
| PostToolUse        | `updatedToolOutput` | Replaces the tool's result (redact, sanitize, or reformat after a successful call)                                |
| MessageDisplay     | `displayContent`    | Replaces the assistant text shown on screen. Display-only: the transcript and what Claude sees keep the original  |

### Environment Variables

| Variable             | Available In       | Description                                                                                                            |
| -------------------- | ------------------ | ---------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE_PROJECT_DIR` | All hooks          | Project root directory                                                                                                 |
| `CLAUDE_PLUGIN_ROOT` | Plugin hooks       | Plugin package root                                                                                                    |
| `CLAUDE_CODE_REMOTE` | All hooks          | `"true"` in remote web environments                                                                                    |
| `CLAUDE_ENV_FILE`    | SessionStart       | Path to file for persisting environment variables                                                                      |
| `CLAUDE_EFFORT`      | Tool-context hooks | Active effort level (`low`/`medium`/`high`/`xhigh`/`max`) when the model supports effort; ultracode reports as `xhigh` |

The same value is available as the `effort.level` JSON input field on tool-context events (PreToolUse, PostToolUse, Stop, SubagentStop). Both reflect the downgraded level when the request exceeds what the model supports.

## Event Reference

### Complete Event Table

28 hook events are defined:

```text
Session lifecycle:
  Setup (init/maintenance) ──> SessionStart ──> [conversation] ──> SessionEnd
                                                      │
Conversation flow:                                    │
  UserPromptSubmit ──> PreToolUse ──> [tool runs] ──> PostToolUse
                           │                              │
                           │ (if blocked)           PostToolUseFailure
                           │
                     PermissionRequest ──> (if denied) PermissionDenied

  MessageDisplay (assistant text about to render on screen)
                           │
Completion events:         │
  Stop (Claude finishes) ──┘
  StopFailure (API error ends the turn)
  SubagentStart / SubagentStop
  TeammateIdle / TaskCreated / TaskCompleted

Context management:
  PreCompact ──> [compaction runs] ──> PostCompact
  InstructionsLoaded (CLAUDE.md / rules loaded)
  ConfigChange (settings file modified)

File system:
  CwdChanged (working directory changes)
  FileChanged (watched file modified)

MCP elicitation:
  Elicitation (server requests input) ──> ElicitationResult (user responds)

Worktree management:
  WorktreeCreate / WorktreeRemove

Other:
  Notification (permission_prompt, idle_prompt, etc.)
```

| Event              | Fires When                                  | Can Block?  | Matcher Filters                                                                                                         |
| ------------------ | ------------------------------------------- | ----------- | ----------------------------------------------------------------------------------------------------------------------- |
| Setup              | Repo setup during init or maintenance       | No          | init, maintenance                                                                                                       |
| SessionStart       | Session begins or resumes                   | No          | startup, resume, clear, compact                                                                                         |
| UserPromptSubmit   | User submits a prompt                       | Yes         | (none -- always fires)                                                                                                  |
| PreToolUse         | Before a tool call                          | Yes         | Tool name                                                                                                               |
| PermissionRequest  | Permission dialog appears                   | Yes         | Tool name                                                                                                               |
| PermissionDenied   | Auto mode classifier denies a tool call     | No\*        | Tool name                                                                                                               |
| PostToolUse        | After a tool call succeeds                  | No          | Tool name                                                                                                               |
| PostToolUseFailure | After a tool call fails                     | No          | Tool name                                                                                                               |
| Notification       | Claude sends a notification                 | No          | permission_prompt, idle_prompt, auth_success, elicitation_dialog, elicitation_complete, elicitation_response            |
| SubagentStart      | Subagent is spawned                         | No          | Agent type                                                                                                              |
| SubagentStop       | Subagent finishes                           | Yes         | Agent type                                                                                                              |
| Stop               | Claude finishes responding                  | Yes         | (none -- always fires)                                                                                                  |
| StopFailure        | API error ends the turn                     | No          | Error type: rate_limit, authentication_failed, billing_error, invalid_request, server_error, max_output_tokens, unknown |
| TeammateIdle       | Agent team member going idle                | Yes         | (none -- always fires)                                                                                                  |
| TaskCreated        | Task is being created                       | Yes         | (none -- always fires)                                                                                                  |
| TaskCompleted      | Task marked as completed                    | Yes         | (none -- always fires)                                                                                                  |
| Elicitation        | MCP server requests user input              | Yes         | MCP server name                                                                                                         |
| ElicitationResult  | User responds to MCP elicitation            | Yes         | MCP server name                                                                                                         |
| PreCompact         | Before context compaction                   | Yes         | manual, auto                                                                                                            |
| PostCompact        | After context compaction                    | No          | manual, auto                                                                                                            |
| ConfigChange       | Settings file changes during session        | Yes         | user_settings, project_settings, local_settings, policy_settings, skills                                                |
| InstructionsLoaded | CLAUDE.md or rule file loaded               | No          | session_start, nested_traversal, path_glob_match, include, compact                                                      |
| CwdChanged         | Working directory changes                   | No          | (none -- always fires)                                                                                                  |
| FileChanged        | Watched file is modified, added, or deleted | No          | File name pattern                                                                                                       |
| WorktreeCreate     | Isolated worktree is created                | Special\*\* | (none -- always fires)                                                                                                  |
| WorktreeRemove     | Worktree is removed                         | No          | (none -- always fires)                                                                                                  |
| SessionEnd         | Session terminates                          | No          | clear, logout, prompt_input_exit, other                                                                                 |
| MessageDisplay     | Assistant text is about to render on screen | No          | (none -- always fires)                                                                                                  |

\* PermissionDenied hooks can return `{"hookSpecificOutput":{"hookEventName":"PermissionDenied","retry":true}}` to signal the model may retry the tool call.

\*\* WorktreeCreate hooks must print the absolute path to the created worktree directory on stdout. This is not a blocking mechanism but a required protocol.

### Matcher Syntax

Matchers filter which events trigger a hook. They use regex-style patterns:

| Pattern              | Matches                              |
| -------------------- | ------------------------------------ |
| `"Bash"`             | Bash tool only                       |
| `"Edit\|Write"`      | Edit or Write tools                  |
| `""` or omitted      | Everything (wildcard)                |
| `"Notebook.*"`       | Anything starting with Notebook      |
| `"mcp__github__.*"`  | All tools from the GitHub MCP server |
| `"mcp__.*__write.*"` | Any write tool from any MCP server   |

Matchers are **case-sensitive**: `"bash"` does not match the `Bash` tool.

### Tool Input Schemas

When writing PreToolUse or PostToolUse hooks, the `tool_input` field varies by tool:

| Tool      | Key Fields in `tool_input`                               |
| --------- | -------------------------------------------------------- |
| **Bash**  | `command`, `description`, `timeout`, `run_in_background` |
| **Write** | `file_path`, `content`                                   |
| **Edit**  | `file_path`, `old_string`, `new_string`, `replace_all`   |
| **Read**  | `file_path`, `offset`, `limit`                           |
| **Glob**  | `pattern`, `path`                                        |
| **Grep**  | `pattern`, `path`, `glob`, `output_mode`                 |
| **Task**  | `prompt`, `description`, `subagent_type`, `model`        |

### Event Input Schemas

Every hook receives a base payload (`session_id`, `transcript_path`, `cwd`, `permission_mode`, `agent_id`, `agent_type`) plus event-specific fields. The table below documents the event-specific fields only.

| Event                           | Input Fields                                                                                                                                                                                                                                 | Exit Code Behavior                                                                                                            |
| ------------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| Setup                           | `trigger` (`init` or `maintenance`)                                                                                                                                                                                                          | 0: stdout shown to Claude. Blocking errors ignored.                                                                           |
| StopFailure                     | `error`, `error_details` (optional), `last_assistant_message` (optional)                                                                                                                                                                     | Fire-and-forget -- all exit codes ignored.                                                                                    |
| PermissionDenied                | `tool_name`, `tool_input`, `tool_use_id`, `reason`                                                                                                                                                                                           | 0: stdout shown in transcript mode. hookSpecificOutput can signal `retry: true`.                                              |
| PostCompact                     | `trigger` (`manual` or `auto`), `compact_summary`                                                                                                                                                                                            | 0: stdout shown to user. Other: stderr shown to user.                                                                         |
| TaskCreated                     | `task_id`, `task_subject`, `task_description` (optional), `teammate_name` (optional), `team_name` (optional)                                                                                                                                 | 0: silent. 2: stderr shown to model, task creation blocked. Other: stderr to user.                                            |
| Elicitation                     | `mcp_server_name`, `message`, `mode` (`form` or `url`, optional), `url` (optional), `elicitation_id` (optional), `requested_schema` (optional)                                                                                               | 0: use hookSpecificOutput (action: accept/decline/cancel + content). 2: deny. Other: stderr to user.                          |
| ElicitationResult               | `mcp_server_name`, `elicitation_id` (optional), `mode` (optional), `action` (`accept`/`decline`/`cancel`), `content` (optional)                                                                                                              | 0: use hookSpecificOutput to override action/content. 2: block (action becomes decline). Other: stderr to user.               |
| ConfigChange                    | `source` (`user_settings`, `project_settings`, `local_settings`, `policy_settings`, `skills`), `file_path` (optional)                                                                                                                        | 0: allow change. 2: block change from being applied. Other: stderr to user.                                                   |
| InstructionsLoaded              | `file_path`, `memory_type` (`User`/`Project`/`Local`/`Managed`), `load_reason` (`session_start`/`nested_traversal`/`path_glob_match`/`include`/`compact`), `globs` (optional), `trigger_file_path` (optional), `parent_file_path` (optional) | Observability-only. Does not support blocking.                                                                                |
| CwdChanged                      | `old_cwd`, `new_cwd`                                                                                                                                                                                                                         | 0: success. hookSpecificOutput.watchPaths registers paths with FileChanged watcher. `CLAUDE_ENV_FILE` is set for env exports. |
| FileChanged                     | `file_path`, `event` (`change`/`add`/`unlink`)                                                                                                                                                                                               | 0: success. hookSpecificOutput.watchPaths can update the watch list. `CLAUDE_ENV_FILE` is set for env exports.                |
| WorktreeCreate                  | `name` (suggested worktree slug)                                                                                                                                                                                                             | 0: stdout must contain the absolute path to the created worktree. Other: creation failed.                                     |
| WorktreeRemove                  | `worktree_path` (absolute path)                                                                                                                                                                                                              | 0: removed. Other: stderr to user.                                                                                            |
| PostToolUse, PostToolUseFailure | `tool_name`, `tool_input`, `duration_ms` (tool execution time, excluding permission prompts and PreToolUse hooks)                                                                                                                            | 0: silent or `hookSpecificOutput.updatedToolOutput` to replace the result. Cannot block.                                      |
| Stop, SubagentStop              | `stop_hook_active`, `background_tasks` (running background tasks), `session_crons` (scheduled cron jobs)                                                                                                                                     | 0: allow stop or `hookSpecificOutput.additionalContext` to continue. 2: block the stop with stderr feedback.                  |
| MessageDisplay                  | Carries the assistant text about to render (input field name not documented)                                                                                                                                                                 | 0: `hookSpecificOutput.displayContent` replaces the on-screen text. Display-only -- cannot block.                             |

## Recipes: Code Quality

### Auto-Format with Prettier

Run Prettier on any file Claude edits or creates.

**Configuration** (in `.claude/settings.json`):

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null"
          }
        ]
      }
    ]
  }
}
```

No separate script needed -- this is a one-liner. The `2>/dev/null` suppresses Prettier errors for non-supported file types.

### Auto-Format Go Files

Run `gofmt` only on `.go` files after edits.

**Configuration:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | grep '\\.go$' | xargs -r gofmt -w"
          }
        ]
      }
    ]
  }
}
```

The `grep` filters to `.go` files only, and `xargs -r` skips execution when there's no match.

### Run Ruff on Python Files

Lint and auto-fix Python files with Ruff after edits.

**Script** (`.claude/hooks/ruff-format.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [[ "$FILE_PATH" != *.py ]]; then
  exit 0
fi

ruff check --fix "$FILE_PATH" 2>&1
ruff format "$FILE_PATH" 2>&1
exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/ruff-format.sh"
          }
        ]
      }
    ]
  }
}
```

### ESLint on Save

Run ESLint with auto-fix on TypeScript/JavaScript files.

**Configuration:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | grep -E '\\.(ts|tsx|js|jsx)$' | xargs -r npx eslint --fix 2>/dev/null"
          }
        ]
      }
    ]
  }
}
```

## Recipes: Safety

### Block Dangerous Commands

Prevent destructive shell commands from running.

**Script** (`.claude/hooks/block-dangerous-commands.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Patterns to block
BLOCKED_PATTERNS=(
  'rm -rf /'
  'rm -rf ~'
  'rm -rf \.'
  'mkfs\.'
  'dd if='
  ':(){ :|:& };:'
  'chmod -R 777 /'
  '> /dev/sda'
  'curl.*|.*sh'
  'wget.*|.*sh'
)

for pattern in "${BLOCKED_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qE "$pattern"; then
    echo "Blocked: command matches dangerous pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/block-dangerous-commands.sh"
          }
        ]
      }
    ]
  }
}
```

### Protect Sensitive Files

Block Claude from editing `.env` files, lock files, and other protected paths.

**Script** (`.claude/hooks/protect-sensitive-files.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

if [ -z "$FILE_PATH" ]; then
  exit 0
fi

PROTECTED_PATTERNS=(
  ".env"
  ".env.local"
  ".env.production"
  "package-lock.json"
  "yarn.lock"
  "bun.lockb"
  ".git/"
  "id_rsa"
  "id_ed25519"
  ".pem"
)

for pattern in "${PROTECTED_PATTERNS[@]}"; do
  if [[ "$FILE_PATH" == *"$pattern"* ]]; then
    echo "Blocked: '$FILE_PATH' matches protected pattern '$pattern'" >&2
    exit 2
  fi
done

exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/protect-sensitive-files.sh"
          }
        ]
      }
    ]
  }
}
```

### Block Pushes to Protected Branches

Prevent Claude from pushing directly to main or master.

**Script** (`.claude/hooks/protect-branches.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Block direct pushes to main/master
if echo "$COMMAND" | grep -qE 'git push.*(main|master)'; then
  echo "Blocked: direct push to protected branch. Use a feature branch and PR instead." >&2
  exit 2
fi

# Block force pushes entirely
if echo "$COMMAND" | grep -qE 'git push.*(-f|--force)'; then
  echo "Blocked: force push is not allowed." >&2
  exit 2
fi

exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/protect-branches.sh"
          }
        ]
      }
    ]
  }
}
```

### Prevent Credential Leaks in Commands

Block commands that might expose secrets in arguments.

**Script** (`.claude/hooks/no-secrets-in-commands.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

# Patterns that suggest credentials in command arguments
SECRET_PATTERNS=(
  'ANTHROPIC_API_KEY='
  'OPENAI_API_KEY='
  'AWS_SECRET_ACCESS_KEY='
  'token=[a-zA-Z0-9]'
  'password='
  'Authorization:.*Bearer'
  'curl.*-H.*Authorization'
)

for pattern in "${SECRET_PATTERNS[@]}"; do
  if echo "$COMMAND" | grep -qiE "$pattern"; then
    echo "Blocked: command may contain credentials. Use environment variables instead." >&2
    exit 2
  fi
done

exit 0
```

## Recipes: Verification

### Run Tests After File Changes

Run the test suite asynchronously after Claude edits source files.

**Script** (`.claude/hooks/run-tests.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')

# Only run tests for source files, not config or docs
if [[ "$FILE_PATH" != *.ts && "$FILE_PATH" != *.js && "$FILE_PATH" != *.go && "$FILE_PATH" != *.py ]]; then
  exit 0
fi

# Skip test files themselves to avoid recursive triggers
if [[ "$FILE_PATH" == *_test.* || "$FILE_PATH" == *.test.* || "$FILE_PATH" == *.spec.* ]]; then
  exit 0
fi

RESULT=$(npm test 2>&1)
EXIT_CODE=$?

if [ $EXIT_CODE -eq 0 ]; then
  echo "{\"systemMessage\": \"Tests passed after editing $FILE_PATH\"}"
else
  # Truncate output to avoid flooding context
  TRUNCATED=$(echo "$RESULT" | tail -20)
  echo "{\"systemMessage\": \"Tests FAILED after editing $FILE_PATH:\\n$TRUNCATED\"}"
fi
```

**Configuration:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
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

Setting `async: true` lets Claude keep working while tests run. Results appear on the next conversation turn.

### Stop Hook Test Gate

Prevent Claude from stopping until the test suite passes. Uses an agent hook that can actually run commands.

**Configuration:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Run the project's test suite and verify all tests pass. If tests fail, respond with {\"ok\": false, \"reason\": \"Tests are failing. Fix them before stopping.\"}. If tests pass, respond with {\"ok\": true}. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

**Critical:** The Stop event includes a `stop_hook_active` field. If you use a command hook instead of an agent hook, you must check this field to prevent infinite loops:

```bash
#!/usr/bin/env bash
INPUT=$(cat)

# Prevent infinite loop: if we already continued due to a stop hook, allow stopping
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

# Run tests
if ! npm test 2>&1; then
  echo "Tests are failing. Fix them before stopping." >&2
  exit 2
fi

exit 0
```

### Task Completion Test Gate

Block a task from being marked complete until tests pass.

**Script** (`.claude/hooks/task-test-gate.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TASK_SUBJECT=$(echo "$INPUT" | jq -r '.task_subject // "unknown task"')

if ! npm test 2>&1; then
  echo "Cannot complete '$TASK_SUBJECT': tests are failing. Fix them first." >&2
  exit 2
fi

exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "TaskCompleted": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/task-test-gate.sh",
            "timeout": 300
          }
        ]
      }
    ]
  }
}
```

### Build Verification Gate

Ensure the project builds before Claude stops.

**Script** (`.claude/hooks/build-gate.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)

if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0
fi

if ! npm run build 2>&1; then
  echo "Build is broken. Fix build errors before stopping." >&2
  exit 2
fi

exit 0
```

## Recipes: Notifications

### macOS Desktop Notification

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

### Linux Desktop Notification

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "notify-send 'Claude Code' 'Claude Code needs your attention'"
          }
        ]
      }
    ]
  }
}
```

### Slack Webhook Notification

**Script** (`.claude/hooks/slack-notify.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
MESSAGE=$(echo "$INPUT" | jq -r '.message // "Claude Code needs attention"')
TITLE=$(echo "$INPUT" | jq -r '.title // "Notification"')

# SLACK_WEBHOOK_URL should be set in your environment
if [ -z "$SLACK_WEBHOOK_URL" ]; then
  exit 0
fi

curl -s -X POST "$SLACK_WEBHOOK_URL" \
  -H 'Content-Type: application/json' \
  -d "{\"text\": \"*$TITLE*: $MESSAGE\"}" \
  >/dev/null 2>&1

exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/slack-notify.sh",
            "async": true
          }
        ]
      }
    ]
  }
}
```

Using `async: true` prevents the Slack request from blocking Claude's flow.

## Recipes: Logging and Auditing

### Log Every Bash Command

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"[\" + (now | todate) + \"] \" + .tool_input.command' >> ~/.claude/command-log.txt"
          }
        ]
      }
    ]
  }
}
```

This logs every command with a timestamp to `~/.claude/command-log.txt` before it runs. Using PreToolUse means even blocked commands are logged.

### Session Start Logger

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"[\" + (now | todate) + \"] session=\" + .session_id + \" cwd=\" + .cwd' >> ~/.claude/sessions.log"
          }
        ]
      }
    ]
  }
}
```

### Debug Wrapper Script

When a hook misbehaves, wrap it with this script to log all inputs and outputs.

**Script** (`.claude/hooks/debug-wrapper.sh`):

```bash
#!/usr/bin/env bash
LOG=~/.claude/hook-debug.log
INPUT=$(cat)
SCRIPT="$1"

TOOL=$(echo "$INPUT" | jq -r '.tool_name // "n/a"')
EVENT=$(echo "$INPUT" | jq -r '.hook_event_name // "n/a"')

echo "=== $(date) | event=$EVENT | tool=$TOOL ===" >> "$LOG"
echo "INPUT: $INPUT" >> "$LOG"

# Run the actual hook, passing stdin
OUTPUT=$(echo "$INPUT" | "$SCRIPT" 2>&1)
CODE=$?

echo "OUTPUT: $OUTPUT" >> "$LOG"
echo "EXIT: $CODE" >> "$LOG"
echo "" >> "$LOG"

# Forward the output and exit code
echo "$OUTPUT"
exit $CODE
```

**Usage** -- wrap any hook by changing its command:

```json
{
  "type": "command",
  "command": ".claude/hooks/debug-wrapper.sh .claude/hooks/protect-branches.sh"
}
```

## Recipes: Context Injection

### Inject Reminders After Compaction

When context compacts, important reminders can be lost. Re-inject them.

**Configuration:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: use Bun, not npm. Run bun test before committing. Current sprint: auth refactor.'"
          }
        ]
      }
    ]
  }
}
```

Stdout from a SessionStart hook is added as context to the conversation. The `compact` matcher ensures this only fires after compaction, not on every session start.

### Load Project State on Session Start

Inject git status and TODO context at the start of every session.

**Script** (`.claude/hooks/load-project-state.sh`):

```bash
#!/usr/bin/env bash
echo "=== Git Status ==="
git status --short 2>/dev/null

echo ""
echo "=== Recent Commits ==="
git log --oneline -5 2>/dev/null

if [ -f TODO.md ]; then
  echo ""
  echo "=== Current TODOs ==="
  cat TODO.md
fi
```

**Configuration:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/load-project-state.sh"
          }
        ]
      }
    ]
  }
}
```

### Inject Sprint Context With Every Prompt

Add project-specific context to every message Claude processes.

**Configuration:**

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "cat .claude/sprint-context.md 2>/dev/null || true"
          }
        ]
      }
    ]
  }
}
```

**Warning:** This fires on every single prompt. Keep the context file small to avoid adding unnecessary tokens per message. A few lines of reminders is fine; a multi-page document is not.

### Persist Environment Variables

SessionStart hooks can write to `$CLAUDE_ENV_FILE` to set environment variables for the session.

**Script** (`.claude/hooks/set-env.sh`):

```bash
#!/usr/bin/env bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  echo 'export NODE_ENV=development' >> "$CLAUDE_ENV_FILE"
  echo 'export DEBUG=true' >> "$CLAUDE_ENV_FILE"
  echo 'export PATH="$PATH:./node_modules/.bin"' >> "$CLAUDE_ENV_FILE"
fi
exit 0
```

**Configuration:**

```json
{
  "hooks": {
    "SessionStart": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/set-env.sh"
          }
        ]
      }
    ]
  }
}
```

`CLAUDE_ENV_FILE` is only available to SessionStart hooks. Other hook types do not have access to it.

## Recipes: Quality Gates

### Prompt-Based Stop Gate

Use a Haiku model to evaluate whether Claude should stop, based on conversation context.

**Configuration:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "prompt",
            "prompt": "Evaluate whether Claude should stop working. Context: $ARGUMENTS\n\nCheck:\n1. Are all user-requested tasks complete?\n2. Are there unaddressed errors?\n3. Is follow-up work needed?\n\nRespond with {\"ok\": true} to allow stopping, or {\"ok\": false, \"reason\": \"explanation\"} to continue.",
            "model": "haiku",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

Prompt hooks cost very little (Haiku at $1/MTok input) and add a lightweight quality check without needing a script.

### Agent-Based Verification Gate

For thorough verification that requires reading files or running commands.

**Configuration:**

```json
{
  "hooks": {
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Before allowing Claude to stop, verify:\n1. Run the test suite and confirm all tests pass\n2. Check that no TODO comments were left in modified files\n3. Verify the build succeeds\n\nIf everything passes, respond {\"ok\": true}. Otherwise, {\"ok\": false, \"reason\": \"details\"}. $ARGUMENTS",
            "timeout": 180
          }
        ]
      }
    ]
  }
}
```

Agent hooks are more expensive (they spawn a full subagent with tool access) but can perform multi-step verification.

### Stop Hook Code Review

Trigger a semantic code review subagent when Claude finishes, covering only files modified since the last review. This combines two hooks: a PostToolUse hook that tracks which files were modified, and a Stop hook that triggers the review.

The pattern addresses a specific problem: Claude ignores system prompt instructions as context fills up. A separate review agent with a fresh context window catches violations that the main agent missed or rationalized away.

**File tracking script** (`.claude/hooks/review-tracker.sh`):

```bash
#!/usr/bin/env bash
set -euo pipefail

LOG_DIR="/tmp"
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty')
ACTION="${1:-}"

if [ -z "$SESSION_ID" ]; then
  exit 0
fi

LOG_FILE="${LOG_DIR}/review-log-${SESSION_ID}.jsonl"

log_file_modified() {
  local FILE_PATH
  FILE_PATH=$(echo "$INPUT" | jq -r '.tool_input.file_path // empty')
  if [ -z "$FILE_PATH" ]; then
    exit 0
  fi

  # Filter by extension -- customize for your project
  case "$FILE_PATH" in
    *.ts|*.tsx|*.js|*.jsx|*.go|*.py) ;;
    *) exit 0 ;;
  esac

  jq -nc --arg f "$FILE_PATH" --arg e "file_modified" \
    '{event: $e, file: $f}' >> "$LOG_FILE"
}

check_and_review() {
  if [ ! -f "$LOG_FILE" ]; then
    exit 0
  fi

  # Find files modified since the last review
  local LAST_REVIEW_LINE
  LAST_REVIEW_LINE=$(grep -n '"review_triggered"' "$LOG_FILE" | tail -1 | cut -d: -f1)

  local FILES
  if [ -n "$LAST_REVIEW_LINE" ]; then
    FILES=$(tail -n +"$((LAST_REVIEW_LINE + 1))" "$LOG_FILE" \
      | jq -r 'select(.event == "file_modified") | .file' \
      | sort -u)
  else
    FILES=$(jq -r 'select(.event == "file_modified") | .file' "$LOG_FILE" \
      | sort -u)
  fi

  if [ -z "$FILES" ]; then
    exit 0
  fi

  # Mark this review point
  jq -nc '{event: "review_triggered"}' >> "$LOG_FILE"

  # Build file list for output
  local FILE_LIST
  FILE_LIST=$(echo "$FILES" | sed 's/^/- /')

  cat >&2 <<REVIEW_MSG
CODE REVIEW REQUIRED

Files modified since last review:
${FILE_LIST}

INSTRUCTION: Use the Task tool with a code review subagent. Pass the file list as the prompt. The subagent should read each file and check against the project's review rules in .claude/review-rules.md (fall back to general quality checks if the file doesn't exist).

After receiving findings:
1. Show all findings to the user.
2. For each finding, either fix it or explain why you're skipping it.
   Valid skip reasons: impossible to satisfy (you tried), conflicts with explicit requirements, or genuinely makes code worse.
   Not valid: "too much time", "out of scope", "pre-existing code", "would require large refactor."
   When uncertain, ask the user.
3. Summarize: what was fixed, what was skipped and why.
REVIEW_MSG

  exit 2
}

case "$ACTION" in
  log) log_file_modified ;;
  review) check_and_review ;;
  *) exit 0 ;;
esac
```

**Configuration:**

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit|MultiEdit",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/review-tracker.sh log"
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/review-tracker.sh review"
          }
        ]
      }
    ]
  }
}
```

**Review rules file** (`.claude/review-rules.md`):

Define project-specific rules that the review subagent checks. The subagent reads this file and applies only what's listed -- no improvisation. Example rules for a TypeScript project:

```text
## No Dangerous Fallback Values

Nullish coalescing (`??`) with a hardcoded default for required values
hides bugs. Required values should fail fast, not silently default.

Exceptions: feature flags defaulting to `false`, optional display
values with sensible defaults.

## No Generic Category Names

Files named utils.ts, helpers.ts, handlers.ts, or directories named
/shared are dumping grounds. Name files after what they contain.

## Domain Logic Stays in Domain Objects

Application services that query an entity's state and then make
decisions based on it are leaking domain logic. The entity should
protect its own invariants.
```

**How it works:**

1. Every Write/Edit/MultiEdit appends the modified file path to a JSONL log keyed by session ID.
2. When Claude stops, the Stop hook checks whether any files were modified since the last review.
3. If yes, it emits an instruction to stderr and exits 2, which blocks Claude and forces it to read the output.
4. Claude spawns a review subagent (Haiku is appropriate -- fast and cheap for focused rule-checking) that reads each file and checks against the rules.
5. The log records a `review_triggered` event so the next Stop only reviews files modified after this point.

**The anti-skip instructions matter.** Without them, Claude will rationalize ignoring findings ("out of scope," "pre-existing issue," "would require refactoring"). The Stop hook output explicitly lists what counts as a valid reason to skip a finding and what doesn't. This is a prompt-level control -- it works because the instruction arrives in a fresh context (the Stop hook output), not buried in a system prompt that's been compressed.

**Limitations:** The Stop hook fires whenever Claude finishes, including when it stops to ask a question. If Claude commits before stopping, the review happens after the commit. Neither issue is fatal, but both are worth knowing about. A `CodeReadyForReview` hook event (which doesn't exist yet) would be the correct abstraction.

This pattern is adapted from [claude-skillz](https://github.com/NTCoding/claude-skillz) by Nick Tune.

## Recipes: Error Recovery

### Alert on API Failures (StopFailure)

Send a desktop notification when a turn ends due to an API error instead of completing normally. StopFailure fires instead of Stop -- if you only listen on Stop, API errors are silent.

**Configuration:**

```json
{
  "hooks": {
    "StopFailure": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"Claude Code: \" + .error + \" -- \" + (.error_details // \"no details\")' | xargs -I{} osascript -e 'display notification \"{}\" with title \"API Error\"'"
          }
        ]
      }
    ]
  }
}
```

StopFailure is fire-and-forget -- exit codes are ignored. Use it for alerting, not control flow.

### Log API Errors to File (StopFailure)

Append every API failure to a log for later analysis. Useful for tracking rate limit patterns.

**Script** (`.claude/hooks/log-api-errors.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
ERROR=$(echo "$INPUT" | jq -r '.error // "unknown"')
DETAILS=$(echo "$INPUT" | jq -r '.error_details // "none"')
SESSION=$(echo "$INPUT" | jq -r '.session_id')

echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) session=$SESSION error=$ERROR details=$DETAILS" \
  >> "${CLAUDE_PROJECT_DIR:-.}/.claude/api-errors.log"
```

**Configuration:**

```json
{
  "hooks": {
    "StopFailure": [
      {
        "matcher": "rate_limit|server_error|authentication_failed",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/log-api-errors.sh"
          }
        ]
      }
    ]
  }
}
```

The matcher filters by error type so you only log errors worth investigating.

## Recipes: Permission Auditing

### Log Denied Tool Calls (PermissionDenied)

Track every tool call the auto mode classifier rejects. Useful for tuning permission rules -- if the same tool keeps getting denied, consider adding an explicit allow rule.

**Script** (`.claude/hooks/log-denied.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name')
REASON=$(echo "$INPUT" | jq -r '.reason // "no reason"')
echo "$(date -u +%Y-%m-%dT%H:%M:%SZ) DENIED tool=$TOOL reason=$REASON" \
  >> "${CLAUDE_PROJECT_DIR:-.}/.claude/permission-denials.log"
```

**Configuration:**

```json
{
  "hooks": {
    "PermissionDenied": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/log-denied.sh"
          }
        ]
      }
    ]
  }
}
```

To let the model retry a denied call (use with caution), return `{"hookSpecificOutput":{"hookEventName":"PermissionDenied","retry":true}}` on stdout.

## Recipes: Context Recovery

### Inject Context After Compaction (PostCompact)

Compaction loses detail. This hook re-injects critical context (active branch, recent test status, key decisions) after every compaction so the model doesn't lose its bearings.

**Script** (`.claude/hooks/post-compact-context.sh`):

```bash
#!/usr/bin/env bash
BRANCH=$(git -C "$CLAUDE_CWD" branch --show-current 2>/dev/null || echo "unknown")
LAST_TEST=$(git -C "$CLAUDE_CWD" log --oneline -1 --grep="test" 2>/dev/null || echo "no recent test commits")
STATUS=$(git -C "$CLAUDE_CWD" status --porcelain 2>/dev/null | head -5)

cat <<EOF
Post-compaction context:
- Branch: $BRANCH
- Last test commit: $LAST_TEST
- Uncommitted files: $(echo "$STATUS" | wc -l | tr -d ' ')
EOF
```

**Configuration:**

```json
{
  "hooks": {
    "PostCompact": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/post-compact-context.sh"
          }
        ]
      }
    ]
  }
}
```

PostCompact also receives `compact_summary` in its input -- the full text of the compaction summary. You can parse it to detect if important context was dropped.

## Recipes: Repo Setup

### Run Setup Scripts on Init (Setup)

Run project bootstrapping when Claude first opens a repo -- install dependencies, generate types, seed databases. The `init` trigger fires once per session; `maintenance` fires periodically.

**Script** (`.claude/hooks/repo-setup.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TRIGGER=$(echo "$INPUT" | jq -r '.trigger')

if [ "$TRIGGER" = "init" ]; then
  # One-time setup
  if [ -f "package.json" ] && [ ! -d "node_modules" ]; then
    echo "Installing dependencies..."
    npm install --silent 2>&1
  fi
  if [ -f "Makefile" ]; then
    make generate 2>&1 || true
  fi
elif [ "$TRIGGER" = "maintenance" ]; then
  # Periodic checks
  if [ -f "package-lock.json" ] && ! npm ls --all >/dev/null 2>&1; then
    echo "Dependencies out of sync, running npm install..."
    npm install --silent 2>&1
  fi
fi
```

**Configuration:**

```json
{
  "hooks": {
    "Setup": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/repo-setup.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

Setup hook stdout is shown to Claude, so the model knows what happened. Blocking errors are ignored -- a failed setup doesn't prevent the session from starting.

## Recipes: Task Management

### Notify on Task Creation (TaskCreated)

Send a Slack message when a teammate creates a task. Useful for agent team coordination.

**Configuration:**

```json
{
  "hooks": {
    "TaskCreated": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '\"Task created: \" + .task_subject + \" (by \" + (.teammate_name // \"main\") + \")\"' | curl -s -X POST -H 'Content-type: application/json' -d @- \"$SLACK_WEBHOOK_URL\""
          }
        ]
      }
    ]
  }
}
```

Exit 2 blocks task creation -- use this for validation (e.g., reject tasks without a description):

```json
{
  "hooks": {
    "TaskCreated": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -e '.task_description | length > 0' > /dev/null || (echo 'Tasks require a description' >&2; exit 2)"
          }
        ]
      }
    ]
  }
}
```

## Recipes: MCP Elicitation

### Auto-Approve Trusted MCP Servers (Elicitation)

When a trusted MCP server requests user input, auto-accept instead of showing the dialog. This removes friction for servers you've already vetted.

**Script** (`.claude/hooks/auto-approve-mcp.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
SERVER=$(echo "$INPUT" | jq -r '.mcp_server_name')

# Auto-approve known trusted servers
case "$SERVER" in
  github|context7|obsidian)
    echo '{"hookSpecificOutput":{"action":"accept"}}'
    exit 0
    ;;
  *)
    # Let the dialog show for unknown servers
    exit 0
    ;;
esac
```

**Configuration:**

```json
{
  "hooks": {
    "Elicitation": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/auto-approve-mcp.sh"
          }
        ]
      }
    ]
  }
}
```

### Audit MCP Responses (ElicitationResult)

Log every user response to MCP elicitations for compliance or debugging.

**Configuration:**

```json
{
  "hooks": {
    "ElicitationResult": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq '{server: .mcp_server_name, action: .action, mode: .mode, time: now | todate}' >> .claude/elicitation-audit.jsonl"
          }
        ]
      }
    ]
  }
}
```

Exit 2 overrides the response to `decline` -- use this to block sensitive data from being sent to specific servers.

## Recipes: Configuration Monitoring

### Block Unauthorized Settings Changes (ConfigChange)

Prevent project or local settings from being modified during a session. Useful in managed environments where settings should only change through deployment.

**Configuration:**

```json
{
  "hooks": {
    "ConfigChange": [
      {
        "matcher": "project_settings|local_settings",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Settings changes are managed by platform engineering. Change rejected.' >&2; exit 2"
          }
        ]
      }
    ]
  }
}
```

Exit 2 blocks the change from being applied to the session. Exit 0 allows it.

### Log All Configuration Changes (ConfigChange)

Append every settings change to an audit log for tracking drift.

**Configuration:**

```json
{
  "hooks": {
    "ConfigChange": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{time: (now | todate), source: .source, file: .file_path}' >> .claude/config-changes.jsonl"
          }
        ]
      }
    ]
  }
}
```

## Recipes: Instruction Auditing

### Log Instruction Loading (InstructionsLoaded)

Track which CLAUDE.md files and rules are loaded and why. Useful for debugging unexpected behavior caused by path-glob rules or `@include` chains.

**Configuration:**

```json
{
  "hooks": {
    "InstructionsLoaded": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -c '{time: (now | todate), file: .file_path, type: .memory_type, reason: .load_reason, globs: .globs, trigger: .trigger_file_path, parent: .parent_file_path}' >> .claude/instructions-loaded.jsonl"
          }
        ]
      }
    ]
  }
}
```

InstructionsLoaded is observability-only -- it cannot block instruction loading. The `load_reason` field tells you why the file was loaded:

- `session_start` -- loaded during initial session setup
- `nested_traversal` -- loaded because it's in a parent directory
- `path_glob_match` -- loaded because a `paths:` frontmatter glob matched a file Claude touched
- `include` -- loaded via `@include` directive from another file
- `compact` -- reloaded after context compaction

## Recipes: File System Monitoring

### Auto-Source Environment on Directory Change (CwdChanged)

When Claude changes working directory (via `add-dir` or `cd`), source the local `.envrc` and export its variables for subsequent Bash commands.

**Script** (`.claude/hooks/cwd-env-loader.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
NEW_CWD=$(echo "$INPUT" | jq -r '.new_cwd')

# If the new directory has an .envrc, export its variables
if [ -f "$NEW_CWD/.envrc" ]; then
  # Write exports to CLAUDE_ENV_FILE so BashTool picks them up
  grep '^export ' "$NEW_CWD/.envrc" >> "$CLAUDE_ENV_FILE"
fi
```

**Configuration:**

```json
{
  "hooks": {
    "CwdChanged": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/cwd-env-loader.sh"
          }
        ]
      }
    ]
  }
}
```

CwdChanged hooks can also return `hookSpecificOutput.watchPaths` to register new file paths with the FileChanged watcher.

### Hot-Reload on File Changes (FileChanged)

Re-run a build or test when a watched file changes. The matcher specifies which filenames trigger the hook -- use it for config files, lock files, or schema definitions.

**Configuration:**

```json
{
  "hooks": {
    "FileChanged": [
      {
        "matcher": ".envrc|.env",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.file_path' | xargs -I{} sh -c 'grep \"^export \" \"{}\" >> \"$CLAUDE_ENV_FILE\" 2>/dev/null || true'"
          }
        ]
      },
      {
        "matcher": "schema.prisma",
        "hooks": [
          {
            "type": "command",
            "command": "npx prisma generate 2>&1",
            "timeout": 30
          }
        ]
      }
    ]
  }
}
```

FileChanged also receives the `event` field (`change`, `add`, or `unlink`) so you can react differently to file creation vs. deletion.

## Recipes: Worktree Management

### Custom Worktree Creation (WorktreeCreate)

Override the default git worktree creation with a custom strategy -- useful for non-git repos or when you need additional setup in each worktree.

**Script** (`.claude/hooks/create-worktree.sh`):

```bash
#!/usr/bin/env bash
INPUT=$(cat)
NAME=$(echo "$INPUT" | jq -r '.name')
BASE_DIR="${CLAUDE_PROJECT_DIR:-$(pwd)}"
WORKTREE_DIR="/tmp/claude-worktrees/$NAME"

mkdir -p "$WORKTREE_DIR"
git -C "$BASE_DIR" worktree add "$WORKTREE_DIR" -b "worktree/$NAME" 2>&1

# Install dependencies in the worktree
if [ -f "$WORKTREE_DIR/package.json" ]; then
  (cd "$WORKTREE_DIR" && npm install --silent) 2>&1
fi

# Print the absolute path -- this is the required protocol
echo "$WORKTREE_DIR"
```

**Configuration:**

```json
{
  "hooks": {
    "WorktreeCreate": [
      {
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/create-worktree.sh",
            "timeout": 120
          }
        ]
      }
    ]
  }
}
```

WorktreeCreate hooks **must** print the absolute path to the created directory on stdout. This is not optional -- the system reads stdout to know where the worktree is.

### Clean Up Worktrees (WorktreeRemove)

Run cleanup when a worktree is removed -- kill background processes, remove temp files, prune git refs.

**Configuration:**

```json
{
  "hooks": {
    "WorktreeRemove": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.worktree_path' | xargs -I{} sh -c 'git worktree remove \"{}\" --force 2>/dev/null; rm -rf \"{}\"'"
          }
        ]
      }
    ]
  }
}
```

## Combining Hooks

### A Complete Safety Setup

A set of hooks focused on preventing mistakes, suitable for `~/.claude/settings.json` (applies to all projects):

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Bash",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/block-dangerous-commands.sh"
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/no-secrets-in-commands.sh"
          },
          {
            "type": "command",
            "command": "~/.claude/hooks/protect-branches.sh"
          },
          {
            "type": "command",
            "command": "jq -r '\"[\" + (now | todate) + \"] \" + .tool_input.command' >> ~/.claude/command-log.txt"
          }
        ]
      },
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "~/.claude/hooks/protect-sensitive-files.sh"
          }
        ]
      }
    ],
    "Notification": [
      {
        "matcher": "",
        "hooks": [
          {
            "type": "command",
            "command": "osascript -e 'display notification \"Claude Code needs your attention\" with title \"Claude Code\"'"
          }
        ]
      }
    ]
  }
}
```

Multiple hooks on the same matcher run in order. If any hook exits 2, the tool call is blocked and subsequent hooks don't run.

### A Complete CI-Style Setup

A project-level setup focused on code quality and verification, suitable for `.claude/settings.json`:

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Edit|Write",
        "hooks": [
          {
            "type": "command",
            "command": "jq -r '.tool_input.file_path' | xargs npx prettier --write 2>/dev/null"
          },
          {
            "type": "command",
            "command": ".claude/hooks/run-tests.sh",
            "async": true,
            "timeout": 300
          }
        ]
      }
    ],
    "Stop": [
      {
        "hooks": [
          {
            "type": "agent",
            "prompt": "Run the test suite. If all tests pass, respond {\"ok\": true}. If any fail, respond {\"ok\": false, \"reason\": \"Tests failing\"}. $ARGUMENTS",
            "timeout": 120
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "startup",
        "hooks": [
          {
            "type": "command",
            "command": ".claude/hooks/load-project-state.sh"
          }
        ]
      },
      {
        "matcher": "compact",
        "hooks": [
          {
            "type": "command",
            "command": "echo 'Reminder: run tests before committing. Follow TDD.'"
          }
        ]
      }
    ]
  }
}
```

## Gotchas and Debugging

### The Stop Hook Infinite Loop

The most common hook bug. If your Stop hook always blocks, Claude will never stop. Always check `stop_hook_active`:

```bash
if [ "$(echo "$INPUT" | jq -r '.stop_hook_active')" = "true" ]; then
  exit 0  # Let Claude stop this time
fi
```

Agent and prompt hooks handle this automatically -- they receive the `stop_hook_active` context in `$ARGUMENTS`.

### Shell Profile Pollution

If your `~/.zshrc` or `~/.bashrc` prints text unconditionally (e.g., `echo "Welcome!"`), it prepends to your hook's stdout and breaks JSON parsing. Fix by wrapping in interactive-shell checks:

```bash
if [[ $- == *i* ]]; then
  echo "Welcome!"
fi
```

### Hook Snapshot at Startup

Claude Code captures hook configuration at session start. If you edit hooks during a session, changes don't take effect until you run `/hooks` to review them or restart the session.

### Async Hooks Cannot Block

Async hooks run in the background. By the time they finish, the triggering action has already proceeded. Use async for notifications and logging, not for safety gates.

### Exit 2 vs JSON

If a hook exits with code 2, stdout is ignored. If you want structured control (allow/deny/ask with reasons), exit 0 and output JSON. Don't mix the approaches.

### PermissionRequest Hooks Don't Fire in Headless Mode

In headless mode (`claude -p`), PermissionRequest events don't fire. Use PreToolUse hooks for automated permission decisions in CI/CD pipelines.

### PostToolUse Cannot Undo

PostToolUse fires after the tool has already run. You can log, notify, or inject a system message, but you can't undo the action.

### The hookEventName Bug

When returning JSON from a PreToolUse hook, the `hookSpecificOutput` object must include `"hookEventName": "PreToolUse"`. Omitting it causes a parse error. This is a common bug in custom hooks:

```json
{
  "hookSpecificOutput": {
    "hookEventName": "PreToolUse",
    "permissionDecision": "allow"
  }
}
```

### Debugging Commands

- **`claude --debug`** -- full hook execution details in output
- **`Ctrl+O`** -- toggle verbose mode to see hook output in the transcript
- **Manual testing** -- pipe JSON to your script directly:

```bash
echo '{"tool_name":"Bash","tool_input":{"command":"rm -rf /"}}' | .claude/hooks/block-dangerous-commands.sh
echo "Exit code: $?"
```

## Best Practices

1. **Start simple.** One or two safety hooks are better than a complex multi-hook pipeline. Add hooks as you find specific needs, not speculatively.

2. **Use async for non-blocking work.** Formatting, logging, notifications, and test runs that don't need to block should use `async: true`.

3. **Keep hooks fast.** Synchronous hooks block Claude's workflow. If a hook takes more than a few seconds, consider making it async or increasing the timeout.

4. **Filter by file type in the script.** Rather than trying to encode file type logic in matchers, check the file extension inside the script. Matchers filter by tool name, not file path.

5. **Use PreToolUse for safety, PostToolUse for quality.** Safety hooks (blocking dangerous actions) should fire before the tool runs. Quality hooks (formatting, testing) should fire after.

6. **Put personal hooks in `~/.claude/settings.json`.** Team hooks go in `.claude/settings.json` (committed). Personal preferences (notifications, editor integrations) go in user settings.

7. **Test hooks manually before deploying.** Pipe sample JSON to your scripts and verify the exit codes and output before adding them to settings.

8. **Log during development.** Use the debug wrapper script or write to a log file while developing hooks. Remove verbose logging once the hook is stable.

9. **Truncate large output.** If a hook outputs test results or build logs, truncate to the last 20-30 lines. Long outputs consume context tokens.

10. **Use `jq -r` for field extraction.** It handles missing fields gracefully (returns "null" or empty string) and avoids fragile grep/sed parsing.

## Anti-Patterns

1. **Stop hooks without `stop_hook_active` check.** Causes infinite loops where Claude can never finish responding.

2. **Synchronous test suites on every edit.** Running a full test suite synchronously after every Edit/Write blocks Claude for minutes. Use `async: true` or limit to specific file patterns.

3. **Overly broad matchers with expensive hooks.** A PostToolUse hook with no matcher that runs a test suite fires on every single tool call -- Read, Glob, Grep, everything.

4. **Secrets in hook scripts.** Don't hardcode API keys or tokens in hook scripts that get committed to the repo. Use environment variables.

5. **Complex JSON construction in bash.** Building nested JSON in bash is fragile. Use `jq -n` for constructing JSON output:

   ```bash
   # Bad
   echo '{"hookSpecificOutput":{"hookEventName":"PreToolUse","permissionDecision":"deny"}}'

   # Good
   jq -n '{
     hookSpecificOutput: {
       hookEventName: "PreToolUse",
       permissionDecision: "deny",
       permissionDecisionReason: "Not allowed"
     }
   }'
   ```

6. **UserPromptSubmit hooks that inject large context.** This fires on every single user message. A 500-line context file injected per message burns thousands of tokens per turn.

7. **Ignoring exit codes from tools.** If your hook calls `npm test` but doesn't check `$?`, it silently passes even when tests fail.

8. **Multiple blocking hooks that duplicate checks.** If you have both a PreToolUse hook and a PermissionRequest hook checking the same thing, you'll get duplicate prompts or conflicting decisions.

## References

- [Official Hooks Reference](https://code.claude.com/docs/en/hooks) -- complete event list, configuration format, JSON schemas
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide) -- tutorial-style walkthrough with examples
- [Bash Command Validator Example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py) -- official Python hook example from Anthropic
- [claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) -- community collection with TTS, logging, and validator implementations
- [claude-code-hooks](https://github.com/karanb192/claude-code-hooks) -- ready-to-use Node.js hooks with configurable safety levels
- [How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks) -- Anthropic blog post on hook configuration patterns
- [Integration Patterns]({{< relref "/extending/integration-patterns" >}}) -- MCP servers, headless mode, GitHub Actions
- [Permissions & Enterprise]({{< relref "/guides/permissions-enterprise" >}}) -- permission modes, managed settings, security controls
