---
title: "Common Failure Modes"
weight: 7
---

# Common Failure Modes

Patterns to watch for and coach against during the rollout.

## 1. The Encyclopedia CLAUDE.md

**Symptom:** A team dumps their entire wiki into CLAUDE.md. 300+ lines of coding standards, architecture descriptions, and process documentation.

**Effect:** Claude's responses get slower, less focused, and the context window fills up before any real work happens. Instructions toward the end of a long CLAUDE.md receive less attention than those at the beginning.

**Fix:** Enforce a line count limit (80 lines for project CLAUDE.md) and push everything else to `agent_docs/`. The CLAUDE.md points to deeper docs; Claude reads them on-demand.

## 2. The Style Guide in Prose

**Symptom:** Teams write paragraphs about code style in CLAUDE.md instead of using linters. "Please use 2-space indentation and prefer const over let."

**Effect:** Wastes context tokens on things a linter can enforce deterministically. Claude may inconsistently follow style guidance but a formatter will always enforce it.

**Fix:** Use linters and code formatters (ESLint, Prettier, gofmt, Black). Use Hooks to run them automatically on file changes. Reserve CLAUDE.md for things that *can't* be expressed as linter rules: architectural patterns, domain conventions, workflow expectations.

## 3. The Copy-Paste Skill

**Symptom:** A skill that's a copy-pasted procedure from Confluence, written for humans.

**Effect:** Claude struggles because the instructions assume human context, use ambiguous language, and don't specify which tools to use or what output format to produce.

**Fix:** Skills need to be written *for Claude* — explicit about which tools to use, which files to read, what output format to produce, and what decisions to make vs. defer to the developer. A human procedure doc and a Claude skill have very different structures.

## 4. Over-Scoping Path Rules

**Symptom:** Teams create a separate rule file for every file extension — `.ts`, `.tsx`, `.css`, `.html`, `.json`, `.yaml` all get their own rules.

**Effect:** 20 rule files means 20 descriptions Claude must evaluate for relevance. The context overhead of rule discovery outweighs the benefit of fine-grained scoping.

**Fix:** Consolidate. `frontend/` rules cover all frontend files. `backend/` covers all backend files. You don't need separate rules for `.ts` and `.tsx` if they follow the same patterns.

## 5. No Iteration Loop

**Symptom:** The team writes CLAUDE.md once during onboarding and never updates it.

**Effect:** Instructions drift from reality. New patterns aren't captured. Claude follows outdated conventions.

**Fix:** Treat CLAUDE.md and rules like code — they live in the repo, go through PR review, and get updated when patterns change. Add a quarterly review cadence: "Is our CLAUDE.md still accurate? Are developers ignoring any instructions? Should rules be added or removed?"

## 6. Everything is a Skill

**Symptom:** Teams build 40 skills before anyone uses them. Half are untested, many overlap, and developers can't remember which one to invoke.

**Effect:** Skill description budget gets consumed. Developers default to not using any skills because there are too many to learn.

**Fix:** Start with 5–8 org-wide skills. Let teams build their own on top based on real workflows discovered during Cohort 1. Every skill should be created because developers asked for it, not because the platform team thought it might be useful.

## 7. Treating Claude Code as a Linter Replacement

**Symptom:** Security and compliance teams want to use Claude Code's /security-review skill as a replacement for SAST/DAST tools in CI/CD.

**Effect:** LLM-based reviews are non-deterministic. The same code might pass one review and fail another. Audit teams can't rely on non-reproducible results.

**Fix:** LLM security review is a *complement* to deterministic tools, not a replacement. Integrate Semgrep, Snyk, or equivalent in CI/CD for the deterministic baseline. Use /security-review as an additional layer during development, not as the gate.

## 8. Ignoring the Context Budget

**Symptom:** Large repos with extensive CLAUDE.md, many rules, many skills, and large agent_docs files. Claude starts losing track of instructions mid-session.

**Effect:** Claude's behavior becomes inconsistent. It follows some rules and ignores others, seemingly at random. Actually, earlier context is being pushed out by newer context.

**Fix:** Run `/context` regularly to monitor token usage. Use the Context Budget Worksheet to plan allocations. If the fixed context exceeds 30K tokens, restructure.
