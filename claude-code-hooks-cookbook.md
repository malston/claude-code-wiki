# Custom Hooks Cookbook: Practical Recipes for Automating Claude Code

## Executive Summary

Hooks let you run code at specific points in Claude Code's lifecycle -- before a tool runs, after a file is edited, when a session starts, when Claude finishes responding. This cookbook provides copy-paste-ready recipes for the most common use cases: auto-formatting, command safety, test gates, notifications, logging, and context injection. Each recipe includes the hook configuration, the script, and notes on gotchas.

| Category          | Example Recipes                                       | Hook Events Used                  |
| ----------------- | ----------------------------------------------------- | --------------------------------- |
| **Code quality**  | Auto-format, lint on save, type check                 | PostToolUse (Edit\|Write)         |
| **Safety**        | Block dangerous commands, protect files, branch guard | PreToolUse (Bash, Edit\|Write)    |
| **Verification**  | Test gates, build checks, stop-until-passing          | PostToolUse, Stop, TaskCompleted  |
| **Notifications** | Desktop alerts, Slack, TTS                            | Notification                      |
| **Logging**       | Command audit, session tracking, debug wrapper        | PostToolUse, SessionStart         |
| **Context**       | Inject reminders, load state, persist env vars        | SessionStart, UserPromptSubmit    |
| **Quality gates** | Block stopping until tasks complete, review checks    | Stop, SubagentStop, TaskCompleted |

---

## Table of Contents

- [Hook Fundamentals](#hook-fundamentals)
  - [Where Hooks Live](#where-hooks-live)
  - [The Three Hook Types](#the-three-hook-types)
  - [Exit Code Protocol](#exit-code-protocol)
  - [JSON Output Format](#json-output-format)
  - [Environment Variables](#environment-variables)
- [Event Reference](#event-reference)
  - [Complete Event Table](#complete-event-table)
  - [Matcher Syntax](#matcher-syntax)
  - [Tool Input Schemas](#tool-input-schemas)
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
- [Combining Hooks](#combining-hooks)
  - [A Complete Safety Setup](#a-complete-safety-setup)
  - [A Complete CI-Style Setup](#a-complete-ci-style-setup)
- [Gotchas and Debugging](#gotchas-and-debugging)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [References](#references)

---

## Hook Fundamentals

### Where Hooks Live

Hooks are configured in JSON settings files. Three scopes are available:

| Location                      | Scope               | Committable? |
| ----------------------------- | ------------------- | ------------ |
| `~/.claude/settings.json`     | All your projects   | No           |
| `.claude/settings.json`       | This project (team) | Yes          |
| `.claude/settings.local.json` | This project (you)  | No           |

Hooks from all scopes merge together. Plugins can also register hooks via `hooks/hooks.json` in their package.

### The Three Hook Types

**Command hooks** run a shell command. The script receives JSON on stdin and communicates via exit codes and stdout.

```json
{
  "type": "command",
  "command": "/path/to/script.sh",
  "timeout": 600,
  "async": false
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

Agent hooks are useful when verification requires inspecting files or running commands, not just evaluating the input data.

### Exit Code Protocol

| Exit Code | Meaning            | Behavior                                                       |
| --------- | ------------------ | -------------------------------------------------------------- |
| **0**     | Success            | Stdout parsed for JSON. For SessionStart, stdout is context    |
| **2**     | Blocking error     | Stderr fed to Claude. Blocks the action (if event supports it) |
| **Other** | Non-blocking error | Stderr shown in verbose mode (Ctrl+O). Execution continues     |

Not every event supports blocking. The events that respond to exit 2:

- **Can block:** PreToolUse, PermissionRequest, UserPromptSubmit, Stop, SubagentStop, TeammateIdle, TaskCompleted
- **Cannot block:** PostToolUse, PostToolUseFailure, Notification, SubagentStart, SessionStart, SessionEnd, PreCompact

### JSON Output Format

When a hook exits 0 and prints JSON to stdout, these universal fields are available:

| Field            | Default | Description                                      |
| ---------------- | ------- | ------------------------------------------------ |
| `continue`       | `true`  | If `false`, Claude stops the entire session      |
| `stopReason`     | --      | Message shown to user when `continue` is `false` |
| `suppressOutput` | `false` | If `true`, hides stdout from verbose mode        |
| `systemMessage`  | --      | Warning message shown to user                    |

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

### Environment Variables

| Variable             | Available In | Description                                       |
| -------------------- | ------------ | ------------------------------------------------- |
| `CLAUDE_PROJECT_DIR` | All hooks    | Project root directory                            |
| `CLAUDE_PLUGIN_ROOT` | Plugin hooks | Plugin package root                               |
| `CLAUDE_CODE_REMOTE` | All hooks    | `"true"` in remote web environments               |
| `CLAUDE_ENV_FILE`    | SessionStart | Path to file for persisting environment variables |

---

## Event Reference

### Complete Event Table

```
Session lifecycle:
  SessionStart ──> [conversation] ──> SessionEnd
                        │
Conversation flow:      │
  UserPromptSubmit ──> PreToolUse ──> [tool runs] ──> PostToolUse
                           │                              │
                           │ (if blocked)           PostToolUseFailure
                           │
                     PermissionRequest (if permission needed)
                           │
Completion events:         │
  Stop (Claude finishes) ──┘
  SubagentStart / SubagentStop
  TeammateIdle / TaskCompleted

Maintenance:
  PreCompact ──> [compaction runs]
  Notification (permission_prompt, idle_prompt, etc.)
```

| Event              | Fires When                   | Can Block? | Matcher Filters                              |
| ------------------ | ---------------------------- | ---------- | -------------------------------------------- |
| SessionStart       | Session begins or resumes    | No         | startup, resume, clear, compact              |
| UserPromptSubmit   | User submits a prompt        | Yes        | (none -- always fires)                       |
| PreToolUse         | Before a tool call           | Yes        | Tool name                                    |
| PermissionRequest  | Permission dialog appears    | Yes        | Tool name                                    |
| PostToolUse        | After a tool call succeeds   | No         | Tool name                                    |
| PostToolUseFailure | After a tool call fails      | No         | Tool name                                    |
| Notification       | Claude sends a notification  | No         | permission_prompt, idle_prompt, auth_success |
| SubagentStart      | Subagent is spawned          | No         | Agent type                                   |
| SubagentStop       | Subagent finishes            | Yes        | Agent type                                   |
| Stop               | Claude finishes responding   | Yes        | (none -- always fires)                       |
| TeammateIdle       | Agent team member going idle | Yes        | (none -- always fires)                       |
| TaskCompleted      | Task marked as completed     | Yes        | (none -- always fires)                       |
| PreCompact         | Before context compaction    | No         | manual, auto                                 |
| SessionEnd         | Session terminates           | No         | clear, logout, other                         |

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

---

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

### Exit 2 vs JSON -- Choose One

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

---

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

---

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

---

## References

- [Official Hooks Reference](https://code.claude.com/docs/en/hooks) -- complete event list, configuration format, JSON schemas
- [Hooks Guide](https://code.claude.com/docs/en/hooks-guide) -- tutorial-style walkthrough with examples
- [Bash Command Validator Example](https://github.com/anthropics/claude-code/blob/main/examples/hooks/bash_command_validator_example.py) -- official Python hook example from Anthropic
- [claude-code-hooks-mastery](https://github.com/disler/claude-code-hooks-mastery) -- community collection with TTS, logging, and validator implementations
- [claude-code-hooks](https://github.com/karanb192/claude-code-hooks) -- ready-to-use Node.js hooks with configurable safety levels
- [How to Configure Hooks](https://claude.com/blog/how-to-configure-hooks) -- Anthropic blog post on hook configuration patterns
