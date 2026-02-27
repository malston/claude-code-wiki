---
title: "Developer Environment Standardization"
linkTitle: "Developer Environment"
weight: 2
---

# Developer Environment Standardization

## The Problem

Without standardization, 500 developers debug 500 different environment configurations. Claude Code needs Node.js 18+, correct environment variables, network connectivity to the LLM gateway, and managed settings in the right filesystem location. Every permutation is a support ticket.

## Option A: Managed Devcontainers (Recommended for VS Code/Codespaces Orgs)

If the org uses VS Code or GitHub Codespaces, create a standard devcontainer with everything pre-configured.

```json
// .devcontainer/devcontainer.json
{
  "name": "Enterprise Dev Environment",
  "image": "mcr.microsoft.com/devcontainers/base:ubuntu",
  "features": {
    "ghcr.io/devcontainers/features/node:1": { "version": "20" }
  },
  "postCreateCommand": "npm install -g @anthropic-ai/claude-code",
  "containerEnv": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://llm-gateway.internal.corp.com/bedrock",
    "CLAUDE_CODE_SKIP_BEDROCK_AUTH": "1",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "mounts": [
    "source=/Library/Application Support/ClaudeCode,target=/etc/claude-code,type=bind,readonly"
  ]
}
```

Developer opens repo → devcontainer starts → Claude Code just works.

## Option B: Coder Workspaces (Self-Hosted Cloud Dev Environments)

Better for orgs wanting tighter control. Coder provides self-hosted cloud development environments with Terraform templates.

Benefits:

- Standardized, pre-configured, centrally managed
- Templates include Claude Code + all tooling
- Audit trail of workspace creation and usage
- Consistent regardless of developer's local machine

## Option C: Configuration as Code (Shell Profiles)

If developers use their own machines directly, distribute a standard shell profile snippet via configuration management (Ansible, Chef, Puppet).

```bash
# /etc/profile.d/claude-code.sh (deployed via config management)

# Bedrock routing
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_BEDROCK_BASE_URL='https://llm-gateway.internal.corp.com/bedrock'
export CLAUDE_CODE_SKIP_BEDROCK_AUTH=1
export CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1

# Corporate CA cert for proxy (if applicable)
export NODE_EXTRA_CA_CERTS='/etc/ssl/certs/corp-ca-bundle.pem'

# Ensure Node.js 18+ is available
if ! command -v node &> /dev/null || [[ $(node -v | cut -d. -f1 | tr -d v) -lt 18 ]]; then
  echo "WARNING: Claude Code requires Node.js 18+. Install via your package manager."
fi
```

Less ideal -- more support burden -- but sometimes the pragmatic choice.

## MCP Server Configuration

Claude Code supports `.mcp.json` in project directories and `~/.claude.json` globally. The managed settings directory also supports **`managed-mcp.json`** for organization-wide MCP server configuration, deployed alongside `managed-settings.json` and `CLAUDE.md`.

The platform team defines which MCP servers are approved and pre-configures them. Use `managed-mcp.json` for org-wide servers (e.g., Jira, Sentry) and project `.mcp.json` for repo-specific servers. MCP server access can be further controlled with `allowedMcpServers` and `deniedMcpServers` in managed-settings.json.

Anthropic recommends that one central team configures MCP servers and checks `.mcp.json` into the codebase so all users benefit.

Approved MCP servers for a typical enterprise:

- **Jira/Confluence** -- ticket management and documentation lookup
- **Sentry/Datadog** -- error and monitoring integration
- **Internal APIs** -- company-specific tooling
- **Database** -- read-only access to staging/dev schemas

## Hooks

Claude Code hooks run shell commands at lifecycle events (before/after tool use, on setup, on stop). Platform team provides standard hooks for:

- Automated linting on file changes
- Type checking before accepting edits
- Desktop notifications when long-running tasks complete

Whether users can add their own hooks is controlled by `allowManagedHooksOnly` in managed-settings.json.

## Plugin Governance

`strictKnownMarketplaces` in managed-settings.json controls which plugin sources are allowed. For enterprise:

- Empty array `[]` blocks all marketplaces (most restrictive)
- Add source objects to allow vetted plugins (e.g., `{"source": "github", "repo": "acme-corp/approved-plugins"}`)
- Supports `github`, `git`, `url`, `npm`, `file`, `directory`, and `hostPattern` source types
- Public marketplace can be added if the security posture allows it

## Claude Code Version Management

`DISABLE_AUTOUPDATER` (bundled in `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC`) prevents Claude Code from auto-updating, but you still need a strategy for controlled rollouts of new versions across 500 machines.

### Recommended Approach

1. **Pin the version in your devcontainer or package manager:**

```json
// devcontainer.json
"postCreateCommand": "npm install -g @anthropic-ai/claude-code@2.1.37"
```

1. **Test new versions with Cohort 1 first.** Before upgrading everyone, have 2-3 power users run the new version for a week. New versions occasionally change behavior (tool calling patterns, skill loading, compaction thresholds).

2. **Upgrade in waves.** Same cohort pattern as the initial rollout -- don't upgrade 500 developers simultaneously.

3. **Track the current version in managed settings documentation.** When you push a version update, update the internal changelog so developers know what changed.

### Version Update Cadence

Claude Code releases frequently (weekly or more). You don't need to track every release. Quarterly updates are reasonable unless a release fixes a bug that affects your deployment or adds a feature you need.

## Platform Team Ownership Summary

| Component             | Owner         | Distribution            |
| --------------------- | ------------- | ----------------------- |
| managed-settings.json | Platform team | MDM / config management |
| Managed CLAUDE.md     | Platform team | MDM / config management |
| Org-wide skills       | Platform team | Plugin or shared repo   |
| .mcp.json template    | Platform team | Repo template           |
| Standard hooks        | Platform team | Repo template           |
| Devcontainer config   | Platform team | Repo template           |
| Project CLAUDE.md     | Team leads    | In each repo            |
| .claude/rules/        | Team leads    | In each repo            |
| Team skills           | Team leads    | In each repo            |
