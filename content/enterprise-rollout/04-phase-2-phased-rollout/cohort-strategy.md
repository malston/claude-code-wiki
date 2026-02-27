---
title: "Phased Rollout -- Cohort Strategy"
linkTitle: "Cohort Strategy"
weight: 1
---

# Phased Rollout -- Cohort Strategy

## Principle

Don't light up 500 developers at once. Each cohort discovers different classes of issues and builds institutional knowledge for the next cohort.

## Cohort 1: Power Users (25 developers, Weeks 5–6)

### Selection Criteria

- Hand-picked across 3–4 teams representing different technology stacks
- Mix of senior engineers (who know the patterns) and enthusiastic mid-levels (who'll push boundaries)
- At least one developer per major codebase
- Include developers who are already CLI/terminal-native

### Objectives

- Validate infrastructure end-to-end (Bedrock routing, gateway, PrivateLink)
- Test managed-settings.json enforcement -- do the deny rules work? Does bypass mode stay disabled?
- Write the first project CLAUDE.md and agent_docs/ files for their repos
- Co-create the initial 5–8 org-wide skills based on real workflows
- Become internal champions who can support Cohort 2

### Expected Discoveries

- Bedrock inference profiles required for on-demand usage (common first gotcha)
- Prompt caching behavior differs from direct API
- Some model versions lag behind on Bedrock
- Specific CLAUDE.md instructions that Claude follows well vs. ignores
- MCP servers that are most valuable for the org's toolchain
- Skills that need more or fewer steps than initially designed
- Edge cases in deny rules (false positives blocking legitimate work)

### Success Metrics

- All 25 developers able to use Claude Code through the enterprise infrastructure
- At least 3 project CLAUDE.md files written and reviewed
- At least 5 org-wide skills tested and iterated
- Zero security policy violations (deny rules holding)
- Qualitative feedback: "This makes me faster" vs. "This gets in the way"

### Platform Team Commitment

- Daily Slack channel for issues during first week
- 30-minute stand-up twice per week with Cohort 1
- Same-day turnaround on configuration issues

## Cohort 2: Full Teams (100 developers, Weeks 7–9)

### Selection Criteria

- Expand to complete teams (not just individual developers)
- Include at least one team that's skeptical -- they'll surface real objections
- Include the team with the most complex codebase

### Objectives

- Stress-test the LLM gateway's rate limiting and budget model
- Validate that team-level CLAUDE.md and skills work across a full team
- Discover the actual cost model (tokens per developer per day)
- Instrument OpenTelemetry metrics

### New Infrastructure Requirements

- Gateway rate limiting tuned based on Cohort 1 usage patterns
- Per-team token budgets configured
- CloudWatch dashboards showing per-user token consumption, latency percentiles, error rates
- Cost allocation tags in AWS for team-level billing

### Expected Discoveries

- Real-world token consumption rates (expect 50K–200K tokens/developer/day depending on usage intensity)
- Teams that use Claude Code very differently (some use it for code gen, others for review, others for documentation)
- Teams that need different model access (Opus for architecture work, Sonnet for routine coding)
- Edge cases in project CLAUDE.md that only surface with diverse usage patterns

### Success Metrics

- Gateway handles 100 concurrent developers without latency spikes
- Per-team budgets prevent runaway costs
- At least 80% of developers reporting increased productivity
- Zero infrastructure outages
- Cost model validated and predictable

### Platform Team Commitment

- Slack channel continues, monitored 8am–6pm
- Weekly office hours for questions
- Bi-weekly feedback surveys

## Cohort 3: Full Organization (375 developers, Weeks 10–12)

### Prerequisites (Must Be True Before Launching)

- Gateway proven at 100-developer scale
- Managed-settings.json deployed to all developer machines via MDM
- Internal documentation written by Cohort 1 champions
- Onboarding guide tested with Cohort 2 (developers who weren't hand-picked)
- Cost projections validated and approved by finance
- CISO sign-off on the security architecture still current

### Rollout Approach

- Department-by-department, not all-at-once
- Each department gets a 15-minute onboarding session led by a Cohort 1/2 champion
- Self-service documentation available for async onboarding
- Platform team monitors gateway metrics for capacity issues

### Expected Discoveries

- Long-tail support issues from developers with non-standard setups
- Teams that need custom skills not anticipated during Cohort 1/2
- Organizational patterns in how different teams use Claude Code
- Real productivity data at scale for leadership reporting

### Success Metrics

- 90%+ of developers have used Claude Code at least once within 2 weeks of access
- Weekly active usage rate > 60% after first month
- Support ticket volume declining (not growing) after first 2 weeks
- Total cost within 10% of projection
- No security incidents

## Rollback Plan

### Principle

Rollback is cohort-level, not all-or-nothing. If a cohort encounters serious issues, pause that cohort while earlier cohorts continue operating.

### Rollback Triggers

- Security incident (deny rule bypass, data exposure)
- Infrastructure instability (gateway outages, Bedrock throttling) affecting developer productivity
- Cost significantly exceeding projections (>25% over forecast)
- Widespread negative developer feedback (>40% reporting "gets in the way" rather than "makes me faster")

### Rollback Actions by Severity

**Pause (reversible):** Disable the gateway route for the affected cohort's users. Developers can't reach Claude Code but nothing is uninstalled. Resume when the issue is resolved.

**Reconfigure:** Push updated managed-settings.json via MDM to tighten deny rules, change model routing, or adjust budgets. No developer action required.

**Full rollback:** Remove Claude Code from developer machines via MDM. Remove managed-settings.json and managed CLAUDE.md. This is the nuclear option -- use only if a fundamental security concern is discovered.

### What Rollback Does NOT Require

- Reverting code already written with Claude Code -- it's in git like any other code
- Removing CLAUDE.md files from repos -- they're inert without the CLI
- Canceling the Bedrock account -- infrastructure can stay warm for re-engagement

### Re-Engagement After Rollback

If you roll back a cohort, fix the root cause and re-launch with a smaller pilot (5-10 developers) before re-expanding. Don't re-launch at the previous cohort size until the fix is validated.

## Timeline Summary

```text
Week 1-4:  Phase 0 -- Infrastructure build
Week 3-6:  Phase 1 -- Platform engineering (overlapping)
Week 5-6:  Cohort 1 -- 25 power users
Week 7-9:  Cohort 2 -- 100 full teams
Week 10-12: Cohort 3 -- 375 remaining developers
Week 12+:  Phase 3 -- Ongoing governance and optimization
```
