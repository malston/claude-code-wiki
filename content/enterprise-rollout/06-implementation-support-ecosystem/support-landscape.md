---
title: "Implementation Support Landscape"
linkTitle: "Support Landscape"
weight: 1
---

# Implementation Support Landscape

## Layer 1: AWS (Infrastructure Plumbing)

### AWS Solutions Architects (Free)

Every enterprise account gets assigned SAs who can help design networking. They'll walk through VPC endpoint setup, Direct Connect integration, and IAM policy design. Excellent at the infrastructure layer.

### AWS Professional Services (Paid)

Hands-on implementation engagements. Now have people specifically focused on Bedrock deployment patterns. The "Guidance for Claude Code with Amazon Bedrock" reference architecture implements proven patterns deployable in hours — ProServ uses this as a starting point.

### AWS Partner Network Consultancies

Accenture, Deloitte, Slalom, etc. all have AWS practices for networking and security work. VPC + PrivateLink is the same pattern used for any private connectivity to AWS managed services — routine work.

**Gap:** Great at infrastructure plumbing. No depth on Claude Code configuration, skills architecture, or developer experience.

## Layer 2: Anthropic (Product Expertise)

### Claude for Enterprise Plan

- SSO and domain capture
- Role-based permissions
- Compliance API access
- Managed policy settings for org-wide Claude Code configurations

### Enterprise Sales Team

Handles contractual/compliance side — data processing agreements, security questionnaires, Compliance API access. Helps navigate Bedrock vs. direct API decisions.

**Gap:** Model company, not consulting firm. Won't Terraform your VPC or deploy your LLM gateway.

## Layer 3: Strategic System Integrators

### Accenture

- Accenture Anthropic Business Group
- ~30,000 professionals receiving Claude training
- Engineers who embed Claude within client environments
- Positioned as full-service implementation partner for large enterprise

### Cognizant

- Deploying Claude to up to 350,000 employees globally
- Engineering platform integration with industry blueprints
- Pre-built integration patterns

### IBM

- Anthropic partnership for Claude integration into IBM software portfolio
- Contributing enterprise-grade reference architectures
- Open-source MCP community tooling

### ServiceNow / Salesforce

- Deep Anthropic partnerships
- Claude embedded in their platforms
- Relevant if enterprise already in those ecosystems

### deepsense.ai

- Official Anthropic Service Partner
- Structured "Jumpstart Packages" for idea-to-prototype
- Specific expertise in regulated sectors with data residency requirements

**Gap:** Sweet spot is $2M+ full-stack transformation. Many "trained professionals" completed certification, not production deployment. Too expensive and broad for a focused 12-week Claude Code rollout.

## Layer 4: LLM Gateway Products

### LiteLLM

- Open-source self-hosted or enterprise cloud
- SOC 2 / ISO 27001 certifications (enterprise tier)
- 100+ LLM provider support including Bedrock
- Built-in spend tracking, rate limiting, user management
- Active community, Python-based

### Kong AI Gateway

- Extension of Kong API Gateway
- Enterprise support contracts
- Best for organizations already using Kong

### Portkey

- Managed gateway with observability focus
- Strong analytics and monitoring dashboards
- SaaS-first approach

These are products, not consultancies. Enterprises either self-host with their platform engineering team or hire separately for setup.
