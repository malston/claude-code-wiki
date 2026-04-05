---
title: "Wiki Log"
weight: 100
---

# Wiki Log

Chronological record of wiki ingests, lint passes, and structural changes. Each entry starts with a parseable prefix for scripting: `## [YYYY-MM-DD] action | description`.

## [2026-02-09] ingest | Enterprise rollout infrastructure docs

Added infrastructure foundation content: Bedrock, gateway, developer environment, cohort strategy, cost tracking, security controls.

## [2026-02-16] ingest | Extending section (5 files)

Added extension-mechanisms, custom-extensions, hooks-cookbook, integration-patterns, agent-teams. Antislop audit completed -- 0 Tier 1/2/3 violations.

## [2026-02-16] ingest | Structured AI development perspective

Added perspectives article on composable primitives vs third-party frameworks.

## [2026-02-20] ingest | Enterprise managed settings configs

Added baseline and strict managed settings variants, deployment script skeleton, rollback playbook.

## [2026-03-01] ingest | Product development section

Added product-thinking, user-research, requirements-specifications, prototyping-iteration, prioritization-tradeoffs.

## [2026-03-01] ingest | Training paths

Added developer-path, platform-engineer-path, product-manager-path. PM path restructured from developer-centric to product-first curriculum.

## [2026-04-05] lint | Full accuracy review against source code

Cross-referenced all wiki content against Claude Code source snapshot (~5 days old). Found 20 issues: 2 fabricated features, 8 wrong numbers, 10 incomplete coverage items.

## [2026-04-05] fix | P0 fabricated features

Removed `delegate` permission mode (3 files), corrected ultrathink from "deprecated" to active feature.

## [2026-04-05] fix | P1 wrong numbers

Fixed thinking token budget (127,999 not 31,999), Sonnet 4.6 max output (128K not 64K), CLAUDE.md precedence (Local highest not Enterprise), auto-compact threshold (deterministic formula not 75-92% range), default effort (medium not high), 1M context (available via [1m] suffix not API-only), skill budget (1%/8,000 not 2%/16,000).

## [2026-04-05] fix | P2 stale model info and incomplete coverage

Updated default model to Sonnet 4.6, fixed Opus subscriber tiers (Max/Team Premium only), added `max` effort level and `best` alias, removed phantom `default` alias, added MEMORY.md 25KB byte limit, completed hook events table (27 events with recipes), added missing agent schema fields, documented HTTP hooks, documented session memory compaction / context collapse / cache break detection.

## [2026-04-05] structure | Karpathy pattern improvements

Added log.md, added cross-section links.
