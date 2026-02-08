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
| **Parallel Sessions**         | Independent tasks, writer/reviewer split | Git worktrees, headless mode             |
| **Headless / CI Integration** | Automated checks, batch operations       | `claude -p` with structured output       |

---

## Table of Contents

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
- [Multi-Session and Parallel Work](#multi-session-and-parallel-work)
  - [Git Worktrees for Isolation](#git-worktrees-for-isolation)
  - [Headless Mode for Automation](#headless-mode-for-automation)
  - [Fan-Out Pattern](#fan-out-pattern)
- [Subagent Patterns](#subagent-patterns)
  - [Investigation Without Context Pollution](#investigation-without-context-pollution)
  - [Post-Implementation Verification](#post-implementation-verification)
  - [When Not to Use Subagents](#when-not-to-use-subagents)
- [Common Failure Patterns](#common-failure-patterns)
- [Best Practices](#best-practices)
- [References](#references)

---

## The Core Loop

Every Claude Code workflow follows the same fundamental loop:

```
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

---

## Explore-Plan-Implement

### When to Plan vs When to Just Do It

```
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

```
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

```
I want to build [brief description]. Interview me in
detail using the AskUserQuestion tool.

Ask about technical implementation, UI/UX, edge cases,
concerns, and tradeoffs. Don't ask obvious questions,
dig into the hard parts I might not have considered.

Keep interviewing until we've covered everything, then
write a complete spec to SPEC.md.
```

Then start a fresh session to implement the spec. The new session has clean context focused entirely on implementation, and you have a written spec to reference.

---

## Fix with Verification

### The Debugging Workflow

The most effective debugging pattern gives Claude the symptom, the likely location, and what "fixed" looks like:

```
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

```
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

---

## Test-Driven Development

### TDD with Claude Code

TDD is a natural fit for Claude Code because tests provide the verification loop that makes Claude most effective.

```
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

```
Session 1: Write comprehensive tests
  → Tests committed to git

Session 2 (fresh context):
  "Run the tests in notification_test.go. Implement
   whatever is needed to make them pass."
  → Claude discovers requirements from the tests
```

This pattern is especially powerful for multi-session work. See [Working Across Context Windows](claude-code-effective-prompting.md#working-across-context-windows) in the effective prompting article.

---

## Code Review

### Self-Review vs Fresh Session

Claude in the same session that wrote the code is biased -- it just produced that code and is inclined to think it's correct. A fresh session provides a genuinely different perspective.

```
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

```
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

```
Session A: Write tests for the feature
       │
Session B: Write code to pass Session A's tests
```

This separation ensures tests aren't influenced by the implementation approach.

---

## Refactoring

### Small Steps with Verification

Refactoring is safest in small, testable increments:

```
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

---

## Session Management

### When to Clear Context

Context accumulates as Claude reads files, runs commands, and exchanges messages. Long sessions with mixed tasks degrade performance.

```
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

```
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

```
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

---

## Multi-Session and Parallel Work

### Git Worktrees for Isolation

Run multiple Claude Code sessions simultaneously with full code isolation:

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

Each worktree has its own file state. Changes in one don't affect the other. Claude instances can't interfere with each other.

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

```
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

```
Step 3: Test on a few files first
  Run on 2-3 files, refine the prompt based on
  what goes wrong, then run at scale.
```

The `--allowedTools` flag restricts what Claude can do when running unattended.

---

## Subagent Patterns

### Investigation Without Context Pollution

Codebase exploration reads many files, which fills your context. Delegating research to subagents keeps your main context clean for implementation:

```
"use subagents to investigate how our authentication
 system handles token refresh, and whether we have
 any existing OAuth utilities I should reuse"
```

The subagent explores in a separate context window, reads as many files as it needs, and reports back a summary. Your main context stays clean.

### Post-Implementation Verification

After Claude implements something, use a subagent for review:

```
"use a subagent to review this code for edge cases
 and security issues"
```

The review happens in fresh context without the implementation bias of the current session.

### When Not to Use Subagents

Opus 4.6 has a strong tendency to spawn subagents even when a direct approach would be faster:

```
Overkill (subagent for a simple search):
  Claude spawns a subagent to grep for a function name

Appropriate (direct approach):
  "just grep for ConfigManager directly, don't
   use a subagent"
```

Use subagents when tasks can run in parallel, require isolated context, or involve independent workstreams. For simple searches, sequential operations, and single-file edits, work directly.

---

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

---

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

---

## References

- [Best Practices (Claude Code Docs)](https://code.claude.com/docs/en/best-practices) -- Official best practices guide
- [Common Workflows (Claude Code Docs)](https://code.claude.com/docs/en/common-workflows) -- Step-by-step workflow recipes
- [Effective Prompting Article](claude-code-effective-prompting.md) -- Structuring requests for better results
- [Context Management Article](claude-code-context-management.md) -- Working within the token budget
- [Extension Mechanisms Article](claude-code-extension-mechanisms.md) -- Subagents, skills, and MCP servers
