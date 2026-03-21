---
title: "Security Controls"
weight: 3
---

# Security Controls

## Claude Code Permission Model

Claude Code requires explicit developer approval for:

- Writing or modifying files
- Executing shell commands
- Making network requests (beyond the LLM API)

This is the first line of defense. Developers see what Claude wants to do before it happens.

## Non-Negotiable Controls

### Bypass Mode Disabled

`disableBypassPermissionsMode: "disable"` in managed-settings.json prevents `--dangerously-skip-permissions`. This flag removes all permission prompts and lets Claude execute freely -- never use in production or enterprise environments, regardless of developer convenience arguments.

### Deny Rules (Managed Settings)

The enterprise baseline denies access to:

```json
"deny": [
  "Read(**/.env)",          // Environment files with secrets
  "Read(**/.env.*)",        // Variant env files
  "Read(**/secrets/**)",    // Secrets directories
  "Read(**/.ssh/**)",       // SSH keys
  "Read(**/credentials*)",  // Credential files
  "Bash(sudo:*)",           // Privilege escalation
  "Bash(su:*)",             // User switching
  "Bash(curl:*)",           // Arbitrary network calls
  "Bash(wget:*)",           // Arbitrary downloads
  "Bash(ssh:*)",            // Remote access
  "Bash(rm -rf:*)"          // Destructive deletion
]
```

These cannot be overridden by project or user settings.

**Caveat: pattern matching boundaries.** Deny rules handle compound commands correctly -- Claude Code is aware of shell operators like `&&`, so each subcommand in `safe-cmd && evil-cmd` must be permitted separately; a permission for `Bash(safe-cmd:*)` does not also permit `evil-cmd`. However, argument-constraining patterns are fragile: option reordering, variable expansion, and extra whitespace can all bypass a pattern like `Bash(curl:http://example.com/*)`. More critically, Read and Edit deny rules apply only to Claude's built-in file tools, not to Bash subprocesses -- a `Read(./.env)` deny rule does not prevent `cat .env` in a shell command. [Sandboxing](#sandboxing) adds OS-level enforcement for the processes it constrains, but it does not automatically block reads of sensitive files inside the working directory. For complex conditions that pattern matching cannot express, use [PreToolUse hooks](#hooks-as-security-controls) as the programmable enforcement layer.

### Project-Level Deny Rules

Teams can add their own deny rules on top of the enterprise baseline via `.claude/settings.json`:

```json
{
  "permissions": {
    "deny": [
      "Read(**/patient-data/**)", // Team-specific sensitive paths
      "Bash(docker push:*)" // Prevent pushing images
    ]
  }
}
```

## File Access Control

### Principle: Compartmentalized Repos

Over-restricting file access makes Claude dramatically less useful. The better pattern is:

- Sensitive data lives in separate repos with separate access controls
- Within a repo Claude can read, deny rules block specific sensitive paths
- Code-level secrets are managed via vault/environment variables, not files in the repo

### Pushback: "Can We Restrict Which Files Claude Can See?"

Yes, via deny rules. But be thoughtful -- Claude needs to read code to be useful. Block specific sensitive paths, don't blanket-deny read access. The better approach is ensuring sensitive data isn't in the codebase at all.

## Deterministic Security Tools

### Critical Principle

Never rely solely on AI-generated security review. LLM reviews are non-deterministic -- the same code might pass one review and fail another.

### Layered Approach

1. **Deterministic baseline (CI/CD):** Semgrep, Snyk, SonarQube, or equivalent SAST/DAST tools run on every PR. These provide reproducible, auditable results.
2. **AI-assisted review (development):** Claude Code's /security-review skill provides an additional perspective during development. It catches categories of issues that rule-based tools miss (logic flaws, authorization gaps).
3. **Human review (PR process):** All AI-generated code goes through normal PR review. The reviewer knows Claude was used and checks accordingly.

### What AI Review Catches That SAST Misses

- Business logic vulnerabilities
- Authorization gaps in complex workflows
- Subtle race conditions
- Missing input validation in non-obvious paths

### What SAST Catches That AI Review Misses (Reliably)

- Known CVE patterns
- Hardcoded secrets (with deterministic regex)
- Dependency vulnerabilities
- Configuration weaknesses with established signatures

## Sandboxing

Claude Code includes built-in sandboxing that restricts filesystem and process access beyond what deny rules provide.

### macOS: Seatbelt (Built-In)

On macOS, Claude Code automatically runs with Seatbelt sandboxing. No installation or configuration required. This restricts Claude Code's filesystem access to the working directory and common tool paths, preventing it from reading or writing files in unexpected locations even if deny rules don't cover them.

### Linux: Bubblewrap + Socat

On Linux, Claude Code supports sandboxing via `bubblewrap` and `socat`, but these must be installed separately:

```bash
# Debian/Ubuntu
apt-get install bubblewrap socat

# RHEL/Fedora
dnf install bubblewrap socat
```

Include these in your devcontainer or Coder workspace templates so sandboxing is active by default for all developers.

### Enterprise Recommendation

Sandboxing is defense in depth -- it limits blast radius if a deny rule is missing or if Claude executes something unexpected. For the 500-developer rollout, ensure sandbox dependencies are included in all standardized developer environments.

## Hooks as Security Controls

Deny rules use pattern matching, which handles most cases but can't express complex conditions. For advanced security logic, use **PreToolUse hooks** -- they can inspect the full tool call and programmatically allow, block, or modify it.

### Example: Block Writes Outside Repo Root

```json
{
  "hooks": {
    "PreToolUse": [
      {
        "matcher": "Write|Edit",
        "hook": {
          "type": "command",
          "command": "python3 /opt/claude-hooks/enforce-repo-boundary.py"
        }
      }
    ]
  }
}
```

The hook script receives the tool input as JSON on stdin and can exit with code 2 to block the action, or exit 0 with a JSON response to allow or modify it.

### What Hooks Can Do That Deny Rules Can't

- Inspect full file paths and resolve symlinks before allowing access
- Check file content patterns (e.g., block writes containing API key formats)
- Enforce multi-condition logic (allow `rm` only for files matching a specific pattern)
- Log detailed audit events to your Security Information and Event Management (SIEM) platform for specific tool calls
- Call external APIs for dynamic policy decisions

### Deployment

Deploy managed hooks via `managed-settings.json` with `allowManagedHooksOnly: true` if you want to prevent project-level hooks from overriding your security hooks.

## Subagent Permission Inheritance

Claude Code subagents inherit all tools, MCP connections, and permissions from the parent session by default. Managed deny rules propagate through the settings precedence hierarchy (managed > CLI > local > project > user) and cannot be overridden at any other level, so subagents that inherit the parent's permission context inherit managed restrictions as well.

The security implication: a subagent spawned during parallel worktree execution has the same tool surface as the parent unless explicitly restricted via `tools` or `disallowedTools` in the subagent definition. Background subagents provide a built-in containment mechanism -- they auto-deny anything not pre-approved at launch.

Recommendations for the 500-developer rollout:

- Verify deny rules cover the subagent execution path. Subagents can use any tool the parent can use, so rules that only account for the parent session leave gaps.
- If hook-based enforcement is critical, set `allowManagedHooksOnly: true` to prevent project-level hooks from overriding managed security hooks in subagent contexts.
- Plugin-provided subagents cannot define `hooks`, `mcpServers`, or `permissionMode` -- a security restriction that limits the blast radius of third-party agent code.
- Subagents cannot spawn other subagents, which prevents infinite nesting and unbounded tool surface expansion.

## Network Security

### Zero Egress from Claude Code

With managed-settings.json configured:

- `CLAUDE_CODE_USE_BEDROCK=1` routes inference through Bedrock
- `CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` blocks telemetry, updates, bug reports
- `Bash(curl:*)` and `Bash(wget:*)` deny rules prevent arbitrary network calls
- The **only** outbound traffic is to the internal LLM gateway

### Verification

Monitor VPC Flow Logs to confirm no unexpected egress from developer subnets to the internet during Claude Code usage.

## Incident Response

### If a Deny Rule is Triggered

Claude Code shows the developer a notification explaining the policy. The developer can:

- Rephrase their request to avoid the blocked operation
- Perform the blocked operation manually outside Claude Code
- Request a policy exception through the platform team

### If Suspicious Usage is Detected

Gateway logs and CloudTrail provide the audit trail. Investigate:

- Unusual token volumes (possible data exfiltration attempt via prompts)
- Requests to unexpected models
- Access outside normal business hours
- Repeated deny rule triggers from the same user

_Last validated against Claude Code docs: 2026-03-20_
