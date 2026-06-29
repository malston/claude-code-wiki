---
title: "ROI Framework"
weight: 3
---

# ROI Framework

This is a decision framework for a company weighing a per-seat purchase of Claude Enterprise as a broad enterprise AI investment. It gives you a model you can fill with your own numbers, a worked example, and the places the math usually lies.

You do not need to invent a methodology. This composes three established layers: a financial chassis (TCO, NPV, payback), an audit-ready wrapper (Forrester Total Economic Impact), and a measurement layer for the benefit side (DORA and SPACE for engineering, time-and-task studies for everyone else). The point of writing it down once is so the executive summary and the cost-tracking pages can reference the same math instead of each re-deriving it.

## The Equation

```text
ROI = (Risk-adjusted annual benefit - Fully-loaded annual cost) / Fully-loaded annual cost

Payback (months) = Fully-loaded annual cost / (Risk-adjusted annual benefit / 12)
```

Two numbers decide whether the result is honest, and both are covered below: the **value-conversion factor** (does time saved turn into value, or just into more Slack) and the **active-seat ratio** (benefit scales with people who actually use it, not seats you bought).

## Cost Side: Total Cost of Ownership

Per-seat SaaS is simpler to model than token-based API consumption, but the subscription line is not the whole cost. Count all of it, annualized.

| Cost line         | What it covers                                               | Notes                                                                           |
| ----------------- | ------------------------------------------------------------ | ------------------------------------------------------------------------------- |
| Seat subscription | Seats x negotiated per-seat price x 12                       | Enterprise pricing is custom (contact sales). Use your quote, not a list price. |
| Integration       | SSO/SCIM setup, security review, DPA, connector/MCP build    | Mostly year-one.                                                                |
| Enablement        | Training, internal champions, prompt libraries, office hours | Recurring but tapers after ramp.                                                |
| Administration    | License management, governance, usage review                 | Steady-state platform/IT time.                                                  |
| Adoption drag     | Temporary output dip while people learn the tool             | Model as a benefit reducer in months 1-3, not a cash line.                      |

For multi-year cases, discount each year's net benefit to present value (NPV) at your company's cost of capital before computing the headline number. A three-year NPV is what a CFO will ask for; a single-year ROI is what an engineering VP will quote.

## Benefit Side: Categories and How to Measure Them

The most common way an enterprise AI business case fails is measuring the wrong return -- counting messages sent or "seats activated" instead of work outcomes. Tie each benefit category to a measurement you can actually pull.

| Benefit            | How it shows up                                  | How to measure it                                                                    |
| ------------------ | ------------------------------------------------ | ------------------------------------------------------------------------------------ |
| Time reclaimed     | Faster drafting, research, summarization, coding | Task-time studies on a sample; for engineers, DORA lead-time-to-change               |
| Quality and rework | Fewer defects, fewer revision cycles             | DORA change-failure rate; rework hours; defect escape rate                           |
| Cycle time         | Work ships sooner, value lands earlier           | Lead time per work item; revenue or savings pulled forward                           |
| Deflection         | Work that no longer needs a person or a vendor   | Tickets self-served, research hours not outsourced, contractor spend avoided         |
| Optionality        | Use cases the tool unlocks later                 | Forrester TEI calls this "flexibility" -- value it as a real option, not a line item |

For engineering populations, anchor the return on **DORA** (deployment frequency, lead time, change-failure rate, time to restore) and **SPACE** (satisfaction, performance, activity, communication, efficiency). They are outcome-level and hard to game, unlike lines of code or acceptance rate. For non-engineering knowledge work, a before/after time-and-task study on a representative sample is the defensible source.

### The Value-Conversion Factor

Hours saved are not dollars saved. Time only converts to value when it is reallocated to work that produces output, and not all of it is. Apply an explicit conversion factor (commonly 0.4-0.7) so the model states the assumption instead of hiding it.

```text
Time-value benefit =
  active users
  x hours saved per user per week
  x working weeks per year
  x loaded hourly cost
  x value-conversion factor
```

## Risk Adjustment

Forrester's TEI methodology haircuts optimistic benefits by a confidence factor and is the step that makes a business case survive finance review. Apply a risk multiplier (commonly 0.7-0.85) to the benefit total to account for measurement error, uneven adoption, and benefits that take longer to land than the model assumes. State the multiplier; do not bury it.

If Anthropic's commissioned Forrester TEI study for Claude is used as a reference point, pull the figures from the study itself rather than from memory, and present them as that study's results, not as a guarantee for this deployment.

## Adoption Weighting

Benefit scales with active usage, cost scales with seats purchased. A rollout at 70% active adoption and one at 30% produce wildly different ROI off the same license bill. Model the active-seat ratio explicitly and forecast it rising across the ramp rather than assuming day-one saturation.

```text
Total benefit = per-active-user benefit x active seats
              = per-active-user benefit x purchased seats x active-seat ratio
```

This is also the lever you control after purchase. Champion programs, enablement, and right-sizing the seat count to real demand move this number more than any pricing negotiation.

## Worked Example

All figures below are illustrative placeholders to show the mechanics. Replace every one with your negotiated quote and your own measured inputs.

```text
Assumptions (ILLUSTRATIVE -- substitute your own):
  Purchased seats ............... 500
  Per-seat price ................ $50 / seat / month   (use your Enterprise quote)
  Active-seat ratio ............. 70%  -> 350 active users
  Hours saved / active user ..... 2 hours / week
  Working weeks ................. 48
  Loaded hourly cost ............ $75 / hour
  Value-conversion factor ....... 0.6
  Risk multiplier ............... 0.75

Annual cost (TCO):
  Subscription .... 500 x $50 x 12 ........... $300,000
  Integration + enablement + admin .......... $150,000
  Total annual cost .......................... $450,000

Annual benefit:
  Gross time-value =
    350 x 2 x 48 x $75 ....................... $2,520,000
  x value-conversion (0.6) ................... $1,512,000
  x risk multiplier (0.75) ................... $1,134,000
  (quality, cycle-time, deflection counted separately, kept at 0 here)

ROI  = (1,134,000 - 450,000) / 450,000 ..... ~152%
Payback = 450,000 / (1,134,000 / 12) ....... ~4.8 months
```

The example deliberately zeroes out quality, cycle-time, and deflection benefits. Those are real but harder to attribute, so a conservative case wins more arguments by leaving them as upside rather than padding the headline.

## Measure a Baseline Before You Buy

Without a before-picture you cannot attribute any delta to the tool, and finance will discount the entire case. Before the purchase or at the start of a pilot:

- Snapshot DORA metrics for the engineering org, or run a task-time study on a representative knowledge-work sample.
- Run the pilot as a cohort with a comparison group where feasible, so a good quarter is not credited to the tool.
- Record the active-seat ratio weekly during the pilot -- it is the single best predictor of full-rollout ROI.

The phased cohort approach in [Cohort Strategy](../../04-phase-2-phased-rollout/cohort-strategy/) is built to produce exactly these measurements.

## Where the Number Lies

- **Seats bought, not seats used.** Cost is committed on purchase; benefit is not. Weight by active seats.
- **Hours saved counted as cash.** Without the value-conversion factor, every model overstates by 40-60%.
- **No baseline.** A delta with nothing to compare against is a guess wearing a number.
- **Attribution to the tool.** A control or comparison group keeps unrelated improvements out of the case.
- **Optimism with no haircut.** Skipping risk adjustment is what gets a business case rejected on second read.

## References

- [Forrester Total Economic Impact (TEI) methodology](https://www.forrester.com/policies/tei/) -- benefits, costs, flexibility, and risk-adjustment.
- [DORA metrics (Accelerate / State of DevOps research)](https://dora.dev/) -- delivery throughput and stability.
- [SPACE framework](https://queue.acm.org/detail.cfm?id=3454124) -- multi-dimensional developer productivity measurement.
- [Cost Tracking and Budgets](../../05-phase-3-observability-and-governance/cost-tracking/) -- the token-based cost view for Claude Code on Bedrock.
- [Market Opportunity Analysis](../../01-skill-gaps-and-market-opportunity/market-opportunity/) -- the engagement-level business case.
