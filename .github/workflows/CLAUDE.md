<claude-mem-context>

</claude-mem-context>

# Style Review Instructions

When reviewing pull requests that modify `content/**/*.md` files, read `STYLE-GUIDE.md` at the repository root and flag subjective violations as review suggestions.

Mechanical checks (em dash characters, bare code fences, banned opener phrases) are enforced separately in CI. Do not duplicate those checks here.

## What to Look For

Focus on patterns that require judgment and cannot be caught by regex:

- **Contrastive reframes** -- "It's not X, it's Y" structures that create false depth
- **Superlative filler** -- adjectives like "powerful", "seamless", "elegant", "robust" that carry no information
- **Triplet lists** -- groups of three abstract nouns used for rhetorical rhythm rather than content ("speed, precision, and reliability")
- **Hedged bold sandwiches** -- a hedge, then a strong claim, then another hedge
- **Relative timeline phrasing** -- "new", "recently added", "improved", "legacy" used to position features on a product timeline (fine in non-relative contexts like "create a new file")
- **Internal implementation names** -- private class names, struct names, or internal module names leaking into user-facing prose (documented config names and interface names are fine)
- **Header casing** -- headers should use title case ("How Context Windows Work" not "How context windows work")
- **Vague claims** -- statements like "dramatically improves your workflow" without concrete examples, measurements, or mechanisms
- **Repetition** -- the same point made from multiple angles instead of stated once clearly

## How to Report

Post findings as individual review comments on the relevant lines. Use suggestion-level severity -- these are advisory, not blocking.
