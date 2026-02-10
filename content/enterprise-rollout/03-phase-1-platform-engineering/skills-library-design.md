---
title: "Skills Library Design — Three-Tier Architecture"
weight: 5
---

# Skills Library Design — Three-Tier Architecture

## Overview

Skills are structured workflows Claude can invoke as complete procedures. Each skill needs a SKILL.md file with YAML frontmatter (name, description) and markdown instructions. The name becomes the /slash-command, and the description helps Claude decide when to load it automatically.

---

## Tier 1: Organization Skills (Global, All Developers)

Distributed via plugin marketplace (internal) or symlink from a shared repo. Installed to `~/.claude/skills/` on each developer machine.

**Start with 5–8 org-wide skills at launch. Don't build 30.**

### /security-review — Highest-Value Enterprise Skill

```markdown
---
name: security-review
description: >
  Performs a structured security review of staged changes.
  Use when preparing code for PR review, after completing a feature,
  or when asked to check for security issues.
allowed-tools: Bash, Read, Grep, Glob
---

# Security Review Procedure

Review the current staged changes (or working tree if nothing staged)
against this checklist. For each category, state PASS, FAIL, or N/A
with a one-line explanation.

## Input Validation
- Are all external inputs validated before use?
- Are SQL queries parameterized (no string concatenation)?
- Are file paths validated against path traversal?

## Authentication & Authorization
- Do new endpoints require authentication?
- Are authorization checks present for resource access?
- Are there any privilege escalation vectors?

## Secrets & Configuration
- Are there any hardcoded secrets, API keys, or passwords?
- Are credentials read from environment/vault, not config files?
- Are there any secrets in log statements?

## Dependencies
- Do new dependencies have known CVEs? Run: `npm audit` or `go vuln check`
- Are dependencies pinned to specific versions?

## Output
Produce a summary table and flag any FAIL items for the developer
to address before opening the PR. Do NOT auto-fix — explain the issue
and let the developer decide.
```

### /pr-description — Standardizes PR Quality

```markdown
---
name: pr-description
description: >
  Generates a PR description from the current branch's changes
  following the org template. Use when preparing to open a pull request.
allowed-tools: Bash, Read, Grep
---

# Generate PR Description

1. Run `git log main..HEAD --oneline` to understand the commit history
2. Run `git diff main --stat` to see files changed
3. Read the PR template at `.github/PULL_REQUEST_TEMPLATE.md` if it exists

Generate a PR description with these sections:

## Summary
Two to three sentences explaining WHAT changed and WHY.

## Changes
Bullet list of specific changes, grouped by area.

## Testing
How were these changes tested? List specific test commands run
and their outcomes.

## Risk Assessment
- What could break?
- What downstream services are affected?
- Is a database migration involved?
- Does this require a config change in any environment?

## Rollback Plan
If this change causes issues in production, what's the rollback procedure?
```

### Additional Org-Wide Skills

- **/test-scaffold** — Generates test files following org testing conventions for the current file
- **/onboard-repo** — Reads agent_docs/ and gives a new developer a codebase walkthrough
- **/incident-doc** — Structured incident documentation template
- **/changelog-entry** — Generates changelog entries from recent commits

### Design Properties of Good Org Skills

- **Opinionated about process, generic about technology.** The /security-review works whether the project is Go, TypeScript, or Java because it focuses on categories of issues, not language-specific checks.
- **Procedural, not declarative.** Skills tell Claude what to do step by step. Conventions and constraints belong in rules.
- **Self-contained.** Each skill should work without requiring the developer to provide additional context.

---

## Tier 2: Team/Project Skills (Per-Repo, Version-Controlled)

Checked into each repo at `.claude/skills/`. Team-specific workflows and patterns.

### Examples

- **/deploy-staging** — Team's specific deployment workflow including environment-specific configs
- **/new-endpoint** — Scaffolds an API endpoint following this project's patterns, using actual shared middleware and types
- **/db-migration** — Generates a migration file following the team's ORM conventions with correct naming scheme
- **/new-component** — For frontend teams: scaffolds a React component with team's state management, styling, and test patterns

### Skills with Supporting Files

```
.claude/skills/
└── new-endpoint/
    ├── SKILL.md              # Instructions
    ├── templates/
    │   ├── handler.ts.md     # Handler template
    │   ├── handler.test.ts.md # Test template
    │   └── openapi.yaml.md   # OpenAPI fragment
    └── examples/
        └── sample-crud.md    # Example of a well-structured endpoint
```

The SKILL.md references these files: "Use the template in `templates/handler.ts.md` as your starting structure. See `examples/sample-crud.md` for a complete working example."

This turns tribal knowledge into executable procedures. The senior engineer who always scaffolds endpoints the right way — their knowledge is now codified in a skill that any developer on the team can invoke.

---

## Tier 3: Personal Skills (Individual Developer)

Stored in `~/.claude/skills/`. Not managed by the org, not shared in repos. Personal workflows: code review checklists, note-taking conventions, learning workflows. The org shouldn't try to control these.

---

## Skill Description Budget

Skill descriptions are loaded into context so Claude knows what's available. The budget scales dynamically at 2% of the context window, with a fallback of 16,000 characters.

If each skill description is ~100 characters, you can have ~160 skills before hitting the budget. In practice, keep descriptions to one sentence and you'll be fine with 30–50 skills across all tiers.

Run `/context` to check for warnings about excluded skills.

---

## Skill Naming Conflicts

When skills share the same name across levels, higher-priority locations win: **enterprise > personal > project**. Plugin skills use a `plugin-name:skill-name` namespace, so they cannot conflict with other levels.

If a skill and a slash command share the same name, the **skill takes precedence**.
