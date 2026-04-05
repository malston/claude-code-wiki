---
title: Wiki Accuracy Review -- 2026-04-05
weight: 99
modified: 2026-04-05T11:29:03-06:00
---

# Wiki Accuracy Review -- 2026-04-05

Cross-referenced all wiki content against the Claude Code source snapshot (~5 days old as of review date). Evaluated structural quality against Karpathy's [LLM Wiki pattern](https://gist.github.com/karpathy/442a6bf555914893e9891c11519de94f).

## Part 1: Structural Assessment (Karpathy Lens)

**What the wiki does well:**

- Clear schema (CLAUDE.md + STYLE-GUIDE.md) with enforced writing conventions
- Content-oriented index with category organization
- Standalone sections extractable for different audiences (enterprise binder)
- Good topical breadth: internals, guides, extending, enterprise, product, perspectives, training
- Training paths organized by role -- synthesis layer over raw content

**Structural gaps:**

- **No `log.md`** -- no chronological record of ingests, updates, or lint passes. No way to tell when pages were last verified against source.
- **No lint process** -- no documented health-check for contradictions, stale claims, or orphan pages.
- **Weak cross-section linking** -- pages link within their section via Hugo relref, but little cross-pollination (permissions guide does not link to enterprise permissions; model selection does not link to extended thinking internals).
- **Dated enterprise section** -- "February 2026" with a disclaimer to check docs, but no mechanism to flag which claims have drifted.
- **No raw sources layer** -- wiki references source code but doesn't maintain curated immutable sources (release notes, changelogs, official docs snapshots) to anchor verification.

## Part 2: Accuracy Findings by Section

### Internals (6 critical errors)

| Page                    | Issue                 | Wiki Says                   | Source Says                                                                                  |
| ----------------------- | --------------------- | --------------------------- | -------------------------------------------------------------------------------------------- |
| `extended-thinking.md`  | Thinking budget       | Default 31,999 / max 63,999 | 127,999 for Opus/Sonnet 4.6 (`utils/context.ts:219`)                                         |
| `extended-thinking.md`  | Sonnet 4.6 max output | 64K                         | 128K upper limit (`utils/context.ts:171`)                                                    |
| `extended-thinking.md`  | Default effort        | "high (default)"            | `medium` for Pro subscribers on Opus 4.6 (`utils/effort.ts:307-318`)                         |
| `extended-thinking.md`  | Ultrathink            | "deprecated"                | Active feature with rainbow UI highlighting (`utils/thinking.ts`, `PromptInput.tsx:685-757`) |
| `context-management.md` | 1M context            | "API-only"                  | Available in Claude Code via `[1m]` suffix (`utils/model/modelOptions.ts:146-161`)           |
| `system-prompt.md`      | CLAUDE.md precedence  | Enterprise highest          | **Local highest**, Enterprise (managed) lowest (`utils/claudemd.ts:1-9`)                     |

**Also missing from internals:**

- Session memory compaction (`trySessionMemoryCompaction`) -- a pre-compaction path
- Context collapse feature (`CONTEXT_COLLAPSE`) -- suppresses auto-compact when active
- Auto-compact circuit breaker after 3 consecutive failures
- Cache break detection analytics (`tengu_prompt_cache_break`)

### Extending (5 critical errors)

| Page                      | Issue                      | Wiki Says                     | Source Says                                                                                                                                                                                                                                                                        |
| ------------------------- | -------------------------- | ----------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `extension-mechanisms.md` | Skill budget               | 2% / 16,000 chars             | 1% / 8,000 chars (`tools/SkillTool/prompt.ts:21-23`)                                                                                                                                                                                                                               |
| `extension-mechanisms.md` | MCP output limit           | 25,000 tokens                 | No such limit found; confused with FileReadTool's limit                                                                                                                                                                                                                            |
| `custom-extensions.md`    | `delegate` permission mode | Listed as valid               | Does not exist (`types/permissions.ts:16-22`)                                                                                                                                                                                                                                      |
| `hooks-cookbook.md`       | Hook events                | 14 events                     | 27 events in source (`coreTypes.ts:25-53`) -- 13 undocumented: `StopFailure`, `PostCompact`, `PermissionDenied`, `Setup`, `TaskCreated`, `Elicitation`, `ElicitationResult`, `ConfigChange`, `WorktreeCreate`, `WorktreeRemove`, `InstructionsLoaded`, `CwdChanged`, `FileChanged` |
| `custom-extensions.md`    | Agent file structure       | Subdirectory with `CLAUDE.md` | Single `.md` files with YAML frontmatter (`loadAgentsDir.ts`)                                                                                                                                                                                                                      |

**Also missing from extending:**

- HTTP hooks (`execHttpHook.ts` exists but undocumented)
- Agent schema fields: `isolation`, `effort`, `background`, `omitClaudeMd`
- Worktree-based isolation for teammates
- `--agent-teams` flag is `[ANT-ONLY]` -- not mentioned

### Guides (9 critical errors)

| Page                           | Issue            | Wiki Says             | Source Says                                                             |
| ------------------------------ | ---------------- | --------------------- | ----------------------------------------------------------------------- |
| `large-codebase-strategies.md` | `/batch` command | Described in detail   | **Does not exist** in source                                            |
| `model-selection.md`           | Default model    | Sonnet 4.5            | **Sonnet 4.6** for 1P users (`utils/model/model.ts:127`)                |
| `model-selection.md`           | Opus default for | "Max, Teams, and Pro" | Max and Team Premium only; Pro gets Sonnet (`utils/model/model.ts:197`) |
| `model-selection.md`           | Effort levels    | 3 (low, medium, high) | 4: low, medium, high, **max** (`utils/effort.ts:13-18`)                 |
| `model-selection.md`           | `best` alias     | Not mentioned         | Exists in source (`utils/model/aliases.ts`)                             |
| `model-selection.md`           | `default` alias  | Listed as valid       | Not in `MODEL_ALIASES` array                                            |
| `permissions-enterprise.md`    | `delegate` mode  | Listed as valid       | Does not exist                                                          |
| `memory-organization.md`       | MEMORY.md limits | 200-line cap only     | Also 25KB byte limit (`memdir/memdir.ts:38`)                            |
| `permissions-enterprise.md`    | Settings cascade | Invents "CLI" scope   | Called `flagSettings` internally                                        |

## Part 3: Severity Summary

### Fabricated features (highest severity)

1. **`/batch` command** -- described with orchestrator, worker agents, worktree isolation, status tables. None of this exists in source.
2. **`delegate` permission mode** -- referenced in 3 separate wiki pages. No such mode in source.
3. **Ultrathink "deprecated"** -- it's an active, highlighted feature.

### Wrong numbers (high severity)

4. Thinking token budget off by 2-4x
5. Skill budget off by 2x on both percentage and character count
6. Sonnet 4.6 max output listed as half actual value
7. CLAUDE.md precedence order inverted
8. Auto-compact threshold range doesn't match deterministic formula

### Stale model information (medium severity)

9. Sonnet 4.5 vs 4.6 as default -- multiple pages affected
10. Opus default subscriber tiers wrong
11. Missing `max` effort level
12. Missing `best` model alias; phantom `default` alias

### Incomplete coverage (medium severity)

13. Only 14 of 27 hook events documented (13 missing)
14. Missing agent schema fields (isolation, effort, background)
15. HTTP hooks undocumented
16. Session memory compaction, context collapse, cache break detection undocumented
17. MEMORY.md byte limit undocumented

## Part 4: Recommendations

### Immediate (lint pass)

1. Fix the 3 fabricated features -- remove `/batch`, remove `delegate`, correct ultrathink status
2. Correct all wrong numbers with source citations
3. Update model information to reflect Sonnet 4.6 / current subscriber tiers
4. Update CLAUDE.md precedence to match actual load order

### Structural (per Karpathy pattern)

5. Add a `log.md` -- even a simple changelog with dates so you can tell when pages were last verified
6. Establish a lint cadence -- periodic verification against source, flagging pages that haven't been checked since the last Claude Code release
7. Add cross-section links -- permissions guide <-> enterprise permissions, model selection <-> extended thinking, hooks cookbook <-> integration patterns
8. Complete the hook events table -- the source defines 26; document all of them
9. Add source anchoring -- when a wiki page makes a specific claim (token counts, precedence orders), cite the source file so future lint passes can verify quickly
