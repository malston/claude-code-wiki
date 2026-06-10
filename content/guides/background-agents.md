---
title: "Background Agents and Agent View: Running Many Sessions at Once"
linkTitle: "Background Agents"
weight: 13
---

# Background Agents and Agent View: Running Many Sessions at Once

## Executive Summary

A background session is a full Claude Code conversation that keeps running without a terminal attached. Agent view, opened with `claude agents`, is one screen that lists every background session, shows what each is doing, and flags the ones that need your input. You dispatch independent tasks -- a bug fix, a PR review, a flaky-test investigation -- as separate rows, work elsewhere, and step in only when a row needs you. A per-user supervisor process hosts the sessions, so they keep running after you close the view or the shell.

Agent view is a research preview and requires Claude Code v2.1.139 or later. Check with `claude --version`.

| Method          | Command                           | Use                                             |
| --------------- | --------------------------------- | ----------------------------------------------- |
| From the shell  | `claude --bg "<task>"`            | Start a session detached from any terminal      |
| From a session  | `/bg` (or `←` on an empty prompt) | Send the current conversation to the background |
| From agent view | Type a prompt in `claude agents`  | Dispatch a fresh session as a new row           |

## Table of Contents

- [Background Agents and Agent View: Running Many Sessions at Once](#background-agents-and-agent-view-running-many-sessions-at-once)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [Opening Agent View](#opening-agent-view)
  - [Creating Background Sessions](#creating-background-sessions)
    - [From Agent View](#from-agent-view)
    - [From Inside a Session](#from-inside-a-session)
    - [From the Shell](#from-the-shell)
    - [Running a Shell Command](#running-a-shell-command)
  - [Reading the Agent View](#reading-the-agent-view)
    - [Session State](#session-state)
    - [Pull Request Status](#pull-request-status)
    - [Row Summaries](#row-summaries)
  - [Working with Sessions](#working-with-sessions)
    - [Peek and Reply](#peek-and-reply)
    - [Attach and Detach](#attach-and-detach)
    - [Organize and Filter](#organize-and-filter)
    - [Keyboard Shortcuts](#keyboard-shortcuts)
  - [Managing Sessions from the Shell](#managing-sessions-from-the-shell)
  - [How File Edits Are Isolated](#how-file-edits-are-isolated)
  - [Model, Effort, and Permissions](#model-effort-and-permissions)
  - [How Sessions Are Hosted](#how-sessions-are-hosted)
  - [Turning Agent View Off](#turning-agent-view-off)
  - [Limitations](#limitations)
  - [Best Practices](#best-practices)
  - [Anti-Patterns](#anti-patterns)
  - [References](#references)

## Opening Agent View

Run `claude agents` to open agent view. It takes over the terminal and lists every background session you have started, across all projects, grouped by state with pinned sessions and the ones that need input at the top.

```bash
claude agents
```

Press `Esc` to return to your shell; sessions keep running while you are away. You can use `claude agents` as your primary entry point instead of `claude`: dispatch every task from the view, attach when you want the full conversation, and press `←` to return to the table.

To narrow the list to one project, pass `--cwd` (v2.1.141 or later):

```bash
claude agents --cwd ~/projects/my-app
```

Subagents and teammates a session spawns are not listed as separate rows. Interactive sessions open in other terminals do not appear until you background them.

## Creating Background Sessions

### From Agent View

Type a prompt in the input at the bottom of agent view and press `Enter`. Each prompt starts its own new session, so entering a second prompt launches a second session rather than following up on the first. The session is named automatically from the prompt; rename it later with `Ctrl+R`.

Prefixes and mentions control how the session starts:

| Input                   | Effect                                                                            |
| ----------------------- | --------------------------------------------------------------------------------- |
| `<agent-name> <prompt>` | If the first word matches a custom subagent, that subagent runs as the main agent |
| `@<agent-name>`         | Mention a custom subagent anywhere in the prompt to run it as the main agent      |
| `@<repo>`               | Mention a repository under the opened directory to run the session there          |
| `/<command>`            | Dispatch a skill or command as the session's first prompt                         |
| `! <command>`           | Run a shell command as a background job instead of starting a Claude session      |
| `#<number>` or a PR URL | Select the session already working on that pull request                           |
| `Shift+Enter`           | Dispatch and immediately attach to the new session                                |

`/exit` and `/quit` close agent view and `/logout` signs you out; every other command or skill is sent to a new session as its first prompt.

### From Inside a Session

Run `/background` or its alias `/bg` to move the current conversation into a background session. Pass a prompt to give one more instruction first:

```text
/bg run the test suite and fix any failures
```

If Claude is responding when you run `/bg`, the response continues in the background. Backgrounding starts a fresh process that resumes from the saved conversation, so running subagents, monitors, and background commands do not transfer; Claude asks you to confirm before backgrounding when any are running. Configuration flags from the original launch carry through: `--mcp-config`, `--strict-mcp-config`, `--settings`, `--add-dir`, `--plugin-dir`, `--fallback-model`, and `--allow-dangerously-skip-permissions`, along with directories added with `/add-dir`.

Pressing `←` on an empty prompt backgrounds the current session and opens agent view with that row selected, in one step. This works from any session, even a fresh one with no history. Turn the shortcut off with the `leftArrowOpensAgents` setting in `/config`.

### From the Shell

Pass `--bg` to start a session that goes straight to the background:

```bash
claude --bg "investigate the flaky SettingsChangeDetector test"
```

Combine with `--agent` to run a specific subagent as the main agent, and `--name` to set the display name:

```bash
claude --agent code-reviewer --bg --name "pr-1234" "address review comments on PR 1234"
```

Claude prints the session's short ID and the commands to manage it:

```text
backgrounded · 7c5dcf5d · pr-1234
  claude agents             list sessions
  claude attach 7c5dcf5d    open in this terminal
  claude logs 7c5dcf5d      show recent output
  claude stop 7c5dcf5d      stop this session
```

### Running a Shell Command

To run a shell command as a background job instead of a Claude session, type `!` as the first character of the dispatch input, or use `--exec` from the shell:

```bash
claude --bg --exec 'pytest -x'
```

The command runs as a PTY-backed job and appears as a row with its most recent output line as the status. No model is invoked. Attach, peek with `Space`, or run `claude logs <id>` to see output. The captured output stays in memory, is not written to disk, and the row cleans up about five minutes after the command exits.

## Reading the Agent View

Agent view groups sessions so the ones that need you are at the top: `Ready for review` (an open pull request) and `Needs input` sit above `Working` and `Completed`. `Completed` collects finished, failed, and stopped sessions together. Press `Ctrl+S` to group by directory instead; the choice persists.

```text
Needs input
  ✻ power-up design           needs input: double jump or wall climb?       1m

Working
  ✽ collision detection       Edit src/physics/CollisionSystem.ts           2m

Ready for review
  ∙ jump physics              Opened PR with collision fix              PR #2048  2h

Completed
  ✻ title screen              result: menu, options, and credits done       9m
```

### Session State

Each row starts with an icon whose color shows the session's state:

| State       | Icon     | Meaning                                                |
| ----------- | -------- | ------------------------------------------------------ |
| Working     | Animated | Claude is running tools or generating a response       |
| Needs input | Yellow   | Claude is waiting on a question or permission decision |
| Idle        | Dimmed   | Nothing to do; ready for your next prompt              |
| Completed   | Green    | The task finished successfully                         |
| Failed      | Red      | The task ended with an error                           |
| Stopped     | Grey     | Stopped with `Ctrl+X` or `claude stop`                 |

The icon's shape shows whether the underlying process is running:

| Shape               | Meaning                                                                           |
| ------------------- | --------------------------------------------------------------------------------- |
| `✻` or animated `✽` | The process is alive and replies immediately                                      |
| `∙`                 | The process has exited; peek, reply, or attach restarts it from where it left off |
| `✢`                 | A `/loop` session sleeping between iterations, with a run count and countdown     |

The terminal tab title shows the awaiting-input count while agent view is open, such as `2 awaiting input · claude agents`.

### Pull Request Status

When a session opens a pull request, a `PR #1234` label appears at the right edge of the row, linked in terminals that support hyperlinks. Multiple pull requests show as a count, such as `3 PRs`. The number is colored by status:

| Color  | Pull request status                           |
| ------ | --------------------------------------------- |
| Yellow | Waiting on checks or review, or checks failed |
| Green  | Checks passed and no review is blocking       |
| Purple | Merged                                        |
| Grey   | Draft or closed                               |

For most tasks this column is where you pick up the result: review and merge the pull request when its number turns green.

### Row Summaries

The one-line summary in each row is generated by a Haiku-class model so you can see what a session is doing without opening the transcript. While a session works, the summary refreshes at most once every 15 seconds plus once per turn end. Each refresh is one short request billed under the session's normal provider. On third-party providers without a Haiku model configured, set `ANTHROPIC_DEFAULT_HAIKU_MODEL` to choose the summary model. From v2.1.161, a `done/total` count such as `2/5` appears before the summary when the session is running parallel work items.

## Working with Sessions

### Peek and Reply

Press `Space` on a selected row to open the peek panel. It shows what the session needs, its most recent output, and any pull requests it opened -- usually enough that you never open the full transcript. Type a reply and press `Enter` to send it without leaving agent view. For a multiple-choice question, press a number key to pick an option; for other blocked sessions, press `Tab` to fill the input with a suggested reply. Prefix a reply with `!` to send a Bash command. Use `↑` and `↓` to peek at adjacent sessions, or `→` to attach.

### Attach and Detach

Press `Enter` or `→` on a row to attach. Agent view is replaced by the full interactive session, and Claude posts a short recap of what happened while you were away. Attached sessions render in fullscreen (a background session has no scrollback to append to); scroll with `PgUp`/`PgDn` and press `Ctrl+O` for transcript mode.

Press `←` on an empty prompt to detach and return to agent view (or `Ctrl+Z` if a dialog has focus). Detaching never stops a session: `←`, `Ctrl+Z`, `/exit`, and double `Ctrl+C` all leave it running. To end a session from inside it, run `/stop`.

### Organize and Filter

Within a group:

- `Ctrl+T` -- pin a session to the top and keep its process running while idle
- `Shift+↑` / `Shift+↓` -- reorder sessions
- `Ctrl+R` -- rename a session
- `Enter` on a group header -- collapse it
- `Ctrl+X`, then `Ctrl+X` again within two seconds -- stop, then delete the session

Type in the dispatch input to filter instead of dispatching:

| Filter                  | Shows                                                   |
| ----------------------- | ------------------------------------------------------- |
| `a:<name>`              | Sessions running the named agent                        |
| `s:<state>`             | Sessions in a state, such as `s:working` or `s:blocked` |
| `#<number>` or a PR URL | The session working on that pull request                |

### Keyboard Shortcuts

Press `?` in agent view to see every shortcut in context.

| Shortcut         | Action                                                            |
| ---------------- | ----------------------------------------------------------------- |
| `↑` / `↓`        | Move between rows                                                 |
| `Enter`          | Attach to the selected session, or dispatch if the input has text |
| `Space`          | Open or close the peek panel                                      |
| `Shift+Enter`    | Dispatch and attach immediately                                   |
| `→`              | Attach to the selected session                                    |
| `Alt+1`..`Alt+9` | Attach to session 1-9 in the focused directory                    |
| `Ctrl+S`         | Switch grouping between state and directory                       |
| `Ctrl+T`         | Pin or unpin the selected session                                 |
| `Ctrl+R`         | Rename the selected session                                       |
| `Ctrl+G`         | Open the dispatch prompt in `$VISUAL` or `$EDITOR`                |
| `Ctrl+X`         | Stop the session; press again within two seconds to delete it     |
| `Esc`            | Close the peek panel, clear the input, or exit                    |
| `?`              | Show all shortcuts                                                |

## Managing Sessions from the Shell

Every background session has a short ID, printed when you start it with `claude --bg` and used as its directory name under `~/.claude/jobs/`. These commands work without opening agent view, which is useful for scripting:

| Command                      | Purpose                                                                                                                                     |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------- |
| `claude agents`              | Open agent view                                                                                                                             |
| `claude agents --cwd <path>` | Open agent view scoped to sessions started under `<path>`                                                                                   |
| `claude agents --json`       | Print live sessions as JSON and exit (`pid`, `cwd`, `kind`, `startedAt`, plus `sessionId`, `name`, `status`, and `waitingFor` when blocked) |
| `claude attach <id>`         | Attach to a session in this terminal                                                                                                        |
| `claude logs <id>`           | Print the session's recent output                                                                                                           |
| `claude stop <id>`           | Stop a session (also `claude kill`)                                                                                                         |
| `claude respawn <id>`        | Restart a session with its conversation intact, e.g. to pick up an updated binary                                                           |
| `claude respawn --all`       | Restart every running session at once                                                                                                       |
| `claude rm <id>`             | Remove a session; keeps a worktree with uncommitted changes and prints its path                                                             |
| `claude daemon status`       | Print the supervisor's state, version, socket directory, and worker count                                                                   |

The conversation transcript stays on your machine after a session is removed and remains available through `claude --resume`.

## How File Edits Are Isolated

Every background session starts in your working directory. Before editing files, Claude moves the session into an isolated git worktree under `.claude/worktrees/`, so parallel sessions read the same checkout but each writes to its own. Claude skips the worktree when the session is already inside a linked worktree, the directory is not a git repository (and no `WorktreeCreate` hook is configured), or the write is outside the working directory.

To turn worktree isolation off for a repository where worktrees are impractical, set `worktree.bgIsolation` to `"none"` (v2.1.143 or later). Background sessions then edit the working copy directly:

```json
{
  "worktree": {
    "bgIsolation": "none"
  }
}
```

Deleting a session in agent view (`Ctrl+X` twice) removes a worktree Claude created for it, including uncommitted changes, so push or commit work you want to keep first. `claude rm` keeps a worktree that has uncommitted changes and prints its path. A worktree you created yourself is left in place either way. A subagent the session spawns inherits the session's worktree unless its frontmatter sets `isolation: worktree`.

## Model, Effort, and Permissions

A background session reads its settings from the directory it runs in. The model shown in the agent view header is the dispatch default, taken from your `model` setting. Override defaults for everything dispatched from a view by passing flags when you open it:

```bash
claude agents --permission-mode plan --model opus --effort high
```

Each session can run a different model: pass `--model` with `claude --bg`, or attach and press `s` on a model in the `/model` picker to switch that session only. The permission mode depends on how the session started -- backgrounding with `/bg` or `←` keeps the current mode, while dispatching from the input or `claude --bg` uses the directory's `defaultMode`. The permission mode, model, and effort persist when the supervisor restarts the process.

`bypassPermissions` and `auto` are refused until you have accepted that mode by running `claude` with it once interactively, since those modes let an unwatched session act without approval. Flags were added across releases:

| Flag or setting                                                              | Minimum version |
| ---------------------------------------------------------------------------- | --------------- |
| `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions` | v2.1.142        |
| `--allow-dangerously-skip-permissions`                                       | v2.1.143        |
| `--agent`, and honoring the `agent` setting for dispatched sessions          | v2.1.157        |
| `--settings`, `--add-dir`, `--plugin-dir`, `--mcp-config`                    | v2.1.142        |

Repeat `--add-dir`, `--plugin-dir`, or `--mcp-config` once per value; the space-separated form is not supported with `claude agents`.

## How Sessions Are Hosted

A per-user supervisor process, separate from your terminal and agent view, hosts background sessions. It starts automatically the first time you background a session or open agent view, and authenticates with the same credentials as your interactive sessions. Each session is its own Claude Code process.

Lifecycle:

- A session that is working, waiting on input, has a terminal attached, or is running a background command, subagent, dynamic workflow, or monitor keeps its process alive.
- Once a session finishes and sits unattached for about an hour, the supervisor stops its process to free resources. The transcript and state stay on disk, and the next attach, peek, or reply starts a fresh process from where it left off. Pin a session with `Ctrl+T` to keep it responsive.
- An empty row left from pressing `←` and never given a prompt is removed after about five minutes.
- Under memory pressure, the supervisor stops idle non-pinned sessions first.
- When the auto-updater replaces the binary on disk, the supervisor restarts into the new version; detached sessions keep running and the new supervisor reconnects.

State lives under your config directory (or `CLAUDE_CONFIG_DIR` if set):

| Path                             | Contents                                                  |
| -------------------------------- | --------------------------------------------------------- |
| `~/.claude/daemon.log`           | Supervisor log                                            |
| `~/.claude/daemon/roster.json`   | Running sessions, used to reconnect after a restart       |
| `~/.claude/jobs/<id>/state.json` | Per-session state shown in agent view                     |
| `~/.claude/jobs/<id>/tmp/`       | Per-session scratch directory (writes here do not prompt) |

Each session has `CLAUDE_JOB_DIR` set to its `~/.claude/jobs/<id>` directory, so shell commands can write temp files to `$CLAUDE_JOB_DIR/tmp` without colliding with parallel sessions. Run `claude daemon status` (or `/doctor`) to check the supervisor without reading these files.

## Turning Agent View Off

Set the `disableAgentView` setting to `true`, or set the `CLAUDE_CODE_DISABLE_AGENT_VIEW` environment variable. Administrators can enforce this through managed settings.

If `claude agents` prints a count followed by your subagents and exits instead of opening the view, agent view is unavailable in that environment (older versions did not open it on Bedrock, Vertex AI, or Foundry). Run `claude update`.

## Limitations

| Limitation         | Details                                                                                                      |
| ------------------ | ------------------------------------------------------------------------------------------------------------ |
| Research preview   | Requires v2.1.139+; the interface and shortcuts may change                                                   |
| Rate limits apply  | Each session consumes subscription usage independently; ten parallel agents burn quota ~10x as fast          |
| Sessions are local | They run on your machine, survive sleep, but stop on shutdown (they show as failed; attaching restarts them) |
| Worktree deletion  | Deleting a session in agent view removes a Claude-created worktree and its uncommitted changes               |

## Best Practices

1. **Dispatch independent tasks.** Agent view shines when sessions do not share files: a bug fix in one module, a PR review, a flaky-test investigation. Worktree isolation handles parallel writes, but tasks that edit the same files still conflict at merge time.

2. **Watch the PR column.** For most dispatched work, the result is a pull request. Let the `PR #N` color tell you when to look: green means checks passed and nothing is blocking.

3. **Peek before attaching.** `Space` shows the latest output or the pending question. Reply from the panel and move on; reserve attaching for when you want the full conversation.

4. **Pin long-lived sessions.** A session you will return to repeatedly stays responsive when pinned with `Ctrl+T`, instead of being stopped after an idle hour.

5. **Pre-accept the permission mode you need.** `auto` and `bypassPermissions` require one interactive acceptance before a background session can use them. Accept once, then dispatch.

6. **Keep parallelism modest.** Two to four parallel sessions is manageable for most work. Beyond that, quota burn and the effort of tracking results tend to outweigh the time saved.

7. **Commit or push before deleting.** Deleting a session in agent view removes its worktree and any uncommitted changes. Use `claude rm` if you want the worktree preserved.

## Anti-Patterns

1. **Parallel sessions editing the same files outside a worktree.** With `worktree.bgIsolation: "none"` or in a non-git directory, concurrent sessions write to the same working copy and overwrite each other. Keep isolation on, or partition the files.

2. **Dispatching ten agents without watching quota.** Background sessions consume usage the same as interactive ones. Ten in parallel exhaust rate limits roughly ten times as fast.

3. **Deleting a session before saving its work.** `Ctrl+X` twice discards the session's worktree, including uncommitted changes. Merge, push, or `claude rm` first.

4. **Treating background sessions as durable across reboots.** They survive sleep but stop on shutdown. Don't rely on one to finish overnight through a restart.

5. **Backgrounding a session mid-task expecting subagents to follow.** Running subagents, monitors, and background commands do not transfer when you `/bg`. Let them finish, or restart them in the backgrounded session.

## References

- [Manage Multiple Agents with Agent View (Claude Code Docs)](https://code.claude.com/docs/en/agent-view) -- agent view, dispatching, the supervisor, and session management
- [Agent View in Claude Code](https://claude.com/blog/agent-view-in-claude-code) -- announcement and motivation
- [Run Agents in Parallel (Claude Code Docs)](https://code.claude.com/docs/en/agents) -- compares agent view with subagents, agent teams, and worktrees
- [Git Worktrees (Claude Code Docs)](https://code.claude.com/docs/en/worktrees) -- worktree isolation and cleanup
- [Agent Teams Article]({{< relref "/extending/agent-teams" >}}) -- the mesh-coordination model for multi-agent work
- [Large Codebase Strategies Article]({{< relref "large-codebase-strategies" >}}) -- parallel work with worktrees on big repositories
