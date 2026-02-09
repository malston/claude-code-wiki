# Build-Out Timeline — 12-Week Implementation

## Week-by-Week Schedule

### Weeks 1–2: Discovery and Infrastructure Design

**Infrastructure Workstream**

- CISO alignment meeting: define "no code leaves network" (Level 1, 2, or 3)
- Design AWS account structure for Bedrock isolation
- Design VPC endpoint + PrivateLink architecture
- Evaluate LLM gateway options (LiteLLM vs. Kong vs. Portkey)
- Begin Terraform for VPC endpoint and networking

**Platform Engineering Workstream**

- Inventory top 5 codebases by developer count
- Interview 2–3 senior engineers per codebase: "What do you always tell new developers? What patterns do people consistently get wrong?"
- Identify Cohort 1 candidates (25 power users)

**Change Management Workstream**

- Stakeholder mapping (CISO, VP Eng, team leads, finance)
- Draft communication plan for rollout announcement
- Establish success metrics with leadership

### Weeks 3–4: Infrastructure Build + Platform Design

**Infrastructure Workstream**

- Deploy VPC endpoint with PrivateLink
- Deploy LLM gateway (internal service)
- Configure gateway: SSO auth, rate limiting, logging
- End-to-end validation: developer laptop → gateway → VPC endpoint → Bedrock → Claude
- CISO review and sign-off on data flow

**Platform Engineering Workstream**

- Draft managed-settings.json baseline
- Draft org-level managed CLAUDE.md (~30 lines)
- Design context budget worksheet for each major codebase
- Design agent_docs/ directory structure template
- Draft initial 5–8 org-wide skills
- Configure MDM deployment for managed settings

**Change Management Workstream**

- Prepare Cohort 1 onboarding materials
- Set up Slack channel for Cohort 1 support
- Brief Cohort 1 candidates on timeline and expectations

### Weeks 5–6: Cohort 1 Launch + Platform Iteration

**Infrastructure Workstream**

- Monitor gateway under Cohort 1 load
- Tune rate limits and timeouts based on real usage
- Resolve Bedrock inference profile gotchas
- Validate prompt caching behavior

**Platform Engineering Workstream**

- Cohort 1 developers write first project CLAUDE.md files
- Cohort 1 tests and iterates org-wide skills
- Discover which instructions Claude follows well vs. ignores
- Iterate: rephrase instructions, move content between layers
- Begin agent_docs/ drafting for top codebases

**Change Management Workstream**

- Daily Slack support for Cohort 1 (first week)
- Twice-weekly stand-ups with Cohort 1
- Collect qualitative feedback: "makes me faster" vs. "gets in the way"
- Identify emerging champion candidates

### Weeks 7–8: Standardize + Cohort 2 Preparation

**Infrastructure Workstream**

- Scale gateway for 100-developer load
- Configure per-team token budgets
- Deploy CloudWatch dashboards (token usage, latency, costs)
- Instrument OpenTelemetry metrics

**Platform Engineering Workstream**

- Finalize managed CLAUDE.md based on Cohort 1 feedback
- Finalize org skills library — package as plugin or shared repo
- Create agent_docs/ template and style guide
- Create .claude/rules/ template with path-scoping examples
- Write developer onboarding guide: "How to write effective CLAUDE.md and skills"

**Change Management Workstream**

- Brief Cohort 2 teams
- Prepare Cohort 2 onboarding session (led by Cohort 1 champions)
- Publish internal documentation from Cohort 1 learnings

### Weeks 9–10: Cohort 2 + Cohort 3 Preparation

**Infrastructure Workstream**

- Monitor gateway at 100-developer scale
- Validate cost model and projections
- Address rate limiting and capacity issues
- Evaluate provisioned throughput need

**Platform Engineering Workstream**

- Each Cohort 2 team writes project CLAUDE.md and team skills using templates
- Platform team reviews and coaches — first pass usually too long, too vague, or mixing declarative/procedural
- Iterate based on developer feedback and token usage metrics
- Finalize all configuration for full rollout

**Change Management Workstream**

- Bi-weekly feedback surveys with Cohort 2
- Weekly office hours
- Prepare Cohort 3 materials
- Brief department leads on rollout plan
- Cost projections reviewed and approved by finance

### Weeks 11–12: Cohort 3 Full Rollout

**Infrastructure Workstream**

- Scale gateway for 500-developer load
- Activate alerting for capacity thresholds
- Final CISO review on security posture at scale

**Platform Engineering Workstream**

- Support remaining teams writing project CLAUDE.md
- Address edge cases and non-standard configurations
- Document all platform team processes for ongoing operations

**Change Management Workstream**

- Department-by-department rollout (not all-at-once)
- 15-minute onboarding sessions led by Cohort 1/2 champions
- Self-service documentation for async onboarding
- Monitor adoption metrics (daily active users, weekly active usage)
- Prepare leadership report: productivity data, cost actuals vs. projections, adoption rates

### Week 12+: Ongoing Operations (Phase 3)

- Quarterly CLAUDE.md and skills review cadence
- Monthly cost and usage reporting to finance and leadership
- Ongoing skills library development based on developer requests
- Model version updates as Anthropic releases new versions on Bedrock
- Continuous refinement of deny rules and security policies
- Annual CISO review of the security architecture

## Effort Distribution

| Workstream | % of Total Effort | Primary Owner |
|---|---|---|
| Infrastructure | 30% | Platform/DevOps team |
| Platform Engineering | 40% | Consultant + platform team |
| Change Management | 30% | Consultant + engineering leadership |

The infrastructure is 30% of effort but often gets 90% of attention. The other 70% — platform engineering and change management — is where the engagement delivers differentiated value.
