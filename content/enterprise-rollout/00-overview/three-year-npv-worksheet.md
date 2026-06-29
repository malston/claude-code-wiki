---
title: "Three-Year NPV Worksheet"
weight: 4
---

# Three-Year NPV Worksheet

## Purpose

The [ROI Framework](../roi-framework/) gives the single-year view an engineering VP quotes. This worksheet produces the multi-year, discounted view a CFO asks for: the three-year net present value (NPV) and payback of a Claude Enterprise seat purchase. Fill in your own numbers; the worked example carries the framework's illustrative figures across three years so the two pages reconcile.

Every dollar figure below is an illustrative placeholder. Replace each with your negotiated seat quote and your own measured inputs.

## The Discount Mechanic

A dollar of benefit in Year 3 is worth less than a dollar today. NPV restates every future net cash flow in today's dollars using your cost of capital `r` (weighted-average cost of capital, or the hurdle rate finance hands you).

```text
Discount factor (year t) = 1 / (1 + r)^t

NPV = sum over t of ( net cash flow_t x discount factor_t )

where net cash flow_t = benefit_t - cost_t
```

This worksheet uses end-of-year discounting (each year's net flow is discounted as if it lands on the last day of the year) and puts one-time setup in Year 0 at a discount factor of 1.0. State the convention next to the result so it is not re-derived differently later.

## Inputs to Gather

| Input                            | Symbol | Example value   | Source                            |
| -------------------------------- | ------ | --------------- | --------------------------------- |
| Purchased seats                  | --     | 500             | Procurement                       |
| Per-seat price / month           | --     | $50             | Your Enterprise quote             |
| Active-seat ratio by year        | --     | 50% / 70% / 80% | Pilot data, ramp forecast         |
| Hours saved / active user / week | --     | 2               | Task-time study                   |
| Loaded hourly cost               | --     | $75             | Finance                           |
| Working weeks / year             | --     | 48              | Finance                           |
| Value-conversion factor          | --     | 0.6             | Assumption (state it)             |
| Risk multiplier                  | --     | 0.75            | Forrester TEI-style haircut       |
| One-time setup (Year 0)          | --     | $120,000        | Integration, SSO, security review |
| Cost of capital                  | `r`    | 10%             | Finance                           |

The risk-adjusted benefit per active user per year is the spine of the model:

```text
Benefit / active user / year =
  hours saved/week x working weeks x loaded hourly cost
  x value-conversion factor x risk multiplier

Example: 2 x 48 x $75 x 0.6 x 0.75 = $3,240 / active user / year
```

## Year-by-Year Build

Active users = purchased seats x active-seat ratio. Benefit = active users x risk-adjusted benefit per user. Recurring cost = subscription + enablement + admin, with enablement tapering after the ramp.

| Line                            | Year 0        | Year 1       | Year 2       | Year 3       |
| ------------------------------- | ------------- | ------------ | ------------ | ------------ |
| Active-seat ratio               | --            | 50%          | 70%          | 80%          |
| Active users                    | --            | 250          | 350          | 400          |
| Benefit (active users x $3,240) | $0            | $810,000     | $1,134,000   | $1,296,000   |
| Subscription (500 x $50 x 12)   | $0            | $300,000     | $300,000     | $300,000     |
| Enablement + admin              | $0            | $110,000     | $90,000      | $80,000      |
| One-time setup                  | $120,000      | $0           | $0           | $0           |
| **Net cash flow**               | **-$120,000** | **$400,000** | **$744,000** | **$916,000** |
| Discount factor (r = 10%)       | 1.0000        | 0.9091       | 0.8264       | 0.7513       |
| **Present value**               | **-$120,000** | **$363,636** | **$614,879** | **$688,200** |

## Headline Results

| Metric                        | Value                               | How it is computed                              |
| ----------------------------- | ----------------------------------- | ----------------------------------------------- |
| Three-year NPV                | ~$1.55M                             | Sum of the present-value row                    |
| Undiscounted three-year net   | $1.94M                              | Sum of the net-cash-flow row                    |
| Three-year ROI (undiscounted) | ~149%                               | (total benefit - total cost) / total cost       |
| Discounted payback            | ~4 months into Year 1               | $120,000 setup / ($400,000 / 12)                |
| IRR                           | Large; not the deciding metric here | Spreadsheet `=IRR()` over the net-cash-flow row |

For this cash-flow shape -- a small upfront cost recovered within months -- IRR runs into the hundreds of percent and stops being informative. NPV and payback are the numbers to present.

## Sensitivity

NPV is most sensitive to the two multipliers that scale the benefit line: the active-seat ratio and the value-conversion factor. Both are linear, so a percentage change in either moves total benefit PV by the same percentage. The discount rate moves the result far less over a three-year horizon.

| Change                      | Three-year NPV |
| --------------------------- | -------------- |
| Base case                   | ~$1.55M        |
| Adoption or conversion -25% | ~$0.88M        |
| Adoption or conversion +25% | ~$2.21M        |
| Cost of capital 10% -> 15%  | ~$1.39M        |

The break-even point is the honest headline: realized benefit (adoption x conversion) can fall to about **42% of plan** before three-year NPV reaches zero.

```text
Break-even benefit multiplier = cost PV / benefit PV
                              = $1.10M / $2.65M
                              = ~0.42
```

That margin of safety is the argument for the purchase, not the base-case NPV. If you cannot defend hitting 42% of the adoption plan, the inputs are wrong, not the deal.

## How to Use It

1. Copy the input table and replace every value with your quote and your measured numbers.
2. Compute risk-adjusted benefit per active user once, then fill the year-by-year build.
3. Apply discount factors for your own `r` and sum the present-value row for NPV.
4. Run the sensitivity rows by scaling the benefit line and recomputing -- find your own break-even multiplier.
5. Forecast the active-seat ratio from pilot data, not from hope. It is the input that decides the result. See [Cohort Strategy](../../04-phase-2-phased-rollout/cohort-strategy/) for producing that number, and the [ROI Framework](../roi-framework/) for the underlying benefit and cost definitions.

## References

- [ROI Framework](../roi-framework/) -- benefit categories, the value-conversion factor, and risk adjustment.
- [Context Budget Worksheet](../../03-phase-1-platform-engineering/context-budget-worksheet/) -- the companion fill-in worksheet for context, not cost.
- Forrester Total Economic Impact (TEI) methodology -- risk-adjusted NPV for software business cases.
