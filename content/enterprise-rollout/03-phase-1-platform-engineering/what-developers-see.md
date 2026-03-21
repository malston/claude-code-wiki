---
title: "What Developers See"
weight: 8
---

# What Developers See

This is the page a team lead hands to developers on day one of rollout.

## When a Deny Rule Fires

Claude Code shows a notification explaining which policy blocked the action. The developer can:

- Rephrase the request to avoid the blocked operation
- Perform the blocked operation manually outside Claude Code
- Request a policy exception through the platform team

Deny rules are not silent failures. The developer sees what was blocked and why.

## Checking Effective Permissions

Run `/permissions` in any Claude Code session to see all active permission rules and their source (managed, project, user). Run `/settings` to see the full effective configuration with managed overrides marked.

These commands are the fastest way to answer "why can't Claude do X?"

## Managed Settings Are Invisible

Developers don't interact with `managed-settings.json` directly. They won't see it, won't know where it lives, and won't need to. Enterprise controls are transparent until a boundary is hit -- at which point the deny rule notification explains the constraint.

This is by design. The platform team sets policy; developers work within it.

## The Mental Model Shift

Claude Code is an agent that proposes actions and asks permission, not an autocomplete engine that suggests the next line. Developers review proposed shell commands and file changes before approving them. This review-then-approve workflow is different from Copilot-style inline suggestions.

Budget training time for this shift during cohort onboarding. Developers who are already CLI-native and comfortable with code review adapt fastest. Developers coming from IDE-centric autocomplete workflows need more ramp time.

## What Stays the Same

Git workflow, PR process, CI/CD pipeline, code review -- none of this changes. Claude Code operates within the existing development process. It creates branches, writes code, runs tests, and proposes commits. The human developer reviews, approves, and merges through the same process they use today.

_Last validated against Claude Code docs: 2026-03-20_
