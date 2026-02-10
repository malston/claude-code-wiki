---
title: "Market Opportunity Analysis"
weight: 2
---

# Market Opportunity Analysis

## The Gap in the Implementation Landscape

### Layer 1: AWS (Infrastructure Plumbing)

- **AWS Solutions Architects** (free with account): VPC endpoint setup, Direct Connect, IAM policy design
- **AWS Professional Services** (paid): Hands-on implementation. Reference architecture "Guidance for Claude Code with Amazon Bedrock" deployable in hours
- **AWS Partner Network consultancies** (Accenture, Deloitte, Slalom): Routine networking/security work
- **Gap:** Excellent at infrastructure plumbing. No depth on Claude Code configuration, skills architecture, or developer experience.

### Layer 2: Anthropic (Product Expertise)

- **Claude for Enterprise plan:** SSO, domain capture, RBAC, Compliance API, managed policy settings for org-wide Claude Code configs
- **Enterprise sales team:** Contractual/compliance side — DPAs, security questionnaires, Compliance API
- **Gap:** Model company, not consulting firm. Won't Terraform your VPC or deploy your LLM gateway.

### Layer 3: Strategic System Integrators (Enterprise Relationships)

- **Accenture:** Accenture Anthropic Business Group, ~30,000 trained professionals, full-stack transformation
- **Cognizant:** Deploying Claude to 350,000 employees, engineering platform integration, industry blueprints
- **IBM:** Claude integration into software portfolio, contributing enterprise reference architectures and open-source MCP tooling
- **deepsense.ai:** Official Anthropic Service Partner, "Jumpstart Packages" for regulated sectors
- **Gap:** Sweet spot is $2M+ full-stack transformation. Many "trained professionals" completed certification, not production deployment.

### Layer 4: LLM Gateway Products

- **LiteLLM:** Enterprise cloud with SOC 2/ISO 27001 — or self-hosted open-source
- **Kong AI Gateway:** Enterprise support contracts, existing Kong customers
- **Portkey:** Managed gateway with observability focus
- **Gap:** Products, not consultancies. Enterprises self-host with platform engineering team or hire separately.

## The Unserved Middle Layer

**Nobody** is doing the middle layer well — the consultant who understands:

1. Infrastructure (VPC endpoints, IAM, networking)
2. Claude Code platform engineering (skills, CLAUDE.md hierarchy, MCP server design, developer experience)
3. Change management (phased rollout, champion programs, productivity measurement)

### Engagement Characteristics

- 6–12 week implementation
- $150K–$300K depending on complexity
- Too small for Accenture individually
- Too infrastructure-heavy for Anthropic
- Too Claude-specific for a generic AWS consultancy
- **This is the gap a platform engineering consultant with deep Claude Code expertise fills**

### Three Workstreams

1. **Infrastructure (30% effort):** Bedrock + PrivateLink + LLM gateway
2. **Platform engineering (40% effort):** Managed configs, skills library, developer environments
3. **Change management (30% effort):** Phased rollout, champion program, productivity measurement

Infrastructure is the minority of effort. The other 70% is platform and people work — where enterprises consistently underinvest.
