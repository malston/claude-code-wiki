---
title: "Tool Execution Context"
linkTitle: "Tool Execution Context"
weight: 6
---

# Tool Execution Context

When Claude runs a bash command or any other tool, the system prompt and skill instructions are **not re-injected** alongside the tool result. The result passes back to the model as bare output. This is sometimes called "pass-through" behavior.

The distinction matters when your workflows depend on behavioral rules defined in CLAUDE.md or a skill file -- those rules are active when Claude is reasoning, but they are not re-delivered when Claude processes tool output.

## How It Works

A normal conversation turn sends the full context to the model on every API call:

```text
API call
├── System prompt (CLAUDE.md + skills)     ← full context
├── Conversation history
└── User message
    └── Model reasons with full context available
```

When Claude invokes a tool (bash, read, write, etc.), the execution happens outside the model. The result is returned as a tool result block:

```text
Model decides to run bash tool
    │
    ▼
Shell executes: cf apps
    │
    ▼
Tool result returned to model:
┌─────────────────────────────────────────┐
│ tool_result: "Getting apps in org..."   │  ← bare output
│                                         │     no system prompt re-injected
│ [app list here]                         │     no skill instructions re-injected
└─────────────────────────────────────────┘
    │
    ▼
Model processes result
```

The model's reasoning capability is unchanged. What changes is that the tool result arrives without the skill instructions being explicitly re-stated alongside it.

## What This Affects

**Behavioral rules in skill files.** A rule like "always confirm the target foundation before running destructive commands" is available when Claude is planning what to do. It may not be in active consideration when Claude is processing the raw output of a bash command and deciding what to run next.

**Output interpretation rules.** If a skill says "when you see diego-cell count below 10, flag it," that instruction may not be in scope when Claude is looking at the raw `cf apps` output returned from the tool. Claude will reason about the output, but without the rule explicitly in front of it.

**Multi-step bash chains.** A sequence of 5-6 tool calls in a row is the highest-risk pattern. Each tool result arrives bare, and the behavioral context from the system prompt is further from the immediate reasoning at each step.

## What This Does Not Affect

The conversation history still contains all prior turns, including Claude's earlier reasoning. The system prompt is re-sent on every full API call (not every tool call within a turn). If Claude pauses to reason between tool calls, context is available.

The issue is specifically about **rules that require active recall** at the moment of processing a tool result, mid-chain.

## Patterns That Work

**Break bash chains with explicit reasoning steps.** Instead of chaining 5 commands silently, ask Claude to summarize what it found after each major result. This forces a reasoning turn where the system prompt is fully in scope.

```text
Instead of:
  "Check all foundations, compare diego-cell counts, flag anomalies, generate report"

Use:
  "Check the nonprod foundation diego-cell counts and tell me what you find."
  [review output]
  "Now check prod and compare."
```

**Put critical constraints in the user message, not just the skill file.** For high-stakes operations, restate the constraint in the prompt:

```bash
# In your message to Claude:
"Run bosh deployments on the prod foundation.
Before running anything destructive, list what you're about to do and wait for confirmation."
```

**Make output interpretation explicit.** Instead of relying on a skill rule to recognize a problem condition, ask Claude directly after getting results:

```text
"Here's the diego-cell output. Are any cells below the minimum threshold?"
```

This turns implicit rule-following into explicit reasoning, which is more reliable.

**Use shorter tool chains for sensitive operations.** BOSH deploys, `cf delete`, and similar destructive commands should be single-step tool calls preceded by explicit confirmation, not the end of a long automated chain.

## CLAUDE.md vs. Skill Files

CLAUDE.md instructions are part of the system prompt and are sent on every API call. They establish baseline behavior for the session. Skill files loaded into CLAUDE.md have the same scope.

Neither is re-injected into individual tool result blocks. The difference between CLAUDE.md and skill files is where the instructions live, not whether they affect tool execution.

For rules you need to be reliably active during tool-heavy workflows, the most durable approach is to include them in the user prompt for that specific task, not only in the skill file.

## Summary

| Context source | Available during reasoning | Active when processing tool results |
|---|---|---|
| System prompt / CLAUDE.md | Yes | Not re-injected, but in conversation history |
| Skill file instructions | Yes | Same as above |
| User message | Yes | Same as above |
| Explicit instruction in user message | Yes | Most reliable for tool-heavy chains |

The model reasons from its full context window, which includes the conversation history. The issue is not that instructions disappear -- it is that they are less likely to be the focal point when the model is processing a stream of tool results mid-chain.

## References

- [Context Management]({{< relref "context-management" >}}) -- How the context window fills up over a session
- [System Prompt]({{< relref "system-prompt" >}}) -- What the system prompt contains and when it is sent
- [Extension Mechanisms]({{< relref "/extending/extension-mechanisms" >}}) -- Skills, hooks, and how they load into context
