---
title: "Developer Path"
weight: 1
---

# Developer Path

A structured progression from basic Claude Code usage to advanced workflows. Each module builds on the previous one -- work through them in order.

| Module                                                          | Focus                                              | Prerequisites |
| --------------------------------------------------------------- | -------------------------------------------------- | ------------- |
| [1. Prompting Foundations](#module-1-prompting-foundations)     | Writing requests that produce correct code         | None          |
| [2. The Verification Loop](#module-2-the-verification-loop)     | Building feedback into every task                  | Module 1      |
| [3. Test-Driven Development](#module-3-test-driven-development) | Using tests as requirements for Claude             | Module 2      |
| [4. Debugging with Claude](#module-4-debugging-with-claude)     | Systematic troubleshooting when things break       | Modules 2-3   |
| [5. Context Management](#module-5-context-management)           | Understanding what Claude sees and remembers       | Modules 1-4   |
| [6. Extending Claude Code](#module-6-extending-claude-code)     | Subagents, skills, MCP servers, and custom tooling | Module 5      |

## Exercise Materials

Clone the exercise repo for hands-on practice alongside each module:

```bash
git clone https://github.com/malston/training-dev-exercises.git ~/code/training-dev-exercises
cd ~/code/training-dev-exercises
```

Each module has a matching exercise directory (`modules/01-prompting/`, `modules/02-verification/`, etc.) with instructions, starter code, and scenarios.

## Module 1: Prompting Foundations

**Goal:** Write requests that produce correct, specific code on the first attempt.

### Key Concepts

**Be explicit about what, where, and why.** Claude works from what you tell it. Vague requests produce vague results.

```text
Bad:  "make auth better"
Good: "Add rate limiting to the login endpoint -- 5 attempts per 10 minutes
       per IP. Return HTTP 429 with a Retry-After header."
```

**Use imperative language for action, questions for advice.** "Fix the bug in parseConfig" triggers code changes. "How should I approach fixing parseConfig?" triggers a discussion.

**Provide context and motivation.** Explaining _why_ you need something helps Claude make better design decisions:

```text
"Add a circuit breaker to the payment service client.
We're seeing cascading failures when the payment API goes down --
the retry storms are taking out the order service too."
```

**Point Claude at the right files.** Instead of letting Claude search, tell it where to look:

```text
"The validation logic is in src/validators/order.ts.
Add a check that shipping_address.country is in the
supported_countries list from config/regions.json."
```

### Exercises

**Starter materials:** `modules/01-prompting/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- three vague prompts to rewrite, a feature requirements list for the task tracker, and example rewrites for comparison.

1. Rewrite three vague prompts ("Add filtering to the task list", "Make the API faster", "Improve the error handling") to be specific enough for Claude to implement on the first attempt. Name the files, the behavior, and the verification step. Compare against `examples.md`.
2. Pick a feature from `requirements.md` (task search, due dates, comments, or bulk status update) and write a prompt that includes the exact file, the behavior, the reason, and how to verify it works. Run it in Claude Code and evaluate whether it produced correct code on the first attempt.
3. Choose another requirement and write two versions: an imperative prompt ("Add X to Y") and a question ("How should I approach adding X?"). Run both (use `/clear` between them) and compare what each produces.

### Reference

- [Effective Prompting]({{< relref "guides/effective-prompting" >}}) -- Full guide on prompt specificity, task decomposition, and anti-patterns

## Module 2: The Verification Loop

**Goal:** Build a workflow where Claude gets concrete feedback after every change.

### Key Concepts

The core Claude Code workflow is a four-step loop:

```text
Instruct → Claude acts → Review output → Course-correct
```

The highest-leverage improvement you can make is giving Claude _something to verify against_. Without verification, Claude guesses whether it succeeded. With verification, it knows.

**Types of verification:**

- **Tests** -- the strongest form. Claude runs them, sees pass/fail, adjusts.
- **Compiler/linter output** -- immediate feedback on syntax and type errors.
- **`hugo serve` or equivalent** -- for content/frontend work, visual confirmation.
- **Explicit checks** -- "After making the change, run `curl localhost:8080/health` and confirm the response includes `version`."

**Plan before you execute.** For uncertain work, enter plan mode (Shift+Tab) and let Claude research before committing to an approach. Separate planning from implementation to avoid wasted work.

**Clear context between unrelated tasks.** Use `/clear` when switching topics. Accumulated context from a previous task adds noise and burns tokens.

### Exercises

**Starter materials:** `modules/02-verification/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- uses the `feature/task-search` branch with a broken search implementation and failing tests.

1. Switch to the `feature/task-search` branch. The search endpoint exists but has a bug and tests are failing. Write a prompt that includes an explicit verification step: "Fix the search in TaskController.java, then run `./mvnw test` and fix any failures."
2. Stay on `feature/task-search`. Use plan mode (Shift+Tab) to investigate: "How is the search feature implemented? What's broken and what's missing?" Then switch to implementation with specific instructions based on what you learned.
3. Complete the search fix, then run `/clear` and start the "Due Dates" feature from `modules/01-prompting/requirements.md`. Notice how `/clear` prevents the search context from polluting the due dates task.

### Reference

- [Workflow Patterns]({{< relref "guides/workflow-patterns" >}}) -- Explore-plan-implement, fix-with-verification, session management, parallel work

## Module 3: Test-Driven Development

**Goal:** Use tests as concrete requirements that survive context changes and session boundaries.

### Key Concepts

**Write the test first.** A failing test is the most precise requirement you can give Claude. It defines exactly what "done" looks like:

```text
"Write a test in tests/test_parser.py that:
1. Parses a CSV with a missing header row
2. Expects a MissingHeaderError with the filename in the message
3. Run the test -- it should fail because the error type doesn't exist yet.
Then implement the minimal code to make it pass."
```

**Red-Green-Refactor cycle:**

1. **Red** -- Write a test that fails. Confirm it fails for the right reason.
2. **Green** -- Write the minimum code to make it pass. No more.
3. **Refactor** -- Clean up while keeping tests green.

**Tests survive context compaction.** Conversation history gets summarized during long sessions, but test files remain on disk. When Claude reads them in the next turn, it recovers the full specification.

**Avoid tests that only exercise mock behavior.** If you mock a dependency, make sure the test still validates real logic in your code. When possible, prefer real dependencies: testcontainers, httptest servers, in-memory databases.

**Never delete a failing test.** A failing test means either the code has a bug or the test needs updating. Deleting it hides problems.

### Exercises

**Starter materials:** `modules/03-tdd/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- includes test stubs for a statistics service (Red phase) and a mock test to replace with real dependencies.

1. Run `./mvnw test -Dtest=TaskStatisticsServiceTest` -- the tests fail because the methods throw `UnsupportedOperationException` (Red). Ask Claude to implement `TaskStatisticsService` with the minimum code to make them pass (Green). Refactor if needed while keeping tests green.
2. Write tests for a "Task Comments" feature (from `modules/01-prompting/requirements.md`) in one Claude session. Run `/clear`, then in a fresh session ask Claude to implement the code to make those tests pass. The tests survive across sessions because they're on disk.
3. Open `TaskServiceMockTest.java` -- it uses Mockito to mock `TaskRepository` and only tests mock behavior. Rewrite it to use the real repository with `@SpringBootTest`. Does the real-dependency test catch issues the mock test misses?

### Reference

- [Testing Strategies]({{< relref "guides/testing-strategies" >}}) -- TDD patterns, context isolation, automating test runs with hooks

## Module 4: Debugging with Claude

**Goal:** Diagnose and fix bugs systematically instead of guessing.

### Key Concepts

**The debugging framework has four phases:**

```text
1. Understand -- What should happen? What actually happens?
2. Reproduce -- Can you trigger the bug reliably? Write a failing test if possible.
3. Investigate -- Trace backward from the symptom to the root cause.
4. Fix and verify -- Change the code, confirm the fix, check for regressions.
```

**Share the actual error.** Copy the full stack trace, error message, and relevant log output. Don't paraphrase -- line numbers and error codes are diagnostic information Claude needs.

```text
Bad:  "The API is returning an error"
Good: "POST /api/orders returns 500. The log shows:
       NullPointerException at OrderService.java:142
       order.getShippingAddress().getZipCode() -- address is null
       when guest checkout skips the address step."
```

**One hypothesis at a time.** When trying fixes, change one thing, test, and evaluate. Multiple simultaneous changes hide which fix actually worked.

**After 2 failed attempts, start fresh.** Use `/clear` and re-approach. Context polluted with dead ends makes Claude repeat the same failed strategies.

### Exercises

**Starter materials:** `modules/04-debugging/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- uses the `buggy` branch with 4 intentional bugs and a BUGS.md describing symptoms.

1. Switch to the `buggy` branch and run `./mvnw spring-boot:run`. It fails (Bug #4). Copy the full stack trace and share it with Claude -- compare this against a vague prompt like "the app won't start."
2. After fixing Bug #4, reproduce Bug #1 (wrong HTTP status on create) with `curl`. Ask Claude to trace backward from the symptom: "POST /api/tasks returns 200 instead of 201. Trace the response path from the controller method to find where the status code is set."
3. Pick Bug #2 or #3 from BUGS.md. Before asking Claude to fix it, write a failing test that captures the bug, then share only the test output and let Claude fix it from there.

### Reference

- [Debugging Techniques]({{< relref "guides/debugging-techniques" >}}) -- The full debugging framework, tracing techniques, common bug categories, anti-patterns

## Module 5: Context Management

**Goal:** Understand what Claude can see, what it forgets, and how to optimize for long sessions.

### Key Concepts

**Every message has a cost.** Claude's context window (200K tokens) holds the system prompt, conversation history, and tool results. File reads are the biggest variable cost -- a 1,000-line file consumes ~8,000-10,000 tokens.

**Compaction is lossy.** When the context window fills (75-92%), older messages get summarized automatically. Key decisions and recent turns are preserved, but details from earlier in the session are lost.

**What survives compaction:**

- CLAUDE.md instructions (re-injected every message)
- Test files and code on disk (available to re-read, though earlier reads are lost from context)
- Recent conversation turns

**What doesn't survive:**

- Detailed discussion from early in the session
- Specific error messages you shared earlier
- Context from file reads that were summarized away

**Strategies for long sessions:**

- Write key decisions to CLAUDE.md or project files -- they persist across compaction and sessions
- Use subagents for research -- a 40-turn investigation costs ~500 tokens as a summary vs. ~20K in the main context
- Read targeted line ranges instead of whole files when you know where the relevant code is
- Use `/compact` proactively before starting a different phase of work

### Exercises

**Starter materials:** `modules/05-context/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- exercises for measuring token costs, delegating to subagents, and persisting decisions.

1. Start a Claude session in the task tracker repo. Ask Claude to read `TaskController.java` and note the token count before and after. Then ask it to read the entire `backend/src/main/java/com/example/tasktracker/` directory. How many tokens does each file read cost?
2. Ask Claude to delegate research to a subagent: "Use a subagent to explore the backend codebase and summarize the design patterns, code organization, and conventions." Then ask the same question directly (without a subagent) and compare the context cost of each approach.
3. Make a design decision during your session (e.g., "use DTOs instead of exposing entities directly"). Write it to CLAUDE.md, run `/compact`, then ask Claude about the decision. It survives because it's on disk. Compare: what happens if you only discuss the decision in conversation?

### Reference

- [Context Management]({{< relref "internals/context-management" >}}) -- Full deep dive on context window mechanics, compaction, and subagent isolation

## Module 6: Extending Claude Code

**Goal:** Use subagents, skills, and MCP servers to scale what Claude can do.

### Key Concepts

**Three extension types, three different purposes:**

| Extension   | What it does                                    | Context impact                                         | Use when                                 |
| ----------- | ----------------------------------------------- | ------------------------------------------------------ | ---------------------------------------- |
| Subagents   | Isolated AI instances with their own context    | Isolated -- ~500 tokens summary                        | Multi-turn work you want to delegate     |
| Skills      | Inject knowledge and workflow into main context | Adds to main context                                   | You want Claude to follow a pattern      |
| MCP Servers | External stateless tools                        | Tool definitions in system prompt + results in context | You need external data (APIs, databases) |

**Subagents save context.** Each subagent gets its own 200K token window. A 40-turn investigation delegated to a subagent returns a summary to your main context -- 97.5% savings.

**Skills inject behavior.** A skill auto-activates based on its description, then injects instructions into the main context. Use skills for "how to approach this kind of task" -- coding standards, review checklists, workflow patterns.

**MCP servers provide external data.** Each call is stateless and fresh. Use MCP servers for things Claude can't do alone: querying databases, calling APIs, reading browser state.

**The Lens + Reviewer pattern.** A lightweight skill watches for relevant situations (the "lens"), then a subagent does deep investigation on demand (the "reviewer"). This gives broad awareness with focused depth.

### Exercises

**Starter materials:** `modules/06-extensions/` in the [exercise repo](https://github.com/malston/training-dev-exercises) -- uses the security module for subagent exploration and includes example slash commands in `.claude/commands/`.

1. Delegate research to a subagent: "Use a subagent to explore the security package (`AuthService.java`, `AuthController.java`) and explain how passwords are stored, how sessions work, and what vulnerabilities exist." Compare the context cost to asking the same question directly.
2. Read the example slash commands in `.claude/commands/`. Try running `/project:review-security`. Then create your own command: write a `.claude/commands/add-endpoint.md` that instructs Claude to add a REST endpoint following the patterns in `TaskController`.
3. Compose extensions: write a `.claude/commands/security-audit.md` that delegates password hashing review to one subagent and session management review to another, then consolidates findings. Compare the quality and context cost against a single prompt asking for everything at once.

### Reference

- [Extension Mechanisms]({{< relref "extending/extension-mechanisms" >}}) -- Subagents, skills, MCP servers architecture, the Lens + Reviewer pattern
- [Custom Extensions]({{< relref "extending/custom-extensions" >}}) -- Building your own subagents, skills, and plugins

## What's Next

After completing this path, you should be able to:

- Write prompts that produce correct code without iteration
- Use TDD to give Claude concrete requirements
- Debug systematically instead of guessing
- Manage context for productive long sessions
- Extend Claude Code with subagents and skills

For team-level adoption and infrastructure concerns, see the [Platform Engineer Path]({{< relref "training/platform-engineer-path" >}}).
