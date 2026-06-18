---
title: "Managed Settings and Security Policy"
linkTitle: "Managed Settings"
weight: 1
---

# Managed Settings and Security Policy

## Overview

The `managed-settings.json` file is the enterprise-level configuration that sits at the top of Claude Code's settings hierarchy and **cannot be overridden by any developer or project-level setting.** It's deployed to every developer machine via Mobile Device Management (MDM) or configuration management tooling.

## Baseline Enterprise Configuration

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://llm-gateway.internal.corp.com/bedrock",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "cleanupPeriodDays": 14,
  "requiredMinimumVersion": "2.1.166",
  "permissions": {
    "disableBypassPermissionsMode": "disable",
    "deny": [
      "Read(**/.env)",
      "Read(**/.env.*)",
      "Read(**/secrets/**)",
      "Read(**/.ssh/**)",
      "Read(**/credentials*)",
      "Bash(sudo:*)",
      "Bash(su:*)",
      "Bash(curl:*)",
      "Bash(wget:*)",
      "Bash(ssh:*)",
      "Bash(rm -rf:*)"
    ]
  },
  "allowManagedPermissionRulesOnly": false,
  "allowManagedHooksOnly": false,
  "strictKnownMarketplaces": []
}
```

## Key Design Decisions

### Bedrock Routing (env section)

- `CLAUDE_CODE_USE_BEDROCK`: Routes all requests through Bedrock instead of api.anthropic.com
- `ANTHROPIC_BEDROCK_BASE_URL`: Points to the internal LLM gateway, not directly to Bedrock
- `CLAUDE_CODE_SKIP_BEDROCK_AUTH`: The gateway holds AWS credentials, developers don't need them

### Telemetry Lockdown

`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC` bundles four flags into one:

- `DISABLE_AUTOUPDATER` -- prevents auto-update checks
- `DISABLE_BUG_COMMAND` -- disables bug reporting
- `DISABLE_ERROR_REPORTING` -- prevents error telemetry
- `DISABLE_TELEMETRY` -- disables usage telemetry

Combined with Bedrock routing, the **only** outbound traffic from Claude Code is to the internal LLM gateway.

### Transcript Cleanup

`cleanupPeriodDays: 14` purges Claude Code session transcripts (which may contain code snippets) from developer machines after two weeks. Tune based on your data retention policy.

### Permission Bypass Disabled

`disableBypassPermissionsMode: "disable"` prevents anyone from using `--dangerously-skip-permissions`. Non-negotiable for regulated environments. Developers get permission prompts -- that's the point.

### Deny Rules

Blocks access to secrets, credentials, SSH keys. Prevents Claude from making arbitrary network calls or running destructive commands. Projects can add their own deny rules on top but can't override these.

### Permission Rule Override

`allowManagedPermissionRulesOnly: false` allows project teams to define their own allow/ask/deny rules on top of the enterprise baseline. Set to `true` for highly regulated environments (defense, healthcare with PHI) where no project-level overrides should be possible.

### Hook and Plugin Control

- `allowManagedHooksOnly: false` -- allows project-level hooks initially. Set to `true` if hook execution is a security concern.
- `strictKnownMarketplaces: []` -- empty array blocks all plugin marketplaces. To allow vetted plugins, add source objects (e.g., `{"source": "github", "repo": "acme-corp/approved-plugins"}`).

### Version Pinning

`requiredMinimumVersion` refuses to start Claude Code if the installed version is older than the value, directing the user to the organization's approved update path. Pair it with `requiredMaximumVersion` to pin a tested ceiling -- background auto-updates and `claude update` skip versions above it, so an in-range install stays in range. In both cases `claude update`, `claude install`, and `claude doctor` keep working outside the range so users can recover. Use these to hold the fleet on a version your team has validated, rather than letting every machine track the latest release. This differs from `minimumVersion`, which blocks downgrades but never blocks startup.

### Additional Managed-Only Controls

| Setting                                   | When to use it                                                                                                                                                                                                  |
| ----------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `parentSettingsBehavior`                  | Set to `"merge"` if you deploy Claude Code through the Agent SDK or an IDE extension and want those host-supplied settings to apply under (and only tighten) the admin tier. Default `"first-wins"` drops them. |
| `pluginSuggestionMarketplaces`            | Allowlist the org marketplaces whose plugins may surface as contextual install suggestions. Names take effect only when the marketplace's source is also declared in managed settings.                          |
| `allowAllClaudeAiMcps`                    | Load claude.ai cloud MCP connectors alongside a deployed `managed-mcp.json` (which otherwise suppresses them).                                                                                                  |
| `sandbox.bwrapPath` / `sandbox.socatPath` | On Linux/WSL, point the sandbox at custom `bubblewrap` and `socat` binary locations when they are not on the default search path.                                                                               |

## Distribution

| Platform | Path                                                            |
| -------- | --------------------------------------------------------------- |
| macOS    | `/Library/Application Support/ClaudeCode/managed-settings.json` |
| Linux    | `/etc/claude-code/managed-settings.json`                        |
| Windows  | `C:\Program Files\ClaudeCode\managed-settings.json`             |

Deploy via:

- **macOS:** Jamf Pro, Kandji, or Microsoft Intune configuration profiles
- **Linux:** Ansible, Chef, Puppet, or package postinstall script
- **Windows:** Group Policy or Intune

This should feel identical to how you'd push any other enterprise configuration file.

## Server-Managed Settings (Anthropic Direct)

Anthropic also offers server-managed settings via the Claude.ai admin console (public beta) for Teams and Enterprise plan customers using Anthropic's API directly. No MDM infrastructure required -- administrators configure settings in a web UI, and Claude Code clients fetch them at startup and poll hourly.

This binder uses endpoint-managed delivery (the `managed-settings.json` file described above) because server-managed settings are **not available** when routing through Bedrock, Vertex, Foundry, or any custom API endpoint. The Bedrock scenario means Anthropic's admin console is not the control plane -- AWS is.

For clients evaluating Anthropic direct deployment (no cloud provider intermediary), server-managed settings are a simpler path to initial controls before MDM is ready. They support the same settings as `managed-settings.json`, including deny rules, hooks, and `disableBypassPermissionsMode`. See the [Claude Code docs on server-managed settings](https://code.claude.com/docs/en/server-managed-settings) for configuration details.

## Validation

After deployment, developers can verify managed settings are active:

```bash
# In Claude Code session
/settings  # Shows effective settings with managed overrides marked
```

Managed settings that restrict an action will show a notification to the developer explaining the policy.

_Last validated against Claude Code docs: 2026-03-20_
