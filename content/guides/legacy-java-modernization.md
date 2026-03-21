---
title: "Real-World Example: Legacy Java Modernization"
linkTitle: "Legacy Java Modernization"
weight: 12
---

# Real-World Example: Legacy Java Modernization

## Overview

This example shows Agent Teams applied to a common enterprise problem: a legacy Java
monolith with decade-old dependencies that no one wants to touch. The goal is to give
a resistant team the confidence and tooling to act incrementally, rather than forcing
a big-bang rewrite.

The scenario comes from a real consulting engagement: a 1M-line Spring/Hibernate
codebase, risk-averse stakeholders, and a team that hasn't had the bandwidth or mandate
to address the underlying debt.

The insight is that Agent Teams are useful here not because they write code faster,
but because they produce **structured findings** that change the conversation.

## Why Agent Teams Fit This Problem

A single Claude Code session on a 1M-line codebase will hit context limits before
it understands the full picture. More importantly, sequential investigation suffers
from anchoring: once you find one problem, you stop looking for others.

Agent Teams let you parallelize _analysis_ across multiple teammates:

- Multiple teammates explore different dimensions simultaneously
- Teammates challenge each other's findings through direct messaging
- The fan-in phase synthesizes a complete picture rather than a partial one

Critically, **all three phases below use read-only teams first**. You do not touch
production code until the client team trusts the findings.

## Phase 1: Reconnaissance Team

**Goal:** Understand the codebase before proposing anything.

**Pattern:** Fan-out / fan-in on analysis tasks. No file writes.

```text
Analyze this legacy Java monolith. Do NOT modify any files.
Do NOT use Write, Edit, or Bash tools that create or change files.

Spawn 4 read-only teammates:

- dependency-auditor: Catalog all Spring and Hibernate versions, transitive
  dependencies, and known CVEs. Map each dependency to its current equivalent
  and flag any with no migration path.

- dead-code-analyst: Identify unreachable code, unused Spring beans, and
  deprecated API usage. Produce a heat map by package showing where the
  heaviest usage of deprecated APIs is concentrated.

- coupling-mapper: Build a dependency graph of major modules. Flag circular
  dependencies, god classes (>500 lines, >10 injected dependencies), and
  packages with no clear bounded context.

- test-coverage-scout: Inventory existing tests. Classify by type
  (unit, integration, none). Flag untested critical paths -- especially
  anything touching payment, auth, or data persistence.

When all four finish, synthesize findings into ANALYSIS.md. Do not recommend
any changes yet. Just describe what exists.
```

**Why this works:** The output is a document, not code. You can show this to
a skeptical client team without triggering defensiveness -- it's observation, not
judgment. "Here's what the agents found in 2 hours" is a different conversation
than "here's our 6-month modernization plan."

### Key Details

- Enforce read-only by instructing teammates explicitly and using the
  `TaskCompleted` hook to reject any task that modified files
- Give each teammate a distinct package scope if the codebase is large enough
  to segment -- this prevents teammates from duplicating work
- The `coupling-mapper` and `dead-code-analyst` findings often contradict each
  other; let them message back and forth to resolve discrepancies before the
  fan-in

## Phase 2: Migration Strategy Team

**Goal:** Surface options with honest tradeoffs, not a single recommended plan.

**Pattern:** Competing hypotheses -- teammates argue positions, then challenge
each other through direct messaging.

```text
Based on ANALYSIS.md, spawn 3 teammates to propose migration strategies.
Each works independently, then challenges the others' proposals.

- strangler-fig-advocate: Design a strangler fig approach. Identify the
  seams where new Spring Boot services can absorb functionality over time
  without requiring changes to the core monolith. Prioritize seams with
  the most CVEs or the most dead code.

- in-place-upgrade-advocate: Design an incremental in-place upgrade path.
  Spring 2.x → 5.x → 6.x, Hibernate 3.x → 6.x. Identify breaking changes
  at each hop. Flag which deprecated APIs from Phase 1 would be removed at
  each step.

- risk-assessor: Review both proposals. Identify what each plan gets wrong.
  Estimate effort, risk, and what happens to the project if the team
  abandons it halfway. Be specific about the failure modes.

Have teammates message each other with challenges. The strangler-fig and
in-place advocates must respond to each criticism before the risk-assessor
produces a final summary.

Synthesize into MIGRATION_OPTIONS.md with a comparison table: approach,
effort estimate, risk level, partial-completion outcome, and prerequisites.
```

**Why this works:** The output explicitly contains a risk column and a
"what happens if we abandon it" column. This is the document that gets shown
to the managers who are 2 years from retirement. You are not advocating for
anything -- you are surfacing tradeoffs that were invisible before.

The competing-advocates structure also produces a more honest document than
a single planner would. The strangler-fig advocate will downplay migration
complexity; the risk-assessor will surface it.

### Key Details

- Use `Shift+Tab` delegate mode (or instruct the lead explicitly in the prompt
  when running headless) so the lead doesn't start implementing migration code
- Set task dependencies so the `risk-assessor` cannot start until both
  advocates have submitted their proposals
- If the client team wants to add their own perspective, they can message
  the `risk-assessor` directly with constraints or history the agents
  don't have access to

## Phase 3: Bug Fix Team

**Goal:** Tackle backlog issues using the existing codebase idioms.

**Pattern:** Research + implementation with a reviewer gate.

```text
Given ANALYSIS.md and this bug report: [BUG_DESCRIPTION]

Spawn 3 teammates:

- context-loader: Read all files relevant to this bug. Identify the full
  call chain, the affected Hibernate mappings, and any related tests.
  Do NOT modify files. Write your findings to /tmp/bug-{id}-context.md.

- implementer: Wait for context-loader to finish. Implement the fix using
  patterns consistent with the existing codebase. Use Spring 2.x idioms,
  not modern Spring. Match the surrounding code style exactly -- do not
  modernize while fixing.

- reviewer: Wait for implementer to finish. Review the fix for unintended
  regressions, consistency with the patterns identified in ANALYSIS.md,
  and whether it introduces any new technical debt. Block task completion
  if tests fail. If the implementer used modern idioms, flag this.
```

**Why this works:** The `implementer` is explicitly told to use old idioms.
This is what builds trust with the team that owns the codebase -- they are not
discovering a sneaked-in refactor when they review the PR. The `reviewer`
enforcing style consistency enforces this automatically.

The `context-loader` phase produces a document that can be attached to the PR,
giving the client team visibility into what the agents actually read and why.

### Scaling Across the Backlog

For multiple bugs in parallel, use the shared task list to queue them:

```text
Create tasks for bugs 101, 102, 103, 104, 105.
Spawn 3 bug-fix teams (context-loader, implementer, reviewer).
Each team self-claims the next available bug when they finish.
Do not let any team claim a bug that another team has in progress.
```

File locking in the task system prevents two teams from claiming the same bug.
Assign each team a dedicated branch prefix (`team-a/`, `team-b/`, etc.) to
prevent branch conflicts.

## Hooks for Quality Gates

Two `TaskCompleted` hook scripts enforce standards across all three phases
without manual checking. Bind both to the `TaskCompleted` event in
`.claude/settings.json`.

### Block Task Completion if Files Were Modified (Phase 1)

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name')

# Only enforce on analysis teammates
if [[ "$TEAMMATE" == *"-analyst"* ]] || [[ "$TEAMMATE" == *"-auditor"* ]] || \
   [[ "$TEAMMATE" == *"-mapper"* ]] || [[ "$TEAMMATE" == *"-scout"* ]]; then
  # Check unstaged, staged, and committed changes against the working tree baseline
  CHANGED=$(git diff --name-only; git diff --cached --name-only)
  if [ -n "$CHANGED" ]; then
    echo "Analysis teammate '$TEAMMATE' modified files. Revert changes before completing task." >&2
    echo "Modified: $CHANGED" >&2
    exit 2
  fi
fi

exit 0
```

### Block Task Completion if Tests Fail (Phase 3)

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TASK=$(echo "$INPUT" | jq -r '.task_subject')
TEAMMATE=$(echo "$INPUT" | jq -r '.teammate_name')

if [[ "$TEAMMATE" == "implementer" ]]; then
  TEST_OUTPUT=$(mvn test -q 2>&1)
  if [ $? -ne 0 ]; then
    echo "Cannot complete '$TASK': tests are failing." >&2
    echo "$TEST_OUTPUT" >&2
    echo "Fix failing tests before marking this task complete." >&2
    exit 2
  fi
fi

exit 0
```

## Common Failure Modes

**The lead starts modernizing while implementing.** Even with delegate mode on,
the lead may suggest modern patterns in its coordination messages. Include this
in your lead prompt: _"Do not suggest modernization. Match existing idioms exactly.
Flag deviations from existing patterns as errors, not improvements."_

**Teammates produce inconsistent findings.** The `coupling-mapper` may flag a
class as a god class while the `dead-code-analyst` flags the same class as
mostly unused. This is not a problem -- have them message each other to reconcile.
The disagreement is itself a useful finding.

**The task list gets out of sync.** Teammates sometimes fail to mark tasks
complete (a known limitation). Monitor the task list with `Ctrl+T` and manually
advance stuck tasks if needed.

**Spawning too many teammates.** On a 1M-line codebase it is tempting to spawn
a teammate per package. Resist this. Four to five focused teammates with clear
file ownership will outperform ten teammates with overlapping scope.

## What This Produces

After all three phases, you have:

- `ANALYSIS.md` -- an inventory of what exists, with no recommendations
- `MIGRATION_OPTIONS.md` -- a comparison of approaches with explicit tradeoffs
- A PR per bug fix, with attached context docs and reviewer notes

This is a consulting deliverable. The client team can make informed decisions
without having to trust a black-box recommendation. The agents' work is
visible, reviewable, and attached to specific artifacts.

## References

- [The Task System]({{< relref "extending/agent-teams" >}}#the-task-system) -- task states, dependencies, self-claiming
- [Competing Hypotheses Pattern]({{< relref "extending/agent-teams" >}}#competing-hypotheses-debugging) -- adversarial investigation
- [Hooks for Teams]({{< relref "extending/agent-teams" >}}#hooks-for-teams) -- `TeammateIdle`, `TaskCompleted`
- [Fan-Out / Fan-In Pattern]({{< relref "extending/agent-teams" >}}#fan-out--fan-in) -- parallel analysis, synthesized results
- [Anthropic C Compiler Case Study](https://www.anthropic.com/engineering/building-c-compiler) -- large-scale agent coordination patterns
