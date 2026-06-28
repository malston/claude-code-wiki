---
title: "Workflow Patterns: Common Development Workflows with Claude Code"
linkTitle: "Workflow Patterns"
weight: 2
---

# Workflow Patterns: Common Development Workflows with Claude Code

## Executive Summary

Claude Code is an agentic coding tool -- it explores, plans, and implements rather than just answering questions. Getting the most out of it means structuring your work around its strengths: verification-driven development, iterative feedback loops, context management, and knowing when to delegate to subagents. This article covers the core workflow patterns for day-to-day development.

| Workflow                      | When to Use                              | Key Pattern                              |
| ----------------------------- | ---------------------------------------- | ---------------------------------------- |
| **Explore-Plan-Implement**    | New features, unfamiliar code            | Separate research from coding            |
| **Fix with Verification**     | Bug fixes, error resolution              | Reproduce, fix, verify                   |
| **Test-Driven Development**   | New features, bug fixes                  | Write tests first, then implement        |
| **Code Review**               | Before merge, after implementation       | Fresh session, different perspective     |
| **Refactor**                  | Code improvement, migration              | Small steps with continuous verification |
| **Multi-Session**             | Large features, multi-day work           | State files, named sessions, checkpoints |
| **Parallel Sessions**         | Independent tasks, writer/reviewer split | `--worktree`, `--tmux`, headless mode    |
| **Headless / CI Integration** | Automated checks, batch operations       | `claude -p` with structured output       |

## Table of Contents

- [Workflow Patterns: Common Development Workflows with Claude Code](#workflow-patterns-common-development-workflows-with-claude-code)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [The Core Loop](#the-core-loop)
  - [Explore-Plan-Implement](#explore-plan-implement)
    - [When to Plan vs When to Just Do It](#when-to-plan-vs-when-to-just-do-it)
    - [The Four Phases](#the-four-phases)
    - [The Interview Pattern](#the-interview-pattern)
  - [Fix with Verification](#fix-with-verification)
    - [The Debugging Workflow](#the-debugging-workflow)
    - [Providing Verification Criteria](#providing-verification-criteria)
  - [Test-Driven Development](#test-driven-development)
    - [TDD with Claude Code](#tdd-with-claude-code)
    - [Tests as Durable Requirements](#tests-as-durable-requirements)
  - [Code Review](#code-review)
    - [Self-Review vs Fresh Session](#self-review-vs-fresh-session)
    - [The Writer/Reviewer Pattern](#the-writerreviewer-pattern)
  - [Refactoring](#refactoring)
    - [Small Steps with Verification](#small-steps-with-verification)
    - [Large-Scale Migrations](#large-scale-migrations)
  - [Session Management](#session-management)
    - [When to Clear Context](#when-to-clear-context)
    - [Rewind and Checkpoints](#rewind-and-checkpoints)
    - [Named Sessions](#named-sessions)
    - [Resuming Work](#resuming-work)
    - [Session Recap](#session-recap)
  - [Recurring Tasks with /loop](#recurring-tasks-with-loop)
    - [Fixed Interval vs Self-Paced](#fixed-interval-vs-self-paced)
    - [Babysit a PR Until It Merges](#babysit-a-pr-until-it-merges)
    - [Wait on a Deploy, Then Verify](#wait-on-a-deploy-then-verify)
    - [Self-Paced Test-Fixing Sweep](#self-paced-test-fixing-sweep)
    - [Stopping a Loop](#stopping-a-loop)
  - [Goal-Driven Sessions with /goal](#goal-driven-sessions-with-goal)
  - [Terminal Display Modes](#terminal-display-modes)
  - [Multi-Session and Parallel Work](#multi-session-and-parallel-work)
    - [Git Worktrees for Isolation](#git-worktrees-for-isolation)
    - [tmux Monitoring Layouts](#tmux-monitoring-layouts)
    - [Headless Mode for Automation](#headless-mode-for-automation)
    - [Fan-Out Pattern](#fan-out-pattern)
  - [Subagent Patterns](#subagent-patterns)
    - [Investigation Without Context Pollution](#investigation-without-context-pollution)
    - [Post-Implementation Verification](#post-implementation-verification)
    - [When Not to Use Subagents](#when-not-to-use-subagents)
  - [Common Failure Patterns](#common-failure-patterns)
  - [Best Practices](#best-practices)
  - [References](#references)

## The Core Loop

Every Claude Code workflow follows the same fundamental loop:

```text
1. Give a focused instruction
       │
2. Claude acts (reads, edits, runs commands)
       │
3. Review the result
       │
   ┌───┴───┐
   │       │
  Done   Course-correct → back to step 1
```

The key insight from the official best practices: **Claude performs dramatically better when it can verify its own work.** Tests, linters, compiler output, screenshots -- anything that gives Claude a feedback loop independent of you.

Without verification, Claude produces code that looks right but may not work. With verification, Claude iterates until the output actually passes. This single pattern -- give Claude a way to check itself -- is the highest-leverage improvement to any workflow.

## Explore-Plan-Implement

### When to Plan vs When to Just Do It

```text
Is the scope clear and the change small?
│
├── YES → Just do it directly
│   "fix the typo on line 12"
│   "add a nil check before dereferencing user"
│   "rename processData to transformRecords"
│
└── NO → Use the explore-plan-implement pattern
    "add OAuth support to the API"
    "refactor the authentication module"
    "migrate from REST to GraphQL"
```

Planning adds overhead. For tasks where you could describe the diff in one sentence, skip the plan and ask Claude to make the change directly. Planning is most valuable when:

- You're uncertain about the approach
- The change touches multiple files
- You're unfamiliar with the code being modified

### The Four Phases

```text
Phase 1: EXPLORE (Plan Mode)
  Claude reads files and understands the codebase.
  No changes are made.
  ┌─────────────────────────────────────────────────┐
  │ "read src/auth/ and understand how sessions     │
  │  and login are handled. also look at how we     │
  │  manage environment variables for secrets."     │
  └─────────────────────────────────────────────────┘
           │
Phase 2: PLAN (Plan Mode)
  Claude proposes an implementation strategy.
  You review and adjust before any code is written.
  ┌─────────────────────────────────────────────────┐
  │ "I want to add Google OAuth. What files need    │
  │  to change? What's the session flow? Create     │
  │  a plan."                                       │
  └─────────────────────────────────────────────────┘
           │
Phase 3: IMPLEMENT (Normal Mode)
  Claude writes code, guided by the approved plan.
  ┌─────────────────────────────────────────────────┐
  │ "implement the OAuth flow from your plan.       │
  │  write tests for the callback handler, run      │
  │  the test suite and fix any failures."          │
  └─────────────────────────────────────────────────┘
           │
Phase 4: COMMIT
  Claude commits with a descriptive message.
  ┌─────────────────────────────────────────────────┐
  │ "commit with a descriptive message and          │
  │  open a PR"                                     │
  └─────────────────────────────────────────────────┘
```

Toggle plan mode with **Shift+Tab** during a session, or start in plan mode with `claude --permission-mode plan`. Press **Ctrl+G** to open the plan in your editor for direct editing before Claude proceeds.

### The Interview Pattern

For larger features where requirements aren't fully defined, have Claude interview you before planning:

```text
I want to build [brief description]. Interview me in
detail using the AskUserQuestion tool.

Ask about technical implementation, UI/UX, edge cases,
concerns, and tradeoffs. Don't ask obvious questions,
dig into the hard parts I might not have considered.

Keep interviewing until we've covered everything, then
write a complete spec to SPEC.md.
```

Then start a fresh session to implement the spec. The new session has clean context focused entirely on implementation, and you have a written spec to reference.

## Fix with Verification

### The Debugging Workflow

The most effective debugging pattern gives Claude the symptom, the likely location, and what "fixed" looks like:

```text
Step 1: Share the symptom
  "users report that login fails after session timeout"

Step 2: Point to the likely location
  "check the auth flow in src/auth/, especially
   token refresh"

Step 3: Define verification
  "write a failing test that reproduces the issue,
   then fix it and verify the test passes"
```

Compare this to the less effective approach:

```text
"fix the login bug"
  → Claude has to search for the bug, guess what's wrong,
    and hope its fix is correct
```

### Providing Verification Criteria

Always give Claude a way to verify its fix:

| Type of Change  | Verification                                                            |
| --------------- | ----------------------------------------------------------------------- |
| Bug fix         | "write a failing test that reproduces the bug, then fix it"             |
| Build error     | "fix the error and verify the build succeeds"                           |
| Logic change    | "run the existing tests after your change"                              |
| UI change       | "take a screenshot and compare to the original" (with Claude in Chrome) |
| Performance fix | "run the benchmark before and after"                                    |

The key: define what "done" looks like before Claude starts working.

## Test-Driven Development

### TDD with Claude Code

TDD is a natural fit for Claude Code because tests provide the verification loop that makes Claude most effective.

```text
Step 1: Write the tests first
  "write tests for a rate limiter that allows 5
   requests per minute per IP. test the happy path,
   the rate limit case, and the reset after timeout."

Step 2: Run the tests (they should fail)
  "run the tests to confirm they fail"

Step 3: Implement to pass the tests
  "implement the rate limiter to pass the tests"

Step 4: Refactor with safety
  "refactor the implementation for clarity --
   keep all tests passing"
```

This works well because:

- The tests define success criteria before implementation
- Claude has a concrete feedback loop (run tests, see failures, fix)
- Refactoring is safe because tests catch regressions
- Tests survive context transitions (compaction, new sessions)

### Tests as Durable Requirements

Tests are the most reliable way to carry requirements across context windows and sessions:

```text
Session 1: Write comprehensive tests
  → Tests committed to git

Session 2 (fresh context):
  "Run the tests in notification_test.go. Implement
   whatever is needed to make them pass."
  → Claude discovers requirements from the tests
```

This pattern works well for multi-session work. See [Working Across Context Windows]({{< relref "effective-prompting#working-across-context-windows" >}}) in the effective prompting article.

## Code Review

### Self-Review vs Fresh Session

Claude in the same session that wrote the code is biased -- it just produced that code and is inclined to think it's correct. A fresh session provides a genuinely different perspective.

```text
Same-session review (useful but biased):
  "review the changes you just made for edge cases"

Fresh-session review (unbiased):
  Session B: "review the rate limiter implementation
  in @src/middleware/rateLimiter.ts. look for edge
  cases, race conditions, and consistency with our
  existing middleware patterns."
```

### The Writer/Reviewer Pattern

Use two sessions for higher-quality output:

```text
Session A (Writer):
  "implement a rate limiter for our API endpoints"
       │
       ▼
Session B (Reviewer):
  "review the rate limiter in @src/middleware/
   rateLimiter.ts. look for edge cases, race
   conditions, and consistency with existing
   middleware patterns."
       │
       ▼
Session A (Writer):
  "here's the review feedback: [paste]. address
   these issues."
```

You can also split by tests and implementation:

```text
Session A: Write tests for the feature
        │
Session B: Write code to pass Session A's tests
```

This separation ensures tests aren't influenced by the implementation approach.

## Refactoring

### Small Steps with Verification

Refactoring is safest in small, testable increments:

```text
Step 1: Identify what to refactor
  "find deprecated API usage in our codebase"

Step 2: Get recommendations
  "suggest how to refactor utils.js to use modern
   JavaScript features"

Step 3: Apply incrementally
  "refactor the date formatting functions first.
   run tests after each change."

Step 4: Verify
  "run the full test suite to confirm nothing broke"
```

Each step produces a reviewable, testable result. If something breaks, you know exactly which change caused it.

### Large-Scale Migrations

For migrations that touch many files, use the fan-out pattern (described below in [Fan-Out Pattern](#fan-out-pattern)). The key: test the migration on a few files first, refine your prompt based on what goes wrong, then run at scale.

## Session Management

### When to Clear Context

Context accumulates as Claude reads files, runs commands, and exchanges messages. Long sessions with mixed tasks degrade performance.

```text
/clear between unrelated tasks:
  Task 1: Fix auth bug → /clear → Task 2: Add logging

After repeated corrections:
  If you've corrected Claude 2+ times on the same
  issue, the context is cluttered with failed approaches.
  /clear and start fresh with a better initial prompt.

After exploration:
  After a deep investigation that read many files,
  /clear before implementation to free context.
```

A clean session with a better prompt almost always outperforms a long session with accumulated corrections.

### Rewind and Checkpoints

Every action Claude takes creates a checkpoint. Double-tap **Escape** or run `/rewind` to restore conversation, code, or both to any previous state.

```text
Workflow: Try something risky
  1. Claude makes a change
  2. You don't like the result
  3. Press Esc+Esc → rewind menu
  4. Restore to before the change
  5. Try a different approach

Options in rewind:
  - Restore conversation only
  - Restore code only
  - Restore both
  - Summarize from a selected message
```

Checkpoints persist across sessions. You can close your terminal and rewind later. This encourages experimentation -- try a risky approach knowing you can always rewind.

### Named Sessions

Give sessions descriptive names with `/rename` so you can find them later:

```text
> /rename oauth-migration
> /rename debugging-memory-leak
> /rename api-v2-endpoints
```

Resume by name from the command line:

```bash
claude --resume oauth-migration
```

Treat sessions like branches -- different workstreams get separate, persistent contexts.

### Resuming Work

```bash
# Resume the most recent conversation
claude --continue

# Pick from recent conversations
claude --resume

# Resume a specific named session
claude --resume oauth-migration

# Resume a session linked to a PR
claude --from-pr 123
```

From inside a session, `/resume` switches to a different conversation without leaving Claude Code.

### Session Recap

When you return to the terminal after stepping away, Claude Code shows a one-line recap of what the session has done so far, so you don't have to scroll back to reorient. The recap generates in the background once at least three minutes have passed since the last completed turn and the terminal is unfocused, so it's ready when you switch back. It only appears once the session has at least three turns, and never twice in a row.

Run `/recap` to generate a summary on demand. It works from claude.ai and the mobile app when Remote Control is active, and is always skipped in non-interactive (`-p`) mode.

Session recap is on by default for every plan and provider. Control it three ways, in increasing precedence:

| Control                           | Effect                                                                                      |
| --------------------------------- | ------------------------------------------------------------------------------------------- |
| `/config` -> **Session recap**    | Toggle on or off interactively                                                              |
| `awaySummaryEnabled` setting      | Set to `false` to disable; same as the `/config` toggle                                     |
| `CLAUDE_CODE_ENABLE_AWAY_SUMMARY` | Set to `0` to force off or `1` to force on, overriding the setting and the `/config` toggle |

## Recurring Tasks with /loop

`/loop` re-runs a prompt or slash command on a schedule while the session stays open. Use it to poll a deploy, babysit a PR, or check back on a long-running build without retyping the same prompt. `/proactive` is an alias for the same command. Loops are session-scoped: they stop when you start a new conversation, and `claude --resume` or `claude --continue` restores any loop created within the last seven days.

### Fixed Interval vs Self-Paced

What you pass to `/loop` determines how it schedules the next run:

| What you provide     | Example                                 | Behavior                                                                  |
| -------------------- | --------------------------------------- | ------------------------------------------------------------------------- |
| Interval and prompt  | `/loop 5m check if the deploy finished` | Runs on a fixed cron schedule at that cadence                             |
| Interval and command | `/loop 20m /review-pr 1234`             | Re-runs the saved skill or command each iteration                         |
| Prompt only          | `/loop check whether CI passed`         | Claude picks the next delay (one minute to one hour) after each iteration |

For a fixed interval, the interval can lead the prompt as a bare token like `30m` or trail it as a clause like `every 2 hours`. Supported units are `s` (seconds), `m` (minutes), `h` (hours), and `d` (days). Cron has one-minute granularity, so seconds round up to the nearest minute and odd intervals like `7m` or `90m` round to the nearest valid step (Claude tells you which it picked).

When you omit the interval, Claude self-paces: after each iteration it chooses a delay between one minute and one hour based on what it observed -- short waits while a build is finishing or a PR is active, longer waits when nothing is pending -- and prints the chosen delay and the reason.

### Babysit a PR Until It Merges

Run `/review-pr` (or your own PR command) on a fixed interval so each pass picks up new CI results and review comments:

```text
/loop 10m check PR 1234: poll CI, pull any failing job logs and
push a minimal fix, address new review comments and resolve the
threads, and merge once everything is green
```

Each iteration re-runs the same instruction against the current state of the PR. When CI is red, Claude diagnoses and pushes a fix; when reviewers leave comments, it addresses them; once the checks pass and nothing is outstanding, it merges. Press `Esc` to stop the loop once the PR lands.

### Wait on a Deploy, Then Verify

Poll a deploy and gate follow-up work on its success:

```text
/loop 5m check if the deploy to staging finished. if it
succeeded, run the smoke tests and stop. if it's still in
progress, report status and wait for the next iteration.
```

The loop reports progress on each pass and only runs the smoke tests once the deploy reports success. Stop it with `Esc` after the tests run, or let the seven-day expiry end it.

### Self-Paced Test-Fixing Sweep

Omit the interval to let Claude work at its own pace through a failing suite:

```text
/loop run the test suite. fix one failing test at a time,
re-run the suite after each fix, and commit when it's green.
keep going until every test passes.
```

Without a fixed interval, Claude schedules the next iteration only when there is more to do. Once the suite is provably green it stops on its own by not scheduling another wakeup. In self-paced mode Claude may also use the [Monitor tool]({{< relref "/extending/integration-patterns" >}}#the-monitor-tool) to stream a background script's output instead of re-running the prompt, which is often more responsive than polling.

### Stopping a Loop

Press `Esc` while a loop is waiting for the next iteration to clear the pending wakeup so it does not fire again. Wakeups display as "Claude resuming /loop wakeup" when they fire. A self-paced loop also ends on its own once the task is provably complete; a fixed-interval loop runs until you stop it or seven days elapse.

## Goal-Driven Sessions with /goal

Where `/loop` re-runs on a clock, `/goal` runs until a condition holds. You set a completion condition and Claude keeps working across turns without you prompting each step. After every turn, a small fast model (Haiku by default) checks whether the condition is met against what Claude has surfaced in the conversation. A "no" returns a short reason and Claude starts another turn; a "yes" clears the goal. `/goal` requires Claude Code v2.1.139 or later.

Reach for a goal when the work has a verifiable end state -- migrating every call site until the build and tests pass, working a labeled issue backlog until the queue is empty, or splitting a file until each module is under a size budget.

```text
/goal all tests in test/auth pass and the lint step is clean
```

Setting a goal starts a turn immediately with the condition as the directive, so you don't send a separate prompt. While it runs, a `◎ /goal active` indicator shows elapsed time, and the evaluator's most recent reason appears in the status view and transcript so you can see what Claude is working toward next.

| Action       | Command             | Notes                                                                                  |
| ------------ | ------------------- | -------------------------------------------------------------------------------------- |
| Set a goal   | `/goal <condition>` | One goal per session; a new condition replaces the active one                          |
| Check status | `/goal`             | Shows the condition, elapsed time, turns evaluated, token spend, and the latest reason |
| Clear a goal | `/goal clear`       | `stop`, `off`, `reset`, `none`, and `cancel` are aliases; `/clear` also removes it     |

Write the condition as something Claude's own output can demonstrate, since the evaluator reads the transcript rather than running commands or files itself. "`npm test` exits 0" works because Claude runs the tests and the result lands in the conversation. The condition can be up to 4,000 characters; to bound a run, add a clause like `or stop after 20 turns`.

Under the hood, `/goal` is a session-scoped [prompt-based Stop hook]({{< relref "/extending/hooks-cookbook" >}}). It is unavailable in untrusted workspaces, when `disableAllHooks` is set at any level, or when `allowManagedHooksOnly` is set in managed settings, and the command tells you why instead of doing nothing. Evaluator tokens bill on the small fast model and are typically negligible next to main-turn spend.

A goal that is still active when a session ends is restored on `claude --resume` or `--continue`, though the turn count, timer, and token baseline reset. `/goal` also runs non-interactively -- `claude -p "/goal ..."` runs the loop to completion in a single invocation, interruptible with Ctrl+C. Pair it with [auto mode]({{< relref "/guides/permissions-enterprise" >}}#auto-mode) so each turn runs unattended.

## Terminal Display Modes

Claude Code's `tui` setting selects how the CLI renders. The `fullscreen` renderer draws on the terminal's alternate screen buffer, like `vim` or `htop`, which removes flicker, keeps memory flat in long conversations, and adds mouse support; `default` is the classic renderer that keeps the conversation in your terminal's native scrollback. Fullscreen rendering is a research preview.

Switch renderers in a live session without losing context:

```text
/tui fullscreen   # switch to the flicker-free renderer and relaunch
/tui default      # switch back to the classic renderer
/tui              # print which renderer is active
```

Because the fullscreen renderer lives in the alternate screen buffer, your terminal's `Cmd+F` and tmux copy mode can't see the conversation. Press `Ctrl+O` to enter the transcript viewer, then `[` to write the conversation into native scrollback or `v` to open it in your editor. Inside the viewer, `?` shows the shortcut panel and `{` / `}` jump between user prompts.

Two commands shape how much you see:

- `/focus` toggles a condensed view that shows only your last prompt, a one-line summary of each tool call with edit diffstats, and the final response. The setting persists across sessions; run `/focus` again to turn it off.
- `Ctrl+O` toggles the transcript between normal and verbose, expanding tool calls and MCP activity that otherwise collapse to a single line.

| Setting / variable                     | Effect                                                                                                                                   |
| -------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| `tui`                                  | `"fullscreen"` or `"default"`; set by `/tui`. `CLAUDE_CODE_NO_FLICKER=1` is equivalent                                                   |
| `autoScrollEnabled`                    | In fullscreen, follow new output to the bottom. Set to `false` (or **Auto-scroll** off in `/config`) to keep the view where you leave it |
| `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN` | Set to `1` to force the classic renderer; takes precedence over `CLAUDE_CODE_NO_FLICKER` and the `tui` setting                           |

Background sessions opened from agent view always use the fullscreen renderer, so neither the `tui` setting nor `CLAUDE_CODE_DISABLE_ALTERNATE_SCREEN` applies to them.

## Multi-Session and Parallel Work

### Git Worktrees for Isolation

Run multiple Claude Code sessions simultaneously with full code isolation. Each worktree gets its own file state, branch, and auto-memory scope. Claude instances can't interfere with each other.

#### The `--worktree` Flag

```bash
# Start a session in an isolated worktree
claude --worktree feature-auth

# Short form
claude -w feature-auth

# Let Claude generate a name
claude --worktree
```

This creates a worktree at `.claude/worktrees/<name>/`. By default the branch is based on `origin/<default-branch>` (the `worktree.baseRef` setting, default `fresh`); set `worktree.baseRef: "head"` to branch from your local HEAD instead. On exit, the worktree is removed automatically if no changes were made. If changes exist, Claude prompts you to keep or remove it.

Add `--tmux` to launch the worktree session inside a tmux pane (`claude --worktree feature-auth --tmux`). This requires `--worktree` and auto-detects iTerm2 for native split panes. Pass `--tmux=classic` to force traditional tmux. For multi-agent pane layouts, see the [agent teams]({{< relref "/extending/agent-teams" >}}) article's tmux display mode.

#### Manual Worktrees

When you need custom branch names or non-standard worktree locations, create worktrees directly with git:

```bash
# Create isolated worktrees for parallel tasks
git worktree add ../project-feature-a -b feature-a
git worktree add ../project-bugfix bugfix-123

# Run Claude in each (separate terminals)
cd ../project-feature-a && claude
cd ../project-bugfix && claude

# Clean up when done
git worktree remove ../project-feature-a
```

### tmux Monitoring Layouts

Many developers run Claude Code inside tmux with dedicated panes for monitoring. The core idea: a test runner or dev server in a side pane gives you an independent verification channel that updates in real time as Claude edits files, without consuming Claude's tool calls.

#### Watch Mode Test Runners

A filesystem watcher re-runs tests automatically whenever Claude saves a file:

```bash
# JavaScript/TypeScript
jest --watch          # or vitest (watch mode is its default)

# Go
find . -name '*.go' | entr -c go test ./...

# Python
ptw                   # pytest-watch

# Rust
cargo watch -x test
```

The watcher detects Claude's file writes and re-runs affected tests within seconds. You see raw test output -- pass/fail, stack traces, timing -- without relying on Claude to report results accurately. This matters during long autonomous runs: you spot a wrong approach in the test output before Claude commits to a fix path.

Claude can still run tests itself via the Bash tool. The watch pane is supplementary -- it provides always-on visibility that runs regardless of what Claude is doing.

#### Common Pane Layouts

A typical four-pane layout:

```text
+----------------------------+-------------+
|                            | Dev server  |
|   Claude Code (main)       | (npm run    |
|                            |  dev)       |
+----------------------------+-------------+
| Git / shell                | Test runner |
|                            | (--watch)   |
+----------------------------+-------------+
```

A simpler two-pane split works when you only need one monitoring channel:

```text
+-------------------+-------------------+
|                   |                   |
|   Claude Code     |  Test watcher     |
|                   |                   |
+-------------------+-------------------+
```

Other panes developers pair with Claude Code:

- **Dev server with live reload** -- `npm run dev`, `vite`, `next dev`. Claude's edits trigger hot reload; you see errors in the server output as they happen.
- **Log tailing** -- `tail -f logs/app.log` or `docker logs -f <container>`.
- **Token monitoring** -- tmux status bar plugins like `tmux-claude-live` display token usage, burn rate, and cost with color-coded warnings.

#### Example Session Script

```bash
#!/bin/bash
SESSION="claude-dev"
DIR="$(pwd)"

if tmux has-session -t "$SESSION" 2>/dev/null; then
    exec tmux attach -t "$SESSION"
fi

# -P -F '#{pane_id}' returns the ID of each pane as it's created,
# so send-keys targets the right pane regardless of base-index config.
CLAUDE=$(tmux new-session -d -s "$SESSION" -c "$DIR" -P -F '#{pane_id}')
tmux send-keys -t "$CLAUDE" "claude" Enter

# Test watcher (right side, 35% width)
TESTS=$(tmux split-window -h -t "$CLAUDE" -c "$DIR" -p 35 -P -F '#{pane_id}')
tmux send-keys -t "$TESTS" "npm run test:watch" Enter

# Dev server (bottom right, 50% of test pane height)
DEV=$(tmux split-window -v -t "$TESTS" -c "$DIR" -p 50 -P -F '#{pane_id}')
tmux send-keys -t "$DEV" "npm run dev" Enter

# Focus Claude pane
tmux select-pane -t "$CLAUDE"

tmux attach -t "$SESSION"
```

#### Letting Claude Read Pane Output

Claude understands tmux commands. You can tell it to read output from another pane:

```text
"check the test output in the other tmux pane using tmux capture-pane"
```

Claude discovers available panes with `tmux list-panes`, reads the watcher's output with `capture-pane`, then acts on the failures it finds. This separates the test-running process from Claude's execution context -- the watcher runs continuously while Claude reads its output on demand.

### Headless Mode for Automation

`claude -p "prompt"` runs Claude without an interactive session -- useful for CI pipelines, pre-commit hooks, and scripts:

```bash
# One-off queries
claude -p "explain what this project does"

# Structured output for scripts
claude -p "list all API endpoints" --output-format json

# As a linter in your build process
claude -p "look at the changes vs main and report any
issues related to typos" --output-format text

# Pipe data through Claude
cat build-error.txt | claude -p "explain the root cause
of this build error" > explanation.txt
```

Add Claude to your build scripts:

```json
{
  "scripts": {
    "lint:claude": "claude -p 'review changes vs main for typos and style issues'"
  }
}
```

### Fan-Out Pattern

For large-scale migrations or batch operations, distribute work across parallel Claude invocations:

```text
Step 1: Generate task list
  "list all Python files that need migrating to the
   new API"

Step 2: Script the fan-out
```

```bash
for file in $(cat files.txt); do
  claude -p "migrate $file from React to Vue. Return OK or FAIL." \
    --allowedTools "Edit,Bash(git commit *)" &
done
wait
```

```text
Step 3: Test on a few files first
  Run on 2-3 files, refine the prompt based on
  what goes wrong, then run at scale.
```

The `--allowedTools` flag restricts what Claude can do when running unattended.

## Subagent Patterns

### Investigation Without Context Pollution

Codebase exploration reads many files, which fills your context. Delegating research to subagents keeps your main context clean for implementation:

```text
"use subagents to investigate how our authentication
 system handles token refresh, and whether we have
 any existing OAuth utilities I should reuse"
```

The subagent explores in a separate context window, reads as many files as it needs, and reports back a summary. Your main context stays clean.

### Post-Implementation Verification

After Claude implements something, use a subagent for review:

```text
"use a subagent to review this code for edge cases
 and security issues"
```

The review happens in fresh context without the implementation bias of the current session.

### When Not to Use Subagents

Opus 4.6 has a strong tendency to spawn subagents even when a direct approach would be faster:

```text
Overkill (subagent for a simple search):
  Claude spawns a subagent to grep for a function name

Appropriate (direct approach):
  "just grep for ConfigManager directly, don't
   use a subagent"
```

Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams. For simple searches, sequential operations, and single-file edits, work directly.

## Common Failure Patterns

**The kitchen-sink session** -- Starting with one task, then asking something unrelated, then going back. Context fills with irrelevant information.

> Fix: `/clear` between unrelated tasks.

**Correcting over and over** -- Claude does something wrong, you correct, still wrong, correct again. Context is polluted with failed approaches.

> Fix: After two corrections, `/clear` and write a better initial prompt.

**The trust-then-verify gap** -- Claude produces plausible-looking code that doesn't handle edge cases.

> Fix: Always provide verification (tests, scripts, screenshots). If you can't verify it, don't ship it.

**The infinite exploration** -- Asking Claude to "investigate" without scoping it. Claude reads hundreds of files, filling context.

> Fix: Scope investigations narrowly or use subagents.

**The over-specified CLAUDE.md** -- CLAUDE.md is too long, important rules get lost in noise.

> Fix: Prune ruthlessly. If Claude already does something without the instruction, delete it.

## Best Practices

1. **Give Claude verification** -- Tests, linters, build commands, screenshots. This is the single highest-leverage pattern.

2. **Separate exploration from implementation** -- Use plan mode to understand the codebase before writing code.

3. **Clear context between tasks** -- `/clear` is your friend. A clean session with a good prompt beats a long session with accumulated noise.

4. **Use named sessions** -- `/rename` your sessions so you can find and resume them. Treat sessions like branches.

5. **Iterate in small steps** -- Review each change before moving on. Catch misunderstandings early.

6. **Use subagents for research** -- Keep your main context clean for implementation by delegating exploration.

7. **Rewind freely** -- Checkpoints are cheap. Try risky approaches knowing you can always rewind.

8. **Match the workflow to the task** -- Small fixes don't need planning. Large features don't need to be one-shot. Use the pattern that fits.

9. **Write tests first for durable requirements** -- Tests survive context transitions, session boundaries, and compaction.

10. **Don't fight -- restart** -- If a session has gone sideways after multiple corrections, start fresh. A clean session with lessons learned is faster than continuing to patch.

## References

- [Best Practices (Claude Code Docs)](https://code.claude.com/docs/en/best-practices) -- Official best practices guide
- [Common Workflows (Claude Code Docs)](https://code.claude.com/docs/en/common-workflows) -- Step-by-step workflow recipes
- [Scheduled Tasks (Claude Code Docs)](https://code.claude.com/docs/en/scheduled-tasks) -- `/loop` interval syntax, self-pacing, and stopping behavior
- [Effective Prompting Article]({{< relref "effective-prompting" >}}) -- Structuring requests for better results
- [Context Management Article]({{< relref "/internals/context-management" >}}) -- Working within the token budget
- [Extension Mechanisms Article]({{< relref "/extending/extension-mechanisms" >}}) -- Subagents, skills, and MCP servers
