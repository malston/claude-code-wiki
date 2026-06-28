---
title: "Remote Control: Driving Local Sessions from claude.ai and Mobile"
linkTitle: "Remote Control"
weight: 14
---

# Remote Control: Driving Local Sessions from claude.ai and Mobile

## Executive Summary

Remote Control connects [claude.ai/code](https://claude.ai/code) or the Claude mobile app to a Claude Code session running on your own machine. You start a task at your desk and pick it up from your phone or another browser, while Claude keeps executing locally against your filesystem, MCP servers, and project configuration. The session never moves to the cloud -- the web and mobile views are a window into the local process.

Remote Control requires Claude Code v2.1.51 or later and a claude.ai subscription (Pro, Max, Team, or Enterprise). It is a research preview, and on Team and Enterprise it is off until an Owner enables it.

| Feature                  | What it does                                               | Entry point                                |
| ------------------------ | ---------------------------------------------------------- | ------------------------------------------ |
| **Remote Control**       | Steer a running local session from claude.ai or mobile     | `claude remote-control`, `/remote-control` |
| **Scheduled routines**   | Run a saved prompt on a cron schedule in Anthropic's cloud | `/schedule`                                |
| **claude.ai connectors** | Use MCP servers you configured in claude.ai                | Automatic when signed in to claude.ai      |

All three depend on a claude.ai login. They are disabled whenever `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, or `apiKeyHelper` is set, or a third-party provider such as Bedrock, Vertex, or Foundry is active, even if you have also logged in to claude.ai.

## Table of Contents

- [Remote Control: Driving Local Sessions from claude.ai and Mobile](#remote-control-driving-local-sessions-from-claudeai-and-mobile)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [How Remote Control Works](#how-remote-control-works)
  - [Requirements](#requirements)
  - [Starting a Session](#starting-a-session)
    - [Server Mode](#server-mode)
    - [Interactive Session](#interactive-session)
    - [From an Existing Session](#from-an-existing-session)
  - [The Connection Indicator](#the-connection-indicator)
  - [Connecting from Another Device](#connecting-from-another-device)
  - [Enabling Remote Control for Every Session](#enabling-remote-control-for-every-session)
  - [Mobile Push Notifications](#mobile-push-notifications)
  - [What Works Remotely](#what-works-remotely)
  - [Trusted Devices](#trusted-devices)
  - [Scheduled Routines with /schedule](#scheduled-routines-with-schedule)
  - [claude.ai Connectors](#claudeai-connectors)
  - [Connection and Security](#connection-and-security)
  - [Limitations](#limitations)
  - [Best Practices](#best-practices)
  - [References](#references)

## How Remote Control Works

When you start a Remote Control session, Claude Code keeps running on your machine and makes outbound HTTPS requests only -- it never opens an inbound port. It registers with the Anthropic API and polls for work. When you connect from another device, the server routes messages between the web or mobile client and your local session over a streaming connection.

Because the session runs locally, your full environment stays available remotely: the filesystem, [MCP servers]({{< relref "/extending/integration-patterns" >}}), tools, and project configuration, and typing `@` autocompletes file paths from your local project. The conversation stays in sync across every connected device, so you can send messages from the terminal, a browser, and your phone interchangeably. If your laptop sleeps or the network drops, the session reconnects when the machine comes back online.

This is different from [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web), which runs in Anthropic-managed cloud infrastructure. Use Remote Control to keep steering local work from another device; use Claude Code on the web to start a task with no local setup or to run many tasks in parallel.

## Requirements

- **Subscription**: Pro, Max, Team, or Enterprise. API keys are not supported. On Team and Enterprise, an Owner must first turn on the Remote Control toggle in [Claude Code admin settings](https://claude.ai/admin-settings/claude-code).
- **Authentication**: run `claude` and sign in with `/login` through claude.ai. A long-lived token from `claude setup-token` or `CLAUDE_CODE_OAUTH_TOKEN` is inference-only and cannot establish a session.
- **Workspace trust**: run `claude` in your project directory at least once to accept the trust dialog.

## Starting a Session

The CLI offers three ways to start a session. The VS Code extension uses the `/remote-control` command.

### Server Mode

Run a dedicated server that waits for remote connections and can host several sessions at once:

```bash
claude remote-control
```

The process stays in your terminal, shows connection status and tool activity, and displays a session URL. Press spacebar to toggle a QR code for quick access from your phone. Useful flags:

| Flag                         | Effect                                                                                                                                                                                |
| ---------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--name "My Project"`        | Set a session title visible in the list at claude.ai/code                                                                                                                             |
| `--spawn <mode>`             | `same-dir` (default), `worktree` (each session gets its own [git worktree]({{< relref "/guides/workflow-patterns" >}}#git-worktrees-for-isolation)), or `session` (serve exactly one) |
| `--capacity <N>`             | Maximum concurrent sessions (default 32); not valid with `--spawn=session`                                                                                                            |
| `--sandbox` / `--no-sandbox` | Enable or disable [sandboxing]({{< relref "/guides/permissions-enterprise" >}}#sandboxing) (off by default)                                                                           |
| `--verbose`                  | Show detailed connection and session logs                                                                                                                                             |

### Interactive Session

Start a normal interactive session that is also reachable remotely. You can type locally while the session is available on other devices:

```bash
claude --remote-control          # or the --rc short form
claude --remote-control "My Project"
```

### From an Existing Session

Promote the conversation you are already in, carrying its history over:

```text
/remote-control                  # or /rc
/remote-control My Project
```

The `--verbose`, `--sandbox`, and `--no-sandbox` flags are not available with this command.

## The Connection Indicator

While a connection is up, a `/rc active` indicator sits in the footer below the input box. It is hidden when the terminal is too narrow to fit it. The indicator text is a link to the session on claude.ai: select it with the down arrow and press Enter, or run `/remote-control` again, to open a status panel with the session URL and a QR code. If the connection fails, a notification shows the reason and the indicator disappears; run `/remote-control` to retry.

## Connecting from Another Device

Once a session is active, connect another device in any of these ways:

- **Open the session URL** in any browser to land directly on the session at claude.ai/code.
- **Scan the QR code** shown next to the URL to open it in the Claude app. In server mode, press spacebar to toggle the QR display.
- **Open [claude.ai/code](https://claude.ai/code) or the Claude app** and pick the session from the list by name. In the mobile app, tap **Code** to reach the list; Remote Control sessions show a computer icon with a green dot when online.

If you don't have the Claude app yet, run `/mobile` inside Claude Code to display a download QR code.

## Enabling Remote Control for Every Session

By default Remote Control activates only when you run `claude remote-control`, `claude --remote-control`, or `/remote-control`. To turn it on automatically for every interactive session, run `/config` and set **Enable Remote Control for all sessions** to `true`. Each interactive process then registers one remote session; to run several concurrent sessions from a single process, use server mode instead.

## Mobile Push Notifications

When Remote Control is active, Claude can push notifications to your phone (requires Claude Code v2.1.110 or later). Claude decides when to send one, typically when a long task finishes or it needs a decision, and you can ask for one in a prompt such as `notify me when the tests finish`.

To set them up: install the Claude app, sign in with the same account you use in the terminal, accept the OS notification prompt, then run `/config` and enable **Push when Claude decides**, **Push when actions required**, or both. Claude skips pushes while you are focused on the connected terminal.

## What Works Remotely

Commands that open an interactive picker in the terminal, such as `/plugin` or `/resume`, run only from the local CLI. These work from mobile and web:

- Text-output commands: `/compact`, `/clear`, `/context`, `/usage`, `/usage-credits`, `/recap`, `/reload-plugins`, `/exit`
- `/mcp` (from v2.1.166): returns a text summary instead of a picker, and accepts `reconnect`, `enable`, and `disable`
- `/config` (from v2.1.181): pass `key=value` to set a setting, or run it with no argument to list settable keys

[`/goal`]({{< relref "/guides/workflow-patterns" >}}#goal-driven-sessions-with-goal) also runs through Remote Control, so you can set a completion condition and let the session work while you step away.

## Trusted Devices

Trusted Devices (beta, Team and Enterprise) is an organization-wide setting that adds two requirements on top of a signed-in account before a member can view or steer Remote Control sessions: an enrolled device and a sign-in no more than 18 hours old. When an admin enables it from the [admin console](https://claude.ai/admin-settings/claude-code), each browser, phone, or desktop app enrolls its own credential during sign-in, and a sign-in older than 18 hours prompts for Face ID, Touch ID, Windows Hello, or a passkey before the next interaction. Biometric checks run on the device through the OS or browser; Anthropic stores only the device's public key and basic metadata. The setting applies to Remote Control only -- regular Claude chat, the terminal, and API usage are unaffected. Members manage their enrolled devices at [claude.ai/settings/account](https://claude.ai/settings/account#trusted-devices).

## Scheduled Routines with /schedule

A routine is a saved Claude Code configuration -- a prompt, one or more repositories, and a set of connectors -- that runs on Anthropic-managed cloud infrastructure, so it keeps working when your laptop is closed. Routines are available on Pro, Max, Team, and Enterprise plans with [Claude Code on the web](https://code.claude.com/docs/en/claude-code-on-the-web) enabled, and run autonomously: there is no permission-mode picker and no approval prompts during a run.

Create and manage routines from the CLI with `/schedule`:

```text
/schedule daily PR review at 9am
/schedule tomorrow at 9am, summarize yesterday's merged PRs
/schedule list                   # show all routines
/schedule update                 # change one, including a custom cron expression
/schedule run                    # trigger one immediately
```

`/schedule` in the CLI creates scheduled routines only; the minimum interval is one hour. To set a custom interval, pick the closest preset, then run `/schedule update` to set a cron expression. Adding an API or GitHub trigger is done on the web at [claude.ai/code/routines](https://claude.ai/code/routines). Because a routine clones the repository in the cloud, the CLI checks that your account has GitHub connected and prompts you to run `/web-setup` if it doesn't.

`/schedule` requires a claude.ai subscription login. The command is hidden when you are authenticated with an API key or a cloud provider, when telemetry-disabling variables such as `DISABLE_TELEMETRY` block feature-flag fetching, or when you are inside a Claude Code on the web session.

For scheduling that runs within an open CLI session instead of the cloud, see [`/loop` and in-session scheduling]({{< relref "/guides/workflow-patterns" >}}#recurring-tasks-with-loop).

## claude.ai Connectors

If you signed in to Claude Code with a claude.ai account, the MCP servers you added in claude.ai are available automatically. Add them at [claude.ai/customize/connectors](https://claude.ai/customize/connectors) (on Team and Enterprise, only admins can); they then appear in `/mcp` marked as coming from claude.ai. Connectors you have never signed in to are collapsed behind a **Show unused connectors** row so an organization-provisioned list doesn't fill the panel.

Some Anthropic-hosted connectors, such as Microsoft 365, Gmail, and Google Calendar, don't support local OAuth from Claude Code because the upstream provider only accepts the redirect URL that claude.ai registered. Authenticating one of these in `/mcp` directs you to connect it at **Settings -> Connectors** on claude.ai, after which it appears in Claude Code automatically.

Connectors load only when your active authentication method is your claude.ai subscription. They are skipped when `ANTHROPIC_API_KEY`, `ANTHROPIC_AUTH_TOKEN`, `apiKeyHelper`, or a third-party provider is active. To turn them off entirely, set `disableClaudeAiConnectors` to `true` in any settings scope:

```json
{
  "disableClaudeAiConnectors": true
}
```

## Connection and Security

All traffic travels through the Anthropic API over TLS, the same transport as any Claude Code session. The local process makes outbound HTTPS requests only and never opens an inbound port. The connection uses multiple short-lived credentials, each scoped to a single purpose and expiring independently. Remote Control needs reachability to the Anthropic API on port 443; a firewall or proxy that blocks the outbound request is the usual cause of a failed connection.

## Limitations

- **One remote session per interactive process.** Outside server mode, each Claude Code instance supports one remote session at a time.
- **The local process must keep running.** Closing the terminal, quitting VS Code, or stopping the `claude` process ends the session.
- **Extended network outage ends the session.** If the machine is awake but offline for more than roughly 10 minutes, the session times out and the process exits. Run `claude remote-control` again to start a new one.
- **Ultraplan disconnects Remote Control.** Both features occupy the claude.ai/code interface, and only one can be connected at a time.
- **Routines are session-independent but cloud-only.** A routine created with `/schedule` runs in the cloud against a fresh clone, not your local working tree.

## Best Practices

1. **Sign in with claude.ai, not an API key.** Remote Control, `/schedule`, and claude.ai connectors all require a claude.ai login. If a feature is missing, run `/status` to confirm the active authentication method and unset `ANTHROPIC_API_KEY` or remove `apiKeyHelper` if one is set.

2. **Use server mode for multiple sessions.** A single `claude remote-control` process hosts several sessions; pick `--spawn=worktree` so on-demand sessions don't edit the same files.

3. **Name your sessions.** Pass `--name` or run `/rename` so sessions are easy to find in the list at claude.ai/code instead of an auto-generated `myhost-graceful-unicorn`.

4. **Pair Remote Control with `/goal`.** Set a completion condition before you step away, then monitor and steer from your phone as the session works toward it.

5. **Scope routines tightly.** A routine runs autonomously with no approval prompts, so limit its repositories, connectors, and network access to what the task actually needs.

## References

- [Remote Control (Claude Code Docs)](https://code.claude.com/docs/en/remote-control) -- setup, connecting, Trusted Devices, and the full troubleshooting list
- [Scheduled Tasks (Claude Code Docs)](https://code.claude.com/docs/en/scheduled-tasks) -- `/loop`, the cron tools, and how `/schedule` compares to in-session scheduling
- [Routines (Claude Code Docs)](https://code.claude.com/docs/en/routines) -- cloud routines, API and GitHub triggers, and connector configuration
- [Use MCP servers from claude.ai (Claude Code Docs)](https://code.claude.com/docs/en/mcp#use-mcp-servers-from-claude-ai) -- claude.ai connectors and `disableClaudeAiConnectors`
- [Background Agents Article]({{< relref "/guides/background-agents" >}}) -- running many local sessions at once from agent view
- [Workflow Patterns Article]({{< relref "/guides/workflow-patterns" >}}) -- `/loop`, `/goal`, and session management
