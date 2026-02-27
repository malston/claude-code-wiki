---
title: "Security Constraint Clarification"
weight: 6
---

# Security Constraint Clarification

## First Conversation with the CISO

"No code leaves the network" has three interpretations that lead to completely different architectures. **Get written alignment before doing anything else.**

### Level 1: "No code to Anthropic directly"

**What it means:** Route through a cloud provider's managed service (AWS Bedrock, Google Vertex AI). The enterprise's contract is with AWS/GCP, not Anthropic directly. Data isn't retained, isn't used for training.

**Architecture:** Claude Code → Bedrock (standard) or Vertex AI (standard)

**Complexity:** Low. Standard Bedrock/Vertex setup with IAM controls.

### Level 2: "No code traverses the public internet"

**What it means:** All traffic stays within the cloud provider's private backbone. No internet gateway, no NAT, no public IPs in the request path.

**Architecture:** Claude Code → Corporate Network → VPC Endpoint (PrivateLink) → Bedrock → Claude models

**Complexity:** Medium. Requires VPC endpoint configuration, Direct Connect or Site-to-Site VPN, and an LLM gateway.

**This is what most regulated enterprises (banking, healthcare, defense contractors) actually mean.** Wells Fargo, JPMorgan, and similar shops operate at this level.

### Level 3: "Truly air-gapped, zero external connectivity"

**What it means:** No connection to any external cloud service whatsoever. All inference must run on-premises.

**Architecture:** Claude Code **cannot work** in this scenario. Alternatives:

- **Tabnine on-prem** ($59/user/month, Kubernetes-based self-hosted)
- **Self-hosted open models** (Code Llama, DeepSeek-Coder) via Ollama or vLLM
- Quality drops **significantly** compared to Claude Sonnet/Opus for agentic coding tasks

**This is a fundamentally different engagement** if the customer truly means Level 3.

## Decision Matrix

| Requirement                | Level 1     | Level 2     | Level 3                |
| -------------------------- | ----------- | ----------- | ---------------------- |
| Claude Code works          | ✅          | ✅          | ❌                      |
| Data not sent to Anthropic | ✅          | ✅          | ✅                      |
| No public internet transit | ❌          | ✅          | ✅                      |
| Zero external connectivity | ❌          | ❌          | ✅                      |
| Infrastructure complexity  | Low         | Medium      | High (different tool)  |
| Model quality              | Full Claude | Full Claude | Significantly degraded |

## Recommendation

Assume Level 2 unless told otherwise. Schedule a 30-minute CISO alignment meeting before any architecture work begins. Get the decision documented in writing -- it will be referenced throughout the engagement.
