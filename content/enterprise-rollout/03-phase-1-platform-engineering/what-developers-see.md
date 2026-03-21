---
title: "What Developers See"
weight: 8
---

# What Developers See

This is the page a team lead hands to developers on day one of rollout.

## When a Deny Rule Fires

Claude Code shows a notification explaining which policy blocked the action and why. Deny rules are not silent failures -- the developer always sees what was blocked. For the full incident response workflow (rephrase, manual workaround, or policy exception), see [Security Controls]({{< relref "../05-phase-3-observability-and-governance/security-controls.md#if-a-deny-rule-is-triggered" >}}).

## Checking Effective Permissions

Run `/permissions` in any Claude Code session to see all active permission rules and their source (managed, project, user). Run `/settings` to see the full effective configuration with managed overrides marked.

These commands are the fastest way to answer "why can't Claude do X?"

## Managed Settings Are Invisible

Developers don't interact with `managed-settings.json` directly. They won't see it, won't know where it lives, and won't need to. Enterprise controls are transparent until a boundary is hit -- at which point the deny rule notification explains the constraint.

This is by design. The platform team sets policy; developers work within it.

## The Mental Model Shift

Claude Code proposes shell commands and file changes, then waits for developer approval before executing. This review-then-approve workflow differs from inline autocomplete suggestions -- developers evaluate complete proposed actions rather than accepting line-by-line completions.

Budget training time for this shift during cohort onboarding. Developers who are already CLI-native and comfortable with code review adapt fastest. Developers coming from IDE-centric autocomplete workflows need more ramp time.

## What Stays the Same

Git workflow, PR process, CI/CD pipeline, code review -- none of this changes. Claude Code operates within the existing development process. It creates branches, writes code, runs tests, and proposes commits. The human developer reviews, approves, and merges through the same process they use today.

_Last validated against Claude Code docs: 2026-03-20_
