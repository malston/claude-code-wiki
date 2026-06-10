---
title: "Dynamic Workflows: Orchestrating Subagents at Scale"
linkTitle: "Dynamic Workflows"
weight: 6
---

# Dynamic Workflows: Orchestrating Subagents at Scale

## Executive Summary

A dynamic workflow is a JavaScript script that orchestrates subagents at scale. You describe the task, Claude writes the script, and a runtime executes it in the background while your session stays responsive. The script holds the loop, the branching, and the intermediate results, so your conversation receives only the final answer instead of a turn-by-turn transcript. Workflows suit tasks that need more agents than one conversation can coordinate: a codebase-wide bug sweep, a 500-file migration, or a research question where sources must be cross-checked against each other.

Dynamic workflows are a research preview. They require Claude Code v2.1.154 or later and run on all paid plans, the Anthropic API, Amazon Bedrock, Google Vertex AI, and Microsoft Foundry. On Pro, enable them from the Dynamic workflows row in `/config`.

| Aspect                       | Subagents                | Agent Teams                  | Dynamic Workflows             |
| ---------------------------- | ------------------------ | ---------------------------- | ----------------------------- |
| Who decides what runs next   | Claude, turn by turn     | The lead agent, turn by turn | The script                    |
| Intermediate results live in | Claude's context         | A shared task list           | Script variables              |
| Scale                        | A few delegated per turn | A handful of peers           | Dozens to hundreds per run    |
| Repeatable unit              | The worker definition    | The team definition          | The orchestration itself      |
| Interruption                 | Restarts the turn        | Teammates keep running       | Resumable in the same session |

## Table of Contents

- [Dynamic Workflows: Orchestrating Subagents at Scale](#dynamic-workflows-orchestrating-subagents-at-scale)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [When to Use a Workflow](#when-to-use-a-workflow)
  - [Triggering a Workflow](#triggering-a-workflow)
    - [The ultracode Keyword](#the-ultracode-keyword)
    - [Ultracode Effort Mode](#ultracode-effort-mode)
    - [Bundled Workflows](#bundled-workflows)
  - [Approving the Run](#approving-the-run)
  - [Watching and Managing Runs](#watching-and-managing-runs)
  - [How a Workflow Runs](#how-a-workflow-runs)
  - [Anatomy of a Workflow Script](#anatomy-of-a-workflow-script)
  - [Saving and Reusing Workflows](#saving-and-reusing-workflows)
  - [Limits](#limits)
  - [Cost](#cost)
  - [Turning Workflows Off](#turning-workflows-off)
  - [Best Practices](#best-practices)
  - [Anti-Patterns](#anti-patterns)
  - [References](#references)

## When to Use a Workflow

Subagents, skills, agent teams, and workflows can all run a multi-step task. The difference is who holds the plan.

| Aspect           | Subagents              | Skills                      | Agent Teams                      | Workflows                     |
| ---------------- | ---------------------- | --------------------------- | -------------------------------- | ----------------------------- |
| What it is       | A worker Claude spawns | Instructions Claude follows | A lead supervising peer sessions | A script the runtime executes |
| Who orchestrates | Claude, turn by turn   | Claude, per the prompt      | The lead, turn by turn           | The script                    |
| Results live in  | Claude's context       | Claude's context            | A shared task list               | Script variables              |
| Scale            | A few per turn         | Same as subagents           | A handful of peers               | Dozens to hundreds per run    |

With subagents, skills, and agent teams, Claude is the orchestrator: it decides turn by turn what to spawn next, and every result lands in a context window. A workflow moves the plan into code. The script holds the loop, the branching, and the intermediate results, so Claude's context holds only the final answer. That is what lets a workflow coordinate hundreds of agents without exhausting the context window.

Moving the plan into code also lets a workflow apply a repeatable quality pattern. The script can have independent agents adversarially review each other's findings before they are reported, or draft a plan from several angles and weigh them against each other, so a run produces a more trustworthy result than a single pass.

Reach for a workflow when:

- A task needs more agents than one conversation can track (a repo-wide audit, a large migration).
- You want the orchestration codified as a script you can read and rerun.
- The result is worth cross-checking, so independent agents should verify each other.

Stay with subagents or a skill when a few delegated tasks per turn cover the work, or with an agent team when a handful of long-running peers need to message each other. See the [Agent Teams article]({{< relref "agent-teams" >}}) for the mesh model.

## Triggering a Workflow

### The ultracode Keyword

To run a single task as a workflow without changing the session's effort level, include the keyword `ultracode` in your prompt. Asking in plain language ("use a workflow", "run a workflow") works too -- Claude treats a direct request as the same opt-in.

```text
ultracode: audit every API endpoint under src/routes/ for missing auth checks
```

Claude Code highlights the keyword and Claude writes a workflow script for the task instead of working through it turn by turn. To dismiss the highlight for a prompt, press `Option+W` (macOS) or `Alt+W` (Windows and Linux), or press backspace with the cursor right after the highlighted keyword. To stop the keyword from triggering at all, turn off the Ultracode keyword trigger in `/config`.

Before v2.1.160 the literal trigger keyword was `workflow`. Natural-language requests work in both versions.

### Ultracode Effort Mode

Ultracode is an effort setting that combines `xhigh` reasoning effort with automatic workflow orchestration. With it on, Claude plans a workflow for each substantive task instead of waiting for you to ask.

```text
/effort ultracode
```

A single request can turn into several workflows in a row: one to understand the code, one to make the change, and one to verify it. This applies to every task in the session, so each request uses more tokens and takes longer than at lower effort levels. Ultracode lasts for the current session and resets when you start a new one. Drop back with `/effort high` when you return to routine work.

Ultracode is available only on models that support `xhigh` effort (Opus 4.7 and 4.8). On other models the `/effort` menu does not offer it. See the [Extended Thinking article]({{< relref "/internals/extended-thinking" >}}) for effort levels.

### Bundled Workflows

Claude Code ships one built-in workflow:

| Command                     | What it does                                                                                                                                                                                      |
| --------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/deep-research <question>` | Fans out web searches across several angles, fetches and cross-checks sources, votes on each claim, and returns a cited report with unsupported claims filtered out. Requires the WebSearch tool. |

Workflows you save yourself become commands the same way and appear in `/` autocomplete alongside the bundled one.

## Approving the Run

When a workflow is about to start, the CLI shows the planned phases and asks for approval:

- **Yes, run it** -- start the run.
- **Yes, and don't ask again for `<name>` in `<path>`** -- start, and skip this prompt for this workflow in this project from now on.
- **View raw script** -- read the script before deciding (`Ctrl+G` opens it in your editor).
- **No** -- cancel.

`Tab` lets you adjust the prompt before the run starts. Whether you see this prompt depends on your permission mode:

| Permission mode                            | When you are prompted                                                                   |
| ------------------------------------------ | --------------------------------------------------------------------------------------- |
| Default, accept edits                      | Every run, unless you selected "don't ask again" for that workflow in this project      |
| Auto                                       | First launch only; later launches start without prompting; skipped when ultracode is on |
| Bypass permissions, `claude -p`, Agent SDK | Never; the run starts immediately                                                       |

The permission mode controls only the launch prompt. The subagents a workflow spawns always run in `acceptEdits` mode and inherit your tool allowlist, regardless of your session's mode, so file edits are auto-approved. Shell commands, web fetches, and MCP tools that are not in your allowlist can still prompt you mid-run. Add the commands the agents will need to your allowlist before a long run to avoid interruptions.

## Watching and Managing Runs

Workflows run in the background. Run `/workflows` at any time to list running and completed workflows, then select one to open its progress view.

```text
/workflows
```

The progress view shows each phase with its agent count, token total, and elapsed time. The footer lists the controls:

| Key            | Action                                                                            |
| -------------- | --------------------------------------------------------------------------------- |
| `↑` / `↓`      | Select a phase or agent                                                           |
| `Enter` or `→` | Drill into a phase, then into an agent to read its prompt, tool calls, and result |
| `Esc`          | Back out one level                                                                |
| `j` / `k`      | Scroll within the agent detail when it overflows                                  |
| `p`            | Pause or resume the run                                                           |
| `x`            | Stop the selected agent, or the whole workflow when focus is on the run           |
| `r`            | Restart the selected running agent                                                |
| `s`            | Save the run's script as a command                                                |

A one-line progress summary also appears in the task panel below the input box while a run is going. Press the down arrow to focus it, then Enter to expand.

## How a Workflow Runs

The runtime executes the script in an isolated environment, separate from your conversation. Intermediate results stay in script variables instead of landing in Claude's context, which is why a run can coordinate far more agents than a single conversation could hold.

Every run writes its script to a file under your session's directory in `~/.claude/projects/`. Claude receives the path when the run starts, so you can ask for it, read the orchestration Claude wrote, diff it against a previous run, or edit it and ask Claude to relaunch from the edited version.

The runtime tracks each agent's result as the run progresses. If you stop a run, you can resume it: agents that already completed return their cached results, and the rest run live. Resume works within the same Claude Code session. If you exit Claude Code while a workflow is running, the next session starts it fresh.

## Anatomy of a Workflow Script

Claude writes the script; you do not have to. Reading one helps you understand what a run is doing and edit it when you want to adjust the orchestration. A script declares its phases in a `meta` block, then uses a small set of primitives to spawn and coordinate agents:

| Primitive    | What it does                                                                                   |
| ------------ | ---------------------------------------------------------------------------------------------- |
| `agent()`    | Spawn one subagent. Returns its text, or a schema-validated object when you pass a JSON Schema |
| `parallel()` | Run several agents concurrently and wait for all of them (a barrier)                           |
| `pipeline()` | Run each item through a series of stages with no barrier between stages                        |
| `phase()`    | Start a named phase; agents spawned after it are grouped under that name in `/workflows`       |
| `log()`      | Emit a progress line to the run                                                                |
| `args`       | Input passed to a saved workflow at invocation time                                            |

A representative script that reviews route files for missing auth checks, then has an independent agent verify each finding before it is reported:

```javascript
export const meta = {
  name: "audit-endpoints",
  description:
    "Audit API routes for missing auth checks, then verify each finding",
  phases: [{ title: "Review" }, { title: "Verify" }],
};

// Subagents validate their output against these JSON Schemas.
const FINDINGS_SCHEMA = {
  type: "object",
  properties: {
    findings: {
      type: "array",
      items: {
        type: "object",
        properties: { title: { type: "string" } },
        required: ["title"],
      },
    },
  },
  required: ["findings"],
};
const VERDICT_SCHEMA = {
  type: "object",
  properties: { isReal: { type: "boolean" } },
  required: ["isReal"],
};

// Each route file is reviewed, then each of its findings is independently verified.
// pipeline() means a file can be in Verify while another is still in Review.
// args is undefined when the workflow runs without input, so guard with ?.
const results = await pipeline(
  args?.files ?? [],
  (file) =>
    agent(`Review ${file} for endpoints missing auth checks.`, {
      phase: "Review",
      schema: FINDINGS_SCHEMA,
    }),
  (review, file) =>
    parallel(
      review.findings.map(
        (finding) => () =>
          agent(
            `Adversarially verify this finding in ${file}: ${finding.title}. Is it real?`,
            {
              phase: "Verify",
              schema: VERDICT_SCHEMA,
            },
          ).then((verdict) => ({ ...finding, confirmed: verdict.isReal })),
      ),
    ),
);

return results.flat().filter((finding) => finding.confirmed);
```

The script -- not Claude turn by turn -- decides what runs next, holds the findings in variables, and applies the verify-before-report pattern. Subagents can be routed to different models, given their own git worktree for isolated edits, or constrained by a token budget; the canonical reference for any run is the generated script you can open and read.

## Saving and Reusing Workflows

When Claude writes a workflow for a task you will repeat, save that run's script as a command. Run `/workflows`, select the run, and press `s`. The save dialog offers two locations (`Tab` toggles between them):

- `.claude/workflows/` in your project -- shared with everyone who clones the repo.
- `~/.claude/workflows/` in your home directory -- available in every project, visible only to you.

Press Enter to save. The workflow then runs as `/<name>` in future sessions. If a project workflow and a personal workflow share a name, the project one wins.

A saved workflow can accept input through the `args` parameter, which the script reads as a global named `args`:

```text
Run /triage-issues on issues 1024, 1025, and 1030
```

Claude passes the list as structured data, so the script can call array and object methods on `args` directly. If `args` is omitted, the global is `undefined`.

## Limits

| Constraint                                           | Why                                                                                                            |
| ---------------------------------------------------- | -------------------------------------------------------------------------------------------------------------- |
| No mid-run user input                                | Only agent permission prompts can pause a run. For sign-off between stages, run each stage as its own workflow |
| No direct filesystem or shell access from the script | Agents read, write, and run commands. The script only coordinates the agents                                   |
| Up to 16 concurrent agents (fewer on limited cores)  | Bounds local resource use                                                                                      |
| 1,000 agents total per run                           | Prevents runaway loops                                                                                         |

## Cost

A workflow spawns many agents, so a single run can use meaningfully more tokens than working through the same task in conversation. Runs count toward your plan's usage and rate limits like any other session.

To gauge the spend before committing to a large task, run the workflow on a small slice first: one directory instead of the whole repo, or a narrow question instead of a broad one. The `/workflows` view shows each agent's token usage as the run progresses, and you can stop the run at any time without losing completed work. The agent caps bound the cost of a runaway script.

Every agent uses your session's model unless the script routes a stage to a different one. Check `/model` before a large run if you usually switch to a smaller model for routine work, and ask Claude to use a smaller model for stages that do not need the strongest one. See the [Model Selection article]({{< relref "/guides/model-selection" >}}).

## Turning Workflows Off

Workflows are available in the CLI, the Desktop app, the IDE extensions, headless mode (`claude -p`), and the Agent SDK. The same disable settings apply everywhere:

```json
{ "disableWorkflows": true }
```

```bash
CLAUDE_CODE_DISABLE_WORKFLOWS=1 claude
```

You can also toggle Dynamic workflows off in `/config`. To disable for an entire organization, set `"disableWorkflows": true` in managed settings or use the toggle on the Claude Code admin settings page. When workflows are disabled, the bundled commands are unavailable, the `ultracode` keyword no longer triggers a run, and `ultracode` is removed from the `/effort` menu.

## Best Practices

1. **Start with `/deep-research`.** The bundled workflow shows the run lifecycle -- phases, the `/workflows` view, a single report at the end -- before you orchestrate your own task.

2. **Scope the slice before the repo.** Run a workflow on one directory or a narrow question first. Read the result and the token usage in `/workflows`, then widen the input once it does what you want.

3. **Read the generated script.** The script is saved under `~/.claude/projects/`. Reading it tells you exactly what will run; editing it and relaunching is faster than re-describing the task.

4. **Pre-approve the tools agents need.** Subagents run in `acceptEdits`, but shell, web, and MCP calls outside your allowlist still prompt mid-run. Add them before a long run.

5. **Route cheap stages to a cheaper model.** Ask Claude to use Sonnet or Haiku for search and triage stages, reserving the strongest model for synthesis.

6. **Save the ones you repeat.** A per-branch review or a recurring triage becomes a `/<name>` command with `s` in the `/workflows` view, with `args` for the per-run input.

7. **Use ultracode deliberately.** `/effort ultracode` plans a workflow for every substantive task, which multiplies tokens and time. Turn it on for a hard stretch of work and drop back to `/effort high` for routine edits.

## Anti-Patterns

1. **A workflow for a one-shot task.** If a few subagents in a single turn cover the work, a workflow adds orchestration overhead and tokens for no benefit. Reach for one when the agent count exceeds what a conversation can track.

2. **Leaving ultracode on for routine work.** It turns every request into one or more workflows. Drop back to `/effort high` once the hard part is done.

3. **Launching a broad run without a slice test.** A repo-wide workflow on the first try can spend heavily before you learn the script does the wrong thing. Test on a directory first.

4. **Expecting to steer mid-run.** A run takes no user input once it starts; only agent permission prompts pause it. If you need a sign-off between stages, split the work into separate workflows.

5. **Ignoring the model setting.** Every agent inherits the session model. A large run on Opus when Sonnet would do multiplies the bill across hundreds of agents.

## References

- [Orchestrate Subagents at Scale with Dynamic Workflows (Claude Code Docs)](https://code.claude.com/docs/en/workflows) -- triggering, the `/workflows` view, saving, limits, and cost
- [Introducing Dynamic Workflows in Claude Code](https://claude.com/blog/introducing-dynamic-workflows-in-claude-code) -- announcement and motivation
- [Run Agents in Parallel (Claude Code Docs)](https://code.claude.com/docs/en/agents) -- comparison of subagents, agent view, agent teams, and workflows
- [Create Custom Subagents (Claude Code Docs)](https://code.claude.com/docs/en/sub-agents) -- the worker primitive workflows orchestrate
- [Manage Costs (Claude Code Docs)](https://code.claude.com/docs/en/costs) -- how multi-agent runs count toward usage limits
- [Agent Teams Article]({{< relref "agent-teams" >}}) -- the mesh-coordination model for multi-agent work
- [Extension Mechanisms Article]({{< relref "extension-mechanisms" >}}) -- subagents, skills, and MCP servers
