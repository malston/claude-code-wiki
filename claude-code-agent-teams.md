# Agent Teams: Multi-Agent Orchestration in Claude Code

## Executive Summary

Agent teams let multiple Claude Code instances work together on complex tasks. One session acts as team lead, coordinating work and assigning tasks. Teammates work independently in their own context windows, communicate through direct messaging, and share a task list. This is an experimental feature (disabled by default) that's most valuable for tasks that benefit from parallel work, competing perspectives, or specialized roles.

| Aspect            | Subagents (Standard)              | Agent Teams                            |
| ----------------- | --------------------------------- | -------------------------------------- |
| **Communication** | Results return to parent only     | Teammates message each other directly  |
| **Coordination**  | Hub-and-spoke (parent manages)    | Mesh (shared task list, self-organize) |
| **Context**       | Isolated, results summarized back | Fully independent sessions             |
| **Best for**      | Focused tasks, research           | Parallel work, competing perspectives  |
| **Cost**          | Lower (one instance + subagents)  | Higher (N separate instances)          |

---

## Table of Contents

- [Enabling Agent Teams](#enabling-agent-teams)
- [Architecture](#architecture)
  - [Components](#components)
  - [Communication Flow](#communication-flow)
  - [Display Modes](#display-modes)
- [Starting a Team](#starting-a-team)
  - [Natural Language Creation](#natural-language-creation)
  - [Specifying Models](#specifying-models)
  - [Delegate Mode](#delegate-mode)
- [The Task System](#the-task-system)
  - [Task States](#task-states)
  - [Task Dependencies](#task-dependencies)
  - [Self-Claiming](#self-claiming)
- [Communication](#communication)
  - [Direct Messages](#direct-messages)
  - [Broadcasts](#broadcasts)
  - [Idle Notifications](#idle-notifications)
- [Hooks for Teams](#hooks-for-teams)
  - [TeammateIdle](#teammateidle)
  - [TaskCompleted](#taskcompleted)
- [Plan Approval](#plan-approval)
- [Team Patterns](#team-patterns)
  - [Competing Hypotheses (Debugging)](#competing-hypotheses-debugging)
  - [Parallel Code Review](#parallel-code-review)
  - [Research + Implementation](#research--implementation)
  - [Cross-Layer Coordination](#cross-layer-coordination)
  - [Fan-Out / Fan-In](#fan-out--fan-in)
- [CLI Flags](#cli-flags)
  - [--agent](#--agent)
  - [--agents](#--agents)
  - [--teammate-mode](#--teammate-mode)
- [Permissions](#permissions)
- [Limitations](#limitations)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [References](#references)

---

## Enabling Agent Teams

Agent teams are experimental and disabled by default. Enable with an environment variable:

```json
{
  "env": {
    "CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS": "1"
  }
}
```

Place this in `~/.claude/settings.json` (all projects) or `.claude/settings.json` (this project).

---

## Architecture

### Components

```
┌──────────────────────────────────────────────────┐
│                   Team Lead                       │
│  (main Claude Code session)                       │
│                                                   │
│  ┌─────────┐  ┌─────────┐  ┌─────────┐          │
│  │Teammate │  │Teammate │  │Teammate │          │
│  │   A     │  │   B     │  │   C     │          │
│  └────┬────┘  └────┬────┘  └────┬────┘          │
│       │             │             │               │
│       └─────────────┼─────────────┘               │
│                     │                              │
│              ┌──────┴──────┐                       │
│              │ Shared Task │                       │
│              │    List     │                       │
│              └─────────────┘                       │
│                                                    │
│              ┌─────────────┐                       │
│              │  Mailbox    │                       │
│              │ (messaging) │                       │
│              └─────────────┘                       │
└──────────────────────────────────────────────────┘
```

| Component     | Role                                                                   |
| ------------- | ---------------------------------------------------------------------- |
| **Team lead** | Main session that creates the team, spawns teammates, coordinates work |
| **Teammates** | Separate Claude Code instances, each with their own context            |
| **Task list** | Shared list of work items; teammates claim and complete tasks          |
| **Mailbox**   | Messaging system for direct inter-agent communication                  |

Storage:

- Team config: `~/.claude/teams/{team-name}/config.json`
- Task list: `~/.claude/tasks/{team-name}/`

### Communication Flow

Unlike subagents (hub-and-spoke), agent teams form a mesh:

```
Subagents:                    Agent Teams:

     Main                     Lead ──── Teammate A
    / | \                      │  \       / |
   A  B  C                    │   \     /  │
                               │    \   /   │
  (all report                  │  Teammate B
   back to main)               │      |
                            Teammate C

                          (all communicate
                           with each other)
```

Teammates can:

- Send messages to specific teammates
- Receive messages from any teammate
- Claim tasks from the shared list
- Update task status
- Send idle notifications to the lead

### Display Modes

| Mode           | Description                                       | Requirements          |
| -------------- | ------------------------------------------------- | --------------------- |
| **in-process** | All teammates in the main terminal                | Any terminal          |
| **tmux**       | Each teammate gets its own tmux pane              | tmux                  |
| **iterm2**     | Each teammate gets its own iTerm2 tab             | iTerm2 with `it2` CLI |
| **auto**       | Uses split panes if in tmux, in-process otherwise | --                    |

Set via settings:

```json
{
  "teammateMode": "in-process"
}
```

Or per-session: `claude --teammate-mode in-process`

**In-process controls:**

- `Shift+Up/Down` -- select a teammate
- `Enter` -- view selected teammate's session
- `Escape` -- interrupt teammate
- `Ctrl+T` -- show task list

---

## Starting a Team

### Natural Language Creation

Describe the team structure in your prompt. Claude creates and manages the team:

```
Create an agent team to refactor the authentication module:
- One teammate designs the API surface
- One teammate implements the core logic
- One teammate writes tests
```

Claude will spawn three teammates, assign initial tasks, and coordinate their work.

### Specifying Models

Control cost by specifying models for teammates:

```
Create a team with 3 teammates to review this codebase.
Use Sonnet for each teammate to keep costs down.
```

### Delegate Mode

By default, the lead can both coordinate and implement. Toggle **delegate mode** (Shift+Tab) to restrict the lead to coordination only:

- Can spawn, message, and shut down teammates
- Can manage tasks
- Cannot use coding tools (Read, Write, Edit, Bash, etc.)

This prevents a common problem where the lead starts implementing instead of delegating. You can also instruct the lead explicitly:

```
You are the team coordinator. Do not implement anything yourself.
Delegate all coding tasks to your teammates.
```

---

## The Task System

### Task States

Tasks flow through three states:

```
pending ──> in_progress ──> completed
```

Tasks can also be deleted if no longer needed.

### Task Dependencies

Tasks can depend on other tasks. A task with unresolved dependencies cannot be claimed:

```
Task 1: Design API schema          [no dependencies]
Task 2: Implement endpoints         [blocked by Task 1]
Task 3: Write integration tests     [blocked by Task 2]
Task 4: Write unit tests            [blocked by Task 1]
```

Tasks 1 and 4 can proceed in parallel once Task 1 completes. Task 3 waits for Task 2.

### Self-Claiming

Teammates can self-claim the next available, unblocked task after finishing their current work. The task list uses file locking to prevent race conditions when multiple teammates try to claim the same task.

The lead can also assign tasks explicitly to specific teammates.

---

## Communication

### Direct Messages

Send a message to a specific teammate:

```
message researcher "What did you find about the rate limiting approach?"
```

Messages arrive at the recipient's next turn. They don't interrupt work in progress.

### Broadcasts

Send a message to all teammates at once:

```
broadcast "Heads up: I'm changing the auth module API. Don't modify auth.ts."
```

Use broadcasts sparingly -- cost scales with team size (each teammate processes the message).

### Idle Notifications

When a teammate finishes its current work, it automatically notifies the lead. The lead can then:

- Assign new tasks
- Ask the teammate to review someone else's work
- Shut down the teammate if done

---

## Hooks for Teams

Two hook events are specific to agent teams.

### TeammateIdle

Fires when a teammate is about to go idle after finishing its turn. Exit with code 2 to send feedback and keep the teammate working.

**Input:**

```json
{
  "hook_event_name": "TeammateIdle",
  "teammate_name": "implementer",
  "team_name": "auth-refactor",
  "session_id": "abc123",
  "cwd": "/path/to/project"
}
```

**Example** -- require a build artifact before going idle:

```bash
#!/usr/bin/env bash
INPUT=$(cat)

if [ ! -f "./dist/output.js" ]; then
  echo "Build artifact missing. Run the build before going idle." >&2
  exit 2
fi

exit 0
```

**Limitations:**

- No matcher support -- fires on every occurrence
- Only `type: "command"` hooks supported (no prompt or agent hooks)

### TaskCompleted

Fires when a task is being marked as completed. Exit with code 2 to prevent completion and send feedback.

**Input:**

```json
{
  "hook_event_name": "TaskCompleted",
  "task_id": "task-001",
  "task_subject": "Implement user authentication",
  "task_description": "Add login and signup endpoints",
  "teammate_name": "implementer",
  "team_name": "auth-refactor"
}
```

**Example** -- require passing tests before task completion:

```bash
#!/usr/bin/env bash
INPUT=$(cat)
TASK=$(echo "$INPUT" | jq -r '.task_subject')

if ! npm test 2>&1; then
  echo "Cannot complete '$TASK': tests are failing." >&2
  exit 2
fi

exit 0
```

**Limitations:**

- No matcher support
- Only `type: "command"` hooks supported

---

## Plan Approval

You can require teammates to plan before implementing. The teammate works in read-only plan mode, submits a plan to the lead, and waits for approval:

```
Spawn an architect teammate to refactor the auth module.
Require plan approval before they make any changes.
```

When the lead rejects a plan, the teammate stays in plan mode, revises based on feedback, and resubmits. The lead makes approval decisions autonomously (you can influence the lead's judgment through your prompt).

This pattern is useful for high-stakes changes where you want a review gate before code modification.

---

## Team Patterns

### Competing Hypotheses (Debugging)

Spawn multiple investigators to explore different theories about a bug. Have them communicate and challenge each other's findings:

```
Users report the app exits after one message instead of staying connected.
Spawn 5 teammates to investigate different hypotheses:
1. WebSocket connection lifecycle
2. Message parsing errors
3. Authentication token expiry
4. Server-side timeout configuration
5. Client-side event handler issues

Have them share findings and try to disprove each other's theories.
Update a shared findings doc with whatever consensus emerges.
```

This fights anchoring bias -- sequential investigation tends to find one explanation and stop looking. Multiple parallel investigators surface the actual root cause more reliably.

### Parallel Code Review

Three specialized reviewers examine the same PR from different angles:

```
Create an agent team to review PR #142:
- Security reviewer: check for vulnerabilities and auth issues
- Performance reviewer: check for N+1 queries, unnecessary allocations
- Test reviewer: check coverage, edge cases, test quality

Each reviewer writes findings independently.
Synthesize into a final review.
```

### Research + Implementation

Separate research from coding with task dependencies:

```
Create a team:
- 2 researchers: investigate the GraphQL library API, edge cases, and patterns
- 1 implementer: build the integration based on research findings

The implementer should wait until both researchers finish.
```

Task dependencies (`blocked by`) ensure the implementer doesn't start until research is complete.

### Cross-Layer Coordination

Each teammate owns a different layer, preventing file conflicts:

```
Create a team for the new user settings feature:
- Frontend teammate: React components in src/components/settings/
- Backend teammate: API endpoints in src/api/settings/
- Database teammate: Schema changes and migrations in src/db/
```

Clear file ownership avoids merge conflicts. Communication through messaging handles cross-layer coordination (e.g., "I need the settings endpoint to return X shape").

### Fan-Out / Fan-In

Break a large task into independent pieces, process in parallel, synthesize:

```
Analyze all 12 API endpoint files for security vulnerabilities.
Spawn 4 teammates, each analyzing 3 files.
When all finish, compile findings into a single report.
```

The shared task list handles coordination. The lead synthesizes results in the fan-in phase.

---

## CLI Flags

### --agent

Run your main session as a specialized agent. Applies the agent's system prompt, tool restrictions, and model:

```bash
claude --agent security-reviewer
claude --agent api-designer --resume my-session
```

You can set a default agent in settings:

```json
{
  "agent": "security-reviewer"
}
```

The CLI flag overrides the settings value.

### --agents

Define subagents dynamically via JSON for the current session only:

```bash
claude --agents '{
  "code-reviewer": {
    "description": "Expert code reviewer",
    "prompt": "You review code for quality and security.",
    "tools": ["Read", "Grep", "Glob", "Bash"],
    "model": "sonnet"
  }
}'
```

These agents exist only for the session and are not saved to disk.

### --teammate-mode

Control how agent team sessions are displayed:

```bash
claude --teammate-mode in-process    # All in main terminal
claude --teammate-mode tmux          # Split into tmux panes
```

---

## Permissions

Teammates inherit the lead's permission settings at spawn time:

- If the lead uses `--dangerously-skip-permissions`, all teammates do too
- Permission requests from teammates bubble up to the lead
- You can change individual teammate modes after spawning (not at spawn time)

**Recommendation:** Pre-approve common operations in your permission settings before spawning teammates. Constant permission prompts create friction in team workflows.

---

## Limitations

| Limitation                 | Details                                                         |
| -------------------------- | --------------------------------------------------------------- |
| **Experimental**           | Disabled by default, requires environment variable              |
| **No session resumption**  | `/resume` and `/rewind` don't restore teammates                 |
| **Task status lag**        | Teammates sometimes fail to mark tasks complete                 |
| **Slow shutdown**          | Teammates finish their current turn before stopping             |
| **One team per session**   | Clean up the current team before starting another               |
| **No nested teams**        | Teammates cannot spawn their own teams                          |
| **Fixed leadership**       | Cannot promote a teammate or transfer lead role                 |
| **Permissions at spawn**   | All teammates inherit lead's mode; change individually after    |
| **Split-pane limitations** | Not supported in VS Code terminal, Windows Terminal, or Ghostty |
| **No context inheritance** | Teammates don't get the lead's conversation history             |

---

## Best Practices

1. **Start with review tasks.** Research and review have clear boundaries, no file conflicts, and easy-to-verify results. Use these to get comfortable with teams before attempting parallel implementation.

2. **Assign clear file ownership.** Two teammates editing the same file leads to overwrites. Break work so each teammate owns distinct file sets.

3. **Give teammates enough context in spawn prompts.** Conversation history doesn't carry over. Include relevant background, constraints, and success criteria.

4. **Use delegate mode for the lead.** On larger teams, the lead should coordinate, not implement. Press Shift+Tab or instruct explicitly.

5. **Pre-approve common permissions.** Teammate permission requests bubble up and create interruptions. Configure permission settings before spawning.

6. **Use hooks for quality gates.** TeammateIdle and TaskCompleted hooks enforce standards (passing tests, build success) without manual checking.

7. **Size tasks appropriately.** Aim for 5-6 self-contained tasks per teammate. Too many small tasks create coordination overhead; too few large tasks underutilize parallelism.

8. **Monitor and steer.** Check on teammates periodically. Redirect approaches that aren't working. Don't leave a team running unattended for hours.

9. **Clean up through the lead.** When done, shut down teammates through the lead session rather than killing processes directly.

10. **Consider cost.** Each teammate is a full Claude instance. Three teammates on Opus for complex work can consume 3-4x the tokens of a single session. Use Sonnet teammates where possible.

---

## Anti-Patterns

1. **Using teams for simple sequential tasks.** If work is naturally sequential (step 1 then step 2 then step 3), a single session is simpler and cheaper. Teams shine when work can be parallelized.

2. **Not assigning file ownership.** Two teammates modifying the same files leads to overwrites and wasted work. Always partition files across teammates.

3. **Skipping spawn context.** Spawning a teammate with "implement the auth module" misses critical context. Include what approach to take, which files to modify, and what constraints exist.

4. **Too many teammates.** More teammates means more coordination overhead, more messages, more cost. Start with 2-3 and scale up only if needed.

5. **Lead implementing instead of delegating.** Without delegate mode, the lead often starts coding instead of coordinating. This defeats the purpose of having a team.

6. **Ignoring idle notifications.** When a teammate goes idle, it needs new work or should be shut down. Idle teammates still consume resources.

7. **Broadcasting frequently.** Every broadcast sends a message to every teammate, consuming tokens per recipient. Use direct messages for teammate-specific communication.

8. **Not pre-approving permissions.** Permission prompts interrupt team flow. Pre-approve common operations before starting the team.

---

## References

- [Official Agent Teams Documentation](https://code.claude.com/docs/en/agent-teams) -- setup, architecture, display modes, task system
- [Official Subagents Reference](https://code.claude.com/docs/en/sub-agents) -- subagent configuration, comparison with teams
- [Official Hooks Reference](https://code.claude.com/docs/en/hooks) -- TeammateIdle, TaskCompleted events
- [Official CLI Reference](https://code.claude.com/docs/en/cli-reference) -- `--agent`, `--agents`, `--teammate-mode` flags
- [Custom Extensions Article](claude-code-custom-extensions.md) -- building subagents and skills
- [Integration Patterns Article](claude-code-integration-patterns.md) -- hooks and headless mode
