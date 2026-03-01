---
title: "Prototyping & Iteration: Build to Learn"
linkTitle: "Prototyping & Iteration"
weight: 4
---

# Prototyping & Iteration: Build to Learn

## Executive Summary

A prototype is a question in code form. You build it to answer a specific question -- "can this API handle the load?", "does this workflow make sense to users?", "will these two systems integrate?" -- and then discard it. This article covers the types of prototypes, when to use each, the Claude Code workflow for running them, and the discipline of deciding what comes after.

| Prototype Type    | Question It Answers                 | Typical Artifact                                       | Timeframe |
| ----------------- | ----------------------------------- | ------------------------------------------------------ | --------- |
| Throwaway script  | Can this work technically?          | Single-file script testing an API, algorithm, or query | 30-90 min |
| UI mockup         | Does this flow make sense to users? | Clickable wireframe or minimal frontend                | 1-3 hours |
| Data pipeline     | Is the data clean enough to use?    | ETL script processing a representative sample          | 1-2 hours |
| Integration spike | Will these systems communicate?     | Minimal client/server exercising the integration point | 1-3 hours |

## Table of Contents

- [Prototypes Are Questions](#prototypes-are-questions)
- [Types of Prototypes and When to Use Each](#types-of-prototypes-and-when-to-use-each)
- [The Claude Code Prototyping Workflow](#the-claude-code-prototyping-workflow)
- [Worked Example: The Full Prototype Cycle](#worked-example-the-full-prototype-cycle)
- [From Prototype to Commitment](#from-prototype-to-commitment)
- [Anti-Patterns](#anti-patterns)
- [The Cycle Continues](#the-cycle-continues)

## Prototypes Are Questions

Every prototype starts with a hypothesis. Without one, you're writing exploratory code with no criteria for success or failure. The hypothesis doesn't need to be formal -- "I think the Stripe API can handle idempotent retries for our use case" is enough -- but it needs to be falsifiable. You should know, before you start coding, what answer would make you stop.

This is what separates prototyping from hacking. Hacking is open-ended exploration. Prototyping is a time-boxed experiment with a specific outcome. You build the minimum thing that confirms or invalidates your hypothesis, record what you learned, and move on.

The output of a prototype is a decision, not code. The code is a byproduct. If you find yourself wanting to keep the code, that's a signal you've confused the prototype with the product.

## Types of Prototypes and When to Use Each

### Throwaway Scripts -- Test Feasibility

A throwaway script answers "can this work?" You're testing whether an API behaves the way the docs claim, whether an algorithm is fast enough on realistic data, or whether a library handles an edge case you care about.

Example: your team is considering using a third-party geocoding API for address normalization. The docs say it handles international addresses, but you process addresses from 30 countries with non-Latin scripts. A 50-line script that sends 100 representative addresses and checks the results tells you more than a week of reading documentation.

Throwaway scripts are the lowest-cost prototype. They run in minutes, require no architecture, and answer binary questions: yes it works, or no it doesn't.

### UI Mockups -- Test Desirability

UI mockups answer "does this flow make sense?" You're testing whether users understand the interaction, whether the information hierarchy is right, or whether the feature feels useful when they see it.

You don't need a design tool. A minimal HTML page or a stripped-down React component that fakes the data is enough to put in front of someone and ask "what would you expect to happen when you click this?" Claude Code can generate a clickable prototype from a description of the workflow.

The fidelity should match the question. Testing navigation structure? Boxes with labels. Testing whether users understand a data visualization? You need real-ish data in the chart. Don't build more than the question requires.

### Data Pipelines -- Test Viability

Data pipelines answer "is the data good enough?" Before building a feature that depends on data from another system -- customer records, usage logs, third-party feeds -- you need to know whether that data is clean, complete, and structured in a way you can use.

Write a script that pulls a representative sample, runs the transformations you'd need, and checks the output. How many records are missing required fields? How many have encoding issues? Does the schema match what the API docs promise?

A one-hour data pipeline prototype can save weeks of building a feature that fails because 30% of the input records are malformed.

### Integration Spikes -- Test Compatibility

Integration spikes answer "will these systems talk to each other?" You're testing authentication flows, message formats, network paths, or protocol compatibility between two systems that need to communicate.

Example: your service needs to publish events to a team's Kafka cluster. The architecture diagram says it'll work. An integration spike that produces and consumes a message through the actual cluster -- with the actual authentication, the actual network policies -- confirms it. Or it reveals that the service account doesn't have write permissions to the topic, which you'd rather discover in a prototype than during a production deploy.

Integration spikes focus on the boundary between systems. The internal logic on either side can be stubs. The connection itself is what you're testing.

## The Claude Code Prototyping Workflow

### Start in a Disposable Space

Prototypes should live in isolation from your production code. Use a [worktree]({{< relref "/guides/workflow-patterns" >}}) or a scratch directory:

```bash
# Worktree approach -- isolated branch, auto-cleanup on exit
claude --worktree geocoding-spike

# Scratch directory approach
mkdir -p ~/scratch/geocoding-spike && cd ~/scratch/geocoding-spike
```

The worktree approach is better for prototypes that touch your existing codebase (integration spikes, UI mockups that need your component library). A scratch directory works for standalone scripts. The [workflow patterns]({{< relref "/guides/workflow-patterns" >}}) guide covers worktree mechanics in detail.

### Prompt for the Simplest Version

State your hypothesis and ask for the minimum code that tests it:

```text
Hypothesis: the Acme geocoding API correctly normalizes addresses
with non-Latin scripts (CJK, Arabic, Cyrillic) to a structured
format we can store.

Build a script that:
1. Reads addresses from ./test-addresses.json (I'll provide the file)
2. Sends each address to the Acme geocoding API
3. Checks whether the response contains structured fields:
   street, city, country, postal_code
4. Reports: total sent, total with all fields, total missing fields,
   and which fields were missing for which input

Use the API key from the ACME_GEOCODING_KEY env var. No error
retry logic, no rate limiting, no logging framework. Just the test.
```

The prompt explicitly excludes production concerns -- error handling, rate limiting, logging. These are the things that turn a 30-minute prototype into a three-hour yak shave.

### Resist the Urge to Polish

The prototype works. It answers your question. Now you notice the variable names are bad, there's no input validation, and the output format is ugly. Resist. Every minute spent polishing a throwaway prototype is a minute wasted. The code exists to produce a decision, and you have your decision.

If you catch yourself refactoring prototype code, stop and write down what you learned instead.

### Document What You Learned

Before discarding the prototype, write down the findings. This can be a comment in a ticket, a message in your team's channel, or a note in your project's CLAUDE.md. The format matters less than capturing three things:

1. **What was the hypothesis?** "The Acme geocoding API handles non-Latin scripts."
2. **What did you find?** "CJK addresses returned structured fields for 95 of 100 test cases. Arabic addresses returned structured fields for 60 of 100 -- the `street` field was missing for most Saudi addresses."
3. **What's the decision?** "CJK support is sufficient. Arabic address handling needs a fallback strategy before we can use this API for the Middle East region."

Then delete the code. Or let the worktree clean itself up on exit.

## Worked Example: The Full Prototype Cycle

A team is building a deployment dashboard. [User research]({{< relref "user-research" >}}) revealed that engineers waste 15-20 minutes watching dashboards after every deploy, waiting to see if anything breaks. The proposed solution: automated rollback triggered by health check failures, so engineers can deploy and move on.

Before writing [requirements]({{< relref "requirements-specifications" >}}), the team has an open question: can the existing health check infrastructure detect failures fast enough to trigger a rollback within 60 seconds?

### Hypothesis

"Our health check endpoint responds within 2 seconds, and the monitoring system detects a failure state within 30 seconds of the health check starting to fail. This leaves 30 seconds for the rollback operation itself."

### Build

In a worktree:

```bash
claude --worktree rollback-timing-spike
```

The prompt:

```text
I need to measure health check failure detection time. Our setup:
- Health check endpoint: GET /healthz on each service instance
- Monitoring: Prometheus scraping /healthz every 10 seconds
- Alert rule: fires after 2 consecutive failed scrapes

Build a test harness that:
1. Deploys a test service to our staging k8s cluster (use the
   existing deploy script at ./scripts/deploy.sh)
2. Waits for the service to be healthy
3. Triggers a failure (kill the health endpoint handler)
4. Measures elapsed time until the Prometheus alert fires
5. Runs this 5 times and reports min/median/max detection time

Use the staging kubeconfig at ~/.kube/staging.yaml and the
Prometheus API at http://prometheus.staging.internal:9090.
```

### Learn

The prototype runs 5 trials. Results:

- Min detection time: 18 seconds
- Median detection time: 24 seconds
- Max detection time: 38 seconds

The 38-second worst case leaves only 22 seconds for the rollback operation. The team's existing deploy process takes 45-90 seconds. The hypothesis is partially invalidated -- detection is fast enough, but the combined detection + rollback exceeds the 60-second target.

### Decide

The team now knows that the 60-second auto-rollback target requires either faster deploys or a different rollback mechanism (container restarting with the previous image instead of a full redeployment). This changes the [requirements]({{< relref "requirements-specifications" >}}) -- they need to specify the rollback mechanism, not assume the existing deploy process will work.

Without the prototype, the team would have written requirements assuming the current deploy process, built the feature, and discovered the timing problem in production. The two-hour spike saved weeks of implementation aimed at an architecture that couldn't meet its own success criteria.

## From Prototype to Commitment

The prototype is done. You have an answer. Now what?

### If the Hypothesis Was Confirmed

Your assumption holds. The API works, the integration connects, the data is clean enough. Move forward:

1. Write [requirements]({{< relref "requirements-specifications" >}}) informed by what you learned. The prototype often reveals constraints and edge cases that belong in the spec.
2. Enter the build cycle with spec-driven development. The prototype told you it's feasible -- the requirements tell you what to build.
3. Do not use the prototype code. Start fresh with production standards: error handling, tests, logging, code review.

### If the Hypothesis Was Invalidated

Your assumption was wrong. This is a good outcome -- you learned it in hours instead of weeks. Go back to [research]({{< relref "user-research" >}}):

1. Document what you learned and why the original approach won't work.
2. Identify alternative approaches. The prototype failure often points to the constraint that matters most.
3. Form a revised hypothesis and, if needed, build another prototype to test it.

### If the Answer Was "It Depends"

Most prototypes produce conditional answers. "The API works for CJK but not Arabic." "The integration works but only with batch sizes under 1,000." These conditions become constraints in your requirements. Capture them precisely -- they're the most valuable output of the prototype.

## Anti-Patterns

### Prototype Rot

"Let's just clean this up and ship it." This is the most common prototyping failure. The code was written to answer a question, without error handling, without tests, without architectural consideration. Cleaning it up takes as long as rewriting it, and the result carries structural decisions made under a "this is throwaway" mindset.

If the prototype code is genuinely close to production quality, you were overbuilding the prototype. Next time, build less.

### Prototyping Without a Hypothesis

Building something "to see what happens" produces open-ended exploration without clear success criteria. You can't decide whether the prototype succeeded because you never defined what success means. Before opening a worktree, write down the hypothesis you're testing and the outcome that would change your plan.

### Prototyping When a Conversation Would Suffice

Some questions don't need code. "Will the billing team's API accept our request format?" is often answered faster by sending them a Slack message with an example payload than by writing an integration spike. Prototypes are for questions that can only be answered by running code. If a human can answer the question in a conversation, start there.

### Scope Creep During the Prototype

"While I'm in here, I might as well add..." is a signal that you've lost focus on the hypothesis. A prototype that tests three things at once is hard to interpret -- if it fails, which hypothesis was wrong? Keep each prototype focused on a single question. If you discover additional questions during the build, note them for separate prototypes.

## The Cycle Continues

Prototyping is the third step in a cycle that starts with understanding the problem and defining what to build:

1. **Discover** -- [User research]({{< relref "user-research" >}}) identifies the problem and surfaces assumptions.
2. **Define** -- [Requirements]({{< relref "requirements-specifications" >}}) turn research into buildable specifications.
3. **Prototype** -- A time-boxed experiment confirms or invalidates the riskiest assumption.
4. **Learn** -- Record findings, update your understanding, adjust the plan.

The cycle repeats. A prototype that invalidates an assumption sends you back to research with better questions. A prototype that confirms your approach feeds directly into refined requirements. Each pass through the loop reduces the risk of building the wrong thing.

The goal is short loops. A week-long prototype that invalidates an assumption is still faster than a month-long implementation that fails in production -- but a two-hour prototype that answers the same question is better still. Use Claude Code to keep the build step fast, and invest your own time in forming good hypotheses and interpreting results.
