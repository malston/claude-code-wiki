---
title: "Large Codebase Strategies"
weight: 11
---

# Large Codebase Strategies

Claude Code operates within a finite context window. On large codebases -- monorepos, enterprise services, anything with hundreds or thousands of files -- that window fills fast. When it does, Claude loses track of instructions, hallucinates file paths, and produces increasingly unreliable output.

This page covers practical strategies for staying within context budget and getting better results when the codebase is bigger than what Claude can hold in its head at once.

## The Core Problem

Every file Claude reads, every conversation turn you accumulate, and every tool result that comes back costs tokens. Claude Code's context window is a fixed budget. Once you exhaust it, auto-compaction kicks in and starts summarizing older content -- which means Claude loses detail on exactly the things it read earlier in the session.

The symptoms are predictable:

- Claude "forgets" instructions you gave earlier in the session
- File edits reference functions or types that don't exist
- Claude re-reads files it already read, burning more context
- Complex multi-file refactors break halfway through

Give Claude less to think about at any given time.

## Strategy 1: Scope Requests Tightly

The biggest context killer is asking Claude to "understand the whole codebase" before making a change. Instead, point it at specific files and use a three-step prompting pattern:

**Step 1 -- Read:** Ask Claude to read only the files relevant to the change.

```text
Read src/auth/middleware.go and src/auth/types.go.
Understand the current middleware chain and the AuthContext type.
```

**Step 2 -- Plan:** Ask Claude to plan the solution without writing code yet.

```text
I need to add rate limiting to the auth middleware.
Plan how you'd implement this -- which files change, what the interface looks like.
Don't write code yet.
```

**Step 3 -- Implement:** Ask Claude to execute the plan.

```text
Implement the rate limiting plan. Start with the middleware changes,
then update the tests.
```

Each step keeps context focused rather than pulling in everything at once. The plan step is especially important -- it forces Claude to commit to an approach before spending tokens on implementation.

## Strategy 2: Invest in CLAUDE.md

Run `/init` inside a Claude Code session so Claude scans your codebase and generates a `CLAUDE.md` file with architecture notes, conventions, and file layout. This gives Claude a compact map of the project without loading every file into context.

Go further and manually add the things Claude would otherwise need to discover by reading source files:

- Module boundaries and key interfaces
- Dependency relationships between packages
- Naming conventions and patterns
- Build and test commands
- Domain-specific terminology

A well-maintained `CLAUDE.md` means Claude starts every session with a working mental model of your project. That is far more token-efficient than Claude re-reading source files to rediscover patterns.

### What to put in CLAUDE.md for large projects

```markdown
# Architecture

- Monorepo: apps/ contains deployable services, pkg/ contains shared libraries
- All HTTP handlers live in internal/api/handlers/
- Repository pattern: interfaces in internal/domain/, implementations in internal/infra/

# Key interfaces

- pkg/middleware/auth.go -- AuthMiddleware interface, all handlers depend on it
- internal/domain/interfaces.go -- core repository contracts

# Conventions

- Error wrapping: always use fmt.Errorf("context: %w", err)
- Table-driven tests with testify/require
- Proto files in api/proto/, generated code in api/gen/

# Commands

- make test -- runs full test suite
- make lint -- golangci-lint
- make generate -- regenerates proto and mocks
```

This kind of concise map saves hundreds of tokens per session compared to Claude exploring the file tree.

### Hierarchical CLAUDE.md for large codebases

A single root `CLAUDE.md` works for small-to-medium projects. For large codebases -- monorepos, multi-service platforms, anything with distinct subsystems -- a flat file either gets too long (burning context tokens) or too shallow (missing the detail Claude needs when working in a specific module).

The solution is a nested hierarchy. Claude Code already supports this -- when it reads files in a subdirectory, it also loads any `CLAUDE.md` in that directory, layering the local context on top of the root context. You get architectural knowledge that loads on demand.

```bash
CLAUDE.md                          ← project-wide: module boundaries, shared conventions, build commands
apps/
  api-gateway/CLAUDE.md            ← gateway-specific: routing patterns, middleware chain, rate limiting config
  billing-service/CLAUDE.md        ← billing-specific: payment provider integration, idempotency patterns
pkg/
  auth/CLAUDE.md                   ← auth internals: token validation flow, RBAC model, test fixtures
  observability/CLAUDE.md          ← tracing/metrics conventions, span naming, log levels
```

**What goes where:**

The root file covers things that apply everywhere -- module layout, dependency direction, shared conventions, CI commands. Each child file covers what Claude needs to know when working _in that directory_ -- key types, entry points, dependencies on sibling modules, local test patterns, known gotchas.

The root file should reference children rather than duplicate them: "auth middleware details in `pkg/auth/CLAUDE.md`." This avoids paying for the same information twice when Claude happens to read both levels.

**Bootstrapping with parallel subagents:**

Writing these by hand across a large codebase is tedious. You can automate the initial generation by spawning parallel subagents -- one per module -- that each analyze their local scope and produce a draft `CLAUDE.md`.

The approach:

1. Write a custom command or skill that defines a standard template for what each local `CLAUDE.md` should cover: key types, entry points, inter-module dependencies, test patterns, and domain-specific notes.

2. Glob your top-level packages or service directories.

3. Spawn a subagent per directory (with worktree isolation if they'll be writing files). Each subagent reads the local code, identifies the patterns, and writes a `CLAUDE.md` following the template.

4. A root-level agent synthesizes the module-level outputs into the top-level `CLAUDE.md`, capturing cross-cutting concerns and module relationships.

This is the parallelization workflow pattern applied to documentation generation. Each subagent only needs to understand its own slice of the codebase, so context pressure stays low.

**Keeping the hierarchy current:**

These files go stale. A few maintenance strategies:

- **Hook on PR merge:** Flag when files in a directory have changed significantly but its `CLAUDE.md` hasn't been updated. A simple line-count diff threshold works as a heuristic.
- **Periodic regeneration:** Run the bootstrapping sweep on a schedule (weekly, or as a CI job) and diff the output against existing files to surface drift.
- **Convention in CLAUDE.md itself:** Add a `Last validated:` date at the top of each file so staleness is visible at a glance.

The hierarchy pays off most when the codebase has clear module boundaries with distinct domain knowledge per module. If your codebase is a tangled monolith where every change touches everything, the root `CLAUDE.md` alone may be the better investment until you untangle the architecture.

## Strategy 3: Use /batch for Wide, Parallel Changes

The `/batch` command is purpose-built for changes that touch many files with the same kind of transformation. It solves the context window problem directly -- each spawned agent gets its own isolated context window, so no single instance needs to hold the entire codebase.

### How /batch works

```text
/batch migrate all handlers in src/api/ from Express to Hono
```

1. **Research and Plan.** The orchestrator enters plan mode, launches explore agents to find all affected files, patterns, and call sites. It decomposes the work into 5--30 independent units.

2. **Spawn Workers.** After you approve the plan, one background agent launches per unit -- all in parallel. Each agent gets its own git worktree for full isolation. Each agent's prompt is self-contained: overall goal, its specific task, and codebase conventions from research.

3. **Track Progress.** The orchestrator renders a status table and updates it as agents complete. Each worker implements its unit, runs tests, and opens a pull request.

### When to use /batch

- Dependency migrations across many packages
- API contract changes and all their callers
- Consistent pattern enforcement (error handling, logging, naming)
- Replacing a library across the codebase (e.g., lodash to native)
- Adding type annotations, docstrings, or test scaffolding at scale

### When not to use /batch

- Changes with dependencies between units (use Agent Teams instead)
- Surgical changes in one area of the codebase (use a single focused session)
- Exploratory work where the approach isn't clear yet

### Getting good results from /batch

Write specific instructions. The quality of the decomposition depends on how well you describe the change:

```text
# Too vague -- poor decomposition
/batch clean up the handlers

# Specific -- good decomposition
/batch migrate all handlers in src/api/ from the old middleware.Auth()
pattern to the AuthMiddleware.Wrap() pattern. Each handler file is
one unit. Update corresponding test files.
```

Review the plan carefully before approving. If the proposed units aren't truly independent -- say two agents both need to modify the same interface file -- push back and ask for re-decomposition. Overlapping units cause merge conflicts.

Your `CLAUDE.md` and custom skills are inherited by each spawned agent, so a well-maintained project context improves every parallel worker.

### Requirements

- Git repository (worktree isolation is mandatory)
- Claude Code v2.1.63 or higher

## Strategy 4: Use Git Worktrees for Manual Parallelism

When `/batch` doesn't fit -- because the tasks aren't uniform, or you want more control -- you can manually run parallel Claude sessions using git worktrees.

```bash
# Terminal 1: feature work
claude --worktree feature-auth

# Terminal 2: bug fix (completely isolated)
claude --worktree bugfix-api-timeout

# Terminal 3: refactor (also isolated)
claude --worktree refactor-logging
```

Each session gets its own branch and working directory. No file conflicts between sessions. Each Claude instance gets a fresh context budget dedicated to its specific task.

When you exit a worktree session:

- **No changes:** worktree and branch are cleaned up automatically
- **Changes exist:** Claude prompts you to keep or remove

Add `.claude/worktrees/` to your `.gitignore` to keep things clean.

Subagents can also use worktree isolation. Ask Claude to "use worktrees for your agents" or add `isolation: worktree` to a custom subagent's frontmatter.

## Strategy 5: Be Strategic About What Claude Reads

For large Go, Java, or TypeScript codebases, Claude doesn't need to read every implementation file to understand a module's contract. Often the high-signal files are enough:

- Interface definitions (`interfaces.go`, `.d.ts` files)
- Proto/OpenAPI/GraphQL schemas
- Test files (they document expected behavior)
- Package-level documentation

Tell Claude what to read instead of letting it explore freely:

```text
Read internal/domain/interfaces.go and api/openapi.yaml.
Then implement the /users/preferences endpoint following
the existing handler patterns.
```

This approach trades completeness for focus. Claude gets exactly the context it needs without burning tokens on implementation details it doesn't need to see.

## Strategy 6: Chain Smaller Steps for Large Refactors

Rather than asking Claude to refactor an entire module in one shot, chain smaller requests where each step stays within context limits:

1. Rename the interface in file A and commit
2. Update the implementations in files B and C, commit
3. Update the callers in files D through F, commit
4. Run the full test suite and fix anything broken

Each step builds on the committed output of the previous step. If Claude's context gets heavy, you can start a fresh session -- the committed code is the handoff.

This is the chaining workflow pattern applied to context management: break the work into steps that each produce a durable artifact (a commit), so no single session needs to hold the full picture.

## Strategy 7: Use Memory and Skills for Recurring Context

### Memory

When you discover something important mid-session, ask Claude to add it to your `CLAUDE.md`:

```text
Add to CLAUDE.md: the config parser has a hidden dependency on the logger package --
always initialize logger before config in main.go
```

This persists the insight across sessions without you needing to re-explain it or re-read files to rediscover it. You can also use `/memory` to view and manage your memory files directly.

### Custom skills

If you find yourself explaining the same architectural patterns or project conventions across sessions, write a custom skill:

```text
.claude/skills/go-service-patterns/SKILL.md
```

Skills get auto-injected into context when relevant, which is far more token-efficient than Claude re-reading source files to rediscover patterns every time. One skill file with your service scaffolding conventions can replace reading 10+ existing service implementations.

## Strategy 8: Monitor Context and Compact Proactively

Don't wait for auto-compaction to kick in at ~75-92% context usage. Use `/compact` proactively at logical breakpoints:

- After completing a subtask but before starting the next one
- After a large file read that you no longer need in full detail
- When you notice Claude starting to lose track of earlier instructions

Think of `/compact` as saving your game progress -- it preserves the important state while freeing up room for the next phase of work.

For very long sessions, consider `/clear` and starting fresh. If you've committed your work, a new session with a clean context window is often more productive than pushing through with a degraded one.

## Decision Framework

| Change type                                      | Strategy                                          |
| ------------------------------------------------ | ------------------------------------------------- |
| Narrow and deep (one module, complex logic)      | Single session, tight scoping, three-step pattern |
| Wide and uniform (same change across many files) | `/batch`                                          |
| Multiple independent tasks                       | Manual worktrees (`claude --worktree`)            |
| Large refactor with ordered dependencies         | Chained smaller steps with commits                |
| Recurring patterns across sessions               | Skills and CLAUDE.md                              |
| Monorepo or multi-service codebase               | Hierarchical CLAUDE.md with per-module context    |
| Context getting heavy mid-session                | `/compact` at logical breakpoints                 |

## Further Reading

- [Context Management]({{< relref "/internals/context-management" >}}) -- how the context window works under the hood
- [Workflow Patterns]({{< relref "/guides/workflow-patterns" >}}) -- chaining, parallelization, and routing patterns
- [Effective Prompting]({{< relref "/guides/effective-prompting" >}}) -- prompting techniques that reduce context waste
- [Memory Organization]({{< relref "/guides/memory-organization" >}}) -- CLAUDE.md, memory files, and skills
- [CLAUDE.md Architecture]({{< relref "/enterprise-rollout/03-phase-1-platform-engineering/claude-md-architecture" >}}) -- enterprise patterns for hierarchical CLAUDE.md design
- [Agent Teams]({{< relref "/extending/agent-teams" >}}) -- for changes that need inter-agent coordination
