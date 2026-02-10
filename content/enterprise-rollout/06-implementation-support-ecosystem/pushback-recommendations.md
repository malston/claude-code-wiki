---
title: "Common Customer Requests — Pushback Recommendations"
weight: 2
---

# Common Customer Requests — Pushback Recommendations

Things the customer will probably ask for that should be redirected.

## "Can we run Claude locally on-prem?"

**Answer:** No. Anthropic doesn't offer self-hosted model deployment. The Bedrock/Vertex path with PrivateLink is the closest you get — data stays within the cloud provider's private backbone and never touches the public internet.

**If they truly need on-prem inference:** The conversation shifts to open-source models (Code Llama, DeepSeek-Coder, StarCoder) via Ollama or vLLM. Quality drops significantly for agentic coding tasks. This is a fundamentally different engagement.

## "Can we restrict which files Claude can see?"

**Answer:** Yes — deny rules in managed settings block specific file patterns. But be thoughtful.

**Pushback:** Over-restricting context makes Claude dramatically less useful. The better pattern is compartmentalized repos with appropriate access controls. Within a repo, block specific sensitive paths (secrets, credentials, PII). Don't blanket-deny read access — Claude needs to read code to help.

## "Can we review every AI suggestion before it hits code?"

**Answer:** Claude Code already has a permission model for this — it asks before writing files or executing commands.

**Pushback:** At 500 developers, per-action approval overhead kills adoption. Better approach:

- Trust Claude for low-risk operations (reading files, generating tests, writing docs)
- Gate high-risk operations through the existing code review process
- All AI-generated code goes through normal PR review regardless
- The reviewer knows Claude was used and reviews accordingly

## "Can we use this to replace our SAST/DAST tools?"

**Answer:** No. Claude's security review is non-deterministic — the same code might pass one review and fail another. Audit teams can't rely on non-reproducible results.

**Recommendation:** Use Claude's /security-review as a *complement* to deterministic SAST/DAST tools (Semgrep, Snyk, SonarQube) in CI/CD. AI catches business logic issues that rule-based tools miss. Rule-based tools catch known patterns reliably every time. Both together provide better coverage than either alone.

## "Can we default to Opus for everyone?"

**Answer:** Technically yes. Financially inadvisable.

**Pushback:** Opus costs significantly more per-token than Sonnet. At 500 developers, defaulting to Opus could be 3–5x the cost of Sonnet. Most routine coding tasks (code generation, test writing, refactoring) produce equivalent quality on Sonnet. Reserve Opus for architecture work, complex debugging, and senior engineers who demonstrably benefit from it.

## "Can we build 30 skills before the rollout?"

**Answer:** You can, but you shouldn't.

**Pushback:** Start with 5–8 org-wide skills. Skills should be created because developers asked for them based on real workflows, not because the platform team anticipated they might be useful. Cohort 1 developers co-create skills from their actual work patterns. Untested skills waste context budget and add confusion.

## "Can we skip the phased rollout and launch to everyone?"

**Answer:** Strongly discouraged.

**Pushback:** Cohort 1 discovers infrastructure issues (inference profiles, caching behavior, model availability). Cohort 2 discovers scale issues (rate limiting, budgets, team-level patterns). Without these discovery phases, 500 developers hit every issue simultaneously, overwhelming support and creating a negative first impression that's hard to recover from.
