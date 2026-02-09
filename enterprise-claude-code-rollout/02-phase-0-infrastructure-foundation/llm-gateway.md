# LLM Gateway Design

## Why a Gateway?

The LLM gateway is the piece most enterprises skip and regret. Without it, you have 500 developer machines each holding AWS credentials and making direct Bedrock calls with no centralized visibility or control.

Deploy **LiteLLM** (open-source or enterprise cloud) or **Kong AI Gateway** as an internal service between developers and Bedrock.

## What the Gateway Provides

### Per-User/Per-Team Token Budgets and Rate Limiting

- Set monthly token budgets per team or per user
- Default to Sonnet for routine work, gate Opus access to specific use cases
- Prevent a single developer from burning through the entire org's budget

### Centralized Authentication

- The gateway holds AWS credentials for Bedrock — developers don't need AWS access
- Developers authenticate to the gateway via corporate SSO
- Eliminates 500 sets of AWS credentials on developer machines

### Request/Response Logging for Audit

- Log request metadata: who, when, which model, token count, latency
- Don't log prompt content if Zero Data Retention (ZDR) is active
- Feed metrics to CloudWatch or your observability stack

### Provider Abstraction

- Swap models or providers without touching developer configs
- Route to different models based on request characteristics
- A/B test model versions transparently

## Developer-Facing Configuration

Once the gateway is deployed, the developer config becomes three environment variables:

```bash
export CLAUDE_CODE_USE_BEDROCK=1
export ANTHROPIC_BEDROCK_BASE_URL='https://llm-gateway.internal.corp.com/bedrock'
export CLAUDE_CODE_SKIP_BEDROCK_AUTH=1  # Gateway handles AWS auth
```

These are baked into the managed-settings.json and deployed via MDM — developers don't configure them manually.

## Product Options

### LiteLLM

- **Open-source** self-hosted or **enterprise cloud** with SOC 2/ISO 27001
- Python-based, well-documented, active community
- Supports 100+ LLM providers including Bedrock
- Built-in spend tracking, rate limiting, and user management
- Good fit for teams that want control and flexibility

### Kong AI Gateway

- Extension of Kong API Gateway — many enterprises already use Kong
- Enterprise support contracts available
- Good fit for organizations already in the Kong ecosystem

### Portkey

- Managed gateway focused on observability
- Good analytics and monitoring dashboards
- SaaS-first approach — less control than self-hosted options

## Deployment Topology

```
┌─────────────────────────────────┐
│  LLM Gateway (internal service) │
│                                 │
│  Deployment: ECS/EKS or VM     │
│  URL: llm-gateway.internal.corp│
│  Auth: SSO / OIDC              │
│                                 │
│  Upstream: VPC Endpoint         │
│  (PrivateLink to Bedrock)       │
└─────────────────────────────────┘
```

The gateway runs as an internal service (ECS, EKS, or a VM) within the same VPC that has the Bedrock endpoint. It's accessible to developer machines via the corporate network but not exposed to the internet.

## Observability Integration

The gateway is the ideal point to instrument **OpenTelemetry metrics** pushed to CloudWatch:

- Per-user token consumption
- Latency percentiles (p50, p95, p99)
- Error rates by model and user
- Request volume over time
- Budget utilization per team

These metrics feed the dashboards that leadership and finance will want in Phase 3.
