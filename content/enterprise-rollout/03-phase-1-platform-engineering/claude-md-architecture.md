---
title: "CLAUDE.md Architecture -- Four-Layer Context Hierarchy"
linkTitle: "CLAUDE.md Architecture"
weight: 3
---

# CLAUDE.md Architecture -- Four-Layer Context Hierarchy

## The Core Design Problem

Claude Code has a context window of ~200K tokens. Every CLAUDE.md file, every rule, every skill description, every file Claude reads, every conversation turn competes for space. The context window is the scarce resource, and the platform engineer's job is to manage it like memory in a constrained system.

Unlike human developers who can skim past irrelevant instructions, Claude treats everything in its context with roughly equal attention. Irrelevant instructions don't just waste tokens -- they actively dilute the signal.

**Design principle: progressive disclosure of context.** Load the minimum viable instructions unconditionally. Load everything else conditionally based on what the developer is actually working on.

## Layer 0: Managed CLAUDE.md (Always Loaded, Org-Wide)

Deployed via MDM alongside managed-settings.json. Every Claude Code session sees this file, regardless of project, team, or developer.

**Budget: 30–50 lines maximum.** This is the most expensive context because it loads into every single session across 500 developers.

### What Belongs Here

- Security non-negotiables (3–5 lines): "Never commit secrets. Never hardcode credentials. Never disable authentication. Never log PII."
- Code review expectations (2–3 lines): "All changes must go through PR review. Include test coverage for new logic."
- AI interaction norms (3–5 lines): "When uncertain about architecture, propose a plan before implementing. Prefer small, reviewable diffs over large rewrites."

### What Does NOT Belong Here

- Language-specific conventions (use rules or project CLAUDE.md)
- Build commands (vary by project)
- Architecture descriptions (project-specific)
- Style guides (use linters, not LLM instructions)

### Anti-Pattern

Treating the org CLAUDE.md as a coding standards document. A 200-line org CLAUDE.md means 200 lines consumed in every session for every developer, most of which is irrelevant to the current task.

## Layer 1: Project CLAUDE.md + Rules Directory (Loaded Per-Repo)

Two mechanisms work together:

### .claude/CLAUDE.md -- Project Main Instructions

Checked into git, shared by the team. **Budget: 60–80 lines.**

Contents:

- Project architecture overview (what is this service, what does it do)
- Build/test/deploy commands
- Key directories and their purposes
- Pointer to deeper documentation: "Read files in `agent_docs/` for detailed patterns before making architectural changes"

### .claude/rules/ -- Modular, Path-Scoped Instructions

Rules are markdown files that can be **conditionally loaded** based on which files Claude is working on:

```sh
.claude/
├── CLAUDE.md                    # Universal project context (~60 lines)
└── rules/
    ├── code-style.md            # No paths: → always loaded
    ├── security.md              # No paths: → always loaded
    ├── api/
    │   └── rest-conventions.md  # paths: "src/api/**/*.ts" → API work only
    ├── database/
    │   └── migration-patterns.md # paths: "src/db/**" → DB work only
    ├── frontend/
    │   ├── react-patterns.md    # paths: "src/components/**/*.tsx"
    │   └── styling.md           # paths: "**/*.css", "**/*.scss"
    └── testing/
        └── test-conventions.md  # paths: "**/*.test.*", "**/*.spec.*"
```

### Path-Scoped Rule Example

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/api/**/*.go"
---

# API Development Rules

Endpoints in this service follow these patterns:

- Input validation using the shared validation middleware (see src/middleware/validate.ts)
- Consistent error response shape: { error: string, code: number, request_id: string }
- All endpoints require authentication unless explicitly listed in src/api/public-routes.ts
- Rate limiting is configured per-route in src/api/rate-limits.yaml
- OpenAPI annotations required on all handler functions

For examples of well-structured endpoints, reference:

- src/api/users/handlers.ts (CRUD with pagination)
- src/api/orders/handlers.ts (async processing with status callbacks)
```

When a developer edits a React component, they get React rules loaded automatically but don't pay the context cost for database migration patterns or API conventions.

### Known Caveat

As of January 2026, there's a known bug where rules with `paths` frontmatter load into context globally regardless of paths at session start. Path scoping still signals intent to Claude about relevance, but test this with the current Claude Code version before designing a heavily path-scoped architecture.

### Rule Formatting Notes

- Glob patterns in YAML frontmatter **must be quoted**: `"**/*.ts"` not `**/*.ts`
- Rules without a `paths` field load unconditionally
- Rules support subdirectory organization (auto-discovered recursively)
- Symlinks are supported -- use for sharing rules across repos

## Layer 2: agent_docs/ and Reference Files (Loaded On-Demand)

Deep knowledge layer -- architecture documents, design decisions, API specs, domain models. These files are **NOT** loaded automatically. CLAUDE.md tells Claude they exist, and Claude reads them when relevant.

```sh
repo/
├── agent_docs/
│   ├── README.md                   # Index: what each doc covers
│   ├── architecture-overview.md    # System design, service boundaries
│   ├── data-model.md               # Entity relationships, schema conventions
│   ├── auth-and-authz.md           # Authentication/authorization patterns
│   ├── deployment-pipeline.md      # CI/CD stages, environment promotion
│   ├── error-handling-strategy.md  # How errors propagate, logging conventions
│   ├── performance-budgets.md      # Latency targets, resource limits
│   └── adr/                        # Architecture Decision Records
│       ├── 001-chose-postgres.md
│       ├── 002-event-sourcing.md
│       └── 003-graphql-gateway.md
```

### The Pointer in CLAUDE.md

```markdown
## Deep Context

Before making architectural changes, read the relevant files in `agent_docs/`.
See `agent_docs/README.md` for an index of available documentation.
Architecture Decision Records in `agent_docs/adr/` explain why key decisions
were made -- read these before proposing alternatives to established patterns.
```

### Writing Guidelines

- **Prefer pointers to copies.** Don't embed code snippets -- they go stale. Instead: "See `src/api/users/handlers.ts:45-80` for the standard handler pattern."
- **Write for Claude, not humans.** Be explicit about constraints and patterns. Claude follows specific instructions better than vague guidance.
- **Keep files focused.** One topic per file. Claude reads files on-demand -- a focused file is more likely to be read when relevant.

### Who Writes These?

Cohort 1 developers (25 power users) draft `agent_docs` based on existing team wikis, design docs, and tribal knowledge. The platform team reviews and standardizes format. Expect 2–4 weeks of focused effort per major codebase.

## Layer 3: Skills (Loaded On-Demand, Invoked Explicitly or Auto-Matched)

Structured workflows Claude invokes as complete procedures. They sit in `.claude/skills/` directories and load only when invoked or when Claude's description-matching determines they're relevant.

Skills differ from rules and CLAUDE.md in an important way: **they're procedural, not declarative.** Rules say "when working on API files, follow these patterns." Skills say "here's a step-by-step procedure for creating a new API endpoint."

See [Skills Library Design](skills-library-design.md) for the full three-tier skills architecture.

## Complete Repository Structure

```sh
repo/
├── CLAUDE.md                          # Short, universal (~60 lines)
├── agent_docs/
│   ├── README.md                      # Index
│   ├── architecture-overview.md
│   ├── data-model.md
│   ├── deployment-pipeline.md
│   └── adr/
│       └── 001-chose-postgres.md
├── .claude/
│   ├── CLAUDE.md                      # Project instructions (alt location)
│   ├── settings.json                  # Project permissions (checked in)
│   ├── settings.local.json            # Personal prefs (gitignored)
│   ├── rules/
│   │   ├── code-style.md              # Global rule
│   │   ├── security.md                # Global rule
│   │   ├── api/
│   │   │   └── rest-conventions.md    # Path-scoped
│   │   └── frontend/
│   │       └── react-patterns.md      # Path-scoped
│   ├── skills/
│   │   ├── new-endpoint/
│   │   │   ├── SKILL.md
│   │   │   └── templates/
│   │   │       └── handler.ts.md
│   │   └── db-migration/
│   │       └── SKILL.md
│   └── commands/
│       ├── deploy-staging.md
│       └── run-tests.md
├── .mcp.json                          # MCP server configuration
└── src/
    └── ...
```
