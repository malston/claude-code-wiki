# Claude Code Wiki

Hugo-based wiki about Claude Code internals, patterns, and usage. Deployed to GitHub Pages.

## Commands

- `hugo serve` -- local dev server
- `hugo --gc --minify` -- production build

## Writing Style

All content MUST follow the rules in [STYLE-GUIDE.md](STYLE-GUIDE.md). Key enforcement points:

- NEVER use contrastive reframes ("It's not X, it's Y", "not just X -- it's Y")
- NEVER use superlative filler (powerful, seamless, elegant, robust, cutting-edge, game-changing)
- NEVER use triplet lists for rhetorical rhythm -- each item must carry information, not cadence
- NEVER use hedged bold sandwiches (hedge, strong claim, hedge)
- NEVER use "Let's be honest" / "Here's the thing" / "The truth is" openers
- NEVER use temporal references (new, recently added, improved, legacy) in content
- NEVER use implementation detail names in user-facing prose
- Use `--` for dashes, not em dash characters
- Be specific: if you can't name a concrete example, the claim doesn't belong
- Show with code/config/commands rather than describing in prose
- Guides: dry, precise, direct. Perspectives: opinionated but still no filler.
