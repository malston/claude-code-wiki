# Effective Prompting: Getting Better Results from Claude Code

## Executive Summary

The quality of your results from Claude Code depends heavily on how you structure your requests. Claude Code's latest models (Opus 4.6, Sonnet 4.5) follow instructions precisely -- which means vague prompts get vague results and specific prompts get specific results. Understanding a few key patterns dramatically improves outcomes.

| Principle                    | Impact                                          | Effort   |
| ---------------------------- | ----------------------------------------------- | -------- |
| **Be explicit, not vague**   | Biggest single improvement in result quality    | Low      |
| **Action over suggestion**   | Gets implementation instead of recommendations  | Low      |
| **Provide context ("why")**  | Helps Claude generalize and make good choices   | Low      |
| **Reference specific code**  | Eliminates guesswork and speeds up responses    | Low      |
| **Decompose large tasks**    | Reduces errors, enables course correction       | Medium   |
| **Use CLAUDE.md well**       | Persistent rules applied to every message       | One-time |
| **Manage multi-window work** | Enables tasks that span beyond a single session | Medium   |

---

## Table of Contents

- [How Claude Code Processes Your Messages](#how-claude-code-processes-your-messages)
- [The Fundamentals](#the-fundamentals)
  - [Be Explicit, Not Vague](#be-explicit-not-vague)
  - [Action vs Suggestion](#action-vs-suggestion)
  - [Provide Context and Motivation](#provide-context-and-motivation)
  - [Reference Specific Code](#reference-specific-code)
- [Task Decomposition](#task-decomposition)
  - [When to Decompose](#when-to-decompose)
  - [The Iterative Loop](#the-iterative-loop)
  - [Plan Mode for Complex Work](#plan-mode-for-complex-work)
- [CLAUDE.md: Persistent Prompting](#claudemd-persistent-prompting)
  - [What Goes in CLAUDE.md](#what-goes-in-claudemd)
  - [What Doesn't Belong in CLAUDE.md](#what-doesnt-belong-in-claudemd)
  - [Keeping It Concise](#keeping-it-concise)
- [Working Across Context Windows](#working-across-context-windows)
  - [Tests-First Strategy](#tests-first-strategy)
  - [State Files and Progress Notes](#state-files-and-progress-notes)
  - [Starting Fresh vs Compaction](#starting-fresh-vs-compaction)
- [Directing Tool Usage](#directing-tool-usage)
  - [Subagent Delegation](#subagent-delegation)
  - [Parallel Operations](#parallel-operations)
  - [When Claude Over-Explores](#when-claude-over-explores)
- [Common Anti-Patterns](#common-anti-patterns)
- [Best Practices Summary](#best-practices-summary)
- [References](#references)

---

## How Claude Code Processes Your Messages

Every message you type becomes part of an API call that includes the full system prompt, entire conversation history, and your new message. Claude reads all of this -- the system prompt instructions, your CLAUDE.md rules, the skill catalog, every previous turn -- before generating a response.

```
What Claude sees when you send a message:
┌──────────────────────────────────────────────────┐
│ System Prompt (~12,000-20,000 tokens)            │
│ ├── Core behavior rules                          │
│ ├── Tool definitions (Read, Edit, Bash, etc.)    │
│ ├── CLAUDE.md files (your persistent rules)      │
│ ├── Skill catalog (available skills)             │
│ └── Environment context (git, OS, directory)     │
├──────────────────────────────────────────────────┤
│ Conversation History (grows each turn)           │
│ ├── Your previous messages                       │
│ ├── Claude's responses                           │
│ ├── Tool calls and their results                 │
│ └── File contents that were read                 │
├──────────────────────────────────────────────────┤
│ Your New Message  ← this is what you just typed  │
└──────────────────────────────────────────────────┘
```

This has practical implications:

1. **Claude already knows your rules** -- Your CLAUDE.md instructions are literally in the prompt. You don't need to repeat them in every message.
2. **Claude has full conversation context** -- It remembers what you discussed earlier in the session. You can say "fix the issue we just discussed" and Claude knows what you mean.
3. **File contents are in context** -- If Claude read a file earlier, that content is still in the conversation. You don't need to tell it to read the file again (unless the file changed).
4. **Context is finite** -- The conversation history grows with each turn. Very long sessions eventually trigger [compaction](claude-code-context-management.md), which summarizes older turns. New sessions start with fresh context.

---

## The Fundamentals

### Be Explicit, Not Vague

Claude Code's models follow instructions precisely. Vague prompts leave room for interpretation; specific prompts get specific results.

```
Vague (Claude has to guess what you want):
  "make the auth better"

Specific (Claude knows exactly what to do):
  "add rate limiting to the login endpoint -- reject after 5 failed
   attempts within 10 minutes, return 429 with a Retry-After header"
```

```
Vague:
  "clean up this code"

Specific:
  "extract the database query logic from handleRequest() in
   server.go into a separate function"
```

```
Vague:
  "write some tests"

Specific:
  "add tests for the ParseConfig function in config_test.go
   covering: valid YAML, missing required fields, and invalid
   port numbers"
```

The pattern: describe **what** you want, **where** it should happen, and any **constraints** that matter.

If you want Claude to go above and beyond, say so explicitly. Instead of "create a dashboard," try "create a dashboard -- include as many relevant features and interactions as possible." Claude won't infer ambition from a brief request.

### Action vs Suggestion

A subtle but important distinction: how you phrase a request determines whether Claude acts or advises.

```
Gets suggestions (Claude will recommend, not implement):
  "can you suggest some improvements to this function?"
  "what changes would you recommend for the error handling?"
  "how should I refactor the authentication module?"

Gets action (Claude will make the changes):
  "improve this function's error handling"
  "refactor the authentication module to use middleware"
  "fix the race condition in the connection pool"
```

If you say "can you suggest," Claude takes you literally and suggests. If you want changes made, use imperative language: "fix," "add," "change," "refactor," "implement."

This also applies to exploration vs implementation:

```
Exploration (Claude investigates and reports):
  "how does the caching layer work in this codebase?"
  "what's causing the test failure in auth_test.go?"

Implementation (Claude investigates and acts):
  "fix the test failure in auth_test.go"
  "add caching to the user lookup endpoint"
```

Both are valid -- just be intentional about which mode you want.

### Provide Context and Motivation

Telling Claude **why** you want something helps it make better decisions, especially when judgment calls arise.

```
Without context (Claude follows the letter):
  "never use fmt.Println in this codebase"

With context (Claude follows the spirit):
  "use the structured logger instead of fmt.Println --
   we need all output to go through our log aggregation
   pipeline so we can search and filter in production"
```

With the context, Claude understands the underlying goal. If it encounters a situation your rule doesn't cover (say, `log.Println`), it can reason that the same principle applies.

```
Without context:
  "split this into two files"

With context:
  "split this into two files -- the handler logic and the
   database queries are tangled together, making it hard
   to test the handlers without a real database"
```

The context helps Claude make the right call about where to draw the boundary.

### Reference Specific Code

When you can point Claude to exact locations, everything gets faster and more accurate.

```
Imprecise (Claude has to search):
  "fix the nil pointer bug"

Precise (Claude goes straight to the issue):
  "fix the nil pointer in auth.go:47 -- the user object
   can be nil when the token is expired"
```

```
Imprecise:
  "update the config struct"

Precise:
  "add a Timeout field to the ServerConfig struct in
   config/types.go, default 30 seconds"
```

Useful specifics to include:

- **File paths** -- `server/handler.go` not "the handler file"
- **Function names** -- `ParseConfig()` not "the config parser"
- **Line numbers** -- `auth.go:47` when you know them
- **Error messages** -- Paste the actual error, don't paraphrase
- **Expected behavior** -- "should return 404" not "doesn't work right"

---

## Task Decomposition

### When to Decompose

Not every task needs decomposition. Here's a quick decision guide:

```
Is the task straightforward and localized?
│
├── YES (single file, clear change) → One message is fine
│   Examples: "fix the typo on line 12"
│             "add a Timeout field to Config"
│             "rename processData to transformRecords"
│
└── NO (multiple files, unclear scope, or new feature) →
    Consider decomposition
    │
    ├── Do you know the approach? → Break into steps yourself
    │   "First, add the database migration for the new table.
    │    Then create the model. Then add the API endpoint."
    │
    └── Unsure of approach? → Use plan mode
        "I want to add OAuth support to the API"
        → Claude explores the codebase and proposes a plan
```

Large, ambiguous tasks are where Claude Code is most likely to make mistakes or go down the wrong path. Breaking them apart gives you checkpoints to verify and course-correct.

### The Iterative Loop

The most effective Claude Code workflow is iterative, not one-shot:

```
1. Give a focused instruction
       │
2. Review the result
       │
3. Course-correct or continue
       │
   ┌───┴───┐
   │       │
  Done   Refine → back to step 1
```

Each iteration is a chance to verify Claude is on the right track. This is faster than writing one massive prompt that tries to anticipate every decision, because:

- You catch misunderstandings early
- You can change direction without wasted work
- Claude has the results of previous steps as context

```
Iteration 1: "add a /health endpoint that returns 200 OK"
  → Review: looks good, but no database check

Iteration 2: "also check the database connection in the
              health check -- return 503 if it's down"
  → Review: good, but the response body is empty

Iteration 3: "return a JSON body with status and db_connected
              fields"
  → Done
```

Three focused messages beat one long message that tries to specify everything upfront, because you can verify each piece.

### Plan Mode for Complex Work

For tasks where you're unsure about the approach, plan mode lets Claude explore the codebase and propose a strategy before writing any code.

**When plan mode helps:**

- New features that touch multiple files
- Refactors where you're not sure what's affected
- Tasks where multiple valid approaches exist
- Anything where you'd normally say "how should I approach this?"

**How it works:**

```
You: "add WebSocket support for real-time notifications"

Claude enters plan mode:
  1. Reads relevant files to understand current architecture
  2. Identifies what needs to change
  3. Proposes an approach with specific files and changes
  4. Asks for your approval before implementing

You: approve (or adjust) the plan

Claude implements the approved plan
```

The value: you review the approach before any code is written. This prevents the expensive scenario where Claude builds something significant that doesn't match what you wanted.

---

## CLAUDE.md: Persistent Prompting

CLAUDE.md files are your persistent instructions -- they're sent to Claude on every message, so they function like a prompt that never has to be repeated.

### What Goes in CLAUDE.md

Effective CLAUDE.md content includes:

- **Coding standards** -- Style rules, naming conventions, testing requirements
- **Project conventions** -- How errors are handled, how logging works, where things live
- **Workflow rules** -- Branching strategy, commit message format, PR process
- **Tool preferences** -- "Use bun instead of npm," "Use structured logger"
- **Common commands** -- Build commands, test commands, deployment commands

```
Example: project-level CLAUDE.md

# Project: API Server

## Stack
- Go 1.22, Chi router, sqlc for database queries
- PostgreSQL 16 with pgx driver
- Tests: go test with testcontainers for integration

## Conventions
- All handlers go in internal/handler/
- All database queries go in internal/db/queries/
- Error responses use the ErrResponse struct from internal/api/
- Use structured logging (slog) -- never fmt.Println

## Commands
- Run tests: go test ./...
- Run integration tests: go test -tags=integration ./...
- Generate sqlc: sqlc generate
```

This tells Claude what it needs to know on every message without you repeating it.

### What Doesn't Belong in CLAUDE.md

Avoid putting these in CLAUDE.md:

- **One-time instructions** -- If you only need it once, say it in the chat
- **Large reference documents** -- Move them to separate files and reference them when needed
- **Obvious rules** -- Don't tell Claude to "write correct code" or "follow best practices" -- it already does this
- **Contradictory rules** -- If two rules conflict, Claude has to guess which one wins

### Keeping It Concise

Every line of CLAUDE.md is re-sent on every API call. A 200-line CLAUDE.md is roughly 1,500-2,000 tokens consumed from your context window on every message. This cost is mitigated by [prompt caching](claude-code-prompt-caching.md) (90% discount after the first message), but the context window space is consumed regardless.

```
Context window budget:
┌───────────────────────────────────────┐
│ System prompt (including CLAUDE.md)   │ ← Bigger CLAUDE.md = less
│                                       │   room for everything else
│ Conversation + file contents          │
│                                       │
│ Available for new content             │
└───────────────────────────────────────┘
```

Rules of thumb:

- **User-scope CLAUDE.md** (`~/.claude/CLAUDE.md`) -- Your personal preferences that apply everywhere. Keep this focused.
- **Project-scope CLAUDE.md** (repo root) -- Project-specific standards. Only include what's specific to this project.
- **If it's longer than ~100 lines**, consider whether everything needs to be there on every message.

---

## Working Across Context Windows

For tasks that span beyond a single context window (very long sessions or multi-session work), specific prompting strategies help maintain continuity.

### Tests-First Strategy

Write tests before implementation. Tests serve as both specification and verification that survives context transitions.

```
Session 1:
  "Write tests for the user notification feature:
   - test that notifications are created on new comments
   - test that email is sent for urgent notifications
   - test that notification preferences are respected"

  → Tests written and committed

Session 2 (fresh context or after compaction):
  "Implement the user notification feature. Run the tests
   in notification_test.go to verify your implementation."

  → Claude discovers requirements from the tests themselves
```

The tests act as durable requirements -- they survive compaction, fresh sessions, and context resets.

### State Files and Progress Notes

For long-running tasks, have Claude maintain progress notes:

```
"Track your progress in progress.md as you work through
 the migration. Note what's done, what's next, and any
 issues you've found."
```

Structured state (like test results) works well in JSON:

```json
{
  "tests": [
    { "name": "auth_flow", "status": "passing" },
    { "name": "user_crud", "status": "failing", "note": "missing migration" },
    { "name": "notifications", "status": "not_started" }
  ]
}
```

Unstructured progress works well in plain text:

```
## Progress
- Completed auth module migration
- Fixed user model edge cases
- Next: investigate notification test failures
- Issue: the email service mock needs updating
```

Git also serves as natural state tracking -- commit messages and diffs tell Claude what was done in previous steps.

### Starting Fresh vs Compaction

When context gets compacted (automatically around 75-92% usage), older turns are summarized. Some detail is lost. For very long tasks, you have two strategies:

**Strategy 1: Let compaction happen**

Good for tasks where the recent context is what matters. Compaction preserves the system prompt and recent turns, summarizing older ones. This works for iterative work where each step builds on the last.

**Strategy 2: Start a fresh session**

Good for tasks with a clear checkpoint. Save state to files, commit your progress, and start a new conversation. Claude discovers state from the filesystem:

```
New session prompt:
  "Review progress.md and the recent git log. Continue
   implementing the migration from where the last session
   left off."
```

Claude's latest models are effective at discovering state from the local filesystem -- often better than relying on a compacted summary of a long conversation.

---

## Directing Tool Usage

### Subagent Delegation

Claude Code can delegate work to subagent processes that run in isolated context windows. This is powerful for parallel work, but Claude (especially Opus 4.6) sometimes over-uses subagents where a direct approach would be faster.

**When subagents help:**

- Multiple independent research tasks
- Deep analysis that would consume main context
- Parallel work on unrelated files

**When direct work is better:**

- Simple file reads or searches
- Sequential operations that share state
- Single-file edits

If you notice excessive subagent spawning, be direct:

```
"Don't use subagents for this -- just grep for the function
 name directly"

"Search for uses of ConfigManager yourself, don't delegate it"
```

### Parallel Operations

Claude can make multiple tool calls simultaneously. For independent operations, this is significantly faster:

```
"Read server.go, handler.go, and config.go -- I need to
 understand how requests flow through the system"

  → Claude reads all three files in parallel (one API call)
     instead of sequentially (three API calls)
```

You don't usually need to ask for this explicitly -- Claude parallelizes independent reads and searches naturally. But if you notice sequential behavior on clearly independent tasks, you can prompt for it: "read these files in parallel."

### When Claude Over-Explores

Opus 4.6 tends to do extensive upfront exploration -- reading many files and searching broadly before acting. This thoroughness often produces better results, but sometimes you want a faster, more targeted approach.

```
If Claude is reading too many files:
  "Just fix the typo on line 12 of config.go -- you don't
   need to read the rest of the codebase"

If Claude is over-researching:
  "I already know the approach -- just implement it as I
   described, don't investigate alternatives"

If Claude is spawning subagents for simple tasks:
  "This is a simple grep -- do it directly"
```

The pattern: tell Claude the scope of the task. If it's small, say it's small. If exploration isn't needed, say so.

---

## Common Anti-Patterns

### The Vague Request

```
Bad:  "fix the bug"
Good: "fix the nil pointer in auth.go:47 when the user
       token is expired"
```

Vague requests make Claude search for what you might mean, read files to understand context, and guess at intent. Specific requests skip all of that.

### Over-Constraining

```
Bad:  "change line 47 to read: if user != nil && user.Token !=
       '' && time.Now().Before(user.Token.Expiry) {"
       (dictating exact implementation)

Good: "handle the case where user or user.Token is nil in
       the auth check at auth.go:47"
       (stating the goal, letting Claude implement)
```

Over-constraining means writing the code in your prompt and asking Claude to type it for you. You lose Claude's ability to consider edge cases you didn't think of or find a cleaner approach.

### Fighting the Model

When Claude does something you didn't expect, the instinct is to add more rules:

```
Round 1: "add error handling" → Claude adds try/catch everywhere
Round 2: "not like that, only at the boundaries"
Round 3: "but you missed the HTTP handler"
Round 4: "and remove the ones in internal functions"
```

A single, clear prompt is better than iterative corrections:

```
"Add error handling at the HTTP handler layer only.
 Internal functions should return errors, not catch them.
 The handlers should catch errors and return appropriate
 HTTP status codes."
```

If you find yourself correcting Claude repeatedly, step back and give a clearer initial instruction rather than piling on corrections.

### Not Reading Output

Claude's tool results and error messages often contain exactly the information needed to solve a problem. A common mistake is ignoring test output, compiler errors, or log messages and asking Claude to "try again."

```
Bad:  "the test still fails, try something else"

Good: "the test fails with 'expected 200 but got 401' --
       looks like the auth middleware is running on this
       endpoint when it shouldn't be"
```

The error message tells you what's wrong. Sharing it (or letting Claude read it) leads to a targeted fix instead of random attempts.

### The Kitchen-Sink Prompt

```
Bad:  "Refactor the entire auth module, add OAuth support,
       implement rate limiting, update the tests, add
       documentation, and deploy to staging"

Good: "Let's add OAuth support to the auth module. Start
       by looking at the current auth flow and proposing
       an approach."
```

Giant prompts with multiple unrelated tasks produce worse results than focused, sequential requests. Each task deserves its own conversation turn where you can verify the result before moving on.

---

## Best Practices Summary

1. **Be specific about what, where, and why** -- Don't make Claude guess your intent. State the goal, point to the location, explain the motivation.

2. **Use imperative language for action** -- "Fix," "add," "change," "implement" get code written. "Could you suggest" gets suggestions.

3. **Iterate in small steps** -- Review each change before requesting the next. This catches misunderstandings early.

4. **Let CLAUDE.md handle recurring rules** -- If you're repeating the same instruction in every conversation, move it to CLAUDE.md.

5. **Keep CLAUDE.md concise** -- Every line costs context window space on every message. Make each line earn its place.

6. **Use plan mode for uncertain tasks** -- When you don't know the approach, let Claude explore and propose before implementing.

7. **Write tests first for long tasks** -- Tests serve as durable requirements that survive context transitions.

8. **Share error messages, don't paraphrase** -- The exact error text is more useful than your summary of it.

9. **Match scope language to task size** -- Tell Claude when something is small and targeted vs large and exploratory.

10. **Commit progress on long tasks** -- Git commits create checkpoints that survive session boundaries. Claude can discover state from the filesystem.

---

## References

- [Prompting Best Practices (Anthropic Docs)](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/claude-prompting-best-practices) -- Official prompting guide for Claude 4.x models
- [Prompt Engineering Overview](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/overview) -- General prompt engineering techniques
- [Memory System](https://code.claude.com/docs/en/memory.md) -- CLAUDE.md file hierarchy and scopes
- [Context Management Article](claude-code-context-management.md) -- Working within the token budget
- [System Prompt Article](claude-code-system-prompt.md) -- What Claude reads before your first message
- [Token Optimization Article](claude-code-token-optimization.md) -- Managing per-message token overhead
