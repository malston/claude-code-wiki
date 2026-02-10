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

## The Four Phases

**Phase 0: Infrastructure Foundation (Weeks 1--4)** -- Stand up cloud provider infrastructure (Amazon Bedrock, Google Vertex AI, or Azure Foundry) with private networking so all LLM traffic stays inside the customer's network. Includes security constraint clarification, LLM gateway design, and Terraform patterns for all three providers.

**Phase 1: Platform Engineering (Weeks 3--6)** -- Configure managed settings, CLAUDE.md architecture, skills libraries, and developer environment standardization. This is where the platform team builds the guardrails that make self-service safe.

**Phase 2: Phased Rollout (Weeks 5--12)** -- Three cohorts of increasing size, each with a learning loop. Cohort 1 (platform engineers) discovers friction; Cohort 2 (willing early adopters) validates the developer experience; Cohort 3 (general availability) proves the model at scale.

**Phase 3: Observability & Governance (Ongoing)** -- Cost tracking with token budgets and model tiering, three-layer audit architecture, and security controls including permission models and SAST/DAST integration.

---

## How to Use This Binder

Each phase section contains standalone documents that can be extracted and shared with different stakeholders -- the infrastructure team gets Phase 0, platform engineering gets Phase 1, leadership gets the executive summary and Phase 2.

Browse the sections in the sidebar, or start with the [Executive Summary](00-overview/executive-summary/).

The content reflects Claude Code's configuration model as of February 2026. Claude Code's enterprise features are evolving rapidly -- validate specific settings and APIs against [code.claude.com/docs](https://code.claude.com/docs) before using in customer-facing materials.
