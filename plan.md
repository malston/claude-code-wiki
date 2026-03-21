# Security Gaps Implementation Plan

Seven surgical additions to the enterprise rollout section. No restructuring of existing content.

---

## Gap 1: Permission Matching Bugs Caveat

- **Target file:** `content/enterprise-rollout/05-phase-3-observability-and-governance/security-controls.md`
- **Location:** After the deny rules code block in "Deny Rules (Managed Settings)" (after line 44, before "Project-Level Deny Rules")
- **Length:** ~5 sentences
- **Outline:**
  1. Deny rules handle compound commands correctly (shell-aware matching splits on `&&`, `||`, `;`).
  2. However, argument-constraining patterns are fragile -- option reordering, variable expansion, and extra whitespace can bypass a pattern.
  3. Read/Edit deny rules apply to Claude's built-in tools only, not Bash subprocesses (`cat .env` bypasses `Read(./.env)` deny).
  4. Sandboxing provides the OS-level enforcement layer that deny rules alone cannot.
  5. Link forward to "Hooks as Security Controls" as the programmable enforcement layer for complex conditions.

---

## Gap 2: Server-Managed Settings Alternative

- **Target file:** `content/enterprise-rollout/03-phase-1-platform-engineering/managed-settings.md`
- **Location:** After "Distribution" section (after line 100), as a new `## Server-Managed Settings (Anthropic Direct)` subsection before "Validation"
- **Length:** ~150 words
- **Outline:**
  1. Anthropic offers server-managed settings via the Claude.ai admin console (public beta) for Teams and Enterprise plan customers.
  2. Settings are delivered from Anthropic's servers at authentication time -- no MDM required.
  3. Why this binder uses endpoint-managed delivery instead: server-managed settings require network access to `api.anthropic.com` and are **not available** when routing through Bedrock, Vertex, Foundry, or custom API endpoints.
  4. For clients evaluating Anthropic direct deployment (no cloud provider intermediary), server-managed settings are a simpler path to initial controls before MDM infrastructure is ready.
  5. Link to Claude Code docs: `code.claude.com/docs/en/server-managed-settings`.

---

## Gap 3: Subagent Tool Inheritance

- **Target file:** `content/enterprise-rollout/05-phase-3-observability-and-governance/security-controls.md`
- **Location:** After "Hooks as Security Controls" section (after line 161), as a new `## Subagent Permission Inheritance` subsection before "Network Security"
- **Length:** ~200 words
- **Outline:**
  1. Claude Code subagents inherit all tools, MCP connections, and permissions from the parent session by default.
  2. Managed deny rules propagate through the permission hierarchy -- subagents inherit the parent's permission context and managed settings are the highest precedence level. `<!-- VERIFY: Managed deny propagation to subagents is inferred from the settings precedence model, not explicitly documented in the subagent docs. -->`
  3. Security implication: a subagent spawned during parallel worktree execution has the same tool surface as the parent unless explicitly restricted via `tools` or `disallowedTools` in the subagent definition.
  4. Background subagents auto-deny anything not pre-approved at launch (a built-in containment mechanism).
  5. Recommendation: teams running parallel subagents should verify deny rules cover the subagent execution path. If hook-based enforcement is critical, set `allowManagedHooksOnly: true` to prevent project-level hooks from overriding managed security hooks in subagent contexts.
  6. Note that plugin-provided subagents cannot define `hooks`, `mcpServers`, or `permissionMode` (security restriction).

---

## Gap 4: Compliance API vs. Bedrock-Native Audit

- **Target file:** `content/enterprise-rollout/05-phase-3-observability-and-governance/audit-compliance.md`
- **Location:** Expand the existing **Note** at the end of "Layer 3: Bedrock Model Invocation Logging" (line 87). Replace the single-paragraph note with a more detailed comparison subsection.
- **Length:** ~150 words
- **Outline:**
  1. Keep the existing framing: Compliance API does not apply to Bedrock.
  2. Add what the Compliance API provides for Anthropic direct (Enterprise plan) customers: programmatic access to usage data, activity logs, conversation histories, and selective deletion. Filtering by user and time range.
  3. Contrast: Bedrock customers get equivalent capabilities through the three-layer AWS-native stack described in this page (CloudTrail + Gateway + Invocation Logging).
  4. Decision point: if the client is evaluating Anthropic direct vs. cloud provider deployment, the Compliance API is the simpler audit path (single integration point) but only available on the Enterprise plan.

---

## Gap 5: Developer-Facing "What Developers See" Page

- **Target file:** New file at `content/enterprise-rollout/03-phase-1-platform-engineering/what-developers-see.md`
- **Location:** Phase 1 section (platform engineering), since this is a day-one onboarding artifact, not a rollout sequencing concern.
- **Length:** ~300 words
- **Outline:**
  1. Frontmatter: title "What Developers See", weight 8 (after existing Phase 1 pages).
  2. Purpose statement: this is the page a team lead hands to developers on day one.
  3. **When a deny rule fires:** Claude shows a notification explaining the policy. The developer can rephrase, perform the action manually, or request an exception.
  4. **Checking effective permissions:** `/permissions` shows all active rules with their source (managed, project, user). `/settings` shows effective settings with managed overrides marked.
  5. **Managed settings are invisible:** Developers don't see or interact with `managed-settings.json` directly. Controls are transparent until a boundary is hit.
  6. **Mental model shift:** Claude Code is an agent that proposes actions and asks permission, not an autocomplete engine. Developers review proposed commands and file changes before approval. This requires training time -- budget for it in cohort onboarding.
  7. **What stays the same:** Git workflow, PR process, CI/CD pipeline, code review. Claude Code operates within the existing development process, not around it.

---

## Gap 6: ISO/IEC 42001:2023 Reference

- **Target file:** `content/enterprise-rollout/05-phase-3-observability-and-governance/audit-compliance.md`
- **Location:** In "Regulatory Framework Alignment" section, after the SOX subsection (after line 129). Add a new `### ISO/IEC 42001:2023` subsection.
- **Length:** ~50 words
- **Outline:**
  1. Anthropic holds ISO/IEC 42001:2023 certification (effective January 2025, Schellman Compliance LLC).
  2. ISO 42001 is the first international standard for AI management systems -- more specifically relevant for enterprises evaluating AI tooling than the general-purpose ISO 27001 infosec certification.
  3. Alongside existing ISO 27001:2022 and SOC 2 Type II certifications.

---

## Gap 7: Per-Page Validation Dates

- **Target files:**
  - `content/enterprise-rollout/03-phase-1-platform-engineering/managed-settings.md`
  - `content/enterprise-rollout/05-phase-3-observability-and-governance/security-controls.md`
  - `content/enterprise-rollout/05-phase-3-observability-and-governance/audit-compliance.md`
- **Location:** End of each file, as a footer line after all content.
- **Format:** `*Last validated against Claude Code docs: 2026-03-20*`
- **Length:** 1 line per file.

---

## Implementation Checklist

- [x] Gap 1: Permission matching caveat in security-controls.md
- [x] Gap 2: Server-managed settings subsection in managed-settings.md
- [x] Gap 3: Subagent permission inheritance in security-controls.md
- [x] Gap 4: Compliance API comparison in audit-compliance.md
- [x] Gap 5: What Developers See page (new file)
- [x] Gap 6: ISO 42001 reference in audit-compliance.md
- [x] Gap 7: Validation dates on three pages
