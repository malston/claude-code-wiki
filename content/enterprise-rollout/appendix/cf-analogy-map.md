---
title: "Cloud Foundry to Claude Code Analogy Map"
linkTitle: "CF Analogy Map"
weight: 2
---

# Cloud Foundry to Claude Code Analogy Map

For consultants coming from a Cloud Foundry background, these analogies help translate platform engineering concepts into the Claude Code domain.

## Core Concept Mapping

| Cloud Foundry                             | Claude Code                                                | Explanation                                                                                          |
| ----------------------------------------- | ---------------------------------------------------------- | ---------------------------------------------------------------------------------------------------- |
| **Org/Space structure**                   | Settings hierarchy (managed → project → user)              | Multi-level configuration with inheritance and isolation between teams                               |
| **Buildpacks**                            | Skills and CLAUDE.md conventions                           | Opinionated frameworks that encode best practices -- developers get patterns by default              |
| **Service Broker catalog**                | Approved MCP servers                                       | Curated set of external integrations available to developers, centrally managed                      |
| **App manifest (manifest.yml)**           | Project `.claude/settings.json` + `CLAUDE.md`              | Declarative configuration checked into the repo that defines how the tool interacts with the project |
| **Platform operator**                     | Platform engineering team managing `managed-settings.json` | Central team that owns the platform layer, sets policies, and enables developer self-service         |
| **`cf push`**                             | Developer runs `claude` with everything pre-configured     | The developer experience is simple because the platform handles complexity underneath                |
| **Stemcells / base images**               | Devcontainers / Coder workspace templates                  | Standardized environment that ensures consistent tooling across all developers                       |
| **Diego cells**                           | LLM Gateway + Bedrock                                      | The compute layer that actually runs workloads, abstracted from the developer                        |
| **UAA (User Account and Authentication)** | SSO + gateway authentication                               | Centralized identity and access management                                                           |
| **Quota plans**                           | Per-team token budgets via LLM gateway                     | Resource limits that prevent any single team from consuming disproportionate capacity                |
| **App security groups**                   | Deny rules in managed-settings.json                        | Network/access restrictions that define what the workload can and cannot reach                       |
| **Route services / service mesh**         | LLM Gateway (LiteLLM / Kong AI)                            | Intermediary that handles routing, auth, logging, and policy enforcement                             |
| **BOSH releases**                         | Skills packaged as plugins                                 | Versioned, distributable packages of capability                                                      |
| **Cloud Controller API**                  | Claude Code CLI + MCP protocol                             | The interface through which developers and automation interact with the platform                     |
| **Logs / Loggregator**                    | CloudTrail + gateway logs + CloudWatch                     | Multi-layer observability stack for audit, debugging, and cost tracking                              |
| **Ops Manager tiles**                     | MCP server integrations                                    | Pre-built integrations that extend the platform's capabilities                                       |

## The Core Insight

**Claude Code without platform engineering is like giving 500 developers raw `cf push` access with no buildpacks, service brokers, or app manifests.**

They'll get something running, but:

- Every developer figures out their own patterns (inconsistency)
- No guardrails on resource consumption (cost blowout)
- No standardized security posture (compliance risk)
- No reusable components (duplicated effort)
- Onboarding is slow and painful (tribal knowledge)

Phase 1 builds the equivalent of buildpacks and manifests for AI-assisted development. When a developer in Cohort 2 or 3 opens Claude Code for the first time, they get:

- Bedrock routing ✓
- Security policy ✓
- Org conventions ✓
- Project-specific patterns ✓
- Standard slash commands ✓
- All without configuring anything themselves

Just type `claude` and start working. That's the platform engineering promise.
