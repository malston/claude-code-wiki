# Architecture Overview

## End-to-End Request Flow

```
┌─────────────────────────────────────────────────────────────────────┐
│                        CORPORATE NETWORK                            │
│                                                                     │
│  ┌───────────────┐  ┌───────────────┐  ┌───────────────┐            │
│  │  Developer 1  │  │  Developer 2  │  │  Developer N  │            │
│  │  claude CLI   │  │  claude CLI   │  │  claude CLI   │            │
│  │               │  │               │  │               │            │
│  │  managed-     │  │  managed-     │  │  managed-     │            │
│  │  settings.json│  │  settings.json│  │  settings.json│            │
│  └──────┬────────┘  └──────┬────────┘  └──────┬────────┘            │
│         │                  │                  │                     │
│         └──────────────────┼──────────────────┘                     │
│                            │                                        │
│                            ▼                                        │
│              ┌──────────────────────────┐                           │
│              │      LLM GATEWAY         │                           │
│              │   (LiteLLM / Kong AI)    │                           │
│              │                          │                           │
│              │  • SSO authentication    │                           │
│              │  • Per-user/team budgets │                           │
│              │  • Rate limiting         │                           │
│              │  • Request logging       │                           │
│              │  • Model routing         │                           │
│              │  • Holds AWS credentials │                           │
│              └───────────┬──────────────┘                           │
│                          │                                          │
└──────────────────────────┼──────────────────────────────────────────┘
                           │  (Direct Connect / Site-to-Site VPN)
                           │
┌──────────────────────────┼──────────────────────────────────────────┐
│                     AWS ACCOUNT (Dedicated)                         │
│                          │                                          │
│              ┌───────────┴─────────────┐                            │
│              │   VPC ENDPOINT          │                            │
│              │   (PrivateLink)         │                            │
│              │                         │                            │
│              │  com.amazonaws.{region} │                            │
│              │  .bedrock-runtime       │                            │
│              │                         │                            │
│              │  Policy: InvokeModel,   │                            │
│              │  InvokeModelWith        │                            │
│              │  ResponseStream ONLY    │                            │
│              └───────────┬─────────────┘                            │
│                          │                                          │
│              ┌───────────┴─────────────┐                            │
│              │   AMAZON BEDROCK        │                            │
│              │                         │                            │
│              │  Claude Sonnet/Opus     │                            │
│              │  (primary model)        │                            │
│              │                         │                            │
│              │  Claude Haiku           │                            │
│              │  (fast model)           │                            │
│              │                         │                            │
│              │  • No data retention    │                            │
│              │  • No training use      │                            │
│              │  • CloudTrail audit     │                            │
│              └─────────────────────────┘                            │
│                                                                     │
│  ┌─────────────────────────────────────────────────────────────┐    │
│  │  OBSERVABILITY                                              │    │
│  │  • CloudTrail → every InvokeModel call with IAM principal   │    │
│  │  • CloudWatch → token usage, latency, error rates           │    │
│  │  • Cost Explorer → per-account Bedrock spending             │    │
│  └─────────────────────────────────────────────────────────────┘    │
│                                                                     │
└─────────────────────────────────────────────────────────────────────┘
```

## Configuration Hierarchy

```
┌───────────────────────────────────────────────────────────────┐
│  HIGHEST PRIORITY (cannot be overridden)                      │
│                                                               │
│  managed-settings.json                                        │
│  • Deployed via MDM (Jamf, Kandji, Intune)                    │
│  • Bedrock routing, security deny rules, disable bypass       │
│  • Location:                                                  │
│    macOS:   /Library/Application Support/ClaudeCode/          │
│    Linux:   /etc/claude-code/                                 │
│    Windows: C:\Program Files\ClaudeCode\                      │
├───────────────────────────────────────────────────────────────┤
│  Managed CLAUDE.md (org-wide, always loaded, ~30 lines)       │
│  • Security non-negotiables, AI interaction norms             │
├───────────────────────────────────────────────────────────────┤
│  .claude/settings.local.json (gitignored)                     │
│  • Individual developer preferences                           │
├───────────────────────────────────────────────────────────────┤
│  Project .claude/settings.json (checked into git)             │
│  • Team-level permissions, MCP server configs                 │
├───────────────────────────────────────────────────────────────┤
│  Project .claude/CLAUDE.md + .claude/rules/ (checked into git)│
│  • Build commands, architecture, path-scoped conventions      │
├───────────────────────────────────────────────────────────────┤
│  ~/.claude/settings.json (user global)                        │
│  • Personal defaults across all projects                      │
│                                                               │
│  LOWEST PRIORITY                                              │
└───────────────────────────────────────────────────────────────┘
```

## Context Window Memory Hierarchy

```
Layer 0: Managed CLAUDE.md          ─── Always loaded, org-wide (~500 tokens)
Layer 1: Project CLAUDE.md + Rules  ─── Loaded per-repo, path-scoped (~3K tokens)
Layer 2: agent_docs/                ─── Loaded on-demand by Claude (~2-5K per doc)
Layer 3: Skills                     ─── Loaded on invocation/auto-match (~1-3K per skill)
```
