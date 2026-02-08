# Subagents, Skills, and MCP Servers: Architecture Deep Dive

## Executive Summary

Claude Code extends capabilities through three distinct mechanisms with different isolation models, memory characteristics, and context window implications:

| Aspect | Subagents | Skills | MCP Servers |
|--------|-----------|--------|-------------|
| **Purpose** | Task delegation with reasoning | Knowledge/workflow injection | External tool/API access |
| **Reasoning** | Full AI (isolated instance) | Inherits main instance | None (deterministic) |
| **Memory** | Session-based, resumable | Shared with main | Stateless per call |
| **Context** | Own isolated window | Injected into main | Minimal overhead |
| **Invocation** | Explicit (Task tool) | Auto-discovered | Explicit tool calls |
| **State** | Fresh but resumable | Part of main conversation | Truly stateless |

---

## Table of Contents

- [Subagents, Skills, and MCP Servers: Architecture Deep Dive](#subagents-skills-and-mcp-servers-architecture-deep-dive)
  - [Executive Summary](#executive-summary)
  - [Table of Contents](#table-of-contents)
  - [Subagents (Task Tool)](#subagents-task-tool)
    - [What They Are](#what-they-are)
    - [Key Characteristics](#key-characteristics)
    - [When to Use Subagents](#when-to-use-subagents)
    - [Example: When to Create a Custom Subagent](#example-when-to-create-a-custom-subagent)
      - [Example 1: Domain-Specific Code Reviewer](#example-1-domain-specific-code-reviewer)
      - [Example 2: Legacy System Migration Assistant](#example-2-legacy-system-migration-assistant)
      - [Example 3: Incident Response Debugger](#example-3-incident-response-debugger)
    - [When NOT to Create a Subagent](#when-not-to-create-a-subagent)
  - [Skills](#skills)
    - [What They Are](#what-they-are-1)
    - [Technical Structure](#technical-structure)
    - [Key Characteristics](#key-characteristics-1)
    - [Context Window Impact](#context-window-impact)
    - [When to Use Skills](#when-to-use-skills)
    - [Example: When to Create a Custom Skill](#example-when-to-create-a-custom-skill)
      - [Example 1: API Design Guidelines](#example-1-api-design-guidelines)
      - [Example 2: Database Migration Checklist](#example-2-database-migration-checklist)
      - [Example 3: Security Review Lens](#example-3-security-review-lens)
    - [When NOT to Create a Skill](#when-not-to-create-a-skill)
    - [Skills vs CLAUDE.md](#skills-vs-claudemd)
    - [Skills vs Subagents](#skills-vs-subagents)
    - [Pattern: Lens (Skill) + Reviewer (Subagent)](#pattern-lens-skill--reviewer-subagent)
      - [The Pattern](#the-pattern)
      - [Example: Code Review](#example-code-review)
      - [When to Use Which](#when-to-use-which)
      - [Other Domains That Fit This Pattern](#other-domains-that-fit-this-pattern)
  - [MCP Servers](#mcp-servers)
    - [What They Are](#what-they-are-2)
    - [Key Characteristics](#key-characteristics-2)
    - [Output Limits](#output-limits)
    - [When to Use MCP Tools](#when-to-use-mcp-tools)
  - [Context Window Implications](#context-window-implications)
    - [Main Instance](#main-instance)
    - [Subagent Context Distribution](#subagent-context-distribution)
    - [MCP Context Impact](#mcp-context-impact)
  - [Memory System Architecture](#memory-system-architecture)
    - [Hierarchical Memory (Not Episodic)](#hierarchical-memory-not-episodic)
    - [Memory Isolation Boundaries](#memory-isolation-boundaries)
    - [What Memory Stores](#what-memory-stores)
    - [Memory Impact on Context](#memory-impact-on-context)
  - [Data Flow Comparison](#data-flow-comparison)
    - [Subagent Flow](#subagent-flow)
    - [MCP Tool Flow](#mcp-tool-flow)
  - [Decision Matrix](#decision-matrix)
    - [Quick Reference](#quick-reference)
  - [Best Practices](#best-practices)
    - [Subagent Configuration](#subagent-configuration)
    - [Skill Design](#skill-design)
    - [MCP Server Usage](#mcp-server-usage)
    - [Context Optimization](#context-optimization)
  - [Key Insight](#key-insight)
    - [The Three Extension Mechanisms](#the-three-extension-mechanisms)
  - [References](#references)

---

## Subagents (Task Tool)

### What They Are

Subagents are specialized AI assistants spawned via the `Task` tool. Each operates as an independent Claude instance with its own conversation context.

### Key Characteristics

**Isolation Model**

- Each subagent gets its own context window (separate from main instance)
- Own conversation transcript stored locally
- Starts fresh on each invocation ("clean slate")
- Inherits subset of tools from main instance (configurable)

**Memory Behavior**

- No memory between separate invocations
- *Can* be resumed via agent ID to continue previous work
- No cross-agent memory sharing
- No access to main instance's conversation history

**Context Flow**

```
Main Instance
    │
    ├─ Delegates task via Task tool
    │
    ▼
Subagent (fresh context)
    ├─ Executes independently
    ├─ Maintains separate transcript
    └─ Returns summary to main instance
    │
    ▼
Main Instance resumes (subagent work didn't pollute context)
```

### When to Use Subagents

- Complex multi-turn reasoning needed
- Task requires specialized instructions/system prompt
- Work would consume >20 turns in main context
- Need separate conversation history
- Want to restrict tool access for safety

**Examples**: Security code review, architecture analysis, complex debugging, exploration tasks

### Example: When to Create a Custom Subagent

#### Example 1: Domain-Specific Code Reviewer

**Scenario**: Your team works on a fintech platform with strict compliance requirements. Every PR needs review for PCI-DSS violations, audit logging gaps, and data retention policy adherence.

**Why a subagent (not a skill)**:

- Multi-turn investigation required (trace data flows, check multiple files)
- Needs specialized system prompt with your compliance rules
- Findings should be isolated - you don't want 50 turns of compliance analysis polluting your main context
- Resumable if interrupted mid-review

**Structure**:

```
.claude/agents/
  compliance-reviewer/
    CLAUDE.md    # Your PCI-DSS rules, audit requirements, data policies
```

**CLAUDE.md contents**:

```text
You are a compliance-focused code reviewer for a fintech platform.

## Review Checklist
- [ ] No PAN (card numbers) logged or stored in plaintext
- [ ] All data access creates audit trail entries
- [ ] PII has retention policy annotations
- [ ] Authentication state validated before sensitive operations

## Output Format
Return findings as:
- CRITICAL: Compliance violation (blocks merge)
- WARNING: Potential issue (needs justification)
- INFO: Suggestion for improvement
```

**Usage**: "Use the compliance-reviewer agent to review the payment processing changes in this PR"

---

#### Example 2: Legacy System Migration Assistant

**Scenario**: You're migrating from a legacy Python 2 codebase to modern Python 3 with async support. The migration requires understanding old patterns, proposing modern equivalents, and tracking what's been migrated.

**Why a subagent (not MCP or skill)**:

- Needs to hold context about the legacy system's patterns across many files
- Multi-turn reasoning: "this old pattern maps to this new pattern"
- Should track migration state without cluttering main conversation
- May need restricted tools (read-only initially, then write access for implementation)

**Structure**:

```
.claude/agents/
  migration-assistant/
    CLAUDE.md
    legacy-patterns.md      # Documented patterns from old codebase
    modern-equivalents.md   # Target patterns
```

**CLAUDE.md contents**:

```text
You assist with Python 2 → Python 3 async migration.

## Your Role
1. Analyze legacy code to identify patterns
2. Propose modern async equivalents
3. Track what's been migrated vs pending

## Legacy Patterns (see legacy-patterns.md)
## Modern Targets (see modern-equivalents.md)

## Rules
- Never mix sync and async in the same call chain
- Preserve all existing behavior during migration
- Flag any blocking I/O that needs async conversion
```

**Usage**: "Use the migration-assistant to analyze the database layer and propose async conversion"

---

#### Example 3: Incident Response Debugger

**Scenario**: Production incidents require systematic investigation - checking logs, tracing requests, examining recent deploys, correlating timestamps. You want a focused debugging session that doesn't lose context as the investigation deepens.

**Why a subagent**:

- Investigation can go 30+ turns deep following a thread
- Needs to maintain hypothesis state ("we ruled out X, now checking Y")
- Isolation prevents incident noise from polluting normal development context
- Resumable - critical for incidents that span shifts or need handoff

**Structure**:

```
.claude/agents/
  incident-debugger/
    CLAUDE.md
```

**CLAUDE.md contents**:

```text
You are an incident response debugger. Your job is systematic root cause analysis.

## Investigation Framework
1. GATHER: Collect symptoms, timestamps, affected users
2. HYPOTHESIZE: Form testable theories about root cause
3. TEST: Gather evidence for/against each hypothesis
4. NARROW: Eliminate hypotheses until root cause identified
5. DOCUMENT: Record findings for postmortem

## State Tracking
Maintain running state:
- Current hypothesis: [what you're testing]
- Ruled out: [eliminated causes]
- Evidence collected: [key findings]

## Rules
- Never guess - always gather evidence
- Document timestamp correlations
- Check recent deployments first
- Ask for access to logs/metrics when needed
```

**Usage**: "Use the incident-debugger to investigate why checkout latency spiked at 3pm"

---

### When NOT to Create a Subagent

Don't create a subagent when:

| Situation | Better Alternative |
|-----------|-------------------|
| Simple checklist to follow | Skill (auto-discovered, lightweight) |
| Need to fetch external data | MCP server (stateless tool) |
| One-off task, won't reuse | Just do it in main context |
| Process guidance, not delegation | Skill |
| Task completes in <10 turns | Main context is fine |

**Rule of thumb**: Create a subagent when you're *delegating work* that needs isolation. Use a skill when you're *guiding work* that happens in main context.

---

## Skills

### What They Are

Skills are **model-invoked knowledge components** - structured packages of instructions and supporting files that Claude discovers and activates automatically based on context.

### Technical Structure

```
.claude/skills/
  my-skill/
    SKILL.md           # YAML frontmatter + markdown instructions
    supporting-file.md # Loaded progressively when needed
    template.txt       # Additional resources
```

**SKILL.md anatomy:**

- `name`: Lowercase identifier (max 64 chars)
- `description`: What triggers auto-discovery (max 1024 chars)
- `allowed-tools` (optional): Restricts available tools when active

### Key Characteristics

**Context Injection (Not Isolation)**

- Skills inject into the *main* conversation context
- No separate context window (unlike subagents)
- Supporting files loaded progressively to manage context bloat
- Skill's reasoning happens in main instance

**Auto-Discovery**

- Claude reads available skill descriptions at initialization
- Automatically activates when description matches current task
- No explicit invocation required (unlike slash commands)
- Description quality determines discovery success

**Sources**

1. Personal: `~/.claude/skills/` (individual workflows)
2. Project: `.claude/skills/` (team-shared, version controlled)
3. Plugin: Bundled in installed plugins' `skills/` directories

### Context Window Impact

Skills are **lightweight context additions**:

- Only the SKILL.md instructions load initially
- Supporting files load on-demand (progressive disclosure)
- No separate token budget - consumes main context
- Well-designed skills minimize footprint until needed

### When to Use Skills

- Reusable workflows/processes
- Domain-specific knowledge injection
- Team standardization of approaches
- Automatic activation based on task type

**Examples**: TDD workflow, debugging framework, code review checklist, brainstorming process

### Example: When to Create a Custom Skill

#### Example 1: API Design Guidelines

**Scenario**: Your team has established REST API conventions - naming patterns, error response formats, pagination standards, versioning rules. Every new endpoint should follow these patterns.

**Why a skill (not a subagent)**:

- Guidance for work happening in main context (not delegated)
- Lightweight - just needs to inject the rules when API work is detected
- No multi-turn investigation needed
- Should auto-activate when you're working on endpoints

**Structure**:

```
.claude/skills/
  api-design/
    SKILL.md
    error-formats.md       # Loaded when discussing errors
    pagination-patterns.md # Loaded when discussing list endpoints
```

**SKILL.md contents**:

```text
---
name: api-design
description: Use when designing, implementing, or reviewing REST API endpoints. Provides team conventions for naming, errors, pagination, and versioning.
---

# API Design Guidelines

## Naming Conventions
- Resources are plural nouns: `/users`, `/orders`, `/products`
- Actions use verbs: `/users/{id}/activate`, `/orders/{id}/cancel`
- Query params for filtering: `?status=active&created_after=2024-01-01`

## HTTP Methods
- GET: Read (idempotent)
- POST: Create
- PUT: Full replace
- PATCH: Partial update
- DELETE: Remove

## Response Envelope
All responses use:
{
  "data": { ... },
  "meta": { "request_id": "...", "timestamp": "..." }
}

## Error Format

See @error-formats.md for standard error responses.

## Pagination

See @pagination-patterns.md for cursor-based pagination standards.

```

**Auto-triggers when**: "add an endpoint for...", "design the API for...", "review this controller"

---

#### Example 2: Database Migration Checklist

**Scenario**: Database migrations are high-risk. Your team has a checklist: backward compatibility, rollback plan, index impact, data backfill strategy. You want Claude to automatically apply this thinking when migration work is detected.

**Why a skill (not a subagent)**:

- Checklist guidance, not delegated investigation
- Should enhance normal workflow, not isolate it
- Lightweight - just the checklist and considerations
- Works within main conversation context

**Structure**:

```

.claude/skills/
  db-migrations/
    SKILL.md

```

**SKILL.md contents**:

```text
---
name: db-migrations
description: Use when creating, reviewing, or planning database migrations. Ensures backward compatibility, rollback safety, and performance considerations.
---

# Database Migration Checklist

## Before Writing Migration

1. **Backward Compatibility**
   - Can old code work with new schema during deploy?
   - Are column renames done as add-copy-drop (not rename)?
   - Are NOT NULL columns added with defaults?

2. **Rollback Plan**
   - Is down migration possible and tested?
   - Will rollback lose data? Document if so.

3. **Performance Impact**
   - Large table? Estimate lock time.
   - Adding index? Consider CONCURRENTLY (Postgres) or pt-online-schema-change.
   - Data backfill? Batch it, don't do in migration.

## Migration Code Standards

- One logical change per migration
- Timestamp-based naming: `20240115143022_add_user_preferences.sql`
- Include both up and down
- Test on production-size dataset before merge

## Red Flags
- DROP COLUMN without deprecation period
- Changing column types on large tables
- Adding unique constraint without checking duplicates
```

**Auto-triggers when**: "create a migration", "add a column", "change the schema", "database migration"

---

#### Example 3: Security Review Lens

**Scenario**: You want security thinking applied to normal code review - not a full audit (that's a subagent), but awareness of common vulnerabilities during regular development.

**Why a skill (not a subagent)**:

- Enhances regular code review, doesn't replace it
- Lightweight awareness, not deep investigation
- Should auto-activate during any code changes
- Part of main workflow, not isolated

**Structure**:

```
.claude/skills/
  security-lens/
    SKILL.md
    owasp-quick-ref.md
```

**SKILL.md contents**:

```text
---
name: security-lens
description: Apply security awareness during code review and implementation. Catches common vulnerabilities without requiring full security audit.
allowed-tools:
  - Read
  - Grep
  - Glob
---

# Security Awareness Lens

When reviewing or writing code, check for:

## Input Handling
- [ ] User input validated before use
- [ ] SQL uses parameterized queries (never string concat)
- [ ] HTML output escaped to prevent XSS
- [ ] File paths validated (no path traversal)

## Authentication/Authorization
- [ ] Auth checks at controller level, not just UI
- [ ] Sensitive operations re-verify permissions
- [ ] Session tokens are httpOnly, secure, sameSite

## Data Exposure
- [ ] Logs don't contain secrets, tokens, PII
- [ ] Error messages don't leak internal details
- [ ] API responses don't include unnecessary fields

## Secrets
- [ ] No hardcoded credentials
- [ ] Secrets from environment/vault, not config files
- [ ] .gitignore covers .env, credentials

See @owasp-quick-ref.md for detailed vulnerability patterns.
```

**Auto-triggers when**: Writing code, reviewing PRs, discussing implementation

---

### When NOT to Create a Skill

Don't create a skill when:

| Situation | Better Alternative |
|-----------|-------------------|
| Deep multi-file investigation | Subagent (needs isolation) |
| Task needs its own conversation | Subagent (separate context) |
| External API/data access | MCP server (stateless tool) |
| One-off project-specific thing | Just put it in CLAUDE.md |
| Complex stateful workflow | Subagent (can maintain state) |

**Rule of thumb**: Create a skill when you want to *inject guidance* into normal work. Create a subagent when you want to *delegate work* entirely.

### Skills vs CLAUDE.md

Both inject into context, so when use which?

| CLAUDE.md | Skills |
|-----------|--------|
| Always loaded | Auto-discovered by relevance |
| Project-wide rules | Task-specific guidance |
| Coding standards, preferences | Workflows, checklists |
| Small, essential context | Can be larger (progressive loading) |
| One file | Directory with supporting files |

**Example**: "Use 4-space indentation" → CLAUDE.md. "How to design an API endpoint" → Skill.

### Skills vs Subagents

| Skills | Subagents |
|--------|-----------|
| Inject into main context | Own isolated context |
| Auto-discovered | Explicitly invoked |
| Lightweight (progressive loading) | Higher overhead (full context) |
| Share conversation memory | Fresh start each time |
| Enhance main instance | Delegate to separate instance |

**Rule of thumb**: Skills for *how* to approach work. Subagents for *delegating* work.

### Pattern: Lens (Skill) + Reviewer (Subagent)

A common question: "Should X be a skill or subagent?" Often the answer is **both** - a lightweight version and a deep version.

#### The Pattern

| Component | Purpose | When Used |
|-----------|---------|-----------|
| **Lens** (Skill) | Awareness during normal work | Always on, auto-discovered |
| **Reviewer** (Subagent) | Thorough investigation | On-demand, explicit delegation |

#### Example: Code Review

```
.claude/skills/
  code-review-lens/          # Light: catches issues while coding
    SKILL.md

.claude/agents/
  code-reviewer/             # Deep: full PR review on demand
    CLAUDE.md
```

**code-review-lens/SKILL.md** (auto-activates during any coding):

```text
---
name: code-review-lens
description: Apply code review awareness during implementation. Catches common issues without requiring full review.
---

# Code Review Awareness

While writing code, watch for:
- [ ] Functions under 30 lines
- [ ] Clear naming (no abbreviations)
- [ ] Error cases handled
- [ ] No hardcoded values
- [ ] Tests cover new behavior
```

**code-reviewer/CLAUDE.md** (invoked explicitly for PR review):

```text
You perform thorough code reviews. Your job is to find issues the author missed.

## Review Process
1. Understand the PR's purpose (read description, linked issues)
2. Trace the changes across all affected files
3. Check for logic errors, edge cases, security issues
4. Verify test coverage is adequate
5. Assess impact on existing functionality

## Output Format
- MUST FIX: Blocks merge (bugs, security, data loss)
- SHOULD FIX: Important but not blocking
- CONSIDER: Suggestions for improvement
- PRAISE: Things done well (be specific)
```

#### When to Use Which

| Situation | Use |
|-----------|-----|
| Writing new code | Lens (skill) auto-activates |
| Quick self-check before commit | Lens (skill) |
| Reviewing someone's PR | Reviewer (subagent) |
| Pre-merge thorough review | Reviewer (subagent) |
| Security audit | Reviewer (subagent) |

#### Other Domains That Fit This Pattern

| Domain | Lens (Skill) | Reviewer (Subagent) |
|--------|--------------|---------------------|
| Security | security-lens | security-auditor |
| Performance | perf-awareness | perf-analyzer |
| Accessibility | a11y-checklist | a11y-auditor |
| Documentation | docs-standards | docs-reviewer |
| Testing | test-guidance | test-coverage-analyzer |

The lens keeps you aware. The reviewer does the deep work.

---

## MCP Servers

### What They Are

External processes following the Model Context Protocol standard. They expose deterministic tools without reasoning capability.

### Key Characteristics

**Stateless Design**

- Each tool call is independent
- No memory of previous requests
- No conversation context
- Fresh query every time

**Tool Exposure Mechanisms**

1. **Direct Tools**: `mcp__github__list_prs`, `mcp__database__query`
2. **Resources**: `@github#my-org/my-repo` (selective context injection)
3. **Slash Commands**: `/mcp__github__create_issue`

**Architecture**

```
Claude Code (Client)
    │
    ├─ HTTP/Stdio/SSE connection
    ▼
MCP Server (stateless)
    ├─ Processes request
    ├─ Returns structured result
    └─ No memory retained
```

### Output Limits

- Default max: 25,000 tokens per server response
- Warning at 10,000 tokens
- Truncation enforced automatically

### When to Use MCP Tools

- External data retrieval
- API calls (GitHub, Slack, databases)
- Deterministic operations (same input = same output)
- Lightweight, frequent tool calls
- No reasoning required beyond data retrieval

---

## Context Window Implications

### Main Instance

Token budget consumed by:

1. **Conversation history** (largest consumer)
2. **Memory system** (CLAUDE.md hierarchy loaded at startup)
3. **File references** (`@path/to/file` inclusions)
4. **Tool results** (bounded at 25K per MCP call)

### Subagent Context Distribution

Each subagent gets independent context:

- Separate token budget
- Fresh conversation history
- Inherits tools but not conversation

**Efficiency Gain**: A 50-turn debugging session becomes 10 turns in main + 40 in subagent, preserving main context for other work.

### MCP Context Impact

Minimal overhead:

- Tool input: Few tokens
- Tool output: Bounded at 25K max
- No accumulation across calls

---

## Memory System Architecture

### Hierarchical Memory (Not Episodic)

Claude Code uses procedural/organizational memory, not conversation history:

```
1. Enterprise Policy (highest precedence)
   ↓
2. Project Memory (CLAUDE.md in version control)
   ↓
3. User Memory (~/.claude/CLAUDE.md)
   ↓
4. Project Local Memory (.claude/CLAUDE.local.md)
```

### Memory Isolation Boundaries

| Layer | Scope | Shared With |
|-------|-------|-------------|
| Enterprise | Organization-wide | All users |
| Project | Team | Repo collaborators |
| User | Personal | No one |
| Local | Machine-specific | No one |

### What Memory Stores

- Coding standards and conventions
- Architecture patterns
- Team processes
- Tool configurations
- Technical constraints

**Not stored**: Conversation history (use episodic-memory plugin for that)

### Memory Impact on Context

- All discovered CLAUDE.md files loaded at startup
- Consume tokens but essential for context
- Prompt caching reduces repeated tokenization cost

---

## Data Flow Comparison

### Subagent Flow

```
User Request
    │
Main Instance determines delegation needed
    │
Task tool invoked
    │
Pre-tool hook (optional validation)
    │
Subagent spawned with fresh context
    │
Subagent executes (may call MCP tools)
    │
Post-tool hook (optional logging)
    │
Main Instance receives summary
    │
Main context preserved (no pollution)
```

### MCP Tool Flow

```
Claude determines tool needed
    │
Tool call prepared (input bounded)
    │
Pre-tool hook (optional validation)
    │
MCP Server processes (stateless)
    │
Output limited (25K max)
    │
Post-tool hook (optional logging)
    │
Result incorporated into context
```

---

## Decision Matrix

```
What kind of capability extension?
│
├─ External data/API call?
│  └─ YES → MCP Tool (stateless, deterministic)
│
├─ Reusable workflow/process guidance?
│  └─ YES → Skill (auto-discovered, context-injected)
│
├─ Multi-turn reasoning in isolation?
│  └─ YES → Subagent (separate context window)
│
├─ Would bloat main context (>20 turns)?
│  └─ YES → Subagent (isolate the work)
│
├─ Team-standardized approach needed?
│  └─ YES → Skill (version-controlled in .claude/skills/)
│
├─ Need specialized system prompt?
│  └─ YES → Subagent (custom instructions per agent)
│
└─ Need isolated conversation history?
   └─ YES → Subagent
   └─ NO → Main instance (possibly with skills)
```

### Quick Reference

| Need | Use |
|------|-----|
| Fetch from GitHub/DB/API | MCP Server |
| Follow TDD process | Skill |
| Debug complex issue | Subagent |
| Standard code review checklist | Skill |
| Security audit with findings | Subagent |
| Query deployment status | MCP Server |
| Brainstorming framework | Skill |
| Explore unfamiliar codebase | Subagent |

---

## Best Practices

### Subagent Configuration

- Restrict tool access to what's actually needed
- Use domain-specific system prompts
- Note agent ID for potential resumption

### Skill Design

- Write precise descriptions (determines auto-discovery success)
- Use progressive disclosure - main instructions in SKILL.md, details in supporting files
- Restrict `allowed-tools` if skill shouldn't access everything
- Version control project skills for team consistency

### MCP Server Usage

- Don't assume state between calls
- Include full context in each tool call
- Monitor output sizes with `/context`

### Context Optimization

- Use 1M token window for long sessions
- Delegate to subagents to distribute workload
- Reference files selectively
- Let prompt caching handle repeated references
- Design skills for minimal initial footprint

---

## Key Insight

Each component solves a specific constraint:

- **Subagents** solve context bloat (distribute work across isolated contexts)
- **Skills** solve workflow standardization (auto-discovered process injection)
- **MCP Servers** solve external integration (lightweight tool access without agents)
- **Memory System** solves knowledge distribution (hierarchical, inheritable instructions)
- **Hooks** solve auditing (intercept and validate all operations)

Together they enable scaling from simple conversations to complex multi-system workflows while maintaining context efficiency.

### The Three Extension Mechanisms

```
┌─────────────────────────────────────────────────────────────┐
│                    Main Claude Instance                     │
│                                                             │
│  ┌────────────────────────────────────────────────────────┐ │
│  │ Context Window                                         │ │
│  │                                                        │ │
│  │  ┌─────────────┐  Skills inject here                   │ │
│  │  │  Skills     │  (auto-discovered,                    │ │
│  │  │  (process   │   progressive loading)                │ │
│  │  │  guidance)  │                                       │ │
│  │  └─────────────┘                                       │ │
│  │                                                        │ │
│  │  + Conversation + Memory + Files + Tool Results        │ │
│  └────────────────────────────────────────────────────────┘ │
│                          │                                  │
│            ┌─────────────┴─────────────┐                    │
│            ▼                           ▼                    │
│   ┌─────────────────┐        ┌─────────────────┐            │
│   │ Task Tool       │        │ MCP Tool Calls  │            │
│   │ (delegates)     │        │ (stateless)     │            │
│   └────────┬────────┘        └────────┬────────┘            │
└────────────┼──────────────────────────┼─────────────────────┘
             │                          │
             ▼                          ▼
    ┌─────────────────┐        ┌─────────────────┐
    │   Subagent      │        │   MCP Server    │
    │ (own context)   │        │   (external)    │
    │                 │        │                 │
    │ Isolated AI     │        │ Deterministic   │
    │ reasoning       │        │ tool execution  │
    └─────────────────┘        └─────────────────┘
```

**Summary**: Skills enhance *how* the main instance works. Subagents *offload* work to isolated instances. MCP servers *fetch* from external systems.

---

## References

Official Claude Code documentation:

- [Subagents](https://code.claude.com/docs/en/sub-agents.md) - Task delegation, isolation model, resumption
- [Skills](https://code.claude.com/docs/en/skills.md) - SKILL.md structure, auto-discovery, progressive loading
- [MCP Servers](https://code.claude.com/docs/en/mcp.md) - Tool integration, transports, output limits
- [Memory](https://code.claude.com/docs/en/memory.md) - CLAUDE.md hierarchy, imports, organization memory
- [Hooks](https://code.claude.com/docs/en/hooks.md) - Event interception, validation, auditing
- [Model Configuration](https://code.claude.com/docs/en/model-config.md) - Context windows, prompt caching
- [Slash Commands](https://code.claude.com/docs/en/slash-commands.md) - Command invocation patterns
