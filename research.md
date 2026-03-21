# Security Gaps Research Findings

Research conducted 2026-03-20 against Claude Code docs at `code.claude.com/docs/en/`.

---

## 1. Permission Matching Behavior and Known Limitations

**Source:** [code.claude.com/docs/en/permissions](https://code.claude.com/docs/en/permissions)

### Rule Evaluation Order

- **deny > ask > allow.** First matching rule wins. Deny rules always take precedence.
- Settings precedence: managed > CLI args > local > project > user. If a tool is denied at any level, no other level can allow it.

### Shell-Aware Matching (Compound Commands)

The docs confirm Claude Code is shell-aware:

> Claude Code is aware of shell operators (like `&&`) so a prefix match rule like `Bash(safe-cmd *)` won't give it permission to run the command `safe-cmd && other-cmd`.

When a user approves a compound command with "Yes, don't ask again", Claude Code saves a **separate rule for each subcommand** (up to 5 rules per compound command), not a single rule for the full compound string.

### Known Limitations with Bash Permission Patterns

The docs include an explicit warning about argument-constraining patterns being fragile:

> Bash permission patterns that try to constrain command arguments are fragile. For example, `Bash(curl http://github.com/ *)` intends to restrict curl to GitHub URLs, but won't match variations like:
>
> - Options before URL: `curl -X GET http://github.com/...`
> - Different protocol: `curl https://github.com/...`
> - Redirects: `curl -L http://bit.ly/xyz`
> - Variables: `URL=http://github.com && curl $URL`
> - Extra spaces: `curl  http://github.com`

Recommended mitigations: use deny rules + WebFetch with domain restrictions, or PreToolUse hooks for URL validation.

### Read/Edit Deny Rule Limitation

Critical caveat from the docs:

> Read and Edit deny rules apply to Claude's built-in file tools, not to Bash subprocesses. A `Read(./.env)` deny rule blocks the Read tool but does not prevent `cat .env` in Bash. For OS-level enforcement that blocks all processes from accessing a path, enable the sandbox.

This means deny rules alone are **not sufficient** for file access control -- sandboxing provides the OS-level enforcement layer.

### Wildcard Behavior

- `*` matches within a single directory for Read/Edit rules (gitignore syntax).
- `**` matches recursively across directories.
- For Bash rules, `*` is a glob pattern. Space before `*` matters: `Bash(ls *)` matches `ls -la` but not `lsof`; `Bash(ls*)` matches both.

---

## 2. Server-Managed Settings vs. Endpoint-Managed Settings

**Source:** [code.claude.com/docs/en/server-managed-settings](https://code.claude.com/docs/en/server-managed-settings)

### Server-Managed Settings

- **Status:** Public beta.
- **Available to:** Claude for Teams and Claude for Enterprise customers.
- **Delivery:** Settings delivered from Anthropic's servers via the Claude.ai admin console. Claude Code clients fetch settings at startup and poll hourly.
- **Version requirements:** Claude Code 2.1.38+ (Teams), 2.1.30+ (Enterprise).
- **Requires:** Network access to `api.anthropic.com`.
- **Access control:** Primary Owner and Owner roles can manage settings.
- **Supports:** All settings available in `settings.json`, including hooks, env vars, and managed-only settings like `disableBypassPermissionsMode`.

### Endpoint-Managed Settings

- **Delivery:** Deployed directly to devices via MDM/OS-level policies (macOS managed preferences, Windows registry) or `managed-settings.json` files on disk.
- **Available to:** Any organization with endpoint management infrastructure.
- **Stronger security:** Settings file can be protected from user modification at the OS level.

### Key Differences

| Aspect                 | Server-Managed                                                          | Endpoint-Managed                           |
| ---------------------- | ----------------------------------------------------------------------- | ------------------------------------------ |
| Best for               | Orgs without MDM, unmanaged devices                                     | Orgs with MDM/endpoint management          |
| Security model         | Client-side control, settings from Anthropic servers                    | OS-level protection via MDM                |
| Precedence             | When both present, server-managed wins; endpoint-managed not used       | Used when no server-managed settings exist |
| Limitations            | Settings apply uniformly (no per-group). MCP configs not distributable. | Requires MDM infrastructure                |
| Platform support       | Requires `api.anthropic.com` access                                     | Works with any API provider                |
| **NOT available for:** | Bedrock, Vertex, Foundry, or custom `ANTHROPIC_BASE_URL`                | No restrictions                            |

### Critical Finding for the Wiki

Server-managed settings are **not available** when using third-party model providers (Bedrock, Vertex, Foundry, custom endpoints). Since this binder's scenario routes through Bedrock, server-managed settings are not applicable. The wiki should note this as context for why endpoint-managed delivery is the only option for the Bedrock path.

---

## 3. Subagent Tool Inheritance and Permission Propagation

**Source:** [code.claude.com/docs/en/sub-agents](https://code.claude.com/docs/en/sub-agents)

### Default Inheritance

- Subagents **inherit all tools from the main conversation by default**, including MCP tools.
- Subagents **inherit the permission context from the main conversation** (including managed deny rules).
- Tool access can be restricted via `tools` (allowlist) or `disallowedTools` (denylist) in subagent config.

### Permission Propagation

- Subagents inherit the parent's permissions. The `permissionMode` field can override the mode (default, acceptEdits, dontAsk, bypassPermissions, plan).
- If the parent uses `bypassPermissions`, this takes precedence and **cannot be overridden** by the subagent.
- Background subagents auto-deny anything not pre-approved at launch.

### Security Implications

- A subagent spawned during parallel worktree execution has the same tool surface as the parent (unless explicitly restricted).
- Subagents cannot spawn other subagents (prevents infinite nesting).
- Plugin subagents do **not** support `hooks`, `mcpServers`, or `permissionMode` frontmatter fields (security restriction).

### What the Docs Do NOT Say

The docs do not explicitly address whether managed deny rules from `managed-settings.json` propagate to subagent sessions. However, since subagents "inherit the permission context from the main conversation" and managed settings are the highest-precedence level (cannot be overridden), the logical conclusion is that managed deny rules do propagate. The docs confirm "deny rules always take precedence" and managed settings "cannot be overridden by any other level."

**Recommendation for the wiki:** State that managed deny rules propagate to subagents (consistent with the documented precedence model), but add a `<!-- VERIFY: ... -->` comment noting this is inferred from the precedence docs rather than explicitly stated in the subagent docs.

---

## 4. Anthropic Compliance API

**Sources:** Web search results, [support.claude.com](https://support.claude.com/en/articles/9970975-how-to-access-audit-logs)

### What It Provides

- Programmatic access to Claude usage data including activity logs, chat histories, and file content.
- Filtering capabilities by user and time range.
- Selective deletion capabilities for data management.
- Real-time, automated access for compliance teams.
- Audit log events for settings changes (mentioned in server-managed settings docs).

### Who It Applies To

- **Claude for Enterprise** plan customers using Anthropic's API directly.
- **NOT applicable to Bedrock.** When using Bedrock, Anthropic has no access to requests -- AWS handles all inference in isolation. Audit tooling is entirely AWS-native.

### Enterprise Plan Features

- Everything in the Team plan plus advanced security and compliance controls.
- Admin console for managing server-managed settings.
- Compliance API access.
- SSO/SAML integration.

### Relevance to the Wiki

The existing note in `audit-compliance.md` already correctly states the Compliance API does not apply to Bedrock. The gap to fill is explaining what it _does_ provide for non-Bedrock customers, making the deployment path decision clearer.

---

## 5. ISO/IEC 42001:2023 Certification Status

**Sources:** [anthropic.com/news](https://www.anthropic.com/news/anthropic-achieves-iso-42001-certification-for-responsible-ai), [privacy.claude.com](https://privacy.claude.com/en/articles/10015870-what-certifications-has-anthropic-obtained)

### Certification Details

- **ISO/IEC 42001:2023** -- AI Management Systems. Certified by Schellman Compliance, LLC.
- **Effective:** January 6, 2025 through January 5, 2028.
- **Scope:** AI management system supporting AI Research & Development and AI Services.
- Anthropic describes itself as "one of the first frontier AI labs to achieve this certification."
- ISO 42001 is the first international standard outlining requirements for AI governance.

### Other Certifications (from Privacy Center)

- **ISO 27001:2022** -- Information Security Management.
- **SOC 2 Type I & Type II** -- Security controls.
- **HIPAA-ready** configuration (BAA available).

### Relevance to the Wiki

The wiki's `audit-compliance.md` references ISO 27001 in the SOX section context but doesn't currently call out ISO 42001. This cert is more directly relevant for enterprises evaluating AI tooling since it specifically covers AI management systems, not just general infosec.

---

## 6. Sandboxing Behavior on macOS and Linux

**Source:** [code.claude.com/docs/en/sandboxing](https://code.claude.com/docs/en/sandboxing)

### macOS: Seatbelt (Built-In)

- Uses the built-in Seatbelt framework. No installation required.
- OS-level enforcement -- all child processes inherit sandbox boundaries.

### Linux: Bubblewrap + Socat

- Requires `bubblewrap` and `socat` packages (apt/dnf install).
- WSL2 supported; WSL1 is **not** (bubblewrap requires kernel features).
- `enableWeakerNestedSandbox` mode for Docker environments -- **considerably weakens security**.

### Sandbox Capabilities

**Filesystem isolation:**

- Default: read/write to CWD and subdirs; read access to rest of system (except denied dirs).
- Cannot write outside CWD without explicit `sandbox.filesystem.allowWrite` config.
- Configurable deny/allow for read and write paths.

**Network isolation:**

- Domain-level restrictions via proxy server running outside sandbox.
- New domain requests trigger permission prompts (or auto-block with `allowManagedDomainsOnly`).
- Applies to all scripts, programs, and subprocesses.

### Key Security Limitations (from docs)

- Network filtering is domain-based only; does not inspect traffic content.
- Broad domains like `github.com` could allow data exfiltration.
- Domain fronting is a potential bypass.
- `allowUnixSockets` can grant access to powerful system services (e.g., docker.sock).
- Overly broad filesystem write permissions can enable privilege escalation.
- Linux `enableWeakerNestedSandbox` considerably weakens security.

### Escape Hatch

- Commands that fail due to sandbox restrictions can be retried with `dangerouslyDisableSandbox` (goes through normal permissions flow).
- Can be disabled with `"allowUnsandboxedCommands": false`.

### Relevance to the Wiki

The existing wiki content on sandboxing is accurate but brief. The sandbox docs now include significantly more detail on filesystem isolation, network isolation, and security limitations. The wiki's existing content covers the basics correctly -- no corrections needed, just the additional context from the gaps prompt.

---

## Summary of Findings

| Gap                          | Research Status | Key Finding                                                                                                                                                      |
| ---------------------------- | --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| 1. Permission Matching Bugs  | Complete        | Docs confirm shell-aware matching works but explicitly warn about fragile argument-constraining patterns and Read/Edit deny rules not covering Bash subprocesses |
| 2. Server-Managed Settings   | Complete        | Not available for Bedrock -- critical context for why the wiki focuses on endpoint-managed delivery                                                              |
| 3. Subagent Tool Inheritance | Complete        | Subagents inherit all tools and permissions by default; managed deny propagation is inferred (not explicitly documented)                                         |
| 4. Compliance API            | Complete        | Enterprise plan only, provides usage logs + conversation histories + selective deletion; not applicable to Bedrock                                               |
| 5. ISO 42001                 | Complete        | Certified Jan 6, 2025 by Schellman; first international AI governance standard                                                                                   |
| 6. Sandboxing                | Complete        | Existing wiki content accurate; sandbox docs now much more detailed on limitations                                                                               |
| 7. Validation Dates          | N/A             | Implementation detail -- use today's date (2026-03-20) after verification                                                                                        |
