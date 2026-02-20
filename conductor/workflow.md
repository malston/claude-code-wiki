# Workflow

## Test-Driven Development

**Strictness: Flexible**

TDD applies to scripts and automation tooling, not to article content. The style-check CI workflow serves as the content quality gate.

| Scope              | TDD Applies? | Verification Method                  |
| ------------------ | ------------ | ------------------------------------ |
| Shell scripts      | Yes          | Unit tests where applicable          |
| CI workflows       | Yes          | Test in feature branch               |
| Article content    | No           | Style-check workflow + manual review |
| Hugo configuration | No           | `hugo serve` verification            |

## Commit Strategy

**Style: Descriptive messages, no format required**

Write clear commit messages describing what changed and why. No prefix convention enforced, but messages should be specific enough to understand the change from the log.

Examples:

- `Add context management article covering compaction and subagents`
- `Fix incorrect Opus 4.6 pricing in model selection guide`
- `Update hooks cookbook with PreCompact event examples`

## Branching

- All non-trivial changes go through feature branches
- Never commit directly to `main` without explicit permission
- Feature branches should be short-lived (single article or related set of changes)

## Code Review

**Policy: Required for non-trivial changes**

- Typo fixes and minor formatting corrections can go direct to `main`
- Article additions, structural changes, and tooling modifications require a PR
- Style-check CI must pass before merge

## Verification Checkpoints

**Frequency: Only at track completion**

Verification happens when a track (logical unit of work) is complete, not at every intermediate step. This keeps momentum while ensuring quality at delivery boundaries.

Verification checklist:

1. Hugo builds without errors (`hugo --gc --minify`)
2. Style-check CI passes
3. Content renders correctly in local preview (`hugo serve`)
4. All articles in the track are linked from appropriate index pages

## Task Lifecycle

```
pending → in_progress → completed
```

Tasks move through three states. A task is only marked `completed` when its acceptance criteria are met and any required verification passes.
