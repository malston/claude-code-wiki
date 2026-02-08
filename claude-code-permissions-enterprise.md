# Permissions & Enterprise Deployment: Securing and Scaling Claude Code

## Executive Summary

Claude Code's permission system controls what actions Claude can take -- from file reads to shell commands to network access. Permissions cascade across five settings scopes (managed, CLI, local, project, user), with deny rules always winning. Enterprise deployments add managed policy files, sandbox enforcement, provider flexibility (Bedrock, Vertex AI, Foundry), and organization-wide controls. This article covers the full permission lifecycle from individual developer configuration to team-wide lockdown.

| Scope       | Location                       | Who Controls | Can Override? |
| ----------- | ------------------------------ | ------------ | ------------- |
| **Managed** | System-level path (admin-only) | IT/Admin     | No (highest)  |
| **CLI**     | Command-line arguments         | Developer    | Only managed  |
| **Local**   | `.claude/settings.local.json`  | Developer    | Managed + CLI |
| **Project** | `.claude/settings.json`        | Team         | Above scopes  |
| **User**    | `~/.claude/settings.json`      | Developer    | All above     |

---

## Table of Contents

- [Permission Modes](#permission-modes)
- [Permission Rules](#permission-rules)
  - [Allow, Deny, Ask](#allow-deny-ask)
  - [Rule Evaluation Order](#rule-evaluation-order)
  - [Tool-Specific Syntax](#tool-specific-syntax)
  - [Permission Prompts and UX](#permission-prompts-and-ux)
- [Settings Cascade](#settings-cascade)
  - [Scope Precedence](#scope-precedence)
  - [Settings File Locations](#settings-file-locations)
- [Sandboxing](#sandboxing)
  - [OS-Level Enforcement](#os-level-enforcement)
  - [Filesystem Isolation](#filesystem-isolation)
  - [Network Isolation](#network-isolation)
  - [Sandbox Configuration](#sandbox-configuration)
  - [Security Limitations](#security-limitations)
- [Enterprise Managed Settings](#enterprise-managed-settings)
  - [Managed Settings File](#managed-settings-file)
  - [Managed-Only Controls](#managed-only-controls)
  - [Example Enterprise Configuration](#example-enterprise-configuration)
  - [Company Announcements](#company-announcements)
- [API Provider Configuration](#api-provider-configuration)
  - [Anthropic (Default)](#anthropic-default)
  - [AWS Bedrock](#aws-bedrock)
  - [Google Vertex AI](#google-vertex-ai)
  - [Microsoft Foundry](#microsoft-foundry)
  - [LLM Gateway Support](#llm-gateway-support)
  - [Authentication Helpers](#authentication-helpers)
- [CI/CD Permission Strategies](#cicd-permission-strategies)
  - [Headless Mode Permissions](#headless-mode-permissions)
  - [GitHub Actions](#github-actions)
- [Security Hardening](#security-hardening)
  - [Minimal-Interruption Developer Setup](#minimal-interruption-developer-setup)
  - [Strict Lockdown Setup](#strict-lockdown-setup)
  - [Hooks for Security Enforcement](#hooks-for-security-enforcement)
- [Debugging Permissions](#debugging-permissions)
- [Best Practices](#best-practices)
- [Anti-Patterns](#anti-patterns)
- [References](#references)

---

## Permission Modes

Permission modes set the overall behavior for how Claude handles tool approval:

| Mode                | Behavior                                                  |
| ------------------- | --------------------------------------------------------- |
| `default`           | Prompts for permission on first use of each tool          |
| `acceptEdits`       | Auto-accepts file edit/write operations for the session   |
| `plan`              | Read-only: Claude can analyze but not modify or execute   |
| `delegate`          | Coordination-only for agent team leads (no coding tools)  |
| `dontAsk`           | Auto-denies unless pre-approved via rules                 |
| `bypassPermissions` | Skips all permission prompts (isolated environments only) |

Set via settings:

```json
{
  "permissions": {
    "defaultMode": "acceptEdits"
  }
}
```

Or via CLI: `claude --permission-mode acceptEdits`

**`bypassPermissions` warning:** This mode gives Claude unrestricted access to your filesystem, shell, and network. Only use in isolated environments (containers, VMs, CI runners). Enterprise admins can prevent this mode entirely with `disableBypassPermissionsMode`.

---

## Permission Rules

### Allow, Deny, Ask

Permission rules are lists of tool patterns that control whether actions are approved, blocked, or require explicit confirmation:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run lint)",
      "Bash(npm run test *)",
      "Bash(git diff *)",
      "Bash(git status)"
    ],
    "ask": ["Bash(git push *)", "Bash(git commit *)"],
    "deny": ["Bash(curl *)", "Bash(wget *)", "Read(./.env)", "Read(./.env.*)"]
  }
}
```

- **allow**: Auto-approved without prompting
- **ask**: Always prompts the user, even if previously approved
- **deny**: Always blocked, no prompt shown

### Rule Evaluation Order

Rules are evaluated: **deny -> ask -> allow**. First matching rule wins.

```
Tool call: Bash("npm run test")
  1. Check deny rules → no match
  2. Check ask rules → no match
  3. Check allow rules → matches "Bash(npm run test *)" → ALLOW
```

If no rule matches, the permission mode determines behavior:

- `default` / `acceptEdits`: Prompt the user
- `dontAsk`: Auto-deny
- `bypassPermissions`: Auto-allow

### Tool-Specific Syntax

**Bash** -- glob patterns with `*`:

| Pattern               | Matches                        |
| --------------------- | ------------------------------ |
| `Bash(npm run build)` | Exact command                  |
| `Bash(npm run *)`     | Any `npm run` subcommand       |
| `Bash(git * main)`    | Any git command targeting main |
| `Bash(* --version)`   | Any command with `--version`   |

Claude Code is aware of shell operators. `Bash(safe-cmd *)` will not permit `safe-cmd && malicious-cmd`. The matching is semantically aware, not just string-based.

**Read and Edit** -- gitignore-style path patterns:

| Pattern                          | Matches                                    |
| -------------------------------- | ------------------------------------------ |
| `Read(./.env)`                   | The `.env` file in project root            |
| `Read(./.env.*)`                 | All `.env.local`, `.env.production`, etc.  |
| `Read(//Users/alice/secrets/**)` | Absolute path (note double `/`)            |
| `Read(~/Documents/*.pdf)`        | Home-relative path                         |
| `Edit(/src/**/*.ts)`             | All TypeScript files recursively in `src/` |

Single `*` matches within a directory. Double `**` matches recursively.

**WebFetch**:

| Pattern                        | Matches                         |
| ------------------------------ | ------------------------------- |
| `WebFetch(domain:example.com)` | Fetch requests to `example.com` |

**MCP tools**:

| Pattern                              | Matches                         |
| ------------------------------------ | ------------------------------- |
| `mcp__puppeteer`                     | Any tool from puppeteer server  |
| `mcp__puppeteer__puppeteer_navigate` | Specific tool                   |
| `mcp__puppeteer__*`                  | All tools from puppeteer (glob) |

**Task (subagents)**:

| Pattern                 | Matches              |
| ----------------------- | -------------------- |
| `Task(Explore)`         | The Explore subagent |
| `Task(my-custom-agent)` | A custom subagent    |

**Skill**:

| Pattern           | Matches                        |
| ----------------- | ------------------------------ |
| `Skill(commit)`   | The commit skill               |
| `Skill(deploy *)` | Any skill with "deploy" prefix |

### Permission Prompts and UX

| Tool Type             | Example          | Prompt Required? | "Don't ask again" Duration        |
| --------------------- | ---------------- | ---------------- | --------------------------------- |
| **Read-only**         | File reads, Grep | No               | N/A                               |
| **Bash commands**     | Shell execution  | Yes (first time) | Permanent (per project + command) |
| **File modification** | Edit, Write      | Yes (first time) | Until session end                 |

Additional behaviors:

- Command injection detection: suspicious commands always require manual approval, even if allowlisted
- Fail-closed matching: unmatched commands default to requiring approval
- `/permissions` slash command shows all active rules and their source

---

## Settings Cascade

### Scope Precedence

Settings from higher-precedence scopes override lower ones:

| Precedence  | Scope       | Location                      | Controlled By |
| ----------- | ----------- | ----------------------------- | ------------- |
| 1 (highest) | **Managed** | System-level path             | IT Admin      |
| 2           | **CLI**     | Command-line arguments        | Developer     |
| 3           | **Local**   | `.claude/settings.local.json` | Developer     |
| 4           | **Project** | `.claude/settings.json`       | Team (git)    |
| 5 (lowest)  | **User**    | `~/.claude/settings.json`     | Developer     |

If a permission is allowed in user settings but denied in project settings, it's denied. Managed settings override everything.

### Settings File Locations

**User settings:** `~/.claude/settings.json`

**Project settings:** `.claude/settings.json` (committed to git -- shared with team)

**Local settings:** `.claude/settings.local.json` (gitignored -- personal to you)

**Managed settings:**

- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux/WSL: `/etc/claude-code/managed-settings.json`
- Windows: `C:\Program Files\ClaudeCode\managed-settings.json`

All files use the same JSON format.

---

## Sandboxing

### OS-Level Enforcement

Claude Code can sandbox Bash commands at the operating system level:

| OS        | Technology         | Setup              |
| --------- | ------------------ | ------------------ |
| **macOS** | Seatbelt framework | Built-in, no setup |
| **Linux** | bubblewrap + socat | Install required   |

Enable via `/sandbox` command or settings.

### Filesystem Isolation

- **Default writes**: Current working directory and subdirectories only
- **Default reads**: Entire system except explicitly denied directories
- **Configurable**: Additional allowed/denied paths in sandbox config

### Network Isolation

- Domain-based restrictions via a proxy server
- `allowedDomains` controls which domains Bash commands can reach
- Unix socket access via `allowUnixSockets`
- Local port binding via `allowLocalBinding`

### Sandbox Configuration

```json
{
  "sandbox": {
    "enabled": true,
    "autoAllowBashIfSandboxed": true,
    "excludedCommands": ["git", "docker"],
    "allowUnsandboxedCommands": false,
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org", "registry.npmjs.org"],
      "allowUnixSockets": [],
      "allowLocalBinding": true,
      "httpProxyPort": 8080,
      "socksProxyPort": 8081
    }
  }
}
```

| Field                      | Description                                    |
| -------------------------- | ---------------------------------------------- |
| `enabled`                  | Turn sandboxing on/off                         |
| `autoAllowBashIfSandboxed` | Auto-approve Bash when sandboxed               |
| `excludedCommands`         | Commands that bypass the sandbox (e.g., `git`) |
| `allowUnsandboxedCommands` | Whether non-sandboxed commands can run at all  |
| `allowedDomains`           | Domain allowlist for network access            |
| `allowUnixSockets`         | Specific Unix sockets that can be accessed     |
| `allowLocalBinding`        | Whether Bash can bind local ports              |

### Security Limitations

- Network filtering is domain-based, not traffic-inspecting -- data exfiltration to allowed domains is possible
- Domain fronting can bypass domain restrictions
- `allowUnixSockets` for the Docker socket effectively grants host-level access
- Overly broad filesystem write permissions can enable privilege escalation
- `enableWeakerNestedSandbox` considerably weakens security (Docker use only)

---

## Enterprise Managed Settings

### Managed Settings File

Managed settings require administrator privileges to create or modify. They use the same JSON format as regular settings but cannot be overridden by any other scope.

**Locations:**

- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux/WSL: `/etc/claude-code/managed-settings.json`
- Windows: `C:\Program Files\ClaudeCode\managed-settings.json`

### Managed-Only Controls

These settings are only available in managed settings files:

| Setting                           | Description                                                                |
| --------------------------------- | -------------------------------------------------------------------------- |
| `disableBypassPermissionsMode`    | Set to `"disable"` to prevent `--dangerously-skip-permissions`             |
| `allowManagedPermissionRulesOnly` | Blocks user/project permission rules; only managed rules apply             |
| `allowManagedHooksOnly`           | Blocks user, project, and plugin hooks; only managed and SDK hooks allowed |
| `strictKnownMarketplaces`         | Controls which plugin marketplaces users can add                           |
| `allowedMcpServers`               | Allowlist of MCP servers users can configure                               |
| `deniedMcpServers`                | Denylist of MCP servers (takes precedence over allow)                      |
| `forceLoginMethod`                | Restrict auth to `claudeai` or `console` only                              |
| `forceLoginOrgUUID`               | Auto-select organization during login                                      |

### Example Enterprise Configuration

```json
{
  "permissions": {
    "allow": [
      "Bash(git diff *)",
      "Bash(git status)",
      "Bash(npm run *)",
      "Bash(go test *)"
    ],
    "deny": [
      "Read(./.env)",
      "Read(./.env.*)",
      "Read(~/.*)",
      "Bash(curl *)",
      "Bash(wget *)",
      "WebFetch"
    ],
    "defaultMode": "default"
  },
  "allowManagedHooksOnly": true,
  "allowManagedPermissionRulesOnly": true,
  "disableBypassPermissionsMode": "disable",
  "allowedMcpServers": [{ "serverName": "github" }, { "serverName": "gitlab" }],
  "deniedMcpServers": [{ "serverName": "filesystem" }],
  "sandbox": {
    "enabled": true,
    "excludedCommands": ["git"],
    "network": {
      "allowedDomains": ["github.com", "*.npmjs.org"]
    }
  },
  "companyAnnouncements": [
    "Review code guidelines at docs.acme.com before committing"
  ]
}
```

### Company Announcements

Organization-wide messaging displayed to all users:

```json
{
  "companyAnnouncements": [
    "Welcome to ACME Corp! Review our code guidelines at docs.acme.com",
    "Reminder: All PRs require code review before merge"
  ]
}
```

---

## API Provider Configuration

### Anthropic (Default)

Default provider. Authenticate via `claude login` or set `ANTHROPIC_API_KEY`.

### AWS Bedrock

```bash
export CLAUDE_CODE_USE_BEDROCK=1
export AWS_REGION=us-east-1
```

**Authentication options:**

- AWS CLI: `aws configure`
- Environment variables: `AWS_ACCESS_KEY_ID`, `AWS_SECRET_ACCESS_KEY`, `AWS_SESSION_TOKEN`
- SSO profile: `AWS_PROFILE`
- Bedrock API keys: `AWS_BEARER_TOKEN_BEDROCK`

**Auto-refresh credentials:**

```json
{
  "awsAuthRefresh": "aws sso login --profile myprofile",
  "env": { "AWS_PROFILE": "myprofile" }
}
```

**Default models:**

- Primary: `global.anthropic.claude-sonnet-4-5-20250929-v1:0`
- Fast/small: `us.anthropic.claude-haiku-4-5-20251001-v1:0`

**Override small model region:** `ANTHROPIC_SMALL_FAST_MODEL_AWS_REGION=us-west-2`

**IAM permissions:** `bedrock:InvokeModel`, `bedrock:InvokeModelWithResponseStream`, `bedrock:ListInferenceProfiles`

**Guardrails integration:**

```json
{
  "env": {
    "ANTHROPIC_CUSTOM_HEADERS": "X-Amzn-Bedrock-GuardrailIdentifier: your-guardrail-id\nX-Amzn-Bedrock-GuardrailVersion: 1"
  }
}
```

### Google Vertex AI

```bash
export CLAUDE_CODE_USE_VERTEX=1
export CLOUD_ML_REGION=global
export ANTHROPIC_VERTEX_PROJECT_ID=YOUR-PROJECT-ID
```

**Authentication:** `gcloud auth application-default login`

**Default models:**

- Primary: `claude-sonnet-4-5@20250929`
- Fast/small: `claude-haiku-4-5@20251001`

**Per-model region overrides:**

```bash
export VERTEX_REGION_CLAUDE_3_5_HAIKU=us-east5
export VERTEX_REGION_CLAUDE_4_0_OPUS=europe-west1
```

**IAM:** `roles/aiplatform.user` or custom with `aiplatform.endpoints.predict`

### Microsoft Foundry

```bash
export CLAUDE_CODE_USE_FOUNDRY=1
export ANTHROPIC_FOUNDRY_RESOURCE={resource}
export ANTHROPIC_DEFAULT_SONNET_MODEL='claude-sonnet-4-5'
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-haiku-4-5'
export ANTHROPIC_DEFAULT_OPUS_MODEL='claude-opus-4-6'
```

**Authentication:** API key (`ANTHROPIC_FOUNDRY_API_KEY`) or Microsoft Entra ID.

**RBAC:** `Azure AI User` or `Cognitive Services User` roles.

### LLM Gateway Support

For corporate gateways or proxies, override base URLs:

| Variable                     | Provider  |
| ---------------------------- | --------- |
| `ANTHROPIC_BASE_URL`         | Anthropic |
| `ANTHROPIC_BEDROCK_BASE_URL` | Bedrock   |
| `ANTHROPIC_VERTEX_BASE_URL`  | Vertex AI |

Skip provider auth (for gateways that handle authentication):

| Variable                        | Provider  |
| ------------------------------- | --------- |
| `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | Bedrock   |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH`  | Vertex AI |
| `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` | Foundry   |

### Authentication Helpers

For dynamic credential rotation:

```json
{
  "apiKeyHelper": "vault read -field=api_key secret/claude"
}
```

The helper script is called after 5 minutes or on HTTP 401. Customize the interval with `CLAUDE_CODE_API_KEY_HELPER_TTL_MS`.

---

## CI/CD Permission Strategies

### Headless Mode Permissions

In headless mode (`claude -p`), configure permissions through flags:

```bash
# Allowlist specific tools
claude -p "Fix the bug" --allowedTools "Read,Edit,Bash(npm test *)"

# Remove tools entirely from model context
claude -p "Review code" --disallowedTools "Bash,Write"

# Budget cap
claude -p "Refactor module" --max-budget-usd 5.00

# Turn limit
claude -p "Fix this" --max-turns 3
```

**Key notes:**

- `PermissionRequest` hooks do NOT fire in headless mode -- use `PreToolUse` hooks instead
- Trust verification is disabled in headless mode
- `--permission-prompt-tool` specifies an MCP tool to handle permission prompts programmatically

### GitHub Actions

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    allowed_tools: "Bash(npm run *),Read,Edit"
    disallowed_tools: "WebFetch"
    max_budget_usd: "10.00"
    max_turns: "50"
```

---

## Security Hardening

### Minimal-Interruption Developer Setup

For developers who want flow with reasonable guardrails:

```json
{
  "permissions": {
    "allow": [
      "Bash(npm run *)",
      "Bash(bun run *)",
      "Bash(go test *)",
      "Bash(git diff *)",
      "Bash(git status)",
      "Bash(git log *)",
      "Bash(git add *)",
      "Bash(* --version)",
      "Bash(* --help *)"
    ],
    "deny": ["Bash(curl *)", "Bash(wget *)", "Read(./.env)", "Read(./.env.*)"],
    "defaultMode": "acceptEdits"
  }
}
```

### Strict Lockdown Setup

For environments requiring maximum control:

```json
{
  "permissions": {
    "allow": ["Bash(git diff *)", "Bash(git status)"],
    "deny": [
      "Bash(curl *)",
      "Bash(wget *)",
      "Read(./.env)",
      "Read(./.env.*)",
      "WebFetch"
    ],
    "defaultMode": "dontAsk"
  },
  "disableAllHooks": true,
  "sandbox": {
    "enabled": true,
    "network": {
      "allowedDomains": ["github.com"]
    }
  }
}
```

In `dontAsk` mode, only explicitly allowed tools work. Everything else is auto-denied without prompting.

### Hooks for Security Enforcement

Use PreToolUse hooks for runtime permission decisions beyond what static rules can express:

```bash
#!/usr/bin/env bash
# Block commands that might expose secrets
INPUT=$(cat)
COMMAND=$(echo "$INPUT" | jq -r '.tool_input.command // empty')

if echo "$COMMAND" | grep -qiE 'password=|token=|secret=|api_key='; then
  echo "Blocked: potential credential exposure" >&2
  exit 2
fi

exit 0
```

See the [Custom Hooks Cookbook](claude-code-hooks-cookbook.md) for complete security hook recipes.

---

## Debugging Permissions

- **`/permissions`** -- lists all active rules and which settings file they come from
- **`/status`** -- shows authentication, proxy, URL settings, and provider configuration
- **`claude --debug`** -- full permission evaluation output
- **`ANTHROPIC_LOG=debug`** -- logs API requests for provider debugging
- **`Ctrl+O`** -- toggles verbose mode to see hook output

---

## Best Practices

1. **Use project settings for team rules.** Put `.claude/settings.json` in version control. This ensures everyone on the team has the same permission rules and deny lists.

2. **Deny before you allow.** Start with deny rules for dangerous patterns (curl, wget, .env access), then selectively allow safe operations. Deny rules always win.

3. **Use `acceptEdits` for daily work.** File edit prompts add friction without much safety benefit for experienced developers. Auto-accept edits and focus deny rules on truly dangerous operations.

4. **Use `dontAsk` for strict environments.** In `dontAsk` mode, only explicitly allowed tools work. Everything else is silently denied. This is the safest mode for environments where you want predictable behavior.

5. **Enable sandboxing for untrusted code.** When working with unfamiliar codebases or running untrusted scripts, the sandbox limits blast radius at the OS level.

6. **Scope permissions appropriately.** Personal preferences go in `~/.claude/settings.json`. Team rules go in `.claude/settings.json`. Sensitive local overrides go in `.claude/settings.local.json` (gitignored).

7. **Use managed settings for enterprise.** Deploy `managed-settings.json` via MDM or configuration management. Set `allowManagedPermissionRulesOnly` to prevent teams from weakening rules.

8. **Pre-approve CI/CD tools.** In headless mode, use `--allowedTools` to explicitly list what Claude can use. Don't rely on `--dangerously-skip-permissions` in production CI.

9. **Test provider configuration with `/status`.** Before deploying Bedrock/Vertex/Foundry configuration to a team, verify auth and model routing works.

10. **Use authentication helpers for credential rotation.** The `apiKeyHelper` setting supports dynamic credential refresh, which is essential for enterprise environments with rotating secrets.

---

## Anti-Patterns

1. **Using `--dangerously-skip-permissions` on developer machines.** This flag gives Claude unrestricted access. It's designed for isolated containers, not laptops with your SSH keys and cloud credentials.

2. **Overly broad allow rules.** `Bash(*)` allows any shell command. Be specific: `Bash(npm run *)`, `Bash(git diff *)`.

3. **No deny rules for sensitive files.** At minimum, deny Read access to `.env` files and SSH keys.

4. **Relying solely on hooks for security.** Hooks are defense-in-depth. Use permission rules as the primary control and hooks for runtime validation.

5. **Not committing project settings.** If `.claude/settings.json` isn't in git, every developer has different rules. Inconsistency leads to security gaps.

6. **Hardcoding API keys in settings files.** Use environment variables or `apiKeyHelper` scripts. Never commit secrets to settings files.

7. **Disabling all hooks in enterprise.** `disableAllHooks: true` removes useful automation. Use `allowManagedHooksOnly: true` instead to keep managed hooks while blocking user-defined ones.

8. **Ignoring sandbox limitations.** Sandboxing is not bulletproof. Allowed domains can be used for data exfiltration. Docker socket access grants host-level privileges. Layer defenses.

---

## References

- [Permissions Reference](https://code.claude.com/docs/en/permissions) -- permission modes, rules, tool syntax
- [Settings Reference](https://code.claude.com/docs/en/settings) -- settings cascade, managed settings, scope precedence
- [Sandboxing](https://code.claude.com/docs/en/sandboxing) -- OS-level enforcement, network isolation, configuration
- [Security](https://code.claude.com/docs/en/security) -- security model, command injection detection, trust verification
- [Authentication](https://code.claude.com/docs/en/authentication) -- login methods, credential helpers, SSO
- [Amazon Bedrock](https://code.claude.com/docs/en/amazon-bedrock) -- Bedrock provider setup, IAM, guardrails
- [Google Vertex AI](https://code.claude.com/docs/en/google-vertex-ai) -- Vertex provider setup, region config
- [Microsoft Foundry](https://code.claude.com/docs/en/microsoft-foundry) -- Foundry provider setup, Entra ID
- [Headless Mode](https://code.claude.com/docs/en/headless) -- CI/CD usage, tool restrictions, output formats
- [CLI Reference](https://code.claude.com/docs/en/cli-reference) -- permission flags, provider flags
- [Example Settings](https://github.com/anthropics/claude-code/tree/main/examples/settings) -- starter configurations (lax, strict, sandbox)
- [Custom Hooks Cookbook](claude-code-hooks-cookbook.md) -- security hook recipes
