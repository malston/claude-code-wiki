---
title: "Enterprise Claude Code Rollout"
weight: 4
bookCollapseSection: false
---

# Enterprise Claude Code Rollout

A consulting binder for deploying Claude Code to a 500-developer enterprise with strict network security requirements.

|                |                                                    |
| -------------- | -------------------------------------------------- |
| **Scenario**   | Enterprise org where no code can leave the network |
| **Engagement** | 12-week implementation consulting                  |
| **Value**      | $150K--$300K depending on complexity               |
| **Date**       | February 2026                                      |

---

## Sections

- **[Overview]({{< relref "enterprise-rollout/00-overview" >}})** -- Executive summary and architecture overview for stakeholder alignment.
- **[Skill Gaps and Market Opportunity]({{< relref "enterprise-rollout/01-skill-gaps-and-market-opportunity" >}})** -- Where developer teams struggle today and the consulting engagement opportunity.
- **[Phase 0: Infrastructure Foundation]({{< relref "enterprise-rollout/02-phase-0-infrastructure-foundation" >}})** (Weeks 1--4) -- Stand up cloud provider infrastructure (Bedrock, Vertex AI, or Foundry) with private networking so all LLM traffic stays inside the customer's network.
- **[Phase 1: Platform Engineering]({{< relref "enterprise-rollout/03-phase-1-platform-engineering" >}})** (Weeks 3--6) -- Configure managed settings, CLAUDE.md architecture, skills libraries, and developer environment standardization.
- **[Phase 2: Phased Rollout]({{< relref "enterprise-rollout/04-phase-2-phased-rollout" >}})** (Weeks 5--12) -- Three cohorts of increasing size, each with a learning loop from platform engineers through early adopters to general availability.
- **[Phase 3: Observability & Governance]({{< relref "enterprise-rollout/05-phase-3-observability-and-governance" >}})** (Ongoing) -- Cost tracking with token budgets, three-layer audit architecture, and security controls.
- **[Implementation Support Ecosystem]({{< relref "enterprise-rollout/06-implementation-support-ecosystem" >}})** -- Support landscape and recommendations for handling organizational pushback.
- **[Appendix]({{< relref "enterprise-rollout/appendix" >}})** -- Build-out timeline, Cloud Foundry analogy map, and reference configurations.

---

## How to Use This Binder

Each phase section contains standalone documents that can be extracted and shared with different stakeholders -- the infrastructure team gets Phase 0, platform engineering gets Phase 1, leadership gets the executive summary and Phase 2.

Browse the sections in the sidebar, or start with the [Executive Summary](00-overview/executive-summary/).

The content reflects Claude Code's configuration model as of February 2026. Claude Code's enterprise features are evolving rapidly -- validate specific settings and APIs against [code.claude.com/docs](https://code.claude.com/docs) before using in customer-facing materials.
