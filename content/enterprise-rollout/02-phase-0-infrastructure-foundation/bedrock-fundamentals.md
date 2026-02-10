---
title: "Amazon Bedrock Fundamentals"
weight: 1
---

# Amazon Bedrock Fundamentals

## What Is Amazon Bedrock?

Bedrock is AWS's managed API gateway for foundation models. Instead of going directly to Anthropic for model access, Bedrock gives you a single AWS-native service that brokers access to foundation models through the same IAM, billing, networking, and compliance infrastructure you already use for everything else in AWS.

**Analogy for Cloud Foundry practitioners:** If Cloud Foundry abstracts away infrastructure for app developers, Bedrock does the same for model inference. Developers don't think about where Claude is running — they just call the API. The platform team controls the networking, access, cost, and compliance layer underneath.

## Key Properties for Enterprise Deployment

### Managed Inference, Not Model Hosting

You don't deploy models, manage GPU clusters, or deal with scaling. You call `InvokeModel` or `InvokeModelWithResponseStream`, and Bedrock handles the rest. AWS runs the Claude models in their infrastructure under a contractual relationship with Anthropic.

### Data Boundary Guarantees

- Customer inputs and outputs are **not** used to train or improve foundation models
- Data is **not** shared with model providers (Anthropic)
- Data is **not** stored beyond immediate request processing (unless you explicitly enable logging)
- Your code/prompts go to AWS, not to Anthropic directly

### Inherits the AWS Security Stack

- **IAM policies** control who can invoke which models
- **CloudTrail** logs every API call
- **VPC endpoints via PrivateLink** keep traffic off the public internet
- **KMS encryption** for data at rest
- **Compliance certifications:** SOC 2, HIPAA, FedRAMP, etc.

### Pricing Model

- **On-demand:** Pay-per-token, no upfront commitment
- **Provisioned throughput:** Guaranteed capacity — at 500 developers, you'll likely need this for at least Sonnet
- **Prompt caching:** Reduces cost and latency for repeated context patterns

## How Claude Code Talks to Bedrock

Normally, Claude Code calls `api.anthropic.com` directly. Setting `CLAUDE_CODE_USE_BEDROCK=1` switches it to the AWS SDK's Bedrock runtime client. The Claude models are the same — same Sonnet, same Opus, same capabilities — but the request path changes:

```text
Without Bedrock:
  developer laptop → internet → api.anthropic.com → Claude model

With Bedrock:
  developer laptop → corporate network → Bedrock endpoint → Claude model (in AWS)

With Bedrock + PrivateLink:
  developer laptop → corporate network → VPC endpoint (PrivateLink) → Bedrock → Claude
  (nothing touches the public internet at any point)
```

### Dual-Model Usage

Claude Code uses **two models simultaneously:**

- **Primary model** (Sonnet or Opus): Heavy reasoning, code generation, analysis
- **Fast model** (Haiku): Lightweight tasks — summarization, classification, quick checks

Both must be enabled in Bedrock's model access settings.

## Known Gotchas

### Inference Profiles Required

Bedrock requires **inference profiles** (cross-region model identifiers) rather than bare model IDs for on-demand throughput:

```
# Won't work:
anthropic.claude-sonnet-4-5

# Correct:
us.anthropic.claude-sonnet-4-5-20250929-v1:0
```

This trips up almost everyone on initial setup.

### Model Availability Lag

Bedrock sometimes lags Anthropic's direct API in model availability by days or weeks when new versions release.

### Haiku Version Pinning

For Bedrock users, Claude Code will not automatically upgrade from Haiku 3.5 to Haiku 4.5. Set `ANTHROPIC_DEFAULT_HAIKU_MODEL` explicitly:

```bash
export ANTHROPIC_DEFAULT_HAIKU_MODEL='us.anthropic.claude-haiku-4-5-20251001-v1:0'
```

### Prompt Caching Differences

Prompt caching behavior differs between direct API and Bedrock. Test caching behavior during Cohort 1 and adjust configuration accordingly.

## Provider Comparison

Bedrock is the recommended path for AWS-native organizations, but Claude Code also supports two other cloud providers that offer the same "no code leaves your network" guarantee. Each has a dedicated guide in this section:

- **[Google Vertex AI Fundamentals](../vertex-fundamentals/)** -- VPC Service Controls, Private Google Access, Workload Identity, Cloud Interconnect
- **[Azure Foundry Fundamentals](../foundry-fundamentals/)** -- Private Endpoints, VNet integration, managed identities, ExpressRoute

### Provider Selection

| Factor                  | Bedrock                         | Vertex AI                      | Azure Foundry                   |
| ----------------------- | ------------------------------- | ------------------------------ | ------------------------------- |
| Set via                 | `CLAUDE_CODE_USE_BEDROCK=1`     | `CLAUDE_CODE_USE_VERTEX=1`     | `CLAUDE_CODE_USE_FOUNDRY=1`     |
| Auth skip (for gateway) | `CLAUDE_CODE_SKIP_BEDROCK_AUTH` | `CLAUDE_CODE_SKIP_VERTEX_AUTH` | `CLAUDE_CODE_SKIP_FOUNDRY_AUTH` |
| Network isolation       | VPC PrivateLink                 | VPC Service Controls           | Private Endpoints               |
| Best for                | AWS-native orgs                 | GCP-native orgs                | Azure-native orgs               |

The platform engineering layer (Phase 1) and rollout strategy (Phase 2) are provider-agnostic -- only Phase 0 infrastructure changes if you use a different provider.
