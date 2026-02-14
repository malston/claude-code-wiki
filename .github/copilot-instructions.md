# Copilot Instructions

This is a Hugo static site (Hugo Book theme) that documents Claude Code internals, usage patterns, and enterprise rollout guidance. Content lives under `content/` in four sections: `internals/`, `guides/`, `extending/`, and `enterprise-rollout/`.

## Build and Validation

- `hugo serve` -- local dev server
- `hugo --gc --minify` -- production build
- `bash scripts/check-style.sh` -- style checker enforced in CI via `.github/workflows/style-check.yml`

The style checker runs on every PR. It catches: em dash characters, triple-hyphen em dashes outside code blocks/inline code, bare code fences missing language identifiers, banned opener phrases, superlative filler words, and contrastive reframe patterns.

## Writing Style

All content must follow `STYLE-GUIDE.md`. When reviewing changes to `content/**/*.md`, check for these violations:

### Formatting

- Use `--` for dashes, never `—` (em dash character) or `---` (triple hyphen) for em dashes
- All fenced code blocks must have a language identifier (`bash`, `text`, `yaml`, `json`, `markdown`, etc.)
- Use ASCII diagrams over Mermaid for simple structures

### Anti-Patterns to Flag

- **Contrastive reframes**: "It's not X, it's Y" or "not just X -- it's Y"
- **Superlative filler**: powerful, seamless, elegant, robust, cutting-edge, game-changing, next-level
- **Triplet lists for rhythm**: three abstract nouns grouped for cadence rather than information
- **Hedged bold sandwiches**: hedge, strong claim, hedge
- **Banned openers**: "Let's be honest", "Here's the thing", "The truth is", "At the end of the day"
- **Relative timeline phrasing**: "new feature", "recently added", "improved X", "legacy Y" when describing features relative to product history (fine in non-relative contexts like "start a new session")
- **Internal implementation names**: don't leak private class/struct names into user-facing prose; documented config names (env vars, flags, settings keys) are fine

### Voice

- Guides: dry, precise, direct. Imperative or declarative sentences.
- Perspectives (in `content/perspectives/`): opinionated, conversational, but still no filler.
- Be specific -- if you can't name a concrete example, the claim doesn't belong.
- Show with code/config/commands rather than describing in prose.

## Shell Scripts

Scripts in `scripts/` use Bash. They should use defensive patterns: `set -euo pipefail`, quote variables, and avoid unportable constructs.

## Hugo Configuration

- Config: `hugo.toml`
- `BookSection = '*'` shows all sections in sidebar
- `ignoreFiles = ['CLAUDE\.md$']` excludes context files from the build
- `unsafe = true` in Goldmark renderer for raw HTML in markdown
