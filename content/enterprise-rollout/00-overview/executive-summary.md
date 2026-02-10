---
title: "Executive Summary"
weight: 1
---

# Executive Summary

## The Engagement

A 500-developer engineering organization with strict security requirements needs to adopt Claude Code as an enterprise-wide AI-assisted development tool. Their core constraint: **no code can leave their network.**

This document describes a 12-week implementation across three workstreams:

1. **Infrastructure (30% effort):** Amazon Bedrock + VPC PrivateLink + LLM Gateway
2. **Platform Engineering (40% effort):** Managed configurations, CLAUDE.md architecture, skills library, developer environments
3. **Change Management (30% effort):** Phased rollout, champion program, productivity measurement

## The Architecture in One Paragraph

Developer workstations connect through the corporate network to an internal LLM gateway (LiteLLM or Kong AI Gateway), which routes requests through a VPC endpoint via AWS PrivateLink to Amazon Bedrock. Bedrock hosts the Claude models within AWS's data boundary. No traffic touches the public internet. No code is retained or used for training. The LLM gateway provides per-user token budgets, centralized authentication, and audit logging. Managed settings enforce organization-wide security policies that individual developers cannot override.

## The Four Phases

### Phase 0: Infrastructure Foundation (Weeks 1–4)

Stand up the Bedrock account, VPC endpoint, PrivateLink connection, and LLM gateway. Validate the network path end-to-end. Get CISO sign-off on the data flow.

### Phase 1: Platform Engineering Layer (Weeks 3–6, overlapping)

Build the managed-settings.json security policy, the CLAUDE.md architecture across four context layers, the organization-wide skills library, and standardized developer environments. This is where most enterprises underinvest, and where the engagement delivers the most differentiated value.

### Phase 2: Phased Rollout (Weeks 5–12)

Three cohorts: 25 power users → 100 full teams → 375 remaining developers. Each cohort discovers different classes of issues and builds institutional knowledge.

### Phase 3: Observability & Governance (Ongoing)

Cost tracking via the LLM gateway and AWS Cost Explorer. Three-layer audit trail (CloudTrail + gateway logs + Bedrock model invocation logging). Continuous refinement of CLAUDE.md and skills based on developer feedback and usage patterns.

## The Key Insight

Infrastructure is a solved problem — any competent AWS engineer can set up Bedrock with PrivateLink. **The difference between "we deployed Claude Code" and "500 developers are actually more productive" is the platform engineering layer:** the context architecture, the skills library, the managed conventions, and the phased change management. That's where the consulting value concentrates.

## The Market Gap

- **AWS** handles infrastructure plumbing but has no depth on Claude Code configuration, skills, or developer experience
- **Anthropic** knows the product deeply but doesn't do infrastructure implementation
- **Large SIs (Accenture, Cognizant)** target $2M+ full-stack transformation — too expensive for a focused 12-week engagement
- **Nobody** is doing the middle layer well — infrastructure + Claude Code platform engineering + phased rollout

This gap represents a 6–12 week consulting engagement at $150K–$300K, ideal for a platform engineering consultant with deep Claude Code expertise.
