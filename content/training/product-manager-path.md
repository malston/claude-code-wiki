---
title: "Product Manager Path"
weight: 3
---

# Product Manager Path

Technical literacy for product managers working alongside developers who use Claude Code. This path covers enough software design, architecture, coding standards, and TDD for you to make informed decisions and participate in developer workflows.

| Module                                                                            | Focus                                       | Prerequisites |
| --------------------------------------------------------------------------------- | ------------------------------------------- | ------------- |
| [1. How Claude Code Works](#module-1-how-claude-code-works)                       | What Claude Code is and isn't               | None          |
| [2. Software Design Principles](#module-2-software-design-principles)             | What makes software maintainable            | Module 1      |
| [3. Architecture Decisions](#module-3-architecture-decisions)                     | How to evaluate technical trade-offs        | Module 2      |
| [4. Coding Standards](#module-4-coding-standards)                                 | Why conventions matter and what to look for | Module 2      |
| [5. Test-Driven Development](#module-5-test-driven-development)                   | How TDD shapes planning and estimation      | Modules 2-4   |
| [6. Working with Developer Workflows](#module-6-working-with-developer-workflows) | Participating in the development process    | Modules 1-5   |

## Exercise Materials

Clone the exercise repo for hands-on practice alongside each module:

```bash
git clone https://github.com/malston/training-pm-exercises.git ~/code/training-pm-exercises
cd ~/code/training-pm-exercises
```

The repo contains a working Spring Boot order service with a mock product backlog, PR branches for review practice, and exercises for each module from understanding Claude Code to feature decomposition.

## Module 1: How Claude Code Works

**Goal:** Understand what Claude Code does so you can set realistic expectations for your team.

### Key Concepts

**Claude Code is a CLI tool that writes code through conversation.** A developer describes what they need, Claude reads the codebase, generates code, runs tests, and iterates. It's interactive, not a batch process.

**What Claude Code does well:**

- Implementing features when given clear requirements and acceptance criteria
- Debugging with access to error output and test results
- Refactoring code while maintaining test coverage
- Exploring unfamiliar codebases and explaining how things work
- Interacting with external services through MCP tools (databases, APIs, browsers) when configured

**What Claude Code doesn't do:**

- Replace developer judgment on architecture and design
- Understand your business context without being told
- Guarantee correct code without verification (tests, reviews)
- Work well with vague requirements ("make it better")

**The quality of output depends on the quality of input.** Specific requirements with clear acceptance criteria produce better code than vague feature requests. This matters for how you write tickets and specs.

**Context windows are finite.** Claude Code can only "see" ~200K tokens at a time. Long conversations get summarized, and earlier details can be lost. This means large, complex tasks work better when broken into smaller pieces.

### Key Questions to Answer

- What's the difference between Claude Code generating code and a developer writing code? (Answer: Claude still needs verification, review, and human judgment on design)
- Why do specific requirements produce better results? (Answer: Claude doesn't have your business context -- you have to provide it)
- Why should large features be broken into smaller tasks? (Answer: context window limits, verification at each step, easier to course-correct)

### Exercises

**Starter materials:** `modules/01-claude-code-basics/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- exercises using the order service and mock backlog to explore Claude Code's capabilities and limitations.

1. Compare two backlog tickets (`backlog/features/001-order-search.md` vs `backlog/features/002-order-history-export.md`). Which gives Claude enough information to implement correctly? What's missing from the vague one?
2. Review `backlog/features/005-customer-dashboard.md` -- this feature is too large for one Claude Code session. List which parts you'd split into separate tasks.
3. Pair with a developer on a Claude Code session and note 3 things that surprised you about how it works.

### Reference

- [Context Management]({{< relref "internals/context-management" >}}) -- How Claude Code's context window works and why it matters for task sizing

## Module 2: Software Design Principles

**Goal:** Understand the principles developers use to keep software maintainable, so you can recognize good and bad design in discussions.

### Key Concepts

**The initial implementation is the cheap part.** Maintenance -- reading, understanding, debugging, extending -- accounts for the majority of the cost over a system's lifetime. Every design decision should favor long-term maintainability.

**YAGNI: You Aren't Gonna Need It.** Don't build for hypothetical future requirements. Build what's needed now, and only add complexity when there's a concrete need. This applies to your roadmap too -- resist feature requests that "might be useful someday."

**Separation of concerns.** Each component should do one thing. When a single module handles authentication, data validation, and email sending, changes to any one concern risk breaking the others. Watch for this in architecture discussions -- "this service does X and also Y and also Z" is a warning sign.

**Naming matters.** Code names should describe what something does, not how it's implemented or its history. If a developer names something "NewAuthService" or "ImprovedValidator," ask what it actually does -- the name should describe the domain concept, not the refactoring history.

### What This Means for PMs

- When estimating work, factor in maintenance cost -- not just initial implementation
- When requesting features, be specific about the need, not the solution. "Users need to filter orders by date range" is better than "add a date picker component"
- When reviewing designs, ask: "What happens when we need to change X?" If the answer involves touching many unrelated files, the design may have a coupling problem

### Exercises

**Starter materials:** `modules/02-design-principles/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- exercises using the order service to practice recognizing separation of concerns, YAGNI violations, and naming quality.

1. Read `OrderService.java` and `OrderController.java`. Why are they separate? If you needed to add email notifications on cancellation, which file changes?
2. Review the full backlog and classify each ticket as "need now," "might need later," or "over-engineering." Which would you defer?
3. Check the `feature/order-notifications` branch -- the developer added email, SMS, and Slack when the ticket only asked for email. Which design principle does this violate?

### Reference

- [Effective Prompting]({{< relref "guides/effective-prompting" >}}) -- How specificity in requirements translates to better AI-generated code

## Module 3: Architecture Decisions

**Goal:** Evaluate technical trade-offs in architecture discussions without needing to write code.

### Key Concepts

**Every architectural choice has costs and benefits.** There's no universal answer to "microservices or monolith" -- it depends on team size, deployment needs, and complexity.

**Common trade-offs you'll encounter:**

| Decision                   | Option A              | Option B                    | Key Factor                           |
| -------------------------- | --------------------- | --------------------------- | ------------------------------------ |
| Service architecture       | Monolith (simpler)    | Microservices (scalable)    | Team size and deployment needs       |
| Data storage               | SQL (structured)      | NoSQL (flexible)            | Query patterns and consistency needs |
| Build vs. buy              | Custom code (control) | Third-party service (speed) | Maintenance burden vs. vendor risk   |
| Performance vs. simplicity | Optimized (complex)   | Simple (slower)             | Whether users notice the difference  |

**Questions to ask in architecture discussions:**

- "What's the simplest thing that could work?" -- pushes back on over-engineering
- "What happens if this component fails?" -- reveals single points of failure
- "How does this change if we have 10x more users?" -- tests scalability assumptions
- "How many teams need to coordinate to deploy this?" -- reveals organizational complexity

**Reversibility matters.** Prefer decisions that are easy to change later. A database schema change that requires migrating millions of rows is hard to reverse. An internal API redesign between two services is relatively easy. Push for reversible choices when the team is uncertain.

### What This Means for PMs

- Don't default to "whatever the engineers recommend" -- ask about trade-offs and make sure the choice aligns with business priorities
- Separate "we need this now" from "we might need this later" -- YAGNI applies to architecture too
- When developers say "this will take longer because we need to do it right," ask what "right" means in concrete terms (e.g., "we need to add a database migration" vs. "we need to redesign the service boundary")

### Exercises

**Starter materials:** `modules/03-architecture/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- trade-off analysis, reversibility assessment, and scalability exercises using the order service.

1. The order service uses an in-memory H2 database. Fill out the trade-off table comparing H2 vs. PostgreSQL for production. What questions would you ask the team?
2. Rate 5 proposed changes (from adding an endpoint to switching frameworks) as easy, moderate, or hard to reverse.
3. Review the customer dashboard feature spec and ask: if user volume grows 10x, which parts break first?

### Reference

- [Architecture Overview]({{< relref "enterprise-rollout/00-overview/architecture-overview" >}}) -- Claude Code request flow and enterprise configuration hierarchy

## Module 4: Coding Standards

**Goal:** Understand why coding standards exist and what to look for when teams adopt them.

### Key Concepts

**Coding standards reduce cognitive load.** When all code in a project follows the same patterns, developers spend less time understanding structure and more time understanding logic. This is the same principle as having a consistent document template -- you know where to find things.

**Standards cover three areas:**

1. **Formatting** -- indentation, line length, file organization. Automated by tools (linters, formatters). Not worth debating.
2. **Naming** -- variable names, function names, file names. Describes what code does. Good names make code self-documenting.
3. **Patterns** -- how to handle errors, structure tests, organize modules. These require judgment and team agreement.

**Claude Code follows project standards automatically** when they're documented in CLAUDE.md. A well-maintained CLAUDE.md file directly controls the quality of AI-generated code -- it tells Claude exactly how to write code that matches the project's conventions.

**Style guides and CLAUDE.md are related but different:**

- Style guides define the rules for humans to follow
- CLAUDE.md encodes those rules (plus project-specific context) for Claude to follow
- Both should be kept in sync

### What This Means for PMs

- Support your team's investment in CLAUDE.md and coding standards -- they directly improve the quality of AI-generated code
- When evaluating Claude Code's output, ask whether it follows the team's patterns. If it doesn't, the CLAUDE.md may need updating.
- Don't push for "just ship it" when code doesn't match standards. Inconsistent code costs more to maintain later than it saves now.

### Exercises

**Starter materials:** `modules/04-coding-standards/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- exercises for reviewing CLAUDE.md, checking PR consistency, and making the business case for standards.

1. Read the project's `CLAUDE.md`. What conventions does it enforce? What's missing that would help Claude produce more consistent code?
2. Compare the three PR branches against the patterns in main. Which is most consistent? Which deviates the most?
3. Make the business case for investing a sprint in CLAUDE.md and coding standards documentation instead of building features.

### Reference

- [Memory Organization]({{< relref "guides/memory-organization" >}}) -- How CLAUDE.md files structure project context for Claude Code

## Module 5: Test-Driven Development

**Goal:** Understand how TDD works and how it affects planning, estimation, and feature delivery.

### Key Concepts

**TDD means writing tests before writing code.** The cycle is:

```text
1. Write a test that describes the desired behavior → it fails
2. Write the minimum code to make the test pass
3. Clean up the code while keeping tests passing
```

This feels backwards at first, but it produces code that's verified by definition -- if the tests pass, the feature works as specified.

**Tests are executable requirements.** A test file says exactly what the software should do, in a way that can be verified automatically. "The login endpoint returns 401 when the password is wrong" -- that's a test, and it's also a requirement.

**How TDD affects planning:**

- Features need acceptance criteria precise enough to become tests
- "The user should be able to log in" isn't testable. "POST /login with valid credentials returns a session token; invalid credentials return 401" is.
- Writing good acceptance criteria is a PM skill that directly improves developer productivity

**How TDD affects estimation:**

- TDD doesn't make development slower -- it shifts debugging time to the beginning
- Without TDD: implement fast, debug later when things break
- With TDD: specify behavior first, implement against the spec, catch bugs immediately
- Total time is similar, but TDD catches problems earlier when they're cheaper to fix

**With Claude Code, tests are especially valuable.** Tests give Claude concrete verification. Without tests, Claude has to guess whether its code works. With tests, it runs them and knows.

### What This Means for PMs

- Write acceptance criteria as specific behaviors, not vague outcomes. Each criterion should be verifiable: given X input, expect Y output.
- Don't pressure developers to skip tests to "move faster." Tests save time over the lifecycle of a feature.
- When Claude Code is used with TDD, the test suite becomes the source of truth for what the software does. Review the tests, not just the code.

### Exercises

**Starter materials:** `modules/05-tdd/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- before/after examples of vague vs. testable acceptance criteria, plus the mock product backlog in `backlog/`.

1. Read through the mock product backlog. Identify which tickets have testable acceptance criteria and which don't. What's missing from the vague ones?
2. Pick a vague ticket and rewrite its acceptance criteria using Given/When/Then format. Compare your version with the examples in `modules/05-tdd/examples.md`.
3. Review the existing `OrderControllerTest.java` -- can you trace each test back to a specific acceptance criterion? Where are the gaps?

### Reference

- [Testing Strategies]({{< relref "guides/testing-strategies" >}}) -- TDD patterns and how tests serve as durable requirements for AI-assisted development

## Module 6: Working with Developer Workflows

**Goal:** Participate effectively in the development process alongside developers using Claude Code.

### Key Concepts

**How developers use Claude Code day-to-day:**

```text
1. Start a session with a specific task
2. Provide context (files, errors, requirements)
3. Claude reads code, proposes changes, runs tests
4. Developer reviews, accepts/rejects, course-corrects
5. Iterate until the task is complete
6. Commit, push, open a PR for review
```

The developer is still in control -- Claude proposes, the developer decides.

**Writing good tickets for AI-assisted development:**

A ticket that works well with Claude Code includes:

- **Clear scope:** what to build, where it lives in the codebase
- **Acceptance criteria:** specific, testable behaviors (see Module 5)
- **Context:** why this feature exists, what problem it solves
- **Constraints:** what's out of scope, what shouldn't change

A ticket that works poorly:

- "Improve the dashboard" (no specific outcome)
- "Make it faster" (no measurement, no target)
- "Fix the bug" (no reproduction steps, no expected behavior)

**Code reviews still matter.** Claude Code generates code, but a human reviews it before it's merged. As a PM, you won't review the code itself, but you can:

- Review that acceptance criteria are met
- Check that the feature behaves correctly in testing
- Verify that the scope matches the ticket (no over-engineering, no missing pieces)

**Session management affects delivery.** Claude Code sessions have context limits. Large features should be broken into tasks that each fit within a session. If you're planning a sprint, think about features as a sequence of small, independently verifiable steps rather than one big deliverable.

### Exercises

**Starter materials:** `modules/06-workflows/` in the [exercise repo](https://github.com/malston/training-pm-exercises) -- three PR branches for review practice and a feature decomposition exercise using the customer dashboard spec.

1. Review the three PR branches (`feature/order-search`, `feature/order-notifications`, `feature/bulk-status`). For each, compare the PR changes against the corresponding backlog ticket. Which PR matches its ticket? Which has scope creep? Which is missing acceptance criteria?
2. Take the customer dashboard feature spec (`backlog/features/005-customer-dashboard.md`) and decompose it into smaller tasks using the template in `templates/decomposition-template.md`. Each task should be independently verifiable.
3. Pick a vague ticket from the backlog and rewrite it with testable acceptance criteria. For each criterion, write it as: "Given [context], when [action], then [expected result]."

### Reference

- [Workflow Patterns]({{< relref "guides/workflow-patterns" >}}) -- How developers structure work sessions, plan-then-implement, and manage parallel tasks

## What's Next

After completing this path, you should be able to:

- Set realistic expectations for Claude Code's capabilities
- Recognize good and bad software design in discussions
- Ask informed questions in architecture decision meetings
- Understand why coding standards and CLAUDE.md matter
- Write acceptance criteria that developers (and Claude) can test against
- Break features into tasks suited for AI-assisted development

For hands-on developer skills, see the [Developer Path]({{< relref "training/developer-path" >}}). For infrastructure and deployment concerns, see the [Platform Engineer Path]({{< relref "training/platform-engineer-path" >}}).
