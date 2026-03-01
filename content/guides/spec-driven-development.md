---
title: "Spec-Driven Development: Structured Planning for AI-Assisted Projects"
linkTitle: "Spec-Driven Development"
weight: 9
---

# Spec-Driven Development: Structured Planning for AI-Assisted Projects

## Executive Summary

Spec-driven development (SDD) is the practice of creating structured specifications _before_ writing code, then using those specs as context-engineered inputs for AI agents. Instead of describing what you want and hoping for good output, you decompose work into researched, planned, verified phases -- each executed in a fresh context window where quality stays high. This article covers the core principles, the development cycle, practical patterns, and how tools like Superpowers, GSD, and GitHub Spec Kit implement them.

| Principle                        | What It Means                                                     | Why It Matters                                        |
| -------------------------------- | ----------------------------------------------------------------- | ----------------------------------------------------- |
| **Specs are prompts**            | Specifications are context engineering, not documentation         | AI agents produce better output from structured input |
| **Fresh contexts prevent decay** | Each task gets an isolated context window                         | Quality stays consistent regardless of project size   |
| **Atomic decomposition**         | Work is broken into small, independent tasks                      | Targets ~50% context usage where quality is highest   |
| **Goal-backward verification**   | Verify that goals are achieved, not only that tasks are completed | A passing task list doesn't mean the feature works    |
| **Structured handoffs**          | Plans, summaries, and state files carry knowledge across sessions | No tribal knowledge lost between context windows      |

## Table of Contents

- [Spec-Driven Development: Structured Planning for AI-Assisted Projects](#spec-driven-development-structured-planning-for-ai-assisted-projects)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [The Problem SDD Solves](#the-problem-sdd-solves)
    - [Context Rot](#context-rot)
    - [The Vibecoding Trap](#the-vibecoding-trap)
  - [Core Principles](#core-principles)
    - [Specifications Are Prompts](#specifications-are-prompts)
    - [Fresh Contexts Prevent Quality Decay](#fresh-contexts-prevent-quality-decay)
    - [Atomic Decomposition Maintains Quality](#atomic-decomposition-maintains-quality)
    - [Goal-Backward Verification](#goal-backward-verification)
    - [Structured Handoffs Bridge Context Boundaries](#structured-handoffs-bridge-context-boundaries)
  - [The Development Cycle](#the-development-cycle)
    - [Research Phase](#research-phase)
    - [Specification Phase](#specification-phase)
    - [Planning Phase](#planning-phase)
    - [Execution Phase](#execution-phase)
    - [Verification Phase](#verification-phase)
    - [Iteration](#iteration)
  - [Practical Patterns](#practical-patterns)
    - [The Interview Pattern](#the-interview-pattern)
    - [Dependency Graphs and Execution Waves](#dependency-graphs-and-execution-waves)
    - [Atomic Commits](#atomic-commits)
    - [Checkpoint Protocols](#checkpoint-protocols)
    - [State Files for Continuity](#state-files-for-continuity)
  - [Tool Landscape](#tool-landscape)
    - [Superpowers Skills](#superpowers-skills)
    - [GSD (Get Shit Done)](#gsd-get-shit-done)
    - [GitHub Spec Kit](#github-spec-kit)
    - [Choosing an Approach](#choosing-an-approach)
  - [Anti-Patterns](#anti-patterns)
  - [Best Practices](#best-practices)
  - [References](#references)

## The Problem SDD Solves

### Context Rot

Claude Code's quality degrades as its context window fills. This isn't a bug -- it's an inherent consequence of how large language models work. Early in a session, Claude has plenty of room to reason carefully, consider edge cases, and produce clean implementations. Past ~50-70% context usage, it shifts into efficiency mode: shorter responses, less thorough reasoning, more shortcuts.

```text
Quality vs. Context Usage

100% |████████████████████████
     |                        ████████
     |                                ████████
     |                                        ██████
     |                                              ████████████
  0% +────────────────────────────────────────────────────────────
     0%          25%          50%          75%          100%
                        Context Window Usage
```

For a small task that fits in one session, this doesn't matter. For a multi-day feature with research, planning, implementation, and debugging, context rot means your first files are implemented well and your last files are implemented poorly -- even though they're part of the same feature.

### The Vibecoding Trap

"Vibecoding" is the pattern of describing what you want in natural language and expecting Claude to produce a complete, working implementation in one shot. It works for small tasks. For anything substantial, it produces:

- **Inconsistent quality** -- Early code is clean, late code is rushed
- **Missing edge cases** -- Context is too crowded to reason about boundaries
- **Incoherent architecture** -- Each piece is built in whatever context happens to be available
- **Untestable output** -- No structured verification, just "looks right"

SDD replaces this with a disciplined cycle: understand the problem, write a structured spec, decompose into atomic tasks, execute each in a fresh context, verify against goals.

## Core Principles

### Specifications Are Prompts

The central insight of SDD is that **specs aren't documentation for humans -- they're context engineering for AI agents**. A well-structured spec gives Claude exactly the information it needs to produce high-quality output, without the noise of an accumulated conversation history.

A traditional spec might read:

> The user authentication system should support email/password login with JWT tokens, rate limiting, and account lockout after failed attempts.

An SDD spec reads more like:

```text
Phase Goal: Users can register and log in securely

Must-Haves:
  - POST /api/auth/register accepts email + password, returns 201 + user object
  - POST /api/auth/login returns JWT cookie (httpOnly, secure, 15min expiry)
  - Rate limit: 5 failed logins per email per 15 minutes → 429
  - Account lockout: 10 failed attempts → lock for 30 minutes
  - Passwords: bcrypt, minimum 8 chars, must include number

Task Dependencies:
  - User model + migration (no dependencies)
  - Registration endpoint (needs: user model)
  - Login endpoint (needs: user model)
  - Rate limiting middleware (needs: login endpoint)
  - Account lockout (needs: rate limiting)

Verification:
  - curl -X POST /api/auth/register → 201
  - curl -X POST /api/auth/login (valid) → 200 + Set-Cookie
  - curl -X POST /api/auth/login (invalid, 6 times) → 429
```

The second version is specific enough that Claude can implement it without asking clarifying questions, verify each piece independently, and produce consistent results across different context windows.

### Fresh Contexts Prevent Quality Decay

If context rot is the disease, fresh contexts are the cure. Instead of implementing an entire feature in one marathon session, SDD breaks work into tasks that each execute in an isolated context window:

```text
┌──────────────┐     ┌──────────────┐     ┌──────────────┐
│   Task 1     │     │   Task 2     │     │   Task 3     │
│              │     │              │     │              │
│  Fresh 200K  │     │  Fresh 200K  │     │  Fresh 200K  │
│  context     │     │  context     │     │  context     │
│              │     │              │     │              │
│  Quality: A  │     │  Quality: A  │     │  Quality: A  │
└──────┬───────┘     └──────┬───────┘     └──────┬───────┘
       │                    │                    │
       ▼                    ▼                    ▼
   commit 1             commit 2             commit 3
```

Each task gets 200K tokens of clean context. The plan file (typically 1,000-3,000 tokens) is the only context loaded. The result: consistent A-grade quality for every task, regardless of whether it's the first or the fiftieth.

This can be achieved through:

- **Subagents** -- Claude spawns a fresh agent via the Task tool for each unit of work
- **New sessions** -- Developer starts a fresh `claude` session with a plan file as input
- **Git worktrees** -- Isolated working directories with clean session state

### Atomic Decomposition Maintains Quality

"Atomic" means each task targets roughly 50% of a context window or less. At that threshold, Claude has plenty of room to reason, test, and produce clean code. The rule of thumb:

- **2-3 tasks per plan** -- Each plan file is a self-contained prompt
- **One concern per task** -- A task creates a model, or an endpoint, or a test suite -- not all three
- **Clear inputs and outputs** -- Each task declares what it needs (files, APIs) and what it produces (new files, modified files, test results)

Over-decomposition is also a risk. If a task is "add a single import statement," it's too small and the overhead of context setup exceeds the benefit. The sweet spot is tasks that take 2-10 minutes of Claude's execution time.

### Goal-Backward Verification

Traditional verification asks: "Did Claude complete the tasks?" SDD verification asks: "Is the goal actually achieved?"

The difference matters. A planner might decompose "users can log in" into five tasks. The executor might complete all five. But if the login endpoint returns a token that the frontend doesn't read, the goal isn't achieved -- even though every task "passed."

Goal-backward verification works in reverse:

1. **What must be TRUE** for the goal to be achieved? (Observable behaviors from user perspective)
2. **What artifacts must exist** for those truths to hold? (Files, endpoints, schemas)
3. **What wiring must connect** the artifacts? (Imports, API calls, state management)
4. **What key links** are most likely to be missing? (Component → API, form → handler, state → render)

Then verify each level:

```text
Artifact Verification Levels:

Level 1 - Existence:    Does the file exist?
Level 2 - Substantive:  Is it real code (not a stub)?
Level 3 - Wired:        Is it imported and used by the system?
```

A file that exists but contains `// TODO: implement` passes Level 1 but fails Level 2. A fully implemented handler that's never imported passes Level 2 but fails Level 3.

### Structured Handoffs Bridge Context Boundaries

When work spans multiple context windows, knowledge must travel between them. SDD uses structured documents -- plans, summaries, state files -- as the handoff mechanism:

```text
Session 1           Handoff              Session 2
┌──────────┐     ┌──────────┐        ┌──────────┐
│ Research │────▶│ SPEC.md  │───────▶│ Planning │
└──────────┘     └──────────┘        └────┬─────┘
                                          │
                                     ┌────▼─────┐
                                     │ PLAN.md  │
                                     └────┬─────┘
                                          │
Session 3                            ┌────▼─────┐
┌──────────┐     ┌──────────┐        │ Execute  │
│ Verify   │◀────│SUMMARY.md│◀───────│ Task 1   │
└──────────┘     └──────────┘        └──────────┘
```

Each document serves a specific role:

- **SPEC.md / constitution** -- Requirements and constraints (what to build)
- **PLAN.md** -- Atomic task list with dependencies (how to build it)
- **SUMMARY.md** -- What was actually built (per-task results, deviations)
- **STATE.md** -- Project memory across phases (decisions, blockers, progress)
- **VERIFICATION.md** -- Gap analysis results (what's missing, what needs fixing)

These aren't optional documentation -- they're the protocol that makes multi-session development coherent.

## The Development Cycle

```text
    ┌──────────┐
    │ Research │  Understand ecosystem, codebase, constraints
    └────┬─────┘
         │
    ┌────▼─────┐
    │ Specify  │  Define requirements, acceptance criteria
    └────┬─────┘
         │
    ┌────▼─────┐
    │  Plan    │  Decompose into atomic tasks with dependencies
    └────┬─────┘
         │
    ┌────▼─────┐
    │ Execute  │  Implement in fresh contexts, TDD, atomic commits
    └────┬─────┘
         │
    ┌────▼─────┐
    │ Verify   │  Goal-backward analysis, artifact checking
    └────┬─────┘
         │
    ┌────▼─────┐
    │ Iterate  │  Close gaps, advance to next phase
    └────┬─────┘
         │
         └──────── (next phase)
```

### Research Phase

Before writing specs or plans, understand what you're building and what you're building on.

**For new projects (greenfield):**

- Explore the ecosystem: what tools, libraries, and patterns exist
- Evaluate feasibility: can this be done? What are the blockers?
- Compare alternatives: if multiple approaches exist, which fits best?

**For existing codebases (brownfield):**

- Map the technology stack and integrations
- Understand existing architecture and file structure
- Document conventions and testing patterns
- Identify technical debt and concerns

The research phase produces reference documents that the planner loads as context. File paths are critical in these documents -- every finding should include the exact path so downstream agents can navigate directly.

### Specification Phase

Specs translate research into structured requirements. The key is being specific enough that an AI agent can implement without asking clarifying questions, while staying abstract enough that the spec doesn't prescribe an implementation.

A good spec includes:

- **Phase goal** -- One sentence describing what's true when the phase is complete
- **Must-haves** -- Observable truths derived using goal-backward methodology
- **Out of scope** -- What this phase explicitly does not address
- **Constraints** -- Technology choices, performance requirements, compatibility needs
- **Acceptance criteria** -- How to verify the goal is achieved

Specs can be as lightweight as a section in a plan file or as formal as a dedicated requirements document. The formality should match the complexity of what you're building. For guidance on writing requirements that work as spec inputs -- choosing formats, decomposing vague requests, and discovering edge cases -- see [Requirements & Specifications]({{< relref "/product/requirements-specifications" >}}).

### Planning Phase

Planning decomposes the spec into executable tasks. Each task is a self-contained unit of work with:

- **Files** -- Exact paths to create or modify (with line ranges for modifications)
- **Action** -- What to implement, including what to avoid and why
- **Verification** -- Specific command to run and expected output
- **Done criteria** -- How to know the task is complete

Tasks are organized into dependency graphs. Tasks with no dependencies can execute in parallel (Wave 1). Tasks that depend only on Wave 1 outputs form Wave 2, and so on.

```text
Wave 1 (parallel)        Wave 2 (parallel)       Wave 3
┌─────────────┐         ┌─────────────┐         ┌─────────────┐
│ User model  │────────▶│ Register    │────────▶│ Rate limit  │
└─────────────┘    ┌───▶│ endpoint    │         └─────────────┘
                   │    └─────────────┘
┌─────────────┐    │    ┌─────────────┐         ┌─────────────┐
│ DB migration│────┘    │ Login       │────────▶│ Account     │
└─────────────┘────────▶│ endpoint    │         │ lockout     │
                        └─────────────┘         └─────────────┘
```

**Vertical slices** are preferred over horizontal layers. A vertical slice delivers a complete user-facing behavior (model + API + UI) rather than building all models, then all APIs, then all UIs. Vertical slices are independently verifiable and reduce integration risk.

### Execution Phase

Execution follows the plan. Each task runs in a fresh context with only the plan file as input. The execution discipline:

1. **Read the task** -- Load the plan, find the current task
2. **Implement with TDD** -- Write a failing test, make it pass, refactor
3. **Verify** -- Run the exact verification command from the plan
4. **Commit** -- Atomic commit for this task only
5. **Report** -- Write a summary of what was done, any deviations

Deviations from the plan happen. The discipline is in how they're handled:

- **Auto-fix**: Logic errors, missing imports, broken types -- fix immediately
- **Auto-add**: Error handling, validation, auth checks -- add if clearly needed
- **Stop and ask**: Architectural changes, new dependencies, framework switches

### Verification Phase

After execution completes, verify the phase goal, not the individual tasks alone.

The verification process:

1. **State the phase goal** -- What must be true?
2. **Derive must-haves** -- What observable behaviors prove the goal?
3. **Check artifacts** -- Do the files exist? Are they substantive? Are they wired into the system?
4. **Test key links** -- Are the critical connections present? (API → database, form → handler, component → state)
5. **Report gaps** -- Any missing pieces become input for the next planning cycle

Verification explicitly **does not trust** execution summaries. The executor saying "all tasks complete" is not evidence. The verifier independently checks the codebase against the goal.

### Iteration

If verification finds gaps, they feed back into planning. A gap plan targets only the missing pieces, not the entire phase. This keeps iteration focused and prevents scope creep.

When verification passes, the phase is complete and the cycle advances:

- Update the project state file
- Archive phase artifacts
- Begin research for the next phase

## Practical Patterns

### The Interview Pattern

Before planning a complex feature, have Claude interview you to surface requirements you haven't articulated. Instead of dumping a vague request, start a conversation:

```text
> I want to add user authentication to the app. Interview me
> about requirements before we plan anything.
```

Claude asks one question at a time (multiple choice when possible), building up a complete picture of what you need. After 5-10 questions, it has enough context to write a solid spec -- one that covers edge cases you wouldn't have mentioned in a freeform prompt.

### Dependency Graphs and Execution Waves

Tasks are analyzed for what they **need** (prerequisites) and what they **create** (artifacts). This produces a dependency graph that determines execution order:

- **Wave 1**: Tasks with no dependencies (can run in parallel)
- **Wave 2**: Tasks depending only on Wave 1 outputs (can run in parallel)
- **Wave N**: Tasks depending on Wave N-1 outputs
- **Checkpoint waves**: Tasks requiring human interaction (block subsequent waves)

Parallel execution across waves can dramatically reduce wall-clock time for complex features. If Waves 1 and 2 each contain three independent tasks, six tasks can execute concurrently across three pairs of sequential work.

### Atomic Commits

Every task produces its own commit immediately after verification:

```text
feat(auth): create user model and migration
feat(auth): add registration endpoint with validation
feat(auth): add login endpoint with JWT cookies
feat(auth): add rate limiting middleware
fix(auth): handle duplicate email in registration
```

Benefits:

- **Git bisect** finds the exact task that introduced a regression
- **Each task** can be reverted independently
- **Clean history** gives future sessions clear context for what was built and why

### Checkpoint Protocols

Not everything can be automated. Checkpoints pause execution for human input:

- **Human-verify** (~90% of checkpoints) -- User confirms automated work looks correct
- **Decision** (~9%) -- User chooses between implementation options
- **Human-action** (~1%) -- Truly unavoidable manual step (email verification link, 2FA code)

The discipline: automation first, checkpoint after. Claude does all the work it can, then pauses for human input -- not the other way around.

### State Files for Continuity

For multi-phase projects, a state file persists project memory across sessions:

```yaml
current_phase: 3
current_plan: auth-rate-limiting
status: executing

decisions:
  - JWT over sessions (Phase 1, user preference)
  - PostgreSQL over SQLite (Phase 0, scalability)
  - bcrypt over argon2 (Phase 2, library maturity)

blockers:
  - Email service provider not selected

last_activity: 2026-02-10
resume_point: "Phase 3, Plan 2, Task 3 (rate limiting middleware)"
```

This prevents repeated decisions, lost context, and the "where was I?" problem when resuming work after a break.

## Tool Landscape

The principles above can be practiced manually with nothing more than markdown files and disciplined session management. But several tools automate parts of the cycle.

### Superpowers Skills

A collection of Claude Code skills that inject workflow discipline into your sessions. Lightweight and modular -- you use whichever skills match your current task.

**The workflow chain:**

```text
brainstorming → writing-plans → executing-plans → verification-before-completion
                                     │
                              (alternative)
                                     │
                         subagent-driven-development
```

- **brainstorming** -- Collaborative design exploration: asks questions one at a time, proposes 2-3 approaches with trade-offs, builds up a validated design incrementally
- **writing-plans** -- Creates implementation plans with exact file paths, complete code examples, TDD steps, and verification commands. Plans are designed so an engineer with zero codebase knowledge could execute them
- **executing-plans** -- Loads a plan and executes it in controlled batches (default: 3 tasks per batch) with review checkpoints between batches
- **subagent-driven-development** -- Alternative to executing-plans: dispatches a fresh subagent per task with code review between each task. Faster iteration, no human-in-loop between tasks
- **verification-before-completion** -- Enforces evidence before claims. No saying "tests pass" without running them and reading the output
- **using-git-worktrees** -- Creates isolated workspaces with smart directory selection and baseline test verification

**Best for**: Individual developers who want structured discipline without heavy tooling. Works with any project type and doesn't require a specific directory structure.

### GSD (Get Shit Done)

A full orchestration system with specialized agents for each phase of development. Automates the entire cycle from project inception through verification.

**The agent pipeline:**

```text
gsd-project-researcher → gsd-planner → gsd-executor → gsd-verifier
         │                                                   │
         ▼                                                   ▼
   Research docs                                       VERIFICATION.md
   (.planning/research/)                               (gap analysis)
                                                             │
gsd-codebase-mapper                                    ┌─────▼──────┐
         │                                             │ Gaps found? │
         ▼                                             └─────┬──────┘
   Codebase docs                                       yes   │   no
   (.planning/codebase/)                                ▼         ▼
                                                   Re-plan    Next phase
```

- **gsd-project-researcher** -- Researches ecosystem before building. Produces stack recommendations, feature landscapes, architecture patterns, and pitfall documentation
- **gsd-codebase-mapper** -- Analyzes existing codebases across four dimensions: technology, architecture, conventions, and concerns
- **gsd-planner** -- Creates atomic plans using goal-backward methodology. Builds dependency graphs, assigns execution waves, maximizes parallelism. Plans target ~50% context usage
- **gsd-executor** -- Executes plans atomically with per-task commits. Handles deviations automatically (auto-fixes bugs, stops for architectural changes). Respects checkpoints
- **gsd-verifier** -- Independently verifies goal achievement. Checks artifact existence, substantiveness, and wiring. Does not trust executor claims
- **gsd-debugger** -- Scientific debugging with hypothesis testing and persistent debug sessions

**Best for**: Complex multi-phase projects where automated quality control justifies the tooling overhead. Projects where context rot would otherwise require constant manual intervention.

### GitHub Spec Kit

An open-source toolkit from GitHub for spec-driven development across AI coding tools. Focuses on the specification layer -- creating structured, machine-readable requirements that any AI agent can work from.

**The artifact structure:**

```text
.speckit/
├── constitution.md         # Project principles and guidelines
└── features/
    └── 001-feature-name/
        ├── specify.md      # Requirements and user stories
        ├── plan.md         # Technical implementation plan
        ├── tasks.md        # Task breakdown
        └── checklist.md    # Quality gates
```

- **Constitution** -- Project-wide principles, coding standards, and constraints that govern all development
- **Specifications** -- Per-feature requirements with user stories and success criteria
- **Plans** -- Technical architecture derived from specifications
- **Tasks** -- Actionable work items derived from plans
- **Analysis** -- Quality validation ensuring consistency across all artifacts

Supports both greenfield (new project from scratch) and brownfield (adding features to existing code) workflows. Installs as a CLI (`specify-cli`) via `uv`.

**Best for**: Teams wanting a standardized spec format that works across multiple AI tools (Claude Code, Copilot, Cursor, etc.). Projects where specs need to be shared and reviewed by humans.

### Choosing an Approach

| Factor                 | Superpowers             | GSD                      | GitHub Spec Kit          |
| ---------------------- | ----------------------- | ------------------------ | ------------------------ |
| **Setup complexity**   | Low (skill files)       | Medium (agents + config) | Low (CLI install)        |
| **Automation level**   | Manual + discipline     | Fully orchestrated       | Spec generation only     |
| **Context management** | Via subagents/worktrees | Built-in (atomic plans)  | External (your workflow) |
| **Verification**       | Manual (with prompts)   | Automated (gsd-verifier) | Manual (analysis cmd)    |
| **Multi-tool support** | Claude Code only        | Claude Code only         | Any AI coding tool       |
| **Team collaboration** | Via shared plans        | Via .planning/ directory | Via .speckit/ directory  |
| **Best project size**  | Small to medium         | Medium to large          | Any                      |
| **Learning curve**     | Low                     | Medium                   | Low                      |

These tools are not mutually exclusive. You could use Spec Kit for requirements, then import those specs into a GSD or Superpowers workflow for execution. The principles are the same -- the tools just automate different parts of the cycle.

## Anti-Patterns

**Over-specifying simple tasks.** If you can describe the change in one sentence and the diff would be under 20 lines, skip the spec. SDD adds value when complexity would otherwise cause quality to decay. For simple changes, it's pure overhead.

**Treating specs as documentation.** Specs are prompts. If your spec reads like a design document for a human audience -- narrative prose, background context, stakeholder analysis -- it's the wrong format. AI agents need structured, actionable, verifiable specifications.

**Massive monolithic plans.** A plan with 15 tasks defeats the purpose. Past 3-4 tasks, context accumulates and quality drops. Break large phases into multiple plans, each targeting ~50% context usage.

**Skipping verification.** The executor says "all tasks complete" and you trust it. This is the single most common failure mode. Task completion is not goal achievement. Always verify independently.

**Planning without research.** Jumping straight to planning without understanding the ecosystem or codebase leads to plans that miss critical constraints, use deprecated libraries, or duplicate existing functionality.

**Gold-plating specs.** Spending more time on the spec than the implementation would take. SDD should reduce total effort, not increase it. If the spec takes longer than just building the thing, the task probably doesn't need SDD.

## Best Practices

1. **Match formality to complexity.** A one-line task needs no spec. A week-long feature needs the full cycle. Most work falls somewhere in between -- use your judgment about which phases to include.

2. **Start with the goal, work backward.** Define what must be TRUE when you're done, then derive what must exist to make it true. This prevents scope creep and keeps verification focused.

3. **Use vertical slices.** Each plan should deliver a complete, testable behavior -- not a horizontal layer. "User can register" is better than "all database models are created."

4. **Commit the specs.** Plans and state files belong in version control. They're part of the project history and serve as context for future sessions.

5. **Keep state files current.** If you make a decision during execution that changes the plan, update the state file immediately. Stale state is worse than no state.

6. **Let deviations inform iteration.** If the executor keeps deviating from plans in the same way, the planning phase needs adjustment -- not the executor.

7. **Fresh session for verification.** The session that wrote the code is biased toward thinking it's correct. Verify in a fresh context.

8. **Calibrate depth to risk.** High-stakes code (auth, payments, data migration) deserves comprehensive specs and verification. Internal tooling can use a lighter touch.

## References

- [Workflow Patterns]({{< relref "workflow-patterns" >}}) -- Core development workflows with Claude Code
- [Context Management]({{< relref "/internals/context-management" >}}) -- How context windows work and why fresh contexts matter
- [Extension Mechanisms]({{< relref "/extending/extension-mechanisms" >}}) -- How skills and subagents inject workflow discipline
- [Custom Extensions]({{< relref "/extending/custom-extensions" >}}) -- Building and managing skills with claudeup
- [Token Optimization]({{< relref "/internals/token-optimization" >}}) -- Managing overhead from plugins and skills
- [GitHub Spec Kit](https://github.com/github/spec-kit) -- GitHub's open-source SDD toolkit
