---
title: "Structured AI Development Without the Framework"
linkTitle: "Structured AI Development"
weight: 4
---

# Structured AI Development Without the Framework

Vibe coding -- describing what you want and letting AI build it -- works until it doesn't.

The first few hundred lines come fast. The AI scaffolds routes, components, database schemas. You iterate by describing changes in conversation. A working prototype appears in minutes.

Then you hit a wall. Somewhere between 500 and 2,000 lines of generated code, the AI starts contradicting its earlier decisions. It rewrites a function it wrote 20 minutes ago. It adds a dependency it already added under a different name. The context window fills up and the AI loses track of what it built.

You can't refactor because there are no tests. You can't add features without breaking existing ones because nothing enforces the contracts between components. The code was generated fast, but nobody -- human or AI -- made structural decisions along the way.

The code may be fine line by line. The problem is that there's no architecture holding it together. Each prompt produces a locally reasonable response that's globally incoherent.

## The Framework Response

The natural response is to wrap AI interactions in a framework. Give the AI structured commands: `/discover` for requirements, `/task` for planning, `/execute` for implementation, `/review` for quality. Encode best practices as rules the AI reads before generating code. Some projects go further and create custom pseudo-languages for "more precise" AI communication.

The impulse makes sense. Unstructured prompting produces unmaintainable code, and structure helps. But packaging that structure as a third-party framework introduces problems of its own.

## Why Frameworks Are the Wrong Abstraction

**They encode opinions as architecture.** A framework that mandates a specific test runner, a specific ID generator, and a specific auth library is selling preferences as infrastructure. Those choices may be reasonable, but they're not structural -- they're someone's stack opinions bundled as dependencies. When those opinions don't match your project, you're fighting the framework instead of building your application.

**They add indirection.** Instead of talking to the AI directly, you're talking to a framework that talks to the AI. When something goes wrong, you're debugging prompt templates, not your actual problem.

**They go stale.** LLMs evolve fast. What Sonnet 3.5 needed in terms of explicit guidance, Opus 4.6 handles without prompting. Frameworks that compensate for model limitations become unnecessary overhead as models improve -- but the framework doesn't remove itself.

**Custom prompt languages solve a problem that doesn't exist.** LLMs understand natural language and markdown. A custom pseudo-language claiming token savings over natural language is solving for a cost that [prompt caching]({{< relref "internals/prompt-caching" >}}) already handles (90% discount on cached input), while adding a syntax the developer has to learn and the LLM has to interpret through an extra layer of abstraction.

**They're monolithic where they should be composable.** A framework bundles discovery, planning, execution, and review into a single system. But these are independent concerns. You might want TDD discipline without the framework's opinions on project scaffolding. You might want code review without the framework's test runner preferences. Bundling forces all-or-nothing adoption.

## Composable Primitives

The solution to unstructured AI coding is a set of primitives that compose independently. Claude Code ships several that, together, produce the structured workflow that frameworks try to provide.

### Project Context: CLAUDE.md

A [CLAUDE.md]({{< relref "guides/memory-organization" >}}) file at the root of your project loads into every message. It tells the AI how your project works before you ask your first question.

```markdown
# My Project

## Stack

- Go 1.22, Chi router, PostgreSQL
- All handlers return (response, error) -- never panic

## Testing

- Table-driven tests for all public functions
- Integration tests use testcontainers for Postgres
- `go test ./...` must pass before any commit

## Conventions

- Errors wrap with fmt.Errorf("functionName: %w", err)
- No global state -- pass dependencies through constructors
```

This replaces the "rules" directories that frameworks provide. It's plain markdown. It lives in your repo. It works with any tool that reads project files.

### Workflow Injection: Skills

[Skills]({{< relref "extending/extension-mechanisms" >}}) inject specific workflows into the AI's behavior when invoked. A TDD skill enforces a specific sequence: write a failing test, run it, implement until it passes, refactor.

```text
You invoke: /tdd
The AI now follows: Red -> Green -> Refactor for every change
```

Skills are independent. You can use TDD without adopting a project scaffolding opinion. You can use a debugging skill without changing your test runner. Each skill adds one workflow without constraining others.

### Automated Guardrails: Hooks

[Hooks]({{< relref "extending/hooks-cookbook" >}}) are shell commands that run in response to tool events. They enforce standards without requiring the AI to remember them.

```json
{
  "hooks": {
    "PostToolUse": [
      {
        "matcher": "Write|Edit",
        "command": "gofmt -w $CLAUDE_FILE_PATH"
      }
    ],
    "Stop": [
      {
        "command": "go test ./... 2>&1 | tail -20"
      }
    ]
  }
}
```

Every file edit gets auto-formatted. Every completed task runs the test suite. The AI doesn't need to be told to format or test -- the hooks handle it. This is the "review" step that frameworks provide through prompt templates, except it runs the actual tools instead of asking the AI to simulate the check.

### Context Isolation: Subagents

When the AI needs to research a library, explore a codebase, or investigate an error, [subagents]({{< relref "internals/context-management" >}}) run that work in an isolated context window. The results come back without the investigation consuming the main conversation's context budget -- typically a 97.5% savings on delegated work.

This addresses the "AI loses track of what it built" problem directly. The main context stays focused on the current task. Research, exploration, and parallel work happen in disposable contexts that don't pollute the primary conversation.

## The Difference in Practice

An unstructured session: you describe what you want, the AI generates code, you iterate through conversation. Thirty minutes later you have 1,500 lines with no tests, inconsistent error handling, and three different naming conventions.

A session with primitives: the AI reads your CLAUDE.md and knows your conventions before generating a line of code. You invoke a TDD skill and every feature starts with a failing test. Hooks auto-format code and run the test suite after each change. Subagents handle research without filling your context window.

The output has tests, follows project conventions, and was verified at each step. Not because a framework enforced a workflow, but because independent primitives each handled their concern.

## What This Doesn't Solve

Primitives don't substitute for judgment. If you don't know what good architecture looks like, CLAUDE.md won't tell you. If you can't evaluate whether generated code is correct, hooks running `go test` won't catch tests that verify the wrong thing.

Structured AI development still requires a developer who can make architectural decisions, evaluate trade-offs, and recognize when the AI is confidently wrong. The primitives make the AI's output more consistent and verifiable. They don't make understanding optional.

This is the same limitation that frameworks have -- they just hide it behind more abstraction. A `/review` command that asks the AI to review its own code is still the AI evaluating itself. A hook that runs the test suite is an external check that doesn't depend on the AI's self-assessment.

## Bottom Line

The problem is real: unstructured AI coding produces code that falls apart. The solution is also real: structured workflows with testing discipline.

You don't need a framework, a custom language, or a new dependency to get there. CLAUDE.md for context. Skills for workflow. Hooks for enforcement. Subagents for isolation. Four primitives, each independent, each composable, each built into the tool.

The frameworks will keep appearing because packaging structure as a product is a business model. The primitives work because they solve the actual problem: giving AI the context and constraints it needs to produce code that holds together.
