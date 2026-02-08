# Memory Organization: Structuring CLAUDE.md and Rules for Scale

## Executive Summary

Claude Code's memory system is a hierarchy of markdown files loaded into the system prompt. Every file you add costs context window space on every message, so organization isn't just about clarity -- it's about efficiency. The key is putting the right information at the right scope, keeping files concise, and using the rules directory for modularity when a single CLAUDE.md gets unwieldy.

| Memory Type         | Location                               | Scope              | Loaded When                                     | Shared With           |
| ------------------- | -------------------------------------- | ------------------ | ----------------------------------------------- | --------------------- |
| **Managed policy**  | System-level path (IT-managed)         | Organization-wide  | Every message                                   | All users             |
| **Project memory**  | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team + project     | Every message                                   | Team (via git)        |
| **Project rules**   | `./.claude/rules/*.md`                 | Team + project     | Every message (or conditional)                  | Team (via git)        |
| **User memory**     | `~/.claude/CLAUDE.md`                  | All your projects  | Every message                                   | Just you              |
| **User rules**      | `~/.claude/rules/*.md`                 | All your projects  | Every message                                   | Just you              |
| **Project local**   | `./CLAUDE.local.md`                    | You + this project | Every message                                   | Just you (gitignored) |
| **Auto memory**     | `~/.claude/projects/<project>/memory/` | You + this project | First 200 lines of MEMORY.md                    | Just you              |
| **Child CLAUDE.md** | Subdirectories of working dir          | Context-dependent  | On demand (when Claude reads files in that dir) | Team (via git)        |

---

## Table of Contents

- [The Memory Hierarchy](#the-memory-hierarchy)
  - [How Files Are Discovered](#how-files-are-discovered)
  - [Precedence](#precedence)
  - [What Goes Where](#what-goes-where)
- [User Memory (~/.claude/CLAUDE.md)](#user-memory)
  - [What Belongs Here](#what-belongs-in-user-memory)
  - [Keeping It Tight](#keeping-user-memory-tight)
- [Project Memory (./CLAUDE.md)](#project-memory)
  - [Team-Shared Instructions](#team-shared-instructions)
  - [Project vs User Scope](#project-vs-user-scope)
  - [The /init Bootstrap](#the-init-bootstrap)
- [Project Local Memory (./CLAUDE.local.md)](#project-local-memory)
- [The Rules Directory (.claude/rules/)](#the-rules-directory)
  - [When to Use Rules vs CLAUDE.md](#when-to-use-rules-vs-claudemd)
  - [Path-Specific Rules](#path-specific-rules)
  - [Organizing with Subdirectories](#organizing-with-subdirectories)
  - [Sharing Rules Across Projects](#sharing-rules-across-projects)
- [Auto Memory](#auto-memory)
  - [What Claude Remembers](#what-claude-remembers)
  - [The 200-Line Limit](#the-200-line-limit)
  - [Topic Files](#topic-files)
- [Imports (@path Syntax)](#imports)
- [Context Cost of Memory](#context-cost-of-memory)
  - [Every Line Has a Price](#every-line-has-a-price)
  - [Measuring Your Memory Footprint](#measuring-your-memory-footprint)
- [Common Mistakes](#common-mistakes)
- [Best Practices](#best-practices)
- [References](#references)

---

## The Memory Hierarchy

### How Files Are Discovered

Claude Code discovers memory files by walking up the directory tree from your working directory to the filesystem root, loading any CLAUDE.md or CLAUDE.local.md files it finds along the way:

```
Working directory: /home/user/projects/my-app/src/

Files loaded (bottom to top):
  /home/user/projects/my-app/src/CLAUDE.md     (if exists)
  /home/user/projects/my-app/CLAUDE.md         (if exists)
  /home/user/projects/CLAUDE.md                (if exists)
  /home/user/CLAUDE.md                         (if exists)
  ~/.claude/CLAUDE.md                          (user scope, always)

Plus:
  /home/user/projects/my-app/.claude/rules/*.md  (project rules)
  ~/.claude/rules/*.md                           (user rules)
  ~/.claude/projects/<project>/memory/MEMORY.md  (auto memory, first 200 lines)
```

Child directories (below your working directory) are different -- their CLAUDE.md files load on demand only when Claude reads files in those directories, not at startup.

### Precedence

More specific instructions take precedence over broader ones:

```
Highest priority
    │
    ├── Managed policy (organization-wide, IT-managed)
    ├── Project CLAUDE.md (repo root)
    ├── Project rules (.claude/rules/*.md)
    ├── User CLAUDE.md (~/.claude/CLAUDE.md)
    ├── User rules (~/.claude/rules/*.md)
    ├── Project local (CLAUDE.local.md)
    └── Auto memory (MEMORY.md)
    │
Lowest priority
```

In practice, conflicts are rare if you put the right content at the right scope. Managed policy overrides everything because it represents organizational requirements (security policies, compliance rules) that individual projects shouldn't override.

### What Goes Where

```
Is this instruction...
│
├── Required by your organization?
│   → Managed policy (IT deploys it)
│
├── Specific to this project, shared with the team?
│   │
│   ├── Applies to all project files → Project CLAUDE.md
│   │
│   └── Applies to specific file types → .claude/rules/ with paths
│
├── Your personal preference, all projects?
│   → User CLAUDE.md (~/.claude/CLAUDE.md)
│
├── Your personal preference, this project only?
│   → CLAUDE.local.md (gitignored)
│
└── Something Claude learned during a session?
    → Auto memory (Claude manages this)
```

---

## User Memory

**Location:** `~/.claude/CLAUDE.md`

This is your personal CLAUDE.md -- loaded into every Claude Code session regardless of which project you're in. It's for preferences and rules that apply to all your work.

### What Belongs in User Memory

- **Your coding style preferences** -- Indentation, naming conventions, formatting rules
- **Your workflow rules** -- Branching strategy, commit habits, TDD requirements
- **Tool preferences** -- "Use bun instead of npm," "use slog instead of fmt.Println"
- **Communication preferences** -- How you want Claude to interact with you
- **Language-specific standards** -- Go style guide links, TypeScript conventions

Example structure:

```markdown
# CLAUDE.md

## Coding Standards

- Use 2-space indentation in TypeScript, tabs in Go
- Prefer simple solutions over clever ones

## Workflow

- Always create feature branches, never commit to main
- Run tests before committing
- Use conventional commits

## Communication

- Be direct, don't pad with pleasantries
- Push back on bad ideas
```

### Keeping User Memory Tight

Your user CLAUDE.md applies to every project. A 200-line file means ~1,500-2,000 tokens loaded into every session, even projects where half the rules don't apply.

**Strategies:**

- Move project-specific rules to the project's CLAUDE.md
- Move language-specific rules to `~/.claude/rules/` with path conditions
- Keep only truly universal preferences in the main file
- Review periodically -- remove rules that are no longer relevant

---

## Project Memory

**Location:** `./CLAUDE.md` or `./.claude/CLAUDE.md`

Project memory is shared with your team via version control. It defines how Claude should work within this specific codebase.

### Team-Shared Instructions

Effective project CLAUDE.md content:

```markdown
# Project: API Server

## Stack

- Go 1.22, Chi router, sqlc for queries
- PostgreSQL 16 with pgx driver

## Architecture

- Handlers in internal/handler/
- Database queries in internal/db/queries/
- Shared types in internal/model/

## Conventions

- Error responses use ErrResponse from internal/api/
- Structured logging only (slog) -- never fmt.Println
- All new endpoints need integration tests

## Commands

- Build: go build ./cmd/server
- Test: go test ./...
- Integration test: go test -tags=integration ./...
- Generate queries: sqlc generate
- Lint: golangci-lint run
```

Notice what this covers:

- **Stack** -- What technologies the project uses
- **Architecture** -- Where things live so Claude doesn't have to search
- **Conventions** -- Project-specific rules that differ from defaults
- **Commands** -- Build/test/lint commands so Claude doesn't guess

### Project vs User Scope

```
User CLAUDE.md (your preferences):
  "Always use conventional commits"
  "Run tests before committing"
  "Prefer simple solutions"

Project CLAUDE.md (team standards):
  "Use Chi router for HTTP endpoints"
  "All handlers go in internal/handler/"
  "Integration tests use testcontainers"
```

The user scope is about **how you work**. The project scope is about **how this project works**. Keep them separate.

### The /init Bootstrap

For new projects, the `/init` command generates a starter CLAUDE.md based on the codebase:

```
> /init
```

This analyzes your project structure and creates a reasonable starting point. Review and edit it -- the generated file is a starting point, not a finished product.

---

## Project Local Memory

**Location:** `./CLAUDE.local.md`

This file is automatically gitignored -- it's for your personal preferences in a specific project that shouldn't be shared with the team.

**Good uses:**

- Your local development URLs and ports
- Personal test data or sandbox credentials
- Overrides for team conventions you handle differently locally
- Notes about your local environment setup

```markdown
# Local Development

## My Environment

- API runs on localhost:8080
- Database: localhost:5432/myapp_dev
- Redis: localhost:6379

## Testing

- Use test-data/fixtures/ for integration test data
- My local Postgres uses password "dev" for testing
```

---

## The Rules Directory

**Location:** `./.claude/rules/*.md` (project) or `~/.claude/rules/*.md` (user)

### When to Use Rules vs CLAUDE.md

The rules directory solves a specific problem: when a single CLAUDE.md gets too large or when different rules apply to different parts of the codebase.

```
When CLAUDE.md is enough:
  - Small to medium projects
  - Under ~100 lines of instructions
  - Rules apply uniformly to all files

When rules directory helps:
  - Large projects with multiple languages or domains
  - Different conventions for frontend vs backend
  - Rules that only apply to specific file types
  - Teams that want to version-control rules independently
```

### Path-Specific Rules

Rules files can include YAML frontmatter with a `paths` field to apply only when Claude is working with matching files:

```markdown
---
paths:
  - "src/api/**/*.ts"
  - "src/middleware/**/*.ts"
---

# API Development Rules

- All endpoints must validate input with Zod schemas
- Use the standard error response format from lib/errors.ts
- Include OpenAPI documentation comments on all handlers
```

This rule only loads when Claude is working with TypeScript files under `src/api/` or `src/middleware/`. It doesn't burden the context when working on other parts of the codebase.

Supported glob patterns:

| Pattern                | Matches                             |
| ---------------------- | ----------------------------------- |
| `**/*.ts`              | All TypeScript files anywhere       |
| `src/**/*`             | All files under src/                |
| `*.md`                 | Markdown files in project root only |
| `src/components/*.tsx` | React components in one directory   |
| `**/*.{ts,tsx}`        | TypeScript and TSX files anywhere   |
| `{src,lib}/**/*.ts`    | TypeScript files in src/ or lib/    |

Rules without a `paths` field load unconditionally -- same as being in CLAUDE.md.

### Organizing with Subdirectories

For larger projects, organize rules into subdirectories:

```
.claude/rules/
├── frontend/
│   ├── react.md           # React component conventions
│   ├── styles.md          # CSS/styling rules
│   └── testing.md         # Frontend test patterns
├── backend/
│   ├── api.md             # API endpoint conventions
│   ├── database.md        # Query and migration rules
│   └── testing.md         # Backend test patterns
├── security.md            # Security rules (all files)
└── code-style.md          # General code style (all files)
```

All `.md` files are discovered recursively. Use descriptive filenames -- the name should tell you what's inside without opening the file.

### Sharing Rules Across Projects

Symlinks let you share rules between projects:

```bash
# Share a common rules directory
ln -s ~/shared-claude-rules .claude/rules/shared

# Share individual rule files
ln -s ~/company-standards/security.md .claude/rules/security.md
```

This is useful for organizations with coding standards that apply across multiple repositories without needing managed policy.

---

## Auto Memory

**Location:** `~/.claude/projects/<project>/memory/`

Auto memory is different from CLAUDE.md files -- it's notes Claude writes for itself, not instructions you write for Claude. Claude records patterns it discovers, debugging insights, architecture notes, and your preferences as it works.

### What Claude Remembers

As Claude works, it may save things like:

- Build commands and test conventions
- Solutions to tricky problems
- Key file locations and module relationships
- Your communication style and tool preferences

You can also tell Claude to remember specific things:

```
"remember that we use pnpm, not npm"
"save to memory that the API tests require a local Redis instance"
```

### The 200-Line Limit

Only the first 200 lines of `MEMORY.md` are loaded into the system prompt. Everything beyond line 200 is invisible at session start. This is a hard constraint -- MEMORY.md must be concise.

```
~/.claude/projects/<project>/memory/
├── MEMORY.md           # Index file (first 200 lines loaded)
├── debugging.md        # Detailed debugging notes
├── api-conventions.md  # API design decisions
└── patterns.md         # Codebase patterns
```

MEMORY.md should act as an index -- concise summaries with links to detailed topic files. Topic files are loaded on demand when Claude needs the information, not at startup.

### Topic Files

Topic files let you store detailed notes without hitting the 200-line limit:

```markdown
# MEMORY.md (concise index)

## Project Overview

- Go API server using Chi router and sqlc
- PostgreSQL 16, deployed on Kubernetes

## Key Files

- Entry point: cmd/server/main.go
- Router setup: internal/router/router.go

## Detailed Notes

- See [debugging.md](debugging.md) for common error patterns
- See [api-conventions.md](api-conventions.md) for endpoint design decisions
```

The pattern: MEMORY.md has the summary, topic files have the detail. Claude reads topic files when it needs them.

---

## Imports

CLAUDE.md files support importing other files using `@path/to/file` syntax:

```markdown
See @README for project overview and @package.json for dependencies.

# Git Workflow

- Follow the conventions in @docs/git-instructions.md
```

Key details:

- Relative paths resolve relative to the file containing the import (not the working directory)
- Absolute paths and home-directory paths (`@~/.claude/my-rules.md`) are supported
- Imports can be recursive (up to 5 levels deep)
- Imports inside code blocks and code spans are ignored
- First use in a project triggers an approval dialog

**Cross-worktree sharing with imports:**

CLAUDE.local.md only exists in one worktree. If you work across git worktrees, use a home-directory import instead:

```markdown
# CLAUDE.local.md

- @~/.claude/my-project-instructions.md
```

This way all worktrees share the same personal instructions.

---

## Context Cost of Memory

### Every Line Has a Price

Every memory file loaded into the system prompt consumes context window space on every message. This is the same cost model described in the [token optimization](claude-code-token-optimization.md) and [system prompt](claude-code-system-prompt.md) articles.

```
Context window budget (e.g., 200K tokens):
┌─────────────────────────────────────────────────┐
│ Core instructions + tool defs    (~6,000-10,000) │
│ CLAUDE.md files (all scopes)     (~2,000-4,000)  │ ← Your memory files
│ Skill + subagent catalogs        (~3,000-5,000)  │
│ Auto memory (MEMORY.md)          (~200-500)      │
│ Conversation history             (grows)         │
│ Available for work               (what's left)   │
└─────────────────────────────────────────────────┘
```

[Prompt caching](claude-code-prompt-caching.md) means this content is cheap to re-send (90% discount after the first message), but the context window space is consumed regardless. A 4,000-token CLAUDE.md costs ~$0.40 per 200-message session with caching -- not expensive, but those 4,000 tokens are unavailable for actual work.

### Measuring Your Memory Footprint

A rough estimate of your CLAUDE.md token cost:

```
Lines of markdown × ~7 tokens/line ≈ total tokens

Example:
  User CLAUDE.md:     230 lines × 7 ≈ 1,600 tokens
  Project CLAUDE.md:   80 lines × 7 ≈   560 tokens
  Project rules:       60 lines × 7 ≈   420 tokens
  MEMORY.md:          150 lines × 7 ≈ 1,050 tokens
  ──────────────────────────────────────────────────
  Total:                             ≈ 3,630 tokens
```

This is a rough estimate -- actual token count depends on content density. Code blocks and tables tend to use more tokens per line than plain text.

---

## Common Mistakes

### Putting Everything in User CLAUDE.md

```
Bad: 230-line user CLAUDE.md with project-specific Go rules,
     React rules, Python rules, and team conventions

Good: User CLAUDE.md has personal preferences (~50-80 lines)
      Project-specific rules live in each project's CLAUDE.md
```

Your user CLAUDE.md loads in every project. Go conventions shouldn't load when you're working in a JavaScript project.

### Generic Instructions That Add No Value

```
Bad:  "Write clean, maintainable code"
      "Follow best practices"
      "Use proper error handling"
      (Claude already does these -- you're spending tokens to say nothing)

Good: "Use slog for all logging, never fmt.Println"
      "Error messages must include the operation that failed"
      "Integration tests use testcontainers, not mocks"
      (Specific to your project, can't be inferred)
```

Every line in CLAUDE.md should tell Claude something it wouldn't know or do by default. If removing the line wouldn't change Claude's behavior, remove it.

### Contradictory Rules Across Scopes

```
User CLAUDE.md:    "Use 4-space indentation"
Project CLAUDE.md: "Use tabs for indentation"
```

When rules conflict, Claude has to guess which one wins. More specific (project) takes precedence over general (user), but it's better to avoid the conflict entirely. Keep scope-appropriate rules at the right scope.

### Not Using CLAUDE.local.md

```
Bad: Committing your personal sandbox URLs and local ports
     to the team's CLAUDE.md

Good: Personal environment details in CLAUDE.local.md
      (automatically gitignored)
```

CLAUDE.local.md exists specifically for personal, project-specific preferences that shouldn't be shared with the team.

### Monolithic CLAUDE.md in Large Projects

```
Bad: 500-line CLAUDE.md covering frontend, backend, database,
     deployment, testing, and security all in one file

Good: Focused CLAUDE.md (~50-80 lines) with architecture overview
      Detailed rules in .claude/rules/ by domain:
      - .claude/rules/frontend/react.md
      - .claude/rules/backend/api.md
      - .claude/rules/testing.md
```

The rules directory exists for this case. Use it when CLAUDE.md exceeds ~100 lines or when rules apply to different parts of the codebase.

---

## Best Practices

1. **Put the right content at the right scope** -- Personal preferences in user memory, team conventions in project memory, environment details in local memory.

2. **Be specific, not generic** -- "Use 2-space indentation" beats "format code properly." Every line should tell Claude something it can't infer on its own.

3. **Use the rules directory for large projects** -- When CLAUDE.md exceeds ~100 lines or when different rules apply to different file types.

4. **Use path-specific rules sparingly** -- Only add `paths` frontmatter when rules genuinely apply to specific file types. Most rules are universal within a project.

5. **Keep MEMORY.md as an index** -- Concise summaries within 200 lines, detailed notes in topic files that load on demand.

6. **Use CLAUDE.local.md for personal environment details** -- Ports, URLs, test credentials, local overrides. It's gitignored automatically.

7. **Use imports for shared content** -- Rather than duplicating content across files, import with `@path/to/file` syntax.

8. **Review periodically** -- Projects evolve. Rules that were relevant 3 months ago may not be relevant now. Remove stale content to free context window space.

9. **Don't duplicate what's in the codebase** -- If your coding standards are in a `CONTRIBUTING.md` or style guide, import it rather than rewriting it in CLAUDE.md.

10. **Prefer fewer, focused files over many small ones** -- Each file adds discovery overhead. Group related rules together unless they have different path scopes.

---

## References

- [Manage Claude's Memory (Claude Code Docs)](https://code.claude.com/docs/en/memory) -- Official documentation on the memory system
- [System Prompt Article](claude-code-system-prompt.md) -- How CLAUDE.md files become part of the system prompt
- [Token Optimization Article](claude-code-token-optimization.md) -- Managing per-message token overhead
- [Context Management Article](claude-code-context-management.md) -- Working within the context window budget
- [Effective Prompting Article](claude-code-effective-prompting.md) -- CLAUDE.md as persistent prompting
