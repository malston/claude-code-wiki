---
title: "Product Manager Path"
weight: 3
---

# Product Manager Path

Technical literacy for product managers using Claude Code. This path starts with what PMs can do directly -- research synthesis, prioritization modeling, requirements writing -- then builds the technical context needed to collaborate effectively with development teams.

| Module                                                                        | Focus                                           | Prerequisites |
| ----------------------------------------------------------------------------- | ----------------------------------------------- | ------------- |
| [1. How Claude Code Works](#module-1-how-claude-code-works)                   | What it is, what PMs can do with it             | None          |
| [2. Product Research & Discovery](#module-2-product-research--discovery)      | Research synthesis, validation, prototyping     | Module 1      |
| [3. Requirements & Prioritization](#module-3-requirements--prioritization)    | Specs, decomposition, trade-off modeling        | Module 2      |
| [4. Technical Literacy](#module-4-technical-literacy)                         | Design, architecture, standards, TDD essentials | Module 2      |
| [5. Working with Development Teams](#module-5-working-with-development-teams) | Tickets, reviews, session planning              | Modules 1-4   |

Modules 3 and 4 can be taken in either order. Both depend on Module 2, and Module 5 depends on all four.

## Module 1: How Claude Code Works

**Goal:** Understand what Claude Code does so you can use it for product work and set realistic expectations for your team.

### Key Concepts

**Claude Code is a CLI tool that works through conversation.** You describe what you need, it reads files, generates output, and iterates. It's interactive, and the quality of output depends on the quality of input.

**What PMs can use Claude Code for:**

- Synthesizing support tickets, interview notes, and usage data into patterns
- Modeling prioritization frameworks (RICE scoring, trade-off matrices)
- Drafting requirements and acceptance criteria from research findings
- Prototyping ideas to validate feasibility before committing engineering time
- Decomposing features into independently deliverable slices

**What Claude Code needs from you:**

- Specific context (paste the data, describe the situation, state constraints)
- Clear outcomes ("identify the top 3 pain points" not "analyze this")
- Verification (Claude proposes, you decide -- same as with developers)

**Limitations that affect how you work:**

- Context windows are finite (~200K tokens). Long sessions lose earlier details. Break complex analysis into focused tasks.
- Claude doesn't have your business context unless you provide it. "Our enterprise customers" means nothing without specifics.
- Output needs verification. Claude will confidently synthesize patterns that aren't there if the input data is thin.

### Exercises

1. Pick a real product question you're working on. Write two versions of a Claude Code prompt for it -- one vague, one specific. Run both and compare the outputs.
2. Take a document you'd normally summarize manually (meeting notes, a competitor's changelog, a support ticket batch). Feed it to Claude Code and evaluate whether the synthesis captures what you'd have caught yourself.

### Reference

- [Context Management]({{< relref "internals/context-management" >}}) -- why session length and task scoping matter
- [Effective Prompting]({{< relref "guides/effective-prompting" >}}) -- how prompt specificity translates to better output

## Module 2: Product Research & Discovery

**Goal:** Use Claude Code to turn raw research inputs into actionable product insights.

### Key Concepts

**Product decisions are only as good as the research behind them.** Most PMs have more data than they can process -- support tickets piling up, interview recordings they haven't revisited, competitor releases they skimmed. Claude Code closes the gap between data collected and data used.

**Research synthesis with Claude Code:**

Support tickets and feedback are the most underused research source. You can paste a batch of tickets and ask Claude to categorize by pain point, identify frequency patterns, and surface quotes that illustrate each theme. The key is giving Claude the raw data and a specific lens:

```text
Categorize these support tickets by the workflow stage where
the user got stuck. For each category, list the frequency and
one representative quote.
```

"Categorize by workflow stage" produces different (and more useful) output than "summarize these tickets." The lens determines what Claude finds.

Interview synthesis works the same way. Paste transcript excerpts, ask Claude to identify recurring themes across participants, flag contradictions, and pull supporting quotes. One focused session per research question beats one massive "analyze everything" session.

**Validation and prototyping:**

Research tells you what the problem might be. Prototyping tests whether your solution makes sense before engineering commits to it. Claude Code can generate throwaway prototypes -- a CLI tool, a data transformation, a mock API response -- that let you test assumptions with real structure rather than slide decks.

The critical discipline: prototypes are for learning, not shipping. If you find yourself polishing a prototype, you've stopped researching and started building.

### Exercises

1. Gather 10-20 support tickets or feature requests related to a single area. Run a Claude Code session to categorize them by underlying need (not surface request). Compare Claude's groupings against your intuition -- where do they diverge?
2. Take a feature idea you're considering and ask Claude Code to build the simplest possible prototype that would test the core assumption. Evaluate: did building it reveal anything the spec alone didn't?
3. Write a prompt that asks Claude to find contradictions in a set of user feedback. Run it against real data and assess whether the contradictions are genuine or artifacts of Claude over-reading the input.

### Reference

- [User Research & Validation]({{< relref "product/user-research" >}}) -- research techniques and Claude Code prompts for each
- [Prototyping & Iteration]({{< relref "product/prototyping-iteration" >}}) -- prototype types, workflow, and anti-patterns

## Module 3: Requirements & Prioritization

**Goal:** Turn research into buildable specs and decide what to build next using quantitative frameworks.

### Key Concepts

**The gap between "we understand the problem" and "the team can build a solution" is where most product work stalls.** Requirements that are too vague produce rework. Requirements that are too detailed waste PM time on implementation decisions that belong to engineers. The target is precise enough to verify, open enough to allow good design.

**From research to requirements:**

Good requirements describe behaviors, not interfaces. "Users can filter orders by date range" is a requirement. "Add a date picker component to the orders page" is a design decision wearing a requirement's clothes.

Claude Code can help bridge the gap. Feed it your research synthesis and ask it to extract testable acceptance criteria. The output needs your judgment -- Claude will generate criteria that are technically precise but may miss business context -- but it gets you from "pile of insights" to "draft spec" faster than starting from scratch.

Feature decomposition is where Claude Code earns its keep. Take a large feature, ask Claude to break it into vertical slices that each deliver user value independently. Push back on slices that are just technical layers ("set up the database" isn't a user-facing slice).

**Prioritization with Claude Code:**

Prioritization frameworks only work when you actually run the numbers. Most teams say they use RICE but do it in their heads. Claude Code can model the full framework -- calculate scores, compare alternatives, surface which assumptions drive the ranking.

The value isn't the score. It's the conversation the model forces. When Claude calculates that Feature A scores higher than the one your stakeholder is pushing for, you have data to point at instead of opinions to argue about.

### Exercises

1. Take a feature request from a stakeholder and write acceptance criteria in Given/When/Then format. Then feed the same request to Claude Code and compare its criteria against yours. Where is Claude more precise? Where does it miss intent?
2. List 5-8 features on your current backlog. Use Claude Code to score them with RICE. Identify which single assumption, if changed, would most alter the ranking.
3. Pick a feature your team estimated as "large" and ask Claude Code to decompose it into vertical slices. Evaluate: could the first slice ship independently and deliver value?

### Reference

- [Requirements & Specifications]({{< relref "product/requirements-specifications" >}}) -- requirement formats, vertical slicing, worked example
- [Prioritization & Trade-offs]({{< relref "product/prioritization-tradeoffs" >}}) -- RICE, opportunity cost, cost of delay, saying no with data

## Module 4: Technical Literacy

**Goal:** Understand enough about software design to ask good questions, evaluate trade-offs, and write requirements that developers (and Claude) can build against.

### Key Concepts

**You don't need to write code.** You need to recognize when technical decisions are being made on your behalf and know the right questions to ask.

**Design principles that affect your work:**

The initial implementation is the cheap part. Maintenance -- reading, understanding, debugging, extending -- is where the cost lives. When developers push back on a "quick" feature, they're usually seeing maintenance cost you can't. Ask: "What makes this expensive to change later?"

YAGNI (You Aren't Gonna Need It) applies to your roadmap too. Every "while we're in there, let's also..." adds scope. If a developer builds email, SMS, and Slack notifications when the ticket asked for email, that's not initiative -- it's scope creep that needs testing, documentation, and maintenance.

**Architecture trade-offs to recognize:**

Every choice has costs. Monolith vs. microservices, SQL vs. NoSQL, build vs. buy -- none have universal answers. Your job isn't to pick the technology. It's to make sure the choice aligns with business priorities. Three questions that cut through most architecture discussions: "What's the simplest thing that could work?" "What happens if this fails?" "How many teams coordinate to deploy this?"

Reversibility matters. Push for choices that are easy to change when the team is uncertain. A database migration across millions of rows is expensive to reverse. An internal API change between two services is cheap.

**Why standards and TDD matter to you:**

Coding standards and CLAUDE.md directly control the quality of AI-generated code. Supporting your team's investment in these isn't a technical luxury -- it's how you get consistent output from Claude Code. Don't push for "just ship it" when code doesn't match standards. Inconsistent code costs more later than it saves now.

TDD means tests are written before code. The tests _are_ the requirements in executable form. When you write acceptance criteria precise enough to test -- "POST /login with invalid credentials returns 401" -- you're writing something a developer can turn directly into a test. Vague criteria ("the user should be able to log in") can't become tests without interpretation, and interpretation introduces bugs.

### Exercises

1. Sit in on a technical discussion or read an architecture decision record. Identify the trade-off being made. What's being optimized for? What's being sacrificed? Do you agree with the priority?
2. Take a ticket you wrote recently and evaluate: could a developer turn each acceptance criterion directly into a test without asking you clarifying questions? Rewrite the ones that fail this test.
3. Review your team's CLAUDE.md. What conventions does it enforce? Ask a developer: what's missing that would help Claude produce more consistent code?

### Reference

- [Effective Prompting]({{< relref "guides/effective-prompting" >}}) -- how specificity in requirements translates to better AI-generated code
- [Testing Strategies]({{< relref "guides/testing-strategies" >}}) -- TDD patterns and how tests serve as durable requirements
- [Memory Organization]({{< relref "guides/memory-organization" >}}) -- how CLAUDE.md structures project context

## Module 5: Working with Development Teams

**Goal:** Participate effectively in the development process alongside developers using Claude Code.

### Key Concepts

**How developers use Claude Code day-to-day:**

A developer starts a session with a specific task, provides context, and iterates with Claude -- reading code, proposing changes, running tests -- until the task is complete. Then they commit, push, and open a PR. The developer is still in control. Claude proposes, the developer decides.

This matters for you because the inputs to that process -- tickets, specs, acceptance criteria -- come from your work. The better those inputs are, the fewer round-trips the developer needs with Claude, and the closer the first output is to what you intended.

**Writing tickets for AI-assisted development:**

A ticket that works well with Claude Code includes clear scope (what to build, where it lives), testable acceptance criteria (Given/When/Then), context (why this feature exists, what problem it solves), and constraints (what's out of scope, what shouldn't change).

A ticket that produces rework: "Improve the dashboard." "Make it faster." "Fix the bug." No specific outcome, no measurement, no reproduction steps. Claude will generate _something_ for these -- that's the danger. It'll look like progress but miss the actual need.

**Session planning affects delivery:**

Claude Code sessions have context limits. Large features work better as a sequence of small, independently verifiable steps. When you decompose features into vertical slices (Module 3), you're also creating natural session boundaries for developers. Each slice becomes one focused Claude Code session with clear inputs and verifiable outputs.

**Your role in code review:**

You won't review code syntax, but you can review that acceptance criteria are met, the feature behaves correctly in testing, and the scope matches the ticket -- no over-engineering, no missing pieces. When Claude Code is used with TDD, the test suite becomes the source of truth for what the software does. Skimming test names can tell you whether your requirements were understood.

### Exercises

1. Pull up three recent tickets your team completed. For each, evaluate: did the output match the ticket's intent? Where there was a gap, was it a ticket clarity problem or an implementation problem?
2. Take a feature you're planning and decompose it into tasks where each task could be completed in a single Claude Code session (roughly: one clear outcome, testable independently). Write the acceptance criteria for the first task.
3. Review a recent PR from your team. Read just the test file names and descriptions. Can you tell what the feature does from the tests alone? If not, what's missing from the acceptance criteria?

### Reference

- [Workflow Patterns]({{< relref "guides/workflow-patterns" >}}) -- how developers structure sessions, plan-then-implement, and manage parallel tasks
- [Product Thinking]({{< relref "product/product-thinking" >}}) -- the product development cycle and how each phase connects

## What's Next

After completing this path, you should be able to:

- Use Claude Code to synthesize research, model priorities, and draft specifications
- Evaluate whether a prototype validated the right assumption
- Write acceptance criteria precise enough to become tests
- Identify the trade-off in an architecture decision and assess whether it aligns with business priorities
- Decompose features into tasks suited for AI-assisted development
- Review PRs against acceptance criteria and scope

For hands-on developer skills, see the [Developer Path]({{< relref "training/developer-path" >}}). For infrastructure and deployment, see the [Platform Engineer Path]({{< relref "training/platform-engineer-path" >}}). For deeper product frameworks, see the [Product Development]({{< relref "product/product-thinking" >}}) section.
