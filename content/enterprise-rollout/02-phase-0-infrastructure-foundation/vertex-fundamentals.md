---
title: "Google Vertex AI Fundamentals"
weight: 2
---

# Google Vertex AI Fundamentals

## What Is Vertex AI?

Vertex AI is Google Cloud's managed AI platform. Anthropic's Claude models are available as partner models through Vertex AI, giving you a GCP-native API that uses the same IAM, billing, networking, and compliance infrastructure you already use for everything else in Google Cloud.

**Analogy for Cloud Foundry practitioners:** Same abstraction as Bedrock -- developers call an API, the platform team controls networking, access, cost, and compliance underneath. The difference is which cloud's control plane you're working with.

## Key Properties for Enterprise Deployment

### Managed Inference, Not Model Hosting

You don't deploy models or manage GPU clusters. You call the Vertex AI prediction endpoint, and Google handles the rest. Google runs the Claude models in their infrastructure under a contractual relationship with Anthropic.

### Data Boundary Guarantees

- Customer inputs and outputs are **not** used to train or improve foundation models
- Data is **not** shared with model providers (Anthropic)
- Data is **not** stored beyond immediate request processing (unless you explicitly enable logging)
- Your code/prompts go to Google Cloud, not to Anthropic directly

### Inherits the Google Cloud Security Stack

- **IAM policies** control who can invoke which models (`roles/aiplatform.user`)
- **Cloud Audit Logs** log every API call
- **VPC Service Controls** keep traffic within a defined security perimeter
- **Private Google Access** keeps traffic off the public internet
- **CMEK encryption** for data at rest
- **Compliance certifications:** SOC 2, ISO 27001, HIPAA, FedRAMP, etc.

### Pricing Model

- **On-demand:** Pay-per-token, no upfront commitment
- **Provisioned throughput:** Guaranteed capacity (requires regional endpoints, not available on global)
- **Prompt caching:** Same pricing structure as direct API -- 90% discount on cache reads

## How Claude Code Talks to Vertex AI

Setting `CLAUDE_CODE_USE_VERTEX=1` switches Claude Code from calling `api.anthropic.com` to using the Google Cloud Vertex AI prediction endpoint. The Claude models are the same -- same Sonnet, same Opus, same capabilities -- but the request path changes:

```text
Without Vertex AI:
  developer laptop -> internet -> api.anthropic.com -> Claude model

With Vertex AI:
  developer laptop -> corporate network -> Vertex AI endpoint -> Claude model (in GCP)

With Vertex AI + VPC Service Controls + Private Google Access:
  developer laptop -> corporate network -> restricted.googleapis.com -> Vertex AI -> Claude
  (nothing touches the public internet at any point)
```

### Environment Variables

#### Required

| Variable                      | Example                | Purpose                       |
| ----------------------------- | ---------------------- | ----------------------------- |
| `CLAUDE_CODE_USE_VERTEX`      | `1`                    | Enables Vertex AI integration |
| `CLOUD_ML_REGION`             | `us-east5` or `global` | Sets the endpoint region      |
| `ANTHROPIC_VERTEX_PROJECT_ID` | `my-gcp-project`       | Identifies the GCP project    |

#### Optional

| Variable                        | Example                     | Purpose                                                          |
| ------------------------------- | --------------------------- | ---------------------------------------------------------------- |
| `ANTHROPIC_MODEL`               | `claude-opus-4-6`           | Overrides the primary model                                      |
| `ANTHROPIC_SMALL_FAST_MODEL`    | `claude-haiku-4-5@20251001` | Overrides the small/fast model                                   |
| `ANTHROPIC_DEFAULT_HAIKU_MODEL` | `claude-haiku-4-5@20251001` | Manual Haiku upgrade (Vertex won't auto-upgrade from 3.5 to 4.5) |
| `CLAUDE_CODE_SKIP_VERTEX_AUTH`  | `1`                         | Skips Vertex auth (for LiteLLM proxy setups)                     |
| `ANTHROPIC_VERTEX_BASE_URL`     | URL                         | Custom base URL (for LiteLLM/gateway pass-through)               |
| `DISABLE_PROMPT_CACHING`        | `1`                         | Disables prompt caching                                          |

#### Per-Model Region Overrides (when `CLOUD_ML_REGION=global`)

| Variable                          | Example        |
| --------------------------------- | -------------- |
| `VERTEX_REGION_CLAUDE_3_5_HAIKU`  | `us-east5`     |
| `VERTEX_REGION_CLAUDE_4_0_SONNET` | `us-east5`     |
| `VERTEX_REGION_CLAUDE_4_0_OPUS`   | `europe-west1` |

Authentication falls back through: `ANTHROPIC_VERTEX_PROJECT_ID` -> `GCLOUD_PROJECT` -> `GOOGLE_CLOUD_PROJECT` -> `GOOGLE_APPLICATION_CREDENTIALS`.

### Dual-Model Usage

Claude Code uses **two models simultaneously:**

- **Primary model** (Sonnet or Opus): Heavy reasoning, code generation, analysis
- **Fast model** (Haiku): Lightweight tasks -- summarization, classification, quick checks

Both must be available in your Vertex AI project. Defaults on Vertex: Sonnet 4.5 (primary) and Haiku 4.5 (fast).

### Model ID Format

Vertex AI uses a different model ID format than Bedrock or the direct API:

| Provider   | Format                                                   | Example                                        |
| ---------- | -------------------------------------------------------- | ---------------------------------------------- |
| Vertex AI  | `claude-{tier}-{version}@{date}`                         | `claude-sonnet-4-5@20250929`                   |
| Bedrock    | `{region}.anthropic.claude-{tier}-{version}-{date}-v1:0` | `us.anthropic.claude-sonnet-4-5-20250929-v1:0` |
| Direct API | `claude-{tier}-{version}-{date}`                         | `claude-sonnet-4-5-20250929`                   |

Current Vertex AI model IDs:

| Model             | Vertex AI Model ID           |
| ----------------- | ---------------------------- |
| Claude Opus 4.6   | `claude-opus-4-6`            |
| Claude Opus 4.5   | `claude-opus-4-5@20251101`   |
| Claude Sonnet 4.5 | `claude-sonnet-4-5@20250929` |
| Claude Haiku 4.5  | `claude-haiku-4-5@20251001`  |

## Region Availability

### Regional Endpoints

**United States:** `us-east1`, `us-east4`, `us-east5`, `us-central1`, `us-south1`, `us-west1`, `us-west4`

**Europe:** `europe-west1`, `europe-west4`

**Asia Pacific:** `asia-southeast1`, `asia-east1`

### Global vs. Regional Endpoints

| Feature                | Global                        | Regional                                    |
| ---------------------- | ----------------------------- | ------------------------------------------- |
| Routing                | Dynamic, maximum availability | Fixed to specified region                   |
| Data residency         | Not guaranteed                | Guaranteed                                  |
| Pricing                | Standard                      | 10% premium (Sonnet 4.5+ and future models) |
| Provisioned throughput | Not supported                 | Supported                                   |

**Gotcha:** Not all Claude models support the global endpoint. If a model doesn't support it and you have `CLOUD_ML_REGION=global`, you get 404 errors. Use `VERTEX_REGION_<MODEL_NAME>` overrides for those models.

## Known Gotchas

### Model Availability Lag

Vertex AI may lag behind Anthropic's direct API when new model versions release. Check [Model Garden](https://console.cloud.google.com/vertex-ai/model-garden) for current availability. Model access may require explicit request and 24--48 hours for approval.

### Haiku Version Pinning

Claude Code will **not** automatically upgrade from Haiku 3.5 to Haiku 4.5 on Vertex. Set `ANTHROPIC_DEFAULT_HAIKU_MODEL` explicitly:

```bash
export ANTHROPIC_DEFAULT_HAIKU_MODEL='claude-haiku-4-5@20251001'
```

### Prompt Caching Differences

Prompt caching on Vertex AI works the same as the direct API, with two nuances:

- Caches are **isolated per GCP project** (not shared across projects)
- Google treats prompt cache hashes as "User Metadata" rather than "Customer Data" -- a data governance nuance worth noting for compliance teams

### Authentication

The `/login` and `/logout` commands are disabled when using Vertex AI. Authentication is handled entirely through Google Cloud credentials (`gcloud auth application-default login`).

### Environment Variable Presence

Having Vertex environment variables set (regardless of value) may trigger Vertex AI detection. Unset them completely when switching providers.

## VPC Service Controls and Private Google Access

This is the GCP equivalent of AWS VPC PrivateLink. VPC Service Controls create a security perimeter around your GCP project, and Private Google Access routes traffic to Google APIs without traversing the public internet.

### Architecture

```
┌──────────────────────────────────────────────────────┐
│  VPC Service Controls Perimeter                       │
│                                                       │
│  ┌─────────────────┐    ┌──────────────────────────┐ │
│  │ Developer VMs /  │    │ Vertex AI                │ │
│  │ GKE Cluster      │───>│ (aiplatform.googleapis)  │ │
│  │                  │    │                          │ │
│  └─────────────────┘    └──────────────────────────┘ │
│          │                                            │
│          │  Private Google Access                     │
│          │  (restricted.googleapis.com)               │
│          │  199.36.153.4/30                           │
└──────────│───────────────────────────────────────────┘
           │
    Cloud Interconnect / Partner Interconnect / Cloud VPN
           │
    ┌──────────────┐
    │ Corporate    │
    │ Network      │
    └──────────────┘
```

### Key Terraform Resources

**IMPORTANT:** GCP enforces a hard limit of one Access Context Manager access policy per organization. If your org already has an access policy, you MUST use a `data` source to reference it instead of creating a new one. The example below assumes no existing policy -- for enterprise deployments, replace the `resource` with `data "google_access_context_manager_access_policy" "existing"` and reference `var.access_policy_name`.

```hcl
# Access policy (organization-level, one per org)
# WARNING: This will fail if your org already has an access policy
# Use data source instead: data "google_access_context_manager_access_policy" "existing"
resource "google_access_context_manager_access_policy" "policy" {
  parent = "organizations/${var.org_id}"
  title  = "Claude Code VPC-SC Policy"
}

# Access level: allow traffic from corporate IP ranges
resource "google_access_context_manager_access_level" "corporate" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/accessLevels/corporate_access"
  title  = "Corporate Network Access"

  basic {
    conditions {
      ip_subnetworks = var.corporate_cidr_ranges
    }
  }
}

# Service perimeter: restrict Vertex AI to the project
resource "google_access_context_manager_service_perimeter" "vertex_perimeter" {
  parent = "accessPolicies/${google_access_context_manager_access_policy.policy.name}"
  name   = "accessPolicies/${google_access_context_manager_access_policy.policy.name}/servicePerimeters/vertex_ai_perimeter"
  title  = "Vertex AI Perimeter"

  status {
    restricted_services = ["aiplatform.googleapis.com"]
    resources           = ["projects/${var.project_number}"]
    access_levels       = [google_access_context_manager_access_level.corporate.name]
  }
}
```

### Private Google Access DNS Configuration

Configure DNS to resolve `*.googleapis.com` to `restricted.googleapis.com` (199.36.153.4/30). This ensures all API traffic -- including Vertex AI calls -- routes through Google's private backbone rather than the public internet.

Use `restricted.googleapis.com` (not `private.googleapis.com`) when deploying with VPC Service Controls. The restricted domain only allows access to APIs supported by VPC-SC, blocking access to unsupported APIs as a defense-in-depth measure.

Enable Private Google Access on all VPC subnets so VMs and GKE nodes without external IPs can reach Vertex AI.

### Dedicated GCP Project

Anthropic recommends a **dedicated GCP project** for Claude Code usage. Benefits:

- **Cost attribution:** All Vertex AI costs in one project, simple to track
- **IAM boundaries:** Separate IAM policies from production workloads
- **Audit scoping:** Cloud Audit Logs scoped to the Claude project
- **VPC-SC isolation:** Simpler perimeter configuration

### Validation Checklist

- [ ] VPC Service Controls perimeter configured with `aiplatform.googleapis.com`
- [ ] DNS resolves `*.googleapis.com` to `restricted.googleapis.com` (199.36.153.4/30)
- [ ] Private Google Access enabled on all relevant subnets
- [ ] Cloud Audit Logs enabled for Vertex AI API calls
- [ ] Cloud Interconnect / VPN connection verified with latency < 50ms
- [ ] Claude Code successfully invokes model through the private path
- [ ] No public internet egress observed in VPC flow logs during Claude Code usage

**Important:** VPC Service Controls changes can take **up to 30 minutes** to propagate after a successful API response. Plan for this during initial setup and testing.

## Gateway Deployment on GCP

The LLM gateway pattern is the same regardless of cloud provider -- see [LLM Gateway Design](../llm-gateway/) for the full rationale. This section covers GCP-specific deployment details.

### Developer-Facing Configuration

```bash
export CLAUDE_CODE_USE_VERTEX=1
export ANTHROPIC_VERTEX_BASE_URL='https://llm-gateway.internal.corp.com/vertex'
export CLAUDE_CODE_SKIP_VERTEX_AUTH=1  # Gateway handles GCP auth
```

### Deployment Topology

```
┌─────────────────────────────────────┐
│  LLM Gateway (internal service)     │
│                                     │
│  Deployment: Cloud Run or GKE      │
│  URL: llm-gateway.internal.corp    │
│  Auth: SSO / OIDC                  │
│                                     │
│  Upstream: Vertex AI endpoint       │
│  (via Private Google Access)        │
└─────────────────────────────────────┘
```

### Credential Management via Workload Identity

The gateway authenticates to Vertex AI using **Workload Identity Federation** -- no service account keys needed.

**For GKE:**

1. Enable Workload Identity Federation on the cluster
2. Create a Kubernetes ServiceAccount for the gateway
3. Grant `roles/aiplatform.user` directly to the Kubernetes principal:
   ```
   principal://iam.googleapis.com/projects/<PROJECT_NUMBER>/locations/global/workloadIdentityPools/<PROJECT_ID>.svc.id.goog/subject/ns/<NAMESPACE>/sa/<KSA_NAME>
   ```

**For Cloud Run:** Assign `roles/aiplatform.user` to the Cloud Run service's service account. No additional configuration needed.

### GCP-Specific Observability

Push **OpenTelemetry metrics** to Cloud Monitoring:

- Per-user token consumption
- Latency percentiles (p50, p95, p99)
- Error rates by model and user
- Request volume over time
- Budget utilization per team

## Corporate Network Connectivity

| Option                       | Bandwidth               | Description                                                       |
| ---------------------------- | ----------------------- | ----------------------------------------------------------------- |
| **Dedicated Interconnect**   | 10--100 Gbps            | Direct physical connection at a Google colocation facility        |
| **Partner Interconnect**     | 50 Mbps--50 Gbps        | Connection through a service provider already connected to Google |
| **HA Cloud VPN**             | Up to 3 Gbps per tunnel | Encrypted IPsec tunnels over the internet                         |
| **Cross-Cloud Interconnect** | 10--100 Gbps            | Direct connection between GCP and another cloud provider          |

All options support Cloud Router for dynamic BGP routing. For enterprise Vertex AI deployments, Dedicated or Partner Interconnect is recommended to keep AI inference traffic off the public internet.

### Redundancy

- **Redundant connections:** Two Interconnect circuits from different providers, or Interconnect + HA VPN as backup
- **Monitoring:** Cloud Monitoring alerts on Interconnect attachment status and VPN tunnel state
- **Failover testing:** Test failover quarterly

## Provider Comparison

For a side-by-side comparison of Bedrock, Vertex AI, and Azure Foundry, see the [Provider Selection table in Amazon Bedrock Fundamentals](../bedrock-fundamentals/#provider-comparison).
