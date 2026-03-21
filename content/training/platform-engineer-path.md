---
title: "Platform Engineer Path"
weight: 2
---

# Platform Engineer Path

A structured progression for platform engineers deploying Claude Code to teams and organizations. Each module covers one layer of the deployment stack -- work through them in order.

| Module                                                            | Focus                                                 | Prerequisites |
| ----------------------------------------------------------------- | ----------------------------------------------------- | ------------- |
| [1. Architecture](#module-1-architecture)                         | Request flow, control points, configuration hierarchy | None          |
| [2. Infrastructure](#module-2-infrastructure)                     | Bedrock/provider setup, VPC endpoints, LLM gateway    | Module 1      |
| [3. Configuration and Policy](#module-3-configuration-and-policy) | Managed settings, CLAUDE.md hierarchy, distribution   | Module 2      |
| [4. Permissions and Security](#module-4-permissions-and-security) | Permission rules, sandboxing, compliance controls     | Module 3      |
| [5. Cost Management](#module-5-cost-management)                   | Budgets, model tiering, observability dashboards      | Modules 2-4   |
| [6. Phased Rollout](#module-6-phased-rollout)                     | Cohort strategy, success metrics, rollback triggers   | Modules 1-5   |

## Exercise Materials

Clone the exercise repo for hands-on practice alongside each module:

```bash
git clone https://github.com/malston/training-platform-exercises.git ~/code/training-platform-exercises
cd ~/code/training-platform-exercises
```

Each module has a matching exercise directory (`exercises/01-architecture/`, `exercises/02-infrastructure/`, etc.) with Terraform configs, policy files, and scenarios.

## Module 1: Architecture

**Goal:** Understand the end-to-end request flow and where control points exist.

### Key Concepts

**The request flow has four hops:**

```text
Developer workstation → LLM gateway → VPC endpoint → Bedrock/provider
```

Every API call follows this path. The LLM gateway and managed settings are your two enforcement points -- the gateway controls traffic in transit, managed settings control behavior on the workstation.

**Configuration follows a strict hierarchy:**

```text
managed settings > CLI flags > local settings > project settings > user settings
```

Managed settings deployed via Mobile Device Management (MDM) cannot be overridden by anything below them. This is how you enforce organizational policy.

**Context window has its own hierarchy:**

```text
managed CLAUDE.md → project CLAUDE.md + rules → skills → conversation
```

A managed CLAUDE.md (~500 tokens) is always loaded before project-level instructions, creating an org-wide behavior baseline.

### Exercises

**Starter materials:** `exercises/01-architecture/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- request flow diagramming, enforcement point mapping, and configuration hierarchy exercises.

1. Diagram the four-hop request path for your organization. For each hop, identify who controls it and what fails if it goes down.
2. Map 6 common policies to their enforcement point (gateway, managed settings, or both).
3. Work through the configuration hierarchy: what happens when a developer's user settings conflict with managed settings? When a project adds allow rules alongside managed deny rules?

### Reference

- [Architecture Overview]({{< relref "enterprise-rollout/00-overview/architecture-overview" >}}) -- Full request flow, VPC isolation, configuration hierarchy

## Module 2: Infrastructure

**Goal:** Set up the cloud infrastructure that routes and controls Claude Code API traffic.

### Key Concepts

**Bedrock is a managed API gateway, not self-hosted model deployment.** AWS runs the models on Trainium hardware. Your data stays in AWS under your IAM controls -- it doesn't go to Anthropic.

**Data boundary guarantees:**

- No training on your data
- No data sharing with Anthropic
- Configurable log retention (check your Bedrock region's data retention options -- defaults and minimums vary)
- All traffic stays within your VPC via PrivateLink

**Inference profiles are required.** Bedrock uses cross-region model identifiers, not bare model IDs:

```text
Correct: us.anthropic.claude-sonnet-4-5-20250929-v1:0
Wrong:   anthropic.claude-sonnet-4-5
```

This trips up almost everyone. Test inference profiles in your first infrastructure validation. Verify the current format in your AWS console or the Bedrock documentation, as model identifiers change with releases.

**Model availability lags the direct API.** Expect days to weeks for models to become available on Bedrock after Anthropic releases them. Plan for this in your rollout timeline.

**The LLM gateway sits between developers and Bedrock.** It handles:

- Authentication (developers authenticate to the gateway, gateway authenticates to Bedrock)
- Rate limiting and budget enforcement
- Model routing (default to Sonnet, gate Opus access)
- Request/response logging for audit

### Exercises

**Starter materials:** `exercises/02-infrastructure/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- Terraform modules for VPC endpoints and Bedrock inference profiles.

1. Set up a Bedrock VPC endpoint in a test account and validate that traffic doesn't leave your VPC.
2. Create inference profiles for Sonnet and Haiku. Test that bare model IDs are rejected.
3. Configure an LLM gateway (or proxy) that routes Claude Code traffic through VPC endpoints.

### Reference

- [Bedrock Fundamentals]({{< relref "enterprise-rollout/02-phase-0-infrastructure-foundation/bedrock-fundamentals" >}}) -- Bedrock setup, inference profiles, data boundaries, provider comparison

## Module 3: Configuration and Policy

**Goal:** Enforce organizational policy through managed settings and CLAUDE.md hierarchy.

### Key Concepts

**managed-settings.json is the single source of truth for enterprise policy.** It lives at:

- macOS: `/Library/Application Support/ClaudeCode/managed-settings.json`
- Linux: `/etc/claude-code/managed-settings.json`

Distribute it via your existing MDM, Chef, Ansible, or Group Policy tooling.

**A baseline enterprise config includes:**

```json
{
  "env": {
    "CLAUDE_CODE_USE_BEDROCK": "1",
    "ANTHROPIC_BEDROCK_BASE_URL": "https://gateway.internal.acme.com/bedrock",
    "CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC": "1"
  },
  "permissions": {
    "deny": ["Bash(curl *)", "Bash(wget *)", "Bash(sudo *)"]
  }
}
```

`CLAUDE_CODE_DISABLE_NONESSENTIAL_TRAFFIC=1` eliminates extraneous outbound traffic (telemetry, error reporting, update checks).

**Managed CLAUDE.md creates an org-wide behavior baseline.** Deploy it alongside managed-settings.json. Keep it concise -- it loads on every message and costs context window space.

**Start permissive, tighten later.** Set `allowManagedPermissionRulesOnly: false` initially to let teams define their own permission rules. Switch to `true` for regulated environments where no project-level overrides should be possible.

### Exercises

**Starter materials:** `exercises/03-configuration/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- baseline and strict managed settings, managed CLAUDE.md, and deployment scripts.

1. Write a managed-settings.json that routes traffic through your LLM gateway and disables non-essential traffic.
2. Write a managed CLAUDE.md with 3-5 org-wide rules (e.g., "never commit secrets," "always run tests before completing").
3. Deploy both to a test machine via your MDM tool. Verify with `/settings` in Claude Code.

### Reference

- [Managed Settings]({{< relref "enterprise-rollout/03-phase-1-platform-engineering/managed-settings" >}}) -- Configuration, distribution, validation, and managed-only controls

## Module 4: Permissions and Security

**Goal:** Configure the permission system to protect codebases without blocking developer productivity.

### Key Concepts

**Permissions cascade across five scopes:**

```text
managed > CLI > local > project > user
```

Each scope can add rules. Deny rules from any scope are evaluated first and always win.

**Rule evaluation order: deny → ask → allow.** Structure your security model as a deny list: block dangerous operations in managed settings, then let project and user settings define what to allow.

**Bash rules are shell-aware.** `Bash(safe-cmd *)` matches `safe-cmd anything` but won't match `safe-cmd && evil-cmd`. Claude Code parses the command structure, not the raw string.

**Sandboxing provides OS-level isolation:**

- macOS: Seatbelt (built-in, no installation required)
- Linux: bubblewrap + socat (requires installation)

Sandboxing limits filesystem and network access at the OS level, independent of Claude Code's permission rules.

**Key managed-only controls for regulated environments:**

- `disableBypassPermissionsMode` -- prevents developers from using `--dangerously-skip-permissions`
- `allowManagedPermissionRulesOnly` -- only IT-defined permission rules apply
- `allowManagedHooksOnly` -- only IT-defined hooks execute

### Exercises

**Starter materials:** `exercises/04-permissions/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- permission files at three scopes and a test harness that validates cascade behavior.

1. Write deny rules for your organization: what bash commands should never be allowed? (e.g., `sudo`, `curl` to external hosts, `rm -rf /`)
2. Test the permission cascade: set a deny rule in managed settings, then try to override it in project settings. Confirm it can't be overridden.
3. Enable Seatbelt sandboxing on a test machine and verify that Claude Code can't access paths outside the project directory.

### Reference

- [Permissions & Enterprise]({{< relref "guides/permissions-enterprise" >}}) -- Full permission system, sandboxing, API provider configuration, CI/CD integration

## Module 5: Cost Management

**Goal:** Set up budgets, model tiering, and observability to control spend at scale.

### Key Concepts

**Model tiering is the primary cost lever:**

| Model      | Input Cost | Output Cost | Use Case                                        |
| ---------- | ---------- | ----------- | ----------------------------------------------- |
| Haiku 4.5  | $1/MTok    | $5/MTok     | Fast tasks (subagent delegation, quick lookups) |
| Sonnet 4.5 | $3/MTok    | $15/MTok    | Default for all developers                      |
| Opus 4.6   | $5/MTok    | $25/MTok    | Gated to senior engineers or specific tasks     |

Default all developers to Sonnet. Gate Opus access via the LLM gateway -- Opus with extended thinking is the largest cost driver.

**Typical usage patterns:**

- Light users (~60%): 50K tokens/day
- Moderate users (~30%): 100K tokens/day
- Heavy users (~10%): 200K+ tokens/day

**Extended thinking multiplies costs.** Thinking tokens are billed at the output rate. A single Opus request with extended thinking can consume tens of thousands of thinking tokens. Control thinking cost via effort levels (`CLAUDE_CODE_EFFORT_LEVEL` in managed settings) or by defaulting developers to Sonnet, which uses less thinking at lower output pricing. Note: `MAX_THINKING_TOKENS` is ignored on Opus 4.6 and Sonnet 4.6 (adaptive thinking), except that setting it to `0` still disables thinking entirely. Use effort levels instead.

**Prompt caching reduces costs up to 90%.** The system prompt and CLAUDE.md are cached across messages in a session. Monitor cache hit rates during Cohort 1 -- caching behavior on Bedrock differs from the direct API.

**Observability stack:**

- AWS Cost Explorer with allocation tags for per-team finance reporting
- CloudWatch dashboards for token consumption, latency, error rates, and top-10 users
- LLM gateway logs for request-level audit trail
- Alert at 80% budget utilization before throttling

### Exercises

**Starter materials:** `exercises/05-cost/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- cost calculator, CloudWatch dashboard definition, and rate-limiting configuration.

1. Calculate your expected monthly cost for 100 developers using the usage pattern distribution above.
2. Set up a CloudWatch dashboard tracking tokens consumed per team per day.
3. Configure the LLM gateway to enforce a daily per-user token limit and test what happens when a developer hits it.

### Reference

- [Cost Tracking]({{< relref "enterprise-rollout/05-phase-3-observability-and-governance/cost-tracking" >}}) -- Budget controls, provisioned throughput, caching economics, alerting

## Module 6: Phased Rollout

**Goal:** Execute a phased rollout that discovers issues early and scales with confidence.

### Key Concepts

**Three cohorts, three objectives:**

| Cohort | Size            | Weeks | Objective                                                          |
| ------ | --------------- | ----- | ------------------------------------------------------------------ |
| 1      | ~25 power users | 5-6   | Validate infrastructure, write CLAUDE.md, create org skills        |
| 2      | ~100 developers | 7-9   | Stress-test gateway, validate cost model, instrument observability |
| 3      | ~375 remaining  | 10-12 | Full org rollout, department-by-department                         |

**Cohort 1 builds the foundation.** Select developers from 3-4 different teams and codebases. They'll write the first project CLAUDE.md files, discover infrastructure issues, and become champions who support Cohort 2.

**Cohort 2 stress-tests at scale.** This is where you validate your cost model, test gateway capacity under load, and confirm observability dashboards work with real multi-team data.

**Cohort 3 is department-by-department.** By this point infrastructure is proven, documentation exists, and champions from earlier cohorts provide peer support.

**Rollback is cohort-level, not all-or-nothing.** Pause the gateway route for affected users via managed-settings.json update. Reconfigure without requiring developer action.

**Rollback triggers:**

- Security incident (any severity)
- Infrastructure instability (gateway errors > threshold)
- Cost > 25% over projection
- > 40% negative developer feedback

**Success metrics:**

- Cohort 1: 3+ CLAUDE.md files written, 5+ skills created, zero policy violations
- Cohort 2: 80%+ report faster development, cost model validated against actuals
- Cohort 3: 90%+ have used Claude within 2 weeks, >60% weekly active after 1 month

### Exercises

**Starter materials:** `exercises/06-rollout/` in the [exercise repo](https://github.com/malston/training-platform-exercises) -- cohort roster template, rollback playbook, success metrics, and communication plan templates.

1. Draft your Cohort 1 roster: identify 25 developers across 3-4 teams who would be effective champions.
2. Write a rollback plan: what specific steps would you take if a security incident occurred during Cohort 2?
3. Define your success metrics for each cohort, adapted to your organization's size and goals.

### Reference

- [Cohort Strategy]({{< relref "enterprise-rollout/04-phase-2-phased-rollout/cohort-strategy" >}}) -- Full cohort execution plan, success metrics, rollback triggers

## What's Next

After completing this path, you should be able to:

- Explain the end-to-end Claude Code request flow and control points
- Set up Bedrock infrastructure with VPC isolation
- Deploy and enforce organizational policy through managed settings
- Configure permissions that protect without blocking productivity
- Set up cost controls and observability for multi-team deployment
- Execute a phased rollout with measurable success criteria

For individual developer skills, see the [Developer Path]({{< relref "training/developer-path" >}}). For product managers working alongside your teams, see the [Product Manager Path]({{< relref "training/product-manager-path" >}}).
