---
title: "Memory Organization: Structuring CLAUDE.md and Rules for Scale"
linkTitle: "Memory Organization"
weight: 6
---

# Memory Organization: Structuring CLAUDE.md and Rules for Scale

## Executive Summary

Claude Code's memory system is a hierarchy of markdown files loaded into the system prompt. Every file you add costs context window space on every message, so organization affects both clarity and efficiency. The key is putting the right information at the right scope, keeping files concise, and using the rules directory for modularity when a single CLAUDE.md gets unwieldy.

| Memory Type         | Location                               | Scope              | Loaded When                                     | Shared With           |
| ------------------- | -------------------------------------- | ------------------ | ----------------------------------------------- | --------------------- |
| **Managed policy**  | System-level path (IT-managed)         | Organization-wide  | Every message                                   | All users             |
| **Project memory**  | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team + project     | Every message                                   | Team (via git)        |
| **Project rules**   | `./.claude/rules/*.md`                 | Team + project     | Every message (or conditional)                  | Team (via git)        |
| **User memory**     | `~/.claude/CLAUDE.md`                  | All your projects  | Every message                                   | Just you              |
| **User rules**      | `~/.claude/rules/*.md`                 | All your projects  | Every message                                   | Just you              |
| **Project local**   | `./CLAUDE.local.md`                    | You + this project | Every message                                   | Just you (gitignored) |
| **Auto memory**     | `~/.claude/projects/<project>/memory/` | You + this project | First 200 lines / 25KB of MEMORY.md             | Just you              |
| **Child CLAUDE.md** | Subdirectories of working dir          | Context-dependent  | On demand (when Claude reads files in that dir) | Team (via git)        |

### Memory as Context Engineering

Memory organization is a context engineering problem. Every file loaded into the system prompt competes for space in a finite context window. Irrelevant context wastes tokens and degrades the model's ability to follow the instructions that matter (see [Context Cost of Memory](#context-cost-of-memory)).

The memory hierarchy maps to four operations identified in [LangChain's context engineering framework](https://blog.langchain.com/context-engineering-for-agents/):

| Operation    | What It Does                              | Memory Feature                                                         |
| ------------ | ----------------------------------------- | ---------------------------------------------------------------------- |
| **Write**    | Save information outside the window       | Auto memory, MEMORY.md topic files, CLAUDE.local.md                    |
| **Select**   | Pull relevant information into the window | Path-specific rules, `@imports`, on-demand child CLAUDE.md             |
| **Compress** | Retain only essential tokens              | The 200-line / 25KB limit, keeping files concise, periodic review      |
| **Isolate**  | Split context across separate scopes      | User vs project vs local scope, rules directory, topic file separation |

The rest of this guide covers how to apply these operations through Claude Code's memory system.

## Table of Contents

- [Memory Organization: Structuring CLAUDE.md and Rules for Scale](#memory-organization-structuring-claudemd-and-rules-for-scale)
  - [Executive Summary](#executive-summary)
    - [Memory as Context Engineering](#memory-as-context-engineering)
  - [Table of Contents](#table-of-contents)
  - [The Memory Hierarchy](#the-memory-hierarchy)
    - [How Files Are Discovered](#how-files-are-discovered)
    - [Precedence](#precedence)
    - [What Goes Where](#what-goes-where)
  - [User Memory](#user-memory)
    - [What Belongs in User Memory](#what-belongs-in-user-memory)
    - [Keeping User Memory Tight](#keeping-user-memory-tight)
  - [Project Memory](#project-memory)
    - [Team-Shared Instructions](#team-shared-instructions)
    - [Project vs User Scope](#project-vs-user-scope)
    - [The /init Bootstrap](#the-init-bootstrap)
    - [Onboarding Teammates](#onboarding-teammates)
  - [Project Local Memory](#project-local-memory)
  - [The Rules Directory](#the-rules-directory)
    - [When to Use Rules vs CLAUDE.md](#when-to-use-rules-vs-claudemd)
    - [Path-Specific Rules](#path-specific-rules)
    - [Organizing with Subdirectories](#organizing-with-subdirectories)
    - [Sharing Rules Across Projects](#sharing-rules-across-projects)
  - [Auto Memory](#auto-memory)
    - [What Claude Remembers](#what-claude-remembers)
    - [The 200-Line / 25KB Limit](#the-200-line--25kb-limit)
    - [Topic Files](#topic-files)
    - [Reviewing Auto Memory for Accuracy](#reviewing-auto-memory-for-accuracy)
    - [Managing Auto Memory](#managing-auto-memory)
  - [Imports](#imports)
  - [Context Cost of Memory](#context-cost-of-memory)
    - [Every Line Has a Price](#every-line-has-a-price)
    - [Measuring Your Memory Footprint](#measuring-your-memory-footprint)
    - [How Memory Interacts with Compaction](#how-memory-interacts-with-compaction)
    - [Model-Specific Instruction Preferences](#model-specific-instruction-preferences)
  - [Common Mistakes](#common-mistakes)
    - [Putting Everything in User CLAUDE.md](#putting-everything-in-user-claudemd)
    - [Generic Instructions That Add No Value](#generic-instructions-that-add-no-value)
    - [Contradictory Rules Across Scopes](#contradictory-rules-across-scopes)
    - [Not Using CLAUDE.local.md](#not-using-claudelocalmd)
    - [Monolithic CLAUDE.md in Large Projects](#monolithic-claudemd-in-large-projects)
  - [Best Practices](#best-practices)
  - [References](#references)

## The Memory Hierarchy

### How Files Are Discovered

Claude Code discovers memory files by walking up the directory tree from your working directory to the filesystem root, loading any CLAUDE.md or CLAUDE.local.md files it finds along the way:

```text
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
  ~/.claude/projects/<project>/memory/MEMORY.md  (auto memory, first 200 lines / 25KB)
```

Child directories (below your working directory) are different -- their CLAUDE.md files load on demand only when Claude reads files in those directories, not at startup.

The `--add-dir` flag gives Claude access to additional directories outside your working directory. By default, CLAUDE.md files from added directories are not loaded. Set `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1` to include their memory files.

### Precedence

The general rule: more specific instructions take precedence over broader ones. The official docs confirm two specifics:

- **Managed policy** overrides everything -- it represents organizational requirements that individual projects shouldn't override
- **Project rules** take priority over **user-level rules** -- user rules are loaded first, then project rules override where they conflict

Beyond that, the docs don't establish a strict total ordering. In practice, conflicts are rare if you put the right content at the right scope:

```text
Managed policy          (organization-wide, highest priority)
    ↓ overrides
Project-level files     (CLAUDE.md, .claude/rules/*.md)
    ↓ overrides
User-level files        (~/.claude/CLAUDE.md, ~/.claude/rules/*.md)

CLAUDE.local.md         (personal + project-specific, gitignored)
Auto memory (MEMORY.md) (Claude's notes, lowest priority)
```

### What Goes Where

```text
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

```text
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

```sh
/init
```

This analyzes your project structure and creates a reasonable starting point -- but much of what `/init` generates is generic content (build commands Claude could discover, language conventions Claude already follows). The [benchmark findings on generic instructions](#generic-instructions-that-add-no-value) suggest this kind of content falls into the category that reduces quality rather than improving it. The study tested standardized coding tasks rather than `/init` output directly, but the mechanism applies: instructions that restate what the model already knows create adherence penalty without adding signal.

After running `/init`, review every line and delete anything you can't justify with: "would removing this cause Claude to make a mistake in this specific repo?" What survives that filter is your actual project memory. Everything else is paying a context tax for nothing.

### Onboarding Teammates

The `/team-onboarding` command generates a teammate ramp-up guide from your local Claude Code usage:

```sh
/team-onboarding
```

Per the [release notes](https://code.claude.com/docs/en/whats-new/2026-w15), run it in a project you know well and hand the output to a new teammate so they can replay your setup instead of starting from defaults. Because the guide is derived from how you use Claude Code in a given project, run it from a repo you've spent real time in.

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

## The Rules Directory

**Location:** `./.claude/rules/*.md` (project) or `~/.claude/rules/*.md` (user)

### When to Use Rules vs CLAUDE.md

The rules directory solves a specific problem: when a single CLAUDE.md gets too large or when different rules apply to different parts of the codebase.

```text
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

This rule only loads when Claude is working with TypeScript files under `src/api/` or `src/middleware/`. It doesn't burden the context when working on other parts of the codebase. This is a **pull-based** pattern -- the model gets information when it reaches for relevant files, rather than having everything pushed into the window upfront. Since irrelevant context degrades performance (see [Context Cost of Memory](#context-cost-of-memory)), loading rules only when they're relevant avoids that penalty.

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

```sh
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

Everything above -- CLAUDE.md, CLAUDE.local.md, and the rules directory -- is **instructions you write for Claude**. You author them, you version-control them, and you decide what goes in. The next section covers a different category: **notes Claude writes for itself**.

## Auto Memory

**Location:** `~/.claude/projects/<project>/memory/`

Auto memory is Claude's own scratchpad. Where CLAUDE.md files contain your instructions, auto memory contains Claude's notes -- patterns it discovers, debugging insights, architecture decisions, and your preferences as it observes them. You can ask Claude to remember things, and you can edit the files directly, but Claude is the primary author.

Each project's memory directory is derived from the git repository root, so all subdirectories within the same repo share one auto memory directory. Git worktrees get separate memory directories.

### What Claude Remembers

As Claude works, it may save things like:

- Build commands and test conventions
- Solutions to tricky problems
- Key file locations and module relationships
- Your communication style and tool preferences

You can also tell Claude to remember specific things:

```text
"remember that we use pnpm, not npm"
"save to memory that the API tests require a local Redis instance"
```

### The 200-Line / 25KB Limit

Only the first 200 lines of `MEMORY.md` are loaded into the system prompt, subject to a 25KB byte cap (whichever limit is hit first). Everything beyond is invisible at session start. These are hard constraints -- MEMORY.md must be concise.

```sh
~/.claude/projects/<project>/memory/
├── MEMORY.md           # Index file (first 200 lines loaded)
├── debugging.md        # Detailed debugging notes
├── api-conventions.md  # API design decisions
└── patterns.md         # Codebase patterns
```

MEMORY.md should act as an index -- concise summaries with links to detailed topic files. Topic files are loaded on demand when Claude needs the information, not at startup. The 25KB byte limit means table-heavy or code-heavy index files can hit the cap before reaching 200 lines.

### Topic Files

Topic files let you store detailed notes without hitting the 200-line / 25KB limit:

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

The pattern: MEMORY.md has the summary, topic files have the detail. Claude reads topic files when it needs them. This is another pull-based pattern -- keeping the always-loaded index small while letting Claude retrieve detailed context on demand.

### Reviewing Auto Memory for Accuracy

Auto memory can capture wrong information. If Claude records an incorrect debugging insight, an outdated architectural assumption, or a misunderstood convention, that error gets loaded into every subsequent session. In context engineering terms, this is **context poisoning** -- false information in the window that the model treats as ground truth and builds on.

Review MEMORY.md periodically for accuracy as well as length. Look for:

- **Outdated facts** -- Architecture that changed, dependencies that were replaced, conventions that evolved
- **Incorrect conclusions** -- Debugging insights from sessions where the root cause turned out to be something else
- **Stale preferences** -- Tool or workflow preferences you've since changed

A wrong memory entry is worse than a missing one. Missing information means Claude has to discover it; wrong information means Claude confidently acts on something false.

### Managing Auto Memory

Use `/memory` during a session to open any memory file (including MEMORY.md) in your editor for direct editing. The `/memory` selector also includes a toggle to enable or disable auto memory.

Auto memory is enabled by default. To disable it:

- **Per session:** Use `/memory` and toggle it off
- **Per project:** Set `"autoMemoryEnabled": false` in `.claude/settings.json`
- **All projects:** Set `"autoMemoryEnabled": false` in `~/.claude/settings.json`
- **Environment override:** `CLAUDE_CODE_DISABLE_AUTO_MEMORY=1` overrides all other settings (useful for CI)

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

## Context Cost of Memory

### Every Line Has a Price

Every memory file loaded into the system prompt consumes context window space on every message. This is the same cost model described in the [token optimization]({{< relref "/internals/token-optimization" >}}) and [system prompt]({{< relref "/internals/system-prompt" >}}) articles.

The cost is both budget and accuracy. Research on context degradation (Chroma Research, 2025) found that adding irrelevant context to the window degrades model performance. Even a single piece of similar-but-wrong information reduces accuracy, though severity varies by model and task, and multiple distractors compound the damage. Generic instructions like "write clean code" waste tokens and compete for attention with your specific, actionable rules.

```text
Context window budget (e.g., 200K tokens):
┌──────────────────────────────────────────────────┐
│ Core instructions + tool defs    (~6,000-10,000) │
│ CLAUDE.md files (all scopes)     (~2,000-4,000)  │ ← Your memory files
│ Skill + subagent catalogs        (~3,000-5,000)  │
│ Auto memory (MEMORY.md)          (~200-500)      │
│ Conversation history             (grows)         │
│ Available for work               (what's left)   │
└──────────────────────────────────────────────────┘
```

[Prompt caching]({{< relref "/internals/prompt-caching" >}}) means this content is cheap to re-send (90% discount after the first message), but the context window space is consumed regardless. A 4,000-token CLAUDE.md costs ~$0.40 per 200-message session with caching -- not expensive, but those 4,000 tokens are unavailable for actual work.

### Measuring Your Memory Footprint

A rough estimate of your CLAUDE.md token cost:

```text
Lines of markdown × ~7 tokens/line ≈ total tokens

Example:
  User CLAUDE.md:     230 lines × 7 ≈ 1,600 tokens
  Project CLAUDE.md:   80 lines × 7 ≈   560 tokens
  Project rules:       60 lines × 7 ≈   420 tokens
  MEMORY.md:          150 lines × 7 ≈ 1,050 tokens
  ──────────────────────────────────────────────────
  Total:                             ≈ 3,630 tokens
```

This is a rough estimate -- actual token count depends on content density. Code blocks and tables tend to use roughly 1.5-2x more tokens per line than plain prose due to syntax characters, pipe delimiters, and alignment markers. If your CLAUDE.md is table-heavy, budget accordingly.

### How Memory Interacts with Compaction

When a conversation approaches the context window limit, Claude Code triggers auto-compaction -- the conversation history is summarized to free space. Memory files are structurally exempt from this process. Compaction only operates on the messages array (conversation turns, tool results, code output). The system prompt -- which contains CLAUDE.md, rules, and MEMORY.md -- exists outside that array and is never modified or removed by compaction.

This has a practical implication: instructions that must persist across a long session belong in memory files, not in conversation. If you tell Claude "always run tests before committing" in chat, that instruction may be lost or diluted when conversation history is summarized. If you put it in CLAUDE.md, it's present at full fidelity on every message.

```text
What compaction touches:
  Conversation turns          → summarized
  Tool results and code output → compressed or dropped

What compaction does not touch:
  System prompt (CLAUDE.md, rules, MEMORY.md) → unchanged
```

### Model-Specific Instruction Preferences

A [CLAUDE.md benchmark](https://techloom.it/blog/claudemd-benchmark-results.html) found that different models respond differently to the same instructions. Some models performed best with no instructions at all, while others benefited from structured formatting or lightweight workflow checklists. The same instruction set that helped one model hurt another. As with the other benchmark findings referenced in this article, these results come from standardized single-file coding tasks and may not transfer to project-specific or multi-file workflows.

If your team uses model routing -- a fast model for simple tasks, a capable model for complex ones -- a one-size-fits-all CLAUDE.md may not serve all models equally. Consider whether your instructions are pulling their weight across the models you deploy to, or whether model-specific instruction sets (via environment-based CLAUDE.md selection or conditional rules) would serve you better.

## Common Mistakes

### Putting Everything in User CLAUDE.md

```text
Bad: 230-line user CLAUDE.md with project-specific Go rules,
     React rules, Python rules, and team conventions

Good: User CLAUDE.md has personal preferences (~50-80 lines)
      Project-specific rules live in each project's CLAUDE.md
```

Your user CLAUDE.md loads in every project. Go conventions shouldn't load when you're working in a JavaScript project.

### Generic Instructions That Add No Value

Generic instructions actively reduce output quality. A [benchmark study of CLAUDE.md effectiveness](https://techloom.it/blog/claudemd-benchmark-results.html) found that adding generic coding instructions consistently reduced quality scores compared to an empty CLAUDE.md. The more generic tokens, the worse the results -- even a handful of bullet points like "write clean code" and "handle edge cases" made things worse.

The mechanism is an **adherence penalty**: generic instructions don't make Claude try harder at things it already does well. Instead, they create an explicit scorecard that can only subtract points. When you write "handle errors properly," you haven't taught Claude anything -- you've given the evaluator (internal or external) a criterion to penalize against when error handling falls short of perfect. The instructions function as a ceiling the model can fail to reach, with no upside when it meets expectations it would have met anyway.

**Caveat:** this finding held for standardized, single-file coding tasks. The study explicitly notes that its scope does not cover project-specific architectural context, multi-file operations, or workflow rules. The value of CLAUDE.md is in encoding knowledge Claude doesn't already have -- your architecture, your deployment constraints, your domain conventions. That kind of content wasn't tested and isn't subject to the same penalty.

```text
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

```text
User CLAUDE.md:    "Use 4-space indentation"
Project CLAUDE.md: "Use tabs for indentation"
```

When rules conflict, Claude has to guess which one wins. More specific (project) takes precedence over general (user), but it's better to avoid the conflict entirely. Keep scope-appropriate rules at the right scope.

### Not Using CLAUDE.local.md

```text
Bad: Committing your personal sandbox URLs and local ports
     to the team's CLAUDE.md

Good: Personal environment details in CLAUDE.local.md
      (automatically gitignored)
```

CLAUDE.local.md exists specifically for personal, project-specific preferences that shouldn't be shared with the team.

### Monolithic CLAUDE.md in Large Projects

```text
Bad: 500-line CLAUDE.md covering frontend, backend, database,
     deployment, testing, and security all in one file

Good: Focused CLAUDE.md (~50-80 lines) with architecture overview
      Detailed rules in .claude/rules/ by domain:
      - .claude/rules/frontend/react.md
      - .claude/rules/backend/api.md
      - .claude/rules/testing.md
```

The rules directory exists for this case. Use it when CLAUDE.md exceeds ~100 lines or when rules apply to different parts of the codebase.

## Best Practices

1. **Put the right content at the right scope** -- Personal preferences in user memory, team conventions in project memory, environment details in local memory.

2. **Be specific, not generic** -- "Use 2-space indentation" beats "format code properly." Every line should tell Claude something it can't infer on its own.

3. **Prefer positive directives over prohibitions** -- "Use slog for logging" outperforms "don't use fmt.Println." Negative instructions [prime the model toward the failure mode](https://techloom.it/blog/claudemd-benchmark-results.html) being described rather than away from it. When you must prohibit something, pair it with the preferred alternative.

4. **Understand that instructions raise the floor, not the ceiling** -- Instructions prevent bad outlier runs more than they improve average quality. A [benchmark study](https://techloom.it/blog/claudemd-benchmark-results.html) found that workflow checklists eliminated the worst outlier runs on instruction-following tasks while barely moving the average. If you need consistent output in production pipelines or automated workflows, a small targeted instruction set has measurable value even when average quality stays flat.

5. **Use the rules directory for large projects** -- When CLAUDE.md exceeds ~100 lines or when different rules apply to different file types.

6. **Use path-specific rules sparingly** -- Only add `paths` frontmatter when rules genuinely apply to specific file types. Most rules are universal within a project.

7. **Keep MEMORY.md as an index** -- Concise summaries within 200 lines / 25KB, detailed notes in topic files that load on demand.

8. **Use CLAUDE.local.md for personal environment details** -- Ports, URLs, test credentials, local overrides. It's gitignored automatically.

9. **Use imports for shared content** -- Rather than duplicating content across files, import with `@path/to/file` syntax.

10. **Review periodically** -- Projects evolve. Rules that were relevant 3 months ago may not be relevant now. Remove stale content to free context window space.

11. **Don't duplicate what's in the codebase** -- If your coding standards are in a `CONTRIBUTING.md` or style guide, import it rather than rewriting it in CLAUDE.md.

12. **Prefer fewer, focused files over many small ones** -- Each file adds discovery overhead. Group related rules together unless they have different path scopes.

13. **Use clear section headers as retrieval anchors** -- Well-structured content with distinct headers, bullet lists, and tables is easier for models to navigate and retrieve from than long paragraphs in CLAUDE.md files.

14. **Put durable instructions in files, not conversation** -- Instructions mentioned in chat may be lost or diluted during [auto-compaction](#how-memory-interacts-with-compaction). If an instruction needs to persist across a long session, it belongs in a memory file.

## References

- [Manage Claude's Memory (Claude Code Docs)](https://code.claude.com/docs/en/memory) -- Official documentation on the memory system
- [System Prompt Article]({{< relref "/internals/system-prompt" >}}) -- How CLAUDE.md files become part of the system prompt
- [Token Optimization Article]({{< relref "/internals/token-optimization" >}}) -- Managing per-message token overhead
- [Context Management Article]({{< relref "/internals/context-management" >}}) -- Working within the context window budget
- [Effective Prompting Article]({{< relref "effective-prompting" >}}) -- CLAUDE.md as persistent prompting
- [Chroma Research: Context Rot](https://research.trychroma.com/context-rot) -- Research on how irrelevant context degrades LLM accuracy
- [LangChain: Context Engineering for Agents](https://blog.langchain.com/context-engineering-for-agents/) -- The write/select/compress/isolate framework
- [CLAUDE.md Benchmark Results](https://techloom.it/blog/claudemd-benchmark-results.html) -- Benchmark study on instruction effectiveness across models
