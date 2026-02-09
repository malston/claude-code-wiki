# Cost Tracking and Budgets

## The Cost Challenge

Bedrock bills per-token. 500 developers using Opus for everything can cost $50K–$200K+/month depending on usage intensity. Without controls, costs are unpredictable and can spike when developers discover long-running agentic workflows.

## Model Tiering Strategy

The LLM gateway is the control point for cost management.

| Use Case | Model | Approx. Cost | Access |
|---|---|---|---|
| Routine coding, quick edits | Sonnet | Lower per-token | Default for all developers |
| Architecture, complex reasoning | Opus | Higher per-token | Gated to senior engineers or by request |
| Summarization, classification | Haiku | Lowest per-token | Claude Code uses automatically as fast model |

### Implementation

Configure the LLM gateway to:

- Default all requests to Sonnet
- Route to Opus only for users/teams with explicit Opus access
- Or allow developers to select via `ANTHROPIC_MODEL` but with higher budget scrutiny for Opus users

## Budget Controls

### Per-Team Monthly Budgets

Set via the LLM gateway. When a team reaches 80% of budget, warn the team lead. At 100%, throttle (don't hard-block) to prevent disruption.

### Per-User Daily Limits

Optional guardrail to prevent individual developers from consuming disproportionate resources. Set based on Cohort 1/2 usage data.

### Typical Usage Expectations

Based on industry data and Cohort 1 calibration:

- **Light users** (occasional queries): 20K–50K tokens/day
- **Moderate users** (regular code generation): 50K–150K tokens/day
- **Heavy users** (agentic workflows, long sessions): 150K–500K tokens/day

Expect 60% light, 30% moderate, 10% heavy across 500 developers.

## AWS Cost Visibility

### Cost Explorer

- Scope to the dedicated Bedrock AWS account
- Tag costs by team using gateway metadata → CloudWatch → Cost Allocation Tags
- Monthly cost reports to finance and engineering leadership

### CloudWatch Dashboards

Deploy dashboards showing:

- Total token consumption (daily, weekly, monthly)
- Per-team token consumption
- Per-model token consumption (Sonnet vs. Opus vs. Haiku)
- Cost trends and projections
- Top 10 users by consumption (for outlier detection, not surveillance)

## Prompt Caching

Bedrock supports prompt caching, which can significantly reduce costs for repeated context patterns (like CLAUDE.md and rules that load every session). Monitor cache hit rates during Cohort 1 and optimize:

- Stable context (CLAUDE.md, rules) benefits most from caching
- Frequently-changing context (code files) benefits less
- Prompt caching behavior on Bedrock may differ from direct API — test explicitly

## Provisioned Throughput

At 500 developers, on-demand Bedrock may hit rate limits during peak hours. Consider provisioned throughput for Sonnet to guarantee capacity. Provisioned throughput costs more but provides:

- Guaranteed request rate
- Predictable latency
- No throttling during peak usage

Evaluate after Cohort 2 based on observed peak concurrent usage.
