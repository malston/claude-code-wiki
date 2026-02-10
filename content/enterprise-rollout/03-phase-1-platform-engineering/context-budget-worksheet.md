---
title: "Context Budget Worksheet"
weight: 6
---

# Context Budget Worksheet

## Purpose

Before building any CLAUDE.md or skills, do this exercise for each major codebase. It forces discipline about what goes where and prevents context overload.

## The Budget

Claude Code's context window is approximately 200K tokens. Everything competes for this space: system prompt, CLAUDE.md files, rules, skill descriptions, code files Claude reads, conversation history, and Claude's own reasoning.

## Fixed Costs (Always Loaded)

These load into every session regardless of what the developer is doing.

| Component | Est. Tokens | Notes |
| --- | --- | --- |
| Claude Code system prompt | ~15,000 | Built-in, cannot be reduced |
| Managed CLAUDE.md (org-wide) | ~500 | **Keep to 30–50 lines** |
| Project CLAUDE.md | ~1,000 | **Keep to 60–80 lines** |
| Unconditional rules (no `paths:`) | ~2,000 | 3–4 rule files |
| Skill descriptions (for discovery) | ~2,000 | 10–15 skills across all tiers |
| **Subtotal** | **~20,500** | |

## Variable Costs (Loaded On-Demand)

These load when triggered by developer activity or explicit invocation.

| Component | Est. Tokens | Trigger |
| --- | --- | --- |
| Path-scoped rules | 500–1,000 each | When working on matching files |
| Skill content (when invoked) | 1,000–3,000 each | /slash-command or auto-match |
| agent_docs/ files | 2,000–5,000 each | When Claude reads for context |
| **Typical session addition** | **5,000–15,000** | |

## Available for Actual Work

| Budget | Tokens |
| --- | --- |
| Total context window | ~200,000 |
| Fixed costs | ~20,500 |
| Typical variable costs | ~10,000 |
| **Available for code, conversation, reasoning** | **~170,000** |

## Warning Thresholds

- **If fixed costs exceed 30K tokens:** You've overloaded Layer 0 and Layer 1. Push content down to agent_docs/ (Layer 2) or skills (Layer 3).
- **If unconditional rules exceed 3K tokens:** Consolidate rules or add path scoping.
- **If skill descriptions exceed 16K characters total:** You have too many skills. Reduce descriptions to one sentence each, or remove rarely-used skills.

## Skill Description Budget

The skill description budget scales dynamically at 2% of the context window, with a fallback of ~16,000 characters. Practical limits:

| Description Length | Max Skills |
| --- | --- |
| ~50 characters each | ~320 skills |
| ~100 characters each | ~160 skills |
| ~200 characters each | ~80 skills |

Keep descriptions to one sentence. Run `/context` to check for warnings about excluded skills.

## Audit Process

Run this monthly for each major codebase:

1. Start a Claude Code session in the repo
2. Run `/context` to see what's loaded and total token usage
3. Compare against budget targets
4. Identify any instructions Claude consistently ignores (sign of context dilution)
5. Move ignored instructions to agent_docs/ or remove them
