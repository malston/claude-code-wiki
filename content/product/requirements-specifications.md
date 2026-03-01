---
title: "Requirements & Specifications: From Problem to Prompt"
linkTitle: "Requirements & Specifications"
weight: 3
---

# Requirements & Specifications: From Problem to Prompt

## Executive Summary

You've done the research. You know what users struggle with. Now you need to turn that understanding into something precise enough that you -- or Claude Code -- can build it. This article covers requirement formats, feature decomposition, edge case discovery, and the handoff to spec-driven development. The goal: close the gap between "I understand the problem" and "I can write a build prompt."

| Format                  | Best For                             | Structure                                                   | Risk If Overused                                       |
| ----------------------- | ------------------------------------ | ----------------------------------------------------------- | ------------------------------------------------------ |
| **User stories**        | Communicating intent to stakeholders | As a [role], I want [action] so that [outcome]              | Too vague for implementation; "so that" clause ignored |
| **Job stories**         | Surfacing motivation and context     | When [situation], I want to [motivation] so I can [outcome] | Harder to estimate; situations can be ambiguous        |
| **Acceptance criteria** | Verifying implementation correctness | Given [context], when [action], then [result]               | Brittle if over-specified; miss the "why"              |

Each format captures different information. Use them in combination: job stories to understand context, user stories to scope features, acceptance criteria to verify builds.

## Table of Contents

- [The Requirements Problem](#the-requirements-problem)
- [From Research to Requirements](#from-research-to-requirements)
  - [Choosing a Format](#choosing-a-format)
  - [Decomposing Vague Requests](#decomposing-vague-requests)
  - [Requirements That Double as AI Context](#requirements-that-double-as-ai-context)
- [Feature Decomposition](#feature-decomposition)
  - [Vertical Slicing](#vertical-slicing)
  - [The Smallest Thing That Teaches You Something](#the-smallest-thing-that-teaches-you-something)
  - [Using Claude Code to Draft Decomposition Options](#using-claude-code-to-draft-decomposition-options)
- [Edge Cases and Constraints](#edge-cases-and-constraints)
  - [Generating Edge Case Lists](#generating-edge-case-lists)
  - [Non-Functional Requirements Engineers Forget](#non-functional-requirements-engineers-forget)
- [Worked Example: Vague Request to Build Prompt](#worked-example-vague-request-to-build-prompt)
- [Handoff to Spec-Driven Development](#handoff-to-spec-driven-development)

## The Requirements Problem

Features fail because they solve the wrong problem. Bad code causes bugs. Bad requirements cause features that work correctly and help nobody.

A team receives the request: "We need better error messages." They spend two weeks rewriting every error string. The messages are now grammatically correct, consistently formatted, and include error codes. Support ticket volume doesn't change. The actual problem was that errors appeared in a log file users never checked -- the messages were fine, but nobody saw them.

Nobody decomposed "better error messages" into a testable statement like "users who encounter error X can resolve it within 5 minutes without contacting support." Requirements work is asking what must be true for the problem to be solved, then writing those truths down precisely enough to build against.

## From Research to Requirements

The [user research]({{< relref "user-research" >}}) article covers how to figure out what the problem is. This section covers how to express what you've learned in formats that are precise enough to build from.

### Choosing a Format

**User stories** communicate scope to non-engineers. "As a deploy engineer, I want to roll back a deployment so that I can recover from a bad release." The format forces you to name a role, an action, and a purpose. Its weakness: the "so that" clause is frequently ignored, and the story alone doesn't tell you what "done" looks like.

**Job stories** surface the triggering situation. "When a deployment fails health checks within 5 minutes of going live, I want to revert to the previous version so I can restore service before customers notice." This captures urgency and timing -- it prevents you from building a rollback feature that only works from a dashboard when the real scenario happens at 3am from a phone.

**Acceptance criteria** define verifiable outcomes. "Given a deployment that failed health checks, when the user clicks Rollback, then the previous version is deployed within 60 seconds and the user sees a confirmation with the restored version number." These translate directly into test cases. Their weakness: they can over-specify implementation details and become brittle if the design changes.

Combine them: a job story for situation and motivation, a user story to scope the feature, acceptance criteria to define "done."

### Decomposing Vague Requests

Most feature requests arrive vague. "Make it faster." "Improve the onboarding." These are symptoms, not specifications. Decompose them by asking: faster than what (baseline), faster for whom (which users/paths), and how fast is enough (target). "Under 5 minutes" is a requirement. "Faster" is a direction without a destination.

Claude Code can help. Feed it the vague request along with your research data:

```text
Stakeholder request: "improve the onboarding experience." From user
research (6 new hire interviews):

- 4 of 6 couldn't complete first deployment without asking a teammate
- Setup guide references 3 undocumented env vars
- Average time from laptop to first deploy: 4 days
- 2 users said CLI error messages didn't tell them what to fix

Decompose "improve onboarding" into 5-8 testable requirements, each
with a measurable outcome and verification method.
```

This produces specific statements because it gives Claude Code research data to work from. Without that context, you'd get generic output like "make the documentation clearer" -- the original vague request rephrased.

### Requirements That Double as AI Context

A requirement good enough for a human is often too vague for Claude Code. Humans fill gaps with institutional knowledge; Claude Code fills gaps with assumptions. Good requirements and good prompts need the same things: specific inputs and outputs, constraints, and verification criteria.

"Add rate limiting to the login endpoint" becomes a better build prompt when it specifies: which endpoint (POST /api/auth/login), what limit (5 attempts per email per 15 minutes), what response (429 with Retry-After header), and what happens at the boundary (6th attempt blocked, counter resets after 15 minutes). Five extra minutes of specificity saves 30 minutes of implementation rework.

## Feature Decomposition

### Vertical Slicing

A vertical slice delivers a complete user-facing behavior, touching every layer needed. "User can roll back a deployment" is a vertical slice -- it includes the UI button, the API endpoint, the rollback logic, and the notification. "Build all the database models" is a horizontal layer -- useful as a building block but not independently verifiable from a user's perspective.

Vertical slices reduce integration risk. When you build all models, then all endpoints, then all UI, integration bugs surface late. When each slice works end-to-end, you catch problems immediately. The trade-off is occasional refactoring when later slices reveal shared patterns -- but working code that evolves beats planned abstractions that might not match reality.

### The Smallest Thing That Teaches You Something

For each feature, ask: what's the thinnest end-to-end slice that validates our riskiest assumption?

If the feature is "deployment rollback," the smallest teaching slice might be a CLI command that reverts a deployment by redeploying the previous container image. No UI, no confirmation dialog, no audit log. This slice teaches you whether the core mechanism works and how long it takes. If rollback takes 8 minutes instead of the expected 60 seconds, you've learned that before investing in UI polish and audit logging.

### Using Claude Code to Draft Decomposition Options

When you have a high-level goal, Claude Code can generate multiple decomposition strategies for you to evaluate:

```text
Goal: Users can roll back a failed deployment from the dashboard.

Current state:
- PostgreSQL deployments table (version, image_tag, status, deployed_at)
- Deploy CLI: `deploy --image-tag <tag>`
- Dashboard shows history but has no rollback action

Propose 3 ways to decompose this into vertical slices, thinnest to
most complete. For each, list the slices and what we learn from each.
```

This gives you options rather than committing to a single decomposition upfront.

## Edge Cases and Constraints

### Generating Edge Case Lists

Before writing code, ask what would make the feature fail. Claude Code enumerates conditions systematically:

```text
We're building a deployment rollback feature with these requirements:
- User clicks "Rollback" on the dashboard for a specific deployment
- System redeploys the previous version (the image_tag from the
  deployment before the selected one)
- Rollback completes within 60 seconds
- User sees confirmation with the restored version number

What edge cases could cause this to fail? Consider: concurrent
operations, data integrity, external dependencies, user error,
and timing conditions.
```

A typical response covers cases you'd catch in code review -- what if there's no previous deployment? What if a rollback is already in progress? -- alongside cases you might miss until production: what if the previous container image has been garbage-collected from the registry?

For each edge case, decide: handle it now, defer it as a documented limitation, or accept the risk.

### Non-Functional Requirements Engineers Forget

Functional requirements describe what the system does. Non-functional requirements describe how it behaves under pressure. Engineers tend to discover these in production.

Common ones to specify upfront:

- **Latency budgets** -- "Rollback completes within 60 seconds." Without this, a correct rollback that takes 10 minutes still fails the user's need.
- **Error handling** -- "Return a meaningful error for 100% of failure cases." Meaningful = the user can take action from the message.
- **Concurrency** -- "One rollback per service at a time. Second request returns 409 Conflict."
- **Accessibility** -- "Rollback button is keyboard-accessible with an ARIA label."
- **Auditability** -- "Every rollback produces an audit log entry: who, from-version, to-version, timestamp, outcome."

Add these during requirements writing, not during code review.

## Worked Example: Vague Request to Build Prompt

Here's the full path from a vague request to a Claude Code build prompt.

**The vague request:** "Our deploys are too risky."

**After research** (support tickets, 3 user interviews):

- Teams deploy and then watch dashboards for 15-20 minutes, afraid to move on
- When something breaks, the recovery process is manual: find the last good image tag, run the deploy CLI, update the load balancer
- Two incidents in the last month where recovery took over 30 minutes because the engineer couldn't find the previous image tag

**Decomposed requirements:**

1. The dashboard shows, for each deployment, the image tag of the version deployed immediately before it
2. A "Rollback" button appears on deployments whose status is "failed" or "degraded"
3. Clicking Rollback triggers a redeployment of the previous image tag via the existing deploy CLI
4. The rollback operation completes within 60 seconds or surfaces an error explaining what went wrong
5. Only one rollback per service can run at a time (409 Conflict for concurrent attempts)
6. An audit log entry records who rolled back, from what version, to what version, and the outcome

**Thinnest vertical slice:** Requirements 1-4 (show previous version, add button, trigger rollback, surface outcome). Requirements 5-6 are second-slice work.

**Claude Code build prompt** (using [spec-driven development]({{< relref "/guides/spec-driven-development" >}}) for execution):

```text
Feature: Deployment Rollback (Slice 1)

Context:
- Deployments table: id, service_name, image_tag, status, deployed_at
- Deploy CLI: `deploy --service <name> --image-tag <tag>`
- Dashboard: React app, detail page at ./frontend/src/pages/DeploymentDetail.tsx

Requirements:
1. GET /api/deployments/:id returns previous_image_tag (most recent
   deployment for same service with earlier deployed_at)
2. Dashboard shows previous image tag on deployment detail page
3. "Rollback" button visible when status is "failed" or "degraded"
4. POST /api/deployments/:id/rollback triggers deploy CLI with
   previous tag, returns new deployment ID
5. Success shows "Rolled back to <tag>"; failure shows CLI error

Acceptance criteria:
- Failed deployment + click Rollback = previous version deployed
- No previous version = no Rollback button
- Successful deployment = no Rollback button

Write a plan for implementing this. Use TDD.
```

## Handoff to Spec-Driven Development

Once your requirements are specific and testable, the [spec-driven development]({{< relref "/guides/spec-driven-development" >}}) guide takes over. It covers writing specs as Claude Code prompts, decomposing into atomic tasks, executing in fresh context windows, and verifying against goals.

The handoff checklist:

- **Each requirement has a verb and a measurable outcome.** "User can roll back" is better than "rollback support."
- **Edge cases are documented, even if deferred.** You don't have to handle every edge case in slice 1, but you should know they exist.
- **Non-functional constraints are explicit.** Latency, concurrency, error handling, and accessibility requirements are written down, not assumed.
- **The thinnest vertical slice is identified.** You know which requirements form the minimum viable behavior and which are second-slice work.

If you can check all four, your requirements are ready to become specs. Gaps discovered later cost rework; gaps caught here cost a few minutes of writing.
