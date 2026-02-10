---
title: "Skills vs. Slash Commands vs. Rules — Decision Framework"
weight: 4
---

# Skills vs. Slash Commands vs. Rules — Decision Framework

## When to Use Rules (.claude/rules/*.md)

Use rules when the instruction is:

- **Declarative** — "when working on X files, follow Y conventions"
- **Automatic** — should apply without the developer invoking anything
- **About patterns and constraints**, not step-by-step procedures
- **Path-scopable** — different rules for different parts of the codebase

**Examples:**

- API endpoint conventions that apply whenever editing API files
- Testing requirements that activate when editing test files
- Security constraints that apply globally
- Framework-specific patterns (React, Go, etc.)

## When to Use Skills (.claude/skills/)

Use skills when the instruction is:

- **Procedural** — a multi-step workflow with a clear sequence
- **Rich** — includes supporting files (templates, examples, scripts)
- **Auto-detectable** — Claude should recognize when it's relevant based on the description
- **Cross-platform** — needs to work across Claude Code, claude.ai, and Claude Desktop

**Examples:**

- Security review checklist (multi-step audit)
- PR description generation (read git state → generate document)
- Endpoint scaffolding with templates
- Incident documentation with structured format

## When to Use Slash Commands (.claude/commands/)

Use commands when the instruction is:

- **Explicitly invoked** — developer types the command intentionally
- **Single-file** — a prompt without supporting materials
- **Argument-driven** — accepts `$ARGUMENTS` (e.g., `/fix-issue 1234`)
- **Discovery-friendly** — benefits from terminal autocomplete

**Examples:**

- `/deploy-staging` — explicit deployment trigger
- `/fix-issue 1234` — issue-specific workflow with argument
- `/run-tests` — simple repeatable command
- `/commit` — standardized commit message generation

## Decision Flowchart

```
Is the instruction about conventions/patterns that should apply automatically?
  YES → Use a Rule (.claude/rules/)
    └── Does it apply only to specific file types?
          YES → Add paths: frontmatter
          NO  → Leave without frontmatter (global rule)

  NO → Is it a multi-step procedure or workflow?
    YES → Does it include templates, examples, or scripts?
      YES → Use a Skill (.claude/skills/skill-name/)
      NO  → Could Claude auto-detect when to use it?
        YES → Use a Skill (for auto-matching)
        NO  → Use a Slash Command (.claude/commands/)

    NO → Is it a simple repeatable action with arguments?
      YES → Use a Slash Command
      NO  → It probably belongs in CLAUDE.md or agent_docs/
```

## Enterprise Default Guidance

For the 500-developer rollout: **default to skills for anything reusable, fall back to slash commands for simple invocations, use rules for always-on conventions.**

| Mechanism | Scope | Loading | Best For |
|---|---|---|---|
| Rules | Per-repo | Automatic (path-scoped or global) | Conventions, constraints |
| Skills | Global, per-repo, or personal | On invocation or auto-match | Workflows, procedures |
| Slash Commands | Global or per-repo | Explicit invocation only | Simple repeatable actions |
| CLAUDE.md | Per-repo | Always loaded | Universal project context |
| agent_docs/ | Per-repo | On-demand (Claude reads when needed) | Deep reference material |
