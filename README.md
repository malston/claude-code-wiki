# Claude Code Wiki

Personal knowledge base for optimizing outcomes with Claude Code - patterns, techniques, and architectural understanding for getting the most from AI-assisted development.

## Contents

### [Extension Mechanisms: Subagents, Skills, and MCP Servers](claude-code-extension-mechanisms.md)

Understanding the three ways Claude Code extends capabilities and when to use each:

**Covered topics:**

- Technical architecture of each mechanism
- When to use each approach (with decision matrix)
- Real-world examples for custom implementations
- Context window and memory implications
- Data flow comparisons and best practices

**Quick reference:**

| Aspect         | Subagents          | Skills            | MCP Servers          |
| -------------- | ------------------ | ----------------- | -------------------- |
| **Purpose**    | Task delegation    | Workflow guidance | External access      |
| **Reasoning**  | Full AI (isolated) | Inherits main     | None (deterministic) |
| **Memory**     | Session-based      | Shared with main  | Stateless            |
| **Context**    | Own window         | Injected          | Minimal overhead     |
| **Invocation** | Explicit           | Auto-discovered   | Explicit tool calls  |

**Key pattern: Lens + Reviewer**

Implementing both lightweight awareness (skill) and deep analysis (subagent) for the same domain:

- `security-lens` (skill) - Auto-activates during coding
- `security-auditor` (subagent) - Deep analysis when explicitly invoked

### [Optimizing Token Usage: Skills, Plugins, and Context Budget](claude-code-token-optimization.md)

Managing the per-message token overhead from skills, plugins, and system configuration:

**Covered topics:**

- Two-phase cost model (catalog vs invocation)
- How to audit your plugin and skill setup
- Decision framework for keep/disable/replace
- Worked example: cutting 21 plugins to 9
- Managing skills with `claudeup` and plugin settings

**Quick reference:**

| Component                | When Loaded        | Token Cost Pattern          |
| ------------------------ | ------------------ | --------------------------- |
| **Skill catalog**        | Every message      | ~25-100 tokens per skill    |
| **Skill content**        | On invocation only | Varies                      |
| **Plugin subagents**     | Every message      | ~50-150 tokens per subagent |
| **CLAUDE.md files**      | Every message      | Entire file contents        |
| **MCP tool definitions** | Every message      | ~30-80 tokens per tool      |

**Key insight:** A setup with 20+ plugins can consume 4,000-5,000+ tokens per message just for the skill/subagent catalog -- before any actual work happens.

### [The System Prompt: What Claude Reads Before You Say Anything](claude-code-system-prompt.md)

Understanding the hidden instruction text assembled and sent on every API call:

**Covered topics:**

- What the system prompt is and how it's assembled
- Anatomy of a Claude Code API call (system prompt + conversation + reminders)
- Every component: core instructions, tool definitions, CLAUDE.md, skill/subagent catalogs, MCP, environment
- Token cost implications and prompt caching
- What you can and can't control

**Quick reference:**

| Component             | Source                   | Typical Size              |
| --------------------- | ------------------------ | ------------------------- |
| **Core instructions** | Claude Code built-in     | ~3,000-5,000 tokens       |
| **Tool definitions**  | Built-in + MCP servers   | ~3,000-5,000 tokens       |
| **CLAUDE.md files**   | All scopes               | ~2,000-4,000 tokens       |
| **Skill catalog**     | Enabled skills + plugins | ~2,000-5,000 tokens       |
| **Subagent catalog**  | Plugin descriptions      | ~1,000-2,000 tokens       |
| **Typical total**     |                          | **~12,000-20,000 tokens** |

**Key insight:** The system prompt is re-sent on every API call. Prompt caching mitigates cost (~90% discount after first message), but the context window space is consumed regardless.

### [Prompt Caching: Why Your System Prompt Doesn't Cost What You Think](claude-code-prompt-caching.md)

How prompt caching reduces the cost of re-sending the system prompt on every API call:

**Covered topics:**

- How prefix-based caching works
- Cache hierarchy in Claude Code (tools → system → messages)
- Full pricing breakdown with worked cost examples
- Cache lifetime, minimum token requirements, and invalidation rules
- Cost optimization vs context optimization distinction

**Quick reference:**

| Operation              | Multiplier | Opus 4.6   | Sonnet 4.5 |
| ---------------------- | ---------- | ---------- | ---------- |
| **Cache write (5min)** | 1.25x base | $6.25/MTok | $3.75/MTok |
| **Cache read**         | 0.1x base  | $0.50/MTok | $0.30/MTok |
| **Uncached input**     | 1x base    | $5/MTok    | $3/MTok    |

**Key insight:** Cache reads are 10x cheaper than base input. A 15,000-token system prompt costs ~$1.60 over a 200-message Opus 4.6 session with caching, vs ~$15 without.

### [Context Management: Working Within the Token Budget](claude-code-context-management.md)

Strategies for managing the context window -- Claude's working memory during a session:

**Covered topics:**

- What the context window is and how it fills up
- What consumes context (file reads are the biggest variable cost)
- Compaction: auto-compact, manual `/compact`, and what's preserved vs lost
- Subagents as context management (97.5% context savings on delegated work)
- Extended thinking and context implications
- Practical strategies for long sessions

**Quick reference:**

| Model          | Standard | Extended (Beta) | Long Context Pricing |
| -------------- | -------- | --------------- | -------------------- |
| **Opus 4.6**   | 200K     | 1M              | 2x input above 200K  |
| **Sonnet 4.5** | 200K     | 1M              | 2x input above 200K  |
| **Haiku 4.5**  | 200K     | --              | --                   |

**Key insight:** Caching reduces cost; context management reduces space consumption. They're complementary -- you need both.

### [Effective Prompting: Getting Better Results from Claude Code](claude-code-effective-prompting.md)

How to structure your requests for better outcomes -- from single messages to multi-session workflows:

**Covered topics:**

- How Claude Code processes your messages (system prompt + conversation + your input)
- The fundamentals: be explicit, action vs suggestion, provide context, reference specific code
- Task decomposition and the iterative refinement loop
- CLAUDE.md as persistent prompting (what to include, what to omit, keeping it concise)
- Working across context windows (tests-first, state files, fresh vs compaction)
- Directing tool usage (subagent delegation, parallel operations, managing over-exploration)
- Common anti-patterns to avoid

**Quick reference:**

| Principle                    | Impact                                          | Effort   |
| ---------------------------- | ----------------------------------------------- | -------- |
| **Be explicit, not vague**   | Biggest single improvement in result quality    | Low      |
| **Action over suggestion**   | Gets implementation instead of recommendations  | Low      |
| **Provide context ("why")**  | Helps Claude generalize and make good choices   | Low      |
| **Reference specific code**  | Eliminates guesswork and speeds up responses    | Low      |
| **Decompose large tasks**    | Reduces errors, enables course correction       | Medium   |
| **Use CLAUDE.md well**       | Persistent rules applied to every message       | One-time |
| **Manage multi-window work** | Enables tasks that span beyond a single session | Medium   |

**Key insight:** Specific prompts get specific results. The biggest improvement comes from stating what you want, where, and why -- not from clever prompt engineering tricks.

### [Memory Organization: Structuring CLAUDE.md and Rules for Scale](claude-code-memory-organization.md)

How to organize Claude Code's memory system -- CLAUDE.md files, rules directories, auto memory, and imports:

**Covered topics:**

- The memory hierarchy: managed policy, project, user, local, auto memory, child CLAUDE.md
- How files are discovered (directory walk) and precedence rules
- User memory vs project memory vs project local -- what goes where
- The `.claude/rules/` directory for modular, path-specific rules
- Auto memory: the 200-line limit and topic file pattern
- Imports (`@path/to/file` syntax) for sharing content across files
- Context cost of memory files and how to measure your footprint
- Common mistakes (generic instructions, monolithic files, scope conflicts)

**Quick reference:**

| Memory Type        | Location                               | Scope              | Shared With           |
| ------------------ | -------------------------------------- | ------------------ | --------------------- |
| **Managed policy** | System-level path (IT-managed)         | Organization-wide  | All users             |
| **Project memory** | `./CLAUDE.md` or `./.claude/CLAUDE.md` | Team + project     | Team (via git)        |
| **Project rules**  | `./.claude/rules/*.md`                 | Team + project     | Team (via git)        |
| **User memory**    | `~/.claude/CLAUDE.md`                  | All your projects  | Just you              |
| **Project local**  | `./CLAUDE.local.md`                    | You + this project | Just you (gitignored) |
| **Auto memory**    | `~/.claude/projects/<project>/memory/` | You + this project | Just you              |

**Key insight:** Every line of CLAUDE.md costs context window space on every message. Be specific, not generic -- "use slog for logging" beats "follow best practices."

### [Workflow Patterns: Common Development Workflows with Claude Code](claude-code-workflow-patterns.md)

Core development workflows and how to structure work around Claude Code's strengths:

**Covered topics:**

- The core loop: instruct, review, course-correct
- Explore-Plan-Implement: separating research from coding, the interview pattern
- Fix with verification: reproduce, fix, verify
- Test-driven development: tests as durable requirements across sessions
- Code review: writer/reviewer pattern with fresh sessions
- Session management: `/clear`, rewind, named sessions, resuming work
- Multi-session and parallel work: git worktrees, headless mode, fan-out pattern
- Subagent patterns: investigation, post-implementation review, avoiding overuse
- Common failure patterns and how to fix them

**Quick reference:**

| Workflow                      | When to Use                        | Key Pattern                              |
| ----------------------------- | ---------------------------------- | ---------------------------------------- |
| **Explore-Plan-Implement**    | New features, unfamiliar code      | Separate research from coding            |
| **Fix with Verification**     | Bug fixes, error resolution        | Reproduce, fix, verify                   |
| **Test-Driven Development**   | New features, bug fixes            | Write tests first, then implement        |
| **Code Review**               | Before merge, after implementation | Fresh session, different perspective     |
| **Multi-Session**             | Large features, multi-day work     | State files, named sessions, checkpoints |
| **Headless / CI Integration** | Automated checks, batch operations | `claude -p` with structured output       |

**Key insight:** Give Claude a way to verify its own work -- tests, linters, build commands, screenshots. This single pattern is the highest-leverage improvement to any workflow.

### [Debugging Techniques: Systematic Troubleshooting with Claude Code](claude-code-debugging-techniques.md)

A systematic approach to debugging with Claude Code -- from sharing errors effectively to tracing root causes:

**Covered topics:**

- The four-phase debugging framework: understand, reproduce, investigate, fix
- Sharing errors effectively (what to include, what not to do)
- Tracing techniques: backward tracing, git history, log analysis, architectural reasoning
- Common bug categories: test failures, runtime errors, "it worked before," intermittent failures
- Using subagents to investigate without polluting context
- Debugging across context windows (clearing, saving progress, git checkpoints)
- Anti-patterns: symptom patching, shotgun debugging, ignoring error messages, fixing tests instead of code

**Quick reference:**

| Technique                     | When to Use                                  | Key Benefit                            |
| ----------------------------- | -------------------------------------------- | -------------------------------------- |
| **Share the actual error**    | Always, as the first step                    | Eliminates guessing                    |
| **Reproduce first**           | Before attempting any fix                    | Confirms the problem, verifies the fix |
| **Trace backward**            | When the error location isn't the root cause | Finds where the problem originates     |
| **Git history investigation** | When it "used to work"                       | Finds the breaking change              |
| **Hypothesis testing**        | Complex bugs with multiple possible causes   | Systematic narrowing to root cause     |

**Key insight:** Understand the root cause before attempting a fix. A failing test that captures the bug, followed by a targeted fix, beats any number of speculative patches.

### [Testing Strategies: TDD Patterns and Test Automation](claude-code-testing-strategies.md)

How to structure test-driven development with Claude Code -- from writing effective tests to automating test workflows:

**Covered topics:**

- Why tests matter more with AI-assisted development (feedback loops, verification)
- TDD red-green-refactor cycle adapted for Claude Code
- Prompting for tests (what to include, what to avoid)
- Context isolation: the writer/implementer split for unbiased tests
- What makes a good test (match patterns, avoid mocks, test behavior, edge cases)
- Tests as durable requirements across context windows and sessions
- Automating with hooks, CLAUDE.md rules, and headless CI
- Test coverage strategies and incremental improvement

**Quick reference:**

| Strategy                        | When to Use                           | Key Benefit                                    |
| ------------------------------- | ------------------------------------- | ---------------------------------------------- |
| **Test-first (TDD)**            | New features, bug fixes               | Tests define requirements, Claude has a target |
| **Test-after**                  | Exploratory work, prototyping         | Locks down behavior once approach is settled   |
| **Existing test suite**         | Refactoring, bug fixes in tested code | Safety net already exists, just run it         |
| **Separate writer/implementer** | High-quality features, complex logic  | Context isolation prevents bias                |
| **Hooks for auto-testing**      | All development                       | Immediate feedback after every edit            |
| **Headless test runner**        | CI/CD, batch validation               | Automated verification at scale                |

**Key insight:** Tests give Claude a concrete feedback loop. Without tests, Claude produces code that looks right. With tests, Claude iterates until the output actually passes.

### [Integration Patterns: Connecting Claude Code with External Tools and Services](claude-code-integration-patterns.md)

How to connect Claude Code with external systems -- from MCP servers and hooks to headless mode and CI/CD:

**Covered topics:**

- The four integration mechanisms: MCP servers, hooks, headless mode, GitHub Actions
- MCP server configuration: transports, scopes, authentication, Tool Search
- Hook lifecycle: events, matchers, command/prompt/agent types, async hooks
- Headless mode: `-p` flag, output formats, piping, system prompt customization
- GitHub Actions: official action, setup, common workflows, cost optimization
- Claude as MCP server (exposing tools to other applications)
- Plugins as packaged integrations (bundling MCP + hooks + skills)
- Integration decision framework and combining patterns

**Quick reference:**

| Mechanism          | Purpose                       | Direction            | Runs When                |
| ------------------ | ----------------------------- | -------------------- | ------------------------ |
| **MCP servers**    | Connect external tools/data   | Claude calls out     | Claude decides to use it |
| **Hooks**          | Automate around Claude's work | System calls scripts | Lifecycle events fire    |
| **Headless mode**  | Script Claude from outside    | External calls in    | Your script invokes it   |
| **GitHub Actions** | CI/CD automation              | Events call Claude   | GitHub events trigger it |

**Key insight:** Each mechanism operates at a different layer and serves a different purpose. MCP for tool access, hooks for automation, headless for scripting, GitHub Actions for CI/CD. The real power comes from combining them.

### [Model Selection & Cost Management: Choosing the Right Model and Controlling Spend](claude-code-model-selection.md)

How to choose between Opus, Sonnet, and Haiku -- and how to manage what you spend:

**Covered topics:**

- The three model tiers: capabilities, pricing, and speed tradeoffs
- Decision framework for choosing the right model per task
- Configuration: aliases, switching, opusplan strategy, effort levels, extended context
- Subagent model selection for cost-efficient delegation
- How costs accumulate: input, output, caching, extended thinking
- Cost reduction strategies: context management, hook preprocessing, headless budgets
- Session-level and team-level cost tracking

**Quick reference:**

| Model          | Strengths                       | Input/MTok | Output/MTok | Cache Read | Speed    |
| -------------- | ------------------------------- | ---------- | ----------- | ---------- | -------- |
| **Opus 4.6**   | Complex reasoning, architecture | $5         | $25         | $0.50      | Moderate |
| **Sonnet 4.5** | Daily coding, balanced          | $3         | $15         | $0.30      | Fast     |
| **Haiku 4.5**  | Quick tasks, simple operations  | $1         | $5          | $0.10      | Fastest  |

**Key insight:** Model selection is the single biggest cost lever. Using Sonnet instead of Opus for routine coding cuts input costs by 40% and output costs by 40%. Using Haiku for simple tasks cuts costs by 80%.

### [Custom Hooks Cookbook: Practical Recipes for Automating Claude Code](claude-code-hooks-cookbook.md)

Copy-paste-ready hook recipes for the most common automation needs:

**Covered topics:**

- Hook fundamentals: types (command, prompt, agent), exit codes, JSON output format
- Complete event reference: all 14 lifecycle events with matcher syntax
- Code quality recipes: auto-format (Prettier, gofmt, Ruff, ESLint) on save
- Safety recipes: block dangerous commands, protect files, guard branches, prevent credential leaks
- Verification recipes: test gates, build checks, stop-until-passing
- Notification recipes: macOS/Linux desktop, Slack webhooks
- Logging recipes: command audit, session tracking, debug wrappers
- Context injection: post-compaction reminders, project state, environment variables
- Quality gates: prompt-based and agent-based Stop hooks
- Combining hooks into complete safety and CI-style setups

**Quick reference:**

| Category          | Example Recipes                                       | Hook Events Used                  |
| ----------------- | ----------------------------------------------------- | --------------------------------- |
| **Code quality**  | Auto-format, lint on save, type check                 | PostToolUse (Edit\|Write)         |
| **Safety**        | Block dangerous commands, protect files, branch guard | PreToolUse (Bash, Edit\|Write)    |
| **Verification**  | Test gates, build checks, stop-until-passing          | PostToolUse, Stop, TaskCompleted  |
| **Notifications** | Desktop alerts, Slack, TTS                            | Notification                      |
| **Logging**       | Command audit, session tracking, debug wrapper        | PostToolUse, SessionStart         |
| **Context**       | Inject reminders, load state, persist env vars        | SessionStart, UserPromptSubmit    |
| **Quality gates** | Block stopping until tasks complete, review checks    | Stop, SubagentStop, TaskCompleted |

**Key insight:** Start simple -- one or two safety hooks are better than a complex multi-hook pipeline. Use PreToolUse for safety (blocking before execution) and PostToolUse for quality (formatting/testing after execution).

### [Building Custom Subagents & Skills: Extending Claude Code](claude-code-custom-extensions.md)

How to build custom subagents, skills, and plugins from scratch:

**Covered topics:**

- Subagents: file structure, YAML frontmatter, tool permissions, model selection, permission modes, persistent memory
- Skills: SKILL.md format, invocation control, auto-discovery, string substitutions, dynamic context injection
- The lens + reviewer pattern: lightweight awareness (skill) + deep analysis (subagent) for any domain
- Plugins: directory structure, manifest, bundling MCP servers + hooks + skills + subagents
- Managing extensions with `claudeup local`
- Scope and priority rules across project, user, and plugin levels

**Quick reference:**

| Extension    | What It Is                   | File Location               | When It Runs                  |
| ------------ | ---------------------------- | --------------------------- | ----------------------------- |
| **Subagent** | Isolated AI worker           | `.claude/agents/*.md`       | When Claude delegates a task  |
| **Skill**    | Injected instructions        | `.claude/skills/*/SKILL.md` | Auto-discovered or `/invoked` |
| **Plugin**   | Packaged bundle of all three | Plugin marketplace or local | When plugin is enabled        |

**Key insight:** Start with a skill, graduate to a subagent. If simple instructions aren't enough because the task needs multi-file investigation or isolated execution, that's when a subagent pays off.

### [Agent Teams: Multi-Agent Orchestration in Claude Code](claude-code-agent-teams.md)

How to coordinate multiple Claude Code instances working together on complex tasks:

**Covered topics:**

- Architecture: team lead, teammates, shared task list, mailbox messaging
- Subagents vs agent teams comparison (hub-and-spoke vs mesh)
- Starting teams, delegate mode, display modes (in-process, tmux, iTerm2)
- Task system: states, dependencies, self-claiming
- Communication: direct messages, broadcasts, idle notifications
- Team-specific hooks: TeammateIdle and TaskCompleted
- Plan approval workflow for high-stakes changes
- Team patterns: competing hypotheses, parallel review, research + implementation, fan-out/fan-in
- CLI flags: `--agent`, `--agents`, `--teammate-mode`

**Quick reference:**

| Aspect            | Subagents (Standard)           | Agent Teams                            |
| ----------------- | ------------------------------ | -------------------------------------- |
| **Communication** | Results return to parent only  | Teammates message each other directly  |
| **Coordination**  | Hub-and-spoke (parent manages) | Mesh (shared task list, self-organize) |
| **Best for**      | Focused tasks, research        | Parallel work, competing perspectives  |
| **Cost**          | Lower (results summarized)     | Higher (N separate instances)          |

**Key insight:** Agent teams shine when work benefits from parallel execution and competing perspectives. For sequential or focused tasks, standard subagents are simpler and cheaper.

### [Permissions & Enterprise Deployment: Securing and Scaling Claude Code](claude-code-permissions-enterprise.md)

How the permission system works and how to deploy Claude Code at organizational scale:

**Covered topics:**

- Permission modes: default, acceptEdits, plan, delegate, dontAsk, bypassPermissions
- Permission rules: allow/deny/ask lists with tool-specific syntax (Bash globs, gitignore paths, MCP tools)
- Settings cascade: 5 scopes with managed settings overriding everything
- Sandboxing: OS-level filesystem and network isolation
- Enterprise controls: managed policy files, `allowManagedHooksOnly`, `disableBypassPermissionsMode`
- API providers: Anthropic, AWS Bedrock, Google Vertex AI, Microsoft Foundry, LLM gateways
- CI/CD strategies: headless mode permissions, GitHub Actions configuration
- Security hardening: minimal-interruption and strict lockdown configurations

**Quick reference:**

| Scope       | Location                       | Who Controls | Can Override? |
| ----------- | ------------------------------ | ------------ | ------------- |
| **Managed** | System-level path (admin-only) | IT/Admin     | No (highest)  |
| **CLI**     | Command-line arguments         | Developer    | Only managed  |
| **Local**   | `.claude/settings.local.json`  | Developer    | Managed + CLI |
| **Project** | `.claude/settings.json`        | Team         | Above scopes  |
| **User**    | `~/.claude/settings.json`      | Developer    | All above     |

**Key insight:** Deny rules always win. Start with deny rules for dangerous patterns, then selectively allow safe operations. Use project settings (committed to git) for team-wide rules and managed settings for enterprise-wide policy.

### [Extended Thinking: How Claude Reasons Through Complex Problems](claude-code-extended-thinking.md)

How extended thinking works, when to use it, and how to control its cost:

**Covered topics:**

- How thinking works: adaptive thinking (Opus 4.6), summarized output, interleaved thinking with tools
- Effort levels: low/medium/high/max and what each controls (thinking depth, tool calls, explanations)
- Configuration: toggle on/off, `MAX_THINKING_TOKENS`, budget vs output limits
- Context window interaction: when thinking tokens are preserved vs stripped
- When to use thinking: architecture, debugging, planning vs simple edits
- Cost management: thinking billed as output tokens, effort as primary cost lever
- Model support and feature compatibility restrictions

**Quick reference:**

| Level      | Thinking Behavior                     | Speed   | Cost    | Availability  |
| ---------- | ------------------------------------- | ------- | ------- | ------------- |
| **max**    | No depth limit, absolute maximum      | Slowest | Highest | Opus 4.6 only |
| **high**   | Almost always thinks deeply (default) | Slow    | High    | All models    |
| **medium** | May skip thinking for simple queries  | Medium  | Medium  | All models    |
| **low**    | Minimizes or skips thinking           | Fast    | Low     | All models    |

**Key insight:** Effort levels are the primary cost lever for thinking. On Opus 4.6 with adaptive thinking, Claude automatically scales thinking depth to task complexity -- manual tuning is rarely needed.

---

## Official Resources

Claude Code documentation:

- [Subagents](https://code.claude.com/docs/en/sub-agents.md)
- [Skills](https://code.claude.com/docs/en/skills.md)
- [MCP Servers](https://code.claude.com/docs/en/mcp.md)
- [Memory System](https://code.claude.com/docs/en/memory.md)
- [Hooks](https://code.claude.com/docs/en/hooks.md)
