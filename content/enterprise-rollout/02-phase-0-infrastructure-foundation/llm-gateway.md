---
title: "LLM Gateway Design"
weight: 3
---

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

## Credential Management

### Gateway Holds AWS Credentials

The gateway authenticates to Bedrock using an IAM role (via instance profile or ECS task role). Developers never see AWS credentials. The `CLAUDE_CODE_SKIP_BEDROCK_AUTH` env var tells Claude Code to send requests without attempting AWS authentication -- the gateway adds credentials to the upstream request.

### Dynamic Credential Rotation with apiKeyHelper

If your gateway issues short-lived tokens to developers instead of using a shared gateway credential, use the `apiKeyHelper` setting in managed-settings.json:

```json
{
  "apiKeyHelper": "python3 /opt/claude-tools/get-gateway-token.py"
}
```

Claude Code calls this command to get a fresh API key. It's invoked on startup and automatically on 401 errors or when the cached token exceeds a 5-minute TTL. The command should output the token to stdout.

Use this when:

- The gateway requires per-user bearer tokens (not just SSO passthrough)
- Credentials rotate more frequently than session duration
- You need credential audit at the individual developer level beyond what SSO provides

## High Availability and Disaster Recovery

### Gateway HA

The LLM gateway is a single point of failure for 500 developers. Deploy for high availability:

- **ECS/EKS:** Minimum 2 replicas across 2 availability zones behind an internal Application Load Balancer
- **Health checks:** Configure ALB health checks against the gateway's health endpoint
- **Auto-scaling:** Scale based on request count and CPU utilization -- peak usage correlates with business hours

### Bedrock Availability

Bedrock is a managed service with AWS's standard SLA. Mitigations:

- **Cross-region inference profiles:** Bedrock supports cross-region inference profiles (e.g., `us.anthropic.claude-*`) that automatically route to available regions. Use these instead of region-specific model IDs.
- **Provisioned throughput:** Guarantees capacity and avoids throttling during peak usage (evaluate after Cohort 2)

### Direct Connect / VPN Redundancy

If the connection between corporate network and VPC goes down, all 500 developers lose access simultaneously.

- **Redundant connections:** Two Direct Connect circuits from different providers, or Direct Connect + Site-to-Site VPN as backup
- **Monitoring:** CloudWatch alarms on VPN tunnel status and Direct Connect connection state
- **Failover testing:** Test failover quarterly

### Degraded Mode

Define what happens during an outage:

- Developers fall back to manual coding (no AI assistance)
- No "degraded mode" where Claude Code routes elsewhere -- the managed settings lock routing to the internal gateway
- Communicate expected recovery time via Slack/status page
- Post-incident review if outage exceeds 30 minutes

## Observability Integration

The gateway is the ideal point to instrument **OpenTelemetry metrics** pushed to CloudWatch:

- Per-user token consumption
- Latency percentiles (p50, p95, p99)
- Error rates by model and user
- Request volume over time
- Budget utilization per team

These metrics feed the dashboards that leadership and finance will want in Phase 3.
